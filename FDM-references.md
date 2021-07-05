The following is a table of references used for the JSBSim FDM. The ID is used to mark values from these references in the FDM files:  

| ID | Name                                                           | URL                                                                                   |
|----|----------------------------------------------------------------|---------------------------------------------------------------------------------------|
| 1  | ASK21 Flight Manual                                            | http://skylinesoaring.org/docs/Manuals/ASK-21-Flight-Manual.pdf                       |
| 2  | ASK21 Mi Flight Manual                                         | http://www.aviation.3wg.aafc.org.au/wp-content/uploads/ASK21Mi-Flight-Manual.pdf      |
| 3  | EASA Type-Certificate Data Sheet (ASK21, ASK21 Mi and ASK21 B) | https://www.easa.europa.eu/sites/default/files/dfu/EASA_A_221_ASK21_issue05.pdf       |
| 4  | ASK21 Manufacturer's Website                                   | https://www.alexander-schleicher.de/en/flugzeuge/ask-21/                              |
| 5  | ASK21 Mi Manufacturer's Website                                | https://www.alexander-schleicher.de/en/flugzeuge/ask-21-mi/                           |
| 6  | ASK21 Maintenance Manual (german)                              | https://www.lsb-donaueschingen.de/downloads/ASK21-D8979-Wartungshandbuch-komplett.pdf |
| 7  | ASK21 TM 04 (manual pages)                                     | https://www.alexander-schleicher.de/wp-content/uploads/2015/02/210_TM04_E_HB.pdf      |
| 8  | ASK21 TM 04A (manual pages)                                    | https://www.alexander-schleicher.de/wp-content/uploads/2015/02/210_TM04A_E_HB.pdf     |
| 9  | ASK21 TM 04B (manual pages)                                    | https://www.alexander-schleicher.de/wp-content/uploads/2015/02/210_TM04B_E.pdf        |
| 10 | ASK21 Mi TM 03 (manual pages)                                  | https://www.alexander-schleicher.de/wp-content/uploads/2015/02/219_TM03_D_HB.pdf      |
| 11 | ASK21 POH (scanned, including weighing records)                | https://mnsoaringclub.com/wp-content/uploads/2019/03/Ask21-POH.pdf                    |

## CoG (Center of Gravity) notes: (ref. [3] A.III.10 / B.III.13 )
* datum is the leading edge at the wing root. This equals about x = -1.635m  on our model
* this leads to the following tables (assuming empty weight is 360kg):
*     ASK21:  

|                         | m behind datum | x [m]  |     reference    |
|-------------------------|----------------|--------|------------------|
| Forward Limit           | 0.234          | -1.401 | ref.[3] A.III.10 |
| Rear Limit              | 0.469          | -1.166 | ref.[3] A.III.10 |
| Empty CoG Forward Limit | 0.784          | -0.851 | ref.[1] p.46     |
| Empty CoG Rear Limit    | 0.792          | -0.843 | ref.[1] p.46     |


*     ASK21 Mi:  

|                         | m behind datum | x [m]  |     reference    |
|-------------------------|----------------|--------|------------------|
| Forward Limit           | 0.234          | -1.401 | ref.[3] B.III.13 |
| Rear Limit              | 0.469          | -1.166 | ref.[3] B.III.13 |
| Empty CoG Forward Limit | ??             | ??     | ??               |
| Empty CoG Rear Limit    | ??             | ??     | ??               |

* the following mass arms are given in the flight manual (ref. [1] p.51f.):  

|	Location		|	arm [in]	|	arm [m]		|	x [m]		|
|-------------------------------|-----------------------|-----------------------|-----------------------|
|	Front Pilot (short)	|	-49.21		|	-1.250		|	-2.885		|
|	Front Pilot (long)	|	-46.65		|	-1.185		|	-2.82		|
|	Rear Pilot		|	 -3.15		|	-0.08		|	-1.715		|
|	Baggage			|	  9.84		|	 0.25		|	-1.385		|

### ref. [11], p.30f.
* this includes a weighing record, showing measured values
* **using the most recent weighing (May 24, 2000), we get the following values:**
* empty mass: 829 lbs = 376 kg  

|                         |  m behind datum  | x [m]  |    reference                  |
|-------------------------|------------------|--------|-------------------------------|
| Empty CoG Forward Limit | 0.760            | -0.875 | ref.[11], p.30 (interpolated) |
| Empty CoG Rear Limit    | 0.778            | -0.857 | ref.[11], p.30 (interpolated) |
| Empty CoG               | 30.19 in = 0.767 | -0.868 | ref.[11], p.31                |
