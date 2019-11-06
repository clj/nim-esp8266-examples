# MQTT Blinky

An MQTT controlled firmware that blinks an LED!

The code in this example builds on the following other examples:

* blinkly-lib

* gc-regions

## Building

A number of Makefile variables can be used to configure the application. Defaults will be used if nothing is specified, but then the firmware will not be able to connect to WiFi  or an MQTT server.

Variables:

- `WIFI_SSID`

- `WIFI_PASSWD`

- `MQTT_BROKER_IP`

- `MQTT_BROKER_PORT`

- `MQTT_USER`

- `MQTT_PASSWD`

The WiFi password can be left blank if for open networks. The MQTT broker port can be left blank if using the default port of 1883. The MQTT user name and password can be left blank if no user name and password is required to connect to the MQTT server.

To compile and upload the firmware:

```
$ make WIFI_SSID=blinky MQTT_BROKER_IP=192.168.1.10 flash
```

These can also be set as environment variables to avoid having to remember to pass them on every `make` invocation.

## MQTT

### Controlling

The firmware will connect to the configured MQTT server and listen on the following topics:

1. `blinky`

2. `blinky/<MAC_ADDR>`

to which `on`, `off`, or `blink` can be sent. The first topic will control all connected mqtt-blinky devices, where as the second will control a specific device addressed by its WiFi MAC address.

### Status

In case you can't see it, the current status of the LED of an mqtt-blinky device is published to:

* `blinky/<MAC_ADDR>/sate`

as either `on` or `off`.

### Example

You should be able to use any MQTT server to control the blinky, this example shows how to control it using [Mosquitto](https://mosquitto.org).

#### Installing Mosquitto

On Mac OS X:

```
$ brew cask install mosquitto
```

Debian:

```
$ apt install mosquitto mosquitto-clients
```

#### Running a Mosquitto Server

Using the default port 1883:

```
OS X:  $ /usr/local/sbin/mosquitto
Linux: $ /usr/sbin/mosquitto
```

Using a custom port if, for example, another application is already using port 1883:

```
OS X:  $ /usr/local/sbin/mosquitto -p PORT
Linux: $ /usr/sbin/mosquitto -p PORT
```

#### Controlling the Blinky

Sending an on message on the default MQTT port:

```shell
$ mosquitto_pub -t blinky -m on
```

Sending a message on a custom port:

```
$ mosquitto_pub -p PORT -t blinky -m on
```

Tell a specific blinky (with MAC address: 0xD1CEDCO1DICE) to start blinking:

```
$ mosquitto_pub -t blinky/D1CEDCO1DICE -m blink
```

#### Observing the State

Listen to all topics on the default MQTT port:

```
$ mosquitto_sub -v -t "#"
```

Listen to all topics on a custom port:

```
mosquitto_sub -p PORT -v -t "#"
```

Listen to a specific blinky's (with MAC address: 0xD1CEDCO1DICE) state topic:

```
mosquitto_sub -t blinky/D1CEDCO1DICE/state
```
