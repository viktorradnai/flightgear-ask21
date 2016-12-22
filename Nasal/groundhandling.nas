####ASK21 Ground Handling System

setlistener("/sim/signals/fdm-initialized", func {
    print("Ground handling system loaded. :D ");
    settimer(update_systems, 2);
    });

var update_systems = func {
#Assisting person
if(getprop("/velocities/groundspeed-kt")<15 & getprop("gear/gear[1]/wow")==1 & getprop("/controls/gear/assist-1")==1){
setprop("controls/gear/assist", 1);
}else{
setprop("controls/gear/assist", 0);
}
#Rudder
#Conditions: must be on ground, must have ground handling enabled (have people standing there) and people can only run up to 15kts (about)
if(getprop("/controls/ground-handling")==1 & getprop("/gear/gear[1]/wow")==1 & getprop("/velocities/groundspeed-kt")<15){
    setprop("/controls/flight/rudder2", getprop("/controls/flight/rudder"));
    setprop("/controls/flight/aileron2", getprop("/controls/flight/aileron"));
    setprop("/controls/throttle-2", getprop("/controls/engines/engine/throttle"));
    if(getprop("/controls/engines/engine/reverser")==1){
        setprop("/controls/throttle-2", 0);
        setprop("/controls/throttle-reverse", getprop("/controls/engines/engine/throttle"));
    }else{
        setprop("/controls/throttle-reverse", 0);
    }
}else{
        setprop("/controls/flight/aileron2", 0);
        setprop("/controls/flight/rudder2", 0);
        setprop("/controls/throttle-2", 0);
        setprop("/controls/throttle-reverse", 0);
        }

    settimer(update_systems,0);
}
