# Nim on the ESP8266 -- Example Code

[![Build Status](https://travis-ci.org/clj/nim-esp8266-examples.svg?branch=master)](https://travis-ci.org/clj/nim-esp8266-examples)

## Dependencies

* [Nim compiler](https://nim-lang.org)
* [esptool](https://github.com/espressif/esptool)
* xtensa-lx106 toolchain, e.g. from the [esp-open-sdk](https://github.com/pfalcon/esp-open-sdk)
* [Espressif ESP8266_NONOS_SDK](https://github.com/espressif/ESP8266_NONOS_SDK)
* [nim-esp8266-sdk](https://github.com/clj/nim-esp8266-sdk)

All examples, except for:

* hello-world
* panic

require the [nim-esp8266-sdk](https://github.com/clj/nim-esp8266-examples).

## Setting Up

The easiest way to get set up on all operating systems is to use a vagrant box bootstrapped by the [nim-esp8266-vagrant](https://github.com/clj/nim-esp8266-vagrant) vagrantfile.

### Linux

Install:

* [Nim compiler](https://nim-lang.org)
  - For example using [choosenim](https://github.com/dom96/choosenim)
* [esp-open-sdk](https://github.com/pfalcon/esp-open-sdk)
  - For use with the nim-esp8266-sdk installing with `make STANDALONE=n` is recommended
* [nim-esp8266-sdk](https://github.com/clj/nim-esp8266-examples)
  - Download the latest release from the [release](https://github.com/clj/nim-esp8266-examples/releases) page
* [Espressif ESP8266_NONOS_SDK](https://github.com/espressif/ESP8266_NONOS_SDK)
  - Check the [nim-esp8266-sdk](https://github.com/clj/nim-esp8266-examples) for supported versions if the Espressif NON-OS SDK

The esp-open-sdk comes with an old version of esptool; install [esptool](https://github.com/espressif/esptool) for Python 3 support and faster uploads.

### OS X/Windows/other

The pain of trying to build a dev environment is unlikely to be worth the effort. Just use the [nim-esp8266-vagrant](https://github.com/clj/nim-esp8266-vagrant) box or build your own Linux based dev environment.

## Compiling and Uploading

With everything set up correctly, `cd` into one of the example directories and type `make`.

The following make targets are available:

* `all` builds the firmware images (default)
* `flash` flashes an ESP (and builds the firmware images if necessary)
* `clean` cleans

With the following variables which can be set:

* `XTENSA_TOOLS_ROOT`
* `SDK_BASE`
* `NIM_SDK_BASE`
* `ESPPORT`
* `ESPTOOL_BAUD`

But see the top of the Makefiles for more info. Please note that the version of the SDK pointed to by `SDK_BASE` and `NIM_SDK_BASE` should agree.

It can be convenient to set the above as environment variables to avoid having to pass them to `make` on every invocation. For example, create a file called `nim-esp-build-setup.sh`, with the following contents (but update the paths as required for your system):

```
export XTENSA_TOOLS_ROOT=/opt/esp-open-sdk/xtensa-lx106-elf/bin
export SDK_BASE=/opt/ESP8266_NONOS_SDK-2.2.1
export NIM_SDK_BASE=/opt/nim-esp8266-sdk/2.2.1/
```

which you can then source into the shell from which building by calling `source nim-esp-build-setup.sh`, once, at the beginning of your session.

## Examples

The examples in this repository, listed roughly in increasing order of complexity

### Hello World

This example prints hello world on the serial console, at the default baud rate, use `miniterm.py /dev/ttyUSB0 74880` to view.

### Hello Nim SDK World

This example prints hello world on the serial console using the same wrapped ESP8266 NONOS SDK function as above, but wrapped using the nim-esp8266-sdk. Use `miniterm.py /dev/ttyUSB0 74880` to view.

### Panic

This example causes the running Nim program to panic and outputs a panic message on the console. Use `miniterm.py /dev/ttyUSB0 74880` to view.

### Blinky

This example blinks the LED on pin 2.

### Blinky Lib

Identical behaviour to Blinky, but uses a library to abstract the raw sdk pin functions.

### Garbage Collection: Regions

Shows how to enable and use the *Regions* garbage collector

**Note:** There are quite a few aspects of this garbage collector which does not work in the current version of Nim (1.0.2). See the source code for details.

### MQTT: Blinky

Blinks the LED on pin 2, but controllable via MQTT. A WiFi connection is required. See more information in the [mqtt-blinky example readme](mqtt-blinky/README.md).

## Troubleshooting

### rf_cal[0] !=0x05,is 0xFF

If the ESP8266 reboots repeatedly, displaying `rf_cal[0] !=0x05,is 0xFF`, then you need to flash the default init data onto the ESP:

* `esptool.py  write_flash ADDRESS esp_init_data_default_v08.bin`

At the following address, depending on the flash size:

* `0x7c000` for 512kB
* `0xfc000` for 1MB
* `0x1fc000` for 2MB
* `0x3fc000` for 4MB

The `esp_init_data_default_v08.bin` file can be found in the [Espressif ESP8266_NONOS_SDK](https://github.com/espressif/ESP8266_NONOS_SDK)s.

## License

The files in this repository are licensed under the MIT license, see the LICENSE file.

The Makefile has been adapted from https://github.com/esp8266/source-code-examples/blob/master/example.Makefile, this repository sadly has no explicit license (see [issue #8](https://github.com/esp8266/source-code-examples/issues/8)). The Nim related changes in these Makefiles are licensed under the MIT license.
