unit ULoadingCircle;

{ Native LCL port copyright © 2026 Herman Schoenfeld <https://sphere10.com>

  Rounded-spoke loading indicator adapted from Sphere10 Framework's
  Windows.Forms.LoadingCircle, using its MacOSX appearance and fading palette.

  Original LoadingCircle copyright © 2006, 2007 Martin R. Gagné
  (martingagne@gmail.com). All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

  - Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.
  - Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.
}

{$IFDEF FPC}
{$mode delphi}
{$ENDIF}

interface

uses
  Classes, SysUtils, Math,
  {$IFDEF FPC}
  Controls, ExtCtrls, Graphics;
  {$ELSE}
  Vcl.Controls, Vcl.ExtCtrls, Vcl.Graphics, Winapi.Windows;
  {$ENDIF}

type
  { TLoadingCircle

    Component-owned animation: no worker or queued callback outlives the
    control. Active must be changed on the LCL thread. Colors are composited
    against Color to reproduce the original alpha-faded spokes on an opaque
    native control. }
  TLoadingCircle = class(TCustomControl)
  private
    FTimer : TTimer;
    FActive : Boolean;
    FPosition : Integer;
    FSpokeColor : TColor;
    procedure SetActive(AValue : Boolean);
    procedure SetSpokeColor(AValue : TColor);
    procedure OnTimer(Sender : TObject);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
  published
    property Active : Boolean read FActive write SetActive default False;
    property SpokeColor : TColor read FSpokeColor write SetSpokeColor default $00A9A9A9;
    property Align;
    property Anchors;
    property Color;
    property ParentColor;
    property Visible;
  end;

implementation

constructor TLoadingCircle.Create(AOwner : TComponent);
begin
  inherited Create(AOwner);
  Width := 36;
  Height := 36;
  Color := clWindow;
  FSpokeColor := $00A9A9A9; // System.Drawing.Color.DarkGray in the original control.
  DoubleBuffered := True;
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := 100;
  FTimer.OnTimer := OnTimer;
end;

destructor TLoadingCircle.Destroy;
begin
  if Assigned(FTimer) then FTimer.Enabled := False;
  inherited Destroy;
end;

procedure TLoadingCircle.SetActive(AValue : Boolean);
begin
  if FActive = AValue then Exit;
  FActive := AValue;
  FTimer.Enabled := AValue;
  if not AValue then FPosition := 0;
  Invalidate;
end;

procedure TLoadingCircle.SetSpokeColor(AValue : TColor);
begin
  if FSpokeColor = AValue then Exit;
  FSpokeColor := AValue;
  Invalidate;
end;

procedure TLoadingCircle.OnTimer(Sender : TObject);
begin
  {$IFDEF FPC}if not IsVisible then Exit;{$ELSE}if not IsWindowVisible(Handle) then Exit;{$ENDIF}
  FPosition := (FPosition + 1) mod 12;
  Invalidate;
end;

procedure TLoadingCircle.Paint;
var
  i, LAlpha, LThickness : Integer;
  LRed, LGreen, LBlue, LBackRed, LBackGreen, LBackBlue : Byte;
  LAngle, LRadius, LCenterX, LCenterY : Double;
  {$IFNDEF FPC}
  LBrush: TLogBrush;
  LPen, LPreviousPen: HGDIOBJ;
  {$ENDIF}
begin
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);
  {$IFDEF FPC}
  RedGreenBlue(ColorToRGB(FSpokeColor),LRed,LGreen,LBlue);
  RedGreenBlue(ColorToRGB(Color),LBackRed,LBackGreen,LBackBlue);
  {$ELSE}
  LRed:=GetRValue(ColorToRGB(FSpokeColor)); LGreen:=GetGValue(ColorToRGB(FSpokeColor)); LBlue:=GetBValue(ColorToRGB(FSpokeColor));
  LBackRed:=GetRValue(ColorToRGB(Color)); LBackGreen:=GetGValue(ColorToRGB(Color)); LBackBlue:=GetBValue(ColorToRGB(Color));
  {$ENDIF}
  LRadius := Min(Width,Height) * 11 / 32;
  LCenterX := Width / 2;
  LCenterY := Height / 2;
  LThickness := Max(2,Round(Min(Width,Height) / 16));
  Canvas.Pen.Width := LThickness;
  {$IFDEF FPC}Canvas.Pen.EndCap := pecRound;{$ENDIF}
  for i := 0 to 11 do begin
    if (not FActive) or (i = 0) then LAlpha := 255
    else LAlpha := i * (255 div 12);
    Canvas.Pen.Color := {$IFDEF FPC}RGBToColor{$ELSE}RGB{$ENDIF}(
      (LRed * LAlpha + LBackRed * (255-LAlpha)) div 255,
      (LGreen * LAlpha + LBackGreen * (255-LAlpha)) div 255,
      (LBlue * LAlpha + LBackBlue * (255-LAlpha)) div 255);
    LAngle := (FPosition + i + 1) * (2 * Pi / 12);
    {$IFDEF FPC}
    Canvas.Line(
      Round(LCenterX + LRadius * 5 / 11 * Cos(LAngle)),
      Round(LCenterY + LRadius * 5 / 11 * Sin(LAngle)),
      Round(LCenterX + LRadius * Cos(LAngle)),
      Round(LCenterY + LRadius * Sin(LAngle)));
    {$ELSE}
    // VCL's TPen has no EndCap property. Retain rounded spokes with a native
    // geometric pen, restoring the canvas HDC before releasing its handle.
    LBrush.lbStyle:=BS_SOLID;
    LBrush.lbColor:=ColorToRGB(Canvas.Pen.Color);
    LBrush.lbHatch:=0;
    LPen:=ExtCreatePen(PS_GEOMETRIC or PS_SOLID or PS_ENDCAP_ROUND or PS_JOIN_ROUND,
      LThickness,LBrush,0,nil);
    if LPen=0 then RaiseLastOSError;
    LPreviousPen:=SelectObject(Canvas.Handle,LPen);
    try
      MoveToEx(Canvas.Handle,Round(LCenterX+LRadius*5/11*Cos(LAngle)),Round(LCenterY+LRadius*5/11*Sin(LAngle)),nil);
      Winapi.Windows.LineTo(Canvas.Handle,Round(LCenterX+LRadius*Cos(LAngle)),Round(LCenterY+LRadius*Sin(LAngle)));
    finally
      SelectObject(Canvas.Handle,LPreviousPen);
      DeleteObject(LPen);
    end;
    {$ENDIF}
  end;
end;

end.
