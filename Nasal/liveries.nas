aircraft.livery.init("Aircraft/ASK21/Models/Liveries");

# Canvas Dynamic Liveries, based on wiki: http://wiki.flightgear.org/Howto:Dynamic_Liveries_via_Canvas
# Setup
var path="Aircraft/ASK21/Models/";
var immat_visible = 1;

var fuselage_canvas = canvas.new({
	"name": "Fuselage Livery Canvas",
	"size": [2048, 1024],
	"view": [2048, 1024],
	"mipmapping": 1
});

var wings_canvas = canvas.new({
	"name": "Wings Livery Canvas",
	"size": [1024, 1024],
	"view": [1024, 1024],
	"mipmapping": 1
});

var raster_group = fuselage_canvas.createGroup();
var immat_group = fuselage_canvas.createGroup();

var raster_w_group = wings_canvas.createGroup();
var immat_w_group = wings_canvas.createGroup();

var fuselage_objects = ["fuselage", "fuselage-mi","engdoorL","engdoorR","gearfairing1","gearfairing1mi", "gearfairing2","gearfairing3", "vstabilizer","elevator","hstabilizer","rudder"];
var wing_objects = ["wing.L1","wing.L2","wing.L3","wing.L4","wing.R1","wing.R2","wing.R3","wing.R4","aileronL","aileronR"];
foreach(var key; fuselage_objects){
	fuselage_canvas.addPlacement({"node": key});
}
foreach(var key; wing_objects){
	wings_canvas.addPlacement({"node": key});
}

# hash with all images added
var layers = {};

var add_raster_texture = func ( group, size_x, image ) {
	if(contains(layers, image)) return;
		#print("Warning: replacing texture (added twice): ", image);
	layers[image] = group.createChild("image").setFile( path~image ).setSize(size_x,1024);
}
# texture path
foreach(var image; ['blank.png',]) {
	add_raster_texture( raster_group, 2048, image );
}
foreach(var image; ['blank-wings.png',]) {
	add_raster_texture( raster_w_group, 1048, image );
}

canvas.parsesvg(immat_group, path~'immat.svg');
canvas.parsesvg(immat_w_group, path~'immat_wings.svg');

var immat = [ immat_group.getElementById("immat.1"), immat_group.getElementById("immat.2"), immat_w_group.getElementById("immat_w.1") ];
var immat_c = [ immat_group.getElementById("immat_c.1"), immat_group.getElementById("immat_c.2"), immat_w_group.getElementById("immat_w_c.1") ];

var update_immat = func () {
	print("Called");
	print("Immat: "~getprop("sim/model/immat"));
	foreach(var key; immat){
		key.setColor(getprop("sim/model/immat-r"), getprop("sim/model/immat-g"), getprop("sim/model/immat-b"));
		key.setFont(getprop("sim/model/immat-font"));
		key.setText(getprop("sim/model/immat"));
	}
	foreach(var key; immat_c){
		key.setColor(getprop("sim/model/immat-r"), getprop("sim/model/immat-g"), getprop("sim/model/immat-b"));
		key.setFont(getprop("sim/model/immat-font"));
		key.setText(getprop("sim/model/immat-competition"));
	}
}

var update_immat_vis = func () {
	var v = getprop("sim/model/livery/show-immat");
	if ( v == 1 and immat_visible == 0){
		foreach(var key; immat){
			key.show();
		}
		foreach(var key; immat_c){
			key.show();
		}
		update_immat();
		immat_visible = 1;
	} else if ( v == 0 and immat_visible == 1 ){
		foreach(var key; immat){
			key.hide();
		}
		foreach(var key; immat_c){
			key.hide();
		}
		immat_visible = 0;
	}
}

var update_livery = func () {
	var livery_string = getprop("sim/model/livery/texture");
	var livery_wing_string = getprop("sim/model/livery/texture-wing");
	add_raster_texture( raster_group, 2048, livery_string );
	add_raster_texture( raster_w_group, 1024, livery_wing_string );
	foreach(var layer; keys(layers)){
		if ( layer != livery_string and layer != livery_wing_string ) {
			#print(layer~" hide");
			layers[layer].hide();
		} else {
			#print(layer~" show");
			layers[layer].show();
		}
	}
}

setlistener("sim/model/immat-trigger", update_immat);
setlistener("sim/model/livery/texture-wing", update_livery);
setlistener("sim/model/livery/show-immat", update_immat_vis);

var sl = setlistener("/sim/signals/fdm-initialized", func() {
	update_immat();
	update_immat_vis();
	update_livery();
	removelistener(sl);
});
