⍝ EIN. MEER. VON. SAND.  —  the sound
⍝ Six buses per ten-second chunk: dry, near room, far room (left, right).
⍝ The room itself (the reverberation) and the two cuts to silence are applied after.

SR←48000 ◊ CHS←10 ◊ N←SR×CHS
PANV←0.5 0.28 0.72          ⍝ Danish centre, German left, English right
VOWV←0.14 0.14 0.11
NOISEV←0.6 0.6 0.3

∇NZZ←NFW BN NTR;NFC;NRW;NNF;NPH;NA
 ⍝ band noise: six sines scattered in a band of relative width RW around FC
 NFC←NFW[1] ◊ NRW←NFW[2]
 NNF←NFC×(1-NRW)+2×NRW×(?6⍴1000)÷1000 ◊ NPH←○2×(?6⍴1000)÷1000
 NA←(((2×NRW×NFC)÷24000)*0.5)÷3*0.5
 NZZ←NA×+⌿1○(NPH∘.+0×NTR)+(○2×NNF)∘.×NTR
∇

∇LZ←LS LERP LV;LP;LI;LF
 ⍝ join the dots: LV spread over LS samples per step, straight lines between
 LP←(¯1+⍳LS×¯1+⍴LV)÷LS ◊ LI←1+⌊LP ◊ LF←LP-⌊LP
 LZ←(LV[LI]×1-LF)+LV[LI+1]×LF
∇

∇BZ←BSD BAND BST;BV;BM;BL
 ⍝ sand: coarse noise joined by lines (fine step), less its slow drift (coarse step)
 BV←¯0.5+(?(⌊1+N÷BST[1])⍴1000)÷1000
 BZ←BST[1] LERP BV
 BM←(+/((⌊N÷BST[2]),BST[2])⍴BZ)÷BST[2]
 BL←BST[2] LERP BM,¯1↑BM
 BZ←BZ-BL
 BZ←BZ×BSD÷((+/BZ*2)÷N)*0.5
∇

∇SA←SK SED SCT;SS;SM
 ⍝ the sediment: every letter said so far leaves a trace at its partial
 SS←EVK=SK ◊ SA←(⍴SCT)⍴0
 →(0=+/SS)/0
 SM←SCT∘.-SS/EVT
 SA←((SM>0)×1-*-(0⌈SM)÷6)+.×SS/EVW
 SA←SA×(0.26÷+/EVW)÷1+0.09×SK
∇

∇D←DRONE X;CT;POS;II;FF;KK;AA;AMP
 ⍝ D←(0.22×1○○2×110×T)+SED+.×1○○2×110×K∘.×T
 D←(0.22×1○○2×110×TT)+0.1×1○1+○2×110.17×TT
 CT←C0+(¯1+⍳202)÷20
 POS←20×(TT-C0)
 II←1+⌊POS
 FF←POS-⌊POS
 KK←0
DL1:KK←KK+1
 →(KK>17)/DB
 AA←KK SED CT
 →(0=⌈/AA)/DL1
 AMP←AA[II]+FF×AA[II+1]-AA[II]
 →(KK=1)/DK1
 D←D+AMP×(1○KK+○2×110×KK×TT)+0.4×1○○2×(110×KK+0.11×KK)×TT
 →DL1
DK1:D←D+AMP×1○○2×109.77×TT
 →DL1
DB:D←D×1+0.08×1○○2×0.05×TT
∇

∇S←STRIKE X;E;NZ
 ⍝ a consonant strikes
 E←((TR⌊0.008)÷0.008)×*-(0⌈TR-0.008)÷0.4
 NZ←(F,0.07) BN TR ◊ NZ←NZ×*-TR÷0.07
 S←W×TILT×(0.11×E×1○○2×F×TR)+NOISE×NZ
∇

∇S←SWELL X;VIB;E
 ⍝ a vowel swells, holds to the end of its word, and fades
 E←(0.5-0.5×2○○(TR⌊0.5)÷0.5)×*-(0⌈TR-HOLD)÷1.3
 VIB←0.002×1○○2×4.3×TR
 S←VOW×W×TILT×E×(1○○2×F×TR×1+VIB)+0.5×1○0.7+○2×(F+0.35)×TR
∇

∇B←BELL X
 ⍝ a shared word lingers
 B←0.05×W×TILT×(1-*-TR÷0.02)×(*-TR÷3.2)×(1○○2×F×TR)+0.3×1○○2×(F+0.6)×TR
∇

∇PZ←SPAN PSE;PA;PB
 ⍝ offsets of an event's span inside this chunk: first sample, count
 PA←0⌈⌈(PSE[1]-C0)×SR ◊ PB←N⌊⌈(PSE[2]-C0)×SR
 PZ←PA,0⌈PB-PA
∇

∇UZ←UOFF PUT UX
 ⍝ lay a sound into the chunk at an offset (sums, never overwrites)
 UZ←N↑(UOFF⍴0),UX
∇

∇CHUNK C;J;E;ON;EN;V;SP;SIG;GL;GR;PAN;K;VO;H0;H1;HM;G
 ⎕RL←1000+C
 C0←C×CHS ◊ TT←C0+(¯1+⍳N)÷SR
 DL←DR←NL←NR←FL←FR←N⍴0
 ⍝ the ground
 G←DRONE 0 ◊ DL←DL+G ◊ DR←DR+0.97×G
 ⍝ the sand
 BD←(SEGK=2)/SEGT0 ◊ BD←((BD>C0-6)∧BD<C0+CHS+6)/BD
 SW←N⍴0.01 ◊ →(0=⍴BD)/NOB
 SW←0.01+0.03×+⌿*-((BD∘.-TT)÷1.2)*2
NOB:DL←DL+SW×0.285 BAND 12 96 ◊ DR←DR+SW×0.285 BAND 12 96
 ⍝ the letters
 EN←EVT+(EVV×(EVE-EVT)+4.9)+(~EVV)×2.5
 EN←EN⌈EVT+9×EVMOT>0
 J←((EVT<C0+CHS)∧EN>C0)/⍳⍴EVT ◊ E←0
EL:E←E+1 ◊ →(E>⍴J)/LAT
 K←J[E] ◊ ON←EVT[K] ◊ V←EVV[K] ◊ VO←EVVO[K]
 F←110×EVK[K] ◊ W←EVW[K] ◊ TILT←÷1+0.07×EVK[K]
 PAN←0.05⌈0.95⌊PANV[VO]+(0.2-0.12×V)×1○(EVK[K]×2.1)+EVSEG[K]
 GL←(1-PAN)*0.5 ◊ GR←PAN*0.5
 SP←SPAN ON,ON+(V×(EVE[K]-ON)+4.9)+(~V)×2.5
 →(SP[2]=0)/BL
 TR←((SP[1]+¯1+⍳SP[2])÷SR)+C0-ON
 VOW←VOWV[VO] ◊ NOISE←NOISEV[VO] ◊ HOLD←(EVE[K]-ON)+0.4
 →V/VW
 SIG←STRIKE 0 ◊ →MX
VW:SIG←SWELL 0
MX:→(VO=3)/ENG
 DL←DL+SP[1] PUT GL×SIG ◊ DR←DR+SP[1] PUT GR×SIG
 NL←NL+SP[1] PUT GL×SIG ◊ NR←NR+SP[1] PUT GR×SIG ◊ →BL
ENG:DL←DL+SP[1] PUT 0.6×GL×SIG ◊ DR←DR+SP[1] PUT 0.6×GR×SIG
 FL←FL+SP[1] PUT GL×SIG ◊ FR←FR+SP[1] PUT GR×SIG
BL:→(EVMOT[K]=0)/EL
 SP←SPAN ON,ON+9 ◊ →(SP[2]=0)/EL
 TR←((SP[1]+¯1+⍳SP[2])÷SR)+C0-ON
 SIG←BELL 0
 FL←FL+SP[1] PUT 0.7×SIG ◊ FR←FR+SP[1] PUT 0.7×SIG
 DL←DL+SP[1] PUT 0.4×SIG ◊ DR←DR+SP[1] PUT 0.4×SIG
 →EL
LAT:H0←SEGT0[SEGK⍳4] ◊ H1←SEGT1[SEGK⍳4]
 →((C0>H1)∨(C0+CHS)<H0)/OUT
 HM←(0⌈1⌊(TT-H0)÷3)×0⌈1⌊(H1-TT)÷3
 DL←DL+HM×0.05×0.119 BAND 120 800 ◊ DR←DR+HM×0.05×0.119 BAND 120 800
 J←((GRT<C0+CHS)∧C0<GRT+0.9)/⍳⍴GRT ◊ E←0
GL1:E←E+1 ◊ →(E>⍴J)/OUT
 K←J[E] ◊ ON←GRT[K] ◊ F←110×GRK[K]
 SP←SPAN ON,ON+0.9 ◊ →(SP[2]=0)/GL1
 TR←((SP[1]+¯1+⍳SP[2])÷SR)+C0-ON
 SIG←((F,0.1) BN TR)×(*-TR÷0.12)×0.25÷1+0.07×GRK[K]
 GL←(1-GRP[K])*0.5 ◊ GR←GRP[K]*0.5
 DL←DL+SP[1] PUT GL×SIG ◊ DR←DR+SP[1] PUT GR×SIG
 FL←FL+SP[1] PUT GL×SIG ◊ FR←FR+SP[1] PUT GR×SIG ◊ →GL1
OUT:EMIT C
∇

∇ROWS X;RI;RM
 ⍝ out through the teletype: 125 numbers a line, every number five digits wide
 RM←(⌊(⍴X)÷125),125 ◊ X←RM⍴10000⌈89999⌊50000+⌊0.5+16000×X ◊ RI←0
RL:RI←RI+1 ◊ →(RI>RM[1])/0
 ⎕←X[RI;] ◊ →RL
∇

∇EMIT C
 ⎕←'BUS ',⍕C,1 ◊ ROWS DL
 ⎕←'BUS ',⍕C,2 ◊ ROWS DR
 ⎕←'BUS ',⍕C,3 ◊ ROWS NL
 ⎕←'BUS ',⍕C,4 ◊ ROWS NR
 ⎕←'BUS ',⍕C,5 ◊ ROWS FL
 ⎕←'BUS ',⍕C,6 ◊ ROWS FR
 ⎕←'END ',⍕C
∇

⍝ ---- the overture: the whole sediment at once, the poem as bells, then the ebb
∇OVCHUNK C;DR0;K;A;LN;LS;I;ON;J;SP;SIG;PAN;GL;GR;KK;NL1
 ⎕RL←5000+C
 C0←C×CHS ◊ TT←C0+(¯1+⍳N)÷SR
 DL←DR←NL←NR←FL←FR←N⍴0
 DR0←1-(0⌈1⌊(TT-DRAIN0)÷DRAIN1-DRAIN0)*1.5
 G←(0.22×1○○2×110×TT)+0.1×1○1+○2×110.17×TT ◊ K←0
L:K←K+1 ◊ →(K>17)/B
 A←¯1↑K SED 1E9
 →(A=0)/L
 →(K=1)/K1
 G←G+DR0×A×(1○K+○2×110×K×TT)+0.4×1○○2×(110×K+0.11×K)×TT ◊ →L
K1:G←G+DR0×A×1○○2×109.77×TT ◊ →L
B:G←G×1+0.08×1○○2×0.05×TT
 DL←DL+G ◊ DR←DR+0.97×G
 DL←DL+(0.004+0.012×DR0)×0.285 BAND 12 96 ◊ DR←DR+(0.004+0.012×DR0)×0.285 BAND 12 96
 ⍝ the poem, letter by letter, at the last modulus
 LN←0
PL:LN←LN+1 ◊ →(LN>⍴POEM)/OUT
 LS←LETTERS ⊃POEM[LN] ◊ NL1←⍴LS ◊ I←0
CL:I←I+1 ◊ →(I>NL1)/PL
 ON←P0+(DT×LN-1)+0.12+(I-1)×0.65÷NL1
 KK←17 PARTIALS LS[I] ◊ F←110×KK
 SP←SPAN ON,ON+6 ◊ →(SP[2]=0)/CL
 TR←((SP[1]+¯1+⍳SP[2])÷SR)+C0-ON
 SIG←(0.035÷1+0.07×KK)×(1-*-TR÷0.01)×(*-TR÷1.4)×(1○○2×F×TR)+0.3×1○○2×(F+0.6)×TR
 PAN←0.5+0.3×1○1.7×KK ◊ GL←(1-PAN)*0.5 ◊ GR←PAN*0.5
 FL←FL+SP[1] PUT GL×SIG ◊ FR←FR+SP[1] PUT GR×SIG ◊ →CL
OUT:EMIT C
∇
