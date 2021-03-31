# MODULE MACC DICE2016
* Uses DICE-2016 formula to se a common MAC Curve across all regions. 
#____________
# REFERENCES
* - DICE-2016 model
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================
##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'


## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

##  PARAMETERS HARDCODED OR ASSIGNED ---------- 
PARAMETERS
** Abatement cost
    expcost2  Exponent of control cost function               / 2.8  /
    pback     Cost of backstop 2010$ per tCO2 2015            / 550  /   #DICE2013: 344     #DICE2016: 550
    gback     Initial cost decline backstop cost per period   / .025 /   #DICE2013: 0.05    #DICE2016: 0.025

** Participation parameters
    periodfullpart Period at which have full participation           /21  /  #DICE2013
    partfract2010  Fraction of emissions under control in 2010       / 1  /  #DICE2013
    partfractfull  Fraction of emissions under control at full time  / 1  /  #DICE2013
;

PARAMETERS
** Backstop
    cost1(t,n)     'Adjusted cost for Backstop'
    partfract(t)   'Fraction of emissions in control regime'
    pbacktime(t)   'Backstop price'
;


##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

** PBackstop values
pbacktime(t)  =  pback*(1-gback)**(t.val-1);
cost1(t,n)    =  pbacktime(t)*sigma(t,n)/expcost2/1000;


#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================
##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

** ABATECOST AND CPRICE AS IN ORIGINAL DICE2016
eq_abatecost(t,n)$(reg(n))..
             ABATECOST(t,n)  =E=  YGROSS(t,n) * cost1(t,n) * (MIU(t,n)**expcost2)
;

eq_cprice(t,n)$(reg(n))..
                CPRICE(t,n)  =E=  pbacktime(t) * (MIU(t,n))**(expcost2-1)
;


#=========================================================================
*   ///////////////////////     SIMULATION    ///////////////////////
#=========================================================================
##  SIMULATION HALFLOOP 1
#_________________________________________________________________________
$elseif.ph %phase%=='simulate_1'

** ABATECOST AND CPRICE AS IN ORIGINAL DICE2016
ABATECOST.l(t,n)  =   YGROSS.l(t,n) * cost1(t,n) * (MIU.l(t,n)**expcost2)  ;
CPRICE.l(t,n)  =  pbacktime(t) * (MIU.l(t,n))**(expcost2-1)  ;


#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================
##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

pbacktime
cost1


$endif.ph
