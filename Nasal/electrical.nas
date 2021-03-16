##
# ASK21 Electrical System
#	by Benedikt Wolf (D-ECHO) 03/2021

#	adapted from: Cessna 172p Electrical System


var ammeter_ave = 0.0;

############################
####	Battery Packs	####
############################

##	example glider battery: https://shop.segelflugbedarf24.de/Flugzeugausstattung/Akkus-Energieversorgung/Sonnenschein-Dryfit-A512-12V/6-5-Ah::731.html
##				http://www.sonnenschein.org/A500.htm	(A512-6.5S)
##				ideal volts: 12.0
##				ideal amps: 0.325 (max. 80 / 300 for 5 sec))
##				amp hours: 6.5
##				charge amps: 25

var	battery = BatteryClass.new( 12.0, 0.325, 6.5, 25, 0);

var reset_battery = func {
	battery.reset_to_full_charge();
}

##
# This is the main electrical system update function.
#

var update_bus = func () {
	var dt = delta_time.getDoubleValue();
	
	if( !serviceable.getBoolValue() ){
		return;
	}
	var load = 0.0;
	var bus_volts = 0.0;
	
	if( circuit_breakers.master.getBoolValue() and master_sw.getBoolValue()){
		bus_volts = battery.get_output_volts();
	}
	
	# switch state
	load += cockpit_bus( bus_volts );
	
	if ( load > 300 ) {
		circuit_breakers.master.setBoolValue( 0 );
	}
	
	battery.apply_load( load, dt );
}

var cockpit_bus = func( bv ) {
	if( bv < 9 ){
		foreach( var el; keys( outputs ) ){
			outputs[el].setDoubleValue( 0.0 );
		}
		return 0.0;
	}
	
	var load = 0.0;
	var bus_volts = bv;
	
	# Electrical Consumers (Instruments)
	# Radio
	outputs.radio.setDoubleValue( bus_volts );
	if( consumers.comm.ptt.getBoolValue() and consumers.comm.start.getDoubleValue() > 0.99 ){
		load += 19.2 / bus_volts;
	} else {
		load += 1.02 * consumers.comm.start.getDoubleValue() / bus_volts;
	}
	
	# Vario
	outputs.ilec_sc7.setDoubleValue( bus_volts );
	#Energy consumption:	25mA (medium volume) 60mA (max volume) -> guess: at 12V
	#			guess: base consumption 5mA (no volume)
	load += 0.06 / bus_volts;
	if( consumers.ilec_sc7.audio.getIntValue() == 2 or ( consumers.ilec_sc7.audio.getIntValue() == 1 and consumers.ilec_sc7.read.getDoubleValue() > 0 ) ){
		load += ( consumers.ilec_sc7.volume.getDoubleValue() * 0.66 ) / bus_volts;
	}
	
	#Turn Coordinator
	#Energy Consumption:
	#	starting ~9.9 / volts (approx)
	#	running ~7.8 / volts (approx)
	if( turn_sw.getBoolValue() ){
		outputs.turn.setDoubleValue( bus_volts );
		if( consumers.tc_spin.getDoubleValue() > 0.99 ){
			load += 7.8 / bus_volts;
		}else{
			load += 9.9 / bus_volts;
		}
	} else {
		outputs.turn.setDoubleValue( 0.0 );
	}
		
	# FLARM
	outputs.flarm.setDoubleValue( bus_volts );
	load += 0.66 / bus_volts; #FLARM
	load += 0.12 / bus_volts; #FLARM display
	
	amps.setDoubleValue( load );
	volts.setDoubleValue( bus_volts );
	
	return load;
}

var update_electrical = maketimer( 0.0, update_bus );
update_electrical.simulatedTime = 1;

##
# Initialize the electrical system
#

setlistener("/sim/signals/fdm-initialized", func {
	reset_circuit_breakers();
	
	update_electrical.start();
	print("Electrical System initialized");
});

