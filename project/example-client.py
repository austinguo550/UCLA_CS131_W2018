import asyncio
import time
import sys


# if len(sys.argv) < 2:
#     print('wrong number of args')
#     sys.exit(1)

async def tcp_echo_client(loop):
    reader, writer = await asyncio.open_connection('127.0.0.1', 19564, loop=loop)
    try:
        message = 'IAMAT kiwi.cs.ucla.edu +34.068930-118.445127 1520023935.918963997\n' #\nWHATSAT kiwi.cs.ucla.edu 10 1'
        # message = 'WHATSAT kiwi.cs.ucla.edu 10 5\n'
        print('Send: %s' % message)
        writer.write(message.encode())
        await writer.drain()
        # writer.write_eof()
        
        while not reader.at_eof():
            data = await reader.read(50000)
            print('%s' % data.decode())
    except KeyboardInterrupt:
        print('Close the socket')
        writer.close()
        return
        
    

# message = input('') + ' ' + str(time.time())
loop = asyncio.get_event_loop()
loop.run_until_complete(tcp_echo_client(loop))
loop.close()