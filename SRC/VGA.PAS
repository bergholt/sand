{$N+,E+}
unit Vga;
{ EIN. MEER. VON. SAND.  --  the screen
  VGA mode 13h, 320x200, 64 greys. Everything is drawn additively into a back buffer
  (light adds to light, like letters settling on letters) and copied to video memory once a frame.
  Compiled with SIM defined (Free Pascal, for testing), frames are written as PGM images instead. }

interface

const
  SCRW = 320; SCRH = 200;

type
  TScreen = array[0..63999] of Byte;
  PScreen = ^TScreen;

var
  Buf: PScreen;

procedure InitGraph;
procedure CloseGraph;
procedure ClearBuf;
procedure Present;
procedure SetBrightness(F: Single);
procedure AddPix(X, Y, V: Integer);
procedure DrawChar(X, Y: Integer; C: Char; V, Scale: Integer);
procedure DrawText(X, Y: Integer; const S: string; V, Scale: Integer);
{$IFDEF SIM}
procedure SaveFrame(const Name: string);
procedure WriteRaw(var T: Text);
{$ENDIF}

implementation

uses {$IFNDEF SIM} Dos, {$ENDIF} Font8;

procedure InitGraph;
{$IFNDEF SIM}
var R: Registers;
{$ENDIF}
begin
  New(Buf);
  ClearBuf;
{$IFNDEF SIM}
  R.AX := $0013; Intr($10, R);
{$ENDIF}
  SetBrightness(0);
end;

procedure CloseGraph;
{$IFNDEF SIM}
var R: Registers;
{$ENDIF}
begin
{$IFNDEF SIM}
  R.AX := $0003; Intr($10, R);
{$ENDIF}
  Dispose(Buf);
end;

procedure ClearBuf;
begin
  { in two halves: some compilers count bytes as a signed 16-bit number }
  FillChar(Buf^[0], 32000, 0);
  FillChar(Buf^[32000], 32000, 0);
end;

procedure Present;
begin
{$IFNDEF SIM}
  { wait for the vertical retrace, then copy the whole frame }
  while (Port[$3DA] and 8) <> 0 do ;
  while (Port[$3DA] and 8) = 0 do ;
  Move(Buf^[0], Mem[$A000:0], 32000);
  Move(Buf^[32000], Mem[$A000:32000], 32000);
{$ENDIF}
end;

var
  Bright: Single;

procedure SetBrightness(F: Single);
{$IFNDEF SIM}
var I, V: Integer;
{$ENDIF}
begin
  if F < 0 then F := 0;
  if F > 1 then F := 1;
  Bright := F;
{$IFNDEF SIM}
  { palette: index i is grey level i (the DAC has six bits: 0..63), scaled for fades }
  Port[$3C8] := 0;
  for I := 0 to 255 do
  begin
    if I < 64 then V := Round(I * F) else V := Round(63 * F);
    Port[$3C9] := V; Port[$3C9] := V; Port[$3C9] := V;
  end;
{$ENDIF}
end;

procedure AddPix(X, Y, V: Integer);
var P: Word; S: Integer;
begin
  if (X < 0) or (X >= SCRW) or (Y < 0) or (Y >= SCRH) or (V <= 0) then Exit;
  P := Word(Y) * SCRW + Word(X);
  S := Buf^[P] + V;
  if S > 63 then S := 63;
  Buf^[P] := S;
end;

procedure DrawChar(X, Y: Integer; C: Char; V, Scale: Integer);
var R, Col, B, SX, SY: Integer;
begin
  if (Ord(C) < 33) or (V <= 0) then Exit;
  for R := 0 to 7 do
  begin
    B := Glyph[Ord(C), R];
    if B <> 0 then
      for Col := 0 to 4 do
        if (B and ($80 shr Col)) <> 0 then
          if Scale = 1 then AddPix(X + Col, Y + R, V)
          else
            for SY := 0 to Scale - 1 do
              for SX := 0 to Scale - 1 do
                AddPix(X + Col * Scale + SX, Y + R * Scale + SY, V);
  end;
end;

procedure DrawText(X, Y: Integer; const S: string; V, Scale: Integer);
var I: Integer;
begin
  for I := 1 to Length(S) do
    DrawChar(X + (I - 1) * 5 * Scale, Y, S[I], V, Scale);
end;

{$IFDEF SIM}
procedure SaveFrame(const Name: string);
var F: file; Hdr: string; I: LongInt; Line: array[0..319] of Byte; X, Y: Integer;
begin
  Assign(F, Name); Rewrite(F, 1);
  Hdr := 'P5 320 200 255' + #10;
  BlockWrite(F, Hdr[1], Length(Hdr));
  for Y := 0 to 199 do
  begin
    for X := 0 to 319 do
    begin
      I := Round(Buf^[Y * 320 + X] * Bright * 255 / 63);
      if I > 255 then I := 255;
      Line[X] := I;
    end;
    BlockWrite(F, Line, 320);
  end;
  Close(F);
end;
procedure WriteRaw(var T: Text);
var X, Y: Integer; I: LongInt; Line: string[255];
begin
  { one frame of 320x200 grey bytes, written as characters (for piping into an encoder) }
  for Y := 0 to 199 do
  begin
    Line := '';
    for X := 0 to 319 do
    begin
      I := Round(Buf^[Y * 320 + X] * Bright * 255 / 63);
      if I > 255 then I := 255;
      Write(T, Chr(I));
    end;
  end;
end;
{$ENDIF}

end.
