*-------------------------------------------------------------------------------
* Module to compute the Social Cost of Carbon via an emission pulse
* after any witch run, run it with --mod_emission_pulse=ssp2_cba_noncoop --cooperation=coop and specify your existing results file (without "_results")
* First version: February 18th, 2019, Author: J. Emmerling
* All SCCs in the current year, to convert from 2005 to 2020 USD, multiply by the deflator 1.302318665
* takes the run (be sure to specify the originally used impact and climate modules!)
* MIU and S are fixed to the loaded file values
* all Social costs expressed in $(2005)/tCO2eq
*-------------------------------------------------------------------------------

$ifthen.ph %phase%=='conf'

* Testing, since it is no optimization (0 superbasic variables), using COOP with gamma=0 to get right SCC values from marginals and via pulse
*$setglobal cooperation 'coop' (needs to be set from the command line!)
$setglobal gamma 0

*Best practice: Set policy to the one used in the loaded run!
*$setglobal policy cba

$setglobal emission_pulse 1 #unit is MtCO2eq
$setglobal nameout %mod_emission_pulse%_emission_pulse
$setglobal output_filename results_%nameout%

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='sets'

* for now requires mod_climate as witchco2 or fair
$if not %climate%=='witchco2' $if not %climate%=='fair' $abort 'USER ERROR: witch co2 or oghg climate module required for mod_emission_pulse!'

*$if %impact%=="off" $abort 'USER ERROR: impacts required to estimate SCC via mod_emission_pulse!'
*$if not %cooperation%=="coop" $abort 'USER ERROR: cooperative mode required to correctly estimate SCC via mod_emission_pulse!'
*$if not %policy%=="cba" $abort 'USER ERROR: policy should be set to cba fro emission pulse based SCC computation'

alias(n, nref);
alias(t, tref);

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='compute_data'

parameter emission_pulse(ghg,t) 'Global emission pulse in GtCO2, split equally across regions';
# Pulse in 2020!
#for other gases it is in term os species (MtCH4 etc)
emission_pulse(ghg,t)=0;
emission_pulse('co2','2') = %emission_pulse% * 1e-3;
*emission_pulse('ch4','2') = %emission_pulse% * 1e-3;
*emission_pulse('n2o','2') = %emission_pulse% * 1e-3;


*-------------------------------------------------------------------------------
$elseif.ph %phase%=='declare_vars'

variable C_nopulse(t,n);
variable YGROSS_nopulse(t,n);
variable S_nopulse(t,n);
variable E_nopulse(t,n,ghg);
variable EIND_nopulse(t,n,ghg);
variable ELAND_nopulse(t,n);
variable K_nopulse(t,n);
variable I_nopulse(t,n);
variable TATM_nopulse(t);
variable MIU_nopulse(t,n,ghg);
parameter tfp_nopulse(t,n);
parameter scc_nopulse(t,n,ghg);
$gdxin '%resdir%results_%mod_emission_pulse%'
$loaddc C_nopulse=C
$loaddc YGROSS_nopulse=YGROSS
$loaddc S_nopulse=S
$loaddc E_nopulse=E
$loaddc EIND_nopulse=EIND
$loaddc ELAND_nopulse=ELAND
$loaddc K_nopulse=K
$loaddc I_nopulse=I
$loaddc TATM_nopulse=TATM
$loaddc scc_nopulse=scc
$loaddc MIU_nopulse=MIU
$loaddc tfp_nopulse=tfp
$gdxin

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='compute_vars'

ELAND.fx(t,n) = ELAND_nopulse.l(t,n);
MIU.fx(t,n,ghg) = MIU_nopulse.l(t,n,ghg);
I.l(t,n) = I_nopulse.l(t,n);
S.fx(t,n) = S_nopulse.l(t,n);
#S.up(t,n) = 1;#S_nopulse.l(t,n) + 0.1;
#S.lo(t,n) = 0;#S_nopulse.l(t,n) - 0.1;
*EIND.l(t,n) = EIND_nopulse.l(t,n);
*E.l(t,n) = E_nopulse.l(t,n) + (%emission_pulse%*1e-3)/CARD(n);
*also for TFP
tfp(t,n) = tfp_nopulse(t,n);
*-------------------------------------------------------------------------------
$elseif.ph %phase%=='after_solve'



*-------------------------------------------------------------------------------
$elseif.ph %phase%=='report'

Parameter damrt(t,n);
Parameter tatm_difference(t);
Parameter scc_pulse_ramsey_global(tref,nref);
Parameter scc_pulse_ramsey_global_regshare(tref,nref);
Parameter scc_pulse_discounted_global(*,tref,nref);
Parameter scc_pulse_ramsey_global_regionalref(tref,nref);
Parameter scc_pulse_ramsey_only_regional(tref,nref);

damrt(t,n) = -(C.l(t,n) - C_nopulse.l(t,n)); #positive values = damages in T$
tatm_difference(t)= TATM.l(t) - TATM_nopulse.l(t);

#for now compute SCC along the baseline, i.e., using arguments of welfare function at original level
C.l(t,n) = C_nopulse.l(t,n);

#compute SCC (as in Rennert et al. (2022)) using global SDF
scc_pulse_ramsey_global(tref,nref) =
  (sum(t$(year(t) ge year(tref)),
           ((sum(nn,C.l(t,nn)) / sum(nn,pop(t,nn)))**(-elasmu)) / ((sum(nn,C.l(tref,nn)) / sum(nn,pop(tref,nn)))**(-elasmu))
           * rr(t)
           * sum(nn,damrt(t,nn)))
           / (%emission_pulse%*1e-3)
            * (1e3)
       )
;

#compute SCC (as in Rennert et al. (2022)) using global SDF, regional contribution of each region's impacts
scc_pulse_ramsey_global_regshare(tref,nref) =
  (sum(t$(year(t) ge year(tref)),
           ((sum(nn,C.l(t,nn)) / sum(nn,pop(t,nn)))**(-elasmu)) / ((sum(nn,C.l(tref,nn)) / sum(nn,pop(tref,nn)))**(-elasmu))
           * rr(t)
           * damrt(t,nref))
           / (%emission_pulse%*1e-3)
            * (1e3)
       )
;

#global SCC evaluated at regional marginal utility of consumption today (Anthoff and Emmerling, 2019)
scc_pulse_ramsey_global_regionalref(tref,nref) =
  (sum(t$(year(t) ge year(tref)),
       sum(n,
           (C.l(t,n) / pop(t,n))**(-elasmu) / (C.l(tref,nref) / pop(tref,nref))**(-elasmu)
           * rr(t)
           * damrt(t,n))
           / (%emission_pulse%*1e-3)
            * (1e3)
           )
       )
;

#regional SCC only taking regional impacts and using regional SDF
scc_pulse_ramsey_only_regional(tref,nref) =
  (sum(t$(year(t) ge year(tref)),
           (C.l(t,nref) / pop(t,nref))**(-elasmu) / (C.l(tref,nref) / pop(tref,nref))**(-elasmu)
           * rr(t)
           * damrt(t,nref)
           / (%emission_pulse%*1e-3)
            * (1e3)
           )
       )
;

#SCC aligned with IAWG with 3 different discount rates, allowing to separate regional impacts
scc_pulse_discounted_global('2',tref,n) = (sum((t)$(year(t) ge year(tref)), damrt(t,n) * (1+0.02)**(-(year(t)-year(tref))) ) / (%emission_pulse%*1e-3)) * 1e3; # in T$/GtCO2 to $/tCO2eq, just simple discounted value
scc_pulse_discounted_global('3.5',tref,n) = (sum((t)$(year(t) ge year(tref)), damrt(t,n) * (1+0.035)**(-(year(t)-year(tref))) ) / (%emission_pulse%*1e-3)) * 1e3; # in T$/GtCO2 to $/tCO2eq, just simple discounted value
scc_pulse_discounted_global('5',tref,n) = (sum((t)$(year(t) ge year(tref)), damrt(t,n) * (1+0.05)**(-(year(t)-year(tref))) ) / (%emission_pulse%*1e-3)) * 1e3; # in T$/GtCO2 to $/tCO2eq, just simple discounted value


$elseif.ph %phase%=='gdx_items'
C_nopulse
YGROSS_nopulse
S_nopulse
I_nopulse
E_nopulse
EIND_nopulse
TATM_nopulse
MIU_nopulse
emission_pulse
scc_nopulse
damrt
tatm_difference
scc_pulse_ramsey_global
scc_pulse_ramsey_global_regshare
scc_pulse_discounted_global
scc_pulse_ramsey_global_regionalref
scc_pulse_ramsey_only_regional

$endif.ph
