#According to https://flarm.com/de/produkte/powerflarm/ range is 3km

#Set variables
var f=0;
var max_dist=3;
var warn1_dist=0.4;
var warn2_dist=0.2;
running=0;

var prop_base = "instrumentation/FLARM/";
var nc_prop = prop_base~"sound/new-contact";
var warn_prop = prop_base~"sound/warn";

#Set properties
while(f<20){
	setprop(prop_base~"targets-tracked/mp["~f~"]", 0);
	f=f+1;
}

var targets={1:nil,2:nil,3:nil,4:nil,5:nil,6:nil,7:nil,8:nil,9:nil,10:nil};


var relative = func (brg, heading) {
	brg=brg-heading;
	while (brg<0){
		brg=360+brg;
	}
	if(brg>0){
		return brg;
	}
}

var new_contact = func ()  { #Sound message for new contact
	print("Something");
	if(getprop(nc_prop) == 1){
		setprop(nc_prop, 0);
	}else{
		setprop(nc_prop, 1);
	}
}

#var target1 = Target.new(ID,brg,dst,hdg,alt);
var Target = {
    new : func(ID,brg,dst,hdg,alt){
    m = { parents : [Target] };
		m.ident=ID;
		m.bearing=brg;
		m.distance=dst;
		m.heading=hdg;
		m.altitude=alt;
		new_contact();
    return m;
    },
    
    update_data : func(ID,brg,dst,hdg,alt){
		me.ident=ID;
		me.bearing=brg;
		me.distance=dst;
		me.heading=hdg;
		me.altitude=alt;
		#print(sprintf("new values: %s, %d, %d, %d, %d", ID, brg, dst, hdg, alt));
	},
    
    update_LED : func(current_heading, current_velocity) {
	
		var LED={1:0,2:0,3:0,4:0,5:0,6:0,7:0,8:0,9:0,10:0,11:0,12:0};
		#print("Being called");
		#print(me.bearing);
		#print(current_heading);
		var relative_bearing=relative(me.bearing,current_heading);
		#print("Relative bearing is");
		#print(relative_bearing);
		var heading_deviation=me.heading-(me.bearing-180);
		if(me.distance<warn2_dist and (heading_deviation<30 or relative_bearing<30 and relative_bearing>-30 or relative_bearing>330 and relative_bearing<390) and current_velocity>5){
			#Warn 1: all LEDs red
			setprop(warn_prop, 2);
			foreach(var key; keys(LED)){
				LED[key]=2;
			}
		}else if(me.distance<warn1_dist){
			#Warn 2: corresponding LED red
			setprop(warn_prop, 1);
			LED[int(relative_bearing/30+1)] = 2;
		}else{
			#Normal: corresponding LED green
			setprop(warn_prop, 0);
			LED[int(relative_bearing/30+1)] = 1;
		}
		
		return LED;
		
		
	#	if(me.distance<0.1 and me.heading-(me.bearing-180)<5 and me.heading-(me.bearing-180)>-5 ){
	#		foreach(var i; keys(LED_green)){
	#			setprop("/instrumentation/FLARM/LED"~i~"-red", 1);
	#		}
	#	}else if(me.distance<0.2){
	#		foreach(var i; keys(LED_green)){
	#			setprop("/instrumentation/FLARM/LED"~i~"-red", LED_green[i]);
	#		}
	#	}else{
	#		foreach(var i; keys(LED_green)){
	#			#print(LED_green[i]);
	#			setprop("/instrumentation/FLARM/LED"~i~"-green", LED_green[i]);
	#		}
	#	}
	},
	update_ub : func(current_altitude){
		var alt_diff=me.altitude-current_altitude; #Altitude difference in ft
		var alt_diff=alt_diff*0.3048/1852;         #Convert altitude difference to nm (first to meter, then to nm)
		#print(alt_diff);
		#print(me.distance);
		var angle=(math.atan(alt_diff/me.distance))*R2D;
		return angle;
	},
	get_distance : func() {
		return me.distance;
	},
};






setlistener("/sim/signals/fdm-initialized", func{
	settimer(update_FLARM, 5);
	#print("FLARM update started");
});


	

var update_FLARM = func{

	var f=0;
	while(f<20){
		#Check whether required properties exist
		if(getprop("/ai/models/multiplayer["~f~"]/bearing-to") != nil and getprop("/ai/models/multiplayer["~f~"]/distance-to-km") != nil){
			#Check whether in range and target not already existing
			if(getprop("/ai/models/multiplayer["~f~"]/distance-to-km")<max_dist and getprop("/instrumentation/FLARM/targets-tracked/mp["~f~"]")==0){
				#Now generate a target
				#print("Generating target");
				var ID=getprop("/ai/models/multiplayer["~f~"]/callsign") or 0;
				var brg=getprop("/ai/models/multiplayer["~f~"]/bearing-to");
				var dst=getprop("/ai/models/multiplayer["~f~"]/distance-to-km");
				var hdg=getprop("/ai/models/multiplayer["~f~"]/orientation/heading-deg") or 0;
				var alt=getprop("/ai/models/multiplayer["~f~"]/position/altitude-ft") or 0;
				targets[f]=Target.new(ID,brg,dst,hdg,alt);
				setprop("/instrumentation/FLARM/targets-tracked/mp["~f~"]", 1);
			}else if(getprop("/ai/models/multiplayer["~f~"]/distance-to-km")>max_dist and getprop("/instrumentation/FLARM/targets-tracked/mp["~f~"]")==1){
				#Target existing, but has moved meanwhile out of range
				#print("Target existing, but has moved meanwhile out of range");
				targets[f]=nil;
				setprop("/instrumentation/FLARM/targets-tracked/mp["~f~"]", 0);
			}
		}else if(getprop("/instrumentation/FLARM/targets-tracked/mp["~f~"]")==1){
			#Target existing, but has meanwhile logged out
			#print("Target existing, but has meanwhile logged out");
			targets[f]=nil;
			setprop("/instrumentation/FLARM/targets-tracked/mp["~f~"]", 0);
		}
		f=f+1;
	}
	
	receive=0;
	
	foreach(var key; keys(targets)){
		if(targets[key]!=nil){
			var ID=getprop("/ai/models/multiplayer["~key~"]/callsign") or 0;
			var brg=getprop("/ai/models/multiplayer["~key~"]/bearing-to");
			var dst=getprop("/ai/models/multiplayer["~key~"]/distance-to-km") or 0;
			var hdg=getprop("/ai/models/multiplayer["~key~"]/orientation/true-heading-deg") or 0;
			var alt=getprop("/ai/models/multiplayer["~key~"]/position/altitude-ft") or 0;
			targets[key].update_data(ID,brg,dst,hdg,alt);
			receive=1;
		}
	}
	
	setprop("/instrumentation/FLARM/receive", receive);
	
	
	
	#Check LEDs
	#12 LEDS, each cover 30 degrees	
	
	heading=getprop("/orientation/heading-deg") or 0;
	velocity=getprop("/velocities/groundspeed-kt") or 0;
	
	var stored_distance=9999;
	var used_angle=nil;
	var LEDs={1:0,2:0,3:0,4:0,5:0,6:0,7:0,8:0,9:0,10:0,11:0,12:0};
	foreach(var key; keys(targets)){
		if(targets[key]!=nil){
			#print("Checking LED on non-nil target");
			var LED=targets[key].update_LED(heading,velocity);
			#print(LED);
			foreach(var f; keys(LED)){
				if(LED[f]==1){
					LEDs[f]=1;
				}else if(LED[f]==2){
					LEDs[f]=2;
				}
			}
			var ca=getprop("/position/altitude-ft");
			var angle=targets[key].update_ub(ca);
			var distance=targets[key].get_distance();
			if(distance<stored_distance){
				used_angle=angle;
				stored_distance=distance;
			}
			
		}else{
			#print("Target is 0");
			#print(key);
		}
	}
	if(used_angle!=nil){
		#print(used_angle);
		if(used_angle>14){
			setprop("/instrumentation/FLARM/ub-LED1", 1);
			setprop("/instrumentation/FLARM/ub-LED2", 0);
			setprop("/instrumentation/FLARM/ub-LED3", 0);
			setprop("/instrumentation/FLARM/ub-LED4", 0);
		}else if(used_angle>7){
			setprop("/instrumentation/FLARM/ub-LED1", 0);
			setprop("/instrumentation/FLARM/ub-LED2", 1);
			setprop("/instrumentation/FLARM/ub-LED3", 0);
			setprop("/instrumentation/FLARM/ub-LED4", 0);
		}else if(used_angle<-14){
			setprop("/instrumentation/FLARM/ub-LED1", 0);
			setprop("/instrumentation/FLARM/ub-LED2", 0);
			setprop("/instrumentation/FLARM/ub-LED3", 0);
			setprop("/instrumentation/FLARM/ub-LED4", 1);
		}else if(used_angle<-7){
			setprop("/instrumentation/FLARM/ub-LED1", 0);
			setprop("/instrumentation/FLARM/ub-LED2", 0);
			setprop("/instrumentation/FLARM/ub-LED3", 1);
			setprop("/instrumentation/FLARM/ub-LED4", 0);
		}else{
			setprop("/instrumentation/FLARM/ub-LED1", 0);
			setprop("/instrumentation/FLARM/ub-LED2", 0);
			setprop("/instrumentation/FLARM/ub-LED3", 0);
			setprop("/instrumentation/FLARM/ub-LED4", 0);
		}
	}else{
		#print("nil");
		setprop("/instrumentation/FLARM/ub-LED1", 0);
		setprop("/instrumentation/FLARM/ub-LED2", 0);
		setprop("/instrumentation/FLARM/ub-LED3", 0);
		setprop("/instrumentation/FLARM/ub-LED4", 0);
	}
	
	foreach(var key; keys(LEDs)){
		if(LEDs[key]<=1){
			setprop("/instrumentation/FLARM/LED"~key~"", LEDs[key]);
			setprop("/instrumentation/FLARM/LED"~key~"-red", 0);
		}else if(LEDs[key]==2){
			setprop("/instrumentation/FLARM/LED"~key~"", 0);
			setprop("/instrumentation/FLARM/LED"~key~"-red", 1);
		}
			
	}
	
	
	
	if((getprop("/systems/electrical/outputs/flarm") or 0)>15){
		settimer(update_FLARM, 0.1);
		running=1;
	}else{
		running=0;
		setprop("/instrumentation/FLARM/LED1", 0);
		setprop("/instrumentation/FLARM/LED2", 0);
		setprop("/instrumentation/FLARM/LED3", 0);
		setprop("/instrumentation/FLARM/LED4", 0);
		setprop("/instrumentation/FLARM/LED5", 0);
		setprop("/instrumentation/FLARM/LED6", 0);
		setprop("/instrumentation/FLARM/LED7", 0);
		setprop("/instrumentation/FLARM/LED8", 0);
		setprop("/instrumentation/FLARM/LED9", 0);
		setprop("/instrumentation/FLARM/LED10", 0);
		setprop("/instrumentation/FLARM/LED11", 0);
		setprop("/instrumentation/FLARM/LED12", 0);
		setprop("/instrumentation/FLARM/LED1-red", 0);
		setprop("/instrumentation/FLARM/LED2-red", 0);
		setprop("/instrumentation/FLARM/LED3-red", 0);
		setprop("/instrumentation/FLARM/LED4-red", 0);
		setprop("/instrumentation/FLARM/LED5-red", 0);
		setprop("/instrumentation/FLARM/LED6-red", 0);
		setprop("/instrumentation/FLARM/LED7-red", 0);
		setprop("/instrumentation/FLARM/LED8-red", 0);
		setprop("/instrumentation/FLARM/LED9-red", 0);
		setprop("/instrumentation/FLARM/LED10-red", 0);
		setprop("/instrumentation/FLARM/LED11-red", 0);
		setprop("/instrumentation/FLARM/LED12-red", 0);
		setprop("/instrumentation/FLARM/ub-LED1", 0);
		setprop("/instrumentation/FLARM/ub-LED2", 0);
		setprop("/instrumentation/FLARM/ub-LED3", 0);
		setprop("/instrumentation/FLARM/ub-LED4", 0);
	}
}

setlistener("/systems/electrical/outputs/flarm", func{
	if((getprop("/systems/electrical/outputs/flarm") or 0)>15 and running==0){
		settimer(update_FLARM, 1);
		running=1;
	}
});
