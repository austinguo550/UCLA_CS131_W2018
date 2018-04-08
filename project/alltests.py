import time
import json
import unicodedata
import datetime
import uuid
import asyncio
import unittest
import os
import subprocess

### CHANGE THESE PORT NUMBERS!!!
SERVER_PORT_MAP = {
    'Alford': 8999,
    'Hamilton': 8998,
    'Welsh': 8994,
    'Ball': 8996,
    'Holiday': 8995,
}


async def communicate_with(server_name, command):
    loop = asyncio.get_event_loop()
    reader, writer = await asyncio.open_connection('127.0.0.1', SERVER_PORT_MAP[server_name],
                                                   loop=loop)
    writer.write(command)
    await writer.drain()
    data = await reader.read()
    writer.close()
    return data


def do_communicate(server_name, command):
    loop = asyncio.get_event_loop()
    r = loop.run_until_complete(communicate_with(server_name, command))
    return r


class ServerHerdTest(unittest.TestCase):

    def test_correct_IAMAT_response(self):
        client_id = uuid.uuid4().hex
        my_time_stamp = "%.9f" % datetime.datetime.now().timestamp()
        rr = do_communicate('Alford', b'IAMAT %s +34.068930-118.445127 %b\n' % (client_id.encode(),
                                                                                my_time_stamp.encode()))
        r = rr.decode()
        self.assertEqual(r[-1], '\n', "ends with newline")
        rs = r.split()
        self.assertEqual(r.count('\n'), 1, "should have exactly one newline")
        self.assertEqual(len(rs), 6, "should have six whitespace-separated components")
        self.assertEqual(rs[0], 'AT', "first component should be AT")
        self.assertEqual(rs[1], 'Alford', "second component should be Alford")
        time_diff = float(rs[2])
        self.assertGreaterEqual(time_diff, 0.0, "time difference should be positive")
        self.assertEqual(rs[3], client_id)
        self.assertEqual(rs[4], '+34.068930-118.445127')
        self.assertEqual(rs[5], my_time_stamp)

    def check_question_mark_space_original(self, bad, explanation):
        rr = do_communicate("Ball", bad)
        self.assertEqual(rr, b'? ' + bad, explanation)

    def check_starts_with_AT(self, req, explanation):
        rr = do_communicate("Holiday", req)
        self.assertEqual(rr[:3], b'AT ', explanation)

    def test_weird_IAMAT(self):
        self.check_question_mark_space_original(b'LLL\n', "should reject random bad string")
        self.check_question_mark_space_original(b'IAMTA kiwi +34.068930-118.445127 1479413884.392014450\n',
                                                "should reject misspelled IAMAT")
        self.check_question_mark_space_original(b'IAMAT ki wi +34.068930-118.445127 1479413884.392014450\n',
                                                "should reject spaces within client ID")
        self.check_question_mark_space_original(b'IAMAT kiwi 34.068930-118.445127 1479413884.392014450\n',
                                                "should reject coordinates without plus")
        self.check_question_mark_space_original(b'IAMAT kiwi -118.445127 1479413884.392014450\n',
                                                "should reject coordinates with only one negative number")
        self.check_question_mark_space_original(b'IAMAT kiwi +18.445127 1479413884.392014450\n',
                                                "should reject coordinates with only one positive number")
        self.check_question_mark_space_original(b'IAMAT kiwi Los_Angeles 1479413884.392014450\n',
                                                "should reject alphabetical coordinates ")
        self.check_question_mark_space_original(b'IAMAT kiwi +34-118 1479413884.392014450\n',
                                                "should reject coordinates of insufficient precision")
        self.check_question_mark_space_original(b'IAMAT ki wi +34.068930-118.445127 NOW\n',
                                                "should reject alphabetical timestamp")
        self.check_question_mark_space_original(b'IAMAT kiwi +34.060000-118.000000 -1479413884.392014450\n',
                                                "should reject negative timestamps")
        self.check_question_mark_space_original(b'IAMAT kiwi +34.060000-118.000000 -1479413884.392014450 HELLO\n',
                                                "should reject IAMAT with extraneous field")

        self.check_starts_with_AT(b'IAMAT %b +34.060000-118.000000 1479413884.392014450\n' % u"\u00e9tudiant".encode(),
                                  "should accept IAMAT with Unicode client ID (NFC)")
        self.check_starts_with_AT(
            b'IAMAT %b +34.060000-118.000000 1479413884.392014450\n' % unicodedata.normalize('NFD',
                                                                                             u'\u00e9tudiant').encode(),
            "should accept IAMAT with Unicode client ID (NFD)")
        self.check_starts_with_AT(
            b'IAMAT %b +34.060000-118.000000 1479413884.392014450\n' % unicodedata.normalize('NFC',
                                                                                             u'\U0001f602').encode(),
            "should accept Emoji as client ID")
        # self.check_starts_with_AT(
        #     b'IAMAT \xff +34.060000-118.000000 1479413884.392014450\n',
        #     "should accept invalid UTF-8 as client ID")

    def test_whatsat(self):
        client_id = uuid.uuid4().hex
        my_time_stamp = "%.9f" % datetime.datetime.now().timestamp()
        at = do_communicate('Hamilton',
                            b'IAMAT %s +34.068930-118.445127 %b\n' % (client_id.encode(), my_time_stamp.encode()))
        rr = do_communicate('Hamilton', b'WHATSAT %s 1 10\n' % (client_id.encode()))
        lines = rr.split(b'\n')
        self.assertGreater(len(lines), 1, "should have more than one line of output")
        self.assertEqual(lines[0].rstrip(), at.rstrip(), "first line should be identical to previous AT response")
        decoded = json.loads(b''.join(lines[1:]).decode())
        self.assertEqual(decoded['status'], 'OK', "status in JSON should be OK")
        self.assertLessEqual(len(decoded['results']), 10, "should have at most 1 response")

    def test_bad_whatsat(self):
        client_id = uuid.uuid4().hex
        my_time_stamp = "%.9f" % datetime.datetime.now().timestamp()
        do_communicate('Welsh', b'IAMAT %s +34.068930-118.445127 %b\n' % (client_id.encode(), my_time_stamp.encode()))
        self.check_question_mark_space_original(b'WHATSAT\n', "should reject WHATSAT with missing components")
        self.check_question_mark_space_original(b'WHATSAT %b\n' % client_id.encode(),
                                                "should reject WHATSAT with missing components")
        self.check_question_mark_space_original(b'WHATSAT %b 2\n' % client_id.encode(),
                                                "should reject WHATSAT with missing components")
        self.check_question_mark_space_original(b'WHATSAT %b 1000 1\n' % client_id.encode(),
                                                "should reject WHATSAT with large radius")
        self.check_question_mark_space_original(b'WHATSAT %b 1 1000\n' % client_id.encode(),
                                                "should reject WHATSAT with large limit")
        self.check_question_mark_space_original(b'WHATSAT %b -10 10\n' % client_id.encode(),
                                                "should reject WHATSAT with negative radius")
        self.check_question_mark_space_original(b'WHATSAT %b 10 -10\n' % client_id.encode(),
                                                "should reject WHATSAT with negative limit")
        self.check_question_mark_space_original(b'WHATSAT hello 10 -10\n',
                                                "should reject WHATSAT with unknown client ID")
        self.check_question_mark_space_original(b'WHATSAT %b r 10\n' % client_id.encode(),
                                                "should reject WHATSAT with alphabetical radius")
        self.check_question_mark_space_original(b'WHATSAT %b 10 l\n' % client_id.encode(),
                                                "should reject WHATSAT with alphabetical limit")

    def test_duplicate_iamat_handling(self):
        client_id = uuid.uuid4().hex
        now = datetime.datetime.now().timestamp()
        my_time_stamp = "%.9f" % now
        first_at = do_communicate('Holiday',
                                  b'IAMAT %s +34.068930-118.445127 %b\n' % (client_id.encode(), my_time_stamp.encode()))
        second_at = do_communicate('Holiday', b'IAMAT %s +34.068930-118.445127 %b\n' % (
            client_id.encode(), ("%.9f" % (now - 1000)).encode()))
        self.assertEqual(second_at, first_at, "should ignore location update with earlier timestamp")
        third_at = do_communicate('Holiday', b'IAMAT %s +34.068930-118.445127 %b\n' % (
            client_id.encode(), ("%.9f" % (now + 1000)).encode()))
        self.assertNotEqual(third_at, first_at, "should accept location update with later timestamp")

    def test_basic_location_propagation(self):
        client_id = uuid.uuid4().hex
        now = datetime.datetime.now().timestamp()
        my_time_stamp = "%.9f" % now
        first_at = do_communicate('Alford', b'IAMAT %s +34.068930-118.445127 %b\n' % (
            client_id.encode(), my_time_stamp.encode())).rstrip()
        time.sleep(0.5) # allow some time for location information to be propagated
        second_at = do_communicate('Ball', b'WHATSAT %s 1 1\n' % (client_id.encode())).split(b'\n')[0].rstrip()
        self.assertEqual(second_at, first_at, "Ball should answer WHATSAT queries using location info from Alford")
        third_at = do_communicate('Holiday', b'WHATSAT %s 1 1\n' % (client_id.encode())).split(b'\n')[0].rstrip()
        self.assertEqual(third_at, first_at, "Holiday should answer WHATSAT queries using location info from Alford")
        fourth_at = do_communicate('Hamilton', b'WHATSAT %s 1 1\n' % (client_id.encode())).split(b'\n')[0].rstrip()
        self.assertEqual(fourth_at, first_at, "Hamilton should answer WHATSAT queries using location info from Alford")
        fifth_at = do_communicate('Welsh', b'WHATSAT %s 1 1\n' % (client_id.encode())).split(b'\n')[0].rstrip()
        self.assertEqual(fifth_at, first_at, "Welsh should answer WHATSAT queries using location info from Alford")


def main():
    os.environ['TZ'] = 'UTC'
    print("Will start automated testing")
    unittest.main(verbosity=2, failfast=True)


if __name__ == '__main__':
    main()
