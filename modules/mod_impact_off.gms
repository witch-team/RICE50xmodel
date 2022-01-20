* IMPACT OFF SUB-MODULE
* Forces a no-impact pojection
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================
##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

 OMEGA.fx(t,n) = 0;



##  EQUATION LIST
#_________________________________________________________________________
* List of equations
* One per line.
$elseif.ph %phase%=='eql'


##  EQUATIONS
#_________________________________________________________________________
* In the phase EQS, you can include new equations to the model.
* The equations are always included.
* Best practice : - condition your equation to be able to do a run with t_fix(t) 
$elseif.ph %phase%=='eqs'


$endif.ph
