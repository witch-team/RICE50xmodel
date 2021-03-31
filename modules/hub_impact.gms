# IMPACT MODULE
* This module gathers all main impact parameters, variables and sets.
* Those will be mapped with specific impact submodules varibles.
*
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================

##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

# DAMAGE CAP
* GDP baseline multiplier (i.e., max_gain=2 -> maximum gains are 2x GDPbase)
$setglobal max_gain    2
$setglobal max_damage  1e-4


##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

VARIABLES
    DAMAGES(t,n)             'Damages [Trill 2005 USD / year]'
    DAMFRAC(t,n)             'Damages as GDP Gross fraction [%GDPgross]: (-) damages (+) gains'
    YNET_ESTIMATED(t,n)      'Potential GDP net of damages [Trill 2005 USD / year]'
;
POSITIVE VARIABLES  YNET_ESTIMATED;

# VARIABLES STARTING LEVELS ----------------------------
* to help convergence if no startboost is loaded
DAMAGES.l(t,n) = 0 ;
DAMFRAC.l(t,n) = 0 ;
YNET_ESTIMATED.l(t,n) = ykali(t,n) ;


#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'
    eq_damages        # Damages equation
    eq_damfrac        # Equation for Damages as GDP fraction
    eq_ynet_estim     # Potential GDP net of damages equation


#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================
##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

# Variables --------------------------------------------
DAMAGES
DAMFRAC
YNET_ESTIMATED


$endif.ph


#===============================================================================
*     /////////////////    SUBMODULE SELECTION   ////////////////////
#===============================================================================

* Include the impact full logic (selected as global option)
* Alternatives: | off | dice | burke | dell | kahn |
$batinclude 'modules/mod_impact_%impact%'  %1
