#Helper functions to print messages

var msg = func ( destination, string ) {
	setprop("/sim/messages/"~destination, string);
}