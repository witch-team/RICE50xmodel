*-------------------------------------------------------------------------------
* Sea-Level Rise
* - Based on Li et al. (2020): Li, Chao, Hermann Held, Sascha Hokamp, and Jochem Marotzke. ‘Optimal Temperature Overshoot Profile Found by Limiting Global Sea Level Rise as a Lower-Cost Climate Target’. Science Advances 6, no. 2 (1 January 2020): eaaw9490. https://doi.org/10.1126/sciadv.aaw9490.
*-------------------------------------------------------------------------------

$ifthen.ph %phase%=='conf'

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='sets'

set w 'sea level rise components' /
thermo 'Thermal expansion'
gris   'Greenlan ice sheet melt'
antis  'Antartic ice sheet melt'
mg     'Mountain glaciers and ice cap melting'
/;

set m /
ml
tc
dp
/;

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='include_data'

# Parameters
scalar slr_beta /1.33/;
scalar slr_d_ml /50/; #m
scalar slr_d_tc /500/; #m
scalar slr_d_dp /3150/; #m
scalar slr_w_e /0.5e-6/; #ms-1
scalar slr_w_d /0.2e-6/; #ms-1
scalar slr_gamma_ml /2.4e-4/; # K-1
scalar slr_gamma_tc /2.0e-4/; # K-1
scalar slr_gamma_dp /2.1e-4/; # K-1
scalar nbsecyear /31556952/; #s

scalar slr_gris0 /0.0055/; # cm
scalar slr_antis0 /0.009/; #cm
scalar slr_mg0 /0.026/; #cm

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='declare_vars'

variable TEMP(m,t) 'Temperature of Sea levels';
*TEMP.lo(m,t) = 0;
*TEMP.lo('tc','1') = 0;TEMP.lo('dp','1') = 0;
*TEMP.fx('tc','1') = 0;TEMP.fx('dp','1') = 0;
TEMP.l('tc','1') = 0;TEMP.l('dp','1') = 0;


variable GMSLR(t) 'Global mean sea level rise [m]';
GMSLR.l(t) = 0;
GMSLR.lo(t) = 0; 
GMSLR.up(t) = 3;


variable SLR(w,t) 'Sea level rise [W/m2]';
SLR.l(w,t) = 0;
SLR.lo(w,t) = 0;
SLR.up(w,t) = 3;
SLR.up('mg',t) = 0.4; # Maximum Sea-level rive from mountain glaciers and ice cap melting

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='eql'

eqslr_tot
eqslr_gris
eqslr_antis
eqslr_mg
eqslr_thermo
eqtemp_ml
eqtemp_tc
eqtemp_dp

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='eqs'

eqslr_tot(t)..
    GMSLR(t) =e= sum(w, SLR(w,t));

eqslr_gris(t)..
    SLR('gris',t) =e= sum(tt$(preds(t,tt)), 5 * (71.5 * TATM(tt) + 20.4 * TATM(tt)**2 + 2.8 * TATM(tt)**3)) / 3.61e5 + slr_gris0;

eqslr_antis(t)..
    SLR('antis',t) =e= sum(tt$(preds(t,tt)), 5 * (0.00074 + 0.00022 * TATM(tt))) + slr_antis0;

eqslr_mg(t)..
    SLR('mg',t) =e= sum(tt$(preds(t,tt)), 5 * (0.0008 * TATM(tt)) * (1 - SLR('mg',tt) / 0.41)**1.646) + slr_mg0;

eqtemp_ml(t)..
    TEMP('ml',t) =e= TATM(t) / slr_beta;

eqtemp_tc(t,tp1)$(tperiod(t) gt 1 and pre(t,tp1))..
    TEMP('tc',t) =e= TEMP('tc',t) + (slr_w_e / slr_d_tc * (TEMP('ml',t) - TEMP('tc',t))) * nbsecyear * tlen(t) -
                                           (slr_w_d / slr_d_tc * (TEMP('tc',t) - TEMP('dp',t))) * nbsecyear * tlen(t);

eqtemp_dp(t,tp1)$(tperiod(t) gt 1 and pre(t,tp1))..
    TEMP('dp',t,tp1) =e= TEMP('dp',t) + (slr_w_d / slr_d_dp * (TEMP('tc',t) - TEMP('dp',t))) * nbsecyear * tlen(t);

 eqslr_thermo(t)..
    SLR('thermo',t) =e= slr_gamma_ml * TEMP('ml',t) * slr_d_ml +
                          slr_gamma_tc * TEMP('tc',t) * slr_d_tc +
                          slr_gamma_dp * TEMP('dp',t) * slr_d_dp;

$elseif.ph %phase%=='after_solve'

* recompute climate

TEMP.l('ml',t) =e= TATM.l(t) / slr_beta;
loop((t,tp1)$pre(t,tp1),
TEMP('tc',tp1) = TEMP.l('tc',t) + (slr_w_e / slr_d_tc * (TEMP.l('ml',t) - TEMP.l('tc',t))) * nbsecyear * tlen(t) -
                                           (slr_w_d / slr_d_tc * (TEMP.l('tc',t) - TEMP.l('dp',t))) * nbsecyear * tlen(t);
TEMP('dp',tp1) =e= TEMP.l('dp',t) + (slr_w_d / slr_d_dp * (TEMP.l('tc',t) - TEMP.l('dp',t))) * nbsecyear * tlen(t);
);
SLR.l('thermo',t) =e= slr_gamma_ml * TEMP.l('ml',t) * slr_d_ml +
                          slr_gamma_tc * TEMP.l('tc',t) * slr_d_tc +
                          slr_gamma_dp * TEMP.l('dp',t) * slr_d_dp;
SLR.l('mg',t) =e= sum(tt$(preds(t,tt)), 5 * (0.0008 * TATM.l(tt)) * (1 - SLR.l('mg',tt) / 0.41)**1.646) + slr_mg0;
SLR.l('gris',t) =e= sum(tt$(preds(t,tt)), 5 * (71.5 * TATM.l(tt) + 20.4 * TATM.l(tt)**2 + 2.8 * TATM.l(tt)**3)) / 3.61e5 + slr_gris0;
SLR.l('antis',t) =e= sum(tt$(preds(t,tt)), 5 * (0.00074 + 0.00022 * TATM.l(tt))) + slr_antis0;
GMSLR.l(t) =e= sum(w, SLR.l(w,t));


*-------------------------------------------------------------------------------
$elseif.ph %phase%=='gdx_items'

TEMP
GMSLR
SLR

$endif.ph
