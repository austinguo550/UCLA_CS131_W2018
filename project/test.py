import asyncio.subprocess
import os
import os.path
import sys

ALL_SERVERS = ['Alford', 'Ball', 'Hamilton', 'Holiday', 'Welsh']


def write_color_coded(color: int, name: str, output: bytes) -> None:
    sys.stdout.buffer.write(bytes([0x1b, 0x5b, 0x33, 0x31 + color, 0x6d]))
    sys.stdout.buffer.write(("% 8s" % name).encode('utf-8'))
    sys.stdout.buffer.write(bytes([0x1b, 0x5b, 0x30, 0x6d, 0x20]))
    sys.stdout.buffer.write(output)
    sys.stdout.buffer.flush()


async def read_subprocess_output(proc, i, server_name, pipe_type):
    while True:
        if proc.returncode is not None:
            write_color_coded(5, 'tester',
                              f'{server_name} terminated unexpectedly with code {proc.returncode}\n'.encode())
            break
        output = await getattr(proc, pipe_type).readline()
        if not output:
            write_color_coded(5, 'tester',
                              f'{pipe_type} pipe to {server_name} closed unexpectedly; its return code is {proc.returncode}\n'.encode())
            break
        write_color_coded(i, server_name, output)


async def run_servers():
    server_py = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'server.py')
    procs = []
    for server_name in ALL_SERVERS:
        c = asyncio.create_subprocess_exec(sys.executable, '-u', server_py,
                                           server_name,
                                           stderr=asyncio.subprocess.PIPE,
                                           stdout=asyncio.subprocess.PIPE)
        procs.append((server_name, await c))

    for i, (server_name, proc) in enumerate(procs):
        asyncio.ensure_future(read_subprocess_output(proc, i, server_name, 'stdout'))
        asyncio.ensure_future(read_subprocess_output(proc, i, server_name, 'stderr'))


def main():
    write_color_coded(5, 'tester', b'Starting servers interactively\n')
    loop = asyncio.get_event_loop()
    asyncio.ensure_future(run_servers())
    try:
        loop.run_forever()
    except KeyboardInterrupt:
        write_color_coded(5, 'tester', b'Stopping servers\n')
        pass


if __name__ == "__main__":
    main()
