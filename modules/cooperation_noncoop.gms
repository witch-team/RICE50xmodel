* COOPERATION COALITIONS
* Define coalitions mappings
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================
##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

$setglobal calc_nweights 1

$setglobal coalitions_t_sequence 1


## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

SET clt "List of all possibly-applied coalitions" /
$include %datapath%n.inc
/;

SET map_clt_n(clt,n);
map_clt_n(clt,n)$sameas(clt, n) = YES;


# Control set for active coalitions
SET cltsolve(clt);
* Initialized to no 
cltsolve(clt) = yes;

#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

clt
map_clt_n

$endif.ph
