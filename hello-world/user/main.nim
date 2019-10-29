proc os_printf(formatstr: cstring) {.header: "<osapi.h>", importc, cdecl, varargs.}


proc nim_user_init() {.exportc.} =
    os_printf("\n\nHello world!\n\n")
