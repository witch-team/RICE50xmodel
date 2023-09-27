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
$setglobal policy cba

$setglobal emission_pulse 1 #unit is MtCO2eq
$setglobal nameout %mod_emission_pulse%_emission_pulse
$setglobal output_filename results_%nameout%

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='sets'

* for now requires mod_climate as witchco2 or wicthoghg
$if not %climate%=='witchco2' $if not %climate%=='witchoghg' $abort 'USER ERROR: witch co2 or oghg climate module required for mod_emission_pulse!'

*$if %impact%=="off" $abort 'USER ERROR: impacts required to estimate SCC via mod_emission_pulse!'
*$if not %cooperation%=="coop" $abort 'USER ERROR: cooperative mode required to correctly estimate SCC via mod_emission_pulse!'
*$if not %policy%=="cba" $abort 'USER ERROR: policy should be set to cba fro emission pulse based SCC computation'

alias(n, nref);
alias(t, tref);

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='compute_data'

parameter emission_pulse(ghg,t);
# Pulse in 2020!
emission_pulse(ghg,t)=0;
emission_pulse('co2','2') = %emission_pulse%*1e-3*CO2toC / wemi2qemi('co2');
*emission_pulse('ch4','2') = %emission_pulse%*1e-3*CO2toC / wemi2qemi('ch4');
*emission_pulse('n2o','2') = %emission_pulse%*1e-3*CO2toC / wemi2qemi('n20');


*-------------------------------------------------------------------------------
$elseif.ph %phase%=='declare_vars'

variable C_nopulse(t,n);
variable YGROSS_nopulse(t,n);
variable S_nopulse(t,n);
variable E_nopulse(t,n);
variable EIND_nopulse(t,n);
variable ELAND_nopulse(t,n);
variable W_EMI_nopulse(ghg,t);
variable K_nopulse(t,n);
variable I_nopulse(t,n);
variable TATM_nopulse(t);
parameter scc_nopulse(t,n);
variable MIU_nopulse(t,n);
parameter tfp_nopulse(t,n);
$if set mod_natural_capital variable NAT_CAP_DAM_nopulse(type,t,n);
$gdxin '%resdir%results_%mod_emission_pulse%'
$loaddc C_nopulse=C
$loaddc YGROSS_nopulse=YGROSS
$loaddc S_nopulse=S
$loaddc E_nopulse=E
$loaddc EIND_nopulse=EIND
$loaddc ELAND_nopulse=ELAND
$loaddc W_EMI_nopulse=W_EMI
$loaddc K_nopulse=K
$loaddc I_nopulse=I
$loaddc TATM_nopulse=TATM
$loaddc scc_nopulse=scc
$loaddc MIU_nopulse=MIU
$loaddc tfp_nopulse=tfp
$if set mod_natural_capital $loaddc NAT_CAP_DAM_nopulse=NAT_CAP_DAM
$gdxin

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='compute_vars'

ELAND.fx(t,n) = ELAND_nopulse.l(t,n);
MIU.fx(t,n) = MIU_nopulse.l(t,n);
I.l(t,n) = I_nopulse.l(t,n);
S.fx(t,n) = S_nopulse.l(t,n);
#S.up(t,n) = 1;#S_nopulse.l(t,n) + 0.1;
#S.lo(t,n) = 0;#S_nopulse.l(t,n) - 0.1;
*EIND.l(t,n) = EIND_nopulse.l(t,n);
*E.l(t,n) = E_nopulse.l(t,n) + (%emission_pulse%*1e-3)/CARD(n);
*W_EMI.l(ghg,t) = W_EMI_nopulse.l(ghg,t) + emission_pulse(ghg,t);
$if not set mod_natural_capital YGROSS.fx(t,n) = YGROSS_nopulse.l(t,n);
*also for TFP
tfp(t,n) = tfp_nopulse(t,n);
*-------------------------------------------------------------------------------
$elseif.ph %phase%=='after_solve'



*-------------------------------------------------------------------------------
$elseif.ph %phase%=='report'

Parameter damrt(t,n);
Parameter tatm_difference(t);
Parameter scc_pulse_simple(t,n);
Parameter scc_pulse_ramsey_global(t,n);
Parameter scc_pulse_ramsey_regional(t,n);
Parameter scc_pulse_ramsey_only_regional(t,n,n);
Parameter scc_discounted_only_regional(*,t,n);
$if set mod_natural_capital Parameter scc_nat_cap(*,t,n), scc_nat_cap_only_regional(*,t,n);
Parameter discount_rate(t);
discount_rate(t) = 0.03;

damrt(t,n) = -(C.l(t,n) - C_nopulse.l(t,n)); #positive values = damages in T$
tatm_difference(t)=TATM.l(t) - TATM_nopulse.l(t);

#for now compute SCC along the baseline, i.e., using arguments of welfare function at original level
C.l(t,n) = C_nopulse.l(t,n);

 #compute SCC
 scc_pulse_ramsey_global(tref,nref) =
  (sum(t$(year(t) ge year(tref)),
           ((sum(nn,C.l(t,nn)) / sum(nn,pop(t,nn)))**(-elasmu)) / ((sum(nn,C.l(tref,nn)) / sum(nn,pop(tref,nn)))**(-elasmu))
           * rr(t)
           * sum(n,damrt(t,n)))
           / (%emission_pulse%*1e-3)
            * (1e3)
       )
;

scc_pulse_ramsey_regional(tref,nref) =
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

scc_pulse_ramsey_only_regional(tref,nref,n) =
  (sum(t$(year(t) ge year(tref)),
           (C.l(t,n) / pop(t,n))**(-elasmu) / (C.l(tref,nref) / pop(tref,nref))**(-elasmu)
           * rr(t)
           * damrt(t,n)
           / (%emission_pulse%*1e-3)
            * (1e3)
           )
       )
;

scc_pulse_simple(tref,n) = (sum((t,nn)$(year(t) ge year(tref)), damrt(t,nn) * (1+discount_rate(t))**(-(year(t)-year(tref))) ) / (%emission_pulse%*1e-3)) * 1e3; # in T$/GtCO2 to $/tCO2eq, just simple discounted global value
#SCC aligned with IAWG with 3 different discount rates, allowing to separate regional impacts
scc_discounted_only_regional('2',tref,n) = (sum((t)$(year(t) ge year(tref)), damrt(t,n) * (1+0.02)**(-(year(t)-year(tref))) ) / (%emission_pulse%*1e-3)) * 1e3; # in T$/GtCO2 to $/tCO2eq, just simple discounted global value
scc_discounted_only_regional('3.5',tref,n) = (sum((t)$(year(t) ge year(tref)), damrt(t,n) * (1+0.035)**(-(year(t)-year(tref))) ) / (%emission_pulse%*1e-3)) * 1e3; # in T$/GtCO2 to $/tCO2eq, just simple discounted global value
scc_discounted_only_regional('5',tref,n) = (sum((t)$(year(t) ge year(tref)), damrt(t,n) * (1+0.05)**(-(year(t)-year(tref))) ) / (%emission_pulse%*1e-3)) * 1e3; # in T$/GtCO2 to $/tCO2eq, just simple discounted global value



$ifthen.nk set mod_natural_capital
scc_nat_cap('market',tref,nref) = 
  (sum(t$(year(t) ge year(tref)),
       sum(n,
           {
            (1-nat_cap_utility_share(n))* ([ (1-nat_cap_utility_share(n)) * ( (CPC.l(t,n))**theta(n) ) + nat_cap_utility_share(n) * ( (NAT_CAP_DAM.l('nonmarket',t,n) / pop(t,n) * 1e6)**theta(n) ) ]**((1-theta(n)-elasmu)/theta(n)) ) * ( CPC.l(t,nref)**(theta(n) - 1) ) 
           }
           /
           {
           (1-nat_cap_utility_share(nref))* ([ (1-nat_cap_utility_share(nref)) * ( (CPC.l(tref,nref))**theta(nref) ) + nat_cap_utility_share(nref) * ( (NAT_CAP_DAM.l('nonmarket',tref,nref) / pop(tref,nref) * 1e6)**theta(nref) ) ]**((1-theta(n)-elasmu)/theta(nref)) ) * (CPC.l(tref,nref))**(theta(nref) - 1)
           }
           * rr(t)
           * damrt(t,n))
           / (%emission_pulse%*1e-3)
            * (1e3)
           )
       )
;

scc_nat_cap('nonmarket',tref,nref) = 
  (sum(t$(year(t) ge year(tref)),
       sum(n,
           {
            (nat_cap_utility_share(n))* ([ (1-nat_cap_utility_share(n)) * ( (C.l(t,n) / pop(t,n))**theta(n) ) + nat_cap_utility_share(n) * ( (1e6 * NAT_CAP_DAM.l('nonmarket',t,n) / pop(t,n))**theta(n) ) ]**((1-theta(n)-elasmu)/theta(n)) ) * (1e6 * NAT_CAP_DAM.l('nonmarket',t,n) / pop(t,n))**(theta(n) - 1)   
           }
            / 
           {
            (1-nat_cap_utility_share(nref))* ([ (1-nat_cap_utility_share(nref)) * ( (C.l(tref,nref) / pop(tref,nref))**theta(nref) ) + nat_cap_utility_share(nref) * ( (1e6 * NAT_CAP_DAM.l('nonmarket',tref,nref) / pop(tref,nref))**theta(nref) ) ]**((1-theta(n)-elasmu)/theta(nref)) ) * (C.l(tref,nref) / pop(tref,nref))**(theta(nref) - 1)
           }
           * rr(t)
           * (-(NAT_CAP_DAM.l('nonmarket',t,n) - NAT_CAP_DAM_nopulse.l('nonmarket',t,n))) )
           / (%emission_pulse%*1e-3)
            * (1e3)
           )
       )
;

#now taking into account only regional impacts, and discounting to world average marginal utility
scc_nat_cap_only_regional('market',tref,nref) = 
  (sum(t$(year(t) ge year(tref)),
       sum(n$sameas(n,nref),
           {
            (1-nat_cap_utility_share(n))* ([ (1-nat_cap_utility_share(n)) * ( (CPC.l(t,n))**theta(n) ) + nat_cap_utility_share(n) * ( (NAT_CAP_DAM.l('nonmarket',t,n) / pop(t,n) * 1e6)**theta(n) ) ]**((1-theta(n)-elasmu)/theta(n)) ) * ( CPC.l(t,nref)**(theta(n) - 1) ) 
           }
           /
           {
#          (1-nat_cap_utility_share(nref))* ([ (1-nat_cap_utility_share(nref)) * ( (C.l(tref,nref) / pop(tref,nref))**theta(nref) ) + nat_cap_utility_share(nref) * ( (1e6 * NAT_CAP_DAM.l('nonmarket',tref,nref) / pop(tref,nref))**theta(nref) ) ]**((1-theta(n)-elasmu)/theta(nref)) ) * (C.l(tref,nref) / pop(tref,nref))**(theta(nref) - 1)
#           sum(nn, pop(t,nn) * (1-nat_cap_utility_share(nn))* ([ (1-nat_cap_utility_share(nn)) * ( (CPC.l(tref,nn))**theta(nn) ) + nat_cap_utility_share(nn) * ( (NAT_CAP_DAM.l('nonmarket',tref,nn) / pop(tref,nn) * 1e6)**theta(nn) ) ]**((1-theta(n)-elasmu)/theta(nn)) ) * (CPC.l(tref,nn))**(theta(nn) - 1) ) /sum(nn,pop(t,nn))
          (1-nat_cap_utility_share(nref))* ([ (1-nat_cap_utility_share(nref)) * ( (C.l(t,nref) / pop(t,nref))**theta(nref) ) + nat_cap_utility_share(nref) * ( (1e6 * NAT_CAP_DAM.l('nonmarket',t,nref) / pop(t,nref))**theta(nref) ) ]**((1-theta(n)-elasmu)/theta(nref)) ) * (C.l(t,nref) / pop(t,nref))**(theta(nref) - 1)
           }
           * (1+0.035)**(-(year(t)-year(tref)))
           * damrt(t,n))
           / (%emission_pulse%*1e-3)
            * (1e3)
           )
       )
;

scc_nat_cap_only_regional('nonmarket',tref,nref) = 
  (sum(t$(year(t) ge year(tref)),
       sum(n$sameas(n,nref),
           {
            (nat_cap_utility_share(n))* ([ (1-nat_cap_utility_share(n)) * ( (C.l(t,n) / pop(t,n))**theta(n) ) + nat_cap_utility_share(n) * ( (1e6 * NAT_CAP_DAM.l('nonmarket',t,n) / pop(t,n))**theta(n) ) ]**((1-theta(n)-elasmu)/theta(n)) ) * (1e6 * NAT_CAP_DAM.l('nonmarket',t,n) / pop(t,n))**(theta(n) - 1)   
           }
            / 
           {
#          (1-nat_cap_utility_share(nref))* ([ (1-nat_cap_utility_share(nref)) * ( (C.l(tref,nref) / pop(tref,nref))**theta(nref) ) + nat_cap_utility_share(nref) * ( (1e6 * NAT_CAP_DAM.l('nonmarket',tref,nref) / pop(tref,nref))**theta(nref) ) ]**((1-theta(n)-elasmu)/theta(nref)) ) * (C.l(tref,nref) / pop(tref,nref))**(theta(nref) - 1)
#           sum(nn, pop(t,nn) * (1-nat_cap_utility_share(nn))* ([ (1-nat_cap_utility_share(nn)) * ( (CPC.l(tref,nn))**theta(nn) ) + nat_cap_utility_share(nn) * ( (NAT_CAP_DAM.l('nonmarket',tref,nn) / pop(tref,nn) * 1e6)**theta(nn) ) ]**((1-theta(n)-elasmu)/theta(nn)) ) * (CPC.l(tref,nn))**(theta(nn) - 1) ) /sum(nn,pop(t,nn))
          (1-nat_cap_utility_share(nref))* ([ (1-nat_cap_utility_share(nref)) * ( (C.l(t,nref) / pop(t,nref))**theta(nref) ) + nat_cap_utility_share(nref) * ( (1e6 * NAT_CAP_DAM.l('nonmarket',t,nref) / pop(t,nref))**theta(nref) ) ]**((1-theta(n)-elasmu)/theta(nref)) ) * (C.l(t,nref) / pop(t,nref))**(theta(nref) - 1)
           }
           * (1+0.035)**(-(year(t)-year(tref)))
           * (-(NAT_CAP_DAM.l('nonmarket',t,n) - NAT_CAP_DAM_nopulse.l('nonmarket',t,n))) )
           / (%emission_pulse%*1e-3)
            * (1e3)
           )
       )
;

$endif.nk

$elseif.ph %phase%=='gdx_items'
C_nopulse
YGROSS_nopulse
S_nopulse
I_nopulse
E_nopulse
EIND_nopulse
TATM_nopulse
W_EMI_nopulse
MIU_nopulse
emission_pulse
scc_nopulse
damrt
tatm_difference
discount_rate
scc_pulse_ramsey_global
scc_pulse_ramsey_regional
scc_pulse_ramsey_only_regional
scc_pulse_simple
scc_discounted_only_regional
$if set mod_natural_capital scc_nat_cap
$if set mod_natural_capital scc_nat_cap_only_regional

$endif.ph
