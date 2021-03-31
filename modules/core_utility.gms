* MODULE UTILITY
*
* Utility function as measure of welfare.
*____________
* REFERENCES
* Berger, Loïc, and Johannes Emmerling. ‘Welfare as Equity Equivalents’. Journal of Economic Surveys 34, no. 4 (26 August 2020): 727–752. https://doi.org/10.1111/joes.12368.
*
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================
##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

##  SETTING CONF ---------------------------------------
# These can be changed by the user to explore alternative scenarios

# DISENTANGLE PARAMETER
# | 1 = EZ Disentangled welfare | 0 = DICE welfare|
$setglobal disentangled 1 
* Inequality aversion
* Range: [0,1.5]; good options: | 0 | 0.5 | 1.45 | 2 |
$setglobal gamma 0.5

# WELFARE GDP-ADJUSTMENT
* | PPP | MER |
$setglobal gdpadjust 'PPP'

# UTILITY SCALING COEFFICIENTS
* these are unnecessary for the calculations but help optimizer covergence.
$setglobal dsnt_scale1   1e-8
$setglobal dsnt_scale2   0
$setglobal dice_scale1   1e-4   #DICE2013: 0.016408662    #DICE2016: 0.0302455265681763
$setglobal dice_scale2   0      #DICE2013: -3855.106895   #DICE2016: -10993.704


## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

* Scaling options to help convergence
PARAMETERS
   dice_scale1  'Scaling factor'    / %dice_scale1% /
   dice_scale2  'Scaling factor'    / %dice_scale2% /
   dsnt_scale1  'Scaling factor'    / %dsnt_scale1% /
   dsnt_scale2  'Scaling factor'    / %dsnt_scale1% /

   gamma  'Inequality aversion' / %gamma% /
;

PARAMETERS
   welfare_gdpadj(t,n)   'Welfare GDP conversion factor: from PPP to %gdpadjust%'
   nweights(t,n)         'Weights used in the welfare of the cooperative solution'
;

##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

# WEIGHTS ----------------------------------------------
* Initialized at 1,
* they change in the 'solve_region' file AFTER FIRST ITERATION
nweights(t,n) = 1;




# GDP ADJUSTMENT ---------------------------------------
* according to selected gdpadjust determine correct conversion factor

# NOTE ......................................................
# The conversion factor applies only in welfare-utility
# evaluation. The whole model and its output variables
# are still only and always referred to a PPP gdp adjustment.
#............................................................
$ifthen.wfadj  %gdpadjust%=='MER'
* PPP to MER conversion needed
   welfare_gdpadj(t,n) = ppp2mer(t,n)  ;
$else.wfadj
* no conversion needed
   welfare_gdpadj(t,n) = 1 ;
$endif.wfadj


##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

VARIABLES
   PERIODU(t,n)      'One period utility function'
   CEMUTOTPER(t,n)   'Period utility'
   TUTILITY(t)       'Intra-region utility'
   UTILITY           'Welfare function'
;


##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'

TUTILITY.lo(t) = 1e-3 ; # needed because of eq_utility (disentangled)


#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATION LIST
#_________________________________________________________________________
$elseif.ph %phase%=='eql'

$ifthen.wf %disentangled%==1
   eq_welfare        # Welfare equation based on disentangled Epstein-Zin prefs
   eq_util           # Welfare equation based on disentangled Epstein-Zin prefs
$else.wf
   eq_cemutotper     # Period utility
   eq_periodu        # Instantaneous utility function equation
   eq_util           # Objective function
$endif.wf


##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

* Disentangled welfare function
$ifthen.wf %disentangled%==1
eq_welfare(t).. TUTILITY(t)  =E=  sum(n$reg(n),  pop(t,n)/sum(nn$reg(nn),pop(t,nn))  *  ((CPC(t,n)*welfare_gdpadj(t,n))**(1-gamma))  );

eq_util.. UTILITY  =E=  sum(t, ( ( (TUTILITY(t)**((1-elasmu)/(1-gamma))) / (1-elasmu) ) - 1 )  * rr(t) )
                    *   tstep
                    *   dsnt_scale1
                    +   dsnt_scale2  ;

$else.wf
* Original DICE welfare function adapted to multiregion
eq_cemutotper(t,n)$(reg(n))..  CEMUTOTPER(t,n)  =E=  PERIODU(t,n) * rr(t) * pop(t,n)  ;

eq_periodu(t,n)$(reg(n))..  PERIODU(t,n)  =E=  ( (CPC(t,n)*welfare_gdpadj(t,n))**(1-elasmu) - 1)/(1-elasmu) - 1  ;

eq_util..   UTILITY   =E=  (dice_scale1 * tstep * sum((t,n)$map_nt, nweights(t,n)*CEMUTOTPER(t,n) )) + dice_scale2  ;
$endif.wf


#=========================================================================
*   ///////////////////////     SIMULATION    ///////////////////////
#=========================================================================

##  SIMULATION HALFLOOP 2
#_________________________________________________________________________
$elseif.ph %phase%=='simulate_2'

$ifthen.wf %disentangled%==1
TUTILITY.l(t)  =  sum(n$reg(n),  pop(t,n)/sum(nn$reg(nn),pop(t,nn))  *  ((CPC.l(t,n)*welfare_gdpadj(t,n))**(1-gamma))  );
$else.wf
PERIODU.l(t,n)  =  ( (C.l(t,n)*welfare_gdpadj(t,n)*1000/pop(t,n))**(1-elasmu) - 1 )/(1-elasmu) - 1  ;
CEMUTOTPER.l(t,n)  =  pop(t,n) * PERIODU.l(t,n) * rr(t)   ;
$endif.wf


##  AFTER SIMULATION
#_________________________________________________________________________
$elseif.ph %phase%=='after_simulation'

$ifthen.wf %disentangled%==1
* Disentangled welfare function
 UTILITY.l  =  sum(t, ( ( (TUTILITY.l(t)**((1-elasmu)/(1-gamma))) / (1-elasmu) ) - 1 )  * rr(t) )
            *   tstep
            *   dsnt_scale1
            +   dsnt_scale2  ;
$else.wf
* Original DICE welfare function adapted to multiregion
UTILITY.l   =  (dice_scale1 * tstep * sum((t,n)$map_nt,  nweights(t,n)*CEMUTOTPER.l(t,n))) + dice_scale2  ;
$endif.wf


#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

# Parameters -------------------------------------------
nweights
$if %disentangled%==1 gamma

# Variables --------------------------------------------
UTILITY


$endif.ph
