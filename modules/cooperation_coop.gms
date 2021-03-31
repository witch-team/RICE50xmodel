* COOPERATION COOP
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================

##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

$setglobal solmode 'coop'

$setglobal coalitions_t_sequence 1

$if set debug $if set debug_region $setglobal solmode 'noncoop'

## REGION WEIGHTS
* Force correct setting for noncoop and disentangled mode
$setglobal region_weights '%weighting%'
$if %disentangled%==1         $setglobal region_weights 'pop'

* Negishi weights
$iftheni.rw  %weighting% == 'negishi'
$setglobal calc_nweights ((CPC.l(t,n)**elasmu)/sum(nn, (CPC.l(t,nn)**(elasmu))))
$setglobal region_weights 'ngsw'
$else.rw
* Population weights
$setglobal calc_nweights 1
$setglobal region_weights 'pop'
$endif.rw


## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

SET clt "List of all possibly-applied coalitions" /
$include %datapath%n.inc
/;

# Control set for active coalitions
SET cltsolve(clt);
* Initialized to no 
cltsolve(clt) = yes;

# MACRO mapping between coalitions and belonging regions
$macro mapclt(n)    sameas(&clt,n)
$macro mapcclt(nn)  sameas(&clt,nn)


$endif.ph