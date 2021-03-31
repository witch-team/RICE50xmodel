* EMISSIONS MODULE
*
* Where Regions emissions are determined.
*____________
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================
#
## CONF
#_________________________________________________________________________
* Definition of the global flags and settings specific to the module
$ifthen.ph %phase%=='conf'

* MIU linear-transition time horizon from 1 to maximum upperbound
$setglobal t_min_miu 9
$setglobal t_max_miu 38

* MIU maximum reacheable upperbound
$setglobal max_miuup 1.2


## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

SET ere 'Emissions-related entities'/
    co2
    co2ffi # Fossil-fuel and Industry CO2
    nip    # net import of permits
    sav    # saved permits
    kghg   # Kyoto greenhouse gases
    ch4
    n2o
    sf6
    #hfc
    #pfc
/;
ALIAS(ere,eere);

SET map_e(ere,eere) 'Relationships between Sectoral Emissions' /
    co2.co2ffi
/;

SET ghg(ere) 'Green-House Gases'
/
    co2
    ch4
    n2o
    #sf6
    #hfc
    #pfc
/;

SET oghg(ghg) 'Other GHGs'
/
    ch4
    n2o
    #sf6
    #hfc
    #pfc
/;

## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

# .......  PARAMETERS HARDCODED OR ASSIGNED  .......
PARAMETERS
* Cumulative emissions startings
   cumeind0   'Starting value of cumulative emissions from industry [GtC]'                 / 400   /  # DICE2016
   cumetree0  'Starting value of cumulative emissions from land use deforestation [GtC]'   / 100   /
* Availability of fossil fuels
   fosslim    'Maximum cumulative extraction fossil fuels (GtC)' / 6000 /
* MIU rate controls
   miu0       'Initial emissions control rate for base calib_emissions'    / 0 / 
   min_miu     'upper bound for control rate MIU at t_min_miu'       / 1.00 / # best compromise
   t_min_miu    'time t when min_miu value can be reached'           / %t_min_miu%    / # 7 - 2045
   max_miu     'upper bound for control rate MIU from t_max_miu'     / %max_miuup%  / # the old DICE limmiu
   t_max_miu    'time t when max_miu value can be reached'           / %t_max_miu%  / # 28 - 2150
;

##  PARAMETERS EVALUATED ----------
PARAMETERS
    world_e(t)
;

SCALAR
* Conversion coefficients
   CtoCO2        'conversion factor from Carbon to CO2'
   CO2toC        'conversion factor from CO2 to Carbon'
;

## BAU EMISSIONS AND CARBON INTENSITY 
PARAMETERS
    ssp_emi_bau(ssp,t,n)   'SSP-Decline rate of decarbonization according to different scenarios (per period)'
    emi_bau_co2(t,n)       "Baseline regional CO2 FFI emissions [GtCO2]"
    sigma(t,n)                  'Decline rate of decarbonization (per period)'
    sig0(n)                     'Carbon intensity at starting time [kgCO2 per output 2005 USD]'
;

$gdxin '%datapath%data_baseline_emissions_calibrated.gdx'
$load   ssp_emi_bau=emi_bau_calibrated
$gdxin
* Configuration settings determine imported scenario
emi_bau_co2(t,n) = ssp_emi_bau('%baseline%',t,n)  ;






##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

CtoCO2 = 44 / 12 ;
CO2toC = 12 / 44 ;

* Baseline emissions
sigma(t,n) = emi_bau_co2(t,n)/ykali(t,n) ;
sig0(n)    = sigma('1',n)    ;

* Initial emissions
e0(n) = q0(n) * sig0(n);


##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

## EMISSIONS CO2 ----------
VARIABLES

    E(t,n)          'Total CO2 emissions  [GtCO2/year]'
    EIND(t,n)       'Industrial emissions [GtCO2/year]'

    CCAEIND(t)      'Cumulative Industrial Carbon Emissions [GTC]'
    CCAETOT(t)      'Cumulative Carbon Emissions [GTC]'
    CUMETREE(t)     'Cumulative from land [GtC]'

    CCO2EIND(t)     'Cumulative Industrial CO2 Emissions [GtCO2]'
    CCO2ETOT(t)     'Cumulative CO2 Emissions [GtCO2]'

    MIU(t,n)        'Emission control rate GHGs'
    ABATEDEMI(t,n)  'Abated Emissions [GtCO2/year]'
;
POSITIVE VARIABLES  ABATEDEMI, MIU ;

# VARIABLES STARTING LEVELS 
* to help convergence if no startboost is loaded
     EIND.l(t,n) = sigma(t,n)*ykali(t,n) ;
        E.l(t,n) = EIND.l(t,n) + eland_bau('uniform',t,n) ;
      MIU.l(t,n) = 0 ; 
ABATEDEMI.l(t,n) = 0 ;



##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

##  EMISSIONS CO2 ----------
* Industrial emissions starting point
EIND.fx(tfirst,n) = e0(n) ;
* Resource limit for fossils emissions
CCAEIND.up(t) = fosslim ;
* Initial cumulated conditions
CCAEIND.FX(tfirst)  = cumeind0    ;
CUMETREE.fx(tfirst) = cumetree0   ;
CCAETOT.FX(tfirst)  = cumeind0 + cumetree0 ;
* CO2-budget starts empty
CCO2EIND.FX(tfirst) = 0 ;
CCO2ETOT.FX(tfirst) = 0 ;


##  CO2 MITIGATION UPPER BOUND SHAPE ----------
loop(t,
# Before transition
MIU.up(t,n)$(t.val lt t_min_miu) = min_miu;
# Transition to negative: linear transition from min_miu to max_miu between t_min_miu and t_max_miu
MIU.up(t,n)$(t.val ge t_min_miu) = min_miu + (max_miu - min_miu) * (t.val - t_min_miu)/(t_max_miu - t_min_miu);
# After transition
MIU.up(t,n)$(t.val gt t_max_miu) = max_miu;
);
MIU.up(t,n)$(t.pos le 2) = 0.03 ; #setting 2020 upperbound as in DICE2016



#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'

##  CO2 EMISSION EQUATIONS ----------
    eq_e                # Emissions equation'
    eq_eind             # Industrial emissions equation'
    eq_ccaeind          # Cumulative carbon emissions equation'
    eq_ccaetot
    eq_cco2eind         # Cumulative CO2 emissions equation (from now on)'
    eq_cco2etot
    eq_cumetree         # Cumulated land-use emissions
    eq_abatedemi        # Abated Emissions according to decision'
    eq_miuinertiaplus   # Inertia in CO2 Control Rate decreasing'
    eq_miuinertiaminus  # Inertia in CO2 Control Rate increasing'


##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

##  EMISSIONS CO2 ----------
* Industrial emissions
 eq_eind(t,n)$(reg(n))..   EIND(t,n)  =E=  sigma(t,n) * YGROSS(t,n) * (1-(MIU(t,n)))  ;

* All emissions
 eq_e(t,n)$(reg(n))..   E(t,n)  =E=  EIND(t,n) + ELAND(t,n)  ;

* Industrial cumulated emissions in Carbon
 eq_ccaeind(t+1)..   CCAEIND(t+1)  =E=  CCAEIND(t) # All industrial emi per period in Carbon
                                   +  (( sum(n$reg(n), EIND(t,n)) + sum(n$(not reg(n)), EIND.l(t,n)) ) * tstep * CO2toC ) ; #Carbon

* Total cumulated emissions in Carbon
 eq_ccaetot(t+1)..   CCAETOT(t+1)  =E=  CCAETOT(t) # All emi (industrial + land) per period in Carbon
                                   +  (( sum(n$reg(n), E(t,n)) + sum(n$(not reg(n)), E.l(t,n)) ) * tstep * CO2toC )  ; #Carbon

* Land Use cumulated emissions in Carbon
 eq_cumetree(t+1)..   CUMETREE(t+1) =E=  CUMETREE(t) # Land Use emi per period in Carbon
                                    + (( sum(n$reg(n), ELAND(t,n))    + sum(n$(not reg(n)), ELAND.l(t,n)) ) * tstep * CO2toC)  ; #Carbon

* Industrial cumulated emissions in CO2
 eq_cco2eind(t+1)..   CCO2EIND(t+1)   =E=  CCO2EIND(t) # All industrial emi per period
                                      +   (( sum(n$reg(n), EIND(t,n))    + sum(n$(not reg(n)), EIND.l(t,n)) )  * tstep )  ; #CO2

* Total cumulated emissions in CO2
 eq_cco2etot(t+1)..   CCO2ETOT(t+1)   =E=  CCO2ETOT(t) # All emi (industrial + land) per period
                                      +   (( sum(n$reg(n), E(t,n))    + sum(n$(not reg(n)), E.l(t,n)) )    * tstep )  ; #CO2

* Emissions abated
 eq_abatedemi(t,n)$(reg(n))..   ABATEDEMI(t,n)  =E=  MIU(t,n) * sigma(t,n) * YGROSS(t,n)  ;



##  MITIGATION CO2 INERTIA ----------
* Inertia in increasing
eq_miuinertiaminus(t+1,n)$(map_nt and (t.val gt 1))..   MIU(t+1,n)  =L=  MIU(t,n) + 0.20 ;

* Inertia in decreasing
eq_miuinertiaplus(t+1,n)$(map_nt  and (t.val gt 1))..   MIU(t+1,n)  =G=  MIU(t,n) - 0.20 ;



##  FIX VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='fix_variables'

tfixvar(MIU,'(t,n)')

##  BEFORE SOLVE
#_________________________________________________________________________
$elseif.ph %phase%=='before_solve'

loop((t,n)$(ctax(t,n) and (MIU.lo(t,n) lt MIU.up(t,n))),
    MIU.lo(t,n) = max(0, min(1 - (0.90*(YNET.l(t,n)-ABATECOST.l(t,n))/ctax(t,n) + EIND.l(t,n))/(sigma(t,n)*YGROSS.l(t,n)), MIU.up(t,n)));
    MIU.l(t,n) = (MIU.lo(t,n) + MIU.up(t,n))/2;
    EIND.l(t,n) = sigma(t,n)*YGROSS.l(t,n)*(1-MIU.l(t,n));
    ABATEDEMI.l(t,n) = sigma(t,n)*YGROSS.l(t,n)*MIU.l(t,n);
);


##  PROBLEMATIC REGIONS
#_________________________________________________________________________
$elseif.ph %phase%=='problematic_regions'


##  AFTER SOLVE
#_________________________________________________________________________
$elseif.ph %phase%=='after_solve'

world_e(t)            = sum(n$(nsolve(n)),  E.l(t,n)  );

display MIU.l, CCAEIND.l;

#=========================================================================
*   ///////////////////////     SIMULATION    ///////////////////////
#=========================================================================

##  SIMULATION SETUP
#_________________________________________________________________________
$elseif.ph %phase%=='set_simulation'



##  SIMULATION HALFLOOP 1
#_________________________________________________________________________
$elseif.ph %phase%=='simulate_1'

#  CO2 EMISSIONS ---------------------------------------

* Industrial emissions
EIND.l(t,n)  =  sigma(t,n) * YGROSS.l(t,n) * (1-(MIU.l(t,n))) ; #CO2

* All emissions
E.l(t,n)  =  EIND.l(t,n) + ELAND.l(t,n) ; #CO2

* Industrial cumulated emissions in Carbon
CCAEIND.l(t+1)  =  CCAEIND.l(t)  + ( sum(n, EIND.l(t,n)) * tstep * CO2toC ) ; #Carbon

* Total cumulated emissions in Carbon
CCAETOT.l(t+1)  =  CCAETOT.l(t)  + ( sum(n, E.l(t,n)) * tstep * CO2toC ) ; #Carbon

* Land Use cumulated emissions in Carbon
CUMETREE.l(t+1) =  CUMETREE.l(t) + (sum(n, ELAND.l(t,n)) * tstep * CO2toC) ; #Carbon

* Industrial cumulated emissions in CO2
CCO2EIND.l(t+1)  =  CCO2EIND.l(t) + ( sum(n, EIND.l(t,n))  * tstep ) ; #CO2

* Total cumulated emissions in CO2
CCO2ETOT.l(t+1)  =  CCO2ETOT.l(t) + ( sum(n, E.l(t,n))  * tstep ) ; #CO2

* Emissions abated
ABATEDEMI.l(t,n)  =  MIU.l(t,n) * sigma(t,n) * YGROSS.l(t,n)   ; #CO2



##  SIMULATION HALFLOOP 2
#_________________________________________________________________________
$elseif.ph %phase%=='simulate_2'


##  AFTER SIMULATION
#_________________________________________________________________________
$elseif.ph %phase%=='after_simulation'


#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

# Sets (excl. aliases) ---------------------------------
ghg

# Parameters -------------------------------------------
fosslim
max_miu
t_max_miu
t_min_miu
world_e
CtoCO2
CO2toC
sigma
emi_bau_co2

# Variables --------------------------------------------
E
EIND
MIU
ABATEDEMI
CCO2EIND
CCO2ETOT

# Equations (only for OPT. run_mode) -------------------
$if %run_mode%=='optimization' eq_e

$endif.ph
