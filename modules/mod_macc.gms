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

# MACC CURVES formula
* | ed | dice2016 |
$setglobal macc 'ed'


* CORRECTION MULTIPLIER
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


# MACC SHAPE
* MACC fitting model | cstay14fit [polinomial 1-4] |
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



##  PARAMETERS OF DICE2016 ABATEMENT COST FUNCTION
PARAMETERS
** Participation parameters
    periodfullpart Period at which have full participation           /21  /  #DICE2013
    partfract2010  Fraction of emissions under control in 2010       / 1  /  #DICE2013
    partfractfull  Fraction of emissions under control at full time  / 1  /  #DICE2013
;


##  PARAMETERS LOADED ----------------------------------

* Correction multiplier calibrated
PARAMETER  MXkali(mxdataref)  "Correction multiplier calibrated over enerdata times"  ;
$gdxin '%datapath%data_mod_macc_correcting_factor'
$load  MXkali
$gdxin


* CO2 MAC-Curves fitting parameters
PARAMETER  macc_%maccfit%_enerdata_CO2(sector,coef,t,n)  'EnerData CO2 MACC -fit with %maccfit%- for given years (2025-2040)'  ;
$gdxin '%datapath%data_macc_ed_co2perc_fit'
$load  macc_%maccfit%_enerdata_CO2    = abat_coef_enerdata_%maccfit%
$gdxin


* OGHG MAC-Curves fitting parameters
$ifthen.oghg %climate% == 'witchoghg'
PARAMETER  macc_fitcoef_enerdata_OGHG(sector,coef,t,n)  'EnerData OGHG MACC fit for given years (2025-2040)'  ;
$gdxin '%datapath%data_macc_enerdata_OGHG'
$load  macc_fitcoef_enerdata_OGHG = abat_coef_enerdata
$gdxin
$endif.oghg


##  PARAMETERS EVALUATED -------------------------------

PARAMETERS
* Backstop
    pbacktime(t)            "Backstop price"
    cost1(t,n)              "Adjusted cost for Backstop"
    partfract(t)            "Fraction of emissions in control regime"
* MACC fit coefficients
    ax_co2(*,sector,t,n)    "EnerData < a > %maccfit%-coeff for MACC"
    bx_co2(*,sector,t,n)    "EnerData < b > %maccfit%-coeff for MACC"
    a_oghg(sector,t,n)      "EnerData < a > fit-coeff for MACC"
    b_oghg(sector,t,n)      "EnerData < b > fit-coeff for MACC"
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


$ifthen.oghg %climate% == 'witchoghg'
a_oghg(sector,t,n)     = macc_fitcoef_enerdata_OGHG(  sector  , 'a', t, n);
b_oghg(sector,t,n)     = macc_fitcoef_enerdata_OGHG(  sector  , 'b', t, n);
$endif.oghg


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
   ABATECOST(t,n)    'Cost of emissions reductions [Trill 2005 USD / year]'
   CPRICE(t,n)       'Carbon Price [ 2005 USD /tCO2 ]'
   ABATECOST_OGHG(oghg,t,n)    'Cost of oghg emissions reductions [Trill 2005 USD / year]'
;

POSITIVE VARIABLES ABATECOST, CPRICE, ABATECOST_OGHG;

# VARIABLES STARTING LEVELS ----------------------------
ABATECOST.l(t,n) = 0 ;
   CPRICE.l(t,n) = 0 ;

##  COMPUTE VARIABLES
#_________________________________________________________________________
* In the phase COMPUTE_VARS, you fix starting points and bounds.
$elseif.ph %phase%=='compute_vars'


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

$if %climate% == 'witchoghg'  eq_abatecost_oghg   # Cost of oghg emissions reductions equation


##  EQUATIONS
#_________________________________________________________________________
* In the phase EQS, you can include new equations to the model.
* The equations are always included.
* Best practice : - condition your equation to be able to do a run with t_fix(t)
$elseif.ph %phase%=='eqs'


$ifthen.macc %macc%=="ed"

* Abatement Cost ::   mx * (a(x^2)/2 + b(x^5)/5) * bau   :: [$/tCO2]x[GtCO2] ->  [ G$ ]
eq_abatecost(t,n)$(reg(n))..
                              #   Correction coefficient
          ABATECOST(t,n)  =E=  mx(t,n)
                              #   Tay14 integral
                              *   ((ax_co2('%maccfit%','Total_CO2',t,n)*power(MIU(t,n),2)/2)  +  (bx_co2('%maccfit%','Total_CO2',t,n)*power(MIU(t,n),5)/5))
                              #   Baseline emissions (due to miu-based integral) [GtCO2]
                              *   emi_bau_co2(t,n)
                              #   Coversion:  [ G$ ] / 1000 -> [Trill $]
                              /   1000
;                             # >> Costs will result in [Trill USD]



* Carbon Price ::   y ~ mx (ax + bx^4)
eq_cprice(t,n)$(reg(n))..
                              #   Correction coefficient
             CPRICE(t,n)  =E=  mx(t,n)
                              #   Taylor14 formulation
                              *   ((ax_co2('%maccfit%','Total_CO2',t,n)*MIU(t,n)) + (bx_co2('%maccfit%','Total_CO2',t,n)*power(MIU(t,n),4)))
;                             # >> CPrice will result in [$/tCO2] by construction


* :::::  ABATE COSTS AND CPRICE FROM ENERDATA OGHG MACCs  ::::: *
** OGHG ABATECOSTS
$ifthen.oghg %climate% == 'witchoghg'
 eq_abatecost_oghg(oghg,sector,t,n)$(reg(n) and  map_sector_ghg(sector,oghg))..
                                  # Powerfit Abatement Cost:  [ USD/tCO2eq_max_abat ] :  a (MIU^(b+1)) / (b+1)
   ABATECOST_OGHG(oghg,t,n)  =E=  ED_a_oghg(sector,t,n)*(MIU_OGHG(oghg,t,n)**(ED_b_oghg(sector,t,n) +1)) / (ED_b_oghg(sector,t,n) +1)
                                  # Baseline emissions   [ GtCo2eq ]
                              *   oghg_emi_bau(oghg,t,n)
                                  # Coversion result     [ G$/1000 = Trill$ ]
                              /   1000   ;
$endif.oghg

$elseif.macc %macc%=="dice2016"
** ABATECOST AND CPRICE AS IN ORIGINAL DICE2016
eq_abatecost(t,n)$(reg(n))..
             ABATECOST(t,n)  =E=  YGROSS(t,n) * cost1(t,n) * (MIU(t,n)**expcost2)
;

eq_cprice(t,n)$(reg(n))..
                CPRICE(t,n)  =E=  pbacktime(t) * (MIU(t,n))**(expcost2-1)
;
$endif.macc

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
cost1
ax_co2
bx_co2
alpha

# Variables ------------------------------

ABATECOST
CPRICE


$endif.ph 
