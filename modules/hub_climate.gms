* HUB CLIMATE 
* ----------------------
* This module gathers all main climate parameters, variables and sets.
* Those will be mapped with specific climate submodules varibles.

#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================
##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

* Climate module to add
* | DICE2016 | cbsimple | witchco2 |
$setglobal climate 'witchco2'
* Default options
$setglobal default_climate 'witchco2'


## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'


## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

PARAMETERS
   tatm0    'Initial Atmospheric Temperature change [degree C from 1900]'   /0.85 / #DICE2013: 0.80    #DICE2016: 0.85
   tocean0  'Initial Lower Stratum Temperature change [degree C from 1900]' /.0068/ #DICE2013: 0.0068  #DICE2016: 0.0068
;


##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'


##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

VARIABLES
   FORC(t)     'Increase in Radiative Forcing [W/m2 from 1900]'
   TATM(t)     'Increase Temperature of Atmosphere [degrees C from 1900]'
   TOCEAN(t)   'Increase Temperature of Lower Oceans [degrees C from 1900]'
;

# VARIABLES STARTING LEVELS 
* to help convergence if no startboost is loaded
  TATM.l(t) = tatm0   ; 
TOCEAN.l(t) = tocean0 ; 


##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

TATM.UP(t)         =  40     ;
TATM.LO(t)         = -10     ;
TATM.fx(tfirst)    = tatm0   ;

TOCEAN.UP(t)       =  20     ;
TOCEAN.LO(t)       = -1      ;
TOCEAN.FX(tfirst)  = tocean0 ;


#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'

   eq_forc         # Radiative Forcing equation
   eq_tatm         # Temperature-climate equation for Atmosphere
   eq_tocean       # Temperature-climate equation for Lower Oceans


#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  GDX ITEMS
$elseif.ph %phase%=='gdx_items'

# Parameters -------------------------------------------
tatm0
tocean0

# Variables --------------------------------------------
FORC
TATM
TOCEAN


$endif.ph



#===============================================================================
*     /////////////////    SUBMODULE SELECTION   ////////////////////
#===============================================================================

* Include the climate full logic (selected as global option)
* Alternatives: | DICE2016 | cbsimple | witchco2 |
$batinclude 'modules/mod_climate_%climate%'  %1
