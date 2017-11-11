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
setlistener("/controls/electric/engine-battery-switch", func {
    if(getprop("/controls/electric/engine-battery-switch")){
        interpolate("/controls/electric/engine-battery-switch-pos", 1.00, 0.25);
    }else{
        interpolate("/controls/electric/engine-battery-switch-pos", 0.00, 0.25);
    }
});   
setlistener("/controls/engines/engine/extend-propeller", func{
	if(getprop("/controls/electric/engine-battery-switch") and !getprop("/engines/engine/running")){
		if(getprop("/controls/engines/engine/extend-propeller")){
			interpolate("/engines/engine/prop-pos-norm", 1.00, 5);
		}else{
			interpolate("/engines/engine/prop-pos-norm", 0.00, 5);
		}
	}
	
	interpolate("controls/engines/engine/extend-propeller-pos", getprop("/controls/engines/engine/extend-propeller"), 0.25);
	
});
setlistener("/controls/engines/engine/magnetos", func{
	if(getprop("/controls/engines/engine/magnetos")<3){
		setprop("/consumables/fuel/tank/selected", 0);
	}else{
		setprop("/consumables/fuel/tank/selected", 1);	
	}
});
	
setlistener("/controls/flight/elevator", func{
	if(getprop("/controls/flight/elevator")<-0.9){
		setprop("/controls/flight/elevator-trim-jump", -1);
	}else if(getprop("/controls/flight/elevator")>0.9){
		setprop("/controls/flight/elevator-trim-jump", 1);
	}else{
		setprop("/controls/flight/elevator-trim-jump", 0);
	}
});
	
setlistener("/sim/signals/fdm-initialized", func{
	setprop("/consumables/fuel/tank/selected", 0);
	print("Hourmeter initialized");
	settimer(update_hourmeter, 36);
});

var update_hourmeter = func{
	
	if(getprop("/engines/engine/running")){
		setprop("/instrumentation/ilec/hours", (getprop("/instrumentation/ilec/hours") or 0)+0.01);
	}
	
	settimer(update_hourmeter, 36);
}

var windcheck = func{
	wd=getprop("/environment/wind-from-heading-deg");
	ch=getprop("/orientation/heading-deg");
	ws=getprop("/environment/wind-speed-kt");
	var wdi=wd-ch;
	if(wdi<0){
		gui.popupTip(sprintf("Wind from %d degrees left at %.1f knots", -wdi, ws));
	}else{
		gui.popupTip(sprintf("Wind from %d degrees right at %.1f knots", wdi, ws));
	}
}
