* MODULE for MAC Curves
* using original DICE2016 or ENERDATA ones
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================
##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

# MACC CURVES formula
* | enerdata | DICE2016 |
$setglobal macc_shape 'enerdata'

* Default options
$setglobal default_macc_shape 'enerdata'


##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

VARIABLES
   ABATECOST(t,n)    'Cost of emissions reductions [Trill 2005 USD / year]'
   CPRICE(t,n)       'Carbon Price [ 2005 USD /tCO2 ]'
;
POSITIVE VARIABLES ABATECOST, CPRICE ;

# VARIABLES STARTING LEVELS ----------------------------
* to help convergence if no startboost is loaded
ABATECOST.l(t,n) = 0 ;
   CPRICE.l(t,n) = 0 ;


#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================
##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'
    eq_abatecost      # Cost of emissions reductions equation'
    eq_cprice         # Carbon price equation'


#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================
##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

ABATECOST
CPRICE


$endif.ph


#===============================================================================
*     /////////////////    SUBMODULE SELECTION   ////////////////////
#===============================================================================

* Include the MACcurves full logic (selected as global option)
* Alternatives: | enerdata | DICE2016 |
$batinclude 'modules/mod_macc_%macc_shape%'  %1
