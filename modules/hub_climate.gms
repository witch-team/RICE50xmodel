* CLIMATE MODULE
*
* This module gathers all main climate parameters, variables and sets.
* Those will be mapped with specific climate submodules varibles.

#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================
##  CONF
#_________________________________________________________________________
* Definition of the global flags and settings specific to the module 
$ifthen.ph %phase%=='conf'

##  SETTING CONF ---------------------------------------

* CLIMATE MODULE
* | witchco2 | fair | witchghg
$setglobal climate 'fair'
$setglobal rcp 'RCP6'
$if %policy%==simulation_tatm_exogen $setglobal climate 'tatm_exogen'
$if %policy%==simulation_climate_regional_exogen $setglobal climate 'tatm_exogen'

## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

** exogenous data from RCPs
set rcp /"RCP3PD","RCP45","RCP6","RCP85"/;
set exorf /'solar','volcanic_annual','stratoz','cloud_tot','totaer_dir','fgassum','mhalosum'/;

## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

##  PARAMETERS HARDCODED OR ASSIGNED ------------------- 
PARAMETERS
   tatm0    'Initial Atmospheric Temperature change [degree C from 1850-1900]'   / 1.1 / 
   dt0       "Temperature change from 1765 (beginning year of FAIR) to reference model period (e.g. average 1850-1900)" /0.15/
   forcing_exogenous(t) "Total exogenous forcing from natural sources and exogenous oghgs [W/m2]",
   emi_gwp(*)        'Global warming potential over a time horizon of 100 years (2007 IPCC AR4) [GTonCO2eq/GTon]'
   fossilch4_frac(t,rcp) "Fraction of fossil methane emissions",
   natural_emissions(t,ghg) "Natural emissions of greenhouse gases",
   NOx_fraction(t,rcp) "Fraction of NOx emissions",
   forcing(t,rcp,*) "Total forcing from RCPs",
   emissions(t,rcp,*) "Total emissions from RCPs";

##  PARAMETERS LOADED ----------------------------------
$gdxin '%datapath%data_mod_climate'
$load emi_gwp Emissions Forcing fossilch4_frac natural_emissions NOx_fraction
$gdxin

##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

forcing_exogenous(t) = sum(exorf,Forcing(t,'%rcp%',exorf));

##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

VARIABLES
   FORC(t)      'Increase in Radiative Forcing [W/m2 from 1900]'
   TATM(t)      'Increase Temperature of Atmosphere [degrees C from 1900]'
   TOCEAN(t)    'Increase Temperature of Lower Oceans [degrees C from 1900]'
   W_EMI(ghg,t) 'World emissions [GTonC/year]'
   RF(ghg,t)    'Radiative forcing from ghg [W/m2]';

#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

# Parameters -------------------------------------------
tatm0

# Variables --------------------------------------------
FORC
TATM

$endif.ph



#===============================================================================
*     /////////////////    SUBMODULE SELECTION   ////////////////////
#===============================================================================

* Include the climate full logic (selected as global option)
* Alternatives: | witchco2 | fair | witchghg
$batinclude 'modules/mod_climate_%climate%'  %1
