import esp8266/nonos-sdk/eagle_soc
import esp8266/nonos-sdk/gpio
import esp8266/nonos-sdk/os_type
import esp8266/nonos-sdk/osapi
import esp8266/pins
import esp8266/user_fns/default_user_rf_cal_sector_set
import esp8266/user_fns/user_pre_init


var
  led_timer: os_timer_t


const
  pin = 2


proc led_timer_fn(arg: pointer) {.cdecl.} =
  let value = get_pin_state(pin)
  pin_set(pin, not value)


proc nim_user_init() {.exportc.} =
  gpio_init()

  PIN_FUNC_SELECT(PERIPHS_IO_MUX_GPIO2_U, FUNC_GPIO2);
  pin_set(pin, 1)

  os_timer_setfn(addr led_timer, led_timer_fn, nil)
  os_timer_arm(addr led_timer, 1000, true)
