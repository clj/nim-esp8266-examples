import esp8266/nonos-sdk/os_type
import esp8266/nonos-sdk/osapi
import esp8266/nonos-sdk/user_interface
import esp8266/types
import esp8266/default_user_rf_cal_sector_set


var
  timer: os_timer_t
  obstack_reset = obstackPtr()

proc timer_fn(arg: pointer) {.cdecl, section: SECTION_ROM.} =
  os_printf("Time: " & $system_get_time() & "\n")
  os_printf("Mem; occupied:" & $getOccupiedMem() & ", free:" &
            $getFreeMem() & ", total:" & $getTotalMem() & "\n")
  setObstackPtr(obstack_reset)  # Deallocate everything since the last
                                # `obstack_reset = obstackPtr()` assignment


# There are a few other ways to work with the Regions GC, e.g. using:
# * withScratchRegion; or
# * withRegion
# but neither of these work in the current version of Nim (1.0.2). Example
# code of what this would look like if it worked is provided below.
#
# Ideally one could also get rid if the call to `obstackPtr()` in the
# declaration of `obstack_reset` above, but the type returned by `obstackPtr`
# and passed to `setObstackPtr` is not exported (and I don't know of a way
# to declare a variable of a non-exported type other than using assignment).


### withScratchRegion
#
# proc timer_fn(arg: pointer) {.cdecl, section: SECTION_ROM.} =
#   withScratchRegion:
#     os_printf("Time: " & $system_get_time() & "\n")
#     os_printf("Mem; occupied:" & $getOccupiedMem() & ", free:" &
#               $getFreeMem() & ", total:" & $getTotalMem() & "\n")


### withRegion
#
# var timer_region: MemRegion
#
# proc timer_fn(arg: pointer) {.cdecl, section: SECTION_ROM.} =
#   withRegion(timer_region):
#     os_printf("Time: " & $system_get_time() & "\n")
#     os_printf("Mem; occupied:" & $getOccupiedMem() & ", free:" &
#               $getFreeMem() & ", total:" & $getTotalMem() & "\n")


### With exported StackPtr type
#
# var obstack_reset: StackPtr
#
# proc timer_fn(arg: pointer) {.cdecl, section: SECTION_ROM.} =
#   os_printf("Time: " & $system_get_time() & "\n")
#   os_printf("Mem; occupied:" & $getOccupiedMem() & ", free:" &
#             $getFreeMem() & ", total:" & $getTotalMem() & "\n")
#   setObstackPtr(obstack_reset)


proc nim_user_init() {.exportc, section: SECTION_ROM.} =
  os_printf("\n\n")

  let dummy = $system_get_time()  # Force something to have been allocated
                                  # As setObstackPtr() is broken when nothing
                                  # is allocated by the time obstackPtr is
                                  # called
                                  # This is unnecessary if your program
                                  # happens to make allocations as a
                                  # side-effect of doing something useful

  obstack_reset = obstackPtr()  # Anything allocated before this call
                                # will be preserved even after calling
                                # setObstackPtr

  os_timer_setfn(addr timer, timer_fn, nil)
  os_timer_arm(addr timer, 1000, true)
