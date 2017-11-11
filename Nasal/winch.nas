#Nasal script to control winch throttle during winch launch

#Seil straffen: not implemented
#Anschleppen: 10% throttle until aircraft is rolling, then rapidly (1s) increase to percentage set in -set file (ac-specific)
#Gas rausnehmen: When speed-in-tow-direction<10 (after it was above), slowly (5s) decrease throttle to 0
var throttle="/sim/hitches/winch/winch/rel-speed";
var sitd="/sim/hitches/winch/speed-in-tow-direction";
var ac_rel=getprop("/sim/hitches/winch/aircraft-speed") or 0.8;
var was_above_10=0;
var at_speed=0;
var stop=0;
var ac_type=getprop("/sim/aero") or 0;
var launch_in_progress = 0;
setprop("/sim/hitches/winch/first-phase", 0);
setprop("/sim/hitches/winch/second-phase", 0);
setprop("/sim/hitches/winch/third-phase", 0);

setlistener("/sim/hitches/winch/open", func{
	if(getprop("/sim/hitches/winch/open")==0){
		launch();
		setprop(throttle, 0);
	}else{
		launch_in_progress=0;
	}		
});


var launch = func{
	if(!launch_in_progress){
		setprop("/controls/gear/assist-1", 1);
		setprop("/sim/messages/ground",sprintf("%s at the rope, ready for departure, winch ready, pulling rope",ac_type));
		launch_in_progress=1;
		setprop("/sim/hitches/winch/first-phase", 1);
		first_phase();
	}else{
		setprop("/sim/messages/ground","Launch already in progress! You can stop launch by pressing q");
	}
}

#First phase: Anschleppen
var first_phase = func{
	if(getprop(throttle)<0.1){
		setprop(throttle, getprop(throttle)+0.02);
	}
	
	if(getprop("/gear/gear[1]/rollspeed-ms")>=0.2){
	setprop("/sim/hitches/winch/first-phase", 0);
	setprop("/sim/hitches/winch/second-phase", 1);
		second_phase();
		setprop("/sim/messages/ground", "Ready");
	}else{
		if(stop==1){
			setprop(throttle, 0);
			setprop("/sim/messages/ground","Stop! Stop! Stop! Open hook!");
			launch_in_progress=0;
			stop=0;
			setprop("/sim/hitches/winch/first-phase", 0);
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
	
	if(was_above_10!=1 and getprop(sitd)>10){
		was_above_10=1;
	}
	
	if(was_above_10==1 and getprop(sitd)<10){
		setprop("/sim/hitches/winch/second-phase", 0);
		setprop("/sim/hitches/winch/third-phase", 1);
		third_phase();
		was_above_10=0;
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
	}else{
		setprop("/sim/hitches/winch/third-phase", 0);
		launch_in_progress=0;
	}
}

var faster = func{
	if(getprop(throttle)<=0.95){
		setprop(throttle, getprop(throttle)+0.15);
	}else{
		setprop(throttle, 1);
	}
}

var slower = func{
	if(getprop(throttle)>=0.15){
		setprop(throttle, getprop(throttle)-0.15);
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



		
		
	
