# Script for recording the minimum / maximum G forces seen by the

gmeterUpdate = func {

    var GCurrent = props.globals.getNode("/accelerations/pilot-g").getValue();
    var GMin = props.globals.getNode("/accelerations/pilot-gmin").getValue();
    var GMax = props.globals.getNode("/accelerations/pilot-gmax").getValue();

    if (GCurrent < GMin) {
        if (GCurrent > -6) {
            setprop("/accelerations/pilot-gmin", GCurrent);
        } else {
          setprop("/accelerations/pilot-gmin", -6);
        }
    } elsif (GCurrent > GMax) {
        if(GCurrent < 10) {
            setprop("/accelerations/pilot-gmax", GCurrent);
        } else {
            setprop("/accelerations/pilot-gmax", 10);
        }
    }

    settimer(gmeterUpdate, 0); # Run again immediately
}

print("Starting gmeterUpdate");

### Init GMeter properties ###
props.globals.getNode("/accelerations/pilot-g", 1).setDoubleValue(1.01);
props.globals.getNode("/accelerations/pilot-gmin", 1).setDoubleValue(1);
props.globals.getNode("/accelerations/pilot-gmax", 1).setDoubleValue(1);

settimer(gmeterUpdate, 2);
