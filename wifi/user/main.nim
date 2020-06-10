import esp8266/nonos-sdk/os_type
import esp8266/nonos-sdk/osapi
import esp8266/nonos-sdk/spi_flash
import esp8266/nonos-sdk/user_interface
import esp8266/types
import esp8266/user_fns/default_user_rf_cal_sector_set
import esp8266/user_fns/user_init
import esp8266/user_fns/user_pre_init

import user_data

var wifi_config: station_config


proc wifi_connect_handle_event_cb(event: ptr System_Event_t) {.cdecl.} =
  case event.event:
  of EVENT_STAMODE_CONNECTED:
    os_printf("WiFi connected\n")
  of EVENT_STAMODE_GOT_IP:
    os_printf("Got an IP address\n")
  of EVENT_STAMODE_DISCONNECTED:
    os_printf("WiFi disconnected\n")
  else:
    discard


proc wifi_setup(ssid: WiFiSsid, password: WiFiPassword) =
  wifi_set_event_handler_cb(wifi_connect_handle_event_cb)

  discard wifi_set_opmode(uint8(STATION_MODE))
  wifi_config.bssid_set = 0
  wifi_config.ssid = ssid
  wifi_config.password = password
  discard wifi_station_set_config(addr wifi_config)
  discard wifi_station_set_auto_connect((uint8)false)
  discard wifi_station_ap_number_set(0)


proc app_init() {.cdecl.} =
  discard wifi_station_connect()


proc nim_user_init() {.exportc.} =
  var
    part_info: partition_item_t
    data: Data

  block:
    let result = system_partition_get_item(partition_type_t(103),
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
    wifi_setup(data.settings.wifi.ssid, data.settings.wifi.password)

    system_init_done_cb(app_init)
  else:
    os_printf(
      "No valid user data found: %s\n" &
      "please upload valid data to flash @0x%08x\n",
      msg, part_info.`addr`)
