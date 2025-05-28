
* MODULE REGIONS
*
* Contains all starting data and main dynamics for model regions
*
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================
##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

$include %datapath%regions.conf


## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

SET n 'Regions' /
$include %datapath%n.inc
/;

$include %datapath%regions.inc

set   reg(n)     'Active regions to be solved' ;
set   reg_all(n)     'Regional equations that are active also for non-solving coalition' ;

alias(n,nn,nnn,nnnn);

* Subset regulating how many countries to solve
set nsolve(n)   'Which regions must be solved across n set';
$if set onlysolve nsolve(n) = yes$(sameas(n,'%onlysolve%'));
$if not set onlysolve nsolve(n) = yes;

* no limits for the moment
reg(n) = yes;

* Baseline experiments dimensions
SETS
    dice_curve "altenative reference curves"       / original, discounted /
    trns_type  "transition type towards DICE"      /    linear_pure,
                                                        linear_soft,
                                                        sigmoid_HHs,
                                                        sigmoid_Hs,
                                                        sigmoid_Ms,
                                                        sigmoid_Ls,
                                                        sigmoid_LLs  /
    trns_end  "year of convergence to DICE"        / 28, 38, 48, 58 /
;


#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'
n
eu

$endif.ph


