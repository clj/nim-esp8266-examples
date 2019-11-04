proc os_printf(formatstr: cstring) {.header: "<osapi.h>", importc, cdecl, varargs.}
proc system_soft_wdt_feed() {.header: "<user_interface.h>", importc, cdecl.}

{.push stack_trace: off, profiler:off.}

proc rawoutput(s: string) =
    os_printf("\r\npanic: %s\r\n", s)

proc panic(s: string) {.noreturn.} =
    rawoutput(s)

    while true:
      system_soft_wdt_feed()

{.pop.}
