import strutils  # Only used in the const section below to set ip and port

import esp8266/nonos-sdk/espconn
import esp8266/nonos-sdk/os_type
import esp8266/nonos-sdk/osapi
import esp8266/nonos-sdk/upgrade
import esp8266/nonos-sdk/user_interface
import esp8266/types
import esp8266/user_fns/default_user_rf_cal_sector_set
import esp8266/user_fns/user_init
import esp8266/user_fns/user_pre_init


const
  WIFI_SSID {.strdefine.} = ""
  WIFI_PASSWD {.strdefine.} = ""
  UPDATE_SERVER {.strdefine.} = ""
  UPDATE_PREFIX {.strdefine.} = "/firmware/"


when WIFI_SSID == "" or WIFI_PASSWD == "" or UPDATE_SERVER == "":
  {.fatal: "Please set WIFI_SSID, WIFI_PASSWD, and UPDATE_SERVER".}


const
  port: uint16 = static: (uint16)UPDATE_SERVER.split(':', 2)[1].parseUInt()
  ip: array[4, uint8] = static:
    var ip: array[4, uint8]
    var octets = UPDATE_SERVER.split(':', 2)[0].split('.', 4)
    for i, octet in octets:
      ip[i] = (uint8)octet.parseUInt()
    ip


var
  timer: os_timer_t
  url: string
  conn: espconn
  update: upgrade_server_info
  count = 10


proc timer_fn(arg: pointer) {.cdecl.}


proc ota_finished_callback(arg: pointer) {.cdecl.} =
  var update = cast[ptr upgrade_server_info](arg)
  if update.upgrade_flag != 0:
    os_printf("\nFOTA success: rebooting!\n")
    system_upgrade_reboot()
  else:
    os_printf("\nFOTA failed!\n")
    os_printf("Trying again in:\n")
    count = 10
    os_timer_disarm(addr timer)
    os_timer_setfn(addr timer, timer_fn, nil)
    os_timer_arm(addr timer, 1000, true)


proc start_update() =
  os_printf("\n\n")

  var user_bin: string
  if system_upgrade_userbin_check() == 0:
    user_bin = "user2.bin"
  else:
    user_bin = "user1.bin"

  url = ("GET " & UPDATE_PREFIX & user_bin & " HTTP/1.1\r\n" &
         "Host: " & UPDATE_SERVER & "\r\n" &
         "Connection: close\r\n" &
         "\r\n")
  update.pespconn = addr conn
  update.ip = ip
  update.port = port
  update.check_cb = ota_finished_callback
  update.check_times = 10000
  update.url = cast[ptr uint8](cstring(url))

  if system_upgrade_start(addr update) == false:
   os_printf("Could not start upgrade\n")
  else:
   os_printf("Upgrading...\n")


proc timer_fn(arg: pointer) {.cdecl.} =
  if count == 0:
    os_timer_disarm(addr timer)
    os_printf("0!")
    start_update()
  else:
    os_printf("%d..", count)
    count -= 1


proc wifi_connect_handle_event_cb(event: ptr System_Event_t) {.cdecl.} =
  case event.event:
  of EVENT_STAMODE_GOT_IP:
    os_timer_disarm(addr timer)
    os_timer_setfn(addr timer, timer_fn, nil)
    os_timer_arm(addr timer, 1000, true)
  of EVENT_STAMODE_DISCONNECTED:
    os_timer_disarm(addr timer)
  else:
    discard


proc wifi_setup() =
    wifi_set_event_handler_cb(wifi_connect_handle_event_cb)

    let wifi_opmode = wifi_get_opmode_default()
    if wifi_opmode != uint8(STATION_MODE):
      os_printf("Setting Wifi mode to station mode\r\n")
      discard wifi_set_opmode(uint8(STATION_MODE))

    var new_config: station_config
    new_config.bssid_set = 0
    new_config.ssid.set_string(WIFI_SSID)
    new_config.password.set_string(WIFI_PASSWD)
    discard wifi_station_set_config(addr new_config)
    discard wifi_station_set_auto_connect((uint8)true)
    discard wifi_station_ap_number_set(5)

    if wifi_station_get_connect_status() == 0:
      discard wifi_station_connect()

    os_printf("Updated station config...\n\r")


proc app_init() {.cdecl.} =
  os_printf("\n\n")

  wifi_setup()

  os_printf("system_upgrade_userbin_check: %d\n", system_upgrade_userbin_check())
  os_printf("upgrade server: %s\n", UPDATE_SERVER)
  os_printf("compile timestamp: %sT%sZ\n", CompileDate, CompileTime)


proc nim_user_init() {.exportc.} =
  system_init_done_cb(app_init)
