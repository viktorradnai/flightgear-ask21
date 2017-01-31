####ASK21 Ground Handling System

setlistener("/sim/signals/fdm-initialized", func {
    print("Ground handling system loaded.");
    settimer(update_systems, 2);
});

var update_systems = func {
    #A short part for the copilot :)
    if(getprop("/sim/weight[1]/weight-lb")>=80){
        setprop("/sim/model/copilot-present", 1);
    }else{
        setprop("/sim/model/copilot-present", 0);
    }




    # Conditions: glider must be on ground and people can only run up to 15kts (about)
    var handlingConditions = getprop("gear/gear[1]/wow") == 1 and getprop("/velocities/groundspeed-kt") < 15;

    # Wing holder
    if (getprop("/controls/gear/assist-1") == 1 and handlingConditions) {
        setprop("controls/gear/assist", 1);
    } else {
        setprop("controls/gear/assist", 0);
    }

    # Ground handling
    if (getprop("/controls/ground-handling") == 1 and handlingConditions) {
        setprop("/controls/flight/rudder2", getprop("/controls/flight/rudder"));
        setprop("/controls/flight/aileron2", getprop("/controls/flight/aileron"));
        setprop("/controls/throttle-2", getprop("/controls/engines/engine/throttle"));

        if (getprop("/controls/engines/engine/reverser")==1) {
            setprop("/controls/throttle-2", 0);
            setprop("/controls/throttle-reverse", getprop("/controls/engines/engine/throttle"));
        } else {
            setprop("/controls/throttle-reverse", 0);
        }
    } else {
        setprop("/controls/flight/aileron2", 0);
        setprop("/controls/flight/rudder2", 0);
        setprop("/controls/throttle-2", 0);
        setprop("/controls/throttle-reverse", 0);
    }

    settimer(update_systems,0);
}
