import esp8266/nonos-sdk/osapi
import esp8266/user_fns/default_user_rf_cal_sector_set
import esp8266/user_fns/user_init
import esp8266/user_fns/user_pre_init


proc nim_user_init() {.exportc.} =
    os_printf("\n\nHello world!\n\n")
