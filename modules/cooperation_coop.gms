* COOPERATION COALITIONS
* Define coalitions mappings
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================

##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

* REGION WEIGHTS
* | negishi | pop |
$setglobal region_weights 'pop'

$setglobal solmode 'coop'

$setglobal coalitions_t_sequence 1

## REGION WEIGHTS
$if %region_weights% == 'negishi' $setglobal calc_nweights ((CPC.l(t,n)**elasmu)/sum(nn, (CPC.l(t,nn)**(elasmu))))

* Population weights
$if %region_weights% == 'pop' $setglobal calc_nweights 1


## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

SET clt "List of all possibly-applied coalitions" /
*$include %datapath%n.inc
grand
/;

SET map_clt_n(clt,n) "Mapping set between coalitions and belonging regions";
map_clt_n('grand',n) = yes;

# Control set for active coalitions
SET cltsolve(clt);
* Initialized to no
cltsolve('grand') = yes;

#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

clt
map_clt_n

$endif.ph
