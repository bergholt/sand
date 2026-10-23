⍝ EIN. MEER. VON. SAND.  —  the score
⍝ A fixed A2; each letter a partial: alphabet position modulo M.
⍝ Danish Æ Ø Å continue the alphabet. The modulus drifts, 12 → 17.

⎕IO←1
⎕PP←12
ALPHA←'ABCDEFGHIJKLMNOPQRSTUVWXYZÆØÅ'
LOWER←'abcdefghijklmnopqrstuvwxyzæøå'
DIGITS←'0123456789'
VOWELS←'AEIOUYÆØÅ'
F0←110

∇Z←UP S;I;J
 S←,S ◊ I←LOWER⍳S ◊ J←I≤⍴LOWER
 Z←(ALPHA,S)[(J×I)+(~J)×(⍴ALPHA)+⍳⍴S]
∇

∇Z←LETTERS S;U
 U←UP S
 Z←(U∈ALPHA,DIGITS)/U
∇

∇K←M PARTIALS S;A;D
 ⍝ the rule: position in the alphabet, modulo M (a remainder of 0 counts as M)
 A←ALPHA⍳S ◊ D←DIGITS⍳S
 K←((A≤⍴ALPHA)×M|A)+(D≤10)×M|D-1
 K←K+M×K=0
∇

∇Z←SPLIT S;M
 M←S≠' '
 Z←((+\M∧~¯1↓0,M)×M)⊂S
∇

∇Z←P IN S;N
 N←⍴P ◊ Z←0
 →(N>⍴S)/0
 Z←∨/(S[(0,⍳(⍴S)-N)∘.+⍳N])∧.=P
∇

∇Z←N WRAP S;W;L;I;C
 W←SPLIT S ◊ Z←0⍴⊂'' ◊ L←'' ◊ I←0
LP:→(I≥⍴W)/END
 I←I+1 ◊ C←⊃W[I]
 →(0=⍴L)/NEW
 →((1+(⍴L)+⍴C)>N)/BRK
 L←L,' ',C ◊ →LP
BRK:Z←Z,⊂L
NEW:L←C ◊ →LP
END:Z←Z,⊂L
∇

⍝ ---- tempo follows meaning: lists rush, the royal names slow, the date stands alone
LIST←SPLIT 'STROHM AECKER WIESEN DOERFFER HUTTEN VOGNE FOLK HESTE STREAMS FIELDS MEADOWS VILLAGES COTTAGES WAGONS MEN HORSES FELD WALD'
ROYAL←SPLIT 'KONG KOENIG FREDERICH FRIDERICH FRIDERICHS FREDERIK KING KINGS CHRISTIAN CHRISTIANS SIETTE SECHSTE SIXTH FOURTH VIERTE HERLIGHED GLORY MONARCHEN MONARCH NORDEN NORTH'

∇Z←TEMPO W;U
 U←LETTERS W ◊ Z←1
 →(U≡'1738')/Y
 →((⊂U)∈LIST)/L
 →((⊂U)∈ROYAL)/R
 →0
Y:Z←3.2 ◊ →0
L:Z←0.62 ◊ →0
R:Z←1.4
∇

⍝ ---- words the three languages share: motifs
MOTIFS←'sand' 'gram' 'rohl' 'frederik' 'christian' '1738' 'sea' 'wind'
∇Z←MOTIF W;U
 U←LETTERS W ◊ Z←0
 →('SAND' IN U)/M1
 →((⊂U)∈'GRAM' 'GRAMS')/M2
 →((⊂U)∈'RØHL' 'ROEHLS')/M3
 →((⊂U)∈'FREDERICH' 'FREDERIK' 'FRIDERICH' 'FRIDERICHS')/M4
 →((⊂U)∈'CHRISTIAN' 'CHRISTIANS')/M5
 →(U≡'1738')/M6
 →((⊂U)∈'MEER' 'SEE' 'SEA' 'HAFVET' 'SHORES')/M7
 →((⊂U)∈'WIND' 'VINDEN')/M8
 →0
M1:Z←1 ◊ →0
M2:Z←2 ◊ →0
M3:Z←3 ◊ →0
M4:Z←4 ◊ →0
M5:Z←5 ◊ →0
M6:Z←6 ◊ →0
M7:Z←7 ◊ →0
M8:Z←8
∇

∇Z←A UNI B
 Z←A+(B-A)×(¯1+?1000000)÷999999
∇

⍝ ---- the form
PRELUDE←12 ◊ SIL1←5 ◊ HINGE←30 ◊ SIL2←6 ◊ CODA←26 ◊ TAIL←1 ◊ GAP←2.6
⍝ voices: 1 Danish · 2 German · 3 English
VNAMES←'da' 'de' 'en'
TXT←(S1DA S1DE S1EN)(S2DA S2DE S2EN)
ORDER←(2 1 3)(3 1 2)      ⍝ I: German, Danish, English   II: English, Danish, German
MODS←(12 12 12)(13 14 15 16 17)
ENTRY←(0.6 0.55 0.5)(0.5 0.42 0.35 0.28 ¯1)

∇Z←SX VLINES VU;QV;QU;QP;QA;QB
 QV←VU[1] ◊ QU←VU[2]
 QA←⊃TXT[SX] ◊ QB←⊃QA[QV] ◊ QP←⊃QB[QU]
 →(QV=3)/EN
 Z←QP ◊ →0
EN:Z←(58 WRAP ⊃QP[1]),58 WRAP ⊃QP[2]
∇

∇ADDSEG R
 ⍝ kind t0 t1 voice section unit modulus   (kinds: 1 prelude 2 voice 3 silence 4 latin 5 coda)
 SEGK←SEGK,R[1] ◊ SEGT0←SEGT0,R[2] ◊ SEGT1←SEGT1,R[3] ◊ SEGV←SEGV,R[4]
 SEGS←SEGS,R[5] ◊ SEGU←SEGU,R[6] ◊ SEGM←SEGM,R[7] ◊ SEGL←SEGL,⊂CURLINES
∇

∇T←RATE BUILD X;SEC;U;VI;V;LINES;START;END;FLE;TT;LI;WS;WI;W;LS;TM;D;M;E;SI;SOLO;NU;MM;EE;OO
 ⎕RL←1738
 SEGK←SEGT0←SEGT1←SEGV←SEGS←SEGU←SEGM←⍳0 ◊ SEGL←0⍴⊂''
 WSEG←WLI←WT0←WT1←WMOT←WSOLO←⍳0 ◊ WTXT←0⍴⊂''
 CURLINES←0⍴⊂'' ◊ ADDSEG 1 0,PRELUDE,0 0 0 0
 T←PRELUDE ◊ SEC←0
SECL:SEC←SEC+1 ◊ →(SEC>2)/FIN
 →(SEC=1)/US
 ADDSEG 3,T,(T+SIL1),0 0 0 0 ◊ T←T+SIL1
 ADDSEG 4,T,(T+HINGE),0 0 0 0 ◊ T←T+HINGE
US:U←0
UL:U←U+1 ◊ NU←3 5 ◊ →(U>NU[SEC])/SECL
 MM←⊃MODS[SEC] ◊ M←MM[U] ◊ EE←⊃ENTRY[SEC] ◊ E←EE[U] ◊ OO←⊃ORDER[SEC]
 START←T ◊ END←T ◊ VI←0
VL:VI←VI+1 ◊ →(VI>3)/UE
 V←OO[VI] ◊ SI←1+⍴SEGK
 LINES←SEC VLINES V,U ◊ TT←START ◊ LI←0
LNL:LI←LI+1 ◊ →(LI>⍴LINES)/LND
 WS←SPLIT ⊃LINES[LI] ◊ WI←0
WNL:WI←WI+1 ◊ →(WI>⍴WS)/LNL
 W←⊃WS[WI] ◊ LS←LETTERS W
 →(0=⍴LS)/WNL
 SOLO←(VI=1)∧LI=1
 TM←(TEMPO W)×(1+0.3×SOLO)×0.85 UNI 1.18
 →(~LS≡'1738')/NY1 ◊ TT←TT+1.2
NY1:D←RATE×((⍴LS)+2)×TM
 WSEG←WSEG,SI ◊ WLI←WLI,LI ◊ WT0←WT0,TT ◊ WT1←WT1,TT+D
 WMOT←WMOT,MOTIF W ◊ WSOLO←WSOLO,SOLO ◊ WTXT←WTXT,⊂W
 TT←TT+D
 →(~LS≡'1738')/WNL ◊ TT←TT+1.2 ◊ →WNL
LND:TT←TT+TAIL
 CURLINES←LINES ◊ ADDSEG 2,START,TT,V,SEC,U,M
 END←END⌈TT
 →(VI≠1)/NF
 FLE←0.4+⌈/((WSEG=SI)∧WLI=1)/WT1
NF:→(E<0)/NOE
 START←(START+(TT-START)×E×0.85 UNI 1.15)⌈(FLE×VI=1)+START×VI≠1 ◊ →VL
NOE:START←FLE ◊ →VL
UE:T←END+GAP ◊ →UL
FIN:CURLINES←0⍴⊂''
 ADDSEG 3,T,(T+SIL2),0 0 0 0 ◊ T←T+SIL2
 ADDSEG 5,T,(T+CODA),0 0 0 0 ◊ T←T+CODA
∇

∇SOLVE;LO;HI;MID;I
 ⍝ the speaking rate that would fill eleven minutes, then thirty per cent faster
 LO←0.01 ◊ HI←1 ◊ I←0
L:I←I+1 ◊ →(I>36)/D
 MID←(LO+HI)÷2
 →(660<MID BUILD 0)/H
 LO←MID ◊ →L
H:HI←MID ◊ →L
D:RATE←LO÷1.3 ◊ TEND←RATE BUILD 0
∇

∇EVENTS;WI;S;LS;D;LINE;CNT;MX;I;N;M;SL
 ⎕RL←7
 EVT←EVE←EVK←EVW←EVV←EVSEG←EVWI←EVI←EVMOD←EVMOT←EVN←EVMX←EVVO←⍳0 ◊ EVCH←''
 WI←0
L:WI←WI+1 ◊ →(WI>⍴WT0)/0
 S←WSEG[WI] ◊ LS←LETTERS ⊃WTXT[WI] ◊ N←⍴LS ◊ D←WT1[WI]-WT0[WI]
 SL←⊃SEGL[S] ◊ LINE←LETTERS ⊃SL[WLI[WI]]
 CNT←+⌿LINE∘.=LS ◊ MX←⌈/+⌿LINE∘.=LINE ◊ M←SEGM[S] ◊ I←¯1+⍳N
 EVT←EVT,WT0[WI]+(I×0.55×D÷N)+(~WSOLO[WI])×¯0.05+0.1×(?N⍴1000)÷1000
 EVE←EVE,N⍴WT1[WI] ◊ EVK←EVK,M PARTIALS LS ◊ EVW←EVW,(CNT÷MX)*0.8
 EVV←EVV,LS∈VOWELS,DIGITS ◊ EVSEG←EVSEG,N⍴S ◊ EVWI←EVWI,N⍴WI ◊ EVI←EVI,I
 EVMOD←EVMOD,N⍴M ◊ EVMOT←EVMOT,N⍴WMOT[WI] ◊ EVN←EVN,CNT ◊ EVMX←EVMX,N⍴MX
 EVVO←EVVO,N⍴SEGV[S] ◊ EVCH←EVCH,LS
 →L
∇

⍝ ---- the Latin face: letters without notes, at random, in the dark
∇LATIN;H0;H1;T
 ⎕RL←3 ◊ H0←SEGT0[SEGK⍳4] ◊ H1←SEGT1[SEGK⍳4]
 GRT←GRK←GRP←⍳0 ◊ T←H0+1.5
L:→(T≥H1-1.5)/0
 GRT←GRT,T ◊ GRK←GRK,?12 ◊ GRP←GRP,0.2 UNI 0.8
 T←T-0.45×⍟(?1000)÷1000.5 ◊ →L
∇

⍝ ---- the overture: the poem, sped up
HALF←0.5 ◊ P0←5×HALF ◊ DT←(2.3÷1.3)×HALF
DRAIN0←P0+(21×DT)+2.7×HALF ◊ DRAIN1←DRAIN0+8×HALF ◊ OV←DRAIN1+4×HALF

∇PRINTSCORE;I;J;SL
 ⎕←'RATE|',⍕RATE ◊ ⎕←'T|',⍕TEND
 ⎕←'OV|',⍕P0 DT DRAIN0 DRAIN1 OV
 I←0
S:I←I+1 ◊ →(I>⍴SEGK)/W
 ⎕←'SEG|',⍕SEGK[I],SEGT0[I],SEGT1[I],SEGV[I],SEGS[I],SEGU[I],SEGM[I]
 J←0 ◊ SL←⊃SEGL[I]
SLL:J←J+1 ◊ →(J>⍴SL)/S
 ⎕←'LINE|',(⍕I,J),'|',⊃SL[J] ◊ →SLL
W:I←0
WL:I←I+1 ◊ →(I>⍴WT0)/E
 ⎕←'WORD|',(⍕WSEG[I],WLI[I],WT0[I],WT1[I],WMOT[I],WSOLO[I]),'|',⊃WTXT[I] ◊ →WL
E:I←0
EL:I←I+1 ◊ →(I>⍴EVT)/G
 ⎕←'EV|',(⍕EVT[I],EVE[I],EVK[I],EVW[I],EVV[I],EVSEG[I],EVWI[I],EVI[I],EVMOD[I],EVMOT[I],EVN[I],EVMX[I],EVVO[I]),'|',EVCH[I] ◊ →EL
G:I←0
GL:I←I+1 ◊ →(I>⍴GRT)/P
 ⎕←'GR|',⍕GRT[I],GRK[I],GRP[I] ◊ →GL
P:I←0
PL:I←I+1 ◊ →(I>⍴POEM)/0
 ⎕←'POEM|',⊃POEM[I] ◊ →PL
∇
