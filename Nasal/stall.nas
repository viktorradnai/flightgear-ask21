
# Stall for ASK21 by HerbyW 09/2017
#

#     /controls/flight/stallflap
#      velocities/airspeed-kt

#       63 km/h = 34.0 kts    Stall speed
#      140 km/h = 75.6 kts    Reisespeed 1.6 m/s
#      
#           km/h = 25.0 kts              m/s 0.98  1.05
#           km/h = 30.0 kts              m/s 0.88  1.05 1.12                                       0.90  
#           63 km/h = 34.0 kts         1.80 m/s 0.80  0.94 0.96 0.84 aoa 23>21        aoa 21>22.7  0.83
#        66 km/h = 35.6 kts         1.00 m/s 0.79  0.91 0.93 0.82               0.80               0.82
#        70 km/h = 37.8 kts         0.80 m/s 0.82  0.90 0.90 0.80               0.78               0.80
#        82 km/h = 44.2 kts         0.75 m/s 0.82  0.86 0.86 0.80               0.76               0.80
#       140 km/h = 75.6 kts         1.60 m/s 1.89  1.64 1.50 1.62               1.46               1.60
#       180 km/h = 97.2 kts         2.90 m/s 3.63  3.04 2.70 3.01               2.70               2.97
#


setprop("/controls/flight/stallflap", 0);

var stalltimer = maketimer(2.0, func {
  var airspeed = getprop("/velocities/airspeed-kt");
  
  if (airspeed > 37.8)
  {
    interpolate("/controls/flight/stallflap", 0, 0.95);
    
  }
  else
  {
    
    if (airspeed > 35.6)
    {
      interpolate("/controls/flight/stallflap", 0.05, 2.8);
      
    }
    else
    {
      
      if (airspeed > 34)
      {
	interpolate("/controls/flight/stallflap", 0.35 , 2.8);
	
      }
      else
      {
	
	if (airspeed > 30)
	{
	  interpolate("/controls/flight/stallflap", 0.85, 2.8);
	  
	}  
	else
	{
	  
	  if (airspeed > 25)
	  {
	    interpolate("/controls/flight/stallflap", 1.0, 2.8);
	    
	  } 
	}}}}
}
);
stalltimer.start();