*starting settings
viter(iter,v,t,n) = 0;
allerr(iter,v) = tolerance(v);
converged = 0;

scalar debug_readyCollect;
scalar iternum;
file fx;
put fx;

$if not set solvermode $setglobal solvermode nlp

*///////////////////////////////////////////////////////////////////////////////
*                                 MAIN LOOP
*///////////////////////////////////////////////////////////////////////////////
* loop on iter set
* continue looping unless "converged" becomes 1
* If max_iterations number is reached, an abort command will interrupt the loop

$if set debug_presolve execute_unload "debudg_presolve_%nameout%.gdx"; abort "Let's see what's wrong...";

loop(iter$(not converged),

* Reset collection loop
clt_problem(clt) = no;
timer = TimeElapsed;

$batinclude "modules" "before_solve"


CO2.solvelink = %solvelink%; # Solving optios
                             # i.e., < 3 > means solving in an async grid
                             # GAMS will generate model, submit to solver and then
                             # proceed in parallel without waiting for the solution.

** SUBMISSION LOOP
*..................................................
* Step 1: every coalition evaluates its best alone-solution
$if set onlysolve cltsolve(clt) = no; cltsolve('%onlysolve%') = yes;
loop(clt$(cltsolve(clt)), # only active coalitions

    reg(nn) = yes$map_clt_n(clt,nn);  # Set <reg> to one single region per loop and then
                                      # solve the model (every equation constrained by reg(n)
                                      # is executed only for reg-current regions )
    reg_all(nn) = yes$reg(nn);           # by default, also equations constrained by reg_all are active only for the solving clt
$if set see_other_climates reg_all(nn) = yes; #this options makes it as such that the other regions can see climate and damage related state variables.       
                                           #decreases computational speed but increases feasibility.

    solve CO2 maximizing UTILITY using %solvermode%;
    h(clt) = CO2.handle;  # Model-attribute <handle> contains an unique identification for each submitted
                        # solution. The handle values stored in h(c) are then used to collect
                        # solutions once processes are completed.
);






** COLLECTION LOOP
*..................................................
* Completed jobs are collected until:
* no more pending jobs left (card(h) is 0) OR timeout expires
repeat

    debug_readyCollect = readyCollect(h);  # Waits until a model solution is ready to be collected.
                                           #  0: One or more of the requested jobs is/are ready
                                           #  1: There is no active job to wait for.
                                           # >1: Troubles!
    abort$(debug_readyCollect gt 1) 'ERROR: problem waiting for coalition to solve';



    ## Handle-collect loop
    loop(clt$(cltsolve(clt) and handlecollect(h(clt))), # HandleCollect tests for the solution status:
                                                # 1: solution available
                                                # 0: otherwise

        execute_loadhandle CO2;  # Update GAMS database with solution for the current instance of CO2-model

        solrep(iter,clt,'solvestat') = CO2.solvestat;  # save solvestat  (1 is ok)
        solrep(iter,clt,'modelstat') = CO2.modelstat;  # save modelstat  (1 or 2 is optimal or locally opt)
        solrep(iter,clt,'feas')      =  ( (CO2.solvestat eq 1 or CO2.solvestat eq 4) and ((CO2.modelstat eq 1) or (CO2.modelstat eq 2) or (CO2.modelstat eq 7)));
        solrep(iter,clt,'opt')       =  ( (CO2.solvestat eq 1) and ((CO2.modelstat eq 1) or (CO2.modelstat eq 2)));




        abort$handledelete(h(clt)) 'ERROR: problem deleting handles' ;   # solution should have been removed
                                                                       # at this stage!




        # :::::  CHECK IF ANY REGION HAS PROBLEM TO SOLVE  ::::: #
        # enter the serial loop if regions are infeasible OR not optimal but converged
        if( (not solrep(iter,clt,'feas') or 
                ( (ord(iter) ge %miniter%) and  
                (sum(v$vcheck(v), allerr(iter,v) lt tolerance(v)) eq card(vcheck)) and 
                not solrep(iter,clt,'opt')) ),
        # In <solrep> i have saved reference of any possible troubling region.
        # I can solve it serially to see if trouble can be overcome.


                # I give to any troubling coalition a limited number of serial attempt
                # to reach a convergence
                if( solretry(iter,clt) < %max_solretry%,
                    solretry(iter,clt) = solretry(iter,clt) + 1;

                    # Set solving region
                    reg(nn) = yes$map_clt_n(clt,nn);
                    reg_all(nn) = yes$reg(nn);           # by default, also equations constrained by reg_all are active only for the solving clt
$if set see_other_climates reg_all(nn) = yes; #this options makes it as such that the other regions can see climate and damage related state variables.       
                                           #decreases computational speed but increases feasibility.

                    # Launch serially the model
                    solve CO2 maximizing UTILITY using %solvermode%;
                    h(clt) = CO2.handle;  # Model-attribute <handle> contains an unique identification for each submitted
                                        # solution. In this way i notify the <handlecollect(h)> of the inner loop i've
                                        # finished my serial solving.


                # Aaargh! Some coalition has run out of its allowed serial attempts!
                else
                    h(clt) = no;
                    clt_problem(clt) = yes; # save coalition in "problem" shame-list
                );

        # Region solved correctly
        else
            h(clt)=0;
        ); # end of problematic coalitions management
    );# end of handlecollect loop


until ((card(h) eq 0) or ((timeelapsed-timer) gt %max_seconds%));
# END of collection loop
* Completed jobs are collected until:
* EITHER no more pending jobs left (card(h) is 0) OR timeout expires




** POST-COLLECTION
*..................................................
* Check that every parallel job has been managed properly

* If card(h) is not empty at this stage,
* it means that timeout has expired.
abort$(card(h) gt 0) 'ERROR: TIME OUT, %max_seconds% seconds elapsed and not all solves are complete';

if(card(clt_problem) gt 0,
    execute_unload 'debug_%nameout%.gdx';
    display 'The following regions have not been solved to feasibility:';
    display clt_problem;
$if %abort_if_infeasible%=="yes"  abort 'ERROR: regions unable to be solved to feasibility';
$if %abort_if_infeasible%=="no"   display 'CAREFUL: at this iteration, some regions were infeasible';

);


*===============================================================================
*                       CONVERGENCE RULE
*===============================================================================

* Update the model propagating all needed infos
$batinclude "modules" "after_solve"

* consider relative change across iterations
savediff(t,n,iter,v)$(vcheck(v))= abs(viter(iter,v,t,n)-viter(iter-1,v,t,n));
allerr(iter,v) = smax((t,n)$(not t5last(t)), savediff(t,n,iter,v)); 

** Convergence rule:
* 1) all regions are optimal
* 2) all variable variation is below tolerance
* 3) iterations are below minimum
converged$(
$if %policy%=="cbudget_regional" $if %burden%=="cost_efficiency" ( abs(cbudget_2020_2100 - ctax_target_rhs) le %conv_budget%) and
    (sum(cltsolve, solrep(iter,cltsolve,'opt')) eq card(cltsolve)) and 
    (sum(v$vcheck(v), allerr(iter,v) lt tolerance(v)) eq card(vcheck)) and 
    (ord(iter) ge %miniter%))
    = 1;

** Weights may change AFTER FIRST ITERATION
$if %region_weights% == 'negishi' nweights(t,n)$((not converged)) = %calc_nweights%;

* For every iteration dump current situation (even if not converged)
$if set all_data_temp put_utility 'gdxout' / 'all_data_temp_%nameout%.gdx' ; execute_unload;

);
# end of main-loop

** FAILURE
*........................................................................
* if still converged = 0
execute_unload$(not converged) 'debug_%nameout%.gdx';
abort$(not converged) 'Still not converged after all iterations';
