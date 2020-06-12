# A cross platform Python script to generate a user_data.bin file
# for the FOTA example.
import binascii
import struct
import sys
import socket

try:
    input = raw_input
except NameError:
    pass


def get_primary_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('10.255.255.255', 1))  # doesn't have to be reachable
        ip = s.getsockname()[0]
    except Exception:
        ip = '127.0.0.1'
    finally:
        s.close()
    return ip


default_host = get_primary_ip() + ':1883'

magic = 0x0a0cdcba
app = 'mqbl'
ssid = input('SSID: ').encode('ascii')
password = input('Password: ').encode('ascii')
print('Using the format: IPv4:PORT')
print('Leave blank for: ' + default_host)
host = input('Host: ')
if not host:
    host = default_host
mqtt_username = input('MQTT Username (leave blank for none): ').encode('ascii')
mqtt_password = input('MQTT Password (leave blank for none): ').encode('ascii')


ip, port = host.split(':', 1)
ip = socket.inet_aton(ip)
port = int(port)


filename = sys.argv[1] if len(sys.argv) > 1 else '0x70000.bin'
with open(filename, 'wb') as fp:
    settings = struct.pack('<I4s32s64s4sHxx64s64s',
                           magic, app, ssid, password, ip,
                           port, mqtt_username, mqtt_password)
    crc = binascii.crc32(settings) & 0xffffffff
    data = settings + struct.pack('<I', crc)
    data += b'\xff' * (4096 - len(data))
    fp.write(data)
