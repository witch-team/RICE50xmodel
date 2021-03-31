* IMPACT DICE SUB-MODULE
** A DICE2016-like impact is uniformly applied across all regions
*____________
* REFERENCES
* - Nordhaus, William. "Projections and Uncertainties about Climate Change in an Era of Minimal Climate Policies". 
* American Economic Journal: Economic Policy 10, no. 3 (1 August 2018): 333–60. https://doi.org/10.1257/pol.20170046.
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================

##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'


## INCLUDE DATA
#_________________________________________________________________________
$elseif.ph %phase%=='include_data'

PARAMETERS
* DICE-2016 damage coefficient
   a1       'Damage intercept'                          / 0       /
   a2       'Damage quadratic term'                     / 0.00236 /
   a3       'Damage exponent'                           / 2.00    /
* Calibrated safety bounds of climate change effect
    ynet_maximum(t,n)       'Maximum allowed gains from climate change'
    ynet_minimum(t,n)       'Maximum allowed damages from climate change'
;

# DAMAGES CAP LEVELS -----------------------------------
* Maximum and minimum reachable values (compared to baseline SSP GDP level)
 ynet_maximum(t,n) =   %max_gain%   * ykali(t,n) ;
 ynet_minimum(t,n) =   %max_damage% * ykali(t,n) ;

* Tolerance for min/max nlp smooting
SCALAR   delta  /1e-2/ ; #-14 more than 1e-8 get solver stucked


##  DECLARE VARIABLES
#_________________________________________________________________________
$elseif.ph %phase%=='declare_vars'

VARIABLES
    DAMFRAC_UNBOUNDED(t,n)   'Potential unbounded damages, as GDP Gross fraction [%GDPgross]: (+) damages (-) gains '
    YNET_UNBOUNDED(t,n)      'Potential unbounded GDP, net of damages [Trill 2005 USD / year]'
#    YNET_UPBOUND(t,n)        'Potential GDP, net of damages, bounded in maximum gains [Trill 2005 USD / year]'
;


## List of equations
#_________________________________________________________________________
$elseif.ph %phase%=='eql'

eq_damfrac_unb
eq_ynet_unb


##  EQUATIONS
#_________________________________________________________________________
$elseif.ph %phase%=='eqs'

##  ESTIMATED YNET AND DAMAGES --------
* Unbounded Damfrac
 eq_damfrac_unb(t,n)$(reg(n))..   DAMFRAC_UNBOUNDED(t,n)  =E=  (a1 * TATM(t)) + (a2 * power(TATM(t),a3))   ;
* Unbounded YNET esteem
 eq_ynet_unb(t,n)$(reg(n))..   YNET_UNBOUNDED(t,n)  =E=  YGROSS(t,n) * (1 - DAMFRAC_UNBOUNDED(t,n))  ;
* Bounded YNET esteem
 eq_ynet_estim(t,n)$(reg(n))..   # Bounds are combined:  MAX( min(YNET_UNBOUNDED,ynet_maximum), ynet_minimum ) via nlp-approximation
     YNET_ESTIMATED(t,n) =E=  (  (( YNET_UNBOUNDED(t,n) + ynet_maximum(t,n) - Sqrt( Sqr(YNET_UNBOUNDED(t,n)-ynet_maximum(t,n)) + Sqr(delta) ))/2)                    # a(x)  --> ( f(x) + g(y) - Sqrt( Sqr( f(x)-g(y) ) + Sqr(delta) ))/2
                                 + ynet_minimum(t,n)                                                                                                                       # + b(y)
                                 + Sqrt( Sqr(   (( YNET_UNBOUNDED(t,n) + ynet_maximum(t,n) - Sqrt( Sqr(YNET_UNBOUNDED(t,n)-ynet_maximum(t,n)) + Sqr(delta) ))/2)      # + Sqrt( Sqr( a(x) -->  ^   ^  ^
                                                 -  ynet_minimum(t,n)                                                                                                      #              - b(y)
                                             ) + Sqr(delta) )                                                                                                              #       ) + Sqr(delta)
                               )/2   ;
                            #................................................................................
                            # UPPER BOUND ->  fix maximum YNET level -> min( YNET_UNBOUNDED, ynet_maximum )
                            # LOWER BOUND ->  fix minimum YNET level -> max( YNET_UNBOUNDED, ynet_minimum )
                            #
                            # A smooth GAMS approximation for  min(f(x),g(y))  is:
                            #    ( f(x) + g(y) - Sqrt( Sqr( f(x)-g(y) ) + Sqr(delta) ) )/2
                            #
                            # A smooth GAMS approximation for  max(f(x),g(y))  is:
                            #   ( a(x) + b(y) + Sqrt( Sqr(a(x)-b(y)) + Sqr(delta) ) )/2
                            #................................................................................

##  EFFECTIVE DAMAGES --------
* Effective net Damages
eq_damages(t,n)$(reg(n))..   DAMAGES(t,n)  =E=  (YGROSS(t,n) - YNET_ESTIMATED(t,n)) ;

* Effective Damages as fraction of YGROSS
 eq_damfrac(t,n)$(reg(n))..   DAMFRAC(t,n)  =E= (-1) * ( DAMAGES(t,n) / YGROSS(t,n) )  ;


#=========================================================================
*   ///////////////////////     SIMULATION    ///////////////////////
#=========================================================================

##  SIMULATION HALFLOOP 1
#_________________________________________________________________________
$elseif.ph %phase%=='simulate_1'

##  ESTIMATED YNET AND DAMAGES --------
* Unbounded Damfrac
DAMFRAC_UNBOUNDED.l(t,n)  =  (a1 * TATM.l(t)) + (a2 * power.l(TATM(t),a3))  ;
* Unbounded YNET esteem
YNET_UNBOUNDED.l(t,n)  =  YGROSS.l(t,n) * (1 - DAMFRAC_UNBOUNDED.l(t,n))  ;
* Bounded YNET esteem
YNET_ESTIMATED.l(t,n) =     max(  min(YNET_UNBOUNDED.l(t,n),ynet_maximum(t,n)), ynet_minimum(t,n) )   ;

##  EFFECTIVE DAMAGES --------
* Effective net Damages
DAMAGES.l(t,n)  =  (YGROSS.l(t,n) - YNET_ESTIMATED.l(t,n)) ;
* Effective Damages as fraction of YGROSS
DAMFRAC.l(t,n)  =  (-1) * (DAMAGES.l(t,n)/YGROSS.l(t,n))  ;


#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

# parameters
a1
a2
a3


$endif.ph
