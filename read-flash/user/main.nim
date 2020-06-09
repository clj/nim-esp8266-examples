import esp8266/nonos-sdk/os_type
import esp8266/nonos-sdk/osapi
import esp8266/nonos-sdk/spi_flash
import esp8266/nonos-sdk/user_interface
import esp8266/user_fns/default_user_rf_cal_sector_set
import esp8266/user_fns/user_init
import esp8266/user_fns/user_pre_init


proc nim_user_init() {.exportc.} =
  var
    part_info: partition_item_t
    data: array[256, byte]

  block:
    let result = system_partition_get_item(partition_type_t(103), addr part_info)
    if not result:
      os_printf("system_partition_get_item returned an error")
      return

  block:
    let result = spi_flash_read(part_info.`addr`, addr data, uint32(len(data)))
    if result != SPI_FLASH_RESULT_OK:
      os_printf("spi_flash_read returned an error %d", result)
      return

  for i in countup(0, len(data) - 1, 16):
    os_printf("0x%08x  ", part_info.`addr` + uint(i))
    for j in i..i+15:
      let c = data[j]
      if c < 0x20 or c > 0x7E:
        os_printf(".")
      else:
        os_printf("%c", c)
    os_printf("\n")

