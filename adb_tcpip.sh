#!/bin/sh
adb connect 192.168.0.16 || adb tcpip 5555 || adb connect 192.168.0.16
adb devices
