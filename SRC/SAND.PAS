program Sand;
{ EIN. MEER. VON. SAND.
  A demo in Turbo Pascal 7 for MS-DOS: VGA 320x200, 64 greys, Sound Blaster 16.

  The letters of the Tisvilde sand drift monument (1738), in German, Danish and English,
  are read by one rule: each letter is a partial of a fixed A2 (110 Hz), its alphabet position
  modulo M, with Danish AE, OE, AA continuing the alphabet (27, 28, 29). The modulus drifts from
  12 to 17. The soundtrack (SAND.SND) was synthesised from the same score; this program shows
  the letters as they sound, the rule working in Pascal, and every letter falling into the sea.

  Compile:  TPC SAND.PAS           (Turbo Pascal 7; SCOREDAT, FONT8, VGA, SND, ENDSCR are units)
  Run:      SAND                   (needs SAND.SND in the same directory; ESC quits)
            SAND 300               (begins five minutes in)
  Test:     define SIM to build a frame renderer instead (Free Pascal -Mtp -dSIM). }

{$N+,E+}
{$M 16384,0,655360}

uses {$IFNDEF SIM} Dos, EndScr, {$ENDIF} ScoreDat, Font8, Vga, Snd;

const
  Y_H = 104;            { the sea horizon }
  Y_S = 236;            { the shore, just below the screen }
  NGMAX = 4200;
  ColX: array[1..3] of Integer = (160, 53, 267);   { Danish centre, German left, English right }

type
  TGrain = record
    Birth: Word;          { centiseconds into the piece }
    Ch: Char;
    Lang: Byte;           { 0 seed, 1 Danish, 2 German, 3 English, 4 code }
    Z0: Word;             { depth, 8.8 fixed point }
    LnZ, Ph, A0: Byte;
    U: ShortInt;          { across the beach, -127..127 }
    OX, OY: Integer;      { where the letter left the text (OY < 0: nowhere) }
  end;
  TGrains = array[1..NGMAX] of TGrain;
  PGrains = ^TGrains;

var
  G: PGrains;
  NG: Integer;
  Rel: array[1..NWORD] of Word;          { when each word leaves its line }
  SinT, CrestT: array[0..255] of Integer;
  Ang: Single;
  MotifOn: array[0..8] of Boolean;
  VoiceE: array[1..3] of Single;

{ ------------------------------------------------------------------ the rule }

function Position(C: Char): Integer;
{ the alphabet is an order; Danish continues it; digits are themselves (+100) }
begin
  case C of
    'A'..'Z': Position := Ord(C) - 64;
    'a'..'z': Position := Ord(C) - 96;
    #198, #230: Position := 27;           { AE ae }
    #216, #248: Position := 28;           { OE oe }
    #197, #229: Position := 29;           { AA aa }
    '0'..'9': Position := 100 + Ord(C) - 48;
  else Position := 0;
  end;
end;

function Sounding(C: Char): Boolean;
begin
  Sounding := Position(C) > 0;
end;

function Partial(C: Char; M: Integer): Integer;
{ k := position mod M, a remainder of 0 counts as M }
var P, K: Integer;
begin
  P := Position(C);
  if P >= 100 then P := P - 100;
  K := P mod M;
  if K = 0 then K := M;
  Partial := K;
end;

function IsVowel(C: Char): Boolean;
begin
  IsVowel := (Position(C) >= 100) or
    (UpCase(C) in ['A', 'E', 'I', 'O', 'U', 'Y']) or (C in [#198, #230, #216, #248, #197, #229]);
end;

function Weight(C: Char; LineNo: Integer): Single;
{ recurrence is loudness: (count in the line / count of the most frequent letter) ^ 0.8 }
var Cnt: array[0..129] of Integer; I, P, Mx: Integer; S: string;
begin
  FillChar(Cnt, SizeOf(Cnt), 0);
  S := Lines[LineNo]; Mx := 1;
  for I := 1 to Length(S) do
  begin
    P := Position(S[I]);
    if P > 0 then begin Inc(Cnt[P]); if Cnt[P] > Mx then Mx := Cnt[P]; end;
  end;
  P := Position(C);
  if Cnt[P] = 0 then Weight := 1
  else Weight := Exp(0.8 * Ln(Cnt[P] / Mx));
end;

{ ------------------------------------------------------------------ small tools }

function Ease(X: Single): Single;
begin
  if X < 0 then X := 0;
  if X > 1 then X := 1;
  Ease := 1 - (1 - X) * (1 - X) * (1 - X);
end;

function Clip(X, A, B: Single): Single;
begin
  if X < A then X := A;
  if X > B then X := B;
  Clip := X;
end;

function IStr(N: LongInt): string;
var S: string;
begin
  Str(N, S); IStr := S;
end;

function WordText(I: Integer): string;
begin
  WordText := Copy(Lines[Words[I].Line], Words[I].Pos, Words[I].Len);
end;

function NLetters(const S: string): Integer;
var I, N: Integer;
begin
  N := 0;
  for I := 1 to Length(S) do if Sounding(S[I]) then Inc(N);
  NLetters := N;
end;

function Rnd(A, B: Single): Single;
begin
  Rnd := A + (B - A) * Random;
end;

function Env(Vowel: Boolean; Tr, Hold: Single): Single;
{ a vowel swells, holds to the end of its word and fades; a consonant strikes }
var E: Single;
begin
  if Tr < 0 then begin Env := 0; Exit; end;
  if Vowel then
  begin
    if Tr < 0.5 then E := 0.5 - 0.5 * Cos(Pi * Tr / 0.5) else E := 1;
    if Tr > Hold then E := E * Exp(-(Tr - Hold) / 1.3);
  end
  else if Tr < 0.008 then E := Tr / 0.008
  else E := Exp(-(Tr - 0.008) / 0.4);
  Env := E;
end;

{ ------------------------------------------------------------------ preparing the sediment }

procedure SortGrains;
var Gap, I, J: Integer; T: TGrain;
begin
  Gap := NG div 2;
  while Gap > 0 do
  begin
    for I := Gap + 1 to NG do
    begin
      T := G^[I]; J := I;
      while (J > Gap) and (G^[J - Gap].Birth > T.Birth) do
      begin
        G^[J] := G^[J - Gap]; J := J - Gap;
      end;
      G^[J] := T;
    end;
    Gap := Gap div 2;
  end;
end;

procedure AddGrain(Birth: LongInt; C: Char; Lang: Byte; OX, OY: Integer; A0: Integer);
var Z: Single;
begin
  if NG >= NGMAX then Exit;
  Inc(NG);
  if Birth < 0 then Birth := 0;
  if Birth > 65000 then Birth := 65000;
  Z := Exp(Rnd(Ln(1.12), Ln(11)));
  G^[NG].Birth := Birth;
  G^[NG].Ch := C;
  G^[NG].Lang := Lang;
  G^[NG].Z0 := Round(Z * 256);
  G^[NG].LnZ := Round(2.3 * Ln(Z) * 256 / (2 * Pi)) and 255;
  G^[NG].Ph := Random(256);
  G^[NG].A0 := A0;
  if OY >= 0 then G^[NG].U := Round(Clip((OX - 160) / 198 + Rnd(-0.12, 0.12), -1, 1) * 127)
  else G^[NG].U := Random(255) - 127;
  G^[NG].OX := OX; G^[NG].OY := OY;
end;

procedure Prepare;
const Seed: string[6] = 'SANDAE';
      CodeCh: string[33] = 'k:=mod;f110*w{}()0123456789strike';
var I, J, S, N, K, V: Integer; W: string; Cap, SegNext: LongInt; T: LongInt;
begin
  RandSeed := 1738;
  for I := 0 to 255 do
  begin
    SinT[I] := Round(256 * Sin(2 * Pi * I / 256));
    CrestT[I] := Round(256 * Exp(3 * Ln((Sin(2 * Pi * I / 256) + 1) / 2 + 1E-6)));
  end;
  { when each word leaves its line: some seconds after it has sounded, or at the next silence }
  for I := 1 to NWORD do
  begin
    T := Words[I].T1 + Round(Rnd(300, 1600));
    for S := 1 to NSEG do
      if (Segs[S].Kind = 3) and (Segs[S].T0 > Words[I].T0) and (Segs[S].T0 < T) then
        T := Segs[S].T0 + Random(80);
    V := Segs[Words[I].Seg].Voice;
    for S := Words[I].Seg + 1 to NSEG do
      if (Segs[S].Kind = 2) and (Segs[S].Voice = V) then
      begin
        SegNext := LongInt(Segs[S].T0) - 120;
        if (SegNext > Words[I].T0) and (SegNext < T) then T := SegNext;
        Break;
      end;
    Rel[I] := T;
  end;
  { the sediment: a few grains to begin with, then every letter, and a little of the code }
  New(G); NG := 0;
  for I := 1 to 90 do AddGrain(0, Seed[1 + Random(6)], 0, 0, -1, 5 + Random(7));
  for I := 1 to NWORD do
  begin
    W := WordText(I); V := Segs[Words[I].Seg].Voice;
    N := NLetters(W); K := 0;
    for J := 1 to Length(W) do
      if Sounding(W[J]) then
      begin
        AddGrain(LongInt(Rel[I]) + Random(60), W[J], V, ColX[V] + Random(81) - 40, 30, 12 + Random(22));
        Inc(K);
        if K mod 3 = 0 then
          AddGrain(Words[I].T0 + Round((K - 1) * 0.55 * (Words[I].T1 - Words[I].T0) / N) + 30,
                   CodeCh[1 + Random(Length(CodeCh))], 4, ColX[V] - 52 + Random(100), 70 + Random(30), 6 + Random(12));
      end;
  end;
  SortGrains;
  Ang := 0;
end;

{ ------------------------------------------------------------------ the sea, seen from the shore }

procedure DrawSea(Tc: LongInt; Alive: Integer; Grow, Calm, Pulse: Single; FullRamp: Boolean);
var I: Integer;
    TPh, AngI, Phi, Ed, K127, KZ, A256, Zb, Reach, Gp, Back, Crest, Dpt, Lp: LongInt;
    Z, SX, SY, U2, Age, A, C2, P256, M: LongInt;
    T: Single;
    LpV: array[0..4] of LongInt;
begin
  T := Tc / 100;
  TPh := Round(T * 46.9) and 255;
  AngI := Round(Ang * 40.7);
  A256 := Round((0.10 + 0.34 * Grow) * Calm * 256);
  Zb := Round((3.4 - 2.2 * Grow) * 256);
  K127 := Round((0.04 + 0.12 * Grow) * 127);
  KZ := Round((0.05 + 0.10 * Grow) * 256);
  C2 := Round((2.1 * Calm + 0.3) * 256);
  P256 := Round(Pulse * 256);
  LpV[0] := 256; LpV[4] := 256;
  for I := 1 to 3 do LpV[I] := Round((0.7 + 1.2 * VoiceE[I]) * 256);
  for I := 1 to Alive do
    with G^[I] do
    begin
      Phi := (TPh + LnZ + (AngI * U) div 127 + Ph div 4
              + (22 * SinT[((U * 33) div 127 + Round(T * 4.48)) and 255]) div 256) and 255;
      Gp := SinT[Phi] + (35 * LongInt(SinT[(2 * Phi) and 255])) div 100;
      Reach := ((LongInt(Z0) - Zb) * 256) div 333 + 102;
      if Reach < 31 then Reach := 31;
      if Reach > 256 then Reach := 256;
      M := ((A256 * Reach) div 256) * Gp div 256;
      Z := LongInt(Z0) - (LongInt(Z0) * M * 141 div 256) div 256;
      { the backwash swirls }
      Back := -SinT[(Phi + 64) and 255];
      if Back < 0 then Back := 0;
      Back := (Back * Round(Calm * 256)) div 256;
      Ed := (LongInt(Ph) * 3 + Round(T * 30)) and 255;
      U2 := U + (Back * K127 * SinT[Ed]) div 65536;
      Z := Z + (Z * ((Back * KZ) div 256) * SinT[(Ed + 64) and 255]) div 65536;
      if Z < 264 then Z := 264;
      Crest := (LongInt(CrestT[Phi]) * Reach) div 256;
      if Z < 563 then U2 := U2 + (U2 * Crest * (563 - Z)) div 314368;
      SY := Y_H + (LongInt(Y_S - Y_H) * 256) div Z;
      SX := 160 + ((U2 * 198) div 127) * LongInt(Z0) div Z;
      { letters that have just left the text travel down to their place }
      Age := Tc - Birth;
      if (not FullRamp) and (OY >= 0) and (Age < 300) then
      begin
        SX := OX + ((SX - OX) * Age) div 300;
        SY := OY + ((SY - OY) * Age) div 300;
      end;
      if (SY >= 200) or (SX < -6) or (SX > 325) then Continue;
      { brightness: the crest, the pulse, the voice that is speaking, depth, freshness }
      A := (LongInt(A0) * (41 + (C2 * Crest) div 256)) div 256;
      A := (A * P256) div 256;
      A := (A * LpV[Lang]) div 256;
      Dpt := 340992 div Z;                      { 2.6 * 256 / z, in 1/256 }
      if Dpt > 256 then Dpt := 256;
      A := (A * (90 + (166 * Dpt) div 256)) div 256;
      if (not FullRamp) and (Age < 300) then A := (A * (256 + (410 * (300 - Age)) div 300)) div 256;
      if A < 2 then Continue;
      if A > 63 then A := 63;
      if Z < 563 then DrawChar(SX - 2, SY - 4, Ch, A, 1)
      else AddPix(SX, SY, A);
    end;
end;

{ ------------------------------------------------------------------ the three columns }

procedure DrawColumn(V: Integer; Tc: LongInt; Calm: Single; var Energy: Single);
const MAXR = 40;
var S, I, J, K, N, R, C, First, CurRow, RowCount, Y, X, B, Dy, LetterNo, Cur: Integer;
    Row, Col: array[1..120] of Integer;
    RowLen: array[0..MAXR] of Integer;
    W, L1, L2, L3, L4, L5, Tmp: string;
    T, T0, D, Tr, E, Wt, Hold: Single;
    LastLine, CurWord: Integer;
    Ch: Char;
begin
  Energy := 0;
  T := Tc / 100;
  { this voice's current exchange }
  S := 0;
  for I := 1 to NSEG do
    if (Segs[I].Kind = 2) and (Segs[I].Voice = V) and (LongInt(Segs[I].T0) - 120 <= Tc) then S := I;
  if S = 0 then Exit;
  { wrap the exchange into rows of at most 21 characters }
  R := 0; C := 0; LastLine := -1;
  for I := 0 to MAXR do RowLen[I] := 0;
  for I := 1 to Segs[S].NWords do
  begin
    K := Segs[S].FirstWord + I - 1;
    N := Words[K].Len;
    if (Words[K].Line <> LastLine) or (C + N > 21) then
    begin
      if LastLine <> -1 then Inc(R);
      C := 0; LastLine := Words[K].Line;
    end;
    if R > MAXR then R := MAXR;
    Row[I] := R; Col[I] := C;
    C := C + N + 1;
    RowLen[R] := C - 1;
  end;
  RowCount := R + 1;
  { where the reading is }
  CurRow := 0; CurWord := 0;
  for I := 1 to Segs[S].NWords do
    if Words[Segs[S].FirstWord + I - 1].T0 <= Tc then begin CurRow := Row[I]; CurWord := I; end;
  First := CurRow - 2;
  if First < 0 then First := 0;
  { the letters }
  for I := 1 to Segs[S].NWords do
  begin
    K := Segs[S].FirstWord + I - 1;
    if (Row[I] < First) or (Row[I] > First + 5) then Continue;
    if Tc >= Rel[K] then Continue;
    W := WordText(K);
    N := NLetters(W);
    T0 := Words[K].T0 / 100; D := (Words[K].T1 - Words[K].T0) / 100;
    Hold := D + 0.4;
    X := ColX[V] - (RowLen[Row[I]] * 5) div 2 + Col[I] * 5;
    Y := 6 + (Row[I] - First) * 9;
    LetterNo := 0;
    for J := 1 to Length(W) do
    begin
      Ch := W[J]; Dy := 0;
      if Tc < Words[K].T0 then B := 14 else B := 34;
      if Tc < LongInt(Segs[S].T0) + 80 - 120 then
        B := Round(B * Clip((Tc - (LongInt(Segs[S].T0) - 120)) / 80, 0, 1));
      if Sounding(Ch) then
      begin
        Tr := T - (T0 + LetterNo * 0.55 * D / N);
        E := Env(IsVowel(Ch), Tr, Hold - LetterNo * 0.55 * D / N);
        Energy := Energy + E;
        B := B + Round(29 * E);
        Dy := -Round(3 * E * Calm);
        Inc(LetterNo);
      end;
      if MotifOn[Words[K].Motif] and (Words[K].Motif > 0) then B := B + 16;
      { loosening before it leaves }
      if Rel[K] - Tc < 100 then B := (B * (Rel[K] - Tc)) div 100 + 4;
      if B > 63 then B := 63;
      DrawChar(X + (J - 1) * 5, Y + Dy, Ch, B, 1);
    end;
  end;
  { the Pascal line that is sounding }
  if CurWord = 0 then Exit;
  for I := 1 to NSEG do
    if (Segs[I].Kind = 3) and (Segs[I].T0 > Segs[S].T0) and (Segs[I].T0 <= Tc) then Exit;
  K := Segs[S].FirstWord + CurWord - 1;
  W := WordText(K); N := NLetters(W);
  D := (Words[K].T1 - Words[K].T0) / 100;
  Cur := Trunc((T - Words[K].T0 / 100) / (0.55 * D / N + 1E-6));
  if Cur > N - 1 then Cur := N - 1;
  if Cur < 0 then Cur := 0;
  J := 0; Ch := ' ';
  for I := 1 to Length(W) do
    if Sounding(W[I]) then begin if J = Cur then Ch := W[I]; Inc(J); end;
  Tr := T - (Words[K].T0 / 100 + Cur * 0.55 * D / N);
  C := Segs[S].Modulus;
  N := Partial(Ch, C);
  I := Position(Ch); if I >= 100 then I := I - 100;
  Str(Trunc(T) div 60: 2, Tmp); if Tmp[1] = ' ' then Tmp[1] := '0'; L1 := '{' + Tmp + ':';
  Str(Trunc(T) mod 60: 2, Tmp); if Tmp[1] = ' ' then Tmp[1] := '0';
  L1 := L1 + Tmp + ' ' + Copy(W, 1, 11) + '}';
  L2 := 'k:=' + IStr(I) + ' mod ' + IStr(C) + ' {' + IStr(N) + '}';
  L3 := 'f:=110*' + IStr(N) + ' {' + IStr(110 * N) + '}';
  Wt := Weight(Ch, Words[K].Line);
  Str(Wt: 5: 3, Tmp); L4 := 'w:=' + Tmp + ';';
  if IsVowel(Ch) then
  begin
    Str(D - Cur * 0.55 * D / Segs[S].NWords + 0.4: 4: 2, Tmp);
    L5 := 'swell(f,w);';
  end
  else L5 := 'strike(f,w);';
  B := 22;
  if Tc > LongInt(Segs[S].T1) + 150 then B := 10;
  E := Clip(1 - Tr / 0.25, 0, 1);
  X := ColX[V] - 52;
  DrawText(X, 62, L1, B - 6, 1);
  DrawText(X, 70, L2, B + Round(24 * E), 1);
  DrawText(X, 78, L3, B + Round(18 * E), 1);
  DrawText(X, 86, L4, B + Round(12 * E), 1);
  DrawText(X, 94, L5, B, 1);
end;

{ ------------------------------------------------------------------ one frame }

procedure Frame(TAll: Single);
var Tc, Said: LongInt; I, S, Alive, NV, M: Integer;
    T, Grow, Calm, Pulse, ETot, Dance, K: Single;
    Line: string;
    Latin, InSil: Boolean;
begin
  ClearBuf;
  T := TAll;
  Tc := Round(T * 100);
  { how much sediment has settled }
  Alive := 0;
  while (Alive < NG) and (G^[Alive + 1].Birth <= Tc) do Inc(Alive);
  Grow := Exp(0.35 * Ln((Alive + 1) / NG));
  { the silences are a flat calm }
  Calm := 1; InSil := False; Latin := False;
  for S := 1 to NSEG do
  begin
    if Segs[S].Kind = 3 then
    begin
      K := Clip(((Segs[S].T0 - Tc) / 100) / 1.0, 0, 1);
      if ((Tc - Segs[S].T1) / 100) / 2.0 > K then K := Clip(((Tc - Segs[S].T1) / 100) / 2.0, 0, 1);
      if K < 0.12 then K := 0.12;
      if K < Calm then Calm := K;
      if (Tc >= Segs[S].T0) and (Tc <= Segs[S].T1) then InSil := True;
    end;
    if (Segs[S].Kind = 4) and (Tc >= Segs[S].T0) and (Tc <= Segs[S].T1) then Latin := True;
  end;
  { shared words: sounding anywhere, lit everywhere }
  for I := 0 to 8 do MotifOn[I] := False;
  for I := 1 to NWORD do
    if (Words[I].Motif > 0) and (Words[I].T0 <= Tc) and (LongInt(Words[I].T1) + 300 >= Tc) then
      MotifOn[Words[I].Motif] := True;
  { solo lines are calm, polyphony dances }
  NV := 0;
  for S := 1 to NSEG do
    if (Segs[S].Kind = 2) and (Segs[S].T0 <= Tc) and (LongInt(Segs[S].T1) - 100 >= Tc) then Inc(NV);
  if NV <= 1 then Dance := 0.3 else if NV = 2 then Dance := 0.75 else Dance := 1;
  { draw the columns into a scratch pass first, to know who is speaking }
  ETot := 0;
  for I := 1 to 3 do ETot := ETot + VoiceE[I];
  Pulse := 0.7 + 0.35 * Grow + 0.1 * Sin(2 * Pi * 0.05 * T) + 0.5 * Clip(ETot, 0, 1.5);
  Ang := 0.9 * Ang + 0.1 * 1.4 * (VoiceE[3] - VoiceE[2]);
  DrawSea(Tc, Alive, Grow, Calm, Pulse, False);
  if not InSil then
    for I := 1 to 3 do
    begin
      DrawColumn(I, Tc, Dance, K);
      VoiceE[I] := 0.8 * VoiceE[I] + 0.2 * (K / 4);
    end;
  if Latin then DrawText(160 - 22, 30, #183' '#183' '#183' '#183' '#183, 10, 1);
  { the drone, as a line of Pascal }
  Said := 0; M := 12;
  for I := 1 to NWORD do
    if Words[I].T0 <= Tc then Said := Said + NLetters(WordText(I));
  for S := 1 to NSEG do
    if (Segs[S].Kind = 2) and (Segs[S].T0 <= Tc) then M := Segs[S].Modulus;
  Line := 'sediment: ' + IStr(Said) + ' letters, mod ' + IStr(M);
  if InSil then DrawText(160 - Length(Line) * 5 div 2, 191, Line, 5, 1)
  else DrawText(160 - Length(Line) * 5 div 2, 191, Line, 14, 1);
  { fade at the very end }
  if T < 2 then SetBrightness(Clip(T / 2, 0, 1))
  else SetBrightness(Clip((TOTAL_CS / 100 - T) / 3, 0, 1));
end;

{ ------------------------------------------------------------------ main }

var
  Quit: Boolean;
  Code: Integer;
{$IFNDEF SIM}
  EndRegs: Registers;
{$ENDIF}
{$IFDEF TESTRUN}
  StopAt: Single; Log: Text; Dump: file; Frames: LongInt;
{$ENDIF}
{$IFDEF SIM}
  PI_: Integer; TS: Single; Name: string; RawOut: Text; FrameNo: LongInt;
{$ENDIF}

begin
  Prepare;
{$IFDEF SIM}
  InitGraph;
  if ParamStr(1) = 'RAW' then
  begin
    { every frame, 30 a second, as raw 320x200 grey bytes to standard output }
    Assign(RawOut, ''); Rewrite(RawOut);
    FrameNo := 0;
    repeat
      TS := FrameNo / 30;
      SimTime := TS;
      Frame(TS);
      WriteRaw(RawOut);
      Inc(FrameNo);
    until TS >= TOTAL_CS / 100;
    Close(RawOut);
    CloseGraph;
    Halt(0);
  end;
  for PI_ := 1 to ParamCount do
  begin
    Val(ParamStr(PI_), TS, Code);
    SimTime := TS;
    Frame(TS);
    Name := 'frame_' + ParamStr(PI_) + '.pgm';
    SaveFrame(Name);
  end;
  CloseGraph;
{$ELSE}
  StartAt := 0;
  if ParamCount >= 1 then begin Val(ParamStr(1), StartAt, Code); if Code <> 0 then StartAt := 0; end;
{$IFDEF TESTRUN}
  StopAt := StartAt + 8;
  if ParamCount >= 2 then Val(ParamStr(2), StopAt, Code);
  Assign(Log, 'LOG.TXT'); Rewrite(Log);
{$ENDIF}
  if not OpenSound('SAND.SND') then
  begin
    WriteLn('EIN. MEER. VON. SAND. needs a Sound Blaster 16 (BLASTER=A220 I7 D1) and SAND.SND.');
    Halt(1);
  end;
  InitGraph;
  StartSound;
  Quit := False;
  repeat
    PumpSound;
    Frame(SoundTime);
    Present;
    if Port[$60] = 1 then Quit := True;       { ESC }
{$IFDEF TESTRUN}
    Inc(Frames);
    if SoundTime >= StopAt then
    begin
      WriteLn(Log, 'reached ', SoundTime: 8: 2, ' s after ', Frames, ' frames');
      Assign(Dump, 'DUMP.RAW'); Rewrite(Dump, 1);
      BlockWrite(Dump, Buf^[0], 32000); BlockWrite(Dump, Buf^[32000], 32000);
      Close(Dump);
      Quit := True;
    end;
{$ENDIF}
  until Quit or SoundEnded;
  StopSound;
  CloseGraph;
  { the end screen: the monument, in text mode, left behind on the screen }
  Move(EndScreen, Mem[$B800:0], 4000);
  EndRegs.AH := 2; EndRegs.BH := 0; EndRegs.DH := 23; EndRegs.DL := 0;
  Intr($10, EndRegs);
{$IFDEF TESTRUN}
  Close(Log);
{$ENDIF}
{$ENDIF}
end.
