import strutils

import esp8266/nonos-sdk/espconn
import esp8266/nonos-sdk/os_type
import esp8266/nonos-sdk/osapi
import esp8266/nonos-sdk/spi_flash
import esp8266/nonos-sdk/upgrade
import esp8266/nonos-sdk/user_interface
import esp8266/types
import esp8266/user_fns/default_user_rf_cal_sector_set
import esp8266/user_fns/user_init
import esp8266/user_fns/user_pre_init

import user_data


var
  data: Data
  wifi_config: station_config
  update: upgrade_server_info
  conn: espconn
  timer: os_timer_t
  url: string
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


proc updateHost(): string =
  return join(data.settings.fota.ip, ".") & ":" & $data.settings.fota.port


proc updatePath(): string =
  # Lets hope there is still a terminating null char :)
  return $cast[cstring](addr data.settings.fota.path)


proc start_update() =
  os_printf("\n\n")

  var user_bin: string
  if system_upgrade_userbin_check() == 0:
    user_bin = "user2.bin"
  else:
    user_bin = "user1.bin"

  url = ("GET " & updatePath() & user_bin & " HTTP/1.1\r\n" &
         "Host: " & updateHost() & "\r\n" &
         "Connection: close\r\n" &
         "\r\n")
  update.pespconn = addr conn
  update.ip = data.settings.fota.ip
  update.port = data.settings.fota.port
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

  discard wifi_set_opmode(uint8(STATION_MODE))
  wifi_config.bssid_set = 0
  wifi_config.ssid = data.settings.wifi.ssid
  wifi_config.password = data.settings.wifi.password
  discard wifi_station_set_config(addr wifi_config)
  discard wifi_station_set_auto_connect((uint8)false)
  discard wifi_station_ap_number_set(0)


proc app_init() {.cdecl.} =
  os_printf("\n\n")
  os_printf("system_upgrade_userbin_check: %d\n", system_upgrade_userbin_check())
  os_printf("upgrade server: %s%s\n", updateHost(), updatePath())
  os_printf("compile timestamp: %sT%sZ\n", CompileDate, CompileTime)
  os_printf("\n\n")

  discard wifi_station_connect()


proc nim_user_init() {.exportc.} =
  os_printf("\n\n")

  var
    part_info: partition_item_t

  block:
    let result = system_partition_get_item(partition_type_t(100),
        addr part_info)
    if not result:
      os_printf("system_partition_get_item returned an error\n")
      return

  block:
    let result = spi_flash_read(part_info.`addr`, addr data, uint32(sizeof(data)))
    if result != SPI_FLASH_RESULT_OK:
      os_printf("spi_flash_read returned an error %d\n", result)
      return

  let (ok, msg) = data.verify()
  if ok:
    wifi_setup()

    system_init_done_cb(app_init)
  else:
    os_printf(
      "No valid user data found: %s\n" &
      "please upload valid data to flash @0x%08x\n",
      msg, part_info.`addr`)
