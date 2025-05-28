* IMPACT DICE SUB-MODULE
** A DICE2016-like impact is uniformly applied across all regions
*____________
* REFERENCES
* - Nordhaus, William. "Projections and Uncertainties about Climate Change in an Era of Minimal Climate Policies". 
* American Economic Journal: Economic Policy 10, no. 3 (1 August 2018): 333–60. https://doi.org/10.1257/pol.20170046.
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
* DICE-2016 damage coefficient
   a1       'Damage intercept'                          / 0       /
   a2       'Damage quadratic term'                     / 0.00236 /
   a3       'Damage exponent'                           / 2.00    /
;


##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'


## List of equations
#_________________________________________________________________________
$elseif.ph %phase%=='eql'

eq_omega


##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

 eq_omega(t,n)$(reg_all(n) and not tfirst(t))..   OMEGA(t,n)  =E=  ( (a1 * TATM(t)) + (a2 * power(TATM(t),a3)) ) - ( (a1 * TATM('2')) + (a2 * power(TATM('2'),a3)) ) ;


#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

# parameters
a1
a2
a3


$endif.ph
