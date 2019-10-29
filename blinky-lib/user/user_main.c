#include "user_interface.h"

#include "nim_main.h"

void ICACHE_FLASH_ATTR
user_init()
{
    NimMain();
    nim_user_init();
}
