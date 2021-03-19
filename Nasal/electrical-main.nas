##
# ASK21 Electrical System
#	by Benedikt Wolf (D-ECHO) 03/2021

#	adapted from: Cessna 172p Electrical System



# Initialize properties
var electrical	=	props.globals.initNode("/systems/electrical");
var serviceable	=	electrical.initNode("serviceable", 1, "BOOL");
var batt_prop	=	electrical.initNode("battery");
var output_prop	=	electrical.initNode("outputs");
var cb_prop	=	props.globals.initNode("/controls/circuit-breakers");
var delta_time	=	props.globals.getNode("/sim/time/delta-sec", 1);

var volts	=	electrical.initNode("volts", 0.0, "DOUBLE");
var amps	=	electrical.initNode("amps", 0.0, "DOUBLE");
var master_sw	=	props.globals.initNode("/controls/electric/battery-switch", 0, "BOOL");
var turn_sw	=	props.globals.initNode("/controls/electric/turn-slip-switch", 0, "BOOL");

var outputs = {
	radio		:	output_prop.initNode("comm[0]", 0.0, "DOUBLE"),
	flarm		:	output_prop.initNode("flarm", 0.0, "DOUBLE"),
	turn		:	output_prop.initNode("turn-coordinator", 0.0, "DOUBLE"),
	ilec_sc7	:	output_prop.initNode("ilec-sc7", 0.0, "DOUBLE"),
};

var consumers = {
	ilec_sc7: {
		volume:	props.globals.getNode( "/instrumentation/ilec-sc7/volume", 1 ),
		audio:	props.globals.getNode( "/instrumentation/ilec-sc7/audio", 1 ),
		read:	props.globals.getNode( "/instrumentation/ilec-sc7/te-reading-mps", 1 ),
	},
	tc_spin:	props.globals.getNode("/instrumentation/turn-indicator/spin", 1),
	comm: {
		start:	props.globals.getNode("/instrumentation/comm[0]/start", 1),
		ptt:	props.globals.getNode("/instrumentation/comm[0]/ptt", 1),
	},
};

# Array of circuit breakers
var circuit_breakers = {
	master: cb_prop.initNode("master", 1, "BOOL"),
};

var freeze_replay	=	props.globals.getNode("/sim/freeze/replay-state");

##
# Battery model class.
#

var BatteryClass = {
	# Constructor
	new: func( name, ideal_volts, ideal_amps, amp_hours, charge_amps, n ){
		var charge_prop = nil;
		if( name == "" ){
			charge_prop = batt_prop.getNode( "charge["~n~"]", 1 );
		} else {
			charge_prop = batt_prop.getNode( "charge-"~ name ~"["~n~"]", 1 );
		}
		var charge	= nil;
		if( charge_prop.getValue() != nil ){			# If the battery charge has been set from a previous FG instance
			charge = charge_prop.getDoubleValue();
		} else {
			charge = 1.0;
			charge_prop.setDoubleValue( charge );
		}
		var obj = {
			parents: [BatteryClass],
			ideal_volts: ideal_volts,
			ideal_amps: ideal_amps,
			amp_hours: amp_hours,
			charge_amps: charge_amps,
			charge: charge,
			charge_prop: charge_prop,
			n: n 
		};
		return obj;
	},
	# Passing in positive amps means the battery will be discharged.
	# Negative amps indicates a battery charge.
	apply_load: func( amps, dt ){
		var old_charge = me.charge_prop.getDoubleValue();
		if( freeze_replay.getBoolValue() ){
			return me.amp_hours * old_charge;
		}
		var amphrs_used = amps * dt / 3600.0;
		var fraction_used = amphrs_used / me.amp_hours;
		
		var new_charge = std.max(0.0, std.min(old_charge - fraction_used, 1.0));
		
		if (new_charge < 0.1 and old_charge_percent >= 0.1)
			gui.popupTip("Warning: Low battery! Enable alternator or apply external power to recharge battery!", 10);
		me.charge = new_charge;
		me.charge_prop.setDoubleValue( new_charge );
		return me.amp_hours * new_charge;
	},
	# Return output volts based on percent charged.  Currently based on a simple
	# polynomial percent charge vs. volts function.
	get_output_volts: func() {
		var x = 1.0 - me.charge;
		var tmp = -(3.0 * x - 1.0);
		var factor = ( math.pow( tmp, 5) + 32 ) / 32;
		return me.ideal_volts * factor;
	},
	# Return output amps available.  This function is totally wrong and should be
	# fixed at some point with a more sensible function based on charge percent.
	# There is probably some physical limits to the number of instantaneous amps
	# a battery can produce (cold cranking amps?)
	get_output_amps: func() {
		var x = 1.0 - me.charge;
		var tmp = -(3.0 * x - 1.0);
		var factor = ( math.pow( tmp, 5) + 32) / 32;
		return me.ideal_amps * factor;
	},
	# Set the current charge instantly to 100 %.
	reset_to_full_charge: func() {
		me.apply_load(-(1.0 - me.charge) * me.amp_hours, 3600);
	},
	# Get current charge
	get_charge: func() {
		return me.charge;
	}
};

var reset_circuit_breakers = func {
	foreach(var cb; keys(circuit_breakers)){
		circuit_breakers[cb].setBoolValue( 1 );
	}
}
