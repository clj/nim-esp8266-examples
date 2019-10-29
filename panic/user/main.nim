var
    v: int8


proc nim_user_init() {.exportc.} =
    v = high(int8)
    inc v
