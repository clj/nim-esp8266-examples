import esp8266/nonos-sdk/eagle_soc
import esp8266/nonos-sdk/gpio
import esp8266/nonos-sdk/os_type
import esp8266/nonos-sdk/osapi
import esp8266/types
import esp8266/default_user_rf_cal_sector_set


var
  led_timer: os_timer_t


const
  pin = 2


proc led_timer_fn(arg: pointer) {.cdecl, section: SECTION_ROM.} =
  let value = (GPIO_REG_READ(GPIO_OUT_ADDRESS) and uint32(1 shl pin)) shr pin
  gpio_output_set(uint32((not value) shl pin),
                  uint32(value shl pin),
                  uint32(1 shl pin), 0)


proc nim_user_init() {.exportc, section: SECTION_ROM.} =
  gpio_init()

  PIN_FUNC_SELECT(PERIPHS_IO_MUX_GPIO2_U, FUNC_GPIO2);
  gpio_output_set(0, uint32(1 shl pin), uint32(1 shl pin), 0)

  os_timer_setfn(addr led_timer, led_timer_fn, nil)
  os_timer_arm(addr led_timer, 1000, true)
