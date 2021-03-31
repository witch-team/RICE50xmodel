*starting settings
viter(iter,v,t,n) = 0;
max_solution_change = %convergence_tolerance%;
converged = 0;

scalar debug_readyCollect;
scalar iternum;
file fx;
put fx;

*$if set debug option iterlim  = 1e5;

$if not set solvermode $setglobal solvermode nlp

*///////////////////////////////////////////////////////////////////////////////
*                                 MAIN LOOP
*///////////////////////////////////////////////////////////////////////////////
* loop on iter set
* continue looping unless "converged" becomes 1
* If max_iterations number is reached, an abort command will interrupt the loop

loop( iter$(not converged),

* Reset collection loop
clt_problem(clt) = no;
timer = TimeElapsed;

$batinclude "modules" "before_solve"



*===============================================================================
*                           NON COOPERATION CASE
*===============================================================================
* Here regions are solved in parallel on different solvelinks.
$ifthen.nc %solmode%=='noncoop'


CO2.solvelink = %solvelink%; # Solving optios
                             # i.e., < 3 > means solving in an async grid
                             # GAMS will generate model, submit to solver and then
                             # proceed in parallel without waiting for the solution.


** SUBMISSION LOOP
*..................................................
* Step 1: every coalition evaluates its best alone-solution
loop(clt$(cltsolve(clt)), # only active coalitions
    reg(nn) = yes$(mapcclt(nn));  # Set <reg> to one single region per loop and then
                                      # solve the model (every equation constrained by reg(n)
                                      # is executed only for reg-current regions )
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
        solrep(iter,clt,'ok')        =  (not ((CO2.solvestat gt 1) or (CO2.modelstat gt 2)));



        abort$handledelete(h(clt)) 'ERROR: problem deleting handles' ;   # solution should have been removed
                                                                       # at this stage!




        # :::::  CHECK IF ANY REGION HAS PROBLEM TO SOLVE  ::::: #

        if((not solrep(iter,clt,'ok')),
        # In <solrep> i have saved reference of any possible troubling region.
        # I can solve it serially to see if trouble can be overcome.


                # I give to any troubling coalition a limited number of serial attempt
                # to reach a convergence
                if( solretry(iter,clt) < %max_solretry%,
                    solretry(iter,clt) = solretry(iter,clt) + 1;


                    # Set solving region to problematic one
                    reg(nn) = yes$(mapcclt(nn));

                    # Inform the model that we are in this phase
                    # (some ad-hoc changes may help in best managing the situation)
$batinclude "modules" 'problematic_regions'

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

* Debug logic and reporting
*$batinclude modules 'debug'



* Re-run problematic regions (if any) serially
if(card(clt_problem) gt 0,
    CO2.solvelink = %solveLink.loadLibrary%;
    loop(clt_problem(clt),
        reg(nn) = yes$(mapcclt(nn));
        solve CO2 maximizing UTILITY using %solvermode%;
    );
    CO2.solvelink = %solvelink%;

    # save its result in a debug-output and terminate process
    execute_unload 'debug_infeas.gdx';
    abort 'ERROR: regions unable to be solved to optimality';
);











*===============================================================================
*                      COOPERATION CASE
*===============================================================================
* simply solve everything serially for the best shared utility
$else.nc


reg(n)$(nsolve(n)) = yes;
solve CO2 maximizing UTILITY using %solvermode%;
### solrep(iter,nsolve) = yes;
solrep(iter,nsolve,'ok') = yes$(not ((CO2.solvestat gt 1) or (CO2.modelstat gt 2))); # MODEL REPORT.
                                                            # modelstat = 1 or 2 is optimal or locally opt
                                                            # modelstat > 2 has infasibilities
                                  # solvestat = 1 is ok.
                                  # solvestat > 1 indicates some different problems


$endif.nc













*===============================================================================
*                       CONVERGENCE RULE
*===============================================================================


viter(iter,'S',t,n)$nsolve(n)   = S.l(t,n);    # Keep track of last investment values
viter(iter,'MIU',t,n)$nsolve(n) = MIU.l(t,n);  # Keep track of last mitigation values



* Evaluate distance measure for convergence
* max_solution_change among all regions and all times between eiter(i,..) and eiter(i-1,..)
max_solution_change$(ord(iter) > 1) = smax((v,t,n)$nsolve(n), abs(viter(iter,v,t,n)-viter(iter-1,v,t,n)));
max_solution_change_iter(iter) = max_solution_change;
display max_solution_change;



** Convergence rule:
* this max_solution_change must be under a specific threshold
* CONVERGENCE TOLERANCE could be set!
converged$((sum(cltsolve, solrep(iter,cltsolve,'ok')) eq card(cltsolve)) and (max_solution_change lt %convergence_tolerance%) and (iter.pos gt %miniter%)) = 1;




** Weights may change AFTER FIRST ITERATION
$if not set disentangled $if %solmode%=='coop' nweights(t,n)$((not converged)) = %calc_nweights%; display nweights;



* Update the model propagating all needed infos
$batinclude "modules" "after_solve"



* For every iteration dump current situation (even if not converged)
$if set gdxtemp put_utility 'gdxout' / 'all_data_temp_' iter.tl:0 '.gdx' ; execute_unload;




);
# end of main-loop
# ///////////////////////////////////












** FAILURE
*........................................................................
* if still converged = 0
abort$(not converged) 'Still not converged after all iterations';
