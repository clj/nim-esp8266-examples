import esp8266/crc
import esp8266/types


const
  magic = 0x0A0CDCBA'u32
  app = "wifi"


type
  WiFiSsid* = array[32, uint8]
  WiFiPassword* = array[64, uint8]
  WiFiCreds* {.packed.} = object
    ssid*: WiFiSsid
    password*: WiFiPassword
  Settings* {.packed.} = object
    magic*: uint32
    app: array[4, uint8]
    wifi*: WifiCreds
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
  import parseopt
  import streams
  import strutils

  import esp8266/types

  var
    data: Data
    ssid: string
    password: string
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
        password = optParser.val
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
  if password == "":
    stdout.write("Password: ")
    password = readLine(stdin)

  data.settings.magic = magic
  data.settings.app.setString(app)
  data.settings.wifi.ssid.setString(ssid)
  data.settings.wifi.password.setString(password)

  data.crc32 = crc32(data.settings)

  littleEndian32(addr data.settings.magic, addr data.settings.magic)
  littleEndian32(addr data.crc32, addr data.crc32)

  let padding = '\xff'.repeat(4096 - sizeof(data))

  let fp = open(dest, fmWrite)
  discard fp.writeBuffer(addr data, sizeof(data))
  fp.write(padding)
  fp.close()
