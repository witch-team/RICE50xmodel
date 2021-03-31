# POLICY: CTax ADVANCE 
* -------------------------------
* Executes carbon taxes according to ADVANCE-project diagnostic
* cuves.
#____________
* REFERENCES
* - http://www.fp7-advance.eu/


#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================


##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

* Select ctax curve 
$setglobal ctax_diag "c30_gr5"
* No impacts
$setglobal impact "off"
$ifi not %impact%=="off" $abort 'USER ERROR: [impact] must be -off- for CTAX policy!'
* Optimization mode
$setglobal run_mode 'optimization'
$if not %run_mode%=='optimization' $abort 'USER ERROR: [run_mode] must be -optimization- for CTAX policy!'
* Invert MACCs to precompute MIU to ease solution
$setglobal ctax_presolve 1
* Smooth emission vars across iterations
$setglobal ctax_smooth_vars 1


## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

SET ctdiag  'Carbon Tax ADVANCE diagnostics [USD/tCO2]'  /
* Mandatory
 c30_const,
 c80_const,
 c30_gr5,
 c80_gr5,
* Recommended
 c0to30_const,
 c0to30_gr5,
 c0to80_gr5,
 c80_lin,
 #BFC1000,           ### CAP BASED, NOT IMPLEMENTED 
 #BHC1000,           ### CAP BASED, NOT IMPLEMENTED 
* Optional
 #base_def,          ### NOT APPLIABLE
 c0to80_const,
 #c0to80_ant,        ### NOT IMPLEMENTED YET
 #c0to80_late,       ### NOT IMPLEMENTED YET
 #c30_hybrid,        ### NOT IMPLEMENTED YET
 #BFC1800,           ### NOT IMPLEMENTED YET
 #BHC1200            ### NOT IMPLEMENTED YET
 hybrid    
/;


## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

PARAMETER ctax_adv_p(ctdiag,t,n)  ;
* Constant value: 30$ from year > 2020, 0$ before.
ctax_adv_p('c30_const',t,n)$(year(t) lt 2020) = 0 ;
ctax_adv_p('c30_const',t,n)$(year(t) ge 2020) = 30 ;
* Constant value: 80$ from year > 2020, 0$ before.
ctax_adv_p('c80_const',t,n)$(year(t) lt 2020) = 0 ;
ctax_adv_p('c80_const',t,n)$(year(t) ge 2020) = 80 ;
* Growing law: ctax(year) = 30 USD * 1.05 ^ (year - 2040).
* from year > 2020
ctax_adv_p('c30_gr5',t,n)$(year(t) lt 2020) = 0 ;
ctax_adv_p('c30_gr5',t,n)$(year(t) ge 2020) = 30 * (1 + 0.05)**(year(t) - 2040)   ;
* Growing law: ctax(year) = 80 USD * 1.05 ^ (year - 2040).
* Starting from year > 2020
ctax_adv_p('c80_gr5',t,n)$(year(t) lt 2020) = 0 ;
ctax_adv_p('c80_gr5',t,n)$(year(t) ge 2020) = 80 * (1 + 0.05)**(year(t) - 2040)    ;
* Constant value: 30$ from year >= 2040, 0$ before.
ctax_adv_p('c0to30_const',t,n)$(year(t) lt 2040) = 0  ;
ctax_adv_p('c0to30_const',t,n)$(year(t) ge 2040) = 30 ;
* Constant value: 80$ from year >= 2040, 0$ before.
ctax_adv_p('c0to80_const',t,n)$(year(t) lt 2040) = 0 ;
ctax_adv_p('c0to80_const',t,n)$(year(t) ge 2040) = 80 ;
* Growing law: ctax(year) = 30 USD * 1.05 ^ (year - 2040).
* Starting from year >= 2040  
ctax_adv_p('c0to30_gr5',t,n)$(year(t) lt 2040) = 0 ;
ctax_adv_p('c0to30_gr5',t,n)$(year(t) ge 2040) = 30 * (1 + 0.05)**(year(t) - 2040)  ;
* Growing law: ctax(year) = 80 USD * 1.05 ^ (year - 2040).
* Starting from year >= 2040 
ctax_adv_p('c0to80_gr5',t,n)$(year(t) lt 2040) = 0 ;
ctax_adv_p('c0to80_gr5',t,n)$(year(t) ge 2040) = 80 * (1 + 0.05)**(year(t) - 2040)  ;
* Hybrid sums c30_gr5 and half-contribute from c80_gr5
ctax_adv_p('hybrid',t,n) = (ctax_adv_p('c30_gr5',t,n) + ctax_adv_p('c80_gr5',t,n))/2  ;


##  COMPUTE DATA
#_________________________________________________________________________ 
$elseif.ph %phase%=='compute_data'

* Apply selected policy
ctax(t,n) = ctax_adv_p('%ctax_diag%', t, n)/1000  ;  #convert from USD/tCO2 to T$/GtCO2
ctax(t,n)$(year(t) gt 2200) = ctax('38',n)  ;


$endif.ph
