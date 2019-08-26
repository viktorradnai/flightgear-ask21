####ASK21 Ground Handling System

setlistener("/sim/signals/fdm-initialized", func {
    print("Ground handling system loaded.");
    settimer(update_systems, 2);
});

var gh = "controls/gear/assist-1";

setlistener("/velocities/groundspeed-kt", func(i) {
	if(i.getValue()>15 and getprop(gh)==1){
		setprop(gh, 0);
	}
});

setlistener("/gear/gear[1]/wow", func(i) {
	if(i.getValue()!=1 and getprop(gh)==1){
		setprop(gh, 0);
	}
});




var update_systems = func {
    
   
    
    #Altimeter code for tutorial
    var setting=getprop("/instrumentation/altimeter/setting-inhg") or 0;
    var qnh=getprop("/environment/pressure-sea-level-inhg") or 0;
    var qfe=getprop("/environmet/pressure-inhg") or 0;
    
    var diff1=setting-qnh;
    var diff2=setting-qnh;
	
	if(diff1>0.05 or diff1<-0.05 and diff2>0.05 or diff2<-0.05){
		setprop("/instrumentation/altimeter/setting-mismatch", 1);
	}else{
		setprop("/instrumentation/altimeter/setting-mismatch", 0);
	}
	
	
    settimer(update_systems,0);
}
