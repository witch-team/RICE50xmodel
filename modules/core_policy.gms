* POLICY MODULE
* ---------------
* Includes settings for principal and most common model policies.
* More complex and articulated policies have a self-dedicated "pol_*" module
* -> BAU-NO-IMPACTS  no mitigation, no impact
* -> BAU-IMPACTS     no mitigations, impacts
* -> CBA             benefit-cost analysis  
* -> SIMULATION      simulation give external trajectories for MIU (and, optionally, S)
* -> CEA-CBUDGET     cost-effective analysis limited by total CO2-budget
* -> CEA-TATM        cost-effective analysis to limit TATM
*


#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================


##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'


# ==== BAU-NO-IMPACTS =======

* Multiple possible equivalent namings
$ifi '%policy%'=='bau' $set bau_no_impacts
$ifi '%policy%'=='bau-no-impacts' $set bau_no_impacts
$ifi '%policy%'=='base' $set bau_no_impacts
$ifthen.pol set bau_no_impacts
* No mitigation
* No impacts
$setglobal impact "off"
$ifi not %impact%=="off" $abort 'USER ERROR: [impact] must be -off- for BAU-NO-IMPACTS policy!'
* Optimization run_mode preferred (but also simulation is ok)
$setglobal run_mode  'optimization'


# ==== BAU-IMPACTS =======

$elseif.pol '%policy%'=='bau-impacts'
* Simulation run_mode
$setglobal run_mode  'simulation'
$ifi not %run_mode%=='simulation' $abort 'USER ERROR: [run_mode] must be -simulation- for BAU-IMPACTS policy!'


# ==== CBA =======

$elseif.pol '%policy%'=='cba'
* Optimization run_mode
$setglobal run_mode  'optimization'
$ifi not %run_mode%=='optimization' $abort 'USER ERROR: [run_mode] must be -optimization- for CBA policy!'


# ==== SIMULATION ======

$elseif.pol '%policy%'=='sim'
* Simulation run_mode
$setglobal run_mode  'simulation'
$ifi not %run_mode%=='simulation' $abort 'USER ERROR: [run_mode] must be -simulation- for SIMULATION policy!'
* Set MIU trajectory to be imported
$setglobal sim_miu_gdx "insert_path_and_filename"
$ifi not exist '%sim_miu_gdx%' $abort "File -%sim_miu_gdx%- not found!  Please set [sim_miu_gdx] flag with -path/filename.gdx- (needed for MIU trajectory)!"
* Set Savings trajectory to be imported (optional: fixed trajectory as default)
$setglobal sim_savings_gdx ""


# ==== CBUDGET =======

$elseif.pol '%policy%'=='cea-cbudget'
* cumulated co2 limit
$setglobal cbudget 650
* Optimization run_mode
$setglobal run_mode  'optimization'
$ifi not %run_mode%=='optimization' $abort 'USER ERROR: [run_mode] must be -optimization- for CBUDGET policy!'
* No impacts
$setglobal impact "off"
$ifi not %impact%=="off" $abort 'USER ERROR: [impact] must be -off- for CBUDGET policy!'
* Cooperation mode 
$ifi not %cooperation%=='coop' $abort 'USER ERROR: [cooperation] must be -coop- for CBUDGET policy!'


# ==== CEA-TATM =======

$elseif.pol '%policy%'=='cea-tatm'
* limit TATM to %tatm_limit% Celsius degrees above preindustrial
$setglobal tatm_limit 2
* Overshoot option: | yes | no |
$setglobal overshoot "yes"
* Optimization run_mode
$setglobal run_mode  'optimization'
$ifi not %run_mode%=='optimization' $abort 'USER ERROR: [run_mode] must be -optimization- for CEA-TATM policy!'
* No impacts
$setglobal impact "off"
$ifi not %impact%=="off" $abort 'USER ERROR: [impact] must be -off- for CEA-TATM policy!'
* Cooperation mode
* Cooperation mode 
$ifi not %cooperation%=='coop' $abort 'USER ERROR: [cooperation] must be -coop- for CBUDGET policy!'



$endif.pol


## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'


## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'


# ==== SIMULATION ======

$ifthen.pol '%policy%'=='sim'

PARAMETERS 
    sim_miu(t,n) 
    sim_savings(t,n) 
;
* Load a MIU trajectory from a give GDX 
$gdxin '%sim_miu_gdx%'
$load sim_miu=MIU.l
$gdxin
* Load external S trajectories if flag refers to an existing file 
$iftheni.sav exist '%sim_savings_gdx%'
$gdxin '%sim_savings_gdx%'
$load sim_savings=S.l
$gdxin
$endif.sav



$endif.pol


##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'


# ==== SIMULATION ======

$ifthen.pol '%policy%'=='sim'
* If no external file is set for Savings trajectories use standard fixed-savings ones
$iftheni.sav not exist '%sim_savings_gdx%'
sim_savings(t,n) = fixed_savings(t,n)  ;
$endif.sav

$endif.pol


##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'


##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'


# ==== BAU-NO-IMPACTS =======

$ifthen.pol set bau_no_impacts
* No mitigation
 MIU.l(t,n) = 0; 
 MIU.fx(t,n) = 0; # Fixing mitigation variable in 2015-2300 period


# ==== BAU-IMPACTS =======

$elseif.pol '%policy%'=='bau-impacts'
* No mitigation
 MIU.l(t,n) = 0; 
 MIU.fx(t,n) = 0; # Fixing mitigation variable in 2015-2300 period


$endif.pol



#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================


##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'


# ==== CEA-CBUDGET =======

$if.pol '%policy%'=='cea-cbudget' eq_carbon_budget


# ==== CEA-TATM =======

$if.pol '%policy%'=='cea-tatm' eq_tatm_limit


##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'


# ==== CBUDGET =======

$ifthen.pol '%policy%'=='cea-cbudget' 
* add carbon budget equation
eq_carbon_budget..   sum((t,n)$(year(t) le 2100), E(t,n) ) * tstep  =L=  %cbudget%;


# ==== CEA-TATM =======

$elseif.pol '%policy%'=='cea-tatm'
$ifthen.over %overshoot%=="yes"
* limit GMT only from 2100 an beyond
 eq_tatm_limit(t)$(year(t) ge 2100)..   TATM(t)  =L=  %tatm_limit% ;
$else.over
* No overshoot, always below limit
 eq_tatm_limit(t)..   TATM(t)  =L=  %tatm_limit% ;
$endif.over


$endif.pol


#=========================================================================
*   ///////////////////////     SIMULATION    ///////////////////////
#=========================================================================


##  SIMULATION SETUP
#_________________________________________________________________________
$elseif.ph %phase%=='set_simulation'


# ==== BAU-IMPACTS =======

$ifthen.pol '%policy%'=='bau-impacts'
* Check impacts are active
$if set no_impacts $abort 'USER ERROR: flag [no_impacts] must be deactivated for BAU-IMPACTS policy!'
* Set no-mitigation choice 
MIU.l(t,n) = 0;


# ==== SIMULATION ======

$elseif.pol '%policy%'=='sim'
* Set mitigation trajectory
MIU.fx(t,n) = sim_miu(t,n)  ;
* Set savings trajectory
S.fx(t,n) = sim_savings(t,n)  ;



$endif.pol



#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================


##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'


# ==== SIMULATION ======

$ifthen.pol '%policy%'=='sim'
 sim_miu
 sim_savings 


$endif.pol




$endif.ph
