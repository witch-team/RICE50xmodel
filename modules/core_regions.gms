
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
alias(n,nn,nnn,nnnn);

* Subset regulating how many countries to solve
* (according to the debug flag presence)
set nsolve(n)   'Which regions must be solved across n set';
$if set debug nsolve(n) = yes$(sameas(n,'%debug_region%'));
$if not set debug nsolve(n) = yes;

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


$ifthen %n%=="ed57"
SET eu27(n) "European Union members" /
aut  # Austria
bel  # Belgium
bgr  # Bulgaria
cro  # Croatia
dnk  # Denmark
esp  # Spain
fin  # Finland
fra  # France
grc  # Greece
hun  # Hungary
irl  # Ireland
ita  # Italy
nld  # Netherlands
pol  # Poland
prt  # Portugal
rcz  # Czech Republic
rfa  # Germany
rom  # Romania
rsl  # Slovakia
slo  # Slovenia
swe  # Sweden
blt  # Baltic states: Finland, Estonia, Latvia
/;
$endif


#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'
n


$endif.ph


