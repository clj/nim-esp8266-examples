import strutils

import esp8266/mqtt
import esp8266/nonos-sdk/eagle_soc
import esp8266/nonos-sdk/gpio
import esp8266/nonos-sdk/os_type
import esp8266/nonos-sdk/osapi
import esp8266/nonos-sdk/user_interface
import esp8266/pins
import esp8266/types
import esp8266/user_fns/default_user_rf_cal_sector_set
import esp8266/user_fns/user_init
import esp8266/user_fns/user_pre_init


const
  WIFI_SSID {.strdefine.} = "changeme"
  WIFI_PASSWD {.strdefine.} = "changeme"
  MQTT_BROKER_IP {.strdefine.} = "changeme"
  MQTT_BROKER_PORT {.intdefine.} = 1883
  MQTT_USER {.strdefine.} = nil
  MQTT_PASSWD {.strdefine.} = nil
  pin = 2
  states = ["off", "on"]

var
  mqtt_client: MQTT_Client
  led_timer: os_timer_t
  state_topic: string
  ctrl_topic: string


proc mac_address(): string =
  var
    mac: array[6, uint8]
  discard wifi_get_macaddr(0, cast[ptr uint8](addr mac))
  for i in 0..<len(mac):
    result &= toHex(mac[i])


proc led_timer_fn(arg: pointer) {.cdecl.} =
  let state = get_pin_state(pin)
  discard MQTT_Publish(addr mqtt_client, state_topic, states[state], 0, 0)
  pin_set(pin, state)


proc mqtt_connected_cb(client: ptr MQTT_Client) {.cdecl.} =
  discard MQTT_Subscribe(client, "blinky", 0)
  discard MQTT_Subscribe(client, ctrl_topic, 0)


proc mqtt_data_cb(client: ptr MQTT_Client; topic_cstring: cconststring; topic_len: uint32;
                  data_cstring: cconststring; data_len: uint32) {.cdecl.} =
  var topic = new_mqtt_data_string(topic_cstring, topic_len)
  var data = new_mqtt_data_string(data_cstring, data_len)
  if topic == "blinky" or topic == ctrl_topic:
    if data == "on":
      os_timer_disarm(addr led_timer)
      discard MQTT_Publish(client, state_topic, "on", 0, 0)
      pin_set(pin, 1)
    elif data == "off":
      os_timer_disarm(addr led_timer)
      discard MQTT_Publish(client, state_topic, "off", 0, 0)
      pin_set(pin, 0)
    elif data == "blink":
      os_timer_disarm(addr led_timer)
      os_timer_setfn(addr led_timer, led_timer_fn, nil)
      os_timer_arm(addr led_timer, 1000, true)


proc wifi_connect_handle_event_cb(event: ptr System_Event_t) {.cdecl.} =
  case event.event:
  of EVENT_STAMODE_GOT_IP:
    MQTT_InitConnection(addr mqtt_client, MQTT_BROKER_IP, MQTT_BROKER_PORT, 0)
    discard MQTT_InitClient(addr mqtt_client, mac_address(), MQTT_USER, MQTT_PASSWD, 120, 1)
    MQTT_Connect(addr mqtt_client)
    MQTT_OnConnected(addr mqtt_client, mqtt_connected_cb)
    MQTT_OnData(addr mqtt_client, mqtt_data_cb)
  else:
    MQTT_Disconnect(addr mqtt_client)


proc wifi_setup() {. section: SECTION_ROM .} =
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

    os_printf("Updated station config...\n\r")


proc app_init() {.cdecl.} =
  os_printf("\n\n")

  gpio_init()
  PIN_FUNC_SELECT(PERIPHS_IO_MUX_GPIO2_U, FUNC_GPIO2);
  pin_set(pin, 0)

  ctrl_topic = "blinky/" & mac_address()
  state_topic = ctrl_topic & "/state"

  wifi_setup()


proc nim_user_init() {.exportc.} =
  system_init_done_cb(app_init)
