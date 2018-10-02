# Total Energy compensated variometers

io.include("Aircraft/Generic/soaring-instrumentation-sdk.nas");

var probe = TotalEnergyProbe.new();

var needle1 = Dampener.new(
	input: probe,
	dampening: 2.3,
	on_update: update_prop("/instrumentation/variometer/te-reading-mps"));

var needle2 = Dampener.new(
	input: probe,
	dampening: 3,
	on_update: update_prop("/instrumentation/te-vario/te-reading2-mps"));

var instrument = Instrument.new(
	components: [probe, needle1, needle2],
	enable: 1);
