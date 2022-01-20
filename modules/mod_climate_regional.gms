* MODULE LOCAL TEMPERATURES
*
* Here's the downscaling logic to evalueate ho local temperatures react to
* athmospheric temperature increase.
*____________
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================
##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

# Set to import regions temperatures to RCP (26, 45, 60, 85)
*$setglobal temp_region_exogen 26

# Set to activate Burke's conservative approach (maximum local temperature used
# for damages evaluation equal to maximum observed temperature in past calibration data )
*$setglobal temp_region_cap

## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

set tincpast /'-8','-7','-6','-5','-4','-3','-2','-1','0',1*58/; 
set tnopast(tincpast) /1*58/;  

## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

##  PARAMETERS HARDCODED OR ASSIGNED -------------------
SCALAR max_temp_region_dam "Maximum temperature observed in regions' past time series [°C]" /30/;

# Downscaler coefficients
parameter climate_region_coef(*,n)  'Estimated coefficients to link GMT and country-level mean temperatures';
$gdxin '%datapath%data_mod_climate_regional'
$loaddc climate_region_coef
$gdxin

$ifthen.exo set temp_region_exogen
#Source:  http://climexp.knmi.nl/selectfield_cmip5.cgi?id=someone@somewhere
#Ensemble mean across 19 models (all, not bias corrected)
parameter temp_region_valid_cmip5(t,n,*);
$gdxin '%datapath%data_mod_climate_regional'
$loaddc temp_region_valid_cmip5
$gdxin
# Exogen local temperatures (for simulation purposes only).
PARAMETER  temp_region_exogen(t,n) 'Loaded exogeous local temperatures';
temp_region_exogen(t,n) = temp_region_valid_cmip5(t,n,'%temp_region_exogen%');
temp_region_exogen(t,n)$(t.val gt 18) = temp_region_exogen('18',n);
$endif.exo

##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'




##  DECLARE VARIABLES
#_________________________________________________________________________
* In the phase DECLARE VARS, you can DECLARE new variables for your module.
* Remember that by modifying sets, you already have some variables for free.
$elseif.ph %phase%=='declare_vars'

VARIABLES
    TEMP_REGION(t,n)              'Near surface regional average temperature [deg.C]'
    TEMP_REGION_DAM(t,n)          'Regional pop-weighted average temperature used for damages evaluation [deg.C]'
    TEMP_REGION_DAM_INCPAST(tincpast,n)  'Regional pop-weighted average temperature used for damages evaluation [deg.C] inlcuding the past'
;

##  COMPUTE VARIABLES
#_________________________________________________________________________
* In the phase COMPUTE_VARS, you fix starting points and bounds.
* DO NOT put VAR.l here! (use the declare_vars phase)
$elseif.ph %phase%=='compute_vars'

##  STABILITY CONSTRAINTS ------------------------------
* to avoid errors/help the solver to converge
* Tolerance for min/max nlp smooting
SCALAR   delta_tempcap  /1e-4/ ;

#compute past temperature (0=2010, -6=1980) values and fix based on same downscaling (hadcrud4 global temp anomaly, corrected for 2015 different (hadcrut, 0.977784, model 0.85))
TEMP_REGION_DAM_INCPAST.fx('0',n) = climate_region_coef('alpha_temp',n) + (climate_region_coef('beta_temp',n)) * (0.782984 - (0.977784-0.85));
TEMP_REGION_DAM_INCPAST.fx('-1',n) = climate_region_coef('alpha_temp',n) + (climate_region_coef('beta_temp',n)) * (0.81058 - (0.977784-0.85));
TEMP_REGION_DAM_INCPAST.fx('-2',n) = climate_region_coef('alpha_temp',n) + (climate_region_coef('beta_temp',n)) * (0.72698 - (0.977784-0.85));
TEMP_REGION_DAM_INCPAST.fx('-3',n) = climate_region_coef('alpha_temp',n) + (climate_region_coef('beta_temp',n)) * (0.56258 - (0.977784-0.85));
TEMP_REGION_DAM_INCPAST.fx('-4',n) = climate_region_coef('alpha_temp',n) + (climate_region_coef('beta_temp',n)) * (0.50598 - (0.977784-0.85));
TEMP_REGION_DAM_INCPAST.fx('-5',n) = climate_region_coef('alpha_temp',n) + (climate_region_coef('beta_temp',n)) * (0.38918 - (0.977784-0.85));
TEMP_REGION_DAM_INCPAST.fx('-6',n) = climate_region_coef('alpha_temp',n) + (climate_region_coef('beta_temp',n)) * (0.35938 - (0.977784-0.85));
TEMP_REGION_DAM_INCPAST.fx('-7',n) = climate_region_coef('alpha_temp',n) + (climate_region_coef('beta_temp',n)) * (0.21278 - (0.977784-0.85));
TEMP_REGION_DAM_INCPAST.fx('-8',n) = climate_region_coef('alpha_temp',n) + (climate_region_coef('beta_temp',n)) * (0.23998 - (0.977784-0.85));


#_________________________________________________________________________
$elseif.ph %phase%=='before_solve'

TEMP_REGION.l(t,n) = climate_region_coef('alpha_temp',n) + (climate_region_coef('beta_temp',n)) * TATM.l(t);
TEMP_REGION_DAM.l(t,n)  =  min(TEMP_REGION.l(t,n), max_temp_region_dam) ;


#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'

   eq_temp_region           # Local avg temperature downscaling equation
   eq_temp_region_dam       # Local temperature used for damages evaluation equation
   eq_temp_region_dam_incpast

##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

$ifthen.exogn not set temp_region_exogen
# Endogenous regional temperature downscaler
 eq_temp_region(t,n)$(reg(n))..
    TEMP_REGION(t,n) =E= climate_region_coef('alpha_temp',n) + (climate_region_coef('beta_temp',n)) * TATM(t);
$else.exogn
# Exogenous regional temeperature
 eq_temp_region(t,n)$(reg(n))..
    TEMP_REGION(t,n) =E= temp_region_exogen(t,n)  ;
$endif.exogn


$ifthen.tempcap set temp_region_cap
 eq_temp_region_dam(t,n)$(reg(n))..
    TEMP_REGION_DAM(t,n)  =E=  ( TEMP_REGION(t,n) + max_temp_region_dam
                                  - Sqrt( Sqr(TEMP_REGION(t,n)-max_temp_region_dam) + Sqr(delta_tempcap) )
                               )/2  ;
    # ................................................................................................
    # NOTE:
    # Following Burke et al.(2015) conservative approach, here we cap maximum local temperature used
    # for damages evaluation at 30°C level, the maximum observed temperature in past time series upon
    # which economic response has been calibrated.
    #
    # A smooth GAMS approximation for  min(f(x),g(y))  is:
    # >   ( f(x) + g(y) - Sqrt( Sqr( f(x)-g(y) ) + Sqr(delta) ) )/2
    # ................................................................................................
$else.tempcap
# No cap here: damages evaluated to effective local temperatures
  eq_temp_region_dam(t,n)$(reg(n)).. TEMP_REGION_DAM(t,n)  =E=  TEMP_REGION(t,n)  ;
$endif.tempcap

   eq_temp_region_dam_incpast(tincpast,n)$(tnopast(tincpast) and reg(n)).. 
      TEMP_REGION_DAM_INCPAST(tincpast,n) =E= sum(t$sameas(t,tincpast), TEMP_REGION_DAM(t,n));


#____________________________________________________________________________________________
$elseif.ph %phase%=='after_solve'

TEMP_REGION.l(t,n) = climate_region_coef('alpha_temp',n) + (climate_region_coef('beta_temp',n)) * TATM.l(t);

$ifthen.exogn set temp_region_exogen
# Exogenous regional temeperature
TEMP_REGION.l(t,n)  =  temp_region_exogen(t,n)  ;
$endif.exogn

$ifthen.tempcap set temp_region_cap
# ................................................................................................
# Following Burke et al.(2015) conservative approach, here we cap maximum local temperature used
# for damages evaluation at 30°C level, the maximum observed temperature in past time series upon
# which economic response has been calibrated.
# ................................................................................................
 TEMP_REGION_DAM.l(t,n)  =  min(TEMP_REGION.l(t,n), max_temp_region_dam) ;
$else.tempcap
# No cap here: damages evaluated to effective local temperatures
 TEMP_REGION_DAM.l(t,n)  =  TEMP_REGION.l(t,n)  ;
$endif.tempcap

TEMP_REGION_DAM_INCPAST.l(tincpast,n)$tnopast(tincpast) = sum(t$sameas(t,tincpast), TEMP_REGION_DAM.l(t,n));

*=========================================================================
*   ///////////////////////     REPORTING     ///////////////////////
*=========================================================================

##  REPORT
#_________________________________________________________________________
$elseif.ph %phase%=='report'

 PARAMETERS
   temp_region_base(n)          'Regional base-temperatures (average 1980-2010) [deg C]'
   deltatemp(t,n)               'Difference between current and base temperatures [deg C]'
;
temp_region_base(n)  =  climate_region_coef('base_temp', n);
deltatemp(t,n)  =  TEMP_REGION_DAM.l(t,n) - temp_region_base(n);

PARAMETER temp_mean_world_weighted(t) 'TEMP_REGION World coming from weighted Forcing coefficients';
temp_mean_world_weighted(t) =  sum(n, pop('1',n) *  climate_region_coef('alpha_temp', n))/sum(n,pop('1',n))
                             + (sum(n, pop('1',n) *  climate_region_coef('beta_temp', n))/sum(n,pop('1',n)) ) * TATM.l(t);


##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

# Parameters -------------------------------------------
climate_region_coef
deltatemp

# Variables --------------------------------------------
TEMP_REGION
TEMP_REGION_DAM
TEMP_REGION_DAM_INCPAST


$endif.ph
