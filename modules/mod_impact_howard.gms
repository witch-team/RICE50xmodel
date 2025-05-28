* IMPACT  SUB-MODULE
** A Howard and Sterner-like impact is uniformly applied across all regions
* based on preferred specification (4) in Table 2.
*____________
* REFERENCES
* - Howard, Peter H., and Thomas Sterner. ‘Few and Not So Far Between: A Meta-Analysis of Climate Damage Estimates’. 
* Environmental and Resource Economics 68, no. 1 (1 September 2017): 197–225. https://doi.org/10.1007/s10640-017-0166-z.
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
   a2       'Damage quadratic term'                     / 0.595   /
   a3       'Damage exponent'                           / 2.00    /
;

#add 25% to the coefficient for accountign for catastrophic damages
a2 = a2 * 1.25;
#convert to percentages 
a2 = a2 / 100;

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

 eq_omega(t,n)$(reg_all(n) and not tfirst(t))..   OMEGA(t,n)  =E=  ( (a1 * TATM(t)) + (a2 * power(TATM(t),a3)) ) - 
                                                               ( (a1 * TATM('2')) + (a2 * power(TATM('2'),a3)) ) ;


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
