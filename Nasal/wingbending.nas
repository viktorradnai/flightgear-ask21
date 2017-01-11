####ASK21 Wing bending system

setlistener("/sim/signals/fdm-initialized", func {
    print("Wing bending system loaded.");
    settimer(update_wingflex, 2);
    });

var update_wingflex = func {
    if(getprop("/sim/current-view/view-number") == 9) {
        offset_wingflex = getprop("accelerations/pilot-g") * 0.17;
        new_z = 1.5 + offset_wingflex;
        setprop("/sim/current-view/y-offset-m", new_z);
    } else if (getprop("/sim/current-view/view-number") == 8) {
        offset_wingflex = getprop("accelerations/pilot-g") * 0.0175;
        new_z = 0.7 + offset_wingflex;
        setprop("/sim/current-view/y-offset-m", new_z);
    }

    settimer(update_wingflex,0.01);
}
