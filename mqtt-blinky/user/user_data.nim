import esp8266/crc
import esp8266/types


const
  magic = 0x0A0CDCBA'u32
  app = "mqbl"


type
  WiFiSsid* = array[32, uint8]
  WiFiPassword* = array[64, uint8]
  WiFiCreds* {.packed.} = object
    ssid*: WiFiSsid
    password*: WiFiPassword
  Mqtt* {.packed.} = object
    ip*: array[4, uint8]
    port*: uint16
    username* {.align(4).}: array[64, uint8]
    password* {.align(4).}: array[64, uint8]
  Settings* {.packed.} = object
    magic*: uint32
    app: array[4, uint8]
    wifi*: WifiCreds
    mqtt*: Mqtt
  Data* {.packed.} = object
    settings*: Settings
    crc32*: uint32


proc verify*(data: var Data): (bool, string) =
  if data.settings.magic != magic:
    return (false, "wrong magic")
  if data.settings.app != app.toArray(4, uint8):
    return (false, "wrong app")
  let crc = crc32(data.settings)
  if data.crc32 != crc:
    return (false, "bad crc")
  return (true, "")


when isMainModule:
  import endians
  import net
  import parseopt
  import streams
  import strutils

  import esp8266/types

  var
    data: Data
    ssid: string
    wifiPassword: string
    mqttUsername: string
    mqttPassword: string
    host: string
    dest = "user_data.bin"
    optParser = initOptParser()

  while true:
    optParser.next()
    case optParser.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      case optParser.key:
      of "ssid", "s":
        ssid = optParser.val
      of "password", "passwd", "pass", "p":
        wifiPassword = optParser.val
      of "host":
        host = optParser.val
      of "mqtt-username":
        mqttUsername = optParser.val
      of "mqtt-password":
        mqttPassword = optParser.val
      else:
        echo("Unknown option: ", optParser.key)
        quit(QuitFailure)
      if optParser.val == "":
        echo("Option: ", optParser.key, " takes one argument")
        quit(QuitFailure)
    of cmdArgument:
      dest = optParser.key

  if ssid == "":
    stdout.write("SSID: ")
    ssid = readLine(stdin)
  if wifiPassword == "":
    stdout.write("WiFi Password: ")
    wifiPassword = readLine(stdin)
  if host == "":
    let default_host = $getPrimaryIPAddr() & ":1883"
    stdout.write("Using the format: IPv4:PORT\n")
    stdout.write("Leave blank for: " & default_host & "\n")
    stdout.write("Host: ")
    host = readLine(stdin)
    if host == "":
      host = default_host
  if mqttUsername == "":
    stdout.write("MQTT Username (blank for none): ")
    mqttUsername = readLine(stdin)
  if mqttPassword == "":
    stdout.write("MQTT Password (blank for none): ")
    mqttPassword = readLine(stdin)

  var parts = host.split(':', 1)
  let ip = parseIpAddress(parts[0])
  let port = parts[1].parseUInt()

  data.settings.magic = magic
  data.settings.app.setString(app)
  data.settings.wifi.ssid.setString(ssid)
  data.settings.wifi.password.setString(wifiPassword)
  data.settings.mqtt.ip = ip.address_v4
  data.settings.mqtt.port = uint16(port)
  data.settings.mqtt.username.setString(mqttUsername)
  data.settings.mqtt.password.setString(mqttPassword)
  data.crc32 = crc32(data.settings)

  littleEndian32(addr data.settings.magic, addr data.settings.magic)
  littleEndian32(addr data.settings.mqtt.port, addr data.settings.mqtt.port)
  littleEndian32(addr data.crc32, addr data.crc32)

  let padding = '\xff'.repeat(4096 - sizeof(data))

  let fp = open(dest, fmWrite)
  discard fp.writeBuffer(addr data, sizeof(data))
  fp.write(padding)
  fp.close()
