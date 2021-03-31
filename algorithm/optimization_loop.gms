$if not "%1"=="1" $abort "Starting time in [coalition_t_sequence] is not -1- (as it should be!)"

# Generate equations list 
EQUATIONS
$batinclude "modules" "eql"
;

# Generate equations logic
$batinclude "modules" "eqs"

MODEL  CO2 /
$batinclude "modules" "eql"
/;
CO2.optfile = 1;
CO2.holdfixed = 1;
CO2.SCALEOPT = 1;

# ................................................
# PROGRESSIVE OPTIMIZATIONS LOOOP 
# ................................................
$label loop0
$if "a%1"=="a" $goto loop1
 
# Fixing variables loading last gdxfix intermediate solution
# Not avaiilable durng first iteraton: skip it
$ifthen.skipfirst not "a%1" == "a1"
$setglobal tfix %1

* <ondotl> option activates or deactivates the automatic addition 
* of the attribute .L to variables on the right-hand side of assignments. 
* It is most useful in the context of macros
$ondotl
$batinclude "modules" 'fix_variables'
$offdotl
$endif.skipfirst


##  SOLVING OPTIONS
#_________________________________________________________________________
# PARALLELIZATION
#.........................................................................
# See https://www.gams.com/latest/docs/UG_GamsCall.html#GAMSAOsolvelink
# AsyncThreads := in-memory parallel (6)
# AsyncGrid    := in-file parallel (3)
# loadLibrary  := in-memory serial (5)
# chainScript  := in-file serial (0)
#.........................................................................
$setglobal solvelink %solvelink.AsyncThreads%
*$setglobal solvelink %solvelink.AsyncGrid%
*$setglobal solvelink %solveLink.loadLibrary%
*$setglobal solvelink %solveLink.chainScript%

# SOLVER OPTIONS
$setglobal iterlim 99900
option sysout     = on        ;
option solprint   = on        ;
option iterlim    = %iterlim% ;
option reslim     = 99999     ;
option solprint   = on        ;
option limrow     = 0         ;
option limcol     = 0         ;

* prints solution listing when asynchronous solve (Grid/Threads) is used
$if set debug option AsyncSolLst = 1;


##  LAUNCH SOLVER
#_________________________________________________________________________
$batinclude "algorithm/solve_regions"

* if errived here solve was successful
* Store result as gdxfix in temp folder
$if set gdxfix execute_unload "%gdxfix%.gdx"
* In debug-mode save all intermediate-coalition results
$if set debug $if set gdxfix execute_unload "%gdxfix%_%1.gdx"

$shift
$goto loop0
# ................................................
# END PROGRESSIVE OPTIMIZATIONS LOOOP 
# ................................................
$label loop1
;