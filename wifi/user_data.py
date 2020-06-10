# A cross platform Python script to generate a user_data.bin file
# for the WiFi example.
import binascii
import struct
import sys

try:
    input = raw_input
except NameError:
    pass

magic = 0x0a0cdcba
app = "wifi"
ssid = input('SSID: ').encode('ascii')
password = input('Password: ').encode('ascii')

filename = sys.argv[1] if len(sys.argv) > 1 else '0x70000.bin'
with open(filename, 'wb') as fp:
    settings = struct.pack('<I4s32s64s', magic, app, ssid, password)
    crc = binascii.crc32(settings) & 0xffffffff
    data = settings + struct.pack('<I', crc)
    data += b'\xff' * (4096 - len(data))
    fp.write(data)
