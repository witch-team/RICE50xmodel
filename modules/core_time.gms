* CORE TIME
*
* Module to state
*  - Temporal structure
*  - Fixed time periods
*  - States of the world 
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================

##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

$setglobal tfix 1

## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

SETS
    t                 'Time period nodes'  # values in time.inc included below
* Time control
    tfirst(t)         'First time period nodes'
    tsecond(t)        'Second time period node'
    tlast(t)          'Last time period nodes'
    last10(t)         'Last 10 period nodes'
;
alias(t,tt,ttt,tp1,tp2,tm1,tm2);

SET       pre(t,tp1)  'Precedence set, t is the predecessor of tp1'    ;
SET       preds(t,tt) 'Predecessors set, tt are all predecessors of t' ;
PARAMETER tperiod(t)  'Time period'                                    ;
PARAMETER year(t)     'Reference year for period t'                    ;
PARAMETER begyear(t)  'Beginning year for period t'                    ;
PARAMETER tlen(t)     'Length of time period [years]'                  ;
SCALAR    tstep       'Length of each time step [years]'       / 5 /   ;

$include %datapath%/time.inc


* Timecontrol definitions
tfirst(t)  =  yes$(t.val eq 1)          ;
tsecond(t) =  yes$(t.val eq 2)          ;
tlast(t)   =  yes$(t.val eq card(t))    ; #true if it equals t-set size (cardinality)
last10(t)  =  yes$(t.val gt card(t)-10) ;

* Fixed period nodes
set tfix(t)    'fixed period nodes';
tfix(t) = no;

* Create and load fix variable
$macro loadfix(name,idx,type) \
&type FIX&name&&idx; \
execute_load '%gdxfix%.gdx',FIX&name=&name;

* Fix variable in tfix
* ( up to card(tfix) timestep )
$macro tfixvar(name,idx) \
loadfix(name,idx,variable) \
&name.fx&&idx$tfix(t) = FIX&name.l&&idx; \
&name.l&&idx$tfix(t) = FIX&name.l&&idx;

* Fix Variable in tfix+1
* ( up to card(tfix)-1 timestep )
* ( up to card(tfix) timestep )
$macro tfix1var(name,idx) \
loadfix(name,idx,variable) \
loop((t,tfix(tp1))$pre(t,tp1), \
&name.fx&&idx = FIX&name.l&&idx; \
&name.l&&idx = FIX&name.l&&idx; \
);

* load parameter in tfix
$macro tfixpar(name,idx) \
loadfix(name,idx,parameter) \
&name&&idx$tfix(t) = FIX&name&&idx;

* combinations of fixes and regions
$macro map_nt (reg(n) and (not tfix(t)))
$macro map_nt1 (reg(n) and (not tfix(t+1)))
$macro map_t (not tfix(t))


##  FIX VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='fix_variables'

$if set gdxfix $if not set tfix $abort 'gdxfix requires tfix'
$if set gdxfix loop(t, tfix(t) = yes$(tperiod(t) le %tfix%));


#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

# Sets (excl. aliases) ---------------------------------
t
tstep
tfix

# Parameters -------------------------------------------
year


$endif.ph
