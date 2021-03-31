* MODULE LAND USE
* To assess how much emissions are coming from Land Use.
* Temporarily based on a distributed version of DICE2016 process.

#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================

##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'


## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

set yearlu /1850*2300/;

## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

PARAMETERS
** LU-Baseline
   eland0(n)        'Carbon emissions from land in 2015 [GtCO2/year]'
   deland           'Decline rate of land emissions (per period)'         / .115  /
   eland_bau(*,t,n) 'Carbon emissions baselines from land [GtCO2/year]'
;

* Historical EMISSIONS
PARAMETER q_emi_valid_primap(*,yearlu,n)  'Historical Emissions per each region [GtC]';
$gdxin  '%datapath%data_historical_values'
$load   q_emi_valid_primap
$gdxin


##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

* starting value averaged over last 10 year ( to minimize risk of high fluctuations)
eland0(n)  = CtoCO2 * sum(yearlu, q_emi_valid_primap('co2lu',yearlu,n)$((yearlu.val ge 2005) and (yearlu.val lt 2015))) / 10  ;

loop(t,
* UNIFORM LOGIC
    eland_bau('uniform',t,n)  =  eland0(n)*(1-deland)**(t.val-1) ;
* DIFFERENTIATED
    # if negative, it remains fixed to its value
    # otherwise smmoth decreasing at DICE2016 rate.
    eland_bau('differentiated',t,n)  =  min(eland0(n)*(1-deland)**(t.val-1), eland0(n) ) ;
);

* global values
PARAMETER global_eland_bau(*,t);
  global_eland_bau('uniform',t)  = sum(n, eland_bau('uniform',t,n))    ;
  global_eland_bau('differentiated',t)  = sum(n, eland_bau('differentiated',t,n))   ;

PARAMETER cumeland_bau(*,t,n), global_cumeland_bau(*,t);
cumeland_bau('uniform','1',n)= 0;
cumeland_bau('differentiated','1',n)= 0;

loop(t,
 cumeland_bau('uniform', t+1, n) =  cumeland_bau('uniform', t, n) + eland_bau('uniform',t,n);
 cumeland_bau('differentiated', t+1, n) =  cumeland_bau('differentiated', t, n) + eland_bau('differentiated',t,n);
);

global_cumeland_bau('uniform',t) = sum(n, cumeland_bau('uniform',t,n)) ;
global_cumeland_bau('differentiated',t) = sum(n, cumeland_bau('differentiated',t,n)) ;


##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

VARIABLES    ELAND(t,n)     'Land-use emissions   [GtCO2/year]';


##  COMPUTE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='compute_vars'


$ifthen.lu set bau_no_impacts
# For BAU scenario take the DICE-like baselines (pessimistic)
ELAND.fx(t,n)  =  eland_bau('uniform',t,n)  ;
$elseif.lu '%policy%'=='bau-impacts'
# For BAU-IMPACTS scenario take the DICE-like baselines (pessimistic)
ELAND.fx(t,n)  =  eland_bau('uniform',t,n)  ;
$else.lu
# For any other policy (mitigative) take more ambitious and realistic baselines
ELAND.fx(t,n)  =  eland_bau('differentiated',t,n)  ;
$endif.lu


#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

# Parameters 
eland0
deland
# Variables
ELAND


$endif.ph

