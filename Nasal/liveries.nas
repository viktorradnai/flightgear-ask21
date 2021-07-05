if( getprop("/sim/aero") == "ask21" or getprop("/sim/aero") == "ask21-jsb" ){
	aircraft.livery.init("Aircraft/ASK21/Models/Liveries/glider");
} else {
	aircraft.livery.init("Aircraft/ASK21/Models/Liveries/mi");
}

