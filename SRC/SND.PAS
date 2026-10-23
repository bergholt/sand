{$N+,E+}
unit Snd;
{ EIN. MEER. VON. SAND.  --  the sound, kept separate
  SAND.SND holds the soundtrack synthesised by the APL program: 8-bit unsigned stereo, 22050 Hz.
  It is streamed from disk through a Sound Blaster 16: auto-init DMA over a 32 KB buffer in two
  halves; the card interrupts after each half, and the main loop refills the half just played.
  The picture follows the sound: SoundTime reads how far the DMA has actually got.
  Settings come from the BLASTER variable (defaults A220 I7 D1, as in DOSBox). }

interface

function OpenSound(const Name: string): Boolean;
procedure StartSound;
procedure PumpSound;
function SoundTime: Single;
procedure StopSound;

var
  SoundEnded: Boolean;
  SimTime: Single;        { used only by the SIM build }
  StartAt: Single;        { seconds into the soundtrack to begin from (SAND 300 starts at 5:00) }

implementation

{$IFNDEF SIM}
uses Dos;

const
  RATE = 22050;
  BUFSIZE = 32768;
  HALF = 16384;
  BYTESPERSEC = 44100.0;   { 22050 frames x 2 channels x 1 byte }

type
  TBuf = array[0..BUFSIZE - 1] of Byte;
  PBuf = ^TBuf;

var
  Base, IrqNo, DmaCh: Word;
  F: file;
  DmaBuf: PBuf;
  Phys: LongInt;
  Played: Word;            { halves finished, counted by the interrupt }
  Filled: Word;            { halves filled from the file }
  EndHalf: Word;
  FileDone: Boolean;
  OldVec: Pointer;
  OldMask: Byte;
  Junk: array[1..4] of PBuf;
  Sink: Byte;
  NJunk: Integer;

procedure SBIrq; interrupt;
begin
  Inc(Played);
  Sink := Port[Base + $0E];               { acknowledge the 8-bit DMA interrupt }
  if IrqNo >= 8 then Port[$A0] := $20;
  Port[$20] := $20;
end;

procedure DspWrite(V: Byte);
var N: Word;
begin
  N := 0;
  while ((Port[Base + $0C] and $80) <> 0) and (N < 60000) do Inc(N);
  Port[Base + $0C] := V;
end;

function DspReset: Boolean;
var I: Word;
begin
  Port[Base + 6] := 1;
  for I := 1 to 100 do Sink := Port[Base + 6];
  Port[Base + 6] := 0;
  DspReset := False;
  for I := 1 to 60000 do
    if (Port[Base + $0E] and $80) <> 0 then
      if Port[Base + $0A] = $AA then begin DspReset := True; Exit; end;
end;

function HexVal(const S: string): Word;
var I, V, D: Word;
begin
  V := 0;
  for I := 1 to Length(S) do
  begin
    case S[I] of
      '0'..'9': D := Ord(S[I]) - 48;
      'A'..'F': D := Ord(S[I]) - 55;
      'a'..'f': D := Ord(S[I]) - 87;
    else D := 0;
    end;
    V := V * 16 + D;
  end;
  HexVal := V;
end;

procedure ReadBlaster;
var S, T: string; I: Integer; C: Char; Code: Integer; V: Word;
begin
  Base := $220; IrqNo := 7; DmaCh := 1;
  S := GetEnv('BLASTER') + ' ';
  T := '';
  for I := 1 to Length(S) do
    if S[I] = ' ' then
    begin
      if Length(T) > 1 then
      begin
        C := UpCase(T[1]);
        if C = 'A' then Base := HexVal(Copy(T, 2, 255))
        else if C = 'I' then begin Val(Copy(T, 2, 255), V, Code); if Code = 0 then IrqNo := V; end
        else if C = 'D' then begin Val(Copy(T, 2, 255), V, Code); if Code = 0 then DmaCh := V; end;
      end;
      T := '';
    end
    else T := T + S[I];
end;

procedure AllocDmaBuffer;
var P: PBuf; Ok: Boolean;
begin
  { the buffer must not cross a 64 KB physical page }
  NJunk := 0;
  repeat
    New(P);
    Phys := LongInt(Seg(P^)) * 16 + Ofs(P^);
    Ok := (Phys and $FFFF) + BUFSIZE <= $10000;
    if not Ok then begin Inc(NJunk); Junk[NJunk] := P; end;
  until Ok or (NJunk = 4);
  DmaBuf := P;
  while NJunk > 0 do begin Dispose(Junk[NJunk]); Dec(NJunk); end;
end;

procedure FillHalf(H: Word);
var Got: Word; Dst: Word;
begin
  Dst := (H mod 2) * HALF;
  if FileDone then begin FillChar(DmaBuf^[Dst], HALF, $80); Exit; end;
  BlockRead(F, DmaBuf^[Dst], HALF, Got);
  if Got < HALF then
  begin
    FillChar(DmaBuf^[Dst + Got], HALF - Got, $80);
    FileDone := True;
    EndHalf := H;
  end;
end;

function OpenSound(const Name: string): Boolean;
begin
  OpenSound := False;
  SoundEnded := False;
  ReadBlaster;
  if DmaCh > 3 then Exit;              { 8-bit DMA channels only }
  if not DspReset then Exit;
  Assign(F, Name);
  {$I-} Reset(F, 1); {$I+}
  if IOResult <> 0 then Exit;
  if StartAt > 0 then Seek(F, (Round(StartAt * RATE) * 2) and $7FFFFFFE);
  AllocDmaBuffer;
  FileDone := False; EndHalf := $FFFF;
  Played := 0;
  FillHalf(0); FillHalf(1); Filled := 2;
  OpenSound := True;
end;

procedure StartSound;
const
  AddrPort: array[0..3] of Byte = ($00, $02, $04, $06);
  CountPort: array[0..3] of Byte = ($01, $03, $05, $07);
  PagePort: array[0..3] of Byte = ($87, $83, $81, $82);
var Vec: Byte; Pic: Word;
begin
  { interrupt vector and PIC }
  if IrqNo < 8 then begin Vec := IrqNo + 8; Pic := $21; end
  else begin Vec := IrqNo + $68; Pic := $A1; end;
  GetIntVec(Vec, OldVec);
  SetIntVec(Vec, @SBIrq);
  OldMask := Port[Pic];
  Port[Pic] := OldMask and not (1 shl (IrqNo mod 8));
  { DMA: auto-initialise, playback, the whole 32 KB buffer }
  Port[$0A] := 4 or DmaCh;
  Port[$0C] := 0;
  Port[$0B] := $58 or DmaCh;
  Port[AddrPort[DmaCh]] := Lo(Word(Phys));
  Port[AddrPort[DmaCh]] := Hi(Word(Phys));
  Port[PagePort[DmaCh]] := Byte(Phys shr 16);
  Port[$0C] := 0;
  Port[CountPort[DmaCh]] := Lo(BUFSIZE - 1);
  Port[CountPort[DmaCh]] := Hi(BUFSIZE - 1);
  Port[$0A] := DmaCh;
  { DSP (Sound Blaster 16): rate, then 8-bit auto-init stereo, interrupt every half }
  DspWrite($D1);
  DspWrite($41); DspWrite(Hi(RATE)); DspWrite(Lo(RATE));
  DspWrite($C6); DspWrite($20);
  DspWrite(Lo(HALF - 1)); DspWrite(Hi(HALF - 1));
end;

procedure PumpSound;
begin
  while Filled < Played + 2 do
  begin
    FillHalf(Filled);
    Inc(Filled);
  end;
  if FileDone and (Played > EndHalf) then SoundEnded := True;
end;

function SoundTime: Single;
const CountPort: array[0..3] of Byte = ($01, $03, $05, $07);
var Lo8, Hi8: Byte; Remaining, Pos, Within: Word; P: Word;
begin
  P := Played;
  Port[$0C] := 0;
  Lo8 := Port[CountPort[DmaCh]];
  Hi8 := Port[CountPort[DmaCh]];
  Remaining := Lo8 + Word(Hi8) * 256;
  Pos := (BUFSIZE - 1) - Remaining;
  if (Pos div HALF) = (P mod 2) then Within := Pos mod HALF else Within := HALF - 1;
  SoundTime := StartAt + (LongInt(P) * HALF + Within) / BYTESPERSEC;
end;

procedure StopSound;
var Vec: Byte; Pic: Word;
begin
  DspWrite($DA);                        { leave 8-bit auto-init mode }
  DspWrite($D3);
  Port[$0A] := 4 or DmaCh;
  if IrqNo < 8 then begin Vec := IrqNo + 8; Pic := $21; end
  else begin Vec := IrqNo + $68; Pic := $A1; end;
  Port[Pic] := OldMask;
  SetIntVec(Vec, OldVec);
  Close(F);
end;

{$ELSE}

function OpenSound(const Name: string): Boolean;
begin OpenSound := True; SoundEnded := False; end;
procedure StartSound; begin end;
procedure PumpSound; begin end;
function SoundTime: Single; begin SoundTime := SimTime; end;
procedure StopSound; begin end;

{$ENDIF}

end.
