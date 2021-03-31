* CLIMATE DICE2016 SUB-MODULE
* Climate dynamics as original DICE2016 model.
*____________
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================

##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

PARAMETERS 
* Initial Conditions
    mat0   'Initial Concentration in atmosphere 2015 [GtC]'         /851  / #DICE2013: 830.4   #DICE2016: 851
    mu0    'Initial Concentration in upper strata 2015 [GtC]'       /460  / #DICE2013: 1527.   #DICE2016: 460
    ml0    'Initial Concentration in lower strata 2015 [GtC]'       /1740 / #DICE2013: 10010.  #DICE2016: 1740
    mateq  'Equilibrium concentration atmosphere [GtC]'             /588  /
    mueq   'Equilibrium concentration in upper strata [GtC]'        /360  / #DICE2013: 1350    #DICE2016: 360
    mleq   'Equilibrium concentration in lower strata [GtC]'        /1720 / #DICE2013: 1720    #DICE2016: 10000
    matpre 'Concentration in Atmosphere at pre-industrial level'    /588.000 / 

* Flow paramaters
    b12      'Carbon cycle transition matrix'                       /.088 / #DICE2013: .088    #DICE2016: .12
    b23      'Carbon cycle transition matrix'                       /0.007/ #DICE2013: 0.00250 #DICE2016: 0.007
       
** Climate model parameters
    t2xco2   'Equilibrium temp impact [degree C per doubling CO2]'  /3.1 /  #DICE2013: 2.9     #DICE2016: 3.1
    fex0     '2015 forcings of non-CO2 GHG [Wm-2]'                  /0.5 /  #DICE2013: 0.25    #DICE2016: 0.5
    fex1     '2100 forcings of non-CO2 GHG [Wm-2]'                  /1.0 /  #DICE2013: 0.70    #DICE2016: 1.0
    fco22x   'Forcings of equilibrium CO2 doubling (Wm-2)'          /3.6813/ #DICE2013: 3.8     #DICE2016: 3.6813
    c10      'Initial climate equation coefficient for upper level' /0.098  /
    c1beta   'Regression slope coefficient(SoA~Equil TSC)'          /0.01243/
    c1       'Climate equation coefficient for upper level'         /0.1005/ #DICE2013: 0.098   #DICE2016: 0.1005
    c3       'Transfer coefficient upper to lower stratum'          /0.088 /
    c4       'Transfer coefficient for lower level'                 /0.025 /
;

##  PARAMETERS EVALUATED -------------------------------
PARAMETERS
** Flow parameters 
   b11        'Carbon cycle transition matrix'
   b21        'Carbon cycle transition matrix'
   b22        'Carbon cycle transition matrix'
   b32        'Carbon cycle transition matrix'
   b33        'Carbon cycle transition matrix'

** OGHG forcing
   forcoth(t) 'Exogenous forcing for other greenhouse gases'
;


##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

* Parameters for long-run consistency of carbon cycle
b11 = 1 - b12  ;
b21 = b12 * mateq / mueq  ;
b22 = 1 - b21 - b23  ;
b32 = b23 * mueq / mleq  ;
b33 = 1 - b32  ;

* OGHG forcing exogenous
forcoth(t) = fex0 + (1/17) * (fex1-fex0) * (t.val-1)$(t.val lt 18)  # Linear interpolation from fex0 (t1) to fex1 (t17), 
                  + (fex1-fex0)$(t.val ge 18)  ;                    # then (t > 17) level fixed to fex1

* Transient TSC Correction ("Speed of Adjustment Parameter")
c1 =  c10 + c1beta*(t2xco2-2.9)  ;

##  DECLARE VARIABLES
#_________________________________________________________________________
* In the phase VARS, you can DECLARE new variables for your module. 
* Remember that by modifying sets, you already have some variables for free.
$elseif.ph %phase%=='declare_vars'

NONNEGATIVE VARIABLES
  MAT(t)    'Carbon concentration increase in Atmosphere [GtC from 1750]'
   MU(t)    'Carbon concentration increase in Shallow Oceans [GtC from 1750]'
   ML(t)    'Carbon concentration increase in Lower Oceans [GtC from 1750]'
;

##  COMPUTE VARIABLES
#_________________________________________________________________________

$elseif.ph %phase%=='compute_vars'

MAT.LO(t)   =  10   ;
MU.LO(t)    =  100  ;
ML.LO(t)    =  1000 ; 

MAT.FX(tfirst) = mat0  ;
MU.FX(tfirst)  = mu0   ;
ML.FX(tfirst)  = ml0   ;


#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________

$elseif.ph %phase%=='eql'

   eq_mat      # Atmospheric concentration equation
   eq_mu       # Shallow Ocean concentration equation
   eq_ml       # Lower Ocean concentration equation


##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

# CARBON CYCLE -----------------------------------------
eq_mat(t+1)..  MAT(t+1)  =E=  MAT(t)*b11 + MU(t)*b21 
                          +  ((sum(n$reg(n), E(t,n)) + sum(n$(not reg(n)), E.l(t,n))) * tstep * CO2toC )  ;# Carbon

eq_mu(t+1)..   MU(t+1)  =E=  MAT(t)*b12 + MU(t)*b22 + ML(t)*b32 ;

eq_ml(t+1)..   ML(t+1)  =E=  MU(t)*b23 + ML(t)*b33  ;

# FORCING ---------------------------------------------
eq_forc(t)..   FORC(t)  =E=  fco22x * ((log((MAT(t)/matpre))/log(2))) + forcoth(t)  ;

# TEMPERATURES -----------------------------------------
* Athmosphere
eq_tatm(t+1)..   TATM(t+1)  =E=  TATM(t) + c1 * ( (FORC(t+1)-(fco22x/t2xco2)*TATM(t)) - c3 * (TATM(t)-TOCEAN(t)) ) ;
* Ocean
eq_tocean(t+1)..   TOCEAN(t+1)  =E=  TOCEAN(t) + c4 * (TATM(t)-TOCEAN(t)) ;


##  AFTER SOLVE
#_________________________________________________________________________
$elseif.ph %phase%=='after_solve'


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# NOTE:
# In order to propagate climate informations across regions 
# (and make each other aware of resulting setting generated 
# by parallel decisions), simulation climate-module phase 
# is called.
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

$set phase 'simulate_1'
$batinclude 'modules/hub_climate'
$set phase 'after_solve'

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# NOTE ALSO: by calling hub_climate you are automatically 
# selecting the simulate_1 phase of the corresponding climate module.
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


#=========================================================================
*   ///////////////////////     SIMULATION    ///////////////////////
#=========================================================================


##  SIMULATION HALFLOOP 1
#_________________________________________________________________________
$elseif.ph %phase%=='simulate_1'

# CARBON CYCLE -----------------------------------------
MAT.l(t+1)  =  MAT.l(t)*b11 + MU.l(t)*b21 + (sum(n, E.l(t,n)) * tstep * CO2toC ) ; # Carbon

MU.l(t+1)  =  MAT.l(t)*b12 + MU.l(t)*b22 + ML.l(t)*b32 ;

ML.l(t+1)  =  MU.l(t)*b23 + ML.l(t)*b33 ;

# FORCING ----------------------------------------------
FORC.l(t)  =  fco22x * ((log((MAT.l(t)/matpre))/log(2))) + forcoth(t);

# TEMPERATURES -----------------------------------------
* Athmosphere
TATM.l(t)$(not tfirst(t))  =  TATM.l(t-1) + c1 * ((FORC.l(t)-(fco22x/t2xco2)*TATM.l(t-1)) - c3 * (TATM.l(t-1)-TOCEAN.l(t-1)))  ;
* Ocean
TOCEAN.l(t+1)  =  TOCEAN.l(t) + c4 * (TATM.l(t)-TOCEAN.l(t))  ;


#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

# Parameters -------------------------------------------
forcoth


$endif.ph