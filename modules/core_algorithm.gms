

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
$setglobal convergence_tolerance 1e-1
$setglobal max_seconds 300 #5 minutes
$setglobal max_seconds 60*60 #1 hour
$setglobal max_solretry 100


## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

SETS
* Sets needed for parallelized solving procedure
    iter    'Iterations for solving'               / i1*i%maxiter% /
    v       'Variables to check for convergence'   / MIU, S /
    vcheck(v)  'Variables that are actually chacked, others just reported' / MIU, S /
    clt_problem(clt) 'Coalitions that were not solved'
    irep 'Report items for solrep' / solvestat, modelstat, ok /
;


## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

SCALAR converged    '1 if model converged, 0 otherwise'  ;
converged = 0;

PARAMETERS
    viter(iter,v,t,n)                'Keep track of last utility values to check for convergence'
    allerr(iter,v)                   'Remaining difference or error in viter values'
    max_solution_change              'Max relative diff wrt last utility values'
    max_solution_change_iter(iter)   'Max relative diff wrt last utility values'
    h(clt)                           'Model handles for parallel computing of regions'
    solrep(iter,*,irep)              'Model stats report in the non-coop case'
    solretry(iter,*)                 'Number of times a region was solved in a given iter'
    timer                            'Time elapsed at the beginning of iter'
;

solrep(iter,clt,irep) = na;
solretry(iter,clt) = 0;

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

viter
allerr
max_solution_change_iter
solrep
converged
elapsed

$endif.ph