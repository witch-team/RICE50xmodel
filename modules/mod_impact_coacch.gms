*-------------------------------------------------------------------------------
* Long-run Damages from Climate Change
* - Economic impacts
* - Adaptation to SLR (with mod_slr)
* based on Wijst, K. van der, et al. “New Damage Curves and Multimodel Analysis Suggest Lower Optimal Temperature.” Nature Climate Change, March 23, 2023. https://doi.org/10.1038/s41558-023-01636-1.
*-------------------------------------------------------------------------------

$ifthen.ph %phase%=='conf'

* Define damage cost function
* chose percentile of the damage function (default=median p50)
$setglobal damcostpb 'p50'

$setglobal damcost 'COACCH_NoSLR'

*$setglobal damcostslr 'COACCH_SLR_NoAd'
*$setglobal damcostslr 'COACCH_SLR_Ad'
$setglobal damcostslr 'none'

$if not set mod_slr $if not '%damcostslr%'=='none' $abort("COACCH damage function with SLR impacts require --mod_slr=1 for Sea-level rise")

$elseif.ph %phase%=='sets'

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='include_data'

$gdxin '%datapath%data_mod_damage'

parameter comega(*,n,*);
$loaddc comega

parameter comega_slr(*,n,*);
$loaddc comega_slr

*for non-convex functions
*comega_slr('COACCH_SLR_Ad',n,'b2')$(comega_slr('COACCH_SLR_Ad',n,'b2') le 0)=0;
*comega_slr('COACCH_SLR_NoAd',n,'b2')$(comega_slr('COACCH_SLR_NoAd',n,'b2') le 0)=0;

*no positive impacts from SLR possible
comega_slr('COACCH_SLR_Ad',n,'b1')$(comega_slr('COACCH_SLR_Ad',n,'b1') le 0)=0;
comega_slr('COACCH_SLR_NoAd',n,'b1')$(comega_slr('COACCH_SLR_NoAd',n,'b1') le 0)=0;

*zero values for running without SLR damages
comega_slr('none',n,'b1') = 0;
comega_slr('none',n,'b2') = 0;

parameter comega_qmul(*,n,*) 'Damage function quantile multiplier';
$loaddc comega_qmul

comega_qmul('%dmgcostslr%',n,'p05')$(comega_qmul('%dmgcostslr%',n,'p05') le 0) = 0;
comega_qmul('%dmgcost%',n,'p05')$(comega_qmul('%dmgcost%',n,'p05') le 0) = 0;

comega_qmul('%dmgcostslr%',n,'p05')$(comega_qmul('%dmgcostslr%',n,'p025') le 0) = 0;
comega_qmul('%dmgcost%',n,'p05')$(comega_qmul('%dmgcost%',n,'p025') le 0) = 0;

parameter temp_base(*) 'temperature adjustment for the damage function';
$loaddc temp_base
$gdxin

* Adaptation efficiency

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='compute_data'

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='declare_vars'

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='compute_vars'

TATM.lo(t) = tatm0;


*-------------------------------------------------------------------------------
$elseif.ph %phase%=='eql'

eqomega

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
- comega_qmul('%damcost%',n,'%damcostpb%') *
                                     (comega('%damcost%',n,'b1') * (TATM('2') - temp_base('%damcost%')) +
                                      comega('%damcost%',n,'b2') * (TATM('2') - temp_base('%damcost%'))**2 +
                                      comega('%damcost%',n,'c')
$if set mod_slr                    + comega_qmul('%damcostslr%',n,'%damcostpb%') * (comega_slr('%damcostslr%',n,'b1') * GMSLR('2') + comega_slr('%damcostslr%',n,'b2') * GMSLR('2')**2)
                                     ) ;

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='report'


$elseif.ph %phase%=='gdx_items'

* Parameters
comega
comega_slr
comega_qmul


$endif.ph
