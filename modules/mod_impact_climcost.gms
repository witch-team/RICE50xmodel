*-------------------------------------------------------------------------------
* Long-run Damages from Climate Change
* - Economic impacts
* - Adaptation
*-------------------------------------------------------------------------------

$ifthen.ph %phase%=='conf'

* Define damage cost function
$setglobal damcost 'climcost'

$elseif.ph %phase%=='sets'

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='include_data'

$gdxin '%datapath%data_mod_damage'

parameter comega(*,n,*);
$loaddc comega

parameter temp_base(*) 'temperature adjustment for the damage function';
$loaddc temp_base
temp_base('%damcost%') = 0.85;

$gdxin

* Adaptation efficiency

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='compute_data'

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='declare_vars'

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='compute_vars'

TATM.lo(t) = 0.85;

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='eql'

eqomega

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='eqs'

**damage function
eqomega(t,n)$(reg(n) and not tfirst(t))..
                OMEGA(t,n) =e= 1 *
                                     (comega('%damcost%',n,'b1') * (TATM(t) - temp_base('%damcost%')) +
                                      comega('%damcost%',n,'b2') * (TATM(t) - temp_base('%damcost%'))**2 +
                                      comega('%damcost%',n,'c')
                                     )
;

*-------------------------------------------------------------------------------
$elseif.ph %phase%=='report'


$elseif.ph %phase%=='gdx_items'

* Parameters
comega


$endif.ph
