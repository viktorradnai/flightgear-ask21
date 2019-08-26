# AR-6201 by D-ECHO based on

# A3XX Lower ECAM Canvas
# Joshua Davidson (it0uchpods)
#######################################

var AR6201_only = nil;
var AR6201_start = nil;
var AR6201_brightness = nil;
var AR6201_squelch = nil;
var AR6201_sch = nil;
var AR6201_sach = nil;
var AR6201_display = nil;
var page = "only";

var base = "/instrumentation/comm[0]/";

var instrument_path = "Aircraft/ASK21/Models/Interior/Panel/Instruments/ar-6201/";

setprop(base~"sq", 1);

var volume_prop = base~"volume";
var start_prop = base~"start";
var volt_prop = "/systems/electrical/outputs/comm[0]";
var volts = props.globals.getNode(volt_prop, 1);
var pilotmenu_prop = base~"pilot-menu";
var channelmenu_prop = base~"channel-menu";
var brightness_prop = base~"brightness";
var squelch_prop = base~"squelch-lim";

var stored_base = base~"stored_frequencies/";

var stored_frequency = {
	new : func(frequency, number){
	m = { parents : [stored_frequency] };
			m.frequency=frequency;
			m.number=number;
	return m;
	},
	set_frequency: func(frequency) {
		me.frequency = frequency;
	},
};

var stored_frequencies={1:nil,2:nil,3:nil,4:nil,5:nil,6:nil,7:nil,8:nil,9:nil,10:nil,11:nil,12:nil,13:nil,14:nil,15:nil};

for(var i = 0; i <= 15; i += 1){
    stored_frequencies[i]=stored_frequency.new(nil, i);
}

var applySelectedFrequency = func () {
	var current_channel = getprop(base~"selected-channel");
	var current_channel_frequency = stored_frequencies[current_channel].frequency;
	if(current_channel_frequency != nil){
		setprop(base~"frequencies/selected-mhz", current_channel_frequency);
	}
	setprop(base~"channel-menu", 0);
	setprop(base~"selected-channel", 0);
}

var saveFrequency = func () {
	var current_channel = getprop(base~"selected-channel");
	var current_frequency = getprop(base~"/frequencies/selected-mhz");
	stored_frequencies[current_channel].set_frequency(current_frequency);
	setprop(base~"channel-menu", 0);
	setprop(base~"selected-channel", 0);
}

var canvas_AR6201_base = {
	init: func(canvas_group, file) {
		var font_mapper = func(family, weight) {
			return "LiberationFonts/LiberationSans-Bold.ttf";
		};

		
		canvas.parsesvg(canvas_group, file, {'font-mapper': font_mapper});

		 var svg_keys = me.getKeys();
		 
		foreach(var key; svg_keys) {
			me[key] = canvas_group.getElementById(key);
			var svg_keys = me.getKeys();
			foreach (var key; svg_keys) {
			me[key] = canvas_group.getElementById(key);
			var clip_el = canvas_group.getElementById(key ~ "_clip");
			if (clip_el != nil) {
				clip_el.setVisible(0);
				var tran_rect = clip_el.getTransformedBounds();
				var clip_rect = sprintf("rect(%d,%d, %d,%d)", 
				tran_rect[1], # 0 ys
				tran_rect[2], # 1 xe
				tran_rect[3], # 2 ye
				tran_rect[0]); #3 xs
				#   coordinates are top,right,bottom,left (ys, xe, ye, xs) ref: l621 of simgear/canvas/CanvasElement.cxx
				me[key].set("clip", clip_rect);
				me[key].set("clip-frame", canvas.Element.PARENT);
			}
			}
		}

		me.page = canvas_group;

		return me;
	},
	getKeys: func() {
		return [];
	},
	update: func() {
		var volt = volts.getValue();
		var volume = getprop(volume_prop) or 0;
		var start = getprop(start_prop) or 0;
		if ( start == 1 and volt > 9 and volume > 0 ) {
			AR6201_start.page.hide();
			var pilot_menu = getprop(pilotmenu_prop) or 0;
			var channel_menu = getprop(channelmenu_prop) or 0;
			if(pilot_menu==1){
				AR6201_only.page.hide();
				AR6201_brightness.page.show();
				AR6201_brightness.update();
				AR6201_squelch.page.hide();
				AR6201_sch.page.hide();
				AR6201_sach.page.hide();
			}else if(pilot_menu==2){
				AR6201_only.page.hide();
				AR6201_brightness.page.hide();
				AR6201_squelch.page.show();
				AR6201_squelch.update();
				AR6201_sch.page.hide();
				AR6201_sach.page.hide();
			}else if(channel_menu == 1){
				AR6201_only.page.hide();
				AR6201_brightness.page.hide();
				AR6201_squelch.page.hide();
				AR6201_sch.page.show();	
				AR6201_sch.update();
				AR6201_sach.page.hide();		
			}else if(channel_menu == 2){
				AR6201_only.page.hide();
				AR6201_brightness.page.hide();
				AR6201_squelch.page.hide();
				AR6201_sch.page.hide();	
				AR6201_sach.page.show();	
				AR6201_sach.update();
			}else{
				AR6201_only.page.show();
				AR6201_only.update();
				AR6201_brightness.page.hide();
				AR6201_squelch.page.hide();
				AR6201_sch.page.hide();
				AR6201_sach.page.hide();
			}
		} else if ( start > 0 and start < 1 and volt > 9 and volume > 0){
			AR6201_only.page.hide();
			AR6201_brightness.page.hide();
			AR6201_start.page.show();
			AR6201_squelch.page.hide();
			AR6201_sch.page.hide();
			AR6201_sach.page.hide();
		} else {
			AR6201_only.page.hide();
			AR6201_brightness.page.hide();
			AR6201_start.page.hide();
			AR6201_squelch.page.hide();
			AR6201_sch.page.hide();
			AR6201_sach.page.hide();
		}
		
		settimer(func me.update(), 0.02);
	},
};
	
	
var canvas_AR6201_only = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_AR6201_only , canvas_AR6201_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return ["TX","SQL","IC","SCAN","active_frq","standby_frq","change.mhz","change.mhz.digits","change.100khz","change.100khz.digits","change.khz","change.khz.digits"];
	},
	update: func() {
		
		var ptt = getprop(base~"ptt") or 0;
		if(ptt==1){
			me["TX"].show();
		}else{
			me["TX"].hide();
		}
		
		var squelch = getprop(base~"sq") or 0;
		if(squelch==1){
			me["SQL"].show();
		}else{
			me["SQL"].hide();
		}
		
		var IC = getprop(base~"intercom") or 0;
		if(IC==1){
			me["IC"].show();
		}else{
			me["IC"].hide();
		}
		
		var scan = getprop(base~"scan") or 0;
		if(scan==1){
			me["SCAN"].show();
		}else{
			me["SCAN"].hide();
		}
		
		var active_frequency = getprop(base~"frequencies/selected-mhz") or 0;
		me["active_frq"].setText(sprintf("%3.3f", active_frequency));
		
		var standby_frequency = getprop(base~"frequencies/standby-mhz") or 0;
		me["standby_frq"].setText(sprintf("%3.3f", standby_frequency));
		
		#Change logic: in standard mode, only standby freq can be directly changed. Change is done by turning the big knob, pressing it will switch the changed part from Mhz (first three digits) to 100Khz (first #digit after decimal point) and Khz (last two digits) -> in 8.33 KHz mode, in 25 KHz mode, there are only two digits after decimal point.
		#Encoding of change logic:
		#	nothing selected	0
		#	MHz			1
		#	100 KHz 		2
		#	KHz     		3
		#	Property: /instrumentation/comm[0]/current-change (int)
		
		var current_change = getprop(base~"current-change") or 0;
		
		if(current_change == 0){
			me["change.mhz"].hide();
			me["change.100khz"].hide();
			me["change.khz"].hide();
		}else if(current_change == 1){
			me["change.mhz"].show();
			me["change.100khz"].hide();
			me["change.khz"].hide();
			me["change.mhz.digits"].setText(sprintf("%3d", standby_frequency));
		}else if(current_change == 2){
			me["change.mhz"].hide();
			me["change.100khz"].show();
			me["change.khz"].hide();
			me["change.100khz.digits"].setText(sprintf("%1d", math.floor(math.mod(standby_frequency*100, 100)/10)));
		}else if(current_change == 3){
			me["change.mhz"].hide();
			me["change.100khz"].hide();
			me["change.khz"].show();
			me["change.khz.digits"].setText(sprintf("%02d", math.mod(standby_frequency*1000,100)));
		}
	}
	
};


var canvas_AR6201_start = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_AR6201_start , canvas_AR6201_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return [];
	},
	
};


var canvas_AR6201_brightness = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_AR6201_brightness , canvas_AR6201_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return ["brightness.bar","brightness.digits","active_frq"];
	},
	update: func() {
	
		var active_frequency = getprop(base~"frequencies/selected-mhz") or 0;
		me["active_frq"].setText(sprintf("%3.3f", active_frequency));
		
		var brightness = getprop(brightness_prop);
		
		me["brightness.digits"].setText(sprintf("%3d", brightness*100));
		me["brightness.bar"].setTranslation((1-brightness)*(-315),0);
	}
	
};


var canvas_AR6201_squelch = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_AR6201_squelch , canvas_AR6201_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return ["squelch.bar","squelch.digits","active_frq"];
	},
	update: func() {
	
		var active_frequency = getprop(base~"frequencies/selected-mhz") or 0;
		me["active_frq"].setText(sprintf("%3.3f", active_frequency));
		
		var squelch = getprop(squelch_prop);
		
		me["squelch.digits"].setText(sprintf("%3d", squelch));
		me["squelch.bar"].setTranslation((1-((squelch-6)/20))*(-315),0);
	}
	
};


var canvas_AR6201_sch = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_AR6201_sch , canvas_AR6201_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return ["channel.num","active_frq"];
	},
	update: func() {
	
		var active_frequency = getprop(base~"frequencies/selected-mhz") or 0;
		var channel = getprop(base~"selected-channel") or 0;
		
		if(channel==0 or channel>15){
			me["active_frq"].setText(sprintf("%3.3f", active_frequency));
			if(channel>15){
				me["channel.num"].setText(">>");
			}else{				
				me["channel.num"].setText("--");
			}
		}else{
			var use_freq = stored_frequencies[channel].frequency;
			if(use_freq != nil){
				me["active_frq"].setText(sprintf("%3.3f", use_freq));
			}else{
				me["active_frq"].setText(sprintf("%3.3f", active_frequency));
			}
			me["channel.num"].setText(sprintf("%02d", channel));
		}
	}
	
};


var canvas_AR6201_sach = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_AR6201_sach , canvas_AR6201_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return ["channel.num","active_frq","ind"];
	},
	update: func() {
	
		var active_frequency = getprop(base~"frequencies/selected-mhz") or 0;
		var channel = getprop(base~"selected-channel") or 0;
		
		me["active_frq"].setText(sprintf("%3.3f", active_frequency));
		
		if(channel==0 or channel>15){
			if(channel>15){
				me["channel.num"].setText(">>");
			}else{				
				me["channel.num"].setText("--");
			}
		}else{
			me["channel.num"].setText(sprintf("%02d", channel));
		}
		
		if(channel <= 15 and stored_frequencies[channel].frequency != nil){
			me["ind"].setText("USED");
		}else{
			me["ind"].setText("FREE");
		}
	}
	
};


var identoff = func {
	setprop("/instrumentation/transponder/inputs/ident-btn", 0);
}

setlistener("/instrumentation/transponder/inputs/ident-btn-2", func{
	setprop("/instrumentation/transponder/inputs/ident-btn", 1);
	settimer(identoff, 18);
});


setlistener("sim/signals/fdm-initialized", func {
	AR6201_display = canvas.new({
		"name": "AR6201",
		"size": [512, 256],
		"view": [512, 256],
		"mipmapping": 1
	});
	AR6201_display.addPlacement({"node": "ar6201.display"});
	var groupOnly = AR6201_display.createGroup();
	var groupStart = AR6201_display.createGroup();
	var groupBrightness = AR6201_display.createGroup();
	var groupSquelch = AR6201_display.createGroup();
	var groupSch = AR6201_display.createGroup();
	var groupSach = AR6201_display.createGroup();


	AR6201_only = canvas_AR6201_only.new(groupOnly, instrument_path~"ar6201.svg");
	AR6201_start = canvas_AR6201_start.new(groupStart, instrument_path~"ar6201-start.svg");
	AR6201_brightness = canvas_AR6201_brightness.new(groupBrightness, instrument_path~"ar6201-menu-brightness.svg");
	AR6201_squelch = canvas_AR6201_squelch.new(groupSquelch, instrument_path~"ar6201-menu-squelch.svg");
	AR6201_sch = canvas_AR6201_sch.new(groupSch, instrument_path~"ar6201-select-channel.svg");
	AR6201_sach = canvas_AR6201_sach.new(groupSach, instrument_path~"ar6201-save-channel.svg");

	AR6201_only.update();
	AR6201_brightness.update();
	AR6201_squelch.update();
	AR6201_sch.update();
	AR6201_sach.update();
	canvas_AR6201_base.update();
});

var showAR6201 = func {
	var dlg = canvas.Window.new([512, 256], "dialog").set("resize", 1);
	dlg.setCanvas(AR6201_display);
}

var stop1 = 0;
var stop2 = 0;
var stop3 = 0;

var sqlicpressed = func () {
	var time_passed = getprop(base~"sql-ic-pressed-time") or 0;
	var pressed = getprop(base~"sql-ic-pressed") or 0;
	if(pressed){
		if( time_passed > 2 and stop1 != 1) {
			var intercom = getprop(base~"intercom");
			if(intercom==0){
				setprop("instrumentation/comm[0]/intercom", 1);
			}else{
				setprop("instrumentation/comm[0]/intercom", 0);
			}
			stop1 = 1;
		}
		setprop(base~"sql-ic-pressed-time", time_passed + 0.1);
		settimer(sqlicpressed, 0.1);		
	} else {
		if(time_passed<2){
			var sq = getprop(base~"sq");
			if(sq==0){
				setprop("instrumentation/comm[0]/sq", 1);
			}else{
				setprop("instrumentation/comm[0]/sq", 0);
			}
		}
		setprop(base~"sql-ic-pressed-time", 0);
		stop1 = 0;
		
	}
}

var swap_freqs = func () {
	var active_prop = base~"frequencies/selected-mhz";
	var standby_prop = base~"frequencies/standby-mhz";
	var active = getprop(active_prop) or 0;
	var standby = getprop(standby_prop) or 0;
	
	var i=1;
	var fail=0;
	while(i<6){
		var frq=stored_frequencies[i].frequency;
		if(frq==nil){
			stored_frequencies[i].set_frequency(active);
			break;
		}else if(i==5){
			fail=1;
		}
		i=i+1;
	}
	if(fail==1){
		stored_frequencies[1].set_frequency(active);
	}
	
	setprop(active_prop, standby);
	setprop(standby_prop, active);
}

var swapscanpressed = func () {
	var time_passed = getprop(base~"swap-scan-pressed-time") or 0;
	var pressed = getprop(base~"swap-scan-pressed") or 0;
	if(pressed){
		if( time_passed > 2 and stop2 != 1) {
			var scan = getprop(base~"scan");
			if(scan==0){
				setprop("instrumentation/comm[0]/scan", 1);
			}else{
				setprop("instrumentation/comm[0]/scan", 0);
			}
			stop2 = 1;
		}
		setprop(base~"swap-scan-pressed-time", time_passed + 0.1);
		settimer(swapscanpressed, 0.1);
	} else {
		if(time_passed<2){
			swap_freqs();
		}
		setprop(base~"swap-scan-pressed-time", 0);
		stop2 = 0;
		
	}
}

var modepressed = func () {
	var short_prop = "instrumentation/comm[0]/channel-menu";
	var long_prop = "instrumentation/comm[0]/pilot-menu";
	var time_prop = "instrumentation/comm[0]/mode-pressed-time";
	var time_passed = getprop(time_prop) or 0;
	var pressed = getprop(base~"mode-pressed") or 0;
	if(pressed){
		if( time_passed > 2 and stop3 != 1) {
			var pm = getprop(long_prop);
			if(pm==0){
				setprop(long_prop, 1);
			}else{
				setprop(long_prop, 0);
			}
			stop3 = 1;
		}
		setprop(time_prop, time_passed + 0.1);
		settimer(modepressed, 0.1);
	} else {
		if(time_passed<2){
			var sch = getprop(short_prop);
			if(sch==0){
				setprop(short_prop,1);
			}else{
				setprop(short_prop,0);
			}
		}
		setprop(time_prop, 0);
		stop3 = 0;
		
	}
}

setlistener(volume_prop, func{
	if(getprop(volume_prop) > 0 and volts.getValue() > 9 and getprop(start_prop) == 0){
		interpolate(start_prop, 1, 5 );
	}else if( ( getprop(volume_prop) == 0 or volts.getValue() <= 9 ) and getprop(start_prop) != 0){
		setprop(start_prop, 0);
	}
});

setlistener(volt_prop, func{
	if(getprop(volume_prop) > 0 and volts.getValue() > 9 and getprop(start_prop) == 0){
		interpolate(start_prop, 1, 5 );
	}else if( ( getprop(volume_prop) == 0 or volts.getValue() <= 9 ) and getprop(start_prop) != 0){
		setprop(start_prop, 0);
	}
});

setlistener(base~"channel-menu", func{
	if(getprop(base~"channel-menu")==0){
		setprop(base~"selected-channel", 0);
	}else if(getprop(base~"channel-menu")==2){
		var i=6;
		var fail=0;
		while(i<16){
			var frq=stored_frequencies[i].frequency;
			if(frq==nil){
				setprop(base~"selected-channel", i);
				break;
			}else if(i==15){
				fail=1;
			}
			i=i+1;
		}
		if(fail==1){
			setprop(base~"selected-channel", 6);
		}
	}
});
	
