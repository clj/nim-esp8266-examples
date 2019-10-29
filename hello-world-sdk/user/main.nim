import esp8266/nonos-sdk/osapi
import esp8266/types
import esp8266/default_user_rf_cal_sector_set


proc nim_user_init() {.exportc,section: SECTION_ROM.} =
    os_printf("\n\nHello world!\n\n")
