* COOPERATION COALITIONS
* Define coalitions mappings
#=========================================================================
*   ///////////////////////       SETTING      ///////////////////////
#=========================================================================
##  CONF
#_________________________________________________________________________
$ifthen.ph %phase%=='conf'

** COALITIONS GDXFIX
*$setglobal gdxfix "results_default"

# This is to be sure to initialize the sequence
$setglobal coalitions_t_sequence 1

$setglobal solmode 'noncoop'

## REGION WEIGHTS
$if %region_weights% == 'negishi' $setglobal calc_nweights ((CPC.l(t,n)**elasmu)/sum(nn, (CPC.l(t,nn)**(elasmu))))

* Population weights
$if %region_weights% == 'pop' $setglobal calc_nweights 1


## SETS
#_________________________________________________________________________
$elseif.ph %phase%=='sets'

* Some pre-defined coalitions
* in a policy file this set can be extended with new coalitions
SET clt "List of all possibly-applied coalitions" /
# Single-region coalitions
$include %datapath%n.inc
# European Union
eu27
noneu27
# Grand coalition (all)
grand

/;

* Some pre-defined coalitions mapping
* in a policy file this set can be extended with new coalitions
SET map_clt_n(clt,n) "Mapping set between coalitions and belonging regions" /
# Single-region coalition
arg.arg
aus.aus
aut.aut
bel.bel
bgr.bgr
blt.blt
bra.bra
can.can
chl.chl
chn.chn
cor.cor
cro.cro
dnk.dnk
egy.egy
esp.esp
fin.fin
fra.fra
gbr.gbr
golf57.golf57
grc.grc
hun.hun
idn.idn
irl.irl
ita.ita
jpn.jpn
meme.meme
mex.mex
mys.mys
nde.nde
nld.nld
noan.noan
noap.noap
nor.nor
oeu.oeu
osea.osea
pol.pol
prt.prt
rcam.rcam
rcz.rcz
rfa.rfa
ris.ris
rjan57.rjan57
rom.rom
rsaf.rsaf
rsam.rsam
rsas.rsas
rsl.rsl
rus.rus
slo.slo
sui.sui
swe.swe
tha.tha
tur.tur
ukr.ukr
usa.usa
vnm.vnm
zaf.zaf
# European Union
eu27.(aut, bel, bgr, cro, dnk, esp, fin, fra, grc, hun, irl, ita, nld, pol, prt, rcz, rfa, rom, rsl, slo, swe, blt)
# Non-EU27
noneu27.(gbr, arg, aus, bra, can, chl, chn, cor, egy, golf57, idn, jpn, meme, mex, mys, nde, noan, noap, nor, osea, rcam, ris, rjan57, rsaf, rsam, rsas, rus, sui, tha, tur, ukr, usa, vnm, zaf, oeu)
# Grand coalitions (all)
grand.(aut, bel, bgr, cro, dnk, esp, fin, fra, grc, hun, irl, ita, nld, pol, prt, rcz, rfa, rom, rsl, slo, swe, blt, gbr, arg, aus, bra, can, chl, chn, cor, egy, golf57, idn, jpn, meme, mex, mys, nde, noan, noap, nor, osea, rcam, ris, rjan57, rsaf, rsam, rsas, rus, sui, tha, tur, ukr, usa, vnm, zaf, oeu)
/;

# Control set for active coalitions
SET cltsolve(clt);
* Initialized to no
cltsolve(clt) = no;

cltsolve('eu27') = yes;
cltsolve('noneu27') = yes;


##  BEFORE SOLVE
#_________________________________________________________________________
$elseif.ph %phase%=='before_solve'

#===============================================================================
*     ///////////////////////     REPORTING     ///////////////////////
#===============================================================================

##  GDX ITEMS
#_________________________________________________________________________
$elseif.ph %phase%=='gdx_items'

clt
map_clt_n


$endif.ph
