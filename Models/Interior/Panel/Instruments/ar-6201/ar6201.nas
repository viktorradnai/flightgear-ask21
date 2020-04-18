# Becker Avionics AR-6201 by Benedikt Wolf (D-ECHO) based on A320 canvas avionics by Joshua Davidson
# Reference: http://www.becker-avionics.com/wp-content/uploads/2017/08/AR620X_IO.pdf

var AR6201_main = nil;
var AR6201_start = nil;
var AR6201_brightness = nil;
var AR6201_squelch = nil;
var AR6201_sch = nil;
var AR6201_sach = nil;
var AR6201_display = nil;

var base		=	props.globals.getNode("/instrumentation/comm[0]/", 1);
var squelch_bool	=	base.initNode("sq", 1, "BOOL");
var squelch_lim		=	base.initNode("squelch-lim", 0.0, "DOUBLE");
var volume		=	base.initNode("volume", 0.0, "DOUBLE");
var start		=	base.initNode("start", 0.0, "DOUBLE");
var pilotmenu_prop	=	base.initNode("pilot-menu", 0, "INT");
var channelmenu_prop	=	base.initNode("channel-menu", 0, "INT");
var brightness_prop	=	base.initNode("brightness", 0.0, "DOUBLE");
var selchannel		=	base.initNode("selected-channel", 0, "INT");
var ptt			=	base.initNode("ptt", 0, "BOOL");
var intercom		=	base.initNode("intercom", 0, "BOOL");
var scan		=	base.initNode("scan", 0, "BOOL");
var current_change	=	base.initNode("current-change", 0, "INT");
var ssp			=	base.initNode("swap-scan-pressed", 0, "BOOL");
var mop			=	base.initNode("mode-pressed", 0, "BOOL");
var sqi			=	base.initNode("sql-ic-pressed", 0, "BOOL");

var volts		=	props.globals.getNode("/systems/electrical/outputs/comm[0]", 1);

var freq		=	base.getNode("frequencies");
var freq_sel		=	freq.getNode("selected-mhz");
var freq_sby		=	freq.getNode("standby-mhz");

var instrument_path = "Aircraft/HK36/Models/Instruments/ar-6201/";

var state = 0;	# 0 = off; 1 = starting; 2 = running

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
	freq_sel.setValue( stored_frequencies[ selchannel.getValue() ].frequency );
	channelmenu_prop.setValue(0);
	selchannel.setValue(0);
}

var saveFrequency = func () {
	stored_frequencies[ selchannel.getValue() ].set_frequency( freq_sel.getValue() );
	channelmenu_prop.setValue(0);
	selchannel.setValue(0);
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
		var sv = start.getValue();
		if ( sv == 1 and volts.getValue() >= 9 and volume.getValue() > 0 ) {
			AR6201_start.page.hide();
			var pilot_menu = pilotmenu_prop.getValue();
			var channel_menu = channelmenu_prop.getValue();
			if(pilot_menu==1){
				AR6201_main.page.hide();
				AR6201_brightness.page.show();
				AR6201_brightness.update();
				AR6201_squelch.page.hide();
				AR6201_sch.page.hide();
				AR6201_sach.page.hide();
			}else if(pilot_menu==2){
				AR6201_main.page.hide();
				AR6201_brightness.page.hide();
				AR6201_squelch.page.show();
				AR6201_squelch.update();
				AR6201_sch.page.hide();
				AR6201_sach.page.hide();
			}else if(channel_menu == 1){
				AR6201_main.page.hide();
				AR6201_brightness.page.hide();
				AR6201_squelch.page.hide();
				AR6201_sch.page.show();	
				AR6201_sch.update();
				AR6201_sach.page.hide();		
			}else if(channel_menu == 2){
				AR6201_main.page.hide();
				AR6201_brightness.page.hide();
				AR6201_squelch.page.hide();
				AR6201_sch.page.hide();	
				AR6201_sach.page.show();
				AR6201_sach.update();
			}else{
				AR6201_main.page.show();
				AR6201_main.update();
				AR6201_brightness.page.hide();
				AR6201_squelch.page.hide();
				AR6201_sch.page.hide();
				AR6201_sach.page.hide();
			}
		} else if ( sv > 0 and sv < 1 and volts.getValue() >= 9 and volume.getValue() > 0){
			AR6201_main.page.hide();
			AR6201_brightness.page.hide();
			AR6201_start.page.show();
			AR6201_squelch.page.hide();
			AR6201_sch.page.hide();
			AR6201_sach.page.hide();
		} else {
			AR6201_main.page.hide();
			AR6201_brightness.page.hide();
			AR6201_start.page.hide();
			AR6201_squelch.page.hide();
			AR6201_sch.page.hide();
			AR6201_sach.page.hide();
		}
	},
};
	
	
var canvas_AR6201_main = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_AR6201_main , canvas_AR6201_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return ["TX","SQL","IC","SCAN","active_frq","standby_frq","change.mhz","change.mhz.digits","change.100khz","change.100khz.digits","change.khz","change.khz.digits"];
	},
	update: func() {
		
		if(ptt.getValue() == 1){
			me["TX"].show();
		}else{
			me["TX"].hide();
		}
		
		if(squelch_bool.getValue() == 1){
			me["SQL"].show();
		}else{
			me["SQL"].hide();
		}
		
		if(intercom.getValue() == 1){
			me["IC"].show();
		}else{
			me["IC"].hide();
		}
		
		if(scan.getValue() == 1){
			me["SCAN"].show();
		}else{
			me["SCAN"].hide();
		}
		
		me["active_frq"].setText(sprintf("%3.3f", freq_sel.getValue()));
		
		var standby_frequency = freq_sby.getValue();
		me["standby_frq"].setText(sprintf("%3.3f", standby_frequency));
		
		#Change logic: in standard mode, only standby freq can be directly changed. Change is done by turning the big knob, pressing it will switch the changed part from Mhz (first three digits) to 100Khz (first #digit after decimal point) and Khz (last two digits) -> in 8.33 KHz mode, in 25 KHz mode, there are only two digits after decimal point.
		#Encoding of change logic:
		#	nothing selected	0
		#	MHz			1
		#	100 KHz 		2
		#	KHz     		3
		#	Property: /instrumentation/comm[0]/current-change (int)
				
		if(current_change.getValue() == 0){
			me["change.mhz"].hide();
			me["change.100khz"].hide();
			me["change.khz"].hide();
		}else if(current_change.getValue() == 1){
			me["change.mhz"].show();
			me["change.100khz"].hide();
			me["change.khz"].hide();
			me["change.mhz.digits"].setText(sprintf("%3d", standby_frequency));
		}else if(current_change.getValue() == 2){
			me["change.mhz"].hide();
			me["change.100khz"].show();
			me["change.khz"].hide();
			me["change.100khz.digits"].setText(sprintf("%1d", math.floor(math.mod(standby_frequency*100, 100)/10)));
		}else if(current_change.getValue() == 3){
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
	update: func() {
	}
	
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
		me["active_frq"].setText(sprintf("%3.3f", freq_sel.getValue()));
		
		var brightness = brightness_prop.getValue();
		
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
		me["active_frq"].setText(sprintf("%3.3f", freq_sel.getValue()));
		
		var squelch = squelch_lim.getValue();
		
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
		var channel = selchannel.getValue();
		
		if( channel==0 or channel>15){
			me["active_frq"].setText(sprintf("%3.3f", freq_sel.getValue()));
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
				me["active_frq"].setText(sprintf("%3.3f", freq_sel.getValue()));
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
		var channel = selchannel.getValue();
		
		me["active_frq"].setText(sprintf("%3.3f", freq_sel.getValue()));
		
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


var ar6201_update = maketimer(0.1, func {
	canvas_AR6201_base.update();
});

setlistener("sim/signals/fdm-initialized", func {
	AR6201_display = canvas.new({
		"name": "AR6201",
		"size": [1024, 512],
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


	AR6201_main = canvas_AR6201_main.new(groupOnly, instrument_path~"ar6201.svg");
	AR6201_start = canvas_AR6201_start.new(groupStart, instrument_path~"ar6201-start.svg");
	AR6201_brightness = canvas_AR6201_brightness.new(groupBrightness, instrument_path~"ar6201-menu-brightness.svg");
	AR6201_squelch = canvas_AR6201_squelch.new(groupSquelch, instrument_path~"ar6201-menu-squelch.svg");
	AR6201_sch = canvas_AR6201_sch.new(groupSch, instrument_path~"ar6201-select-channel.svg");
	AR6201_sach = canvas_AR6201_sach.new(groupSach, instrument_path~"ar6201-save-channel.svg");

	ar6201_update.start();
});

var stop1 = 0;
var stop2 = 0;
var stop3 = 0;

var sqi_time = 0.0;

var sqlicpressed = func () {
	if(sqi.getValue()){
		if( sqi_time > 2 and stop1 != 1) {
			if(intercom.getValue() == 0){
				intercom.setValue( 1 );
			}else{
				intercom.setValue( 0 );
			}
			stop1 = 1;
		}
		sqi_time = sqi_time + 0.1;
		settimer(sqlicpressed, 0.1);		
	} else {
		if(sqi_time < 2){
			if(squelch_bool.getValue() == 0){
				squelch_bool.setValue( 1 );
			}else{
				squelch_bool.setValue( 0 );
			}
		}
		sqi_time = 0.0;
		stop1 = 0;
		
	}
}

var swap_freqs = func () {
	var sel = freq_sel.getValue();
	
	var i=1;
	var fail=0;
	while(i<6){
		var frq=stored_frequencies[i].frequency;
		if(frq==nil){
			stored_frequencies[i].set_frequency( sel );
			break;
		}else if(i==5){
			fail=1;
		}
		i=i+1;
	}
	if(fail==1){
		stored_frequencies[1].set_frequency( sel );
	}
	
	freq_sel.setValue( freq_sby.getValue() );
	freq_sby.setValue( sel );
}

var ssp_time = 0.0;

var swapscanpressed = func () {
	var pressed = ssp.getValue();
	if(pressed){
		if( ssp_time > 2 and stop2 != 1) {
			if(scan.getValue() == 0){
				scan.setValue(1);
			}else{
				scan.setValue(0);
			}
			stop2 = 1;
		}
		ssp_time = ssp_time + 0.1;
		settimer(swapscanpressed, 0.1);
	} else {
		if( ssp_time < 2){
			swap_freqs();
		}
		ssp_time = 0;
		stop2 = 0;
		
	}
}

var mop_time = 0.0;

var modepressed = func () {
	var short_prop = "instrumentation/comm[0]/channel-menu";
	var long_prop = "instrumentation/comm[0]/pilot-menu";
	
	if( mop.getValue() ){
		if( mop_time > 2 and stop3 != 1) {
			if(pilotmenu_prop.getValue() == 0){
				pilotmenu_prop.setValue( 1 );
			} else {
				pilotmenu_prop.setValue( 0 );
			}
			stop3 = 1;
		}
		mop_time = mop_time + 0.1;
		settimer(modepressed, 0.1);
	} else {
		if( mop_time < 2 ){
			if( channelmenu_prop.getValue() == 0 ){
				channelmenu_prop.setValue( 1 );
			} else {
				channelmenu_prop.setValue( 0 );
			}
		}
		mop_time = 0;
		stop3 = 0;
		
	}
}

var check_state = func () {
	if ( state == 0 ){
		if ( volts.getValue() >= 9 and volume.getValue() > 0 ) {
			state = 1;
			start.setValue(0.5);
			settimer(	func() { start.setValue(1); },	5);
			#interpolate(start, 1, 5);
		}
	} else {
		if ( volts.getValue() < 9 or volume.getValue() == 0 ){
			state = 0;
			start.setValue(0);
		}
	}
}


setlistener(volume, func{
	check_state();
});

setlistener(volts, func{
	check_state();
});

setlistener(channelmenu_prop, func{
	if ( channelmenu_prop.getValue() == 0 ){
		selchannel.setValue(0);
	} else if ( channelmenu_prop.getValue() == 2 ){
		var i = 6;
		var fail = 0;
		while ( i < 16 ){
			var frq = stored_frequencies[i].frequency;
			if ( frq == nil ){
				selchannel.setValue(i);
				break;
			} else if ( i == 15 ) {
				fail = 1;
			}
			i = i + 1;
		}
		if ( fail == 1 ){
			selchannel.setValue(6);
		}
	}
});
	
