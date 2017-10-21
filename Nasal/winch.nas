#Nasal script to control winch throttle during winch launch

#Seil straffen: not implemented
#Anschleppen: 10% throttle until aircraft is rolling, then rapidly (1s) increase to percentage set in -set file (ac-specific)
#Gas rausnehmen: When speed-in-tow-direction<15 (after it was above), slowly (5s) decrease throttle to 0
var throttle="/sim/hitches/winch/winch/rel-speed";
var sitd="/sim/hitches/winch/speed-in-tow-direction";
var ac_rel=getprop("/sim/hitches/winch/aircraft-speed") or 0.8;
var was_above_15=0;
var at_speed=0;
var stop=0;
var ac_type=getprop("/sim/aero") or 0;

setlistener("/sim/hitches/winch/open", func{
	if(getprop("/sim/hitches/winch/open")==0){
		launch();
		setprop(throttle, 0);
	}
});


var launch = func{
	setprop("/controls/gear/assist-1", 1);
	setprop("/sim/messages/ground",sprintf("%s at the rope, ready for departure, winch ready, pulling rope",ac_type));
	first_phase();
}

#First phase: Anschleppen
var first_phase = func{
	if(getprop(throttle)<0.1){
		setprop(throttle, getprop(throttle)+0.02);
	}
	
	if(getprop("/gear/gear[1]/rollspeed-ms")>=0.2){
		second_phase();
		setprop("/sim/messages/ground", "Ready");
	}else{
		if(stop==1){
			setprop(throttle, 0);
			setprop("/sim/messages/ground","Stop! Stop! Stop! Open hook!");
			stop=0;
		}else{
			settimer(first_phase, 0.1);
		}
		#print("In first phase");
	}
}
#Second phase: Accelerate and keep
var second_phase = func{
	if(at_speed==0){
		setprop(throttle, getprop(throttle)+0.08);
	}
	if(getprop(throttle)>=0.8 and at_speed==0){
		at_speed=1;
	}
	
	if(was_above_15!=1 and getprop(sitd)>15){
		was_above_15=1;
	}
	
	if(was_above_15==1 and getprop(sitd)<15){
		third_phase();
		was_above_15=0;
		at_speed=0;
	}else{
		settimer(second_phase, 0.1);
		#print("In sec phase");
	}
}
#Third phase: Decelerate
var third_phase = func{
	if(getprop(throttle)>0){
		setprop(throttle, getprop(throttle)-0.05);
		settimer(third_phase, 0.1);
		#print("In third phase");
	}
}

var faster = func{
	if(getprop(throttle)<=0.8){
		setprop(throttle, getprop(throttle)+0.2);
	}else{
		setprop(throttle, 1);
	}
}

var slower = func{
	if(getprop(throttle)>=0.2){
		setprop(throttle, getprop(throttle)-0.2);
	}else{
		setprop(throttle, 1);
	}
}

var stop = func{
	if(getprop("/gear/gear[1]/wow")==0){
		setprop("/sim/message/atc", "Stop not possible, Continuing");
	}else{
		stop=1;
	}
}


		
		
	
