import esp8266/nonos-sdk/os_type
import esp8266/nonos-sdk/osapi
import esp8266/nonos-sdk/user_interface
import esp8266/default_user_rf_cal_sector_set


var
  timer: os_timer_t
  str: string


proc timer_fn(arg: pointer) {.cdecl.} =
  os_printf("Time: " & $system_get_time() & "\n")
  os_printf("Mem; system free heap: " & $system_get_free_heap_size() & "\n")
  if len(str) > 100:
    str = ""
  else:
    str &= "0123456789"
  os_printf(str & "\n")


proc nim_user_init() {.exportc.} =
  os_printf("\n\n")

  os_timer_setfn(addr timer, timer_fn, nil)
  os_timer_arm(addr timer, 1000, true)
