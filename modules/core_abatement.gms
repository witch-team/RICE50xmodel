* MODULE MACC
*
* Marginal abatement cost curves.
* Comes after a rather elaborated fitting process based on EnerData data,
* and therefore deserves a self-standing module.
*____________
* REFERENCES
* - EnerData(c) 2017 MACCs
* - DICE 2016
*
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================

##  CONF
#_________________________________________________________________________
* Definition of the global flags and settings specific to the module
$ifthen.ph %phase%=='conf'

# BACKSTOP DATA 
* (DICE2016 as default)
$setglobal pback      550
$setglobal gback      0.025
$setglobal expcost2   2.8
* time starting transition to pbackstop
$setglobal tstart_pbtransition   7
* time of full-convergence to backstop curve [18,38]
$setglobal tend_pbtransition   28
* parameter influencing logistic transition speed (0,2]
$setglobal klogistic 0.25
#........................
# Some reference times:
# 2020 -> t = 2
# 2040 -> t = 6
# 2050 -> t = 8
# 2100 -> t = 18
# 2125 -> t = 23
# 2150 -> t = 28
# 2200 -> t = 38
# 2250 -> t = 48
# 2300 -> t = 58
#.......................

$setglobal macc_costs prob50 #options: ssps, prob25, prob33, prob50, prob66, prob75, enerdata

## SETS
#_________________________________________________________________________
* In the phase SETS you should declare all your sets, or add to the existing
* sets the element that you need.
$elseif.ph %phase%=='sets'

SET
sector  'EnerData sectors'   /
    "Electricity"
    "Other_energy_transformation"
    "Total_buildings_agriculture"
    "Total_industry_processes"
    "Total_industry_fuelcombustion"
    "Total_CO2"
    "Total_transport" /;

SET quant 'Quantiles of the AR6 distribution'  / "prob25", "prob33", "prob50", "prob66", "prob75" /;

# coefficients for polinomial curves
SET coef  'Coefficients for MACCs'  / c0*c4 /;

SET coefact(coef,*)  'Polynomial shape for each relevant species/sector/cdr option'  / c1.co2, c4.co2, c1.ch4, c4.ch4, c1.n2o, c4.n2o /;

## INCLUDE DATA
#_________________________________________________________________________
* In the phase INCLUDE_DATA you should declare and include all exogenous parameters.
* You can also modify the data loaded in data.gms
* Best practice : - create a .gdx containing those and to loading it
*                 - this is the only phase where we should have numbers...
$elseif.ph %phase%=='include_data'

PARAMETER coefn(coef)  'Number of coefficients for MACC fitting' / c0 0, c1 1, c2 2, c3 3, c4 4 /;
PARAMETER convy_ghg(ghg) 'Conversion factor for abatement cost (must give tril dollar/yr)' / co2 1e-3, ch4 1e-6, n2o 1e-6 /; 
PARAMETER cprice_max(t,n,ghg) 'Maximum carbon price for each GHG';

##  PARAMETERS HARDCODED OR ASSIGNED ------------------- 

PARAMETERS
* DICE backstop
    expcost2  "Exponent of control cost function"                / %expcost2% / #DICE: 2.8
    pback     "Cost of backstop 2010$ per tCO2 in 2015"          / %pback%    / #DICE2013: 344     #DICE2016: 550
    gback     "Initial cost decline backstop cost per period"    / %gback%    / #DICE2013: 0.05    #DICE2016: 0.025
;

##  PARAMETERS LOADED ----------------------------------

##  PARAMETERS EVALUATED -------------------------------

PARAMETERS
* Backstop
    pbacktime(t)            "Backstop price"
    cost1(t,n)              "Adjusted cost for Backstop"
* MACC transition
    mx(t,n,ghg)                 "Enerdata MACC multiplier calibated on diagnostics"
    alpha(t)                "Transition to backstop coefficient"
    MXpback(t,n,ghg)            "MX to obtain full pbackstop"
    mx_correction_factor(sector,quant,t,n)  "MX starting value from AR6 correction factor"
    MXstart(t,n,ghg)            "MX value from which to start"
    MXdiff(t,n,ghg)             "MX transition gap"
    macc_coef(t,n,*,coef) "final coefficients for relevant entities"
;

* CO2 MAC-Curves fitting parameters
PARAMETER  macc_ed_coef(sector,*,t,n)  'EnerData CO2 MACC -fit with 1-2-4 power fit for given years (2025-2050)'  ;
$gdxin '%datapath%data_mod_macc'
$load  macc_ed_coef = macc_ed_coef
$gdxin

* CO2 MAC-Curves fitting parameters
PARAMETER  macc_pbl_coef(t,n,ghg,*)  'EnerData CO2 MACC -fit with 1-2-4 power fit for given years (2025-2050)'  ;
$gdxin '%datapath%data_mod_nonco2'
$load  macc_pbl_coef = macc_ghg_coefficients
$gdxin

* CO2 MAC-Curves fitting parameters
PARAMETER  maxmiu_pbl(t,n,ghg)  'EnerData CO2 MACC -fit with 1-2-4 power fit for given years (2025-2050)'  ;
$gdxin '%datapath%data_mod_nonco2'
$load  maxmiu_pbl = max_miu
$gdxin
maxmiu_pbl(t,n,'co2') = 1;

* Correction multiplier calibrated
PARAMETER  mx_correction_factor(sector,quant,t,n)  "Correction multiplier calibrated over enerdata times"  ;
$gdxin '%datapath%data_mod_macc'
$load  mx_correction_factor
$gdxin


##  COMPUTE DATA
#_________________________________________________________________________
* In the phase COMPUTE_DATA you should declare and compute all the parameters
* that depend on the data loaded in the previous phase.
$elseif.ph %phase%=='compute_data'

* map coefficients
macc_coef(t,n,ghg,'c1') = macc_pbl_coef(t,n,ghg,'c1');
macc_coef(t,n,ghg,'c4') = macc_pbl_coef(t,n,ghg,'c4');

macc_coef(t,n,'co2','c1') =  macc_ed_coef('Total_CO2','a',t,n);
macc_coef(t,n,'co2','c4') =  macc_ed_coef('Total_CO2','d',t,n);

macc_coef(t,n,ghg,coef)$(macc_coef(t,n,ghg,coef) < 0) = 0;

#  PBackstop curve -------------------------------------
pbacktime(t)  =  pback*(1-gback)**(tperiod(t)-1);
cost1(t,n)    =  pbacktime(t)*sigma(t,n,'co2')/expcost2/1000;



# TRANSITION TO BACKSTOP -------------------------------
* It is directly related to settings from conf phase.
* Shape, slope and convergence time are all taken into account here

## logistic pbtransition
scalar x0 ;
x0 = %tstart_pbtransition% + ((%tend_pbtransition%-%tstart_pbtransition%)/2)  ;
alpha(t) = 1/(1+exp(-%klogistic%*(tperiod(t)-x0)));


# BACKSTOP MULTIPLIER ----------------------------------

# NOTE .....................................................................
# Following evaluations give answer to the question:
# Which multiplier would make my full-abatement MACcurve (MIU=1) coincide
# to the previously-evaluated pbackstop (in every time-step)?
#...........................................................................

# Mx = back_end / (a bau + b bau^4)  -->  MIU = 1
MXpback(t,n,ghg)  =  pbacktime(t)
                / ( sum(coef$coefact(coef,ghg), macc_coef(t,n,ghg,coef)*power(maxmiu_pbl(t,n,ghg),(coefn(coef)))) / emi_gwp(ghg) );


# NOTE ........................................................................
# Before transition the original multiplier applies,
# then a smooth  transition to the pback-curve is performed,
# by progressively reducing the distance (according to the shaping alpha-param)
#...............................................................................

MXstart(t,n,ghg) = 1;
$ifthen.macc %macc_costs%=='enerdata'
MXstart(t,n,'co2') = 1;
$elseif.macc %macc_costs%=='ssps'

$ifthen.ssp %baseline%=='ssp1'
MXstart(t,n,'co2') =  mx_correction_factor('Total_CO2','prob33',t,n);
$elseif.ssp %baseline%=='ssp2'
MXstart(t,n,'co2') =  mx_correction_factor('Total_CO2','prob50',t,n);
$elseif.ssp %baseline%=='ssp3'
MXstart(t,n,'co2') =  mx_correction_factor('Total_CO2','prob75',t,n);
$elseif.ssp %baseline%=='ssp4'
MXstart(t,n,'co2')$((ykali('2',n)/pop('2',n)*1e6*113.647/104.691) le 13205) =  mx_correction_factor('Total_CO2','prob66',t,n);
MXstart(t,n,'co2')$((ykali('2',n)/pop('2',n)*1e6*113.647/104.691) gt 13205) =  mx_correction_factor('Total_CO2','prob33',t,n);
$elseif.ssp %baseline%=='ssp5'
MXstart(t,n,'co2') =  mx_correction_factor('Total_CO2','prob66',t,n);
$endif.ssp 

$else.macc
MXstart(t,n,'co2') =  mx_correction_factor('Total_CO2','%macc_costs%',t,n);
$endif.macc

MXdiff(t,n,ghg)  =  max(MXstart(t,n,ghg)  - MXpback(t,n,ghg) ,0) ;

* Final coefficient values:
mx(t,n,ghg)      =  MXstart(t,n,ghg)  -  alpha(t) * MXdiff(t,n,ghg);

* update macc coefficients for each sector
macc_coef(t,n,ghg,coef) = mx(t,n,ghg) * macc_coef(t,n,ghg,coef);

##  DECLARE VARIABLES
#_________________________________________________________________________
* In the phase VARS, you can DECLARE new variables for your module.
* Remember that by modifying sets, you already have some variables for free.
$elseif.ph %phase%=='declare_vars'

VARIABLES
   ABATECOST(t,n,ghg)    'Cost of emissions reductions [Trill 2005 USD / year]'
   MAC(t,n,ghg)       'Carbon Price [ 2005 USD /tCO2 ]'
;

POSITIVE VARIABLES ABATECOST, MAC;

# VARIABLES STARTING LEVELS ----------------------------
ABATECOST.l(t,n,ghg) = 0 ;
   MAC.l(t,n,ghg) = 0 ;

##  COMPUTE VARIABLES
#_________________________________________________________________________
* In the phase COMPUTE_VARS, you fix starting points and bounds.
$elseif.ph %phase%=='compute_vars'

MIU.up(t,n,ghg)$(not tmiufix(t) and not sameas(ghg,'co2')) = maxmiu_pbl(t,n,ghg);

#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================



##  EQUATION LIST
#_________________________________________________________________________
* List of equations
* One per line.
$elseif.ph %phase%=='eql'

    eq_abatecost      # Cost of emissions reductions equation'
    eq_cprice         # Carbon price equation'


##  EQUATIONS
#_________________________________________________________________________
* In the phase EQS, you can include new equations to the model.
* The equations are always included.
* Best practice : - condition your equation to be able to do a run with t_fix(t)
$elseif.ph %phase%=='eqs'

eq_abatecost(t,n,ghg)$(reg(n)).. ABATECOST(t,n,ghg)  =E=  emi_bau(t,n,ghg) * convy_ghg(ghg) *
                    sum(coef$coefact(coef,ghg), macc_coef(t,n,ghg,coef)*power(MIU(t,n,ghg),(coefn(coef)+1))/(coefn(coef)+1)); # back to trillion dollars

eq_cprice(t,n,ghg)$(reg(n)).. MAC(t,n,ghg)  =E=  sum(coef$coefact(coef,ghg), macc_coef(t,n,ghg,coef)*power(MIU(t,n,ghg),(coefn(coef))));


#_________________________________________________________________________
$elseif.ph %phase%=='before_solve'

cprice_max(t,n,ghg) = sum(coef$coefact(coef,ghg), macc_coef(t,n,ghg,coef)*power(MIU.up(t,n,ghg),(coefn(coef)))); 

#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  GDX ITEMS
#_________________________________________________________________________
* List the items to be kept in the final gdx
$elseif.ph %phase%=='gdx_items'


# Parameters -----------------------------
pback
gback
expcost2
pbacktime
mx
mx_correction_factor
macc_ed_coef
cost1
alpha
macc_coef
cprice_max
maxmiu_pbl

# Variables ------------------------------

ABATECOST
MAC


$endif.ph 
