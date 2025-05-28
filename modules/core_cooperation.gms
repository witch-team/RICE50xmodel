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

# This is to be sure to initialize the sequence
$setglobal coalitions_t_sequence 1

## REGION WEIGHTS
$if %region_weights% == 'negishi' $setglobal calc_nweights ((CPC.l(t,n)**elasmu)/sum(nn, (CPC.l(t,nn)**(elasmu))))

* Population weights
$if %region_weights% == 'pop' $setglobal calc_nweights 1

$setglobal sel_coalition "g7brics"

## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

* Some pre-defined coalitions
* in a policy file this set can be extended with new coalitions

SET clt "List of all possibly-applied coalitions" /
$include %datapath%n.inc
/;

# map set for coalitions to native regions
SET map_clt_n(clt,n);
map_clt_n(clt,n) = no;

# Control set for active coalitions
SET cltsolve(clt);
cltsolve(clt) = no;

$ifthen.coop %cooperation%=="coop"

SET clt / grand /; # add grand coalition

map_clt_n('grand',n) = yes;
cltsolve('grand') = yes;

$elseif.coop %cooperation%=="noncoop"

map_clt_n(clt,n)$sameas(clt, n) = YES;
cltsolve(clt) = yes;

$elseif.coop %cooperation%=="coalitions"

$batinclude "coalitions/coal_%sel_coalition%.gms"

$else.coop 
abort 'Cooperation mode not defined';
$endif.coop


#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

Parameter reorder_clt(clt);

#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

clt
map_clt_n
cltsolve


$endif.ph
