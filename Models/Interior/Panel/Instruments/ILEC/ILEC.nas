# ILEC Engine Instrument by Benedikt Wolf (D-ECHO)

var engine	=	props.globals.getNode("/engines/engine[0]/");
var eng_rpm	=	engine.getNode("engine-rpm", 1);

var fuel_level	=	props.globals.getNode("/consumables/fuel/tank/level-m3", 1);

var powered_p	=	props.globals.getNode("/instrumentation/ilec/powered", 1);
var powered	=	0;

var mode	=	props.globals.initNode("/instrumentation/ilec/mode", 0, "INT");

var selftest	=	props.globals.initNode("/instrumentation/ilec/selftest", 0, "INT");	# 0 = not done, 1 = running; 2 = done
var selftest_timer = maketimer( 1.0, func { selftest.setIntValue( 2 ); } );
selftest_timer.singleShot = 1;
selftest_timer.simulatedTime = 1;

var rpm_flash	=	{
	obj:	aircraft.light.new( "/instrumentation/ilec/rpm-flashing", [ 0.5, 0.3 ] ),
	state:		props.globals.getNode("/instrumentation/ilec/rpm-flashing/state", 1 ),
};
setlistener( powered_p, func {
	if( powered_p.getBoolValue() ){
		if( selftest.getIntValue() == 0 ){
			selftest.setIntValue( 1 );
			selftest_timer.start();
		}
	} else {
		if( selftest.getIntValue() != 0 ){
			selftest.setIntValue( 0 );
		}
	}
});

