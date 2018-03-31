import config

import os, sys, time, re
import asyncio
import aiohttp
import async_timeout
import json

serverIDs = ['Goloman', 'Hands', 'Holiday', 'Welsh', 'Wilkes']
valid_commands = ['IAMAT', 'WHATSAT']       # valid commands from clients

clients = {}    # client_id : [server_id, time_diff, latlong, time_sent]
SERVER_ID = 0
TIME_DIFF = 1
LATLONG = 2
TIME_SENT = 3
tasks = {}      # task : (reader, writer)

# directed server communication graph
communications_graph = {
    'Goloman': ['Hands', 'Holiday', 'Wilkes'],
    'Hands': ['Goloman', 'Wilkes'],
    'Holiday': ['Goloman', 'Welsh'],
    'Wilkes': ['Goloman', 'Hands'],
    'Welsh': ['Holiday'],
}

ports = {
    'Goloman': 19560,
    'Hands': 19561,
    'Holiday': 19562,
    'Wilkes': 19563,
    'Welsh': 19564,
}

# regex used often:
valid_field = re.compile(r'^\S+$')
iso_latlong = re.compile(r'^[+-][0-9]+.[0-9]+[+-][0-9]+.[0-9]+$')
unix_time = re.compile(r'^[0-9]*.[0-9]+$|^[0-9]+.[0-9]*$')
int_matcher = re.compile(r'^[0-9]+$')
time_diff_re = re.compile(r'^[+-][0-9]+.[0-9]+$')
# compile regex to squeeze spaces
squeeze_space = re.compile(r'\s+')


#############################################################################################
#############################################################################################
#############################################################################################

# MAIN

def main():
    ####################
    ## setup
    if len(sys.argv) != 2:
        print('Invalid number of arguments: please specify port ID')
        sys.exit(1)
    global server_id
    server_id = sys.argv[1]
    if server_id not in serverIDs:
        print('Invalid server ID')
        sys.exit(1)
    print(server_id)

    # logfile name
    global log
    log = '%s_log.txt' % server_id
    
    ####################
    ## core functionality

    # open logfile to write to
    global f
    f = open(log, 'a+')

    # get event loop
    global loop
    loop = asyncio.get_event_loop()
    loop.set_debug(True)        # TODO just for testing

    # start loop to accept clients
    coro = asyncio.start_server(accept_client, '127.0.0.1', ports[server_id], loop=loop)
    server = loop.run_until_complete(coro)

    # Serve requests until Ctrl+C is pressed
    print('Serving on {}'.format(server.sockets[0].getsockname()))
    try:
        loop.run_forever()
    except KeyboardInterrupt:
        print('Closing server...')
        f.close()

    # Close the server if the server specifically cancels itself (KeyboardInterrupt)
    server.close()
    loop.run_until_complete(server.wait_closed())
    loop.close()

    # close the logfile
    f.close()


#############################################################################################
#############################################################################################
#############################################################################################

# GENERIC

## TODO: need to fill in which exception want to catch
async def server_write_transport_stream(writer, msg):
    if msg == None:
        return

    await write_transport_stream(writer, msg)
    writer.close()  # close connection after all server writes

# message is str, not byte encoded
async def write_transport_stream(writer, msg):
    if msg == None:
        return

    try:
        writer.write(msg.encode())
        await writer.drain()
    except:
        print('IOError in write_transport_stream: %s' % msg)

async def write_to_log(msg):
    if msg == None:
        return
        
    try:
        f.write(msg)
    except:
        print('IOError in write_to_log: %s' % msg)




#############################################################################################
#############################################################################################
#############################################################################################

# CODE ABOUT SERVERS CONNECTING TO SERVERS


# currently gives errors if can't connect to all the servers
async def tcp_server_client(msg, dont_send):
    for server in communications_graph[server_id]:
        if server in dont_send:
            continue
        try:
            reader, writer = await asyncio.open_connection('127.0.0.1', ports[server], loop=loop)
            await write_to_log('Opened connection with %s\n' % server)
            await server_write_transport_stream(writer, msg)
            await write_to_log('Propagated message: %s\n' % msg)
            await write_to_log('Dropped connection with %s\n' % server)
        except:
            print('Error while connecting and propagating message to server %s' % server)
            await write_to_log('Error while connecting and propagating message to server %s: Dropped connection with %s\n' % (server, server))



#############################################################################################
#############################################################################################
#############################################################################################

# CODE ABOUT CLIENT CONNECTIONS


''' Accept the client and asynchronously process it before closing server end of connection
*   input:  reader          - StreamReader
*   input:  writer          - StreamWriter
'''
def accept_client(reader, writer):
    # accept all clients equally, handle clients and servers separately
    task = asyncio.ensure_future(handle_client(reader, writer))
    tasks[task] = (reader, writer)

    def close_client(task):
        print('Closing client')
        del tasks[task]
        writer.close()
    
    # if the task is completed, close the client
    task.add_done_callback(close_client)


''' Processes the client and returns when client closes write end
*   input:  reader          - StreamReader
*   input:  writer          - StreamWriter
'''
async def handle_client(reader, writer):
    # handle clients and servers separately

    while not reader.at_eof():
        data = await reader.readline()
        # sanitize and split input, then sanitize split
        buf = list(filter(lambda x: len(x) > 0, squeeze_space.sub(r' ', data.decode()).strip().split(' ')))
        # greedily process input messages, if a message exists
        await process_buf(writer, buf)
        print(buf)


# doesn't return anything
async def process_buf(writer, buf):
    time_received = time.time()

    print('Processing {}'.format(buf))

    # check if message might exist
    if len(buf) < 4:
        return

    command = buf[0]
    if command in valid_commands or command == 'AT':
        if await validate_command(command, buf[1:]):
            input_command = '%s %s' % (command, ' '.join(buf[1:]))
            res = await handle_command(command, buf[1:], time_received)
        else:
            input_command = '%s' % ' '.join(buf)
            res = '? %s' % ' '.join(buf)   # print the invalid message

    else:       # invalid command
        input_command = '%s' % ' '.join(buf)
        res = '? %s' % ' '.join(buf)   # print the invalid message

    # write back to the client
    await write_transport_stream(writer, res)
    # log the input
    await write_to_log('Received: %s\n' % input_command)      # input will always end in \n, print representation
    # log the output
    await write_to_log('Sent: %s\n' % res)                  # output will always have the ending \n (handle_command returns this), print representation



''' Takes in a message array and returns a response
*   input:  message_arr     - message in array format
*   input:  time_received   - time command was received
*   output: res             - response in string format
'''
async def handle_command(command, message_arr, time_received):
    res = None
    if command == 'IAMAT':
        client_id = message_arr[0]
        latlong = message_arr[1]
        time_sent = message_arr[2]
        # make the time diff
        time_diff = time_received - float(time_sent)
        if time_diff < 0:
            time_diff = '-%f' %time_diff
        else:
            time_diff = '+%f' %time_diff

        clients[client_id] = [server_id, time_diff, latlong, time_sent]   # might be time_received instead of time.time() [time server sent response]

        res = 'AT %s %s %s %s %s\n' % (server_id, time_diff, client_id, latlong, time_sent)
        propagated_msg = 'AT %s %s %s %s %s %s\n' % (server_id, time_diff, client_id, latlong, time_sent, server_id)

        dont_send = [] # don't send to the server that sent this message, or the one the flood started from: but I am both

        # propagate information to other servers
        # open connections to other servers
        # send message to other servers
        # close connection to other servers
        connect_to_servers = asyncio.ensure_future(tcp_server_client(propagated_msg, dont_send))
        def finish_connecting(task):
            print('Propagated messages to servers {}'.format(communications_graph[server_id]))
        connect_to_servers.add_done_callback(finish_connecting)


    elif command == 'WHATSAT':
        client_id = message_arr[0]
        radius = int(message_arr[1])    # int or float?
        number_of_results = int(message_arr[2])

        if client_id not in clients:
            return None

        temp_server, time_diff, latlong, time_sent = clients[client_id]

        # communicate with Google Places API
        latlong_arr = list(filter(lambda x: len(x) > 0, re.split(r'[+-]', latlong)))
        # print(latlong_arr)
        latitude = latlong_arr[0]
        longitude = latlong_arr[1]
        url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=%s,%s&radius=%d&key=%s' % (latitude, longitude, radius, config.API_KEY)
        # print(url)
        async with aiohttp.ClientSession() as session:
            json_response = await fetch(session, url)
            json_response['results'] = json_response['results'][:number_of_results]
            # print(json.dumps(json_response, indent=3))
            # print(json_response)
            api_response = json.dumps(json_response, indent=3)

        res = 'AT %s %s %s %s %s\n%s\n\n' % (temp_server, time_diff, client_id, latlong, time_sent, api_response)

    elif command == 'AT':
        original_server = message_arr[0]
        time_diff = message_arr[1]
        client_id = message_arr[2]
        latlong = message_arr[3]
        time_sent = message_arr[4]
        client_server = message_arr[5]

        print('Opened connection with %s\n' % client_server)
        print('Dropped connection with %s after receiving message ->\n' % client_server)
        await write_to_log('Opened connection with %s\n' % client_server)
        await write_to_log('Dropped connection with %s after receiving message ->\n' % client_server)

        # check to see if client entry exists or was not already updated: if not, create it and propagate
        if client_id not in clients or float(time_sent) > float(clients[client_id][TIME_SENT]):
            # update current server information
            clients[client_id] = [original_server, time_diff, latlong, time_sent]   # might be time_received instead of time.time() [time server sent response]
            # propagate information to other servers
            # open connections to other servers
            # send message to other servers
            # close connection to other servers
            # propagated msg
            propagated_msg = '%s %s %s\n' % (command, ' '.join(message_arr[:-1]), server_id)    # always propagates the original server the client communicated with
            dont_send = [client_server, original_server]  # don't send to the server that sent this message, or the one the flood started from
            connect_to_servers = asyncio.ensure_future(tcp_server_client(propagated_msg, dont_send))
            def finish_connecting(task):
                print('Propagated messages to servers {}'.format(communications_graph[server_id]))
            connect_to_servers.add_done_callback(finish_connecting)
        else:
            return None # otherwise don't propagate

    return res


''' HTTP Fetch using aiohttp
*   input:  session         - aiohttp session
*   input:  url             - url to do GET request on
*   output: response        - response in json dictionary format
'''
async def fetch(session, url):
    async with async_timeout.timeout(10):
        async with session.get(url) as response:
            return await response.json()    # returns a dict
                                # or should i use .text() ? eggert says needs to be "exact format google returns, with modification of newlines and number of results..."


''' Checks to see if the message is valid format
*   input:  message_arr     - message in array format
*   output: bool            - boolean if the message arr is a valid command with correct field format
'''
async def validate_command(command, rest):

    # all fields need to have no whitespace
    if not all([valid_field.match(x) for x in rest]):
        return False

    # other validation checks?
    if command == 'IAMAT':
        if len(rest) != 3:
            return False
        latlong = rest[1]
        time_sent = rest[2]
        if not (iso_latlong.match(latlong) and unix_time.match(time_sent)):
            return False

    elif command == 'WHATSAT':
        if len(rest) != 3:
            return False
        client_id = rest[0]
        radius = rest[1]
        number_of_results = rest[2]

        # check regex
        if not (int_matcher.match(radius) and int_matcher.match(number_of_results)):
            return False

        radius = int(radius)
        number_of_results = int(number_of_results)

        if (radius > 50 or radius < 0) or (client_id not in clients) or (number_of_results > 20 or number_of_results < 0):
            return False

        if client_id not in clients:
            return False
        
    elif command == 'AT':           # for servers # will probably change
        if len(rest) != 6:
            return False
        time_diff = rest[1]
        latlong = rest[3]
        time_sent = rest[4]

        if not (time_diff_re.match(time_diff) and iso_latlong.match(latlong) and unix_time.match(time_sent)):
            return False
    else:
        return False

    return True


if __name__ == '__main__':
    main()