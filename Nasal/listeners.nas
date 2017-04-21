setlistener("/controls/electric/battery-switch", func {
    if(getprop("/controls/electric/battery-switch")){
        interpolate("/controls/electric/battery-switch-pos", 1.00, 0.25);
    }else{
        interpolate("/controls/electric/battery-switch-pos", 0.00, 0.25);
    }
});
setlistener("/controls/electric/turn-slip-switch", func {
    if(getprop("/controls/electric/turn-slip-switch")){
        interpolate("/controls/electric/turn-slip-switch-pos", 1.00, 0.25);
    }else{
        interpolate("/controls/electric/turn-slip-switch-pos", 0.00, 0.25);
    }
});        