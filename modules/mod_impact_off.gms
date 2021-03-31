* IMPACT OFF SUB-MODULE
* Forces a no-impact pojection
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================
##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'


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

##  ESTIMATED YNET AND DAMAGES -------------------------
* YNET esteem
eq_ynet_estim(t,n)$(reg(n))..   YNET_ESTIMATED(t,n) =E=  YGROSS(t,n)  ;

##  EFFECTIVE DAMAGES ----------------------------------
* Effective net Damages
eq_damages(t,n)$(reg(n))..   DAMAGES(t,n)  =E=  0 ;
* Effective Damages as fraction of YGROSS
eq_damfrac(t,n)$(reg(n))..   DAMFRAC(t,n)  =E= 0 ;


#=========================================================================
*   ///////////////////////     SIMULATION    ///////////////////////
#=========================================================================

##  SIMULATION HALFLOOP 1
#_________________________________________________________________________
$elseif.ph %phase%=='simulate_1'
 
##  ESTIMATED YNET AND DAMAGES -------------------------
* Bounded YNET esteem
 YNET_ESTIMATED.l(t,n) =  YGROSS.l(t,n)  ;
##  EFFECTIVE DAMAGES ----------------------------------
* Effective net Damages
 DAMAGES.l(t,n)  =  0 ;
* Effective Damages as fraction of YGROSS
 DAMFRAC.l(t,n)  = 0 ;


$endif.ph
