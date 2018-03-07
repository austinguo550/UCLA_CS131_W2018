import asyncio
import time
import sys


# if len(sys.argv) < 2:
#     print('wrong number of args')
#     sys.exit(1)

async def tcp_echo_client(loop):
    reader, writer = await asyncio.open_connection('127.0.0.1', 8888, loop=loop)
    while 1:
        try:
            # option = input('')
            # message1 = 'IAMAT kiwi.cs.ucla.edu +34.068930-118.445127 %f' % time.time()
            # message2 = 'WHATSAT kiwi.cs.ucla.edu 10 1'
            # message = ''
            # if option == '1':
            #     message = message1
            # else:
            #     message = message2
            message = """     IAMAT     kiwi.cs.ucla.edu 
+34.068930-118.445127          1520023934.918963997         WHATSAT
            """#input('')
            print('Send: %s' % message)
            writer.write(message.encode())
            await writer.drain()
            
            data = await reader.read(50000)
            print('Received: %s' % data.decode())
        except KeyboardInterrupt:
            print('Close the socket')
            writer.close()
            return
    

# message = input('') + ' ' + str(time.time())
loop = asyncio.get_event_loop()
loop.run_until_complete(tcp_echo_client(loop))
loop.close()