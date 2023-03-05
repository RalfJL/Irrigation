import webserver
import string
import json

# webtext water container is empty at xx cm
var container_empty_text = "{s}Fass leer bei{m}%i cm{e}"
var container_empty_distance = 100
# set default if empty
if tasmota.cmd("Mem1").item("Mem1") == "" 
	tasmota.cmd(string.format("Mem1 %i", container_empty_distance));
end
container_empty_distance =  number(tasmota.cmd("Mem1").item("Mem1"))
# webtext: moisture threshold in %
var moist_threshold_text = "{s}Feuchtegrenze {m}%i %%{e}"
var moisture_trheshold = 50

var flora_pump1 = "Flora892404"
var flora_pump1_moisture = 0
# Webtext for Pump1: pump duration in seconds
var pump1_duration_text = "{s}Pumpdauer %i{m}%i Sekunden{e}"
var flora_pump1_text ="{s}Flora Pumpe %i{m}%s"

var flora_pump2 = "Flora892AF8"
var flora_pump2_moisture = 0
# webtext: pumduration 2 in seconds
var pump2_duration_text = "{s}Pumpdauer %i{m}%i Sekunden{e}"
var flora_pump2_text ="{s}Flora Pumpe %i{m}%s"

#######
#var distance_sensor = "VL53L0X"
var distance_sensor = "SR04"

# calculate runtime of the pump
def calc_runtime(value)
	if value <= 10
		return value*10
	else
		return 100+value
	end
end

##########################################
########## Webinterface ##################
#-
# webinterface for pump values
# values[0-1] are the relais of the pump
# values[2-3] are the runtime of a pump in seconds after which the pump is turned off
# value[4]    is the moisture level threshold; pump will only start if the moisture is below that threshold
-#
class IrrigationWeb : Driver
	var values

 def init()
	self.values = list(1, 2, 3, 4, 5, 6, 7, 8)
	self.values[2] = tasmota.cmd("Channel3").item("Channel3") # duration pump 1
	self.values[3] = tasmota.cmd("Channel4").item("Channel4") # duration pump 2
	self.values[4] = tasmota.cmd("Channel5").item("Channel5") # max distance of water tank
	self.values[5] = flora_pump1 # flora pump 1
	self.values[6] = flora_pump2 # flora pump2
 end
 
 # set values that sahl be shown
 def set(sensorid, value)
	self.values[sensorid] = value
 end 
	
 def web_sensor(sensorid, value)
	#values[sensorid] = value
	#tasmota.log(string.format("web_sensor: sensorid %i, value ", sensorid, value))
	webserver.content_send("{s}--------------------------{m}----------")
	webserver.content_send(string.format(pump1_duration_text, 1, self.values[2]))
	webserver.content_send(string.format(flora_pump1_text, 1, self.values[5]))
	webserver.content_send(string.format(pump2_duration_text, 2, self.values[3]))
	webserver.content_send(string.format(flora_pump1_text, 2, self.values[6]))
	webserver.content_send(string.format(container_empty_text, container_empty_distance))
	webserver.content_send(string.format(moist_threshold_text, self.values[4]))
	moisture_trheshold = self.values[4]
 end
end
irrigation_web_interface = IrrigationWeb()
tasmota.add_driver(irrigation_web_interface)

############################################
# set moisture web display
def moisture(value, trigger)
  var tr=string.split(trigger,7)
  var valnum=number(tr[1])
  tasmota.log(string.format("Trigger %s, %i", tr, value))
  # set value for webinterface
  irrigation_web_interface.set(valnum-1, value)
  tasmota.set_power(4, false)
end
# set rule for slider movement
tasmota.add_rule("Channel5", moisture)

#########################################
# change of container empty distance
def empty_distance(value, trigger)
	container_empty_distance =  number(tasmota.cmd("Mem1").item("Mem1"))
end
# rule to update webinterface
tasmota.add_rule("Mem1", empty_distance)


############################################
######### PUMP 1 ###########################
#-
# Pump1 and Flora for pump1
# make sure gpio for pump1 is "Relay 1"
# and PWM gpio for pump 1 is PWM 3 (gpio will not be used and turned off
# we need the PWM only to have a slider for pump duration
-#


###########################################
# set flora value
def flora1(value, trigger)
  tasmota.log(string.format("Trigger flora; value %d, trigger %s", value, trigger))
  flora_pump1_moisture = number(value)
end
# trigger for moisture update
tasmota.add_rule(flora_pump1+"#Moisture", flora1)

#############################################
# set power time of a relay
# and value for web interface
def power_stop1(value, trigger)
  # set pump runtime
  tasmota.cmd(string.format("pulsetime1 %i", calc_runtime(value)))
  # turn off PWM
  tasmota.set_power(2, false)
  # set value for webinterface
  irrigation_web_interface.set(2, value)
end
# trigger if slider is moved
tasmota.add_rule("Channel3", power_stop1)

########################################
# stop pump is container is empty or too wet
def wet_or_empty1(value, trigger)
	# get distance
	var dist = real(json.load(tasmota.read_sensors()).item(distance_sensor).item("Distance"))
	tasmota.log(string.format("Pump%i: Water level: %f, empty > %i", 1, dist, container_empty_distance))
	if dist > container_empty_distance 
		# stop pump because there is no more water in the tank
		tasmota.cmd(string.format("Power%i off", 1))
	end
	tasmota.log(string.format("Pump1: moisture %i, wet > %i", flora_pump1_moisture, moisture_trheshold))
	if flora_pump1_moisture > moisture_trheshold
		# stop if wet
		tasmota.cmd(string.format("Power%i off", 1))
		tasmota.log(string.format("Pump%i off: moisture %i, wet > %i", 1, flora_pump1_moisture, moisture_trheshold))
	end
end
tasmota.add_rule("Power1", wet_or_empty1)

##########################################
########## PUMP 2 ########################
#-
# Pump2 and Flora for pump2
# make sure gpio for pump1 is "Relay 2"
# and PWM gpio for pump 2 is PWM 4 (gpio will not be used and turned off
# we need the PWM only to have a slider for pump duration
-#


###########################################
# set flora value
def flora2(value, trigger)
  tasmota.log(string.format("Trigger flora; value %d, trigger %s", value, trigger))
	flora_pump2_moisture = number(value)
end
# trigger for moisture update
tasmota.add_rule(flora_pump2+"#Moisture", flora2)

#############################################
# set power time of a relay
# and value for web interface
def power_stop2(value, trigger)
  # set pump runtime
  tasmota.cmd(string.format("pulsetime2 %i", calc_runtime(value)))
  tasmota.set_power(3, false)
  # set value for webinterface
  irrigation_web_interface.set(3, value)
end
# trigger if slider is moved
tasmota.add_rule("Channel4", power_stop2)

########################################
# stop pump is container is empty or too wet
def wet_or_empty2(value, trigger)
	# get distance
	var dist = real(json.load(tasmota.read_sensors()).item(distance_sensor).item("Distance"))
	tasmota.log(string.format("Pump%i: Water level: %f, empty > %i", 2, dist, container_empty_distance))
	if dist > container_empty_distance 
		# stop pump because there is no more water in the tank
		tasmota.cmd(string.format("Power%i off", 2))
	end
	tasmota.log(string.format("Pump2: moisture %i, wet > %i", flora_pump2_moisture, moisture_trheshold))
	if flora_pump2_moisture > moisture_trheshold
		# stop if wet
		tasmota.cmd(string.format("Power%i off", 2))
		tasmota.log(string.format("Pump%i: moisture %i, wet > %i", 2, flora_pump2_moisture, moisture_trheshold))
	end
end
tasmota.add_rule("Power2", wet_or_empty2)



# delete rules
#-
tasmota.remove_rule("Power1")
tasmota.remove_rule("Power2")
tasmota.remove_rule("Channel3")
tasmota.remove_rule("Channel4")
tasmota.remove_rule("Channel5")
tasmota.remove_rule("Flora892404#Moisture")
tasmota.remove_rule("Flora892AF8#Moisture")
tasmota.remove_driver(irrigation_web_interface)
tasmota.remove_rule("Mem1")
-#