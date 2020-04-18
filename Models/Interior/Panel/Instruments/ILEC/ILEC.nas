# ILEC Engine Instrument by D-ECHO based on

# A3XX Lower ECAM Canvas
# Joshua Davidson (it0uchpods)
#######################################

var ILEC_only = nil;
var ILEC_display = nil;

var engine	=	props.globals.getNode("/engines/engine[0]/");
var eng_rpm	=	engine.getNode("engine-rpm", 1);

var fuel_level	=	props.globals.getNode("/consumables/fuel/tank/level-m3", 1);

var volts	=	props.globals.getNode("/systems/electrical/volts", 1);

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
		if (volts.getValue() >= 9) {
			ILEC_only.page.show();
			ILEC_only.update();
		} else {
			ILEC_only.page.hide();
		}
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
		var rpm = eng_rpm.getValue();
		if( rpm >= 1000 ){
			me["LeftInd"].setText(sprintf("%4d", math.round(rpm,100)));
		}else{
			me["LeftInd"].setText(sprintf("%4d", 0));
		}
		me["RightInd"].setText(sprintf("%2d", math.round( fuel_level.getValue() *1000,1)));
	},
};


var ilec_update = maketimer(0.1, func {
	canvas_ILEC_base.update();
});

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
	
	ilec_update.start();
});
