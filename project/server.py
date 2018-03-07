import config

import os, sys, time, re
import asyncio
import aiohttp
import async_timeout
import json, pprint

serverIDs = ['Goloman', 'Hands', 'Holiday', 'Welsh', 'Wilkes']
valid_commands = ['IAMAT', 'WHATSAT']
clients = {}    # client_id : [time_diff, latlong, time_sent]
tasks = {}

log = 'log.txt'

# regex used often:
# valid command field
valid_field = re.compile(r'^\S+$')

def main():
    # setup
    if len(sys.argv) != 2:
        print('Invalid number of arguments: please specify port ID')
        sys.exit(1)
    global server_id
    server_id = sys.argv[1]
    if server_id not in serverIDs:
        print('Invalid server ID')
        sys.exit(1)
    print(server_id)
    
    # core functionality
    ''' NOTE:
    Goloman<->Hands
    Goloman<->Holiday
    Goloman<->Wilkes
    Hands<->Wilkes
    Holiday<->Welsh '''

    # open logfile to write to
    global f
    f = open(log, 'w')

    loop = asyncio.get_event_loop()
    coro = asyncio.start_server(accept_client, '127.0.0.1', 8888, loop=loop)
    server = loop.run_until_complete(coro)

    # Serve requests until Ctrl+C is pressed
    print('Serving on {}'.format(server.sockets[0].getsockname()))
    try:
        loop.run_forever()
    except KeyboardInterrupt:
        print('Closing server...')

    # Close the server if the server specifically cancels itself (KeyboardInterrupt)
    server.close()
    loop.run_until_complete(server.wait_closed())
    loop.close()

    # close the logfile
    f.close()


''' Accept the client and asynchronously process it before closing server end of connection
*   input:  reader          - StreamReader
*   input:  writer          - StreamWriter
'''
def accept_client(reader, writer):
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

    # compile regex to squeeze spaces
    squeeze_space = re.compile(r'\s+')
    buf = []
    while not reader.at_eof():        # continue until client eof
        print(buf)
        data = await reader.read(100)
        buf += list(filter(lambda x: len(x) > 0, squeeze_space.sub(r' ', data.decode()).strip().split(' ')))   # sanitize and split input, then sanitize split
        # greedily process incoming messages
        if await contains_message(buf):
            buf = await process_message(buf, writer)      # every time you process some of the data, remove part you processed


''' Takes in a message array and returns a response
*   input:  message_arr     - message in array format
*   input:  time_received   - time command was received
*   output: res             - response in string format
'''
async def handle_command(message_arr, time_received):
    res = ''
    command = message_arr[0]
    if command == 'IAMAT':
        client_id = message_arr[1]
        latlong = message_arr[2]
        time_sent = float(message_arr[3])
        time_diff = time_received - time_sent
        if time_diff < 0:
            time_diff = '-%f' %time_diff
        else:
            time_diff = '+%f' %time_diff
        clients[client_id] = [time_diff, latlong, time_sent]   # might be time_received instead of time.time() [time server sent response]
        res = 'AT %s %s %s %s %f' % (server_id, time_diff, client_id, latlong, time_sent)
    elif command == 'WHATSAT':
        client_id = message_arr[1]
        radius = int(message_arr[2])    # int or float?
        number_of_results = int(message_arr[3])
        time_diff, latlong, time_sent = clients[client_id]

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

        res = 'AT %s %s %s %s %f\n%s\n\n' % (server_id, time_diff, client_id, latlong, time_sent, api_response)
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


''' Checks to see if buffer potentially has a message
*   input:  buf             - buffer array
*   output: bool            - does the buffer have a message in it
'''
async def contains_message(buf):
    if len(buf) == 0:
        return False

    if buf[0] in valid_commands:    # client commands
        if len(buf) >= 4:
            return True
        return False
    elif buf[0] == 'AT':            # server commands
        if len(buf) >= 5:
            return True
        return False
    # currently processing 4 commands at a time
    if len(buf) >= 4:               # invalid commands
        return True
    return False


''' Process the message inside the buffer
*   input:  buf             - buffer array
*   input:  writer          - StreamWriter responses
*   output: remainder       - Remainder of the buffer
'''
async def process_message(buf, writer):
    time_received = time.time()

    # validate message
    message_arr = buf[:4]
    if not await valid_message(message_arr):
        print('? %r' % ' '.join(message_arr))   # print the invalid message
        return buf[4:]                          # throw away the 4 fields just processed
    
    # log the input
    f.write(' '.join(message_arr))

    res = await handle_command(message_arr, time_received)
    print(res)
    writer.write(res.encode())
    await writer.drain()

    # log the output
    f.write(res)

    return buf[4:]


''' Checks to see if the message is valid format
*   input:  message_arr     - message in array format
*   output: bool            - boolean if the message arr is a valid command with correct field format
'''
async def valid_message(message_arr):
    if (message_arr[0] == 'AT' and len(message_arr) != 5) or len(message_arr) != 4:
        return False
    command = message_arr[0]
    if command not in valid_commands:
        return False

    # all fields need to have no whitespace
    if not all([valid_field.match(x) for x in message_arr]):
        return False

    # other validation checks?
    if command == 'WHATSAT':
        client_id = message_arr[1]
        radius = int(message_arr[2])
        number_of_results = int(message_arr[3])
        if radius > 50 or radius < 0 or client_id not in clients or number_of_results > 20 or number_of_results < 0:
            return False
    return True


if __name__ == '__main__':
    main()