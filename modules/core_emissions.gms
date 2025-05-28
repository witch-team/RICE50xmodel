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
$setglobal t_min_miu 8 #2050
$setglobal t_max_miu 12 #2070

* MIU maximum reacheable upperbound
$setglobal max_miuup 1.2

* Carbon-intensity transition curve
* | linear_pure | linear_soft | sigmoid_HHs | sigmoid_Hs | sigmoid_Ms | sigmoid_Ls | sigmoid_LLs |
$setglobal sig_trns_type 'sigmoid_Ls'

* Time of full-convergence to dice-ref carbon-intensity curve
* | 28 | 38 | 48 | 58 |
$setglobal sig_trns_end  '38'

* SSP-n hypothesis on dice-reference curve for carbon-intensity
* |original | discounted |
$setglobal sig_dice_ref_curve 'discounted'

* Maximum change for inertia in MIU per time step
* based on AR6 ENGAGE db, 3.4 p.p. change per year is the 95th percentila, or 17 p.p. in 5 years
$setglobal miuinertia 0.034 # no inertia: 0.24 , implying 1.2 per 5 years (=no inertia), or 0.034

## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

SET ghg 'Green-House Gases' / "co2","ch4","n2o" /;

SET v /'CH4','N2O'/;
set vcheck(v) /'CH4','N2O'/;

## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

# .......  PARAMETERS HARDCODED OR ASSIGNED  .......
PARAMETERS
* Availability of fossil fuels
   fosslim    'Maximum cumulative extraction fossil fuels (GtC)' / 6000 /
   miu_inertia(ghg) 'Inertia in the control rate MIU per year'    # best compromise
;

##  PARAMETERS EVALUATED ----------

SCALAR
* Conversion coefficients
   CtoCO2        'conversion factor from Carbon to CO2'
   CO2toC        'conversion factor from CO2 to Carbon'
;

## BAU EMISSIONS AND CARBON INTENSITY 
PARAMETERS
    ssp_sigma(ssp,t,n,ghg)   'SSP-Decline rate of decarbonization according to different scenarios (per period)'
    sigma(t,n,ghg)                  'Carbon intensity of GDP [kgGHG per USD(2005)]'
    emi_bau(t,n,ghg)            'BAU emissions of CO2 [GtCO2/year]'
    convq_ghg(ghg)               'Conversion factor for GHG emissions'
    sig0(n)                     'Carbon intensity at starting time [kgCO2 per output 2005 USD]'
;

$gdxin '%datapath%data_baseline.gdx'
$load   ssp_sigma=ssp_ci
$gdxin


##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

* Configuration settings determine imported scenario
sigma(t,n,ghg) = ssp_sigma('%baseline%',t,n,ghg);

* Mt for ch4 and n2o, Gt for co2
convq_ghg('co2') = 1;
convq_ghg('ch4') = 1e3;
convq_ghg('n2o') = 1e3;

* set miu inertia
miu_inertia(ghg) = %miuinertia%;

CtoCO2 = 44 / 12 ;
CO2toC = 12 / 44 ;

* Baseline emissions
emi_bau(t,n,ghg) = convq_ghg(ghg) *sigma(t,n,ghg) * ykali(t,n) ;

$if %baseline%=='ssp5' fosslim=10000;

$if set noneg max_miu=1;

*following challenges to mitigation criterium
$if %residual_emissions%=='low' max_miu=1; 
$if %residual_emissions%=='medium' max_miu=0.975; 
$if %residual_emissions%=='high' max_miu=0.925; 

##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

## EMISSIONS CO2 ----------
VARIABLES

    E(t,n,ghg)          'Total GHG emissions  [GtGHG/year or MtGHG/year]'
    EIND(t,n,ghg)       'Industrial GHG emissions [GtGHG/year or MtGHG/year]'
    MIU(t,n,ghg)        'Emission control rate GHGs'
    ABATEDEMI(t,n,ghg)  'Abated Emissions [GtGHG/year or MtGHG/year]'
;

POSITIVE VARIABLES  ABATEDEMI, MIU ;

# VARIABLES STARTING LEVELS 
     EIND.l(t,n,ghg) = convq_ghg(ghg) * sigma(t,n,ghg)*ykali(t,n) ;
        E.l(t,n,ghg) = EIND.l(t,n,ghg) + eland_bau(t,n,'%luscenario%')$sameas(ghg,'co2');
      MIU.l(t,n,ghg) = 0 ; 
ABATEDEMI.l(t,n,ghg) = 0 ;

##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

##  EMISSIONS CO2 ----------
* Industrial emissions starting point
EIND.fx(tfirst,n,ghg) = sigma(tfirst,n,ghg) * convq_ghg(ghg) * ykali(tfirst,n);

# negative emissions from mod_cdr
MIU.up(t,n,ghg) = 1;

#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'

##  CO2 EMISSION EQUATIONS ----------
    eq_e                # Emissions equation'
    eq_eind             # Industrial emissions equation'
    eq_abatedemi        # Abated Emissions according to decision'
    eq_miuinertiaplus   # Inertia in CO2 Control Rate decreasing'
    eq_miuinertiaminus  # Inertia in CO2 Control Rate increasing'

##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

##  EMISSIONS CO2 ----------
* Industrial emissions
 eq_eind(t,n,ghg)$(reg(n))..   EIND(t,n,ghg)  =E=  sigma(t,n,ghg) * convq_ghg(ghg) * YGROSS(t,n) * (1-MIU(t,n,ghg))  ;

* All emissions
 eq_e(t,n,ghg)$(reg(n))..   E(t,n,ghg)  =E=  EIND(t,n,ghg) + ELAND(t,n)$(sameas(ghg,'co2')) 
$if set mod_dac                      - E_NEG(t,n)$(sameas(ghg,'co2')) 
;

* Emissions abated
 eq_abatedemi(t,n,ghg)$(reg(n))..   ABATEDEMI(t,n,ghg)  =E=  MIU(t,n,ghg) * sigma(t,n,ghg) * convq_ghg(ghg) * YGROSS(t,n)  ;

##  MITIGATION CO2 INERTIA ----------
* Inertia in increasing
eq_miuinertiaplus(t,tp1,n,ghg)$(reg(n) and (tperiod(t) gt 1) and pre(t,tp1) and not tmiufix(tp1))..   MIU(tp1,n,ghg)  =L=  MIU(t,n,ghg) + miu_inertia(ghg)*tstep;

* Inertia in decreasing
eq_miuinertiaminus(t,tp1,n,ghg)$(reg(n) and (tperiod(t) gt 1) and pre(t,tp1) and not tmiufix(tp1))..   MIU(tp1,n,ghg)  =G=  MIU(t,n,ghg) - miu_inertia(ghg)*tstep;

##  FIX VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='fix_variables'

tfixvar(MIU,'(t,n)')

##  BEFORE SOLVE
#_________________________________________________________________________
$elseif.ph %phase%=='before_solve'


##  AFTER SOLVE
#_________________________________________________________________________
$elseif.ph %phase%=='after_solve'

viter(iter,'MIU',t,n)$nsolve(n) = MIU.l(t,n,'co2');  # Keep track of last mitigation values
viter(iter,'CH4',t,n)$nsolve(n) = MIU.l(t,n,'ch4');  # Keep track of last mitigation values
viter(iter,'N2O',t,n)$nsolve(n) = MIU.l(t,n,'n2o');  # Keep track of last mitigation values

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
CtoCO2
CO2toC
sigma
emi_bau

# Variables --------------------------------------------
E
EIND
MIU
ABATEDEMI

# Equations -------------------
eq_e

$endif.ph
