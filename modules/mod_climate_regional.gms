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

$setglobal downscaling cmip5_pop #cmip5_pop, cmip6_pop, cmip6_area

## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

set tincpast /'-8','-7','-6','-5','-4','-3','-2','-1','0',1*58/; 
set tnopast(tincpast) /3*58/;  
set tpast(tincpast);  

tpast(tincpast) = not tnopast(tincpast);

## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

##  PARAMETERS HARDCODED OR ASSIGNED -------------------
SCALAR max_temp_region_dam "Maximum temperature observed in regions' past time series [°C]" /30/;

Parameter tatm_valid(tincpast) "Historical temperatures for past data, increase relative to 1850-1900 mean";

Parameter temp_valid_yearlu(*,yearlu,n);
$gdxin '%datapath%/data_historical_values.gdx'
$ifthen.cmip %downscaling%=="cmip5_pop" $load temp_valid_yearlu=temp_valid_hadcrut4
$else.cmip $load temp_valid_yearlu=temp_valid_hadcrut5
$endif.cmip
$gdxin 

# Downscaler coefficients
parameter climate_region_coef(*,n)  'Estimated coefficients to link GMT and country-level mean temperatures';
$gdxin '%datapath%data_mod_climate_regional'
$if %downscaling%=="cmip5_pop" $loaddc climate_region_coef=climate_region_coef_cmip5
$if %downscaling%=="cmip6_pop" $loaddc climate_region_coef=climate_region_coef_cmip6_pop
$if %downscaling%=="cmip6_area"  $loaddc climate_region_coef=climate_region_coef_cmip6_area
$gdxin

parameter temp_region_valid(t,n,*);
$gdxin '%datapath%data_mod_climate_regional'
$if %downscaling%=="cmip5_pop" $loaddc temp_region_valid=temp_region_valid_cmip5
$if %downscaling%=="cmip6_pop" $loaddc temp_region_valid = temp_region_valid_pop_cmip6
$if %downscaling%=="cmip6_area" $loaddc temp_region_valid = temp_region_valid_area_cmip6
$gdxin

$ifthen.exo set temp_region_exogen
# Exogen local temperatures (for simulation purposes only).
PARAMETER  temp_region_exogen(t,n) 'Loaded exogeous local temperatures';
temp_region_exogen(t,n) = temp_region_valid(t,n,'%temp_region_exogen%');
temp_region_exogen(t,n)$(tperiod(t) gt 18) = valuein(2100, temp_region_exogen(tt,n));
$endif.exo

##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

#calculate average 5yr temperature from yearly hadcrut4 data
tatm_valid(tincpast)$tpast(tincpast) = sum((n,yearlu)$(yearlu.val> (2015-tstep*(1-tincpast.val))-3 and yearlu.val<(2015-tstep*(1-tincpast.val))+3),temp_valid_yearlu('atm',yearlu,n))/(sum(n,1)*tstep) ;
#tatm0=tatm_valid('1');

##  DECLARE VARIABLES
#_________________________________________________________________________
* In the phase DECLARE VARS, you can DECLARE new variables for your module.
* Remember that by modifying sets, you already have some variables for free.
$elseif.ph %phase%=='declare_vars'

VARIABLES
    TEMP_REGION(t,n)              'Near surface regional average temperature [deg.C]'
    TEMP_REGION_DAM(t,n)          'Regional pop-weighted average temperature used for damages evaluation [deg.C]'
    TEMP_REGION_DAM_INCPAST(tincpast,n)  'Regional pop-weighted average temperature used for damages evaluation [deg.C] inlcuding the past'
    PRECIP_REGION(t,n)            'Regional average precipitation [mm/day]'
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

#Parameter tatm_valid(tincpast)
#tatm_valid(tincpast) = temp_valid_hardcrut4('')
#compute past temperature (0=2010, -6=1980) values and fix based on same downscaling (hadcrud4 global temp anomaly)
TEMP_REGION_DAM_INCPAST.fx(tincpast,n)$(tpast(tincpast)) = climate_region_coef('alpha_temp',n) + climate_region_coef('beta_temp',n) * tatm_valid(tincpast);
TEMP_REGION.l(tfirst,n) = climate_region_coef('alpha_temp',n) + (climate_region_coef('beta_temp',n)) * TATM.l(tfirst);

#_________________________________________________________________________
$elseif.ph %phase%=='before_solve'

TEMP_REGION.l(t,n) = climate_region_coef('alpha_temp',n) + (climate_region_coef('beta_temp',n)) * TATM.l(t);
$if set temp_region_exogen TEMP_REGION.l(t,n)=temp_region_exogen(t,n);
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
   eq_precip_region         # Local avg precipitation downscaling equation

##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

$ifthen.exogn not set temp_region_exogen
# Endogenous regional temperature downscaler
 eq_temp_region(t,n)$(reg_all(n))..
    TEMP_REGION(t,n) =E= climate_region_coef('alpha_temp',n) + (climate_region_coef('beta_temp',n)) * TATM(t)
$if set mod_sai -  DTEMP_REGION_SAI(t,n)
    ;
$else.exogn
# Exogenous regional temeperature
 eq_temp_region(t,n)$(reg_all(n))..
    TEMP_REGION(t,n) =E= temp_region_exogen(t,n)  ;
$endif.exogn

 eq_precip_region(t,n)$(reg_all(n))..
    PRECIP_REGION(t,n) =E= 
    ( climate_region_coef('alpha_precip',n) + climate_region_coef('beta_precip',n) * TATM(t) ) * 12 * ( 1 
$if set mod_sai +   DPRECIP_REGION_SAI(t,n) 
    );

$ifthen.tempcap set temp_region_cap
 eq_temp_region_dam(t,n)$(reg_all(n))..
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
  eq_temp_region_dam(t,n)$(reg_all(n)).. TEMP_REGION_DAM(t,n)  =E=  TEMP_REGION(t,n)  ;
$endif.tempcap

   eq_temp_region_dam_incpast(tincpast,n)$(tnopast(tincpast) and reg_all(n)).. 
      TEMP_REGION_DAM_INCPAST(tincpast,n) =E= sum(t$sameas(t,tincpast), TEMP_REGION_DAM(t,n));


#____________________________________________________________________________________________
$elseif.ph %phase%=='after_solve'

TEMP_REGION.l(t,n) = climate_region_coef('alpha_temp',n) + (climate_region_coef('beta_temp',n)) * TATM.l(t) 
$if set mod_sai - DTEMP_REGION_SAI.l(t,n)
;

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
tatm_valid
temp_region_valid

# Variables --------------------------------------------
TEMP_REGION
PRECIP_REGION
TEMP_REGION_DAM
TEMP_REGION_DAM_INCPAST


$endif.ph
