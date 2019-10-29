#include "user_interface.h"
#include "c_types.h"
#include "spi_flash.h"

#include "nim_main.h"

void ICACHE_FLASH_ATTR
user_init()
{
    NimMain();
    nim_user_init();
}

// Source: https://github.com/pfalcon/esp-open-sdk/blob/e629109c762b505839cb2a06763f8615447e6e67/user_rf_cal_sector_set.c
// License: https://github.com/pfalcon/esp-open-sdk/tree/e629109c762b505839cb2a06763f8615447e6e67#license
uint32 user_rf_cal_sector_set(void) {
    extern char flashchip;
    SpiFlashChip *flash = (SpiFlashChip*)(&flashchip + 4);
    uint32_t sec_num = flash->chip_size >> 12;
    return sec_num - 5;
}
