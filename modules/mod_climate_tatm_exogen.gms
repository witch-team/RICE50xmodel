* EXOGEN TATM CLIMATE SUB-MODULE
*
* Athmospheric mean Temperature imposed by external data (ssp-based)
* Climate dynamics follow simple-climate specifications
* Intended for SIMULATION mainly
*____________
* REFERENCES
* - IPCC: https://unfccc.int/sites/default/files/7_knutti.reto.3sed2.pdf

#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================

##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

#setglobal results_for_fixed_tatm results_ssp2_cba_noncoop.gdx

## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

##  PARAMETERS LOADED ----------
# EXOGENOUS TATM
PARAMETER
    temp_tatm_exogen(t)   'Atmospheric temperature increase from external data [+°C]'
;

$ifthen.exo set results_for_fixed_tatm 
$gdxin %results_for_fixed_tatm%
$loaddc temp_tatm_exogen = TATM.l
$gdxin
$endif.exo
##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

$ifthen.exo not set results_for_fixed_tatm
#for now simplified trajectories for tatm
temp_tatm_exogen(t) = tatm0;
$endif.exo


##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

$if not set results_for_fixed_tatm temp_tatm_exogen(t) = tatm0;

# fix temperature
TATM.fx(t) = temp_tatm_exogen(t);
TATM.l(t) = temp_tatm_exogen(t); 

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

# parameters
temp_tatm_exogen


$endif.ph
