*-------------------------------------------------------------------------------
* Long-run Damages from Climate Change
* - Economic impacts
* - Adaptation
*-------------------------------------------------------------------------------

$ifthen.ph %phase%=='conf'

* Toggle adaptation
$setglobal adaptation 'NO'

* Define adaptation efficacy
$setglobal adap_efficiency ssp2
$if %baseline%=='ssp1' $setglobal adap_efficiency ssp1_ssp5
$if %baseline%=='ssp3' $setglobal adap_efficiency ssp3
$if %baseline%=='ssp5' $setglobal adap_efficiency ssp1_ssp5

* Define damage cost function
$setglobal damcost 'climcost'
$setglobal damcostslr 'none'
$setglobal damcostpb 'p50'

*$setglobal damcost 'COACCH_NoSLR'
*$setglobal damcostslr 'COACCH_SLR_NoAd'

*$setglobal damcost 'COACCH_NoSLR'
*$setglobal damcostslr 'COACCH_SLR_Ad'

*$setglobal damcost 'COACCH_All_impacts_NoAd'
*$setglobal damcostslr 'none'


$elseif.ph %phase%=='sets'

set
    iq  'Nodes representing economic values (which have a Q)' /ada, cap, act, gcap/
    g   'Goods sector' /prada,rada,scap/
;

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='include_data'

Parameter dk_ada(g) ' depreciation of adapatation aggregates';

$gdxin '%datapath%data_mod_damage'

parameter k_h0(n);
$loaddc k_h0

parameter k_edu0(n);
$loaddc k_edu0

parameter owa(*,n);
$loaddc owa

parameter ces_ada(*,n);
$loaddc ces_ada

parameter comega(*,n,*);
$loaddc comega

parameter comega_slr(*,n,*);
$loaddc comega_slr
#for no no concav functions
comega_slr('COACCH_SLR_Ad',n,'b2')$(comega_slr('COACCH_SLR_Ad',n,'b2') le 0)=EPS;
comega_slr('COACCH_SLR_NoAd',n,'b2')$(comega_slr('COACCH_SLR_NoAd',n,'b2') le 0)=EPS;
#now also no negative linear term
#comega_slr('COACCH_SLR_Ad',n,'b1')$(comega_slr('COACCH_SLR_Ad',n,'b1') le 0)=0;
#comega_slr('COACCH_SLR_NoAd',n,'b1')$(comega_slr('COACCH_SLR_NoAd',n,'b1') le 0)=0;
comega_slr('none',n,'b1') = 0;
comega_slr('none',n,'b2') = 0;

parameter comega_qmul(*,n,*) 'Damage function quantile multiplier';
$loaddc comega_qmul
$ifthen.x %damcostpb%=='p50'
comega_qmul('%damcost%',n,'p50') = 1;
comega_qmul('%damcostslr%',n,'p50') = 1;
$endif.x
comega_qmul('%damcostslr%',n,'p05')$(comega_qmul('%damcostslr%',n,'p05') le 0) = EPS;
comega_qmul('%damcostslr%',n,'p95')$(comega_qmul('%damcostslr%',n,'p95') le 0) = EPS;

parameter temp_base(*) 'temperature adjustment for the damage function';
$loaddc temp_base
temp_base('%damcost%') = 0.85;

$gdxin

* Adaptation efficiency

$if not set adap_efficiency $setglobal adap_efficiency 'ssp2'

$ifthen.ae %adap_efficiency%=='ssp2'
ces_ada('eff',n)      = 1;

$elseif.ae %adap_efficiency%=='ssp1_ssp5'
ces_ada('eff',n)      = 1.25;

$elseif.ae %adap_efficiency%=='ssp3'
ces_ada('eff',n)      = 0.75;

$endif.ae


*-------------------------------------------------------------------------------
$elseif.ph %phase%=='compute_data'

dk_ada('prada') = 0.1;
dk_ada('rada') = 1;
dk_ada('scap') = 0.03;

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='declare_vars'

Variable K_ADA(g,t,n), I_ADA(g,t,n), Q_ADA(g,t,n);


*-------------------------------------------------------------------------------
$elseif.ph %phase%=='compute_vars'


K_ADA.fx('prada',tfirst,n) = 1e-5;
K_ADA.fx('rada',tfirst,n)  = 1e-5;
K_ADA.fx('scap',tfirst,n)  = 1e-5;

TATM.lo(t) = 0.85;

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='declare_vars'

TATM.lo(t) = 0.85;

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='eql'

eqomega

$iftheni.ada %adaptation%=='YES'
eqq_ada
eqq_act
eqq_cap
eqq_gcap
$endif.ada

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='eqs'

**damage function
eqomega(t,n)$(reg(n) and not tfirst(t))..
                OMEGA(t,n) =e= comega_qmul('%damcost%',n,'%damcostpb%') *
                                     (comega('%damcost%',n,'b1') * (TATM(t) - temp_base('%damcost%')) +
                                      comega('%damcost%',n,'b2') * (TATM(t) - temp_base('%damcost%'))**2 +
                                      comega('%damcost%',n,'c')
$if set mod_slr                    + comega_qmul('%damcostslr%',n,'%damcostpb%') * (comega_slr('%damcostslr%',n,'b1') * GMSLR(t) + comega_slr('%damcostslr%',n,'b2') * GMSLR(t)**2)
                                     )
$ifi %adaptation%=='YES'        / ( 1 + Q('ADA',t+1,n)**ces_ada('exp',n) )
;

$iftheni.ada %adaptation%=='YES'
eqq_ada(t,n)$reg(n)..
            Q_ADA('ADA',t,n)  =e= ces_ada('tfpada',n)*(owa("act",n)*Q_ADA('ACT',t,n)**ces_ada('ada',n)+ owa("cap",n)*Q_ADA('CAP',t,n)**ces_ada('ada',n))**(1/ces_ada('ada',n));

eqq_act(t,n)$reg(n)..
            Q_ADA('ACT',t,n)  =e= ces_ada('eff',n) *owa('actc',n)*(owa("rada",n)*I_ADA('RADA',t,n)**ces_ada('act',n)+ owa("prada",n)*K_ADA('PRADA',t,n)**ces_ada('act',n))**(1/ces_ada('act',n));

eqq_cap(t,n)$reg(n)..
            Q_ADA('CAP',t,n)  =e= (owa("gcap",n)*Q_ADA('GCAP',t,n)**ces_ada('cap',n)+ owa("scap",n)*K_ADA('SCAP',t,n)**ces_ada('cap',n))**(1/ces_ada('cap',n));

eqq_gcap(t,n)$reg(n)..
            Q_ADA('GCAP',t,n) =e= ((k_h0(n)+k_edu0(n))/2)*tfp(t,n);
$endif.ada

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='report'


$elseif.ph %phase%=='gdx_items'

* Parameters
ces_ada
comega
k_edu0
k_h0
owa


$endif.ph
