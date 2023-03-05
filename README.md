# Irrigation
Irrigation system based on Tasmota

Tasmota can be a very good base for own projects. It has support for a lot of sensors, has a nice easy WebUI, handles WiFi and MQTT and, as this writing, comes with Bluetooth support and Berry as programming language on ESP32 boards.

So why not try to build a plant watering system with it, that does not need a water tap or external electricity?

## Features
This is what it should have
+ WebUI to control watering timers and the number of seconds a pump should run
+ Use SR04 ultrasonic distance sensor to stop pumps when water container is empty so that there will be no damage to the pumps
+ Use MI Flora sensors to check if watering is necessary at all

## My system
is installed in a garden that has no electricity or town water.
+ It runs on a 30W solar panel with a cheap solar charger and a 20AH 12V battery
+ It has a 300 l water container that I fill from ground water (using an extra 230V pump)
+ It has 2 12V submerged pumps that water a tomato house and vegetable patch
+ It uses 2 Mi Flora sensors to check if watering is necessary
+ Is connected via WiFi and MQTT to my home

Please have a look at the [Wiki](https://github.com/RalfJL/Irrigation/wiki) for instructions to setup.

Picture will follow.
