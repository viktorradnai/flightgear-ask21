##
# Procedural model of an ASK21mi electrical system.  Includes a
# preliminary battery charge/discharge model and realistic ammeter
# gauge modeling.
#
# Based on C172P electrical system.


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
                ideal_volts : 24.0,
                ideal_amps : 30.0,
                amp_hours : 3.1875,
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

##
# Alternator model class.
#

var AlternatorClass = {};

AlternatorClass.new = func {
    var obj = { parents : [AlternatorClass],
                rpm_source : "/engines/engine[0]/engine-rpm-checked", #RPM depending on propeller extended/retracted
                rpm_threshold : 2200.0,
                ideal_volts : 28.0,
                ideal_amps : 60.0 };
    setprop( obj.rpm_source, 0.0 );
    return obj;
}

##
# Computes available amps and returns remaining amps after load is applied
#

AlternatorClass.apply_load = func( amps, dt ) {
    # Scale alternator output for rpms < 800.  For rpms >= 800
    # give full output.  This is just a WAG, and probably not how
    # it really works but I'm keeping things "simple" to start.
    var rpm = getprop( me.rpm_source );
    var factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    # print( "alternator amps = ", me.ideal_amps * factor );
    var available_amps = me.ideal_amps * factor;
    return available_amps - amps;
}

##
# Return output volts based on rpm
#

AlternatorClass.get_output_volts = func {
    # scale alternator output for rpms < 800.  For rpms >= 800
    # give full output.  This is just a WAG, and probably not how
    # it really works but I'm keeping things "simple" to start.
    var rpm = getprop( me.rpm_source );
    var factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    # print( "alternator volts = ", me.ideal_volts * factor );
    return me.ideal_volts * factor;
}


##
# Return output amps available based on rpm.
#

AlternatorClass.get_output_amps = func {
    # scale alternator output for rpms < 800.  For rpms >= 800
    # give full output.  This is just a WAG, and probably not how
    # it really works but I'm keeping things "simple" to start.
    var rpm = getprop( me.rpm_source );
    var factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    # print( "alternator amps = ", ideal_amps * factor );
    return me.ideal_amps * factor;
}

var alternator = AlternatorClass.new();

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
        alternator_volts = alternator.get_output_volts();
    }

    # switch state
    var master_bat = getprop("/controls/electric/battery-switch");
    var genfail = getprop("/controls/electric/generator-fail");

    if(getprop("/engines/engine/prop-pos-norm")==1){
	setprop("/engines/engine/engine-rpm-checked", getprop("/engines/engine/engine-rpm"));
    }else{
	setprop("/engines/engine/engine-rpm", 0);
    }
    
    # determine power source
    var bus_volts=0.0;
    var power_source = nil;
    if (master_bat){
	var bus_volts = battery_volts;
	var power_source = "battery";
    }
    if ( alternator_volts > bus_volts and !genfail) {
        bus_volts = alternator_volts;
        power_source = "alternator";
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
    if ( power_source == "battery" ) {
        battery.apply_load( load, dt );
    } elsif ( bus_volts > battery_volts ) {
        battery.apply_load( -battery.charge_amps, dt );
    }

    # filter ammeter needle pos
    ammeter_ave = 0.8 * ammeter_ave + 0.2 * ammeter;

    # outputs
    setprop("/systems/electrical/amps", ammeter_ave);
    setprop("/systems/electrical/volts", bus_volts);
    if (bus_volts > 12)
        vbus_volts = bus_volts;
    else
        vbus_volts = 0.0;

    return load;
}


var electrical_bus_1 = func() {
    var bus_volts = 0.0;
    var load = 0.0;
    
    # check master breaker
   # if ( getprop("/controls/circuit-breakers/master") ) {
        # we are feed from the virtual bus
        bus_volts = vbus_volts;        
   # }
    #print("Bus volts: ", bus_volts);
        
    # Vario
    setprop("/systems/electrical/outputs/ilec-sc7", bus_volts);
    load += bus_volts / 57;
    
    
    # Radio    
    setprop("/systems/electrical/outputs/ar-3201", bus_volts);
	if(bus_volts>12){
		setprop("/systems/electrical/outputs/ar-3201-norm", 1);
	}else{
		setprop("/systems/electrical/outputs/ar-3201-norm", 0);
	}
    load += bus_volts / 57;
    
    #Turn Coordinator
    if ( getprop("/controls/electric/turn-slip-switch")==1) {
        setprop("/systems/electrical/outputs/turn", bus_volts);
        setprop("/systems/electrical/outputs/turn-coordinator", bus_volts);
        load += bus_volts / 57;
    } else {
        setprop("/systems/electrical/outputs/turn", 0.0);
        setprop("/systems/electrical/outputs/turn-coordinator", 0.0);
    }
    
    setprop("/systems/electrical/outputs/flarm", bus_volts);
    setprop("/systems/electrical/outputs/comm[0]", bus_volts);
    
    #Prop in/out
    if ( getprop("/controls/engines/engine/extend-propeller")==1 and getprop("/engines/engine/prop-pos-norm")!=1 or getprop("/controls/engines/engine/extend-propeller")==0 and getprop("/engines/engine/prop-pos-norm")!=0 )  {
        setprop("/systems/electrical/outputs/spindle-motor", bus_volts);
        load += bus_volts / 25;
    } else {
        setprop("/systems/electrical/outputs/spindle-motor", 0.0);
    }
    
    #Ignition
    if ( getprop("/controls/electric/engine-battery-switch")==1 and getprop("/controls/engines/engine/magnetos")==3 ) {
        setprop("/systems/electrical/outputs/ignition", bus_volts);
        if(bus_volts>12.5){
		setprop("/controls/engines/engine[0]/mixture-int", 1);
	}else{
		setprop("/controls/engines/engine[0]/mixture-int", 0);
	}		
        load += bus_volts / 2;
    } else {
        setprop("/systems/electrical/outputs/ignition", 0.0);
    }
    
    #Starter
    if ( getprop("/controls/electric/engine-battery-switch")==1 and getprop("/controls/engines/engine/starter")==1 ) {
        setprop("/systems/electrical/outputs/starter", bus_volts);
        load += bus_volts ;
    } else {
        setprop("/systems/electrical/outputs/starter", 0.0);
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
