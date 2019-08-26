#    This file is part of extra500
#
#    extra500 is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 2 of the License, or
#    (at your option) any later version.
#
#    extra500 is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with extra500.  If not, see <http://www.gnu.org/licenses/>.
#
#	Authors: 		Dirk Dittmann
#	Date: 		Mai 02 2015
#
#	Last change:	Eric van den Berg
#	Date:			15.08.16
#




#1326px=1483mm
#0.89413px=1mm
#126,93


#Load Constants
var mm_px=0.89413;
var kg_lbs=2.20462;
var JETA_LBGAL=6.7898;
var ad_const=160; 	#160lbs average adult weight
var ch_const=80;	#80lbs average children weight

var clamp = func(value,min=0.0,max=0.0){
	if(value < min) {value = min;}
	if(value > max) {value = max;}
	return value;
}

var MyWindow = {
  # Constructor
  #
  # @param size ([width, height])
  new: func(size, type = nil, id = nil)
  {
    var ghost = canvas._newWindowGhost(id);
    var m = {
      parents: [MyWindow, canvas.PropertyElement, ghost],
      _node: props.wrapNode(ghost._node_ghost)
    };

    m.setInt("size[0]", size[0]);
    m.setInt("size[1]", size[1]);

    # TODO better default position
    m.move(0,0);

    # arg = [child, listener_node, mode, is_child_event]
    setlistener(m._node, func m._propCallback(arg[0], arg[2]), 0, 2);
    if( type )
      m.set("type", type);

    m._isOpen = 1;
    return m;
  },
  # Destructor
  del: func
  {
    me._node.remove();
    me._node = nil;

    if( me["_canvas"] != nil )
    {
      me._canvas.del();
      me._canvas = nil;
    }
     me._isOpen = 0;
  },
  # Create the canvas to be used for this Window
  #
  # @return The new canvas
  createCanvas: func()
  {
    var size = [
      me.get("size[0]"),
      me.get("size[1]")
    ];

    me._canvas = canvas.new({
      size: [2 * size[0], 2 * size[1]],
      view: size,
      placement: {
        type: "window",
        id: me.get("id")
      }
    });

    me._canvas.addEventListener("mousedown", func me.raise());
    return me._canvas;
  },
  # Set an existing canvas to be used for this Window
  setCanvas: func(canvas_)
  {
    if( !isa(canvas_, canvas.Canvas) )
      return debug.warn("Not a canvas.Canvas");

    canvas_.addPlacement({type: "window", index: me._node.getIndex()});
    me['_canvas'] = canvas_;
  },
  # Get the displayed canvas
  getCanvas: func()
  {
    return me['_canvas'];
  },
  getCanvasDecoration: func()
  {
    return canvas.wrapCanvas(me._getCanvasDecoration());
  },
  setPosition: func(x, y)
  {
    me.setInt("tf/t[0]", x);
    me.setInt("tf/t[1]", y);
  },
  move: func(x, y)
  {
    me.setInt("tf/t[0]", me.get("tf/t[0]", 10) + x);
    me.setInt("tf/t[1]", me.get("tf/t[1]", 30) + y);
  },
  # Raise to top of window stack
  raise: func()
  {
    # on writing the z-index the window always is moved to the top of all other
    # windows with the same z-index.
    me.setInt("z-index", me.get("z-index", 0));
  },
# private:
  _propCallback: func(child, mode)
  {
    if( !me._node.equals(child.getParent()) )
      return;
    var name = child.getName();

    # support for CSS like position: absolute; with right and/or bottom margin
    if( name == "right" )
      me._handlePositionAbsolute(child, mode, name, 0);
    else if( name == "bottom" )
      me._handlePositionAbsolute(child, mode, name, 1);

    # update decoration on type change
    else if( name == "type" )
    {
      if( mode == 0 )
        settimer(func me._updateDecoration(), 0);
    }
  },
  _handlePositionAbsolute: func(child, mode, name, index)
  {
    # mode
    #   -1 child removed
    #    0 value changed
    #    1 child added

    if( mode == 0 )
      me._updatePos(index, name);
    else if( mode == 1 )
      me["_listener_" ~ name] = [
        setlistener
        (
          "/sim/gui/canvas/size[" ~ index ~ "]",
          func me._updatePos(index, name)
        ),
        setlistener
        (
          me._node.getNode("size[" ~ index ~ "]"),
          func me._updatePos(index, name)
        )
      ];
    else if( mode == -1 )
      for(var i = 0; i < 2; i += 1)
        removelistener(me["_listener_" ~ name][i]);
  },
  _updatePos: func(index, name)
  {
    me.setInt
    (
      "tf/t[" ~ index ~ "]",
      getprop("/sim/gui/canvas/size[" ~ index ~ "]")
      - me.get(name)
      - me.get("size[" ~ index ~ "]")
    );
  },
  _onClose : func(){
	me.del();
  },
  _updateDecoration: func()
  {
    var border_radius = 9;
    me.set("decoration-border", "25 1 1");
    me.set("shadow-inset", int((1 - math.cos(45 * D2R)) * border_radius + 0.5));
    me.set("shadow-radius", 5);
    me.setBool("update", 1);

    var canvas_deco = me.getCanvasDecoration();
    canvas_deco.addEventListener("mousedown", func me.raise());
    canvas_deco.set("blend-source-rgb", "src-alpha");
    canvas_deco.set("blend-destination-rgb", "one-minus-src-alpha");
    canvas_deco.set("blend-source-alpha", "one");
    canvas_deco.set("blend-destination-alpha", "one");

    var group_deco = canvas_deco.getGroup("decoration");
    var title_bar = group_deco.createChild("group", "title_bar");
    title_bar
      .rect( 0, 0,
             me.get("size[0]"),
             me.get("size[1]"), #25,
             {"border-top-radius": border_radius} )
      .setColorFill(0.25,0.24,0.22)
      .setStrokeLineWidth(0);

    var style_dir = "gui/styles/AmbianceClassic/decoration/";

    # close icon
    var x = 10;
    var y = 3;
    var w = 19;
    var h = 19;
    var ico = title_bar.createChild("image", "icon-close")
                       .set("file", style_dir ~ "close_focused_normal.png")
                       .setTranslation(x,y);
    ico.addEventListener("click", func me._onClose());
    ico.addEventListener("mouseover", func ico.set("file", style_dir ~ "close_focused_prelight.png"));
    ico.addEventListener("mousedown", func ico.set("file", style_dir ~ "close_focused_pressed.png"));
    ico.addEventListener("mouseout",  func ico.set("file", style_dir ~ "close_focused_normal.png"));

    # title
    me._title = title_bar.createChild("text", "title")
                         .set("alignment", "left-center")
                         .set("character-size", 14)
                         .set("font", "LiberationFonts/LiberationSans-Bold.ttf")
                         .setTranslation( int(x + 1.5 * w + 0.5),
                                          int(y + 0.5 * h + 0.5) );

    var title = me.get("title", "Canvas Dialog");
    me._node.getNode("title", 1).alias(me._title._node.getPath() ~ "/text");
    me.set("title", title);

    title_bar.addEventListener("drag", func(e) {
      if( !ico.equals(e.target) )
        me.move(e.deltaX, e.deltaY);
    });
  }
};

var COLOR = {};
COLOR["Red"] 			= "rgb(244,28,33)";
COLOR["Green"] 			= "#008000";
COLOR["Black"] 			= "#000000";
COLOR["btnActive"] 		= "#9ec5ffff";
COLOR["btnPassive"] 		= "#003ea2ff";
COLOR["btnEnable"] 		= "#2a7fffff";
COLOR["btnBorderEnable"] 	= "#0000ffff";
COLOR["btnDisable"] 		= "#8c939dff";
COLOR["btnBorderDisable"] 	= "#69697bff";


var SvgWidget = {
	new: func(dialog,canvasGroup,name){
		var m = {parents:[SvgWidget]};
		m._class = "SvgWidget";
		m._dialog 	= dialog;
		m._listeners 	= [];
		m._name 	= name;
		m._group	= canvasGroup;
		return m;
	},
	removeListeners  :func(){
		foreach(l;me._listeners){
			removelistener(l);
		}
		me._listeners = [];
	},
	setListeners : func(instance) {
		
	},
	init : func(instance=me){
		
	},
	deinit : func(){
		me.removeListeners();	
	},
	
};

var TankWidget = {
	new: func(dialog,canvasGroup,name,lable,index,refuelable=1){
		var m = {parents:[TankWidget,SvgWidget.new(dialog,canvasGroup,name)]};
		m._class = "TankWidget";
		m._index 	= index;
		m._refuelable 	= refuelable;
		m._lable 	= lable;
		m._nLevel 	= props.globals.initNode("/consumables/fuel/tank["~m._index~"]/level-gal_us",0.0,"DOUBLE");
		m._nCapacity 	= props.globals.initNode("/consumables/fuel/tank["~m._index~"]/capacity-gal_us",0.0,"DOUBLE");
		
		m._level	= m._nLevel.getValue();
		m._capacity	= m._nCapacity.getValue();
		m._fraction	= m._level / m._capacity;
			
		m._cFrame 	= m._group.getElementById(m._name~"_Frame");
		m._cLevel 	= m._group.getElementById(m._name~"_Level");
		#m._cDataName 	= m._group.getElementById(m._name~"_Data_Name");
		#m._cDataMax 	= m._group.getElementById(m._name~"_Data_Max");
		m._cDataLevel 	= m._group.getElementById(m._name~"_Data_Level");
		#m._cDataPercent	= m._group.getElementById(m._name~"_Data_Percent");
				
		#m._cDataName.setText(m._lable);
		#m._cDataMax.setText(sprintf("%3.0f",m._capacity * JETA_LBGAL));
		m._cDataLevel.setText(sprintf("%3.0f",m._level * JETA_LBGAL));
		#m._cDataPercent.setText(sprintf("%3.1f",m._fraction*100.0));
		
		
		m._left		= m._cFrame.get("coord[0]");
		m._right	= m._cFrame.get("coord[2]");
		m._width	= m._right - m._left;
		#me.cLeftAuxFrame.addEventListener("wheel",func(e){me._onLeftAuxFuelChange(e);});
		
		return m;
	},
	setListeners : func(instance) {
		
		append(me._listeners, setlistener(me._nLevel,func(n){me._onFuelLevelChange(n);},1,0) );
		if(me._refuelable == 1){
			me._cFrame.addEventListener("drag",func(e){me._onFuelInputChange(e);});
			me._cLevel.addEventListener("drag",func(e){me._onFuelInputChange(e);});
			me._cFrame.addEventListener("wheel",func(e){me._onFuelInputChange(e);});
			me._cLevel.addEventListener("wheel",func(e){me._onFuelInputChange(e);});
			
		}
	},
	init : func(instance=me){
		me.setListeners(instance);
	},
	deinit : func(){
		me.removeListeners();	
	},
	_onFuelLevelChange : func(n){
		me._level	= n.getValue();
		me._fraction	= me._level / me._capacity;
		
		me._cDataLevel.setText(sprintf("%3.0f",me._level * JETA_LBGAL));
		#me._cDataPercent.setText(sprintf("%3.1f",me._fraction*100.0));
		
		me._cLevel.set("coord[2]", me._left + (me._width * me._fraction));
			
	},
	_onFuelInputChange : func(e){
		var newFraction = 0;
		if(e.type == "wheel"){
			newFraction = me._fraction + (e.deltaY/me._width);
		}else{
			newFraction = me._fraction + (e.deltaX/me._width);
		}
		newFraction = clamp(newFraction,0.0,1.0);
		me._nLevel.setValue(me._capacity * newFraction);
		
	},
};




var WeightWidget = {
	new: func(dialog,canvasGroup,name,widgets){
		var m = {parents:[WeightWidget,SvgWidget.new(dialog,canvasGroup,name)]};
		m._class = "WeightWidget";
		m._widget = {};
		
		foreach(w;keys(widgets)){
			if(widgets[w] != nil){
				if(widgets[w]._class == "PayloadWidget"){
					m._widget[w] = widgets[w];
				}
			}
		}
		
		
 		m._cCenterGravityX	 	= m._group.getElementById("CenterGravity_X");
 		m._cCenterGravityXMarker	= m._group.getElementById("CenterGravity_X_Marker");
 		m._cCenterGravityXWarning	= m._group.getElementById("CenterGravity_X_Warning");
# 		m._cCenterGravityY	 	= m._group.getElementById("CenterGravity_Y");
# 		m._cCenterGravityBall	 	= m._group.getElementById("CenterGravity_Ball").updateCenter();
#		m._cWeightEmpty		 	= m._group.getElementById("Weight_Empty");
		m._cWeightGross	 		= m._group.getElementById("Weight_Gross");
		m._cWeightMTOW	 		= m._group.getElementById("Weight_MTOW");
		m._cWeightWarning	 	= m._group.getElementById("Weight_Warning");
#		m._cWeightPayload	 	= m._group.getElementById("Weight_Payload");
#		m._cWeightPAX		 	= m._group.getElementById("Weight_PAX");
#		m._cWeightMaxRamp	 	= m._group.getElementById("Weight_Max_Ramp");
#		m._cWeightMaxTakeoff	 	= m._group.getElementById("Weight_Max_Takeoff");
#		m._cWeightMaxLanding	 	= m._group.getElementById("Weight_Max_Landing");
#		m._cWeightMACPercent	 	= m._group.getElementById("Weight_MAC_Percent");
		
# 		m._cCenterGravityXMax	 	= m._group.getElementById("CenterGravity_X_Max");
# 		m._cCenterGravityXMin	 	= m._group.getElementById("CenterGravity_X_Min");
# 		m._cCenterGravityYMax	 	= m._group.getElementById("CenterGravity_Y_Max");
# 		m._cCenterGravityYMin	 	= m._group.getElementById("CenterGravity_Y_Min");
		m._cWeight_Limits_lbs	 	= m._group.getElementById("Weight_Limits_lbs");
		m._cWeight_Limits_in	 	= m._group.getElementById("Weight_Limits_in");
		
		
		
		#m._nCGx 	= props.globals.initNode("/fdm/jsbsim/inertia/cg-x-mm-rp");
		#m._nCGy 	= props.globals.initNode("/fdm/jsbsim/inertia/cg-y-in");
		m._nGross 	= props.globals.initNode("/fdm/jsbsim/inertia/weight-lbs");
		m._nPayload 	= props.globals.initNode("/fdm/jsbsim/inertia/weight-lbs");
		m._nEmpty 	= props.globals.initNode("/fdm/jsbsim/inertia/empty-weight-lbs");
		m._nRamp 	= props.globals.initNode("/limits/mass-and-balance/maximum-ramp-mass-lbs");
		m._nTakeoff 	= props.globals.initNode("/limits/mtow-lbs");
		m._nLanding 	= props.globals.initNode("/limits/mass-and-balance/maximum-landing-mass-lbs");
# 		m._nCGxMax 	= props.globals.initNode("/limits/mass-and-balance/cg-x-max-in",120.0,"DOUBLE");
# 		m._nCGxMin 	= props.globals.initNode("/limits/mass-and-balance/cg-x-min-in",150.0,"DOUBLE");
# 		m._nCGyMax 	= props.globals.initNode("/limits/mass-and-balance/cg-y-max-in",100.0,"DOUBLE");
# 		m._nCGyMin 	= props.globals.initNode("/limits/mass-and-balance/cg-y-min-in",-100.0,"DOUBLE");
		m._nMac 	= props.globals.initNode("/limits/mass-and-balance/mac-mm",1322.0,"DOUBLE");
		m._nMac0 	= props.globals.initNode("/limits/mass-and-balance/mac-0-mm",3200.0,"DOUBLE");
		
		
		m._cgX  	= 0;
		m._cgY  	= 0;
		m._empty 	= 0;
		m._payload 	= 0;
		m._pax		= 0;
		m._gross 	= 0;
		m._ramp  	= 0;
		m._takeoff  	= 0;
		m._landing 	= 0;
		m._MACPercent 	= 0.0; # %
		m._MAC 			= m._nMac.getValue(); # mm
		m._MAC_0 		= m._nMac0.getValue(); # mm
		m._MAC_Limit_Min	= 0.17; #%
		m._MAC_Limit_Max	= 0.35; #%
#		m._WeightLimit_lbs_x0 	= m._cWeight_Limits_lbs.get("coord[2]");
#		m._WeightLimit_lbs_y0 	= m._cWeight_Limits_lbs.get("coord[1]");
#		m._WeightLimit_in_x0 	= m._cWeight_Limits_in.get("coord[0]");
#		m._WeightLimit_in_y0 	= m._cWeight_Limits_in.get("coord[3]");
		
#		m._WeightLimit_lbs_pixel 	= 0;
#		m._WeightLimit_in_pixel 	= 0;
		
		
# 		m._cgXMax	= m._nCGxMax.getValue();
# 		m._cgXMin	= m._nCGxMin.getValue();
# 		m._cgYMax	= m._nCGyMax.getValue();
# 		m._cgYMin	= m._nCGyMin.getValue();
		
		
#		m._ramp = m._nRamp.getValue();
#		m._cWeightMaxRamp.setText(sprintf("%.0f",m._ramp));
		m._takeoff = m._nTakeoff.getValue();
#		m._cWeightMaxTakeoff.setText(sprintf("%.0f",m._takeoff));
#		m._landing = m._nLanding.getValue();
#		m._cWeightMaxLanding.setText(sprintf("%.0f",m._landing));
		
# 		m._cCenterGravityXMax.setText(sprintf("%.2f",m._cgXMax));
# 		m._cCenterGravityXMin.setText(sprintf("%.2f",m._cgXMin));
# 		m._cCenterGravityYMax.setText(sprintf("%.2f",m._cgYMax));
# 		m._cCenterGravityYMin.setText(sprintf("%.2f",m._cgYMin));
		
#		m._empty = m._nEmpty.getValue() + getprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[7]") + getprop("/fdm/jsbsim/inertia/pointmass-weight-lbs[8]");
#		m._cWeightEmpty.setText(sprintf("%.0f",m._empty));
		
		
#		m._cWeightMACPercent.setText(sprintf("%.2f",m._MACPercent));
		
		return m;
	},
	setListeners : func(instance) {
		append(me._listeners, setlistener(fuelPayload._nGrossWeight,func(n){me._onGrossWeightChange(n);},1,0) );
		append(me._listeners, setlistener(fuelPayload._nCGx,func(n){me._onCGChange(n);},1,0) );
		
	},
	init : func(instance=me){
		me.setListeners(instance);
	},
	deinit : func(){
		me.removeListeners();	
	},
	_onGrossWeightChange : func(n){
		
		#me._cgX = me._nCGx.getValue();
 		#me._cCenterGravityX.setText(sprintf("%3d",me._cgX));
 		
 		#me._cCenterGravityXMarker.setTranslation((me._cgX-142)*mm_px,0);
 		
 		#if(me._cgX>234 and me._cgX<469){
		#	me._cCenterGravityXWarning.hide();
		#}else{
		#	me._cCenterGravityXWarning.show();
		#}
		
		me._gross = me._nGross.getValue();
		me._cWeightGross.setText(sprintf("%4d",me._gross));
		
		me._cWeightMTOW.setText(sprintf("%4d",me._takeoff));
		
		
		
		#me._cCenterGravityBall.setTranslation(me._cgX * (64/13), (me._cgY - 136.0) * (64/13) );
		#me._cCenterGravityBall.setTranslation((me._cgY - 136.0) , me._cgX);

		
		if (me._gross > me._takeoff){
			me._cWeightWarning.show();
			me._cWeightGross.setColor(COLOR["Red"]);
		}else{
			me._cWeightWarning.hide();
			me._cWeightGross.setColor(COLOR["Black"]);
		}
		
	},
	_onCGChange : func(n){
		
		me._cgX = fuelPayload._nCGx.getValue();
 		me._cCenterGravityX.setText(sprintf("%3d",me._cgX));
 		
 		me._cCenterGravityXMarker.setTranslation((me._cgX-142)*mm_px,0);
 		
 		if(me._cgX>234 and me._cgX<469){
			me._cCenterGravityXWarning.hide();
		}else{
			me._cCenterGravityXWarning.show();
		}
		
	},
	
	
	
};

var PayloadWidget = {
	new: func(dialog,canvasGroup,name,lable,index){
		var m = {parents:[PayloadWidget,SvgWidget.new(dialog,canvasGroup,name)]};
		m._class = "PayloadWidget";
		m._index 	= index;
		m._lable 	= lable;
		
		#debug.dump(m._listCategoryKeys);
		
		m._nRoot	= props.globals.getNode("/payload/weight["~m._index~"]");
		m._nLable 	= m._nRoot.initNode("name","","STRING");
		
		### HACK : listener on /payload/weight[0]/weight-lb not working
		###	   two props one for fdm(weight-lb) one for dialog(nt-weight-lb) listener
		m._nWeightFdm 	= m._nRoot.initNode("weight-lb",0.0,"DOUBLE");
		m._weight	= m._nWeightFdm.getValue(); # lbs
		m._nWeight 	= m._nRoot.initNode("nt-weight-lb",m._weight,"DOUBLE");
		
		m._nCapacity 	= m._nRoot.initNode("max-lb",0.0,"DOUBLE");
		
		m._capacity	= m._nCapacity.getValue();
		m._fraction	= m._weight / m._capacity;
		
		m._cFrame 	= m._group.getElementById(m._name~"_Frame");
		m._cLevel 	= m._group.getElementById(m._name~"_Level");
		m._cLBS 	= m._group.getElementById(m._name~"_Lbs");
	
		m._cLBS.setText(sprintf("%3.0f",m._weight));
				
		
		m._left		= m._cFrame.get("coord[0]");
		m._right	= m._cFrame.get("coord[2]");
		m._width	= m._right - m._left;
		
		return m;
	},
	setListeners : func(instance) {
		### FIXME : use one property remove the HACK
		append(me._listeners, setlistener(me._nWeight,func(n){me._onWeightChange(n);},1,0) );
				
		me._cFrame.addEventListener("drag",func(e){me._onInputChange(e);});
		me._cLevel.addEventListener("drag",func(e){me._onInputChange(e);});
		me._cFrame.addEventListener("wheel",func(e){me._onInputChange(e);});
		me._cLevel.addEventListener("wheel",func(e){me._onInputChange(e);});
		
			
		
	},
	init : func(instance=me){
		me.setListeners(instance);
	},
	deinit : func(){
		me.removeListeners();	
	},
	setWeight : func(weight){
		me._weight = weight;
		
		### HACK : set two props 
		me._nWeight.setValue(me._weight);
		me._nWeightFdm.setValue(me._weight);
		
	},
	_onWeightChange : func(n){
		me._weight	= me._nWeight.getValue();
		#print("PayloadWidget._onWeightChange() ... "~me._weight);
		
		me._fraction	= me._weight / me._capacity;
		
		me._cLBS.setText(sprintf("%3.0f",me._weight));
		
		me._cLevel.set("coord[2]", me._left + (me._width * me._fraction));
		
		
			
	},
	_onInputChange : func(e){
		var newFraction =0;
		if(e.type == "wheel"){
			newFraction = me._fraction + (e.deltaY/me._width);
		}else{
			newFraction = me._fraction + (e.deltaX/me._width);
		}
		newFraction = clamp(newFraction,0.0,1.0);
		me._weight = me._capacity * newFraction;
		
		me.setWeight(me._weight);

	},
};

var BallastWidget = {
	new: func(dialog,canvasGroup,name,lable,index){
		var m = {parents:[BallastWidget,SvgWidget.new(dialog,canvasGroup,name)]};
		m._class = "BallastWidget";
		m._index 	= index;
		m._lable 	= lable;
		
		#debug.dump(m._listCategoryKeys);
		
		m._nRoot	= props.globals.getNode("/payload/weight["~m._index~"]");
		m._nLable 	= m._nRoot.initNode("name","","STRING");
		
		### HACK : listener on /payload/weight[0]/weight-lb not working
		###	   two props one for fdm(weight-lb) one for dialog(nt-weight-lb) listener
		m._nWeightFdm 	= m._nRoot.initNode("weight-lb",0.0,"DOUBLE");
		m._weight	= m._nWeightFdm.getValue(); # lbs
		m._nWeight 	= m._nRoot.initNode("nt-weight-lb",m._weight,"DOUBLE");
		
		m._nCapacity 	= m._nRoot.initNode("max-lb",0.0,"DOUBLE");
		
		m._nPlates	= m._nRoot.initNode("plates",0,"DOUBLE");
		m._plates	= m._nPlates.getValue();
		m._nPlatesMax	= m._nRoot.initNode("plates-max",12,"DOUBLE");
		
		m._cLbs		= m._group.getElementById(m._name~"_Lbs");
		m._cFrame0 	= m._group.getElementById(m._name~"_0");
		m._cFrame2 	= m._group.getElementById(m._name~"_2");
		m._cFrame4 	= m._group.getElementById(m._name~"_4");
		m._cFrame6 	= m._group.getElementById(m._name~"_6");
		m._cFrame8	= m._group.getElementById(m._name~"_8");
		m._cFrame10 	= m._group.getElementById(m._name~"_10");
		m._cFrame12 	= m._group.getElementById(m._name~"_12");
	
		m._cLbs.setText(sprintf("%2.1f",m._nWeight.getValue()));
		#m._cNCh.setText(sprintf("%3d",m._nChildren.getValue()));
				
		
		
		return m;
	},
	setListeners : func(instance) {
		### FIXME : use one property remove the HACK
		append(me._listeners, setlistener(me._nPlates,func(n){me._onPlatesChange(n);},1,0) );
		append(me._listeners, setlistener(me._nWeight,func(n){me._onWeightChange(n);},1,0) );
				
		me._cFrame0.addEventListener("click",func(e){me.setPlates(0);});
		me._cFrame2.addEventListener("click",func(e){me.setPlates(2);});
		me._cFrame4.addEventListener("click",func(e){me.setPlates(4);});
		me._cFrame6.addEventListener("click",func(e){me.setPlates(6);});
		me._cFrame8.addEventListener("click",func(e){me.setPlates(8);});
		me._cFrame10.addEventListener("click",func(e){me.setPlates(10);});
		me._cFrame12.addEventListener("click",func(e){me.setPlates(12);});
				
		
			
		
	},
	init : func(instance=me){
		me.setListeners(instance);
	},
	deinit : func(){
		me.removeListeners();	
	},
	setWeight : func(plates){
		me._weight = plates*kg_lbs;
		### HACK : set two props 
		me._nWeight.setValue(me._weight);
		me._nWeightFdm.setValue(me._weight);
		
		
	},
	setPlates : func(plates){
		me._plates = plates;
		me._nPlates.setValue(me._plates);
		
	},
	_onWeightChange : func(n){
		var weight = me._nWeight.getValue();
		
		var plates=weight/kg_lbs;
		
		me.setPlates(plates);
		
		me._cLbs.setText(sprintf("%2.1f",me._weight));	
		
			
	},
	_onPlatesChange : func(n){
		var plates = me._nPlates.getValue();
		
		me.setWeight(plates);
		
		
			
	},
};



var FuelPayloadClass = {
	new : func(){
		var m = {parents:[FuelPayloadClass]};
		m._nRoot 	= props.globals.initNode("/ask21/dialog/fuel");
		
		m._nGrossWeight	= props.globals.initNode("/fdm/jsbsim/inertia/nt-weight-lbs",0.0,"DOUBLE"); #listener on weight-lbs not possible, set via system in Systems/fuelpayload.xml
		m._nCGx	= props.globals.initNode("/fdm/jsbsim/inertia/cg-x-mm-rp",0.0,"DOUBLE"); #calculated CG distance to reference point, set via system in Systems/fuelpayload.xml
		
		m._name  = "Fuel and Payload";
		m._title = "Fuel and Payload Settings";
		m._fdmdata = {
			grosswgt : "/fdm/jsbsim/inertia/weight-lbs",
			payload  : "/payload",
			cg       : "/fdm/jsbsim/inertia/cg-x-in",
		};
		m._tankIndex = [
			"Tank"
			];
		
		
		m._listeners = [];
		m._dlg 		= nil;
		m._canvas 	= nil;
		
		m._isOpen = 0;
		m._isNotInitialized = 1;
		
		m._widget = {
			Tank	 	: nil,
			Pilot	 	: nil,
			Copilot		: nil,
			Ballast	 	: nil,
			weight	 	: nil,
		};
		

		return m;
	},
	toggle : func(){
		if(me._dlg != nil){
			if (me._dlg._isOpen){
				me.close();
			}else{
				me.open();	
			}
		}else{
			me.open();
		}
	},
	close : func(){
		me._dlg.del();
		me._dlg = nil;
	},
	removeListeners  :func(){
		foreach(l;me._listeners){
			removelistener(l);
		}
		me._listeners = [];
	},
	setListeners : func(instance) {
	
		
	},
	_onClose : func(){
		#print("FuelPayloadClass._onClose() ... ");
		me.removeListeners();
		me._dlg.del();
		
		foreach(widget;keys(me._widget)){
			if(me._widget[widget] != nil){
				me._widget[widget].deinit();
				me._widget[widget] = nil;
			}
		}
		
	},
	open : func(){
		if(getprop("/gear/gear[0]/wow") == 1){
			me.openFuel();
		}else{
			screen.log.write("Changing fuel and payload in air is not possible. Please land first.");
		}
		
	},
	openFuel : func(){
		
		
		me._dlg = MyWindow.new([1024,690], "dialog");
		me._dlg._onClose = func(){
			fuelPayload._onClose();
		}
		me._dlg.set("title", "Fuel and Payload");
		me._dlg.move(100,100);
		
		
		me._canvas = me._dlg.createCanvas();
		me._canvas.set("background", "#FFFFFF");
		
		me._group = me._canvas.createGroup();

		canvas.parsesvg(me._group, "Aircraft/ASK21/gui/dialogs/FuelPayload.svg",{"font-mapper": global.canvas.FontMapper});
		
		me._fuselage_mi 	= me._group.getElementById("fuselage_ask21mi");
		me._fuselage 	= me._group.getElementById("fuselage_ask21");
		me._fuel	= me._group.getElementById("fuel_group");
		me._cg_mi	= me._group.getElementById("cg_mi");
		me._cg		= me._group.getElementById("cg");
		me._title	= me._group.getElementById("title");
		me._title_mi	= me._group.getElementById("title_mi");
		
		var variant = getprop("/sim/aero") or "";
		if(variant=="ask21mi" or variant=="ask21mi-jsb"){
			me._title.hide();
			me._title_mi.show();
			me._fuselage_mi.show();
			me._fuselage.hide();
			me._fuel.show();
			me._cg_mi.show();
			me._cg.hide();
			me._widget.Tank 		= TankWidget.new(me,me._group,"Fuel","Fuel Tank:",0,1);
		 }else{
			me._title.show();
			me._title_mi.hide();
			me._fuselage_mi.hide();
			me._fuselage.show();
			me._fuel.hide();
			me._cg_mi.hide();
			me._cg.show();
		}
			
		
		me._widget.Pilot		= PayloadWidget.new(me,me._group,"Pilot","Pilot",0);
		me._widget.Copilot		= PayloadWidget.new(me,me._group,"Copilot","Copilot",1);
		me._widget.Ballast		= BallastWidget.new(me,me._group,"Ballast","Ballast",2);
		
		me._widget.weight = WeightWidget.new(me,me._group,"Weight",me._widget);
		
		foreach(widget;keys(me._widget)){
			if(me._widget[widget] != nil){
				me._widget[widget].init();
			}
		}
		
		#me.setListeners();
		
		
	},
	_onNotifyChange : func(n){

	},
	_onFuelTotalChange : func(n){
		
	}
	
};

var fuelPayload = FuelPayloadClass.new();

gui.menuBind("fuel-and-payload", "dialogs.fuelPayload.toggle();");

