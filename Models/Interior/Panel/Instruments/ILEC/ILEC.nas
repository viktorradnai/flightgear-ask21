# ILEC Engine Instrument by D-ECHO based on

# A3XX Lower ECAM Canvas
# Joshua Davidson (it0uchpods)
#######################################

var ILEC_only = nil;
var ILEC_display = nil;
var page = "only";
var ILEC_flight_counter = 0;
var ILEC_flight_counter_stop = 0;
var ILEC_up_counter = 0;
var ILEC_down_counter = 0;
setprop("/engines/engine[0]/engine-rpm", 0);

var canvas_ILEC_base = {
	init: func(canvas_group, file) {
		var font_mapper = func(family, weight) {
			return "LiberationFonts/LiberationSans-Bold.ttf";
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
			ILEC_only.page.show();
		} else {
			ILEC_only.page.hide();
		}
		
		settimer(func me.update(), 0.02);
	},
};
	
	
var canvas_ILEC_only = {
	new: func(canvas_group, file) {
		var m = { parents: [canvas_ILEC_only , canvas_ILEC_base] };
		m.init(canvas_group, file);

		return m;
	},
	getKeys: func() {
		return ["LeftInd", "RightInd"];
	},
	update: func() {
	
			
	
	if(getprop("/engines/engine[0]/engine-rpm")>=1000){
		me["LeftInd"].setText(sprintf("%s", math.round(getprop("/engines/engine[0]/engine-rpm") or 0,100)));
	}else{
		me["LeftInd"].setText(sprintf("%s", 0000));
	}
	me["RightInd"].setText(sprintf("%s", math.round(getprop("/consumables/fuel/tank/level-m3")*1000,1)));

		settimer(func me.update(), 0.1);
	},
};



setlistener("sim/signals/fdm-initialized", func {
	ILEC_display = canvas.new({
		"name": "ILEC",
		"size": [320, 128],
		"view": [320, 128],
		"mipmapping": 1
	});
	ILEC_display.addPlacement({"node": "ILEC.screen"});
	var groupOnly = ILEC_display.createGroup();

	ILEC_only = canvas_ILEC_only.new(groupOnly, "Aircraft/ASK21/Models/Interior/Panel/Instruments/ILEC/ILEC-display.svg");

	ILEC_only.update();
	canvas_ILEC_base.update();
});

var showILEC = func {
	var dlg = canvas.Window.new([128, 512], "dialog").set("resize", 1);
	dlg.setCanvas(ILEC_display);
}
