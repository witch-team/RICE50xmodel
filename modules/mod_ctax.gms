* MODULE CARBON TAX
* Set a carbon tax policy in the model. --ctax_spec=30 sets 30$/tCO2 tax increasing by 5% p.a.
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================
##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

* default ctax: off
$setglobal ctax_spec "no_ctax"

$ifthen.ctx not %ctax_spec%=='no_ctax' 
* Invert MACCs to precompute MIU to ease solution
$setglobal ctax_presolve 1
* No impacts
$setglobal impact "off"
$ifi not %impact%=="off" $abort 'USER ERROR: [impact] must be -off- with an active CTAX policy!'
* Optimization mode
$setglobal run_mode 'optimization'
$if not %run_mode%=='optimization' $abort 'USER ERROR: [run_mode] must be -optimization- for CTAX policy!'
$endif.ctx

* Smooth emission vars across iterations
$setglobal ctax_smooth_vars 1


## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

PARAMETER
  ctax(t,n)                  'Regions Carbon Tax according to selected policy [Trill 2005 USD/GtCO2]'
  alpha_ctax(n) 'Scale ctax impact on budget equations'
;

##  COMPUTE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='compute_data'

$ifthen.ctx %ctax_spec%=='no_ctax'
* Set no-ctax policy baseline
ctax(t,n) = 0;
$else.ctx
* Apply selected policy
ctax(t,n) = (%ctax_spec%/1000) * (1 + 0.05)**(year(t)-2015); #convert from USD/tCO2 to T$/GtCO2
ctax(t,n)$(year(t) ge 2200) = ctax('37',n) ; # Flat from 2200 
$endif.ctx                                    


##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

variable EITER(iter,t,n), EPREV(t,n);
EPREV.l(t,n) = emi_bau_co2(t,n);

$ifthen.ps %ctax_presolve%==1
variable
    PRESOLVE_MIU(t,n)
    PRESOLVE_OBJ
    SAVED_MIU(t,n)
;
PRESOLVE_MIU.lo(t,n) = 0;
PRESOLVE_MIU.up(t,n) = 10;
$endif.ps


#=========================================================================
*   ///////////////////////     OPTIMIZATION    ///////////////////////
#=========================================================================

##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

* Additional equations for a pre-solve model
$ifthen.ps %ctax_presolve%==1
equations
    eq_presolve_miu2price(t,n)
    eq_presolve_obj
;

eq_presolve_obj.. PRESOLVE_OBJ =e= 1;

eq_presolve_miu2price(t,n)$ctax(t,n)..
    ctax(t,n)*1e3 =e=
    mx(t,n)*(
        (ax_co2('%maccfit%','Total_CO2',t,n)*PRESOLVE_MIU(t,n)) +
        (bx_co2('%maccfit%','Total_CO2',t,n)*power(PRESOLVE_MIU(t,n),4))
    )
;
model model_presolve / eq_presolve_miu2price, eq_presolve_obj /;
model_presolve.optfile = 1;
model_presolve.holdfixed = 1;
$endif.ps


##  BEFORE SOLVE
#_________________________________________________________________________
$elseif.ph %phase%=='before_solve'

alpha_ctax(n) = 1;
$ifthen.ps %ctax_presolve%==1
if(iter.pos le 1,
    SAVED_MIU.lo(t,n) = MIU.lo(t,n);
    SAVED_MIU.up(t,n) = MIU.up(t,n);
    # Fix miu inverting maccs
    alpha_ctax(n) = 0;
    solve model_presolve using nlp minimizing PRESOLVE_OBJ;
    abort$((model_presolve.solvestat gt 1) or (model_presolve.modelstat gt 2)) 'Unable to invert MACCs';
    MIU.l('1',n) = 1 - e0(n)/sigma('1',n)/ykali('1',n);
    MIU.fx('2',n) = 0.03;
    loop(t$(t.pos gt 2),
        MIU.fx(t,n)$(ctax(t,n)) = PRESOLVE_MIU.l(t,n);
    );
    loop(t$(t.pos gt 2),
        MIU.fx(t,n)$(ctax(t,n)) = max(min(max(min(PRESOLVE_MIU.l(t,n), MIU.l(t-1,n)+0.2-1e-6), MIU.l(t-1,n)-0.2+1e-6), SAVED_MIU.up(t,n)), SAVED_MIU.lo(t,n));
    );
else
    # Revert to normal MIU
    MIU.lo(t,n)$((t.pos gt 2) and ctax(t,n)) = SAVED_MIU.lo(t,n);
    MIU.up(t,n)$((t.pos gt 2) and ctax(t,n)) = SAVED_MIU.up(t,n);
);

$endif.ps


##  PROBLEMATIC REGIONS
#_________________________________________________________________________
$elseif.ph %phase%=='problematic_regions'

alpha_ctax(nn) = alpha_ctax(nn)/2;


##  AFTER SOLVE
#_________________________________________________________________________
$elseif.ph %phase%=='after_solve'

converged$(smin(n, alpha_ctax(n)) lt 1) = 0;

if(not converged,
EITER.l(iter,t,n) = E.l(t,n);
if(iter.pos eq 1,
    EPREV.l(t,n) = EITER.l(iter,t,n);
else
    EPREV.l(t,n) = (EITER.l(iter,t,n)+EITER.l(iter-1,t,n))/2;
$ifthen.sv %ctax_smooth_vars%==1
    MIU.l(t,n)$(t.pos gt 2) = (viter(iter,'MIU',t,n) + viter(iter-1,'MIU',t,n))/2;
    EIND.l(t,n)$(t.pos gt 2) = sigma(t,n) * YGROSS.l(t,n) * (1-(MIU.l(t,n))) ;
    E.l(t,n) = EIND.l(t,n) + ELAND.l(t,n);
$endif.sv
);
);




#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================


##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

ctax




$endif.ph
