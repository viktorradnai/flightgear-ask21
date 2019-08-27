##
# Procedural model of an ASK21 electrical system.  Includes a
# preliminary battery charge/discharge model and realistic ammeter
# gauge modeling.
#
# Based on C172P electrical system.

# Initialize properties
var com_ptt = props.globals.getNode("/instrumentation/comm[0]/ptt", 1);
var com_start = props.globals.getNode("/instrumentation/comm[0]/start", 1);
var vario_vol = props.globals.getNode("/instrumentation/ilec-sc7/volume", 1);
var vario_aud = props.globals.getNode("/instrumentation/ilec-sc7/audio", 1);
var vario_read = props.globals.getNode("/instrumentation/ilec-sc7/te-reading-mps", 1);
var turnbank_spin = props.globals.getNode("/instrumentation/turn-indicator/spin", 1);

##
# Initialize internal values
#

var vbus_volts = 0.0;
var ebus1_volts = 0.0;
var ebus2_volts = 0.0;

var ammeter_ave = 0.0;
##
# Battery model class.
#

var BatteryClass = {};

BatteryClass.new = func {
    var obj = { parents : [BatteryClass],
                ideal_volts : 12.0,
                ideal_amps : 30.0,
                amp_hours : 7.6,
                charge_percent : getprop("/systems/electrical/battery-charge-percent") or 1.0,
                charge_amps : 7.0 };
    setprop("/systems/electrical/battery-charge-percent", obj.charge_percent);
    return obj;
}

##
# Passing in positive amps means the battery will be discharged.
# Negative amps indicates a battery charge.
#

BatteryClass.apply_load = func (amps, dt) {
    var old_charge_percent = getprop("/systems/electrical/battery-charge-percent");

    if (getprop("/sim/freeze/replay-state"))
        return me.amp_hours * old_charge_percent;

    var amphrs_used = amps * dt / 3600.0;
    var percent_used = amphrs_used / me.amp_hours;

    var new_charge_percent = std.max(0.0, std.min(old_charge_percent - percent_used, 1.0));

    if (new_charge_percent < 0.1 and old_charge_percent >= 0.1)
        gui.popupTip("Warning: Low battery! Enable alternator or apply external power to recharge battery!", 10);
    me.charge_percent = new_charge_percent;
    setprop("/systems/electrical/battery-charge-percent", new_charge_percent);
    return me.amp_hours * new_charge_percent;
}

##
# Return output volts based on percent charged.  Currently based on a simple
# polynomial percent charge vs. volts function.
#

BatteryClass.get_output_volts = func {
    var x = 1.0 - me.charge_percent;
    var tmp = -(3.0 * x - 1.0);
    var factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    return me.ideal_volts * factor;
}


##
# Return output amps available.  This function is totally wrong and should be
# fixed at some point with a more sensible function based on charge percent.
# There is probably some physical limits to the number of instantaneous amps
# a battery can produce (cold cranking amps?)
#

BatteryClass.get_output_amps = func {
    var x = 1.0 - me.charge_percent;
    var tmp = -(3.0 * x - 1.0);
    var factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    return me.ideal_amps * factor;
}

##
# Set the current charge instantly to 100 %.
#

BatteryClass.reset_to_full_charge = func {
    me.apply_load(-(1.0 - me.charge_percent) * me.amp_hours, 3600);
}


var battery = BatteryClass.new();


var recharge_battery = func {
    # Charge battery to 100 %
    battery.reset_to_full_charge();
}
##
# This is the main electrical system update function.
#

var ElectricalSystemUpdater = {
    new : func {
        var m = {
            parents: [ElectricalSystemUpdater]
        };
        # Request that the update function be called each frame
        m.loop = updateloop.UpdateLoop.new(components: [m], update_period: 0.0, enable: 0);
        return m;
    },

    enable: func {
        me.loop.reset();
        me.loop.enable();
    },

    disable: func {
        me.loop.disable();
    },

    reset: func {
        # Do nothing
    },

    update: func (dt) {
        update_virtual_bus(dt);
    }
};

##
# Model the system of relays and connections that join the battery,master/alt switches.
#

var update_virtual_bus = func (dt) {
    var serviceable = getprop("/systems/electrical/serviceable");
    var load = 0.0;
    var battery_volts = 0.0;
    if ( serviceable ) {
        battery_volts = battery.get_output_volts();
    }

    # switch state
    var master_bat = getprop("/controls/electric/battery-switch");

    
    # determine power source
    if (master_bat){
	var bus_volts = battery_volts;
	var power_source = battery;
    }else{
	var bus_volts = 0.0;
    }
    #print( "virtual bus volts = ", bus_volts );

    # bus network (1. these must be called in the right order, 2. the
    # bus routine itself determins where it draws power from.)
    load += electrical_bus_1();
    
    # swtich the master breaker off if load is out of limits
    if ( load > 55 ) {
      bus_volts = 0;
    }

    # system loads and ammeter gauge
    var ammeter = 0.0;
    if ( bus_volts > 1.0 ) {
        # ammeter gauge
        if ( power_source == "battery" ) {
            ammeter = -load;
        } else {
            ammeter = battery.charge_amps;
        }
    }
    # print( "ammeter = ", ammeter );

    # charge/discharge the battery
    battery.apply_load( load, dt );

    # filter ammeter needle pos
    ammeter_ave = 0.8 * ammeter_ave + 0.2 * ammeter;

    # outputs
    setprop("/systems/electrical/amps", ammeter_ave);
    setprop("/systems/electrical/volts", bus_volts);
    setprop("/systems/electrical/load", load);
    if (bus_volts > 9)
        vbus_volts = bus_volts;
    else
        vbus_volts = 0.0;

    return load;
}


#Load sources:
#	com:		https://www.skyfox.com/becker-ar6201-022-vhf-am-sprechfunkgeraet-8-33.html
#	vario:		http://www.ilec-gmbh.com/ilec/manuals/SC7pd.pdf
#	turn:		https://www.airteam.eu/de/p/falcon-tb02e-2-1 (not the same but similar)
#	flarm:		http://flarm.com/wp-content/uploads/man/FLARM_InstallationManual_D.pdf
#	flarm display:	https://www.air-store.eu/Display-V3-FLARM

var electrical_bus_1 = func() {
	var bus_volts = 0.0;
	var load = 0.0;
    
	bus_volts = vbus_volts;       
	
	if(bus_volts > 9){
        
		# Vario
		setprop("/systems/electrical/outputs/ilec-sc7", bus_volts);
		#Energy consumption:	25mA (medium volume) 60mA (max volume) -> guess: at 12V
		#			guess: base consumption 5mA (no volume)
		load += 0.06 / bus_volts;
		if(vario_aud.getValue() == 2 or (vario_aud.getValue() == 1 and vario_read.getValue() > 0)){
			load += (vario_vol.getValue()*0.66) / bus_volts;
		}
	
	
		# Radio  
		setprop("/systems/electrical/outputs/comm", bus_volts);
		if(com_ptt.getBoolValue() and com_start.getValue()==1){
			load += 19.2 / bus_volts;
		}else{
			load += 1.02*com_start.getValue() / bus_volts;
		}
    
		#Turn Coordinator
		#Energy Consumption:
		#	starting ~9.9 / volts (approx)
		#	running ~7.8 / volts (approx)
		if ( getprop("/controls/electric/turn-slip-switch")==1) {
			#setprop("/systems/electrical/outputs/turn", bus_volts);
			setprop("/systems/electrical/outputs/turn-coordinator", bus_volts);
			if( turnbank_spin.getValue() > 0.99 ){
				load += 7.8 / bus_volts;
			}else{
				load += 9.9 / bus_volts;
			}
		} else {
			#setprop("/systems/electrical/outputs/turn", 0.0);
			setprop("/systems/electrical/outputs/turn-coordinator", 0.0);
		}
		
		setprop("/systems/electrical/outputs/flarm", bus_volts);
		load += 0.66 / bus_volts; #FLARM
		load += 0.12 / bus_volts; #FLARM display
	}else{
		setprop("/systems/electrical/outputs/comm", 0.0);
		setprop("/systems/electrical/outputs/ilec-sc7", 0.0);
		#setprop("/systems/electrical/outputs/turn", 0.0);
		setprop("/systems/electrical/outputs/turn-coordinator", 0.0);
		setprop("/systems/electrical/outputs/flarm", 0.0);
	}
		

	# register bus voltage
	ebus1_volts = bus_volts;

	# return cumulative load
	return load;
}

##
# Initialize the electrical system
#

var system_updater = ElectricalSystemUpdater.new();

setlistener("/sim/signals/fdm-initialized", func {
    # checking if battery should be automatically recharged
    if (!getprop("/systems/electrical/save-battery-charge")) {
        battery.reset_to_full_charge();
    };

    system_updater.enable();
    print("Electrical system initialized");
});
