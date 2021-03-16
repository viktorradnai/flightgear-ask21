##
# ASK21 Electrical System
#	by Benedikt Wolf (D-ECHO) 03/2021

#	adapted from: Cessna 172p Electrical System


#	References: 	ref. [2] and ref. [10]

var ammeter_ave = [ 0.0, 0.0 ];

# Initialize properties
var generator_fail = props.globals.getNode( "/controls/electric/generator-fail", 1);

var engine_bus_p = {
	amps:	electrical.initNode("engine-amps",  0.0, "DOUBLE"),
	volts:	electrical.initNode("engine-volts", 0.0, "DOUBLE"),
	load:	electrical.initNode("engine-load",  0.0, "DOUBLE"),
};

var engine_ctrl = {
	batt_switch:	props.globals.getNode("/controls/electric/engine-battery-switch", 1),
	starter:	props.globals.getNode("/controls/engines/engine[0]/starter", 1),
	magneto:	props.globals.getNode("/controls/engines/engine[0]/magnetos", 1),
	mixture:	props.globals.getNode("/controls/engines/engine[0]/mixture-int", 1),
	prop_pos:	props.globals.getNode("/engines/engine/prop-pos-norm", 1),
	prop_cmd:	props.globals.getNode("/controls/engines/engine/extend-propeller", 1),
};

outputs.spindle_motor 	= props.globals.initNode("/systems/electrical/outputs/spindle-motor",	0.0, "DOUBLE");
outputs.starter 	= props.globals.initNode("/systems/electrical/outputs/starter",		0.0, "DOUBLE");
outputs.ignition 	= props.globals.initNode("/systems/electrical/outputs/ignition",	0.0, "DOUBLE");

circuit_breakers.master_eng = cb_prop.initNode("master-engine", 1, "BOOL");

##
# Alternator model class.
#

var AlternatorClass = {
	new: func {
		var obj = { parents : [AlternatorClass],
		rpm_source : props.globals.getNode( "/engines/engine[0]/engine-rpm-checked", 1), #RPM depending on propeller extended/retracted
		rpm_threshold : 2200.0,
		ideal_volts : 14.0,
		ideal_amps : 60.0 };
		obj.rpm_source.setDoubleValue( 0.0 );
		return obj;
	},
	apply_load: func( amps, dt ){
		# Computes available amps and returns remaining amps after load is applied
		# Scale alternator output for rpms < 800.  For rpms >= 800
		# give full output.  This is just a WAG, and probably not how
		# it really works but I'm keeping things "simple" to start.
		var rpm = me.rpm_source.getDoubleValue();
		var factor = rpm / me.rpm_threshold;
		if ( factor > 1.0 ) {
			factor = 1.0;
		}
		# print( "alternator amps = ", me.ideal_amps * factor );
		var available_amps = me.ideal_amps * factor;
		return available_amps - amps;
	},
	get_output_volts: func {
		# Return output volts based on rpm
		# scale alternator output for rpms < 800.  For rpms >= 800
		# give full output.  This is just a WAG, and probably not how
		# it really works but I'm keeping things "simple" to start.
		var rpm = me.rpm_source.getDoubleValue();
		var factor = rpm / me.rpm_threshold;
		if ( factor > 1.0 ) {
			factor = 1.0;
		}
		# print( "alternator volts = ", me.ideal_volts * factor );
		return me.ideal_volts * factor;
	},
	get_output_amps: func {
		# Return output amps available based on rpm.
		# scale alternator output for rpms < 800.  For rpms >= 800
		# give full output.  This is just a WAG, and probably not how
		# it really works but I'm keeping things "simple" to start.
		var rpm = me.rpm_source.getDoubleValue();
		var factor = rpm / me.rpm_threshold;
		if ( factor > 1.0 ) {
			factor = 1.0;
		}
		# print( "alternator amps = ", ideal_amps * factor );
		return me.ideal_amps * factor;
	},
};

var alternator = AlternatorClass.new();

############################
####	Battery Packs	####
############################
var batteries = {
	main:	BatteryClass.new( 12.0, 0.325, 7.2, 25, 0),
	eng:	BatteryClass.new( 12.0, 0.325, 24, 25, 0),
};

var reset_battery = func {
	batteries.main.reset_to_full_charge();
	batteries.eng.reset_to_full_charge();
}

##
# This is the main electrical system update function.
#

var update_bus = func () {
	var dt = delta_time.getDoubleValue();
	
	engine_bus( dt );
	
	if( !serviceable.getBoolValue() ){
		return;
	}
	var load = 0.0;
	var bus_volts = 0.0;
	
	
	
	
	if( circuit_breakers.master.getBoolValue() and master_sw.getBoolValue()){
		bus_volts = batteries.main.get_output_volts();
	}
	
	# switch state
	load += cockpit_bus( bus_volts );
	
	if ( load > 300 ) {
		circuit_breakers.master.setBoolValue( 0 );
	}
	
	batteries.main.apply_load( load, dt );
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

var engine_bus = func ( dt ) {
	
	if( !serviceable.getBoolValue() or !circuit_breakers.master_eng.getBoolValue() ){
		return;
	}
	var load = 0.0;
	var bus_volts = 0.0;
	var battery_volts = batteries.eng.get_output_volts();
	var alternator_volts = alternator.get_output_volts();
	
	var power_source = nil;
	if( master_sw.getBoolValue() ){
		bus_volts = battery_volts;
		power_source = "battery_eng";
	}
	if( alternator_volts > bus_volts and !generator_fail.getBoolValue() ){
		bus_volts = alternator_volts;
		power_source = "alternator";
	}
	
	
	#Prop in/out
	if ( ( engine_ctrl.prop_cmd.getValue() == 1 and engine_ctrl.prop_pos.getValue() != 1 ) or ( engine_ctrl.prop_cmd.getValue() == 0 and engine_ctrl.prop_pos.getValue() != 0 ) )  {
		outputs.spindle_motor.setDoubleValue( bus_volts );
		load += bus_volts / 25;
	} else {
		outputs.spindle_motor.setDoubleValue( 0.0 );
	}
	
	#Ignition
	if ( engine_ctrl.batt_switch.getBoolValue() and engine_ctrl.magneto.getValue()==3 ) {
		outputs.ignition.setDoubleValue( bus_volts );
		if(bus_volts > 12.5){
			engine_ctrl.mixture.setValue(1);
		}else{
			engine_ctrl.mixture.setValue(0);
		}		
		load += bus_volts / 2;
	} else {
		outputs.ignition.setDoubleValue( 0.0 );
	}
	
	#Starter
	if ( engine_ctrl.batt_switch.getBoolValue() and engine_ctrl.starter.getBoolValue() ) {
		outputs.starter.setDoubleValue( bus_volts );
		load += bus_volts ;
	} else {
		outputs.starter.setDoubleValue( 0.0 );
	}
	
	if( load > 55 ){
		circuit_breakers.master_eng.setBoolValue( 0 );
	}
	
	var ammeter = 0.0;
	if( bus_volts > 1.0 ){
		if ( power_source == "battery_eng" ) {
			ammeter = -load;
		} else {
			ammeter = batteries.eng.charge_amps;
		}
	}
	
	if( power_source == "battery_eng" ){
		batteries.eng.apply_load( load, dt );
	} elsif( bus_volts > battery_volts ){
		batteries.eng.apply_load( -batteries.eng.charge_amps, dt );
	}
	
	# filter ammeter needle pos
	ammeter_ave[1] = 0.8 * ammeter_ave[1] + 0.2 * ammeter;
		
	engine_bus_p.amps.setDoubleValue( ammeter_ave[1] );
	engine_bus_p.load.setDoubleValue( load );
	engine_bus_p.volts.setDoubleValue( bus_volts );
	
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

