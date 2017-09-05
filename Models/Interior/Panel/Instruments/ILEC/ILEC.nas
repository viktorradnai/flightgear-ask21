# Garmin GTX 327 by D-ECHO based on

# A3XX Lower ECAM Canvas
# Joshua Davidson (it0uchpods)
#######################################

var GTX327_only = nil;
var GTX327_display = nil;
var page = "only";
var GTX327_flight_counter = 0;
var GTX327_flight_counter_stop = 0;
var GTX327_up_counter = 0;
var GTX327_down_counter = 0;
setprop("/engines/engine[0]/rpm", 0);
setprop("/instrumentation/transponder/inputs/digitnbr", 1);
setprop("/instrumentation/transponder/inputs/ident-btn", 0);
setprop("/instrumentation/transponder/inputs/ident-btn-2", 0);
setprop("/instrumentation/GTX327/start", 0);
setprop("/instrumentation/GTX327/stop", 0);
setprop("/instrumentation/GTX327/func", 1);
setprop("/systems/electrical/avionics1-bus/GTX327", 0);

var canvas_GTX327_base = {
	init: func(canvas_group, file) {
		var font_mapper = func(family, weight) {
			#return "LiberationFonts/LiberationMono-Bold.ttf";
		};

		canvas.parsesvg(canvas_group, file, {'font-mapper': font_mapper});

		var svg_keys = me.getKeys();
		foreach(var key; svg_keys) {
			me[key] = canvas_group.getElementById(key);
		}

		me.page = canvas_group;

		return me;
	},
	getKeys: func() {
		return [];
	},
	update: func() {
		if (getprop("/controls/electric/battery-switch") == 1) {
			GTX327_only.page.show();
		} else {
			GTX327_only.page.hide();
		}
		
		settimer(func me.update(), 0.02);
	},
};
	
	
var canvas_GTX327_only = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_GTX327_only , canvas_GTX327_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return ["LeftInd", "RightInd"];
	},
	update: func() {
	
			
	
	if(getprop("/engines/engine[0]/rpm")>=1000){
		me["LeftInd"].setText(sprintf("%s", math.round(getprop("/engines/engine[0]/engine-rpm") or 0,100)));
	}else{
		me["LeftInd"].setText(sprintf("%s", 0000));
	}
	me["RightInd"].setText(sprintf("%s", math.round(getprop("/consumables/fuel/tank/level-m3")*1000,1)));

		settimer(func me.update(), 0.02);
	},
};


var identoff = func {
	setprop("/instrumentation/transponder/inputs/ident-btn", 0);
}

setlistener("/instrumentation/transponder/inputs/ident-btn-2", func{
	setprop("/instrumentation/transponder/inputs/ident-btn", 1);
	settimer(identoff, 18);
});


setlistener("sim/signals/fdm-initialized", func {
	GTX327_display = canvas.new({
		"name": "GTX327",
		"size": [1280, 512],
		"view": [1280, 512],
		"mipmapping": 1
	});
	GTX327_display.addPlacement({"node": "ILEC.screen"});
	var groupOnly = GTX327_display.createGroup();

	GTX327_only = canvas_GTX327_only.new(groupOnly, "Aircraft/ASK21/Models/Interior/Panel/Instruments/ILEC/ILEC-display.svg");

	GTX327_only.update();
	canvas_GTX327_base.update();
});

var showGTX327 = func {
	var dlg = canvas.Window.new([128, 512], "dialog").set("resize", 1);
	dlg.setCanvas(GTX327_display);
}
