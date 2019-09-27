# ####################################################################################
# ####################################################################################
# Nasal script to handle drag robot, in case there is no other dragger
#
# ####################################################################################
# Author:  Klaus Kerner
# Version: 2012-03-08
#
# ####################################################################################
# Concepts:
# 1. search for allready existing dragger in the property tree                  done
# 2. if an dragger does not exist, create a new one                             done
# 3. place dragger in front of glider                                           done
# 4. run the dragger up into the sky                                       mostly done
# 5. after releasing tow reset the dragger                                 mostly done
# 6. allow redefining presets                                                   done

# ####################################################################################

# possible models for the Dragger
var models = { DR400 : 'AI/Aircraft/DR400/Models/dr400-ai.xml', PA28 : 'AI/Aircraft/pa-28/pa-28-d-emlh.xml', Ercoupe : 'AI/Aircraft/ercoupe/Models/ercoupe-ai.xml', Staggerwing : 'AI/Aircraft/Beechcraft-Staggerwing/Models/model17-ai.xml'};

var sent = 0;
var last_leg = 0;
    
    
# drag-robot dialog: helper function to run the roboter, avoiding race conditions
var guiRunDragRobot = func {
    towing.findBestAIObject();
    #hookDragger();  
    setprop("controls/gear/assist-1",1);                    # level the plane
    ask21.msg("atc","Glider levelled."); 
    startDragRobot();
}

var print_straight= func (leg_distance_m) {	
    ask21.msg("ai-plane", "straight ahead for " ~ math.round(leg_distance_m) ~ "m");
}
var print_turn = func (direction, degrees) {
    ask21.msg("ai-plane", "turn " ~ direction ~ " " ~ math.round(degrees) ~ " deg");
}

# ####################################################################################
# drag-robot dialog: helper function to cancel the roboter, avoiding race conditions
var guiCancelDragRobot = func {
    removeDragRobot();
    resetRobotAttributes();
    #removeTowingRope();
}


# ####################################################################################
# findDragger
# used by key 
# used by gui, when dealing with drag roboter
# the first found plane, that is close enough and has callsign "dragger" will be used
var findDragger = func {
  
  # local variables
  var aiobjects = [];                     # keeps the ai-planes from the property tree
  var dragid = 0;                         # id of dragger
  var callsign = 0;                       # callsign of dragger
  var cur = geo.Coord.new();              # current processed ai-plane
  var lat_deg = 0;                        # latitude of current processed aiobject
  var lon_deg = 0;                        # longitude of current processed aiobject
  var alt_m = 0;                          # altitude of current processed aiobject
  var glider = geo.Coord.new();           # coordinates of glider
  var distance_m = 0;                     # distance to ai-plane
  
  
  var towlength_m = getprop("sim/glider/towing/conf/rope_length_m");
  
  
  aiobjects = props.globals.getNode("ai/models").getChildren(); 
  glider = geo.aircraft_position(); 
  
  foreach (var aimember; aiobjects) { 
    if ( (var c = aimember.getNode("callsign") ) != nil ) { 
      callsign = c.getValue();
      dragid = aimember.getNode("id").getValue();
      if ( callsign == "dragger" ) {
        lat_deg = aimember.getNode("position/latitude-deg").getValue(); 
        lon_deg = aimember.getNode("position/longitude-deg").getValue(); 
        alt_m = aimember.getNode("position/altitude-ft").getValue() * FT2M; 
        
        cur = geo.Coord.set_latlon( lat_deg, lon_deg, alt_m ); 
        distance_m = (glider.distance_to(cur)); 
        
        if ( distance_m < towlength_m ) { 
          ask21.msg("atc","dragger with id %s nearby in %s m", dragid, distance_m);
          setprop("sim/glider/towing/dragid", dragid); 
          break; 
        }
        else {
          ask21.msg("atc","dragger with id %s too far at %s m", dragid, distance_m);
        }
      }
    }
    else {
      ask21.msg("atc","no dragger found");
    }
  }
  
} # End Function findDragger


# ####################################################################################
# hookDragger
# used by key
# used by gui
var hookDragger = func {
  
  # if dragid > 0
  #  set property /fdm/jsbsim/fcs/dragger-cmd-norm
  #  level plane
  
  if ( getprop("sim/glider/towing/dragid") != nil ) { 
    createTowingRope();                                           # create rope model
    setprop("fdm/jsbsim/fcs/dragger-cmd-norm", 1);                # closes the hook
    setprop("sim/glider/towing/hooked", 1); 
    ask21.msg("atc","hook closed"); 
    setprop("orientation/roll-deg", 0); 
    ask21.msg("atc","glider leveled"); 
  }
  else { 
    ask21.msg("atc","no dragger nearby"); 
  }
  
} # End Function hookDragger

# ####################################################################################
# ## new properties in the property tree
# ai/models/dragger
# ai/models/dragger/id
# ai/models/dragger/callsign
# ai/models/dragger/valid
# ai/models/dragger/position/latitude-deg
# ai/models/dragger/position/longitude-deg
# ai/models/dragger/position/altitude-ft
# ai/models/dragger/orientation/true-heading-deg
# ai/models/dragger/orientation/pitch-deg
# ai/models/dragger/orientation/roll-deg
# ai/models/dragger/velocities/true-airspeed-kt
# ai/models/dragger/velocities/vertical-speed-fps
# models/model[id_model]/path
# models/model[id_model]/longitude-deg-prop
# models/model[id_model]/latitude-deg-prop
# models/model[id_model]/elevation-ft-prop
# models/model[id_model]/heading-deg-prop
# sim/glider/dragger/flags/exist                flag for existence of robot
# sim/glider/dragger/flags/run                  flag for triggering operation
# sim/glider/dragger/robot/id_AI
# sim/glider/dragger/robot/id_model
# sim/glider/dragger/robot/wp0lat_deg           wp0 reference point for different legs
# sim/glider/dragger/robot/wp0lon_deg
# sim/glider/dragger/robot/wp0alt_m
# sim/glider/dragger/robot/wp0head_deg
# sim/glider/dragger/robot/exit_height_m        exit height for stopping robot
# sim/glider/dragger/robot/anchorlat_deg        anchor for checking leg position
# sim/glider/dragger/robot/anchorlon_deg
# sim/glider/dragger/robot/anchoralt_m
# sim/glider/dragger/robot/leg_type             storing type of leg, 0 start, 
#                                                                    1 turn, 
#                                                                    2 straight
#                                                                    3 end 
# sim/glider/dragger/robot/leg_distance_m       target distance in straight leg
# sim/glider/dragger/robot/leg_angle_deg        target turn angle in turn leg
# sim/glider/dragger/robot/turnside             1: right turn, 0: left turn
# sim/glider/dragger/robot/leg_segment          storing segment of leg0, 
#                                                                    0 tauten, 
#                                                                    1 acceleration
#                                               storing segment of leg1
#                                                                    2 roll in 
#                                                                    3 keep roll angle
#                                                                    4 roll out
# sim/glider/dragger/conf/glob_min_speed_takeoff_mps
#                .../glob/glob_min_speed_takeoff_mps
# sim/glider/dragger/conf/glob_max_speed_mps
#                .../glob/glob_max_speed_mps
# sim/glider/dragger/conf/glob_max_speed_lift_mps
#                .../glob/glob_max_speed_lift_mps
# sim/glider/dragger/conf/glob_max_speed_tauten_mps
#                .../glob/glob_max_speed_tauten_mps
# sim/glider/dragger/conf/glob_min_acceleration_mpss
#                .../glob/glob_min_acceleration_mpss
# sim/glider/dragger/conf/glob_max_acceleration_mpss
#                .../glob/glob_max_acceleration_mpss
# sim/glider/dragger/conf/glob_max_roll_deg
#                .../glob/glob_max_roll_deg
# sim/glider/dragger/conf/glob_max_rollrate_degs
#                .../glob/glob_max_rollrate_degs
# sim/glider/dragger/conf/glob_max_turnrate_degs
#                .../glob/glob_max_turnrate_degs
# sim/glider/dragger/conf/glob_max_lift_height_m
#                .../glob/glob_max_lift_height_m
# sim/glider/dragger/conf/glob_max_tautendist_m
#                .../glob/glob_max_tautendist_m

# ## used properties from the property tree
# environment/wind-from-north-fps
# environment/wind-from-east-fps
# environment/wind-from-down-fps
# orientation/heading-deg
# sim/glider/dragger/hooked



# ####################################################################################
# global variables:
var dragrobot_timeincrement_s = 0;                     # timer increment



# ####################################################################################
# set drag roboter parameters to global values, if not properly defined by plane 
# setup-file
# store global values or plane-specific values to prepare for reset option
var initRobotAttributes = func {
  # SI units for the advanced dialog
    setprop("sim/glider/gui/dragrobot/min_speed_takeoff", 72);
    setprop("sim/glider/gui/dragrobot/max_speed", 129.6);
    setprop("sim/glider/gui/dragrobot/max_speed_tauten", 10.8);
  # constants for describing dragger attributes, if not defined by plane setup-file
  var glob_min_speed_takeoff_mps  = 20;       # min. speed for take-off of drag-robot
  var glob_max_speed_mps          = 36;       # max. speed of drag-robot
  var glob_max_speed_lift_mps     = 3;        # max. lift speed of drag-robot
  var glob_max_speed_tauten_mps   = 3;        # max. speed to tauten the rope
  var glob_min_acceleration_mpss  = 0.5;      # min. acceleration
  var glob_max_acceleration_mpss  = 3;        # max. acceleration
  var glob_max_roll_deg           = 20;       # max. roll angle
  var glob_max_rollrate_degs      = 5;        # max. roll rate per second
  var glob_max_turnrate_degs      = 3;        # max. turn rate per second 
                                                # at max roll angle
  var glob_max_lift_height_m      = 800;      # max. lifht height over start point
  var glob_max_tautendist_m       = 50;       # max. distance for tauten the rope
  
  if ( getprop("sim/glider/dragger/conf/glob_min_speed_takeoff_mps") == nil ) {
    setprop("sim/glider/dragger/conf/glob_min_speed_takeoff_mps", 
             glob_min_speed_takeoff_mps);
    setprop("sim/glider/dragger/glob/glob_min_speed_takeoff_mps", 
             glob_min_speed_takeoff_mps);
  }
  else {
    setprop("sim/glider/dragger/glob/glob_min_speed_takeoff_mps",
             getprop("sim/glider/dragger/conf/glob_min_speed_takeoff_mps"));
  }
  
  if ( getprop("sim/glider/dragger/conf/glob_max_speed_mps") == nil ) {
    setprop("sim/glider/dragger/conf/glob_max_speed_mps", 
             glob_max_speed_mps);
    setprop("sim/glider/dragger/glob/glob_max_speed_mps", 
             glob_max_speed_mps);
  }
  else {
    setprop("sim/glider/dragger/glob/glob_max_speed_mps", 
             getprop("sim/glider/dragger/conf/glob_max_speed_mps"));
  }
  
  if ( getprop("sim/glider/dragger/conf/glob_max_speed_lift_mps") == nil ) {
    setprop("sim/glider/dragger/conf/glob_max_speed_lift_mps", 
             glob_max_speed_lift_mps);
    setprop("sim/glider/dragger/glob/glob_max_speed_lift_mps", 
             glob_max_speed_lift_mps);
  }
  else {
    setprop("sim/glider/dragger/glob/glob_max_speed_lift_mps", 
             getprop("sim/glider/dragger/conf/glob_max_speed_lift_mps"));
  }
  
  if ( getprop("sim/glider/dragger/conf/glob_max_speed_tauten_mps") == nil ) {
    setprop("sim/glider/dragger/conf/glob_max_speed_tauten_mps", 
             glob_max_speed_tauten_mps);
    setprop("sim/glider/dragger/glob/glob_max_speed_tauten_mps", 
             glob_max_speed_tauten_mps);
  }
  else {
    setprop("sim/glider/dragger/glob/glob_max_speed_tauten_mps", 
             getprop("sim/glider/dragger/conf/glob_max_speed_tauten_mps"));
  }
  
  if ( getprop("sim/glider/dragger/conf/glob_min_acceleration_mpss") == nil ) {
    setprop("sim/glider/dragger/conf/glob_min_acceleration_mpss", 
             glob_min_acceleration_mpss);
    setprop("sim/glider/dragger/glob/glob_min_acceleration_mpss", 
             glob_min_acceleration_mpss);
  }
  else {
    setprop("sim/glider/dragger/glob/glob_min_acceleration_mpss", 
             getprop("sim/glider/dragger/conf/glob_min_acceleration_mpss"));
  }
  
  if ( getprop("sim/glider/dragger/conf/glob_max_acceleration_mpss") == nil ) {
    setprop("sim/glider/dragger/conf/glob_max_acceleration_mpss", 
             glob_max_acceleration_mpss);
    setprop("sim/glider/dragger/glob/glob_max_acceleration_mpss", 
             glob_max_acceleration_mpss);
  }
  else {
    setprop("sim/glider/dragger/glob/glob_max_acceleration_mpss", 
             getprop("sim/glider/dragger/conf/glob_max_acceleration_mpss"));
  }
  
  if ( getprop("sim/glider/dragger/conf/glob_max_roll_deg") == nil ) {
    setprop("sim/glider/dragger/conf/glob_max_roll_deg", 
             glob_max_roll_deg);
    setprop("sim/glider/dragger/glob/glob_max_roll_deg", 
             glob_max_roll_deg);
  }
  else {
    setprop("sim/glider/dragger/glob/glob_max_roll_deg", 
             getprop("sim/glider/dragger/conf/glob_max_roll_deg"));
  }
  
  if ( getprop("sim/glider/dragger/conf/glob_max_rollrate_degs") == nil ) {
    setprop("sim/glider/dragger/conf/glob_max_rollrate_degs", 
             glob_max_rollrate_degs);
    setprop("sim/glider/dragger/glob/glob_max_rollrate_degs", 
             glob_max_rollrate_degs);
  }
  else {
    setprop("sim/glider/dragger/glob/glob_max_rollrate_degs", 
             getprop("sim/glider/dragger/conf/glob_max_rollrate_degs"));
  }
  
  if ( getprop("sim/glider/dragger/conf/glob_max_turnrate_degs") == nil ) {
    setprop("sim/glider/dragger/conf/glob_max_turnrate_degs", 
             glob_max_turnrate_degs);
    setprop("sim/glider/dragger/glob/glob_max_turnrate_degs", 
             glob_max_turnrate_degs);
  }
  else {
    setprop("sim/glider/dragger/glob/glob_max_turnrate_degs", 
             getprop("sim/glider/dragger/conf/glob_max_turnrate_degs"));
  }
  
  if ( getprop("sim/glider/dragger/conf/glob_max_lift_height_m") == nil ) {
    setprop("sim/glider/dragger/conf/glob_max_lift_height_m", 
             glob_max_lift_height_m);
    setprop("sim/glider/dragger/glob/glob_max_lift_height_m", 
             glob_max_lift_height_m);
  }
  else {
    setprop("sim/glider/dragger/glob/glob_max_lift_height_m", 
             getprop("sim/glider/dragger/conf/glob_max_lift_height_m"));
  }
  
  if ( getprop("sim/glider/dragger/conf/glob_max_tautendist_m") == nil ) {
    setprop("sim/glider/dragger/conf/glob_max_tautendist_m", 
             glob_max_tautendist_m);
    setprop("sim/glider/dragger/glob/glob_max_tautendist_m", 
             glob_max_tautendist_m);
  }
  else {
    setprop("sim/glider/dragger/glob/glob_max_tautendist_m", 
             getprop("sim/glider/dragger/conf/glob_max_tautendist_m"));
  }
}



# ####################################################################################
# re-initialize presets
var resetRobotAttributes = func {
  # reading all global variables in case they has been changed in the property tree
  setprop("sim/glider/dragger/conf/glob_min_speed_takeoff_mps", 
    getprop("sim/glider/dragger/glob/glob_min_speed_takeoff_mps"));
  setprop("sim/glider/dragger/conf/glob_max_speed_mps",  
    getprop("sim/glider/dragger/glob/glob_max_speed_mps"));
  setprop("sim/glider/dragger/conf/glob_max_speed_lift_mps", 
    getprop("sim/glider/dragger/glob/glob_max_speed_lift_mps"));
  setprop("sim/glider/dragger/conf/glob_max_speed_tauten_mps", 
    getprop("sim/glider/dragger/glob/glob_max_speed_tauten_mps"));
  setprop("sim/glider/dragger/conf/glob_min_acceleration_mpss", 
    getprop("sim/glider/dragger/glob/glob_min_acceleration_mpss"));
  setprop("sim/glider/dragger/conf/glob_max_acceleration_mpss", 
    getprop("sim/glider/dragger/glob/glob_max_acceleration_mpss"));
  setprop("sim/glider/dragger/conf/glob_max_roll_deg", 
    getprop("sim/glider/dragger/glob/glob_max_roll_deg"));
  setprop("sim/glider/dragger/conf/glob_max_rollrate_degs", 
    getprop("sim/glider/dragger/glob/glob_max_rollrate_degs"));
  setprop("sim/glider/dragger/conf/glob_max_turnrate_degs", 
    getprop("sim/glider/dragger/glob/glob_max_turnrate_degs"));
  setprop("sim/glider/dragger/conf/glob_max_lift_height_m", 
    getprop("sim/glider/dragger/glob/glob_max_lift_height_m"));
  setprop("sim/glider/dragger/conf/glob_max_tautendist_m", 
    getprop("sim/glider/dragger/glob/glob_max_tautendist_m"));
}



# ####################################################################################
# check for allready available dragger
var checkDragger = func {
  
  #local variables
  var dragid = -1;                              # the allready used id
  var aiobjects = {};                           # vector to keep all ai objects
  
  aiobjects = props.globals.getNode("ai/models", 1).getChildren();  # store AI objects
  foreach ( var aimember; aiobjects ) { 
    # get data from aimember
    if ( (var c = aimember.getNode("callsign")) != nil) {
      var callsign = c.getValue();
      if ( callsign == "dragger" ) {
        dragid = aimember.getNode("id").getValue();
      } 
    }
  }
  return(dragid);
}



# ####################################################################################
# get the next free id of ai/models members
var getFreeAIID = func {
  
  #local variables
  var aiid = 0;                                 # for the next unsused id
  var aiobjects = {};                           # vector to keep all ai objects
  
  aiobjects = props.globals.getNode("ai/models", 1).getChildren();  # store AI objects
  foreach ( var aimember; aiobjects ) { 
    # get data from aimember
    if ( (var c = aimember.getNode("id")) != nil) {
      var id = c.getValue();
      if ( aiid <= id ) {
        aiid = id +1;
      } 
    }
  }
  
# dirty bug-fix for double-used IDs, assign a most probably never reached ID (9999)
# hopefully this will change in the future with correct ID assignment as the 
# AI-system does, needs access to flightgear core functions
#  return(aiid);
  return(9999);
}



# ####################################################################################
# get the next free id of models/model members
var getFreeModelID = func {
  
  #local variables
  var modelid = 0;                                 # for the next unsused id
  var modelobjects = {};                           # vector to keep all model objects
  
  modelobjects = props.globals.getNode("models", 1).getChildren(); # get model objects
  foreach ( var member; modelobjects ) { 
    # get data from member
    if ( (var c = member.getNode("id")) != nil) {
      var id = c.getValue();
      if ( modelid <= id ) {
        modelid = id +1;
      } 
    }
  }
  return(modelid);
}



# ####################################################################################
# create the drag robot in the ai property tree
var createDragRobot = func {
  # place drag roboter with a distance, that the tow is nearly tautened
  var rope_length_m = getprop("/sim/hitches/aerotow/tow/length");
  var tauten_relative = getprop("/sim/glider/towing/conf/rope_x1") or 0.7;
  var install_distance_m = rope_length_m * (tauten_relative - 0.02);
  
  # local variables
  var ac_pos = geo.aircraft_position();                   # get position of aircraft
  var ac_hd  = getprop("orientation/heading-deg");        # get heading of aircraft
  var dip    = ac_pos.apply_course_distance( ac_hd , install_distance_m );   
                                                          # initial dragger position, 
                                                            # close to tauten-distance
  var dipalt_m = geo.elevation(dip.lat(), dip.lon());     # height at dragger position
  var glob_max_lift_height_m     = 
    getprop("sim/glider/dragger/conf/glob_max_lift_height_m");
  
  # get the next free ai id and model id
  var freeAIid = getFreeAIID();
  var freeModelid = getFreeModelID();
  
  
  var dragger_ai  = props.globals.getNode("ai/models/dragger", 1);
  var dragger_mod = props.globals.getNode("models", 1);
  var dragger_sim = props.globals.getNode("sim/glider/dragger/robot", 1);
  var dragger_flg = props.globals.getNode("sim/glider/dragger/flags", 1);
  
  dragger_sim.getNode("id_AI", 1).setIntValue(freeAIid);
  dragger_sim.getNode("id_model", 1).setIntValue(freeModelid);
  dragger_sim.getNode("leg_type", 1).setIntValue(0);
  dragger_sim.getNode("leg_distance_m", 1).setValue(2000);
  dragger_sim.getNode("leg_angle_deg", 1).setValue(ac_hd);
  dragger_sim.getNode("leg_segment", 1).setIntValue(0);
  
  dragger_flg.getNode("exist", 1).setIntValue(1);
  
  
  dragger_ai.getNode("id", 1).setIntValue(freeAIid);
  dragger_ai.getNode("callsign", 1).setValue("dragger");
  dragger_ai.getNode("valid", 1).setBoolValue(1);
  dragger_ai.getNode("position/latitude-deg", 1).setValue(dip.lat());
  dragger_ai.getNode("position/longitude-deg", 1).setValue(dip.lon());
  dragger_ai.getNode("position/altitude-ft", 1).setValue(dipalt_m * M2FT);
  dragger_ai.getNode("orientation/true-heading-deg", 1).setValue(ac_hd);
  dragger_ai.getNode("orientation/pitch-deg", 1).setValue(0);
  dragger_ai.getNode("orientation/roll-deg", 1).setValue(0);
  dragger_ai.getNode("velocities/true-airspeed-kt", 1).setValue(0);
  dragger_ai.getNode("velocities/vertical-speed-fps", 1).setValue(0);
  
  dragger_mod.model = dragger_mod.getChild("model", freeModelid, 1);
  dragger_mod.model.getNode("path", 1).setValue(models[getprop("sim/glider/dragger/model")]);
  dragger_mod.model.getNode("longitude-deg-prop", 1).setValue(
        "ai/models/dragger/position/longitude-deg");
  dragger_mod.model.getNode("latitude-deg-prop", 1).setValue(
        "ai/models/dragger/position/latitude-deg");
  dragger_mod.model.getNode("elevation-ft-prop", 1).setValue(
        "ai/models/dragger/position/altitude-ft");
  dragger_mod.model.getNode("heading-deg-prop", 1).setValue(
        "ai/models/dragger/orientation/true-heading-deg");
  dragger_mod.model.getNode("roll-deg-prop", 1).setValue(
        "ai/models/dragger/orientation/roll-deg");
  dragger_mod.model.getNode("load", 1).remove();
  
  
  #storing initial position for reseting after reaching escape height
  setprop("sim/glider/dragger/robot/wp0lat_deg", dip.lat() );
  setprop("sim/glider/dragger/robot/wp0lon_deg", dip.lon() );
  setprop("sim/glider/dragger/robot/wp0alt_m", dipalt_m );
  setprop("sim/glider/dragger/robot/wp0head_deg", ac_hd );
  setprop("sim/glider/dragger/robot/exit_height_m", dip.alt() + glob_max_lift_height_m ); 
}



# ####################################################################################
# main function to initialize the drag roboter
# used by key "D" or gui
var setupDragRobot = func {
  
  # look for allready existing ai object with callsign "dragger"
  var existingdragid = checkDragger();
  if ( existingdragid > -1 ) {               # dragger allready exists, we can exit
    ask21.msg("atc"," existing dragger id: ", existingdragid);
  }
  else {                                     # dragger does not exist, we have to work
    # create a new ai object with callsign "dragger"
    # set initial position 
    createDragRobot();
    ask21.msg("ai-plane"," I will lift you up into the sky.");
  }
}



# ####################################################################################
# dummy function to delete the drag roboter
# used by gui and dragrobot.nas functions
var removeDragRobot = func {
  
  # look for allready existing ai object with callsign "dragger"
  # will be filled in the next future
  
  # in any case, first stop the dragger
  setprop("sim/glider/dragger/flags/run", 0);
  
  # next check for the dragger is still existent
  # if yes, 
  #   remove the dragger from the property tree ai/models
  #   remove the dragger from the property tree models/
  #   remove the dragger working properties
  # if no, 
  #   do nothing
  
  # local variables
  var modelsNode = {};
  
  if ( getprop("/sim/glider/dragger/flags/exist") == 1 ) {   # does the dragger exist?
    # remove 3d model from scenery
    # identification is /models/model[x] with x=id_model
    var id_model = getprop("sim/glider/dragger/robot/id_model");
    modelsNode = "models/model[" ~ id_model ~ "]";
    props.globals.getNode(modelsNode).remove();
    props.globals.getNode("ai/models/dragger").remove();
    props.globals.getNode("sim/glider/dragger/robot").remove();
    ask21.msg("atc","dragger removed");
    setprop("/sim/glider/dragger/flags/exist", 0);
  }
  else {                                                     # do nothing
    ask21.msg("atc","dragger does not exist");
  }
  
}



# ####################################################################################
# run the drag robot for start leg
var leg0DragRobot = func {
  
  # ##################################################################################
  # Strategy:
  # set flag for start
  # tauten the rope
  # accelerate up to minimum lift speed
  # switch to next leg
  
  
  
  
  var initpos_geo = geo.Coord.new();
  var dragpos_geo = geo.Coord.new();
  var temppos_geo = geo.Coord.new();
  
  var oldspeed_mps     = 0;
  var oldlift_mps      = 0;
  var oldheading_deg   = 0;
  var newspeed_mps     = 0;
  var newlift_mps      = 0;
  var newliftdist_m    = 0;
  var newelevation_m   = 0;
  var distance_m       = 0;
  var leg_distance_m   = 0;
  var deltatime_s      = 0;
  var leg_angle_deg    = 0;
  var headwind_mps     = 0;
  
  
  var segment = getprop("sim/glider/dragger/robot/leg_segment");
  var glob_min_speed_takeoff_mps = 
    getprop("sim/glider/dragger/conf/glob_min_speed_takeoff_mps");
  var glob_max_speed_tauten_mps  = 
    getprop("sim/glider/dragger/conf/glob_max_speed_tauten_mps");
  var glob_min_acceleration_mpss = 
    getprop("sim/glider/dragger/conf/glob_min_acceleration_mpss");
  var glob_max_acceleration_mpss = 
    getprop("sim/glider/dragger/conf/glob_max_acceleration_mpss");
  var glob_max_tautendist_m     = 
    getprop("sim/glider/dragger/conf/glob_max_tautendist_m");
  
  
  if ( dragrobot_timeincrement_s == 0 ) {
    deltatime_s = getprop("sim/time/delta-sec");
  }
  else {
    deltatime_s = dragrobot_timeincrement_s;
  }
  
  
  oldspeed_mps     = getprop("ai/models/dragger/velocities/true-airspeed-kt") * KT2MPS;
  oldheading_deg   = getprop("ai/models/dragger/orientation/true-heading-deg");
  
  initpos_geo.set_latlon( getprop("sim/glider/dragger/robot/wp0lat_deg"), 
                          getprop("sim/glider/dragger/robot/wp0lon_deg"), 
                          getprop("sim/glider/dragger/robot/wp0alt_m") );
  dragpos_geo.set_latlon( getprop("ai/models/dragger/position/latitude-deg"), 
                          getprop("ai/models/dragger/position/longitude-deg"), 
                          getprop("ai/models/dragger/position/altitude-ft") * FT2M);
  
  headwind_mps = aircraft.wind_speed_from(oldheading_deg) * KT2MPS;
  
  
  # update properties like speed and position
  if ( segment == 1 ) {                         # accelerate to min take-off speed
    newspeed_mps = oldspeed_mps + glob_max_acceleration_mpss * deltatime_s;
    distance_m = (oldspeed_mps - headwind_mps) * deltatime_s 
                   + 0.5 * glob_max_acceleration_mpss * deltatime_s * deltatime_s ;
  }
  else {                                        # segment 0, tauten rope
    if ( ( oldspeed_mps - headwind_mps ) < glob_max_speed_tauten_mps ) {
      if ( oldspeed_mps < headwind_mps ) {
        oldspeed_mps = headwind_mps;
      }
      newspeed_mps = glob_min_acceleration_mpss * deltatime_s + oldspeed_mps; 
      distance_m = (oldspeed_mps - headwind_mps) * deltatime_s 
                   + 0.5 * glob_min_acceleration_mpss * deltatime_s * deltatime_s ;
      if ( distance_m < 0.01 ) {  # keep robot locked until speed is high enough
        distance_m = 0;
      }
    }
    else {
      newspeed_mps = oldspeed_mps;
      distance_m = (oldspeed_mps - headwind_mps) * deltatime_s ;
    }
    if ( dragpos_geo.direct_distance_to(initpos_geo) > glob_max_tautendist_m ) { 
      setprop("sim/glider/dragger/robot/leg_segment", 1);
    }
  }
  
  temppos_geo.set_latlon(dragpos_geo.lat(), dragpos_geo.lon());
  newelevation_m = geo.elevation( temppos_geo.lat(), temppos_geo.lon() );
  
  dragpos_geo.apply_course_distance( oldheading_deg , distance_m );
  dragpos_geo.set_alt(newelevation_m);
  
  setprop("ai/models/dragger/position/latitude-deg", dragpos_geo.lat());
  setprop("ai/models/dragger/position/longitude-deg", dragpos_geo.lon());
  setprop("ai/models/dragger/position/altitude-ft", dragpos_geo.alt() * M2FT);
  setprop("ai/models/dragger/velocities/true-airspeed-kt", newspeed_mps * MPS2KT);
  
  
  # check for exit criteria
  if ( oldspeed_mps > glob_min_speed_takeoff_mps ) { 
    # set anchor point
    setprop("sim/glider/dragger/robot/anchorlat_deg", dragpos_geo.lat());
    setprop("sim/glider/dragger/robot/anchorlon_deg", dragpos_geo.lon());
    setprop("sim/glider/dragger/robot/anchoralt_m", dragpos_geo.alt());
    # set flags for next leg
    setprop("sim/glider/dragger/robot/leg_type", 2);    # next one is straight forward
    # set next exit criteria for straight leg, 200m ... 400m 
    leg_distance_m = 200 + rand() * 200;
    setprop("sim/glider/dragger/robot/leg_distance_m", leg_distance_m ); 
    print_straight(leg_distance_m);
  }
}



# ####################################################################################
# run the drag robot for turns
var leg1DragRobot = func {
  # turns are described by the turn angle, so the delta angle from heading at initial 
  # position to heading from current position is the criteria for exit
  
  
  var initpos_geo = geo.Coord.new();
  var dragpos_geo = geo.Coord.new();
  
  var oldspeed_mps     = 0;
  var oldlift_mps      = 0;
  var oldheading_deg   = 0;
  var oldroll_deg      = 0;
  var deltatime_s      = 0;
  var distance_m       = 0;
  var newspeed_mps     = 0;
  var newlift_mps      = 0;
  var newelevation_m   = 0;
  var newroll_deg      = 0;
  var newturn_deg      = 0;
  var newheading_deg   = 0;
  var wind_from_east_mps = 0;
  var wind_from_nord_mps = 0;
  var wind_from_down_mps = 0;
  
  
  var segment = getprop("sim/glider/dragger/robot/leg_segment");
  var side    = getprop("sim/glider/dragger/robot/turnside");
  var targetheading_deg = getprop("sim/glider/dragger/robot/leg_angle_deg");
  var glob_min_speed_takeoff_mps = 
    getprop("sim/glider/dragger/conf/glob_min_speed_takeoff_mps");
  var glob_max_speed_mps         = 
    getprop("sim/glider/dragger/conf/glob_max_speed_mps");
  var glob_max_speed_lift_mps    = 
    getprop("sim/glider/dragger/conf/glob_max_speed_lift_mps");
  var glob_max_acceleration_mpss = 
    getprop("sim/glider/dragger/conf/glob_max_acceleration_mpss");
  var glob_max_roll_deg          = 
    getprop("sim/glider/dragger/conf/glob_max_roll_deg");
  var glob_max_rollrate_degs     = 
    getprop("sim/glider/dragger/conf/glob_max_rollrate_degs");
  var glob_max_turnrate_degs     = 
    getprop("sim/glider/dragger/conf/glob_max_turnrate_degs");
  
  
  if ( dragrobot_timeincrement_s == 0 ) {
    deltatime_s = getprop("sim/time/delta-sec");
  }
  else {
    deltatime_s = dragrobot_timeincrement_s;
  }
  
  oldspeed_mps     = getprop("ai/models/dragger/velocities/true-airspeed-kt") * KT2MPS;
  oldlift_mps      = getprop("ai/models/dragger/velocities/vertical-speed-fps") * FT2M;
  oldheading_deg   = getprop("ai/models/dragger/orientation/true-heading-deg");
  oldroll_deg      = getprop("ai/models/dragger/orientation/roll-deg");
  wind_from_east_mps = getprop("environment/wind-from-east-fps") * FT2M;
  wind_from_nord_mps = getprop("environment/wind-from-north-fps") * FT2M;
  wind_from_down_mps = getprop("environment/wind-from-down-fps") * FT2M;
  
  dragpos_geo.set_latlon( getprop("ai/models/dragger/position/latitude-deg"), 
                          getprop("ai/models/dragger/position/longitude-deg"), 
                          getprop("ai/models/dragger/position/altitude-ft") * FT2M);
  
  # calculate current roll angle for turns
  if ( side == 1 ) {          # right turns
    if ( segment == 2 ) {
      if ( oldroll_deg < glob_max_roll_deg) {
        # calculate new roll angle
        newroll_deg = oldroll_deg + deltatime_s * glob_max_rollrate_degs;
      }
      else {
        newroll_deg = oldroll_deg;
        setprop("sim/glider/dragger/robot/leg_segment", 3);
      }
    }
    
    if (segment == 3 ) {
      newroll_deg = oldroll_deg;
      # check for target turn 
      if ( (oldheading_deg > targetheading_deg) 
             and 
               (oldheading_deg <= (targetheading_deg+5)) ) { 
        # turn finished
        setprop("sim/glider/dragger/robot/leg_segment", 4);
      }
      # if yes, change segment type
    }
    
    if ( segment == 4 ) {
      if ( oldroll_deg > 0) {
        # calculate new roll angle
        newroll_deg = oldroll_deg - deltatime_s * glob_max_rollrate_degs;
      }
      else {                                                      # also exit criteria
        newroll_deg = 0;
        # set anchor point
        setprop("sim/glider/dragger/robot/anchorlat_deg", dragpos_geo.lat());
        setprop("sim/glider/dragger/robot/anchorlon_deg", dragpos_geo.lon());
        setprop("sim/glider/dragger/robot/anchoralt_m", dragpos_geo.alt());
	# set next leg
	setprop("sim/glider/dragger/robot/leg_segment", 2);
	setprop("sim/glider/dragger/robot/leg_type", 2);
	var length_m = 100;                                    # first turn after 100m
	setprop("sim/glider/dragger/robot/leg_distance_m", length_m); 
	print_straight(length_m);
      }
    }
  }
  else {                 # left turns
    if ( segment == 2 ) {
      if ( oldroll_deg > -glob_max_roll_deg) {
        # calculate new roll angle
        newroll_deg = oldroll_deg - deltatime_s * glob_max_rollrate_degs;
      }
      else {
        newroll_deg = oldroll_deg;
        setprop("sim/glider/dragger/robot/leg_segment", 3);
      }
    }
    
    if (segment == 3 ) {
      newroll_deg = oldroll_deg;
      # check for target turn 
      if ( (oldheading_deg < targetheading_deg) 
             and 
               (oldheading_deg >= (targetheading_deg-5)) ) { 
        # turn finished
        setprop("sim/glider/dragger/robot/leg_segment", 4);
      }
      # if yes, change segment type
    }
    
    if ( segment == 4 ) {
      if ( oldroll_deg < 0) {
        # calculate new roll angle
        newroll_deg = oldroll_deg + deltatime_s * glob_max_rollrate_degs;
      }
      else {                                                      # also exit criteria
        newroll_deg = 0;
        # set anchor point
        setprop("sim/glider/dragger/robot/anchorlat_deg", dragpos_geo.lat());
        setprop("sim/glider/dragger/robot/anchorlon_deg", dragpos_geo.lon());
        setprop("sim/glider/dragger/robot/anchoralt_m", dragpos_geo.alt());
        if(!last_leg){
		# set next leg
		setprop("sim/glider/dragger/robot/leg_segment", 2);
		setprop("sim/glider/dragger/robot/leg_type", 2);
		var length_m = 100;                                    # first turn after 100m
		setprop("sim/glider/dragger/robot/leg_distance_m", length_m); 
		print_straight(length_m);
	}else{
		setprop("sim/glider/dragger/robot/leg_segment", 2);
		setprop("sim/glider/dragger/robot/leg_type", 2);
		setprop("sim/glider/dragger/robot/leg_distance_m", 1500); 
		setprop("sim/glider/dragger/conf/glob_max_speed_lift_mps", 0);
	}
      }
    }
  }
  # calculate current speed
  if ( oldspeed_mps >= glob_max_speed_mps) {
    newspeed_mps = oldspeed_mps;
    distance_m = oldspeed_mps * deltatime_s;
  }
  else { 
    newspeed_mps = oldspeed_mps + glob_max_acceleration_mpss * deltatime_s;
    distance_m = oldspeed_mps * deltatime_s 
                 + 0.5 * glob_max_acceleration_mpss * deltatime_s * deltatime_s;
  }
  
  # calculate current lift
  newlift_mps = glob_max_speed_lift_mps * (oldspeed_mps - glob_min_speed_takeoff_mps) / 
                   (glob_max_speed_mps - glob_min_speed_takeoff_mps);
  newliftdist_m = (newlift_mps + wind_from_down_mps) * deltatime_s;
  
  
  # calculate current turn rate based on roll angle
  newturn_deg = glob_max_turnrate_degs * newroll_deg / glob_max_roll_deg * deltatime_s;
  
  # calculate new heading based on turn rate
  if ( (oldheading_deg + newturn_deg) > 360 ) { # if a rightturn exceeds 360 heading
    newheading_deg = oldheading_deg + newturn_deg - 360;
  }
  else {
    if ( (oldheading_deg + newturn_deg) < 0 ) { # if a leftturn exceeds 0 heading
      newheading_deg = oldheading_deg + newturn_deg +360;
    }
    else { # for all other headings
      newheading_deg = oldheading_deg + newturn_deg;
    }
  }
  
  # calculate new position based on new heading and distance increment
  dragpos_geo.apply_course_distance( newheading_deg , distance_m );
  dragpos_geo.apply_course_distance( 270.0 , wind_from_east_mps * deltatime_s );
  dragpos_geo.apply_course_distance( 180.0 , wind_from_nord_mps * deltatime_s );
  newelevation_m = dragpos_geo.alt() + newliftdist_m;
  dragpos_geo.set_alt(newelevation_m);
  
  
  setprop("ai/models/dragger/position/latitude-deg",         dragpos_geo.lat());
  setprop("ai/models/dragger/position/longitude-deg",        dragpos_geo.lon());
  setprop("ai/models/dragger/position/altitude-ft",          dragpos_geo.alt() * M2FT);
  setprop("ai/models/dragger/orientation/true-heading-deg",  newheading_deg);
  setprop("ai/models/dragger/orientation/roll-deg",          newroll_deg);
  setprop("ai/models/dragger/velocities/true-airspeed-kt",   newspeed_mps * MPS2KT);
  setprop("ai/models/dragger/velocities/vertical-speed-fps", newlift_mps * M2FT);
}



# ####################################################################################
# run the drag robot for straight legs
var leg2DragRobot = func {
  # straight legs are described by the length, so the delta distance from initial 
  # position to current position is the criteria for exit
  
  
  
  var initpos_geo = geo.Coord.new();
  var dragpos_geo = geo.Coord.new();
  
  var oldspeed_mps     = 0;
  var oldheading_deg   = 0;
  var newspeed_mps     = 0;
  var newlift_mps      = 0;
  var newliftdist_m    = 0;
  var newelevation_m   = 0;
  var distance_m       = 0;
  var leg_distance_m   = 0;
  var deltatime_s      = 0;
  var leg_angle_deg    = 0;
  var wind_from_east_mps = 0;
  var wind_from_nord_mps = 0;
  var wind_from_down_mps = 0;
  
  var glob_min_speed_takeoff_mps = 
    getprop("sim/glider/dragger/conf/glob_min_speed_takeoff_mps");
  var glob_max_speed_mps         = 
    getprop("sim/glider/dragger/conf/glob_max_speed_mps");
  var glob_max_speed_lift_mps    = 
    getprop("sim/glider/dragger/conf/glob_max_speed_lift_mps");
  var glob_max_acceleration_mpss = 
    getprop("sim/glider/dragger/conf/glob_max_acceleration_mpss");
  
  
  if ( dragrobot_timeincrement_s == 0 ) {
    deltatime_s = getprop("sim/time/delta-sec");
  }
  else {
    deltatime_s = dragrobot_timeincrement_s;
  }
  
  oldspeed_mps     = getprop("ai/models/dragger/velocities/true-airspeed-kt") * KT2MPS;
  oldheading_deg   = getprop("ai/models/dragger/orientation/true-heading-deg");
  leg_distance_m   = getprop("sim/glider/dragger/robot/leg_distance_m");
  wind_from_east_mps = getprop("environment/wind-from-east-fps") * FT2M;
  wind_from_nord_mps = getprop("environment/wind-from-north-fps") * FT2M;
  wind_from_down_mps = getprop("environment/wind-from-down-fps") * FT2M;
  
  initpos_geo.set_latlon( getprop("sim/glider/dragger/robot/anchorlat_deg"), 
                          getprop("sim/glider/dragger/robot/anchorlon_deg"), 
                          getprop("sim/glider/dragger/robot/anchoralt_m") );
  dragpos_geo.set_latlon( getprop("ai/models/dragger/position/latitude-deg"), 
                          getprop("ai/models/dragger/position/longitude-deg"), 
                          getprop("ai/models/dragger/position/altitude-ft") * FT2M);
  
  if ( oldspeed_mps >= glob_max_speed_mps) {
    newspeed_mps = oldspeed_mps;
    distance_m = oldspeed_mps * deltatime_s;
  }
  else { 
    newspeed_mps = oldspeed_mps + glob_max_acceleration_mpss * deltatime_s;
    distance_m = oldspeed_mps * deltatime_s 
                 + 0.5 * glob_max_acceleration_mpss * deltatime_s * deltatime_s;
  }
  
  newlift_mps = glob_max_speed_lift_mps * (oldspeed_mps - glob_min_speed_takeoff_mps) / 
                   (glob_max_speed_mps - glob_min_speed_takeoff_mps);
  newliftdist_m = (newlift_mps + wind_from_down_mps) * deltatime_s;
  
  dragpos_geo.apply_course_distance( oldheading_deg , distance_m );
  dragpos_geo.apply_course_distance( 270.0 , wind_from_east_mps * deltatime_s );
  dragpos_geo.apply_course_distance( 180.0 , wind_from_nord_mps * deltatime_s );
  newelevation_m = dragpos_geo.alt() + newliftdist_m;
  dragpos_geo.set_alt(newelevation_m);
  
  setprop("ai/models/dragger/position/latitude-deg", dragpos_geo.lat());
  setprop("ai/models/dragger/position/longitude-deg", dragpos_geo.lon());
  setprop("ai/models/dragger/position/altitude-ft", dragpos_geo.alt() * M2FT);
  setprop("ai/models/dragger/velocities/true-airspeed-kt", newspeed_mps * MPS2KT);
  setprop("ai/models/dragger/velocities/vertical-speed-fps", newlift_mps * M2FT);
  
  
	
  
	# exit criteria to final drop-down: max height reached
	if(!last_leg){
		if ( dragpos_geo.alt() > getprop("sim/glider/dragger/robot/exit_height_m") and sent == 0) {
			ask21.msg("ai-plane"," we have reached max height, bye bye"); 
			sent = 1;
			settimer(func(){
					setprop("sim/glider/dragger/robot/leg_type", 3);
					setprop("sim/glider/dragger/robot/leg_segment", 2);
					ask21.msg("ai-plane","turn right, I turn left" );
					# unhook from dragger
					towing.releaseHitch("aerotow");
				}, 2);
		}else{
			# exit criteria to next turn
			if ( dragpos_geo.direct_distance_to(initpos_geo) > leg_distance_m ) { 
				var turn_deg = 30 + rand() * 240;                    # turn range from 30° to 270°
				if ( (oldheading_deg + turn_deg) >= 360) {
					leg_angle_deg = oldheading_deg + turn_deg - 360;
				}else {
					leg_angle_deg = oldheading_deg + turn_deg;
				}
				setprop("sim/glider/dragger/robot/leg_angle_deg", leg_angle_deg);
				var side = rand();
				if (side > 0.5) {
					setprop("sim/glider/dragger/robot/turnside", 1);
					print_turn("right", turn_deg);
				}else {
					setprop("sim/glider/dragger/robot/turnside", 0);
					print_turn("left", turn_deg);
				}
				setprop("sim/glider/dragger/robot/leg_type", 1);
				setprop("sim/glider/dragger/robot/leg_segment", 2);
			}
		}
	}else if ( dragpos_geo.direct_distance_to(initpos_geo) > leg_distance_m ){
		stopRobot();
	}
}



# ####################################################################################
# run the drag robot for final leg
var leg3DragRobot = func {
  
  
  
  var initpos_geo = geo.Coord.new();
  var dragpos_geo = geo.Coord.new();
  
  var oldspeed_mps     = 0;
  var oldheading_deg   = 0;
  var newspeed_mps     = 0;
  var newlift_mps      = 0;
  var newliftdist_m    = 0;
  var newelevation_m   = 0;
  var distance_m       = 0;
  var leg_distance_m   = 0;
  var deltatime_s      = 0;
  var leg_angle_deg    = 0;
  var wind_from_east_mps = 0;
  var wind_from_nord_mps = 0;
  var wind_from_down_mps = 0;
  
  var glob_min_speed_takeoff_mps = 
    getprop("sim/glider/dragger/conf/glob_min_speed_takeoff_mps");
  var glob_max_speed_mps         = 
    getprop("sim/glider/dragger/conf/glob_max_speed_mps");
  var glob_max_speed_lift_mps    = 
    getprop("sim/glider/dragger/conf/glob_max_speed_lift_mps");
  var glob_max_acceleration_mpss = 
    getprop("sim/glider/dragger/conf/glob_max_acceleration_mpss");
  
  
  if ( dragrobot_timeincrement_s == 0 ) {
    deltatime_s = getprop("sim/time/delta-sec");
  }
  else {
    deltatime_s = dragrobot_timeincrement_s;
  }
  
  speed_mps     = getprop("ai/models/dragger/velocities/true-airspeed-kt") * KT2MPS;
  oldheading_deg   = getprop("ai/models/dragger/orientation/true-heading-deg");
  leg_distance_m   = 50;
  wind_from_east_mps = getprop("environment/wind-from-east-fps") * FT2M;
  wind_from_nord_mps = getprop("environment/wind-from-north-fps") * FT2M;
  wind_from_down_mps = getprop("environment/wind-from-down-fps") * FT2M;
  
  initpos_geo.set_latlon( getprop("sim/glider/dragger/robot/anchorlat_deg"), 
                          getprop("sim/glider/dragger/robot/anchorlon_deg"), 
                          getprop("sim/glider/dragger/robot/anchoralt_m") );
  dragpos_geo.set_latlon( getprop("ai/models/dragger/position/latitude-deg"), 
                          getprop("ai/models/dragger/position/longitude-deg"), 
                          getprop("ai/models/dragger/position/altitude-ft") * FT2M);
  
    distance_m = speed_mps * deltatime_s;
  
  newlift_mps = 0.0;
  newliftdist_m = wind_from_down_mps * deltatime_s;
  
  dragpos_geo.apply_course_distance( oldheading_deg , distance_m );
  dragpos_geo.apply_course_distance( 270.0 , wind_from_east_mps * deltatime_s );
  dragpos_geo.apply_course_distance( 180.0 , wind_from_nord_mps * deltatime_s );
  newelevation_m = dragpos_geo.alt() + newliftdist_m;
  dragpos_geo.set_alt(newelevation_m);
  
  setprop("ai/models/dragger/position/latitude-deg", dragpos_geo.lat());
  setprop("ai/models/dragger/position/longitude-deg", dragpos_geo.lon());
  setprop("ai/models/dragger/position/altitude-ft", dragpos_geo.alt() * M2FT);
  setprop("ai/models/dragger/velocities/true-airspeed-kt", speed_mps * MPS2KT);
  setprop("ai/models/dragger/velocities/vertical-speed-fps", newlift_mps * M2FT);
  
  
  # left turn
  if ( dragpos_geo.direct_distance_to(initpos_geo) > leg_distance_m ) { 
	setprop("sim/glider/dragger/robot/leg_type", 1);
	setprop("sim/glider/dragger/robot/leg_segment", 2);
	setprop("sim/glider/dragger/robot/turnside", 0);
	setprop("sim/glider/dragger/conf/glob_max_speed_lift_mps", -1);
	setprop("sim/glider/dragger/conf/glob_max_roll_deg", 45);
	setprop("sim/glider/dragger/conf/glob_max_turnrate_degs", 8);
	if ( (oldheading_deg - 90) <= 0) {
		leg_angle_deg = 360 + ( oldheading_deg - 90 );
	}
	else {
		leg_angle_deg = oldheading_deg - 90;
	}
	setprop("sim/glider/dragger/robot/leg_angle_deg", leg_angle_deg);
	last_leg = 1;
	
  }
  
  
}


var stopRobot = func {
	  # stop loop for updating roboter
  if ( getprop("sim/glider/dragger/flags/run") == 1 ) {
    setprop("sim/glider/dragger/flags/run", 0);
  }
  
  
  # reseting all variables and position to initial values
   setprop("ai/models/dragger/position/latitude-deg",         
                  getprop("sim/glider/dragger/robot/wp0lat_deg") );
  setprop("ai/models/dragger/position/longitude-deg",        
                  getprop("sim/glider/dragger/robot/wp0lon_deg") );
  setprop("ai/models/dragger/position/altitude-ft",          
                  getprop("sim/glider/dragger/robot/wp0alt_m")  * M2FT - 33);
  setprop("ai/models/dragger/orientation/true-heading-deg",  
                  getprop("sim/glider/dragger/robot/wp0head_deg") );
  setprop("ai/models/dragger/orientation/roll-deg",          0);
  setprop("ai/models/dragger/velocities/true-airspeed-kt",   0);
  setprop("ai/models/dragger/velocities/vertical-speed-fps", 0);
  setprop("sim/glider/dragger/robot/leg_type", 0);
  setprop("sim/glider/dragger/robot/leg_segment", 0);
setprop("sim/glider/dragger/conf/glob_max_speed_lift_mps", 3);
  
  removeDragRobot();
}


# ####################################################################################
# function to switch the drag roboter on or off running
# used by key "d" and gui
var startDragRobot = func {
  if ( getprop("sim/glider/dragger/flags/run" ) == 1) {
    setprop("sim/glider/dragger/flags/run", 0);
    print(" stop the drag robot");
  }
  else { 
    print(" start the drag robot");
    setprop("sim/glider/dragger/flags/run", 1);
  }
}



# ####################################################################################
# triggered function to run the drag roboter
var runDragRobot = func {
  if ( getprop("sim/glider/dragger/flags/run" ) == 1) {
    var leg = -1;
    
    leg = getprop("sim/glider/dragger/robot/leg_type");
    
    if ( leg == 0 ) { 
      leg0DragRobot();
    }
    
    if ( leg == 1 ) { 
      leg1DragRobot();
    }
    
    if ( leg == 2 ) { 
      leg2DragRobot();
    }
    
    if ( leg == 3 ) { 
      leg3DragRobot();
    }
    
    settimer(runDragRobot, dragrobot_timeincrement_s);
  }
}



# ####################################################################################
var pulling = setlistener("sim/glider/dragger/flags/run", runDragRobot);
var initializing_dragrobot = setlistener("sim/signals/fdm-initialized", initRobotAttributes);
