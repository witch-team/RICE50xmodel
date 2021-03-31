* MODULE MACC
*
* Marginal abatement cost curves.
* Comes after a rather elaborated fitting process based on EnerData data,
* and therefore deserves a self-standing module.
*____________
* REFERENCES
* - EnerData(c) 2017 MACCs
*

#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================

##  CONF
#_________________________________________________________________________
* Definition of the global flags and settings specific to the module
$ifthen.ph %phase%=='conf'

##  SETTING CONF ---------------------------------------
* These can be changed by the user to explore alternative scenarios



##  CALIBRATED CONF ------------------------------------
* These settings shouldn't be changed


# CORRECTION MULTIPLIER
* | ssp2marker | advance | ssp2markerXT | advanceXT |
$setglobal mxdataref ssp2marker


# BACKSTOP DATA 
* (DICE2016 as default)
$setglobal pback      550
$setglobal gback      0.025
$setglobal expcost2   2.8
* time starting transition to pbackstop
$setglobal tstart_pbtransition   7
* time of full-convergence to backstop curve [18,38]
$setglobal tend_pbtransition   23
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


* MACC fitting model [polinomial 1-4]
$setglobal maccfit "poly14fit"



## SETS
#_________________________________________________________________________
* In the phase SETS you should declare all your sets, or add to the existing
* sets the element that you need.
$elseif.ph %phase%=='sets'

SETS

   coef    'fit coefficients for MACC'  / a, b /

   sector  'EnerData sectors'   /
        Total_CO2
        Total_CH4
        #Total_HFC
        Total_N2O
        #Total_PFC
        #Total_SF6
    /

   map_sector_ghg(sector,ghg) 'Relationships between Enerdata Sectors and GHG' /
        Total_CO2.co2
        Total_CH4.ch4
        #Total_HFC.hfc
        Total_N2O.n2o
        #Total_PFC.pfc
        #Total_SF6.sf6
    /

;

* MX alternative data references
SET mxdataref 'Rata-reference for macc multiplier calibration'/

        ssp2marker
        advance
        ssp2markerXT
        advanceXT
    /
;



## INCLUDE DATA
#_________________________________________________________________________
* In the phase INCLUDE_DATA you should declare and include all exogenous parameters.
* You can also modify the data loaded in data.gms
* Best practice : - create a .gdx containing those and to loading it
*                 - this is the only phase where we should have numbers...
$elseif.ph %phase%=='include_data'


##  PARAMETERS HARDCODED OR ASSIGNED ------------------- 

PARAMETERS
* DICE backstop
    expcost2  "Exponent of control cost function"                / %expcost2% / #DICE: 2.8
    pback     "Cost of backstop 2010$ per tCO2 in 2015"          / %pback%    / #DICE2013: 344     #DICE2016: 550
    gback     "Initial cost decline backstop cost per period"    / %gback%    / #DICE2013: 0.05    #DICE2016: 0.025
;


##  PARAMETERS LOADED ----------------------------------

* Correction multiplier calibrated
PARAMETER  MXkali(mxdataref)  "Correction multiplier calibrated over enerdata times"  ;
$gdxin '%datapath%data_mod_macc_correcting_factor'
$load  MXkali
$gdxin


* CO2 MAC-Curves fitting parameters
PARAMETER  macc_%maccfit%_enerdata_CO2(sector,coef,t,n)  'EnerData CO2 MACC -fit with %maccfit%- for given years (2025-2040)'  ;
$gdxin '%datapath%data_macc_enerdata_co2perc_fit'
$load  macc_%maccfit%_enerdata_CO2    = abat_coef_enerdata_%maccfit%
$gdxin



##  PARAMETERS EVALUATED -------------------------------

PARAMETERS
* Backstop
    pbacktime(t)            "Backstop price"
    cost1(t,n)              "Adjusted cost for Backstop"
    partfract(t)            "Fraction of emissions in control regime"
* MACC fit coefficients
    ax_co2(*,sector,t,n)    "EnerData < a > %maccfit%-coeff for MACC"
    bx_co2(*,sector,t,n)    "EnerData < b > %maccfit%-coeff for MACC"
* MACC transition
    mx(t,n)                 "Enerdata MACC multiplier calibated on diagnostics"
    alpha(t)                "Transition to backstop coefficient"
    MXpback(t,n)            "MX to obtain full pbackstop"
    MXstart(n)              "MX starting value"
    MXend(t,n)              "MX value to be reached"
    MXdiff(t,n)             "MX transition gap"
;





##  COMPUTE DATA
#_________________________________________________________________________
* In the phase COMPUTE_DATA you should declare and compute all the parameters
* that depend on the data loaded in the previous phase.
$elseif.ph %phase%=='compute_data'



# MACC fit-coefficients --------------------------------

ax_co2('%maccfit%','Total_CO2',t,n)    = macc_%maccfit%_enerdata_CO2('Total_CO2', 'a', t, n);
bx_co2('%maccfit%','Total_CO2',t,n)    = macc_%maccfit%_enerdata_CO2('Total_CO2', 'b', t, n);


#  PBackstop curve -------------------------------------

pbacktime(t)  =  pback*(1-gback)**(t.val-1);
cost1(t,n)    =  pbacktime(t)*sigma(t,n)/expcost2/1000;



# TRANSITION TO BACKSTOP -------------------------------
* It is directly related to settings from conf phase.
* Shape, slope and convergence time are all taken into account here

## logistic pbtransition
scalar x0 ;
x0 = %tstart_pbtransition% + ((%tend_pbtransition%-%tstart_pbtransition%)/2)  ;
alpha(t) = 1/(1+exp(-%klogistic%*(t.val-x0)));



# BACKSTOP MULTIPLIER ----------------------------------

# NOTE .....................................................................
# Following evaluations give answer to the question:
# Which multiplier would make my full-abatement MACcurve (MIU=1) coincide
# to the previously-evaluated pbackstop (in every time-step)?
#...........................................................................

# Mx = back_end / (a bau + b bau^4)  -->  MIU = 1
MXpback(t,n)  =  pbacktime(t)
                /  ((ax_co2('%maccfit%','Total_CO2',t,n) * 1)  +  (bx_co2('%maccfit%','Total_CO2',t,n) * power(1,4)))  ;


# NOTE ........................................................................
# Before transition the original multiplier applies,
# then a smooth  transition to the pback-curve is performed,
# by progressively reducing the distance (according to the shaping alpha-param)
#...............................................................................

MXstart(n)   =  MXkali('%mxdataref%')  ;
MXend(t,n)   =  MXpback(t,n)  ;
MXdiff(t,n)  =  max( MXstart(n)  - MXend(t,n),0) ;

* Final coefficient values:
mx(t,n)      =  MXstart(n)  -  alpha(t) * MXdiff(t,n);




##  DECLARE VARIABLES
#_________________________________________________________________________
* In the phase VARS, you can DECLARE new variables for your module.
* Remember that by modifying sets, you already have some variables for free.
$elseif.ph %phase%=='declare_vars'

VARIABLES
* Abatement costs
    ABATECOST_ED(t,n) 'Cost of emissions reductions according to EnerData MACC  [Trill 2005 USD / year]'
    ABATECOST_PB(t,n) 'Cost of emissions reductions according to PBackstop MACC [Trill 2005 USD / year]'
* CPrices
    CPRICE_ED(t,n)    'Carbon price according to EnerData MACC [ 2005 USD / tCO2 ]'
    CPRICE_PB(t,n)    'Carbon price according to backstop [ 2005 USD / tCO2 ]'
;
POSITIVE VARIABLES ABATECOST_ED, ABATECOST_PB, CPRICE_ED, CPRICE_PB;




##  COMPUTE VARIABLES
#_________________________________________________________________________
* In the phase COMPUTE_VARS, you fix starting points and bounds.
* DO NOT put VAR.l here! (use the declare_vars phase)
$elseif.ph %phase%=='compute_vars'



#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================



##  EQUATION LIST
#_________________________________________________________________________
* List of equations
* One per line.
$elseif.ph %phase%=='eql'


    eq_abate_ed          #'Cost of emissions reductions equation according to enerdata macc'
    eq_abate_pb          #'Cost of emissions reductions equation according to pbackstop'

    eq_cprice_ed          #'Carbon price equation according to enerdata macc'
    eq_cprice_pb          #'Carbon price equation according to pbackstop'



##  EQUATIONS
#_________________________________________________________________________
* In the phase EQS, you can include new equations to the model.
* The equations are always included.
* Best practice : - condition your equation to be able to do a run with t_fix(t)
$elseif.ph %phase%=='eqs'


# ABATEMENT COSTS AND CPRICE FROM PBACKSTOP ------------

eq_abate_pb(t,n)$(reg(n))..  ABATECOST_PB(t,n)  =E=   YGROSS(t,n) * cost1(t,n) * (MIU(t,n)**expcost2)  ;


eq_cprice_pb(t,n)$(reg(n)).. CPRICE_PB(t,n)  =E=  pbacktime(t) * (MIU(t,n))**(expcost2-1)  ;



# ABATE COSTS AND CPRICE FROM ENERDATA CO2 MACCs  ------

* y ~ ax + bx^4   --with multiplier-->   y ~ mx (ax + bx^4)
* with constraints (R-colf optim package) avoiding negative costs

* Abatement Cost ::   mx * (a(x^2)/2 + b(x^5)/5) * bau   :: [$/tCO2]x[GtCO2] ->  [ G$ ]
eq_abate_ed(t,n)$(reg(n))..
                              #   Correction coefficient
          ABATECOST_ED(t,n)  =E=  mx(t,n)
                              #   Tay14 integral
                              *   ((ax_co2('%maccfit%','Total_CO2',t,n)*power(MIU(t,n),2)/2)  +  (bx_co2('%maccfit%','Total_CO2',t,n)*power(MIU(t,n),5)/5))
                              #   Baseline emissions (due to miu-based integral) [GtCO2]
                              *   emi_bau_co2(t,n)
                              #   Coversion:  [ G$ ] / 1000 -> [Trill $]
                              /   1000
;                             # >> Costs will result in [Trill USD]

* Carbon Price ::   y ~ mx (ax + bx^4)
eq_cprice_ed(t,n)$(reg(n))..
                              #   Correction coefficient
             CPRICE_ED(t,n)  =E=  mx(t,n)
                              #   Taylor14 formulation
                              *   ((ax_co2('%maccfit%','Total_CO2',t,n)*MIU(t,n)) + (bx_co2('%maccfit%','Total_CO2',t,n)*power(MIU(t,n),4)))
;                             # >> CPrice will result in [$/tCO2] by construction



#  FINAL ABATECOSTS AND CPRICE --------------------

eq_abatecost(t,n)$(reg(n)).. ABATECOST(t,n)  =E=  ABATECOST_ED(t,n)  ;

eq_cprice(t,n)$(reg(n)).. CPRICE(t,n)  =E=  CPRICE_ED(t,n)  ;



#=========================================================================
*   ///////////////////////     SIMULATION    ///////////////////////
#=========================================================================

##  SIMULATION SETUP
#_________________________________________________________________________
* In this phase you have either to fix free variables or to declare useful
* parameters for the simulation loop.
* You are NOT inside a loop(t,..) at this stage.
$elseif.ph %phase%=='set_simulation'


##  SIMULATION HALFLOOP 1
#_________________________________________________________________________
* In the phase SIM1, you have to replicate all equations but keeping VAR.l instead
* of the pure variable and '=' instead =E=.
* Consider that you ARE inside a loop(t, ..),therefore NOTHING can be declared as new
$elseif.ph %phase%=='simulate_1'


# ABATEMENT COSTS AND CPRICE FROM PBACKSTOP ------------

          ABATECOST_PB.l(t,n)  =  YGROSS.l(t,n) * cost1(t,n) * (MIU.l(t,n)**expcost2)  ;


             CPRICE_PB.l(t,n)  =  pbacktime(t) * (MIU.l(t,n))**(expcost2-1)   ;



# ABATE COSTS AND CPRICE FROM ENERDATA CO2 MACCs  ------

* y ~ ax + bx^4   --with multiplier-->   y ~ mx (ax + bx^4)
* with constraints (R-colf optim package) avoiding negative costs

* Abatement Cost ::   mx * (a(x^2)/2 + b(x^5)/5) * bau   :: [$/tCO2]x[GtCO2] ->  [ G$ ]
                              #   Correction coefficient
         ABATECOST_ED.l(t,n)  =  mx(t,n)
                              #   Tay14 integral
                              *   ((ax_co2('%maccfit%','Total_CO2',t,n)*power(MIU.l(t,n),2)/2)  +  (bx_co2('%maccfit%','Total_CO2',t,n)*power(MIU.l(t,n),5)/5))
                              #   Baseline emissions (due to miu-based integral) [GtCO2]
                              *   emi_bau_co2(t,n)
                              #   Coversion:  [ G$ ] / 1000 -> [Trill $]
                              /   1000
;                             # >> Costs will result in [Trill USD]


* Carbon Price ::   y ~ mx (ax + bx^4)
                              #   Correction coefficient
            CPRICE_ED.l(t,n)  =   mx(t,n)
                              #   Taylor14 formulation
                              *   ((ax_co2('%maccfit%','Total_CO2',t,n)*MIU.l(t,n)) + (bx_co2('%maccfit%','Total_CO2',t,n)*power(MIU.l(t,n),4)))
;                             # >> CPrice will result in [$/tCO2] by construction


# FINAL ABATECOSTS AND CPRICE --------------------------
 
 ABATECOST.l(t,n)  =  ABATECOST_ED.l(t,n)  ;

 CPRICE.l(t,n)  =  CPRICE_ED.l(t,n) ;



##  SIMULATION HALFLOOP 2
#_________________________________________________________________________
* In the phase SIM2, you have to replicate all equations but keeping VAR.l instead
* of the pure variable and '=' instead =E=.
* Everything declared at halfloop1 has already been executed.
* Consider that you ARE inside a loop(t, ..),therefore NOTHING can be declared as new
$elseif.ph %phase%=='simulate_2'


##  AFTER SIMULATION
#_________________________________________________________________________
* In this phase you are OUTSIDE the loop(t,..), at the end of the simulation process.
$elseif.ph %phase%=='after_simulation'


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

# Variables ------------------------------
ABATECOST_PB
ABATECOST_ED
CPRICE_ED
CPRICE_PB


$endif.ph 
