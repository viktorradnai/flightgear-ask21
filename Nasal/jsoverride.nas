var jsoverride = func {

    var button = props.globals.getNode("/input/joysticks/js/button");
    if (button == nil) return;

    print('Overriding buttons on joystick "' ~ props.globals.getNode("/input/joysticks/js/name").getValue() ~ '".');

    binding = button.getNode("binding");
    if (binding == nil) {
        binding = button.addChild("binding");
    }

    binding.addChild("command");
    binding.addChild("property");
    binding.addChild("value");

    if (button.getNode("binding[1]") == nil) {
        b = button.addChild("binding");
        b.addChild("command");
        b.addChild("property");
        b.addChild("value");
    }

    if (button.getNode("binding[2]") == nil) {
        b = button.addChild("binding");
        b.addChild("command");
        b.addChild("property");
        b.addChild("value");
    }

    b = button.getNode("mod-up/binding");
    if (b == nil) {
        m = button.addChild("mod-up");
        b = m.addChild("binding");
    }

    b.addChild("command");
    b.addChild("property");
    b.addChild("value");

    button.getNode("binding/command").setValue("property-assign");
    button.getNode("binding/property").setValue("/sim/hitches/hook-open");
    button.getNode("binding/value").setValue("true");
    button.getNode("binding[1]/command").setValue("property-assign");
    button.getNode("binding[1]/property").setValue("/sim/hitches/aerotow/open");
    button.getNode("binding[1]/value").setValue("true");
    button.getNode("binding[2]/command").setValue("property-assign");
    button.getNode("binding[2]/property").setValue("/sim/hitches/winch/open");
    button.getNode("binding[2]/value").setValue("true");
    button.getNode("mod-up/binding/command").setValue("property-assign");
    button.getNode("mod-up/binding/property").setValue("/sim/hitches/hook-open");
    button.getNode("mod-up/binding/value").setValue("false");
}

jsoverride()
