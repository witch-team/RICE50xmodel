*-------------------------------------------------------------------------------
* Long-run Damages from Climate Change
* - Economic impacts
* - Adaptation
*
* Based on: Bosello and De Cian (2014) - Documentation on the development of damage functions and adaptation in the WITCH model
*-------------------------------------------------------------------------------

$ifthen.ph %phase%=='conf'

* Define adaptation efficacy
$setglobal adap_efficiency ssp2
$if %baseline%=='ssp1' $setglobal adap_efficiency ssp1_ssp5
$if %baseline%=='ssp3' $setglobal adap_efficiency ssp3
$if %baseline%=='ssp5' $setglobal adap_efficiency ssp1_ssp5

$elseif.ph %phase%=='sets'

set
    iq  'Nodes representing economic values (which have a Q)' /ada, cap, act, gcap/
    g   'Adaptation sectors' /prada, rada, scap/
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

VARIABLES    
            K_ADA(g,t,n)        'Adaptation capital [Trill 2005 USD / year]'
            I_ADA(g,t,n)        'Adaptation investment [Trill 2005 USD / year]'
            Q_ADA(iq,t,n)       'Adaptation [Trill 2005 USD / year]'
;

Q_ADA.lo(iq,t,n) = 1e-8;
Q_ADA.up(iq,t,n) = 1e3;
Q_ADA.l(iq,t,n) = 1e-5;
K_ADA.lo(g,t,n) = 1e-8;
K_ADA.up(g,t,n) = 1e3;
K_ADA.l(g,t,n) = 1e-8;
I_ADA.lo(g,t,n) = 1e-8;
I_ADA.up(g,t,n) = 1e3;
I_ADA.l(g,t,n) = 1e-8;

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='compute_vars'


K_ADA.fx('prada',tfirst,n) = 1e-5;
K_ADA.fx('rada',tfirst,n)  = 1e-5;
K_ADA.fx('scap',tfirst,n)  = 1e-5;

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='declare_vars'

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='eql'

eqq_ada
eqq_act
eqq_cap
eqq_gcap
eqk_prada
eqk_scap


*-------------------------------------------------------------------------------
$elseif.ph %phase%=='eqs'

# CES: Adaptation = adaptation actions + adaptive capacity
eqq_ada(t,n)$reg(n)..
            Q_ADA('ada',t,n)  =e= ces_ada('tfpada',n)*(owa('act',n)*Q_ADA('act',t,n)**ces_ada('ada',n)+ owa('cap',n)*Q_ADA('cap',t,n)**ces_ada('ada',n))**(1/ces_ada('ada',n));

# CES: Adaptation actions = flow adaptation (reactive i.e. rada) + stock adaptation (proactive i.e. prada)
eqq_act(t,n)$reg(n)..
            Q_ADA('act',t,n)  =e= ces_ada('eff',n) *owa('actc',n)*(owa('rada',n)*I_ADA('rada',t,n)**ces_ada('act',n)+ owa('prada',n)*K_ADA('prada',t,n)**ces_ada('act',n))**(1/ces_ada('act',n));

# CES: Adaptive capacity = generic adaptive capacity + specific adaptive capacity
eqq_cap(t,n)$reg(n)..
            Q_ADA('cap',t,n)  =e= (owa('gcap',n)*Q_ADA('gcap',t,n)**ces_ada('cap',n)+ owa('scap',n)*K_ADA('scap',t,n)**ces_ada('cap',n))**(1/ces_ada('cap',n));

#Generic capacity is exogenous and grows at the same rate as tfp (scaled by the average of stock of knowledge and human capital)
eqq_gcap(t,n)$reg(n)..
            Q_ADA('gcap',t,n) =e= ((k_h0(n)+k_edu0(n))/2)*tfp(t,n);

# Depreciation of stock adaptation:
eqk_prada(t,tp1,n)$(reg(n) and pre(t,tp1))..
            K_ADA('prada',tp1,n) =E= (1 - dk_ada('prada'))**tstep * K_ADA('prada',t,n) + I_ADA('prada',t,n)*tstep;

# Depreciation of specific adaptation:
eqk_scap(t,tp1,n)$(reg(n) and pre(t,tp1))..
            K_ADA('scap',tp1,n) =E= (1 - dk_ada('scap'))**tstep * K_ADA('scap',t,n) + I_ADA('scap',t,n)*tstep;


*-------------------------------------------------------------------------------
$elseif.ph %phase%=='report'


$elseif.ph %phase%=='gdx_items'

ces_ada
k_edu0
k_h0
owa
K_ADA
I_ADA
Q_ADA

$endif.ph
