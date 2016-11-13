## Pushback
##########
var pbLoop = func {

if(getprop("/sim/model/pushback/position-norm") >= 0.9 ){
setprop("/controls/flight/rudder2", getprop("/controls/flight/rudder"));
setprop("/sim/model/pushback/target-speed-fps-2", getprop("/sim/model/pushback/target-speed-fps"));
}else
{
setprop("/controls/flight/rudder2", 0);
setprop("/sim/model/pushback/target-speed-fps-2", 0);
}

	settimer(pbLoop, 0);
 };
 

# start the loop 2 seconds after the FDM initializes

setlistener("sim/model/pushback/enabled", func {
	settimer(func {
		pbLoop();
	}, 2);
});

