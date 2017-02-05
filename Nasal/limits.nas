# $Id$
#
# Nasal script to print errors to the screen when aircraft exceed design limits:
#  - extending spoiler above maximum spoiler extension speed(s)
#  - exceeding Vne 
#  - exceeding Vno (->Caution)
#  - exceeding structural G limits
# Taken from Aircraft/Generic and adapted for ASK21

var checkSpoiler = func(n) {
  var spoilersetting = n.getValue();
  if (spoilersetting == 1)
    return;

  var airspeed = getprop("velocities/airspeed-kt");
  var ltext = "";
  var speed = getprop("limits/max-spoiler-extension-speed");


    if ((speed != nil) and (spoilersetting < 1) and (airspeed > speed)       )  {
          ltext = "Spoilers extended above maximum spoiler extension speed!";
        }

    if (ltext != "")
    {
      screen.log.write(ltext);
    }
  
}


# Set the listeners
setlistener("controls/engines/engine/throttle", checkSpoiler);

var checkG = func{
  if (getprop("/sim/freeze/replay-state"))
    return;

  var airspeed = getprop("velocities/airspeed-kt");
  var vne      = getprop("limits/vne");
  var vmo      = getprop("limits/vmo");
  var g = getprop("/accelerations/pilot-g") or 1;
  var max_positive_vmo = getprop("limits/max-positive-g-vmo");
  var max_negative_vmo = getprop("limits/max-negative-g-vmo");
  var max_positive_vne = getprop("limits/max-positive-g-vne");
  var max_negative_vne = getprop("limits/max-negative-g-vne");
  var msg = "";

  if ((max_positive_vmo != nil) and (airspeed <= vmo) and (g > max_positive_vmo))
  {
    msg = "Airframe structural positive-g load under manoeuvering speed limit exceeded!";
  }else if ((max_positive_vne != nil) and airspeed > vmo  and (g > max_positive_vne)){
    msg = "Airframe structural positive-g load above manoeuvering speed limit exceeded!";
    }
    
  if ((max_negative_vmo != nil) and (airspeed <= vmo) and (g < max_negative_vmo))
  {
    msg = "Airframe structural negative-g load under manoeuvering speed limit exceeded!";
  }else if ((max_negative_vne != nil) and airspeed > vmo  and (g < max_negative_vne)){
    msg = "Airframe structural negative-g load above manoeuvering speed limit exceeded!";
    }
  
  
  if (msg != ""){
    # If we have a message, display it, but don't bother checking for
    # any other errors for 5 seconds. Otherwise we're likely to get
    # repeated messages.
    screen.log.write(msg);
    settimer(checkG, 5);
  }else{
    settimer(checkG, 1);
  }
}

var checkVNE = func {
  if (getprop("/sim/freeze/replay-state"))
    return;

  var airspeed = getprop("velocities/airspeed-kt");
  var vne      = getprop("limits/vne");
  var vmo      = getprop("limits/vmo");
  var msg = "";

  if ((airspeed != nil) and (vne != nil) and (airspeed > vne))
  {
    msg = "Airspeed exceeds Vne!";
  } else if ((airspeed != nil) and (vmo != nil) and (airspeed > vmo))
    {
    msg = "Caution: Airspeed exceeds Vmo!";
  }

  
  
  if (msg != "")
  {
    # If we have a message, display it, but don't bother checking for
    # any other errors for 5 seconds. Otherwise we're likely to get
    # repeated messages.
    screen.log.write(msg);
    settimer(checkVNE, 5);
  }
  else
  {
    settimer(checkVNE, 1);
  }
}

var checkMTOW = func{
  if (getprop("/sim/freeze/replay-state"))
    return;

  var gw = getprop("fdm/yasim/gross-weight-lbs");
  var mtow = getprop("limits/mtow-lbs");
  var msg = "";
  
  if ((mtow != nil) and (gw != nil) and (gw > mtow))
  {
    msg = "Maximum Takeoff Weight exceeded!";
  }    
  
  if (msg != ""){
    # If we have a message, display it, but don't bother checking for
    # any other errors for 5 seconds. Otherwise we're likely to get
    # repeated messages.
    screen.log.write(msg);
    settimer(checkMTOW, 5);
  }else{
    settimer(checkMTOW, 1);
  }
}


checkG();
checkMTOW();
checkVNE();
