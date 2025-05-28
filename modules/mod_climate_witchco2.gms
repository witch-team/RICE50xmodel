* CLIMATE WITCH-CO2 SUB-MODULE
*
* Represents the climate
*    - based on the DICE model equations
*    - Radiative forcing for non CO2 ghgs
*    - parameters adjusted to the MAGICC6.4 model
*____________
* REFERENCES
* - "About the WITCH climate module"
*   witch\branches\climate\doc\TR-witch-cm.pdf
* - "Calibration of the WITCH carbon cycle to BERNcc from MAGICC6.4"
*   Modelling meeting presentation (16/04/2013)

#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================
##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'


## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

SET m  'Climate layers' /
   atm    'Atmosphere'
   upp    'Upper Oceans'
   low    'Deep Oceans'
/;
alias (m,mm);
set mbox(m) /atm,upp,low/;    

## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

PARAMETERS
   fex0     '2015 forcings of non-CO2 GHG [Wm-2]'                             / 0.5 /  #DICE2013: 0.25    #DICE2016: 0.5
   fex1     '2100 forcings of non-CO2 GHG [Wm-2]'                             / 1.0 /  #DICE2013: 0.70    #DICE2016: 1.0
;

##  PARAMETERS LOADED ----------------------------------
$gdxin '%datapath%data_mod_climate'
PARAMETER tempc(*)          'Temperature update coefficients';
$load tempc
PARAMETER rfc(ghg,*)        'Radiative forcing update coefficients';
$load rfc

#.....................................................
# NOTE: this WITCH parameter has been UPDATED to
# 2015 VALUES (through one-cycle WITCH run)
#.....................................................
PARAMETER wcum_emi0(ghg,m)  'Initial world GHG emissions [GTon]';
$load wcum_emi0
PARAMETER cmphi(m,mm)       'Carbon Cycle transfert matrix with exchange coefficients';
$load cmphi


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Following parameters come from original WITCH climate and
# are kept only as reference.
# They are not needed inside current module.
#
# PARAMETER temp0(m) 'Initial temperature [deg C above preindustrial levels]';
# $loaddc temp0
#
# PARAMETER wcum_emi_eq(ghg)    'GHG stocks not subject to decay [GTon]';
# $load wcum_emi_eq
#
# PARAMETER emi_preind(ghg)     'Stocks of non-CO2 gases in pre-industrial [GTon]';
# $load emi_preind
#
# PARAMETER cmdec1(*)         'Yearly retention factor for non-co2 gases';
# $loaddc cmdec1
#
# PARAMETER cmdec2(*)         'One period retention factor for non-co2 ghg';
# $loaddc cmdec2
#
# * Calibrate on average runs with WITCH given MAGICC outputs
# PARAMETER rfaerosols(t) 'Radiative forcing from others (aerosols indirect and direct effects, ozone)';
# $loaddc rfaerosols
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
$gdxin


## load estimated fit from CO2 to OGHG forcing
Parameters oghg_coeff(*)  'Calibrated coefficients for OGHG-forcing related to CO2-forcing';
$gdxin '%datapath%data_ssp_iam.gdx'
$load   oghg_coeff
$gdxin


##  PARAMETERS EVALUATED -------------------------------
PARAMETERS
   wemi2qemi(ghg)    'Conversion factor W_EMI [GtC for CO2, Gt for others] into Q_EMI [GtonCeq]'
   wemi(ghg,t)       'World GHG emissions'
   forcoth(t)        'Exogenous forcing from other greenhouse gases'
   tocean0  'Initial Lower Stratum Temperature change [degree C from 1850-1900]' / 0.11/ 
;


##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

* OGHG forcing exogenous
forcoth(t) =  fex0 + (1/17) * (fex1-fex0) * (tperiod(t)-1)$(tperiod(t) lt 18)  # Linear interpolation from fex0 (t1) to fex1 (t17),
           +  (fex1-fex0)$(tperiod(t) ge 18) ;                   # then (t > 17) level fixed to fex1

#.......................................................
# NOTE:
# Since we have emissions in CO2-CO2eq,
# but they are converted to carbon equivalent for
# the climate module, and emi_gwp is in [GTonCO2eq/GTon],
# therefore we need to convert the emi_gwp as well
#.......................................................

wemi2qemi(ghg)   = 1 / emi_gwp(ghg) * CO2toC ;
wemi2qemi('co2') =  1 / CO2toC;

##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

VARIABLES
   WCUM_EMI(ghg,m,t)  'Global stock of GHG [GTon]'
   RFoth(t)           'Radiative forcing otherGHG as fraction of RFco2 [W/m2'
;
POSITIVE VARIABLES WCUM_EMI;

##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

TATM.UP(t)         =  10     ;
TATM.LO(t)         = -10     ;
TATM.fx(tfirst)    = tatm0   ;

TOCEAN.UP(t)       =  20     ;
TOCEAN.LO(t)       = -1      ;
TOCEAN.FX(tfirst)  = tocean0 ;

# Stability for Emissions
W_EMI.up(ghg,t)   =  200 ;
W_EMI.lo(ghg,t)   = -100 ;
W_EMI.lo('co2',t) = -200 ;

WCUM_EMI.UP(ghg,m,t) = 8000 ;   # consider the co2 bound fosslim = 6000
WCUM_EMI.LO(ghg,m,t) = 0.0001 ;
WCUM_EMI.fx(ghg,m,tfirst)$wcum_emi0(ghg,m) = wcum_emi0(ghg,m) ;

# Stability for Temperatures
RF.lo(ghg,t) = -10;
RF.up(ghg,t) =  40;


#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'

   eq_w_emi_co2      # world tstep co2-emissions
   eq_wcum_emi_co2   # accumulation of Carbon in the atmosphere / upper box / deep oceans
   eq_rf_co2         # CO2 radiative forcing
   eq_rf_oghg        # OGHG radiative forcing
   eq_forc         # Radiative Forcing equation
   eq_tatm         # Temperature-climate equation for Atmosphere
   eq_tocean       # Temperature-climate equation for Lower Oceans


##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

# WORLD EMISSIONS --------------------------------------
* World CO2 emissions (in GTonC)
eq_w_emi_co2(t)..   W_EMI('co2',t)  =E=  ( (sum(n$reg(n), E(t,n,'co2')) + sum(n$(not reg(n)), E.l(t,n,'co2')) )  )
                                     /   wemi2qemi('co2')  
$if set mod_emission_pulse           + emission_pulse('co2',t)                                     
                                     ; # Carbon

* Accumulation of CARBON in the atmosphere / upper box / deep oceans
eq_wcum_emi_co2(m,t,tp1)$(pre(t,tp1) and mbox(m))..   WCUM_EMI('co2',m,tp1)  =E=  sum(mm, cmphi(mm,m) * WCUM_EMI('co2',mm,t))     # exchange transfer in matrix from previous values
                                                      +   (tstep * W_EMI('co2',t))$(sameas(m,'atm'))  ;   # + new emi-values added in atm level
                                                                                                       # Carbon
* CO2 radiative forcing
eq_rf_co2(t)..   RF('co2',t)  =E=  rfc('co2','alpha')*(log(WCUM_EMI('co2','atm',t))-log(rfc('co2','beta')))  ;

* OGHG radiative forcing
eq_rf_oghg(t)..   RFoth(t)  =E=  oghg_coeff('intercept') + oghg_coeff('slope') * RF('co2',t)  ;

* Total radiative forcing
eq_forc(t)..   FORC(t)  =E=  RF('co2',t) + RFoth(t)
$if set mod_sai $if "%sai_experiment%"=="g0" + geoeng_forcing * W_SAI(t)
;

* Global temperature increase from pre-industrial levels
eq_tatm(t,tp1)$pre(t,tp1)..   TATM(tp1)  =E=  TATM(t) +  tempc('sigma1')*(  FORC(t)
                                                               -  tempc('lambda')* TATM(t)
                                                               -  tempc('sigma2')*( TATM(t)-TOCEAN(t) )   );

* Ocean temperature
eq_tocean(t,tp1)$pre(t,tp1)..   TOCEAN(tp1)  =E= TOCEAN(t) + tempc('heat_ocean') * (TATM(t)-TOCEAN(t))  ;


##  AFTER SOLVE
#_________________________________________________________________________
$elseif.ph %phase%=='after_solve'

#............................................................
# NOTE:
# In order to propagate climate informations across regions
# (and make each other aware of resulting setting generated
# by parallel decisions), simulation climate-module phase
# is called.
#............................................................

W_EMI.fx('co2',t) = W_EMI.l('co2',t);
$if set mod_sai $if "%sai_experiment%"=="g0" W_SAI.fx(t) = sum(n,N_SAI.l(t,n));

solve witchco2 using cns;

* unconstrain w_emi
W_EMI.lo('co2',t) = -inf;
W_EMI.up('co2',t) = inf;

$if set mod_sai $if "%sai_experiment%"=="g0" W_SAI.lo(t) = 0;
$if set mod_sai $if "%sai_experiment%"=="g0" W_SAI.up(t) = +inf;

viter(iter,'TATM',t,n)$nsolve(n) = TATM.l(t);  # Keep track of last temperature values

#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

# Parameters -------------------------------------------
forcoth

# Variables --------------------------------------------
W_EMI
WCUM_EMI
RF
RFoth


$endif.ph
