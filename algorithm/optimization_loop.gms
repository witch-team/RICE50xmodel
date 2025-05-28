$if not "%1"=="1" $abort "Not set starting-time <t=1> in coalitions_t_sequence"

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
CO2.SCALEOPT = 1;

option cns            = conopt3   ; #specify conopt3 for CNS solver

* fix relevant climate variable to bau run first iteration climate model
$if set mod_sai W_SAI.fx(t) = sum(n,N_SAI.l(t,n));

$ifthen.climate %climate%=="fair"

model fair / eq_reslom,eq_concco2,eq_catm,eq_cumemi,eq_csinks,eq_concghg,eq_methoxi,
             eq_forcco2,eq_forcch4,eq_forcn20,eq_forcoghg,
             eq_forco3trop,eq_forcing,eq_forch2o,
             eq_tatm,eq_tslow,eq_tfast,eq_irflhs,eq_irfrhs     /;

* fix W_EMI to bau run
W_EMI.fx(ghg,t) = sum(n, E.l(t,n,ghg)
$if set mod_emission_pulse           + emission_pulse(ghg,t)                                     
);
FF_CH4.fx(t) = FF_CH4.l(t);

* initialize climate variables to BAU run
solve fair using cns; 

FF_CH4.lo(t) = 0;
FF_CH4.up(t) = 1;

$elseif.climate %climate%=="witchco2"

model witchco2 / eq_wcum_emi_co2,eq_rf_co2,eq_rf_oghg,eq_forc,eq_tatm,eq_tocean/;

* fix W_EMI to bau run
W_EMI.fx('co2',t) = sum(n, E.l(t,n,'co2')
$if set mod_emission_pulse           + emission_pulse('co2',t)                                     
) /   wemi2qemi('co2');

* initialize climate variables to BAU run
solve witchco2 using cns; 


$elseif.climate %climate%=="witchghg"

model witchghg / eq_wcum_emi_co2,eq_wcum_emi_oghg,eq_rf_co2,eq_rf_oghg,eq_forc,eq_tatm,eq_tocean/;

* fix W_EMI to bau run
W_EMI.fx(ghg,t) = sum(n, E.l(t,n,ghg)
$if set mod_emission_pulse           + emission_pulse(ghg,t)                                     
) / wemi2qemi(ghg);

* initialize climate variables to BAU run
solve witchghg using cns; 

$endif.climate

* unconstrain relevant climate variables
W_EMI.lo(ghg,t) = -inf;
W_EMI.up(ghg,t) = inf;
$if set mod_sai W_SAI.lo(t) = 0;
$if set mod_sai W_SAI.up(t) = +inf;

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
option sysout         = on        ;
option solprint       = on        ;
option iterlim        = %iterlim% ;
option reslim         = 99999     ;
option solprint       = on        ;
option limrow         = 0         ;
option limcol         = 0         ;
option holdFixedAsync = 1         ; 
option nlp            = conopt3   ; #by default: use CONOPT3


* prints solution listing when asynchronous solve (Grid/Threads) is used
$if set onlysolve option AsyncSolLst = 1;

##  LAUNCH SOLVER
#_________________________________________________________________________
$if not set serial_solving $batinclude "algorithm/solve_regions"
$if set serial_solving $batinclude "algorithm/solve_regions_serial"
$shift
$goto loop0
# ................................................
# END PROGRESSIVE OPTIMIZATIONS LOOOP 
# ................................................
$label loop1
;