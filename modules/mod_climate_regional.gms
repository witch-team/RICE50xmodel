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

# Set 1 to import regions temperatures from external data
$setglobal exogen_temp_region 0

# Set 1 to activate Burke's conservative approach (maximum local temperature used
# for damages evaluation equal to maximum observed temperature in past calibration data )
$setglobal temp_region_cap 1


## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

##  PARAMETERS HARDCODED OR ASSIGNED -------------------
SCALAR max_temp_region_dam "Maximum temperature observed in regions' past time series [°C]" /30/;

# Downscaler coefficients
parameter climate_region_coef(*,n)  'Estimated coefficients to link GMT and country-level mean temperatures';

#Source:  http://climexp.knmi.nl/selectfield_cmip5.cgi?id=someone@somewhere
#Ensemble mean across 19 models (all, not bias corrected)
parameter temp_region_valid_cmip5(t,n,*);

$gdxin '%datapath%data_mod_climate_regional'
$loaddc climate_region_coef
$loaddc temp_region_valid_cmip5
$gdxin


##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'


##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

VARIABLES
    TEMP_REGION(t,n)      'Near surface regional average temperature [deg.C]'
    TEMP_REGION_DAM(t,n)  'Regional pop-weighted average temperature used for damages evaluation [deg.C]'
;


##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

SCALAR   delta_tempcap  /1e-4/ ;



#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'

   eq_temp_region           # Local avg temperature downscaling equation
   eq_temp_region_dam       # Local temperature used for damages evaluation equation


##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

 eq_temp_region(t,n)$(reg(n))..
    TEMP_REGION(t,n) =E= climate_region_coef('alpha_temp',n) + (climate_region_coef('beta_temp',n)) * TATM(t);

# NOTE:
# Following Burke et al.(2015) conservative approach, here we cap maximum local temperature used
# for damages evaluation at 30°C level, the maximum observed temperature in past time series upon
# which economic response has been calibrated.
#
# A smooth GAMS approximation for  min(f(x),g(y))  is:
#    ( f(x) + g(y) - Sqrt( Sqr( f(x)-g(y) ) + Sqr(delta) ) )/2

$ifthen.tempcap %temp_region_cap%==1
* Cap active on temperatures for damages evaluation
 eq_temp_region_dam(t,n)$(reg(n))..
    TEMP_REGION_DAM(t,n)  =E=  ( TEMP_REGION(t,n) + max_temp_region_dam
                                  - Sqrt( Sqr(TEMP_REGION(t,n)-max_temp_region_dam) + Sqr(delta_tempcap) )
                               )/2  ;
$else.tempcap
* No-cap here: damages evaluated to effective local temperatures
  eq_temp_region_dam(t,n)$(reg(n)).. TEMP_REGION_DAM(t,n)  =E=  TEMP_REGION(t,n)  ;
$endif.tempcap


#=========================================================================
*   ///////////////////////     SIMULATION    ///////////////////////
#=========================================================================


##  SIMULATION HALFLOOP 1
#_________________________________________________________________________
$elseif.ph %phase%=='simulate_1'

# Here exogenous temperatures (either regional or athmospheric) may be forced into 
# model loop, if [policy] is set to -sim-exogen-temp- value.

$ifthen.exogn %exogen_temp_region% == 1
$ifthen.treg %exogen_source% == 'tatm'
# Exogenous atmospheric temeperature
  TATM.l(t) = tatm_exogen(t)  ;
  TEMP_REGION.l(t,n)  = climate_region_coef('alpha_temp',n) + (climate_region_coef('beta_temp',n)) * tatm_exogen(t)  ;
$else.treg
# Exogenous regional temeperature
  TEMP_REGION.l(t,n)  =  temp_region_exogen(t,n)  ;
$endif.treg
$else.exogn 
# Endogenous regional temperature downscaler
  TEMP_REGION.l(t,n)  = climate_region_coef('alpha_temp',n) + (climate_region_coef('beta_temp',n)) * TATM.l(t)  ;
$endif.exogn


# Following Burke et al.(2015) conservative approach, here we cap maximum local temperature used
# for damages evaluation at 30°C level, the maximum observed temperature in past time series upon
# which economic response has been calibrated.

$ifthen.tempcap %temp_region_cap%==1
* Cap active on temperatures for damages evaluation
 TEMP_REGION_DAM.l(t,n)  =  min(TEMP_REGION.l(t,n), max_temp_region_dam) ;
$else.tempcap
* No-cap here: damages evaluated to effective local temperatures
 TEMP_REGION_DAM.l(t,n)  =  TEMP_REGION.l(t,n)  ;
$endif.tempcap



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

# Parameters
climate_region_coef
temp_region_valid_cmip5
deltatemp

# Variables 
TEMP_REGION
TEMP_REGION_DAM


$endif.ph
