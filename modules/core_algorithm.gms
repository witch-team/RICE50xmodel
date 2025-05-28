

# CORE ALGORITHM
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================
##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

# CONVERGENCE
* Maximum number of iterations
$setglobal maxiter 100
* Minimum number of iterations
$setglobal miniter 4
$setglobal convergence_tolerance 1e-2 #max 1% variation of normalization factor across iterations (e.g. 1% of baseline emissions)
$setglobal max_seconds 60*60 #1 hour
$setglobal max_solretry 100
$setglobal abort_if_infeasible "yes" #yes | no . If no, model will keep iterating even if some regions are infeasible

## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

SETS
* Sets needed for parallelized solving procedure
    iter    'Iterations for solving'               / i1*i%maxiter% /
    v       'Variables to check for convergence (they should be normalized, not absolute values)'   / MIU, S, Y, TATM /
    vcheck(v)  'Variables that are actually chacked, others just reported' / MIU, S, Y, TATM /
    clt_problem(clt) 'Coalitions that were not solved'
    irep 'Report items for solrep' / solvestat, modelstat, feas, opt /
;

SET resolve_regions(iter) 'iterations for which to try and resolve non-feasible or non-optimal regions after each parallel bunch of solving';
resolve_regions(iter) = no;
$if not set avoid_resolving resolve_regions(iter) = yes;

## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

SCALAR converged    '1 if model converged, 0 otherwise'  ;
converged = 0;

PARAMETERS
    viter(iter,v,t,n)                'Keep track of last utility values to check for convergence'
    savediff(t,n,iter,v)             'Relative difference between iterations of variable of interest (absolute if zero in previous iter)'
    allerr(iter,v)                   'Remaining difference or error in viter values'
    tolerance(v)                     'Convergence tolerance for each variable'
    h(clt)                           'Model handles for parallel computing of regions'
    solrep(iter,*,irep)              'Model stats report in the non-coop case'
    solretry(iter,*)                 'Number of times a region was solved in a given iter'
    timer                            'Time elapsed at the beginning of iter'
;

solrep(iter,clt,irep) = na;
solretry(iter,clt) = 0;
tolerance(v) = %convergence_tolerance%;

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

viter
savediff
allerr
solrep
converged
elapsed

$endif.ph