      {******************************************************************}
      { SVG Image                                                        }
      {                                                                  }
      { home page : http://www.mwcs.de                                   }
      { email     : martin.walter@mwcs.de                                }
      {                                                                  }
      { date      : 22-09-2008                                           }
      {                                                                  }
      { version   : 0.69b                                                }
      {                                                                  }
      { Use of this file is permitted for commercial and non-commercial  }
      { use, as long as the author is credited.                          }
      { This file (c) 2005, 2008 Martin Walter                           }
      {                                                                  }
      { Thanks to:                                                       }
      { Bart Vandromme (parsing errors)                                  }
      { Chris Ueberall (parsing errors)                                  }
      { Elias Zurschmiede (font error)                                   }
      { Christopher Cerny  (Dash Pattern)                                }
      {                                                                  }
      { This Software is distributed on an "AS IS" basis, WITHOUT        }
      { WARRANTY OF ANY KIND, either express or implied.                 }
      {                                                                  }
      { *****************************************************************}

unit SVG;

{.$DEFINE USE_TEXT} // Define to use "real" text instead of paths

interface

uses
  Winapi.Windows, Winapi.GDIPOBJ, Winapi.GDIPAPI,
  System.Classes, System.Math, System.NetEncoding, System.Math.Vectors, System.Types,
  Xml.XmlIntf,
  GDIPOBJ2, GDIPKerning, GDIPPathText,
  SVGTypes, SVGStyle;

type
  TSVG = class;

  TSVGObject = class(TPersistent)
  private
    FItems: TList;
    FVisible: Integer;
    FDisplay: Integer;
    FBounds: TBounds;
    FParent: TSVGObject;
    FStyle: TStyle;
    FID: string;
    FObjectName: string;
    FClasses: TStrings;

    function GetCount: Integer;
    procedure SetItem(const Index: Integer; const Item: TSVGObject);
    function GetItem(const Index: Integer): TSVGObject;

    function GetDisplay: Integer;
    function GetObjectBounds: TBounds;
    function GetVisible: Integer;
  protected
    procedure AssignTo(Dest: TPersistent); override;
    function New(Parent: TSVGObject): TSVGObject; virtual; abstract;
    procedure CalcObjectBounds; virtual;

    function GetRoot: TSVG;
  public
    constructor Create; overload; virtual;
    constructor Create(Parent: TSVGObject); overload;
    destructor Destroy; override;
    procedure Clear; virtual;
    function Clone(Parent: TSVGObject): TSVGObject;
    function Add(Item: TSVGObject): Integer;
    procedure Delete(Index: Integer);
    function Remove(Item: TSVGObject): Integer;
    function IndexOf(Item: TSVGObject): Integer;
    function FindByID(const Name: string): TSVGObject;
    function FindByType(Typ: TClass; Previous: TSVGObject = nil): TSVGObject;
    procedure CalculateMatrices;

    procedure PaintToGraphics(Graphics: TGPGraphics); virtual; abstract;
    procedure PaintToPath(Path: TGPGraphicsPath); virtual; abstract;
    procedure ReadIn(const Node: IXMLNode); virtual;

    property Items[const Index: Integer]: TSVGObject read GetItem write SetItem; default;
    property Count: Integer read GetCount;

    property Display: Integer read GetDisplay write FDisplay;
    property Visible: Integer read GetVisible write FVisible;
    property ObjectBounds: TBounds read GetObjectBounds;
    property Parent: TSVGObject read FParent;
    property Style: TStyle read FStyle;
    property ID: string read FID;
    property ObjectName: string read FObjectName;
  end;

  TSVGMatrix = class(TSVGObject)
  private
    FPureMatrix: TMatrix;
    FCompleteCalculatedMatrix: TMatrix;
    FCalculatedMatrix: TMatrix;
    procedure SetPureMatrix(const Value: TMatrix);
    procedure CalcMatrix;

    function Transform(const P: TPointF): TPointF; overload;
    function Transform(const X, Y: TFloat): TPointF; overload;
  protected
    procedure AssignTo(Dest: TPersistent); override;
  public
    procedure Clear; override;
    procedure ReadIn(const Node: IXMLNode); override;
    property Matrix: TMatrix read FCompleteCalculatedMatrix;
    property PureMatrix: TMatrix read FPureMatrix write SetPureMatrix;
  end;

  TSVGBasic = class(TSVGMatrix)
  private
    FFillColor: Integer;
    FStrokeColor: Integer;
    FFillOpacity: TFloat;
    FStrokeOpacity: TFloat;
    FStrokeWidth: TFloat;
    FStrokeLineJoin: string;
    FStrokeLineCap: string;
    FStrokeMiterLimit: TFloat;
    FStrokeDashOffset: TFloat;
    FStrokeDashArray: TSingleDynArray;
    FStrokeDashArrayCount: Integer;
    FArrayNone: Boolean;

    FFontName: string;
    FFontSize: TFloat;
    FFontWeight: Integer;
    FFontStyle: Integer;
    FTextDecoration: TTextDecoration;

    FPath: TGPGraphicsPath2;
    FClipPath: TGPGraphicsPath;
    FX: TFloat;
    FY: TFloat;
    FWidth: TFloat;
    FHeight: TFloat;
    FStyleChanged: Boolean;

    function IsFontAvailable: Boolean;
    procedure ReadChildren(const Node: IXMLNode); virtual;
    procedure SetStrokeDashArray(const S: string);
    procedure SetClipURI(const Value: string);

    function GetFillColor: Integer;
    function GetStrokeColor: Integer;
    function GetFillOpacity: TFloat;
    function GetStrokeOpacity: TFloat;
    function GetStrokeWidth: TFloat;
    function GetClipURI: string;
    function GetStrokeLineCap: TLineCap;
    function GetStrokeDashCap: TDashCap;
    function GetStrokeLineJoin: TLineJoin;
    function GetStrokeMiterLimit: TFloat;
    function GetStrokeDashOffset: TFloat;
    function GetStrokeDashArray(var Count: Integer): PSingle;

    function GetFontName: string;
    function GetFontWeight: Integer;
    function GetFontSize: TFloat;
    function GetFontStyle: Integer;
    function GetTextDecoration: TTextDecoration;
    procedure ParseFontWeight(const S: string);
    procedure UpdateStyle;
    procedure OnStyleChanged(Sender: TObject);
  protected
    FRX: TFloat;
    FRY: TFloat;
    FFillURI: string;
    FStrokeURI: string;
    FClipURI: string;
    FLineWidth: TFloat;
    FFillRule: Integer;
    FColorInterpolation: TFloat;
    FColorRendering: TFloat;

    procedure AssignTo(Dest: TPersistent); override;
    function New(Parent: TSVGObject): TSVGObject; override;
    procedure ReadStyle(Style: TStyle); virtual;
    procedure ConstructPath; virtual;
    function GetClipPath: TGPGraphicsPath;
    procedure CalcClipPath;

    function GetFillBrush: TGPBrush;
    function GetStrokeBrush: TGPBrush;
    function GetStrokePen(const StrokeBrush: TGPBrush): TGPPen;

    procedure BeforePaint(const Graphics: TGPGraphics; const Brush: TGPBrush;
      const Pen: TGPPen); virtual;
    procedure AfterPaint(const Graphics: TGPGraphics; const Brush: TGPBrush;
      const Pen: TGPPen); virtual;
  public
    constructor Create; override;
    procedure Clear; override;
    procedure PaintToGraphics(Graphics: TGPGraphics); override;

    procedure PaintToPath(Path: TGPGraphicsPath); override;
    procedure ReadIn(const Node: IXMLNode); override;

    property Root: TSVG read GetRoot;

    property FillColor: Integer read GetFillColor write FFillColor;
    property StrokeColor: Integer read GetStrokeColor write FStrokeColor;
    property FillOpacity: TFloat read GetFillOpacity write FFillOpacity;
    property StrokeOpacity: TFloat read GetStrokeOpacity write FStrokeOpacity;
    property StrokeWidth: TFloat read GetStrokeWidth write FStrokeWidth;
    property ClipURI: string read GetClipURI write SetClipURI;
    property FillURI: string read FFillURI write FFillURI;
    property StrokeURI: string read FStrokeURI write FStrokeURI;
    property X: TFloat read FX write FX;
    property Y: TFloat read FY write FY;
    property Width: TFloat read FWidth write FWidth;
    property Height: TFloat read FHeight write FHeight;
    property RX: TFloat read FRX write FRX;
    property RY: TFloat read FRY write FRY;

    property StrokeLineCap: TLineCap read GetStrokeLineCap;
    property StrokeLineJoin: TLineJoin read GetStrokeLineJoin;
    property StrokeMiterLimit: TFloat read GetStrokeMiterLimit write FStrokeMiterLimit;
    property StrokeDashOffset: TFloat read GetStrokeDashOffset write FStrokeDashOffset;

    property FontName: string read GetFontName write FFontName;
    property FontSize: TFloat read GetFontSize write FFontSize;
    property FontWeight: Integer read GetFontWeight write FFontWeight;
    property FontStyle: Integer read GetFontStyle write FFontStyle;
    property TextDecoration: TTextDecoration read GetTextDecoration write FTextDecoration;
  end;

  TSVG = class(TSVGBasic)
  strict private
    FRootBounds: TGPRectF;
    FDX: TFloat;
    FDY: TFloat;
    FInitialMatrix: TMatrix;
    FSource: string;
    FAngle: TFloat;
    FAngleMatrix: TMatrix;
    FRootMatrix: TMatrix;
    FViewBox: TRectF;
    FFileName: string;
    FSize: TGPRectF;

    procedure SetViewBox(const Value: TRectF);

    procedure SetSVGOpacity(Opacity: TFloat);
    procedure SetAngle(Angle: TFloat);
    procedure Paint(const Graphics: TGPGraphics; Rects: PRectArray;
      RectCount: Integer);
    procedure CalcCompleteSize;
  private
    FStyles: TStyleList;
    procedure CalcRootMatrix;
  protected
    procedure AssignTo(Dest: TPersistent); override;
    function New(Parent: TSVGObject): TSVGObject; override;
    procedure ReadStyles(const Node: IXMLNode);
    property RootMatrix: TMatrix read FRootMatrix;
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure Clear; override;
    procedure ReadIn(const Node: IXMLNode); override;

    procedure DeReferenceUse;
    function GetStyleValue(const Name, Key: string): string;

    procedure LoadFromText(const Text: string);
    procedure LoadFromFile(const FileName: string);
    procedure LoadFromStream(Stream: TStream); overload;
    procedure SaveToFile(const FileName: string);
    procedure SaveToStream(Stream: TStream);

    function SaveToNode(const Parent: IXMLNode;
      Left, Top, Width, Height: TFloat): IXMLNode;

    procedure SetBounds(const Bounds: TGPRectF);
    procedure Scale(const ADX: TFloat; ADY: TFloat = -1);
    procedure PaintTo(DC: HDC; Bounds: TGPRectF;
      Rects: PRectArray; RectCount: Integer); overload;
    procedure PaintTo(MetaFile: TGPMetaFile; Bounds: TGPRectF;
      Rects: PRectArray; RectCount: Integer); overload;
    procedure PaintTo(Graphics: TGPGraphics; Bounds: TGPRectF;
      Rects: PRectArray; RectCount: Integer); overload;
    function RenderToIcon(Size: Integer): HICON;
    function RenderToBitmap(Width, Height: Integer): HBITMAP;

    property InitialMatrix: TMatrix read FInitialMatrix write FInitialMatrix;
    property SVGOpacity: TFloat write SetSVGOpacity;
    property Source: string read FSource;
    property Angle: TFloat read FAngle write SetAngle;
    property ViewBox: TRectF read FViewBox write SetViewBox;
  end;

  TSVGContainer = class(TSVGBasic)
  protected
    function New(Parent: TSVGObject): TSVGObject; override;
  public
    procedure ReadIn(const Node: IXMLNode); override;
  end;

  TSVGSwitch = class(TSVGBasic)
  protected
    function New(Parent: TSVGObject): TSVGObject; override;
  public
    procedure ReadIn(const Node: IXMLNode); override;
  end;

  TSVGDefs = class(TSVGBasic)
  protected
    function New(Parent: TSVGObject): TSVGObject; override;
  public
    procedure ReadIn(const Node: IXMLNode); override;
  end;

  TSVGUse = class(TSVGBasic)
  private
    FReference: string;
  protected
    procedure AssignTo(Dest: TPersistent); override;
    function New(Parent: TSVGObject): TSVGObject; override;
    procedure Construct;
  public
    procedure PaintToPath(Path: TGPGraphicsPath); override;
    procedure PaintToGraphics(Graphics: TGPGraphics); override;
    procedure Clear; override;
    procedure ReadIn(const Node: IXMLNode); override;
  end;

  TSVGRect = class(TSVGBasic)
  protected
    function New(Parent: TSVGObject): TSVGObject; override;
  protected
    procedure ConstructPath; override;
    procedure CalcObjectBounds; override;
  public
    procedure ReadIn(const Node: IXMLNode); override;
  end;

  TSVGLine = class(TSVGBasic)
  private
  protected
    function New(Parent: TSVGObject): TSVGObject; override;
    procedure ConstructPath; override;
    procedure CalcObjectBounds; override;
  public
    procedure ReadIn(const Node: IXMLNode); override;
  end;

  TSVGPolyLine = class(TSVGBasic)
  private
    FPoints: TListOfPoints;
    FPointCount: Integer;
    procedure ConstructPoints(const S: string);
  protected
    procedure AssignTo(Dest: TPersistent); override;
    function New(Parent: TSVGObject): TSVGObject; override;
    procedure ConstructPath; override;
    procedure CalcObjectBounds; override;
  public
    constructor Create; override;
    procedure Clear; override;
    procedure ReadIn(const Node: IXMLNode); override;
  end;

  TSVGPolygon = class(TSVGPolyLine)
  private
  protected
    function New(Parent: TSVGObject): TSVGObject; override;
    procedure ConstructPath; override;
  public
  end;

  TSVGEllipse = class(TSVGBasic)
  private
  protected
    function New(Parent: TSVGObject): TSVGObject; override;
    procedure ConstructPath; override;
    procedure CalcObjectBounds; override;
  public
    procedure ReadIn(const Node: IXMLNode); override;
  end;

  TSVGPath = class(TSVGBasic)
  private
    procedure PrepareMoveLineCurveArc(const ACommand: Char; SL: TStrings);
    function SeparateValues(const ACommand: Char; const S: string): TStrings;
    function Split(const S: string): TStrings;
  protected
    function New(Parent: TSVGObject): TSVGObject; override;
    procedure ConstructPath; override;
    procedure CalcObjectBounds; override;
  public
    procedure ReadIn(const Node: IXMLNode); override;
  end;

  TSVGImage = class(TSVGBasic)
  private
    FFileName: string;
    FImage: TGPImage;
    FStream: TMemoryStream;
  protected
    procedure AssignTo(Dest: TPersistent); override;
    function New(Parent: TSVGObject): TSVGObject; override;
    procedure CalcObjectBounds; override;
  public
    constructor Create; override;
    procedure Clear; override;
    procedure PaintToGraphics(Graphics: TGPGraphics); override;
    procedure ReadIn(const Node: IXMLNode); override;
    property Data: TMemoryStream read FStream;
  end;

  TSVGCustomText = class(TSVGBasic)
  private
    FText: string;
    FUnderlinePath: TGPGraphicsPath;
    FStrikeOutPath: TGPGraphicsPath;

    FFontHeight: TFloat;
    FDX: TFloat;
    FDY: TFloat;

    FHasX: Boolean;
    FHasY: Boolean;

    function GetCompleteWidth: TFloat;
    procedure SetSize; virtual;
    function GetFont: TGPFont;
    function GetFontFamily(const FontName: string): TGPFontFamily;

    function IsInTextPath: Boolean;
  protected
    procedure AssignTo(Dest: TPersistent); override;
    function New(Parent: TSVGObject): TSVGObject; override;
    procedure ConstructPath; override;
    procedure ParseNode(const Node: IXMLNode); virtual;
    procedure CalcObjectBounds; override;
    procedure BeforePaint(const Graphics: TGPGraphics; const Brush: TGPBrush;
      const Pen: TGPPen); override;
    procedure AfterPaint(const Graphics: TGPGraphics; const Brush: TGPBrush;
      const Pen: TGPPen); override;

    procedure ReadTextNodes(const Node: IXMLNode); virtual;
  public
    constructor Create; override;
    procedure Clear; override;
    procedure ReadIn(const Node: IXMLNode); override;
    procedure PaintToGraphics(Graphics: TGPGraphics); override;

    property DX: TFloat read FDX write FDX;
    property DY: TFloat read FDY write FDY;
    property FontHeight: TFloat read FFontHeight write FFontHeight;
    property Text: string read FText write FText;
  end;

  TSVGText = class(TSVGCustomText)
  public
    procedure ReadIn(const Node: IXMLNode); override;
  end;

  TSVGTSpan = class(TSVGText)
  private
  protected
    procedure ReadTextNodes(const Node: IXMLNode); override;
  public
  end;

  TSVGTextPath = class(TSVGCustomText)
  private
    FOffset: TFloat;
    FOffsetIsPercent: Boolean;
    FPathRef: string;
    FMethod: TTextPathMethod;
    FSpacing: TTextPathSpacing;
  protected
    procedure ConstructPath; override;
    procedure ReadTextNodes(const Node: IXMLNode); override;
  public
    procedure Clear; override;
    procedure ReadIn(const Node: IXMLNode); override;
  end;

  TSVGClipPath = class(TSVGBasic)
  private
    FClipPath: TGPGraphicsPath;
  protected
    function New(Parent: TSVGObject): TSVGObject; override;
    procedure ConstructClipPath;
  public
    destructor Destroy; override;
    procedure Clear; override;
    procedure PaintToPath(Path: TGPGraphicsPath); override;
    procedure PaintToGraphics(Graphics: TGPGraphics); override;
    procedure ReadIn(const Node: IXMLNode); override;
    function GetClipPath: TGPGraphicsPath;
  end;

implementation

uses
  System.SysUtils, System.Variants, System.StrUtils, System.Character,
  Xml.XmlDoc,
{$IFDEF MSWINDOWS}
  Xml.Win.msxmldom,
{$ENDIF}
  GDIPUtils, SVGParse, SVGProperties, SVGColor, SVGPaint, SVGPath, SVGCommon;

{$REGION 'TSVGObject'}
constructor TSVGObject.Create;
begin
  inherited;
  FParent := nil;
  FStyle := TStyle.Create;
  FItems := TList.Create;
  FClasses := TstringList.Create;
  FClasses.Delimiter := ' ';
  Clear;
end;

constructor TSVGObject.Create(Parent: TSVGObject);
begin
  Create;
  if Assigned(Parent) then
  begin
    Parent.Add(Self);
  end;
end;

destructor TSVGObject.Destroy;
begin
  Clear;
  FItems.Free;

  if Assigned(FParent) then
  begin
    FParent.Remove(Self);
  end;

  FStyle.Free;
  FClasses.Free;

  inherited;
end;

procedure TSVGObject.CalcObjectBounds;
begin
end;

procedure TSVGObject.CalculateMatrices;
var
  C: Integer;
begin
  if Self is TSVGMatrix then
  begin
    if Self is TSVG then
      TSVG(Self).CalcRootMatrix
    else
      TSVGMatrix(Self).CalcMatrix;

    if Self is TSVGBasic then
      TSVGBasic(Self).CalcClipPath;

    CalcObjectBounds;
  end;

  for C := 0 to FItems.Count - 1 do
  begin
    TSVGObject(FItems[C]).CalculateMatrices;
  end;
end;

procedure TSVGObject.Clear;
begin
  while Count > 0 do
  begin
    Items[0].Free;
  end;

  Visible := 1;
  Display := 1;
  FID := '';

  FClasses.Clear;
  FStyle.Clear;
  FObjectName := '';
end;                           

function TSVGObject.Clone(Parent: TSVGObject): TSVGObject;
var
  C: Integer;
begin
  Result := New(Parent);
  Result.Assign(Self);

  for C := 0 to FItems.Count - 1 do
    GetItem(C).Clone(Result);
end;

function TSVGObject.Add(Item: TSVGObject): Integer;
begin
  Result := FItems.Add(Item);
  Item.FParent := Self;
end;

procedure TSVGObject.Delete(Index: Integer);
var
  Item: TSVGBasic;
begin
  if (Index >= 0) and (Index < Count) then
  begin
    Item := FItems[Index];
    FItems.Delete(Index);
    Remove(Item);
  end;
end;

function TSVGObject.Remove(Item: TSVGObject): Integer;
begin
  Result := FItems.Remove(Item);
  if Assigned(Item) then
  begin
    if Item.FParent = Self then
      Item.FParent := nil;
  end;
end;

function TSVGObject.IndexOf(Item: TSVGObject): Integer;
begin
  Result := FItems.IndexOf(Item);
end;

function TSVGObject.FindByID(const Name: string): TSVGObject;

  procedure Walk(SVG: TSVGObject);
  var
    C: Integer;
  begin
    if (SVG.FID = Name) or ('#' + SVG.FID = Name) then
    begin
      Result := SVG;
      Exit;
    end;

    for C := 0 to SVG.Count - 1  do
    begin
      Walk(SVG[C]);
      if Assigned(Result) then
        Exit;
    end;
  end;

begin
  Result := nil;
  Walk(Self);
end;

function TSVGObject.FindByType(Typ: TClass; Previous: TSVGObject = nil): TSVGObject;
var
  Found: Boolean;

  procedure Walk(SVG: TSVGObject);
  var
    C: Integer;
  begin
    if (SVG.ClassName = Typ.ClassName) and
       (Found) then
    begin
      Result := SVG;
      Exit;
    end;

    if SVG = Previous then
      Found := True;

    for C := 0 to SVG.Count - 1  do
    begin
      Walk(SVG[C]);
      if Assigned(Result) then
        Exit;
    end;
  end;

begin
  Found := (Previous = nil);
  Result := nil;
  Walk(Self);
end;

procedure TSVGObject.AssignTo(Dest: TPersistent);
var
  SVG: TSVGObject;
begin
  if (Dest is TSVGObject) then
  begin
    SVG := Dest as TSVGObject;
    SVG.FVisible := FVisible;
    SVG.Display := FDisplay;
    SVG.FBounds := FBounds;
    SVG.FID := FID;
    SVG.FObjectName := FObjectName;

    FreeAndNil(SVG.FStyle);
    SVG.FStyle := FStyle.Clone;
    SVG.FClasses.Assign(FClasses);
  end;
end;

function TSVGObject.GetCount: Integer;
begin
  Result := FItems.Count;
end;

procedure TSVGObject.SetItem(const Index: Integer; const Item: TSVGObject);
begin
  if (Index >= 0) and (Index < Count) then
    FItems[Index] := Item;
end;

function TSVGObject.GetItem(const Index: Integer): TSVGObject;
begin
  if (Index >= 0) and (Index < Count) then
    Result := FItems[Index]
  else
    Result := nil;
end;

function TSVGObject.GetObjectBounds: TBounds;
begin
  Result := FBounds;
end;

function TSVGObject.GetRoot: TSVG;
var
  Temp: TSVGObject;
begin
  Temp := Self;

  while Assigned(Temp) and (not (Temp is TSVG)) do
    Temp := Temp.FParent;

  Result := TSVG(Temp);
end;

function TSVGObject.GetDisplay: Integer;
var
  SVG: TSVGObject;
begin
  SVG := Self;
  while Assigned(SVG) and (SVG.FDisplay = INHERIT) do
    SVG := SVG.FParent;

  if Assigned(SVG) then
    Result := SVG.FDisplay
  else
    Result := 1;
end;

function TSVGObject.GetVisible: Integer;
var
  SVG: TSVGObject;
begin
  SVG := Self;
  while Assigned(SVG) and (SVG.FVisible = INHERIT) do
    SVG := SVG.FParent;

  if Assigned(SVG) then
    Result := SVG.FVisible
  else
    Result := 1;
end;

procedure TSVGObject.ReadIn(const Node: IXMLNode);
var
  S: string;
  C: Integer;
begin
  LoadString(Node, 'id', FID);

  LoadDisplay(Node, FDisplay);
  LoadVisible(Node, FVisible);

  for C := 0 to Node.AttributeNodes.count - 1 do
  begin
    S := Node.AttributeNodes[C].nodeName;
    FStyle.AddStyle(S, Node.AttributeNodes[C].nodeValue);
  end;

  LoadString(Node, 'style', S);
  FStyle.SetValues(S);

  S := '';
  LoadString(Node, 'class', S);

  FClasses.DelimitedText := S;
  for C := FClasses.Count - 1 downto 0 do
  begin
    FClasses[C] := Trim(FClasses[C]);
    if FClasses[C] = '' then
      FClasses.Delete(C);
  end;

  FObjectName := Node.nodeName;
end;
{$ENDREGION}

{$REGION 'TSVGMatrix'}
procedure TSVGMatrix.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TSVGMatrix then
  begin
    TSVGMatrix(Dest).FPureMatrix := FPureMatrix;
  end;
end;

procedure TSVGMatrix.CalcMatrix;
var
  C: Integer;
  List: TList;
  SVG: TSVGObject;
  CompleteMatrix: TMatrix;
  LMatrix: TMatrix;
  NewMatrix: TMatrix;
begin
  List := TList.Create;

  try
    SVG := Self;

    while Assigned(SVG) do
    begin
      List.Insert(0, SVG);
      SVG := SVG.FParent;
    end;

    FillChar(CompleteMatrix, SizeOf(CompleteMatrix), 0);
    FillChar(LMatrix, SizeOf(LMatrix), 0);
    for C := 0 to List.Count - 1 do
    begin
      SVG := TSVGMatrix(List[C]);
      if (SVG is TSVGMatrix) then
      begin
        if SVG is TSVG then
          NewMatrix := TSVG(SVG).RootMatrix
        else
          NewMatrix := TSVGMatrix(SVG).FPureMatrix;

        if NewMatrix.m33 = 1 then
        begin
          if CompleteMatrix.m33 = 0 then
            CompleteMatrix := NewMatrix
          else
            CompleteMatrix := CompleteMatrix * NewMatrix;

          if not (SVG is TSVG) then
          begin
            if LMatrix.m33 = 0 then
              LMatrix := NewMatrix
            else
              LMatrix := LMatrix * NewMatrix;
          end;
        end;
      end;
    end;
  finally
    List.Free;
  end;

  FCompleteCalculatedMatrix := CompleteMatrix;
  FCalculatedMatrix := LMatrix;
end;

procedure TSVGMatrix.Clear;
begin
  inherited;
  FillChar(FPureMatrix, SizeOf(FPureMatrix), 0);
end;

procedure TSVGMatrix.ReadIn(const Node: IXMLNode);
var
  M: TMatrix;
begin
  inherited;
  M := FPureMatrix;
  LoadTransform(Node, 'transform', M);
  FPureMatrix := M;
end;

procedure TSVGMatrix.SetPureMatrix(const Value: TMatrix);
begin
  FPureMatrix := Value;

  CalcMatrix;
end;

function TSVGMatrix.Transform(const P: TPointF): TPointF;
begin
  if FCalculatedMatrix.m33 = 1 then
  begin
    Result := P * FCalculatedMatrix;
  end
  else
  begin
    Result := P;
  end;
end;

function TSVGMatrix.Transform(const X, Y: TFloat): TPointF;
begin
  Result := Transform(TPointF.Create(X,Y));
end;
{$ENDREGION}

{$REGION 'TSVGBasic'}
constructor TSVGBasic.Create;
begin
  inherited;
  FPath := nil;
  SetLength(FStrokeDashArray, 0);
  FStyle.OnChange := OnStyleChanged;
  FClipPath := nil;
end;

procedure TSVGBasic.BeforePaint(const Graphics: TGPGraphics;
  const Brush: TGPBrush; const Pen: TGPPen);
begin
end;

procedure TSVGBasic.CalcClipPath;
begin
  FClipPath := GetClipPath;
end;

procedure TSVGBasic.Clear;
begin
  inherited;

  FX := 0;
  FY := 0;
  FWidth := 0;
  FHeight := 0;
  FRX := INHERIT;
  FRY := INHERIT;
  FFillURI := '';
  FStrokeURI := '';
  FillColor := INHERIT;
  StrokeColor := INHERIT;

  StrokeWidth := INHERIT;

  StrokeOpacity := 1;
  FillOpacity := 1;
  FLineWidth := INHERIT;

  FStrokeLineJoin := '';
  FStrokeLineCap := '';
  FStrokeMiterLimit := INHERIT;
  FStrokeDashOffset := INHERIT;

  SetLength(FStrokeDashArray, 0);
  FStrokeDashArrayCount := 0;
  FArrayNone := False;

  FFontName := '';
  FFontSize := INHERIT;
  FFontWeight := INHERIT;
  FFontStyle := INHERIT;

  FTextDecoration := [tdInherit];

  FreeAndNil(FPath);
  FClipPath := nil;
end;

procedure TSVGBasic.PaintToGraphics(Graphics: TGPGraphics);
var
  Brush, StrokeBrush: TGPBrush;
  Pen: TGPPen;

  TGP: TGPMatrix;

  ClipRoot: TSVGBasic;
begin
  if (FPath = nil) {or (FPath.GetLastStatus <> OK)} then
    Exit;

  if FClipPath = nil then
    CalcClipPath;

  try
    if Assigned(FClipPath) then
    begin
      if ClipURI <> '' then
      begin
        ClipRoot := TSVGBasic(GetRoot.FindByID(ClipURI));
        if Assigned(ClipRoot) then
        begin
          TGP := GetGPMatrix(ClipRoot.Matrix);
          try
            Graphics.SetTransform(TGP);
          finally
            TGP.Free;
          end;
        end;
      end;
      Graphics.SetClip(FClipPath);
      Graphics.ResetTransform;
    end;

    TGP := GetGPMatrix(Matrix);
    try
      Graphics.SetTransform(TGP);
    finally
      TGP.Free;
    end;

    if FStyleChanged then
    begin
      UpdateStyle;
      FStyleChanged := False;
    end;
    Brush := GetFillBrush;
    try
      StrokeBrush := GetStrokeBrush;
      Pen := GetStrokePen(StrokeBrush);

      try
        BeforePaint(Graphics, Brush, Pen);
        if Assigned(Brush) and (Brush.GetLastStatus = OK) then
          Graphics.FillPath(Brush, FPath);

        if Assigned(Pen) and (Pen.GetLastStatus = OK) then
          Graphics.DrawPath(Pen, FPath);

        AfterPaint(Graphics, Brush, Pen);
      finally
        Pen.Free;
        StrokeBrush.Free;
      end;
    finally
      Brush.Free;
    end;

  finally
    Graphics.ResetTransform;
    Graphics.ResetClip;
  end;
end;

procedure TSVGBasic.PaintToPath(Path: TGPGraphicsPath);
var
  P: TGPGraphicsPath;
  M: TGPMatrix;
begin
  if FPath = nil then
    Exit;
  P := FPath.Clone;

  if Matrix.m33 = 1 then
  begin
    M := GetGPMatrix(Matrix);
    P.Transform(M);
    M.Free;
  end;

  Path.AddPath(P, False);
  P.Free;
end;

procedure TSVGBasic.OnStyleChanged(Sender: TObject);
begin
  FStyleChanged := True;
end;

procedure TSVGBasic.UpdateStyle;
var
  LRoot: TSVG;
  C: Integer;
  Style: TStyle;
begin
  LRoot := GetRoot;
  for C := -2 to FClasses.Count do
  begin
    case C of
      -2: Style := LRoot.FStyles.GetStyleByName(FObjectName);
      -1: Style := LRoot.FStyles.GetStyleByName('#' + FID);
      else
        begin
          if C < FClasses.Count then
          begin
            if Assigned(LRoot) then
            begin
              Style := LRoot.FStyles.GetStyleByName('.' + FClasses[C]);
              if Style = nil then
                Style := LRoot.FStyles.GetStyleByName(FClasses[C]);
            end else
              Style := nil;
          end else
            Style := FStyle;
          end;
        end;

    if Assigned(Style) then
      ReadStyle(Style);
  end;

  FillColor := GetColor(FFillURI);
  StrokeColor := GetColor(FStrokeURI);
  FFillURI := ParseURI(FFillURI);
  FStrokeURI := ParseURI(FStrokeURI);
  ClipURI := ParseURI(FClipURI);
end;

procedure TSVGBasic.ReadIn(const Node: IXMLNode);
begin
  inherited;

  LoadLength(Node, 'x', FX);
  LoadLength(Node, 'y', FY);
  LoadLength(Node, 'width', FWidth);
  LoadLength(Node, 'height', FHeight);
  LoadLength(Node, 'rx', FRX);
  LoadLength(Node, 'ry', FRY);

  if (FRX = INHERIT) and (FRY <> INHERIT) then
  begin
    FRX := FRY;
  end;

  if (FRY = INHERIT) and (FRX <> INHERIT) then
  begin
    FRY := FRX;
  end;

  UpdateStyle;
end;

procedure TSVGBasic.AfterPaint(const Graphics: TGPGraphics;
  const Brush: TGPBrush; const Pen: TGPPen);
begin

end;

procedure TSVGBasic.AssignTo(Dest: TPersistent);
var
  C: Integer;
begin
  inherited;

  if Dest is TSVGBasic then
  begin
    TSVGBasic(Dest).FFillColor := FFillColor;
    TSVGBasic(Dest).FStrokeColor := FStrokeColor;
    TSVGBasic(Dest).FFillOpacity := FFillOpacity;
    TSVGBasic(Dest).FStrokeOpacity := FStrokeOpacity;
    TSVGBasic(Dest).FStrokeWidth := FStrokeWidth;
    TSVGBasic(Dest).FStrokeLineJoin := FStrokeLineJoin;
    TSVGBasic(Dest).FStrokeLineCap := FStrokeLineCap;
    TSVGBasic(Dest).FStrokeMiterLimit := FStrokeMiterLimit;
    TSVGBasic(Dest).FStrokeDashOffset := FStrokeDashOffset;
    TSVGBasic(Dest).FStrokeDashArrayCount := FStrokeDashArrayCount;

    TSVGBasic(Dest).FFontName := FFontName;
    TSVGBasic(Dest).FFontSize := FFontSize;
    TSVGBasic(Dest).FFontWeight := FFontWeight;
    TSVGBasic(Dest).FFontStyle := FFontStyle;
    TSVGBasic(Dest).FTextDecoration := FTextDecoration;

    if Assigned(FStrokeDashArray) then
    begin
      SetLength(TSVGBasic(Dest).FStrokeDashArray, FStrokeDashArrayCount);
      for C := 0 to FStrokeDashArrayCount - 1 do
        TSVGBasic(Dest).FStrokeDashArray[C] := FStrokeDashArray[C];
    end;

    TSVGBasic(Dest).FArrayNone := FArrayNone;

    if Assigned(FPath) then
      TSVGBasic(Dest).FPath := FPath.Clone;

    TSVGBasic(Dest).FRX := FRX;
    TSVGBasic(Dest).FRY := FRY;
    TSVGBasic(Dest).FFillURI := FFillURI;
    TSVGBasic(Dest).FStrokeURI := FStrokeURI;
    TSVGBasic(Dest).ClipURI := FClipURI;
    TSVGBasic(Dest).FLineWidth := FLineWidth;
    TSVGBasic(Dest).FFillRule := FFillRule;
    TSVGBasic(Dest).FColorInterpolation := FColorInterpolation;
    TSVGBasic(Dest).FColorRendering := FColorRendering;

    TSVGBasic(Dest).FX := FX;
    TSVGBasic(Dest).FY := FY;
    TSVGBasic(Dest).FWidth := Width;
    TSVGBasic(Dest).FHeight := Height;
  end;
end;

function TSVGBasic.New(Parent: TSVGObject): TSVGObject;
begin
  Result := TSVGBasic.Create(Parent);
end;

procedure TSVGBasic.ReadStyle(Style: TStyle);

  procedure ConstructFont;
  var
    Bold, Italic: Integer;
    FN: string;
  begin
    Bold := Pos('Bold', FFontName);
    Italic := Pos('Italic', FFontName);

    FN := FFontName;

    // Check for Bold
    if Bold <> 0 then
    begin
      FFontName := Copy(FN, 1, Bold - 1) + Copy(FN, Bold + 4, MaxInt);
      if Copy(FFontName, Length(FFontName), 1) = '-' then
        FFontName := Copy(FFontName, 1, Length(FFontName) - 1);
      if IsFontAvailable then
      begin
        Style['font-weight'] := 'bold';
        Exit;
      end;
      if Copy(FFontName, Length(FFontName) - 1, 2) = 'MT' then
      begin
        FFontName := Copy(FFontName, 1, Length(FFontName) - 2);
        if Copy(FFontName, Length(FFontName), 1) = '-' then
          FFontName := Copy(FFontName, 1, Length(FFontName) - 1);
        if IsFontAvailable then
        begin
          Style['font-weight'] := 'bold';
          Exit;
        end;
      end;
    end;

    // Check for Italic
    if Italic <> 0 then
    begin
      FFontName := Copy(FN, 1, Italic - 1) + Copy(FN, Italic + 6, MaxInt);
      if Copy(FFontName, Length(FFontName), 1) = '-' then
        FFontName := Copy(FFontName, 1, Length(FFontName) - 1);
      if IsFontAvailable then
      begin
        Style['font-style'] := 'italic';
        Exit;
      end;
      if Copy(FFontName, Length(FFontName) - 1, 2) = 'MT' then
      begin
        FFontName := Copy(FFontName, 1, Length(FFontName) - 2);
        if Copy(FFontName, Length(FFontName), 1) = '-' then
          FFontName := Copy(FFontName, 1, Length(FFontName) - 1);
        if IsFontAvailable then
        begin
          Style['font-style'] := 'italic';
          Exit;
        end;
      end;
    end;

    // Check for Bold and Italic
    if (Bold <> 0) and (Italic <> 0) then
    begin
      FFontName := Copy(FN, 1, Bold - 1) + Copy(FN, Bold + 4, MaxInt);
      if Copy(FFontName, Length(FFontName), 1) = '-' then
        FFontName := Copy(FFontName, 1, Length(FFontName) - 1);
      Italic := Pos('Italic', FFontName);

      FFontName := Copy(FFontName, 1, Italic - 1) + Copy(FFontName, Italic + 6, MaxInt);
      if Copy(FFontName, Length(FFontName), 1) = '-' then
        FFontName := Copy(FFontName, 1, Length(FFontName) - 1);

      if IsFontAvailable then
      begin
        Style['font-weight'] := 'bold';
        Style['font-style'] := 'italic';
        Exit;
      end;
      if Copy(FFontName, Length(FFontName) - 1, 2) = 'MT' then
      begin
        FFontName := Copy(FFontName, 1, Length(FFontName) - 2);
        if Copy(FFontName, Length(FFontName), 1) = '-' then
          FFontName := Copy(FFontName, 1, Length(FFontName) - 1);
        if IsFontAvailable then
        begin
          Style['font-weight'] := 'bold';
          Style['font-style'] := 'italic';
          Exit;
        end;
      end;
    end;

    FFontName := FN;
    if Copy(FFontName, Length(FFontName) - 1, 2) = 'MT' then
    begin
      FFontName := Copy(FFontName, 1, Length(FFontName) - 2);
      if Copy(FFontName, Length(FFontName), 1) = '-' then
        FFontName := Copy(FFontName, 1, Length(FFontName) - 1);
      if IsFontAvailable then
        Exit;
    end;

    FFontName := FN;
  end;

var
  Value: string;
  SL: TStringList;
begin
  Value := Style.Values['stroke-width'];
  if Value <> '' then
    FStrokeWidth := ParseLength(Value);

  Value := Style.Values['line-width'];
  if Value <> '' then
    FLineWidth := ParseLength(Value);

  Value := Style.Values['opacity'];
  if Value <> '' then
  begin
    FStrokeOpacity := ParsePercent(Value);
    FFillOpacity := FStrokeOpacity;
  end;

  Value := Style.Values['stroke-opacity'];
  if Value <> '' then
    FStrokeOpacity := ParsePercent(Value);

  Value := Style.Values['fill-opacity'];
  if Value <> '' then
    FFillOpacity := ParsePercent(Value);

  Value := Style.Values['color'];
  if Value <> '' then
  begin
    FStrokeURI := Value;
    FFillURI := Value;
  end;

  Value := Style.Values['stroke'];
  if Value <> '' then
    FStrokeURI := Value;

  Value := Style.Values['fill'];
  if Value <> '' then
    FFillURI := Value;

  Value := Style.Values['clip-path'];
  if Value <> '' then
    ClipURI := Value;

  Value := Style.Values['stroke-linejoin'];
  if Value <> '' then
    FStrokeLineJoin := Value;

  Value := Style.Values['stroke-linecap'];
  if Value <> '' then
    FStrokeLineCap := Value;

  Value := Style.Values['stroke-miterlimit'];
  if Value <> '' then
    if not TryStrToTFloat(Value, FStrokeMiterLimit) then
      FStrokeMiterLimit := 0;

  Value := Style.Values['stroke-dashoffset'];
  if Value <> '' then
    if not TryStrToTFloat(Value, FStrokeDashOffset) then
      FStrokeDashOffset := 0;

  Value := Style.Values['stroke-dasharray'];
  if Value <> '' then
    SetStrokeDashArray(Value);

  Value := Style['font-family'];
  if Value <> '' then
  begin
    FFontName := Value;
    if not IsFontAvailable then
      ConstructFont;
  end;

  Value := Style['font-weight'];
  if Value <> '' then
    ParseFontWeight(Value);

  Value := Style['font-size'];
  if Value <> '' then
    FFontSize := ParseLength(Value);

  Value := Style['text-decoration'];
  if Value <> '' then
  begin
    SL := TStringList.Create;
    try
      SL.Delimiter := ' ';
      SL.DelimitedText := Value;

      if SL.IndexOf('underline') > -1 then
      begin
        Exclude(FTextDecoration, tdInherit);
        Include(FTextDecoration, tdUnderLine);
      end;

      if SL.IndexOf('overline') > -1 then
      begin
        Exclude(FTextDecoration, tdInherit);
        Include(FTextDecoration, tdOverLine);
      end;

      if SL.IndexOf('line-through') > -1 then
      begin
        Exclude(FTextDecoration, tdInherit);
        Include(FTextDecoration, tdStrikeOut);
      end;

      if SL.IndexOf('none') > -1 then
        FTextDecoration := [];
    finally
      SL.Free;
    end;
  end;

  Value := Style['font-style'];
  if Value <> '' then
  begin
    if Value = 'normal' then
      FFontStyle := FontNormal;

    if Value = 'italic' then
      FFontStyle := FontItalic;
  end;
end;

procedure TSVGBasic.ReadChildren(const Node: IXMLNode);
var
  C: Integer;
  SVG: TSVGObject;
  LRoot: TSVG;
  NodeName: string;
begin
  for C := 0 to Node.ChildNodes.count - 1 do
  begin
    SVG := nil;

    NodeName := Node.childNodes[C].nodeName;

    if NodeName = 'g' then
    begin
      SVG := TSVGContainer.Create(Self);
    end
    else if NodeName = 'switch' then
    begin
      SVG := TSVGSwitch.Create(Self);
    end
    else if NodeName = 'defs' then
    begin
      SVG := TSVGDefs.Create(Self);
    end
    else if NodeName = 'use' then
    begin
      SVG := TSVGUse.Create(Self);
    end
    else if NodeName = 'rect' then
    begin
      SVG := TSVGRect.Create(Self);
    end
    else if NodeName = 'line' then
    begin
      SVG := TSVGLine.Create(Self);
    end
    else if NodeName = 'polyline' then
    begin
      SVG := TSVGPolyLine.Create(Self);
    end
    else if NodeName = 'polygon' then
    begin
      SVG := TSVGPolygon.Create(Self);
    end
    else if NodeName = 'circle' then
    begin
      SVG := TSVGEllipse.Create(Self);
    end
    else if NodeName = 'ellipse' then
    begin
      SVG := TSVGEllipse.Create(Self);
    end
    else if NodeName = 'path' then
    begin
      SVG := TSVGPath.Create(Self);
    end
    else if NodeName = 'image' then
    begin
      SVG := TSVGImage.Create(Self);
    end
    else if NodeName = 'text' then
    begin
      SVG := TSVGText.Create(Self);
    end
    else if NodeName = 'tspan' then
    begin
      SVG := TSVGTSpan.Create(Self);
    end
    else if NodeName = 'textPath' then
    begin
      SVG := TSVGTextPath.Create(Self);
    end
    else if NodeName = 'clipPath' then
    begin
      SVG := TSVGClipPath.Create(Self);
    end
    else if NodeName = 'linearGradient' then
    begin
      SVG := TSVGLinearGradient.Create(Self);
    end
    else if NodeName = 'radialGradient' then
    begin
      SVG := TSVGRadialGradient.Create(Self)
    end
    else if NodeName = 'style' then
    begin
      LRoot := GetRoot;
      LRoot.ReadStyles(Node.childNodes[C]);
    end;

    if Assigned(SVG) then
    begin
      SVG.ReadIn(Node.childNodes[C]);
    end;
  end;
end;

procedure TSVGBasic.SetClipURI(const Value: string);
begin
  FClipURI := Value;

  CalcClipPath;
end;

procedure TSVGBasic.SetStrokeDashArray(const S: string);
var
  C, E: Integer;
  SL: TStringList;
  D: TFloat;
begin
  SetLength(FStrokeDashArray, 0);

  FArrayNone := False;
  if Trim(S) = 'none' then
  begin
    FArrayNone := True;
    Exit;
  end;

  SL := TStringList.Create;
  try
    SL.Delimiter := ',';
    SL.DelimitedText := S;

    for C := SL.Count - 1 downto 0 do
    begin
      SL[C] := Trim(SL[C]);
      if SL[C] = '' then
        SL.Delete(C);
    end;

    if SL.Count = 0 then
    begin
      Exit;
    end;

    if SL.Count mod 2 = 1 then
    begin
      E := SL.Count;
      for C := 0 to E - 1 do
        SL.Add(SL[C]);
    end;

    SetLength(FStrokeDashArray, SL.Count);
    FStrokeDashArrayCount := SL.Count;

    for C := 0 to SL.Count - 1 do
    begin
      if not TryStrToTFloat(SL[C], D) then
        D := 0;
      FStrokeDashArray[C] := D;
    end;
  finally
    SL.Free;
  end;
end;

function TSVGBasic.GetFillBrush: TGPBrush;
var
  Color: Integer;
  Opacity: Integer;
  Filler: TSVGObject;
begin
  Result := nil;
  Color := FillColor;
  Opacity := Round(255 * FillOpacity);

  if FFillURI <> '' then
  begin
    Filler := GetRoot.FindByID(FFillURI);
    if Assigned(Filler) and (Filler is TSVGFiller) then
      Result := TSVGFiller(Filler).GetBrush(Opacity, Self);
  end else
    if Color >= 0 then
      Result := TGPSolidBrush.Create(ConvertColor(Color, Opacity));
end;

function TSVGBasic.GetFillColor: Integer;
var
  SVG: TSVGObject;
begin
  SVG := Self;
  while Assigned(SVG) and (TSVGBasic(SVG).FFillColor = INHERIT) do
    SVG := SVG.FParent;

  if Assigned(SVG) then
    Result := TSVGBasic(SVG).FFillColor
  else
    Result := 0;
end;

function TSVGBasic.GetStrokeBrush: TGPBrush;
var
  Color: Integer;
  Opacity: Integer;
  Filler: TSVGObject;
begin
  Result := nil;
  Color := StrokeColor;
  Opacity := Round(255 * StrokeOpacity);

  if FStrokeURI <> '' then
  begin
    Filler := GetRoot.FindByID(FStrokeURI);
    if Assigned(Filler) and (Filler is TSVGFiller) then
      Result := TSVGFiller(Filler).GetBrush(Opacity, Self);
  end else
    if Color >= 0 then
      Result := TGPSolidBrush.Create(ConvertColor(Color, Opacity));
end;

function TSVGBasic.GetStrokeColor: Integer;
var
  SVG: TSVGObject;
begin
  SVG := Self;
  while Assigned(SVG) and (TSVGBasic(SVG).FStrokeColor = INHERIT) do
    SVG := SVG.FParent;

  if Assigned(SVG) then
    Result := TSVGBasic(SVG).FStrokeColor
  else
    Result := -2;
end;

function TSVGBasic.GetFillOpacity: TFloat;
var
  SVG: TSVGObject;
begin
  SVG := Self;
  while Assigned(SVG) and (TSVGBasic(SVG).FFillOpacity = INHERIT) do
    SVG := SVG.FParent;

  if Assigned(SVG) then
    Result := TSVGBasic(SVG).FFillOpacity
  else
    Result := 1;

  SVG := FParent;
  while Assigned(SVG) do
  begin
    Result := Result * TSVGBasic(SVG).FillOpacity;
    SVG  := SVG.FParent;
  end;
end;

function TSVGBasic.GetStrokeOpacity: TFloat;
var
  SVG: TSVGObject;
begin
  SVG := Self;
  while Assigned(SVG) and (TSVGBasic(SVG).FStrokeOpacity = INHERIT) do
    SVG := SVG.FParent;

  if Assigned(SVG) then
    Result := TSVGBasic(SVG).FStrokeOpacity
  else
    Result := 1;

  SVG := FParent;
  while Assigned(SVG) do
  begin
    Result := Result * TSVGBasic(SVG).StrokeOpacity;
    SVG  := SVG.FParent;
  end;
end;

function TSVGBasic.GetStrokePen(const StrokeBrush: TGPBrush): TGPPen;
var
  Pen: TGPPen;
  DashArray: PSingle;
  C: Integer;
begin
  if Assigned(StrokeBrush) and (StrokeBrush.GetLastStatus = OK) then
  begin
    Pen := TGPPen.Create(0, GetStrokeWidth);
    Pen.SetLineJoin(GetStrokeLineJoin);
    Pen.SetMiterLimit(GetStrokeMiterLimit);
    Pen.SetLineCap(GetStrokeLineCap, GetStrokeLineCap, GetStrokeDashCap);

    DashArray := GetStrokeDashArray(C);
    if Assigned(DashArray) then
    begin
      Pen.SetDashPattern(DashArray, C);
      Pen.SetDashStyle(DashStyleCustom);
      Pen.SetDashOffset(GetStrokeDashOffset);
    end;

    Pen.SetBrush(StrokeBrush);
    Result := Pen;
  end else
    Result := nil;
end;

function TSVGBasic.GetStrokeWidth: TFloat;
var
  SVG: TSVGObject;
begin
  SVG := Self;
  while Assigned(SVG) and (TSVGBasic(SVG).FStrokeWidth = INHERIT) do
    SVG := SVG.FParent;

  if Assigned(SVG) and (SVG is TSVGBasic) then
    Result := TSVGBasic(SVG).FStrokeWidth
  else
    Result := -2;
end;

function TSVGBasic.GetTextDecoration: TTextDecoration;
var
  SVG: TSVGObject;
begin
  SVG := Self;
  while Assigned(SVG) and (tdInherit in TSVGBasic(SVG).FTextDecoration) do
    SVG := SVG.FParent;

  if Assigned(SVG) then
    Result := TSVGBasic(SVG).FTextDecoration
  else
    Result := [];
end;

function TSVGBasic.IsFontAvailable: Boolean;
var
  FF: TGPFontFamily;
begin
  FF := TGPFontFamily.Create(GetFontName);
  Result :=  FF.GetLastStatus = OK;
  FF.Free;
end;

function TSVGBasic.GetClipURI: string;
var
  SVG: TSVGObject;
begin
  SVG := Self;
  while Assigned(SVG) and (TSVGBasic(SVG).FClipURI = '') do
    SVG := SVG.FParent;

  if Assigned(SVG) then
    Result := TSVGBasic(SVG).FClipURI
  else
    Result := '';
end;

function TSVGBasic.GetStrokeLineCap: TLineCap;
var
  SVG: TSVGObject;
begin
  Result := LineCapFlat;

  SVG := Self;
  while Assigned(SVG) and (TSVGBasic(SVG).FStrokeLineCap = '') do
    SVG := SVG.FParent;

  if Assigned(SVG) then
  begin
    if TSVGBasic(SVG).FStrokeLineCap = 'round' then
      Result := LineCapRound;

    if TSVGBasic(SVG).FStrokeLineCap = 'square' then
      Result := LineCapSquare;
  end;
end;

function TSVGBasic.GetStrokeDashCap: TDashCap;
var
  SVG: TSVGObject;
begin
  Result := TDashCap.DashCapFlat;

  SVG := Self;
  while Assigned(SVG) and (TSVGBasic(SVG).FStrokeLineCap = '') do
  begin
    SVG := SVG.FParent;
  end;

  if Assigned(SVG) then
  begin
    if TSVGBasic(SVG).FStrokeLineCap = 'round' then
    begin
      Result := TDashCap.DashCapRound;
    end;
  end;
end;

function TSVGBasic.GetStrokeLineJoin: TLineJoin;
var
  SVG: TSVGObject;
begin
  Result := LineJoinMiterClipped;

  SVG := Self;
  while Assigned(SVG) and (TSVGBasic(SVG).FStrokeLineJoin = '') do
    SVG := SVG.FParent;

  if Assigned(SVG) then
  begin
    if TSVGBasic(SVG).FStrokeLineJoin = 'round' then
      Result := LineJoinRound;

    if TSVGBasic(SVG).FStrokeLineJoin = 'bevel' then
      Result := LineJoinBevel;
  end;
end;

function TSVGBasic.GetStrokeMiterLimit: TFloat;
var
  SVG: TSVGObject;
begin
  Result := 4;

  SVG := Self;
  while Assigned(SVG) and (TSVGBasic(SVG).FStrokeMiterLimit = INHERIT) do
    SVG := SVG.FParent;

  if Assigned(SVG) and (TSVGBasic(SVG).FStrokeMiterLimit <> INHERIT) then
      Result := TSVGBasic(SVG).FStrokeMiterLimit;
end;

function TSVGBasic.GetStrokeDashOffset: TFloat;
var
  SVG: TSVGObject;
begin
  Result := 0;

  SVG := Self;
  while Assigned(SVG) and (TSVGBasic(SVG).FStrokeDashOffset = INHERIT) do
    SVG := SVG.FParent;

  if Assigned(SVG) and (TSVGBasic(SVG).FStrokeDashOffset <> INHERIT) then
      Result := TSVGBasic(SVG).FStrokeDashOffset;
end;

function TSVGBasic.GetStrokeDashArray(var Count: Integer): PSingle;
var
  SVG: TSVGObject;
begin
  Result := nil;
  Count := 0;

  SVG := Self;
  while Assigned(SVG) and
        (TSVGBasic(SVG).FStrokeDashArrayCount = 0) and
        (not TSVGBasic(SVG).FArrayNone) do
    SVG := SVG.FParent;

  if Assigned(SVG) and Assigned(TSVGBasic(SVG).FStrokeDashArray) and
     (not TSVGBasic(SVG).FArrayNone) then
  begin
    Result := @TSVGBasic(SVG).FStrokeDashArray;
    Count := TSVGBasic(SVG).FStrokeDashArrayCount;
  end;
end;

function TSVGBasic.GetFontName: string;
var
  SVG: TSVGObject;
begin
  SVG := Self;
  while Assigned(SVG) and
    ((not (SVG is TSVGBasic)) or (TSVGBasic(SVG).FFontName = '')) do
    SVG := SVG.FParent;

  if Assigned(SVG) and (SVG is TSVGBasic) then
    Result := TSVGBasic(SVG).FFontName
  else
    Result := 'Arial';
end;

function TSVGBasic.GetFontWeight: Integer;
var
  SVG: TSVGObject;
begin
  SVG := Self;
  while Assigned(SVG) and
    ((not (SVG is TSVGBasic)) or (TSVGBasic(SVG).FFontWeight = INHERIT)) do
    SVG := SVG.FParent;

  if Assigned(SVG) and (SVG is TSVGBasic) then
    Result := TSVGBasic(SVG).FFontWeight
  else
    Result := FW_NORMAL;
end;

function TSVGBasic.GetFontSize: TFloat;
var
  SVG: TSVGObject;
begin
  SVG := Self;
  while Assigned(SVG) and
    ((not (SVG is TSVGBasic)) or (TSVGBasic(SVG).FFontSize = INHERIT)) do
    SVG := SVG.FParent;

  if Assigned(SVG) and (SVG is TSVGBasic) then
    Result := TSVGBasic(SVG).FFontSize
  else
    Result := 11;
end;

function TSVGBasic.GetFontStyle: Integer;
var
  SVG: TSVGObject;
begin
  SVG := Self;
  while Assigned(SVG) and
    ((not (SVG is TSVGBasic)) or (TSVGBasic(SVG).FFontStyle = INHERIT)) do
    SVG := SVG.FParent;

  if Assigned(SVG) and (SVG is TSVGBasic) then
    Result := TSVGBasic(SVG).FFontStyle
  else
    Result := 0;
end;

procedure TSVGBasic.ParseFontWeight(const S: string);
begin
  if S = 'normal' then
  begin
    FFontWeight := FW_NORMAL;
  end
  else if S = 'bold' then
  begin
    FFontWeight := FW_BOLD;
  end
  else if S = 'bolder' then
  begin
    FFontWeight := FW_EXTRABOLD;
  end
  else if S = 'lighter' then
  begin
    FFontWeight := FW_LIGHT;
  end
  else
  begin
    TryStrToInt(S, FFontWeight);
  end;
end;

procedure TSVGBasic.ConstructPath;
begin
  FreeAndNil(FPath);
end;

function TSVGBasic.GetClipPath: TGPGraphicsPath;
var
  Path: TSVGObject;
  ClipRoot: TSVGClipPath;
begin
  Result := nil;

  if ClipURI <> '' then
  begin
    Path := GetRoot.FindByID(ClipURI);
    if Path is TSVGClipPath then
      ClipRoot := TSVGClipPath(Path)
    else
      ClipRoot := nil;
    if Assigned(ClipRoot) then
      Result := ClipRoot.GetClipPath;
  end;
end;
{$ENDREGION}

{$REGION 'TSVG'}
procedure TSVG.LoadFromText(const Text: string);
var
  XML: IXMLDocument;
  DocNode: IXMLNode;
begin
  Clear;
  try
    FSource := Text;
    {$IFDEF MSWINDOWS}
    TMSXMLDOMDocumentFactory.AddDOMProperty('ProhibitDTD', False, True);
    {$ENDIF}
    XML := TXmlDocument.Create(nil);
    XML.LoadFromXML(Text);

    if Assigned(XML) then
    begin
      DocNode := XML.documentElement;
      if Assigned(DocNode) and (DocNode.nodeName = 'svg') then
        ReadIn(DocNode)
      else
        FSource := '';
    end else
      FSource := '';
  finally
    XML := nil;
  end;
end;

procedure TSVG.LoadFromFile(const FileName: string);
var
  St: TFileStream;
begin
  St := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    LoadFromStream(St);
    FFileName := FileName;
  finally
    St.Free;
  end;
end;

procedure TSVG.LoadFromStream(Stream: TStream);
var
  SL: TStringList;
begin
  SL := TstringList.Create;
  try
    Stream.Position := 0;
    SL.LoadFromStream(Stream, TEncoding.UTF8);
    LoadFromText(SL.Text);
  finally
    SL.Free;
  end;
end;

procedure TSVG.SaveToFile(const FileName: string);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TSVG.SaveToStream(Stream: TStream);
var
  SL: TstringList;
begin
  SL := TstringList.Create;
  try
    SL.Text := FSource;
    SL.SaveToStream(Stream);
  finally
    SL.Free;
  end;
end;

function TSVG.SaveToNode(const Parent: IXMLNode; Left, Top, Width, Height: TFloat): IXMLNode;

  function ConvertFloat(const D: TFloat): string;
  begin
    Result := FloatToStr(D);
    Result := StringReplace(Result, ',', '.', []);
  end;

var
  XML: IXMLDocument;
  Translation: string;
  LScale: string;
  C: Integer;
  Container: IXMLNode;
  Attribute: IXMLNode;
  NewNode: IXMLNode;
begin
  Result := nil;
  if FSource = '' then
    Exit;

  try
    {$IFDEF MSWINDOWS}
    TMSXMLDOMDocumentFactory.AddDOMProperty('ProhibitDTD', False, True);
    {$ENDIF}
    XML := TXmlDocument.Create(nil);
    XML.LoadFromXML(FSource);

    Container := Parent.ownerDocument.createElement('g', '');
    Parent.ChildNodes.Add(Container);

    if (Left <> 0) or (Top <> 0) then
      Translation := 'translate(' + ConvertFloat(Left) + ', ' + ConvertFloat(Top) + ')'
    else
      Translation := '';

    if (Width <> FWidth) or (Height <> FHeight) then
      LScale := 'scale(' + ConvertFloat(Width / FWidth) + ', ' +
        ConvertFloat(Width / FWidth) + ')'
    else
       LScale := '';

    if LScale <> '' then
    begin
      if Translation = '' then
      begin
        Translation := LScale
      end
      else
      begin
        Translation := Translation + ' ' + LScale;
      end;
    end;

    if Translation <> '' then
    begin
      Attribute := Container.ownerDocument.createElement('transform', '');
//      Container.attributes.setNamedItem(Attribute);
    end;

    for C := 0 to XML.documentElement.childNodes.Count - 1 do
    begin
      NewNode := XML.documentElement.childNodes[C].cloneNode(True);
      Container.childNodes[C].ChildNodes.Add(NewNode);
      Result := NewNode;
    end;
  finally
    XML := nil;
  end;
end;

procedure TSVG.Scale(const ADX: TFloat; ADY: TFloat = -1);
begin
  if ADY < 0 then
  begin
    ADY := ADX;
  end;

  if not (SameValue(FDX, ADX) and SameValue(FDY, ADY)) then
  begin
    FDX := ADX;
    FDY := ADY;
  end;
end;

procedure TSVG.PaintTo(DC: HDC; Bounds: TGPRectF;
  Rects: PRectArray; RectCount: Integer);
var
  Graphics: TGPGraphics;
begin
  Graphics := TGPGraphics.Create(DC);
  try
    Graphics.SetSmoothingMode(SmoothingModeAntiAlias);
    PaintTo(Graphics, Bounds, Rects, RectCount);
  finally
    Graphics.Free;
  end;
end;

procedure TSVG.PaintTo(MetaFile: TGPMetaFile; Bounds: TGPRectF;
  Rects: PRectArray; RectCount: Integer);
var
  Graphics: TGPGraphics;
begin
  Graphics := TGPGraphics.Create(MetaFile);
  try
    Graphics.SetSmoothingMode(SmoothingModeAntiAlias);
    PaintTo(Graphics, Bounds, Rects, RectCount);
  finally
    Graphics.Free;
  end;
end;

procedure TSVG.PaintTo(Graphics: TGPGraphics; Bounds: TGPRectF;
  Rects: PRectArray; RectCount: Integer);
var
  M: TGPMatrix;
  MA: Winapi.GDIPOBJ.TMatrixArray;
begin
  M := TGPMatrix.Create;
  try
    Graphics.GetTransform(M);
    try
      M.GetElements(MA);

      FInitialMatrix.m11 := MA[0];
      FInitialMatrix.m12 := MA[1];
      FInitialMatrix.m21 := MA[2];
      FInitialMatrix.m22 := MA[3];
      FInitialMatrix.m31 := MA[4];
      FInitialMatrix.m32 := MA[5];
      FInitialMatrix.m33 := 1;

      SetBounds(Bounds);

      Paint(Graphics, Rects, RectCount);
    finally
      Graphics.SetTransform(M);
    end;
  finally
    M.Free;
  end;
end;

constructor TSVG.Create;
begin
  inherited;
  FStyles := TStyleList.Create;
  FillChar(FInitialMatrix, SizeOf(FInitialMatrix), 0);
  FDX := 1;
  FDY := 1;
end;

destructor TSVG.Destroy;
begin
  FreeAndNil(FStyles);
  inherited;
end;

procedure TSVG.Clear;
begin
  inherited;

  FSource := '';

  if Assigned(FStyles) then
    FStyles.Clear;

  FillChar(FViewBox, SizeOf(FViewBox), 0);
  FillChar(FInitialMatrix, SizeOf(FInitialMatrix), 0);

  FX := 0;
  FY := 0;
  FWidth := 0;
  FHeight := 0;

  FSize := MakeRect(0.0, 0, 0, 0);

  FRX := 0;
  FRY := 0;

  FillColor := -2;
  FillOpacity := 1;
  StrokeColor := -2;
  StrokeWidth := 1;
  StrokeOpacity := 1;

  FAngle := 0;
  FillChar(FAngleMatrix, SizeOf(TMatrix), 0);

  FLineWidth := 1;

  FFileName := '';
end;

procedure TSVG.SetSVGOpacity(Opacity: TFloat);
begin
  StrokeOpacity := Opacity;
  FillOpacity := Opacity;
end;

procedure TSVG.SetViewBox(const Value: TRectF);
begin
  FViewBox := Value;
end;

procedure TSVG.SetAngle(Angle: TFloat);
var
  X: Single;
  Y: Single;
begin
  if not SameValue(FAngle, Angle) then
  begin
    FAngle := Angle;
    X := Width / 2;
    Y := Height / 2;
    FAngleMatrix := TMatrix.CreateTranslation(X, Y) * TMatrix.CreateRotation(Angle) *
      TMatrix.CreateTranslation(-X, -Y)
  end;
end;

procedure TSVG.SetBounds(const Bounds: TGPRectF);
begin
  FRootBounds := Bounds;

  if FWidth = 0 then
    FWidth := FRootBounds.Width;

  if FHeight = 0 then
    FHeight := FRootBounds.Height;

  if (FWidth > 0) and (FRootBounds.Width <> -1) then
    FDX := FRootBounds.Width / FWidth;

  if (FHeight > 0) and (FRootBounds.Height <> -1) then
    FDY := FRootBounds.Height / FHeight;

  CalculateMatrices;
end;

procedure TSVG.Paint(const Graphics: TGPGraphics; Rects: PRectArray;
  RectCount: Integer);

  procedure PaintBounds(const Item: TSVGObject);
  var
    Pen: TGPPen;
  begin
    Graphics.ResetTransform;
    Pen := TGPPen.Create(MakeColor(0, 0, 0), 2);
    Graphics.DrawLine(Pen, Item.ObjectBounds.TopLeft.X, Item.ObjectBounds.TopLeft.Y,
      Item.ObjectBounds.TopRight.X, Item.ObjectBounds.TopRight.Y);

    Graphics.DrawLine(Pen, Item.ObjectBounds.TopRight.X, Item.ObjectBounds.TopRight.Y,
      Item.ObjectBounds.BottomRight.X, Item.ObjectBounds.BottomRight.Y);

    Graphics.DrawLine(Pen, Item.ObjectBounds.BottomRight.X, Item.ObjectBounds.BottomRight.Y,
      Item.ObjectBounds.BottomLeft.X, Item.ObjectBounds.BottomLeft.Y);

    Graphics.DrawLine(Pen, Item.ObjectBounds.BottomLeft.X, Item.ObjectBounds.BottomLeft.Y,
      Item.ObjectBounds.TopLeft.X, Item.ObjectBounds.TopLeft.Y);

    Pen.Free;
  end;

  function InBounds(Item: TSVGObject): Boolean;
  var
    C: Integer;
    Bounds: TBounds;
  begin
    Result := True;
    if RectCount > 0 then
    begin
      for C := 0 to RectCount - 1 do
      begin
        Bounds := Item.ObjectBounds;
        if Intersect(Bounds, Rects^[C]) then
          Exit;
      end;
      Result := False;
    end;
  end;

  function NeedsPainting(Item: TSVGObject): Boolean;
  begin
    Result := (Item.Display = 1) and
       (Item.FStyle.Values['display'] <> 'none') and
       (Item.Visible = 1);
  end;

  procedure PaintItem(const Item: TSVGObject);
  var
    C: Integer;
  begin
    if NeedsPainting(Item) then
    begin
      if InBounds(Item) then
        Item.PaintToGraphics(Graphics);
      for C := 0 to Item.Count - 1 do
        PaintItem(Item[C]);
    end;
  end;

begin
  PaintItem(Self);
end;

procedure TSVG.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TSVG then
  begin
    TSVG(Dest).FRootBounds := FRootBounds;
    TSVG(Dest).FDX := FDX;
    TSVG(Dest).FDY := FDY;
    TSVG(Dest).FInitialMatrix := FInitialMatrix;
    TSVG(Dest).FViewBox := FViewBox;
    TSVG(Dest).FSource := Source;
    TSVG(Dest).FSize := FSize;

    FreeAndNil(TSVG(Dest).FStyles);
    TSVG(Dest).FStyles := FStyles.Clone;
    TSVG(Dest).FFileName := FFileName;
  end;
end;

function TSVG.New(Parent: TSVGObject): TSVGObject;
begin
  Result := TSVG.Create(Parent);
end;

procedure TSVG.ReadStyles(const Node: IXMLNode);
var
  C: Integer;
  SL: TStrings;
begin
  SL := TStringList.Create;
  try
    if Node.Attributes['type'] = 'text/css' then
    begin
      SL.Text := Node.text;
    end
    else
    begin
      for C := 0 to Node.childNodes.count - 1 do
      begin
        if Node.childNodes[C].nodeName = '#cdata-section' then
        begin
          SL.Text := Node.childNodes[C].text;
        end;
      end;
    end;

    for C := SL.Count - 1 downto 0 do
    begin
      SL[C] := Trim(SL[C]);
      if SL[C] = '' then
      begin
        SL.Delete(C);
      end;
    end;
    for C := 0 to SL.Count - 1 do
      FStyles.Add(SL[C]);
  finally
    SL.Free;
  end;
end;

function TSVG.RenderToBitmap(Width, Height: Integer): HBITMAP;
var
  Bitmap: TGPBitmap;
  Graphics: TGPGraphics;
  R: TGPRectF;
begin
  Result := 0;
  if (Width = 0) or (Height = 0) then
    Exit;

  Bitmap := TGPBitmap.Create(Width, Height);
  try
    Graphics := TGPGraphics.Create(Bitmap);
    try
      Graphics.SetSmoothingMode(SmoothingModeAntiAlias);
      R := CalcRect(MakeRect(0.0, 0, Width, Height), FWidth, FHeight, baCenterCenter);
      PaintTo(Graphics, R, nil, 0);
    finally
      Graphics.Free;
    end;
    Bitmap.GetHBITMAP(MakeColor(255, 255, 255), Result);
  finally
    Bitmap.Free;
  end;
end;

function TSVG.RenderToIcon(Size: Integer): HICON;
var
  Bitmap: TGPBitmap;
  Graphics: TGPGraphics;
  R: TGPRectF;
begin
  Result := 0;
  if Size = 0 then
    Exit;

  Bitmap := TGPBitmap.Create(Size, Size);
  try
    Graphics := TGPGraphics.Create(Bitmap);
    try
      Graphics.SetSmoothingMode(SmoothingModeAntiAlias);
      R := CalcRect(MakeRect(0.0, 0, Size, Size), Width, Height, baCenterCenter);
      PaintTo(Graphics, R, nil, 0);
    finally
      Graphics.Free;
    end;
    Bitmap.GetHICON(Result);
  finally
    Bitmap.Free;
  end;
end;

procedure TSVG.CalcCompleteSize;

  function GetLeft(const Bounds: TBounds): TFloat;
  begin
    Result := Min(Bounds.TopLeft.X,
      Min(Bounds.TopRight.X,
        Min(Bounds.BottomLeft.X, Bounds.BottomRight.X)));
  end;

  function GetTop(const Bounds: TBounds): TFloat;
  begin
    Result := Min(Bounds.TopLeft.Y,
      Min(Bounds.TopRight.Y,
        Min(Bounds.BottomLeft.Y, Bounds.BottomRight.Y)));
  end;

  function GetRight(const Bounds: TBounds): TFloat;
  begin
    Result := Max(Bounds.TopLeft.X,
      Max(Bounds.TopRight.X,
        Max(Bounds.BottomLeft.X, Bounds.BottomRight.X)));
  end;

  function GetBottom(const Bounds: TBounds): TFloat;
  begin
    Result := Max(Bounds.TopLeft.Y,
      Max(Bounds.TopRight.Y,
        Max(Bounds.BottomLeft.Y, Bounds.BottomRight.Y)));
  end;

  procedure Walk(Item: TSVGObject);
  var
    C: Integer;
    Left, Top, Right, Bottom, Width, Height: TFloat;
  begin
    Item.CalcObjectBounds;
    Left := GetLeft(Item.FBounds);
    Top := GetTop(Item.FBounds);
    Right := GetRight(Item.FBounds);
    Bottom := GetBottom(Item.FBounds);

    Width := Right - Left;
    Height := Bottom - Top;

    FSize.Width := Max(Width, FSize.Width);
    FSize.Height := Max(Height, FSize.Height);

    for C := 0 to Item.Count - 1 do
      Walk(Item[C]);
  end;

begin
  Walk(Self);
end;

procedure TSVG.CalcRootMatrix;
var
  ViewBoxMatrix: TMatrix;
  BoundsMatrix: TMatrix;
  ScaleMatrix: TMatrix;
begin
  ViewBoxMatrix := TMatrix.CreateTranslation(-FViewBox.Left, -FViewBox.Top);
  BoundsMatrix := TMatrix.CreateTranslation(FRootBounds.X, FRootBounds.Y);
  ScaleMatrix := TMatrix.CreateScaling(FDX, FDY);

  if FInitialMatrix.m33 = 1 then
  begin
    FRootMatrix := FInitialMatrix
  end
  else
  begin
    FRootMatrix := TMatrix.Identity;
  end;

  FRootMatrix := BoundsMatrix * FRootMatrix;
  FRootMatrix := ViewBoxMatrix * FRootMatrix;
  FRootMatrix := ScaleMatrix * FRootMatrix;
  if FAngleMatrix.m33 = 1 then
    FRootMatrix := FAngleMatrix * FRootMatrix;

  if FPureMatrix.m33 = 1 then
    FRootMatrix := FPureMatrix * FRootMatrix;
end;

procedure TSVG.ReadIn(const Node: IXMLNode);
var
  ViewBoxStr: string;
begin
  if Node.nodeName <> 'svg' then
    Exit;

  inherited;

  Display := 1;
  Visible := 1;

  FViewBox.Width := FWidth;
  FViewBox.Height := FHeight;

  ViewBoxStr := VarToStr(Node.Attributes['viewBox']);
  if ViewBoxStr <> '' then
    FViewBox := ParseDRect(ViewBoxStr);

  //Fix for SVG without width and height but with viewBox
  if (FWidth = 0) and (FHeight = 0) then
  begin
    FWidth := FViewBox.Width;
    FHeight := FViewBox.Height;
  end;

  ReadChildren(Node);

  DeReferenceUse;

  CalcCompleteSize;

  if ParseUnit(VarToStr(Node.Attributes['width'])) = suPercent then
    FWidth := FSize.Width * 100 / FWidth;

  if ParseUnit(VarToStr(Node.Attributes['height'])) = suPercent then
    FHeight := FSize.Height * 100 / FHeight;
end;

procedure TSVG.DeReferenceUse;
var
  Child: TSVgObject;
begin
  Child := FindByType(TSVGUse);
  while Assigned(Child) do
  begin
    TSVGUse(Child).Construct;
    Child := FindByType(TSVGUse, Child);
  end;
end;

function TSVG.GetStyleValue(const Name, Key: string): string;
var
  Style: TStyle;
begin
  Result := '';
  Style := FStyles.GetStyleByName(Name);
  if Assigned(Style) then
    Result := Style[Key];
end;
{$ENDREGION}

// TSVGContainer

function TSVGContainer.New(Parent: TSVGObject): TSVGObject;
begin
  Result := TSVGContainer.Create(Parent);
end;

procedure TSVGContainer.ReadIn(const Node: IXMLNode);
begin
  inherited;
  ReadChildren(Node);
end;

// TSVGSwitch

function TSVGSwitch.New(Parent: TSVGObject): TSVGObject;
begin
  Result := TSVGSwitch.Create(Parent);
end;

procedure TSVGSwitch.ReadIn(const Node: IXMLNode);
begin
  inherited;
  ReadChildren(Node);
end;

// TSVGDefs

function TSVGDefs.New(Parent: TSVGObject): TSVGObject;
begin
  Result := TSVGDefs.Create(Parent);
end;

procedure TSVGDefs.ReadIn(const Node: IXMLNode);
begin
  inherited;
  Display := 0;
  ReadChildren(Node);
end;

// TSVGDefs

function TSVGUse.New(Parent: TSVGObject): TSVGObject;
begin
  Result := TSVGUse.Create(Parent);
end;

procedure TSVGUse.PaintToGraphics(Graphics: TGPGraphics);
begin
end;

procedure TSVGUse.PaintToPath(Path: TGPGraphicsPath);
var
  UseObject: TSVGBasic;
begin
  inherited;

  if FReference <> '' then
  begin
    UseObject := TSVGBasic(GetRoot.FindByID(FReference));
    if Assigned(UseObject) then
      UseObject.PaintToPath(Path);
  end;
end;

procedure TSVGUse.Construct;
var
  Container: TSVGContainer;
  SVG: TSVGObject;
  Child: TSVGObject;
  Matrix: TMatrix;
begin
  while Count > 0 do
    GetItem(0).Free;

  SVG := nil;
  if FReference <> '' then
  begin
    if FReference[1] = '#' then
      SVG := GetRoot.FindByID(Copy(FReference, 2, MaxInt));
  end;

  if Assigned(SVG) then
  begin
    Matrix := TMatrix.CreateTranslation(X, Y);

    Container := TSVGContainer.Create(Self);
    Container.FObjectName := 'g';
    Container.FPureMatrix := Matrix;
    SVG := SVG.Clone(Container);

    Child := SVG.FindByType(TSVGUse);
    while Assigned(Child) do
    begin
      TSVGUse(Child).Construct;
      Child := SVG.FindByType(TSVGUse);
    end;
  end;
end;

procedure TSVGUse.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TSVGUse then
  begin
    TSVGUse(Dest).FReference := FReference;
  end;
end;

procedure TSVGUse.Clear;
begin
  inherited;
  FReference := '';
end;

procedure TSVGUse.ReadIn(const Node: IXMLNode);
begin
  inherited;
  LoadString(Node, 'xlink:href', FReference);
end;

{$REGION 'TSVGRect'}

procedure TSVGRect.ReadIn(const Node: IXMLNode);
begin
  inherited;

  if FRX > FWidth / 2 then
    FRX := FWidth / 2;

  if FRY > FHeight / 2 then
    FRY := FHeight / 2;

  ConstructPath;
end;

function TSVGRect.New(Parent: TSVGObject): TSVGObject;
begin
  Result := TSVGRect.Create(Parent);
end;

procedure TSVGRect.CalcObjectBounds;
var
  SW: TFloat;
begin
  SW := Max(0, GetStrokeWidth) / 2;
  FBounds.TopLeft := Transform(FX - SW, FY - SW);
  FBounds.TopRight := Transform(FX + FWidth + SW, FY - SW);
  FBounds.BottomRight := Transform(FX + FWidth + SW, FY + Height + SW);
  FBounds.BottomLeft := Transform(FX - SW, FY + FHeight + SW);
end;

procedure TSVGRect.ConstructPath;
begin
  inherited;
  FPath := TGPGraphicsPath2.Create;

  if (FRX <= 0) and (FRY <= 0) then
    FPath.AddRectangle(MakeRect(FX, FY, FWidth, FHeight))
  else
    FPath.AddRoundRect(FX, FY, FWidth, FHeight, FRX, FRY);
end;
{$ENDREGION}

{$REGION 'TSVGLine'}
procedure TSVGLine.ReadIn(const Node: IXMLNode);
begin
  inherited;

  LoadLength(Node, 'x1', FX);
  LoadLength(Node, 'y1', FY);
  LoadLength(Node, 'x2', FWidth);
  LoadLength(Node, 'y2', FHeight);

  ConstructPath;
end;

function TSVGLine.New(Parent: TSVGObject): TSVGObject;
begin
  Result := TSVGLine.Create(Parent);
end;

procedure TSVGLine.CalcObjectBounds;
var
  SW: TFloat;
  Left, Top, Right, Bottom: TFloat;
begin
  SW := Max(0, GetStrokeWidth) / 2;
  Left := Min(X, Width) - SW;
  Top := Min(Y, Height) - SW;
  Right := Max(X, Width) + SW;
  Bottom := Max(Y, Height) + SW;
  FBounds.TopLeft := Transform(Left, Top);
  FBounds.TopRight := Transform(Right, Top);
  FBounds.BottomRight := Transform(Right, Bottom);
  FBounds.BottomLeft := Transform(Left, Bottom);
end;

procedure TSVGLine.ConstructPath;
begin
  inherited;
  FPath := TGPGraphicsPath2.Create;
  FPath.AddLine(X, Y, Width, Height);
end;
{$ENDREGION}

{$REGION 'TSVGPolyLine'}
constructor TSVGPolyLine.Create;
begin
  inherited;
  FPointCount := 0;
end;

procedure TSVGPolyLine.CalcObjectBounds;
var
  Left, Top, Right, Bottom: TFloat;
  C: Integer;
  SW: TFloat;
begin
  Left := MaxTFloat;
  Top := MaxTFloat;
  Right := -MaxTFloat;
  Bottom := -MaxTFloat;
  for C := 0 to FPointCount - 1 do
  begin
    if FPoints[C].X < Left then
      Left := FPoints[C].X;

    if FPoints[C].X > Right then
      Right := FPoints[C].X;

    if FPoints[C].Y < Top then
      Top := FPoints[C].Y;

    if FPoints[C].Y > Bottom then
      Bottom := FPoints[C].Y;
  end;

  SW := Max(0, GetStrokeWidth) / 2;
  FBounds.TopLeft := Transform(Left - SW, Top - SW);
  FBounds.TopRight := Transform(Right + SW, Top - SW);
  FBounds.BottomRight := Transform(Right + SW, Bottom + SW);
  FBounds.BottomLeft := Transform(Left - SW, Bottom + SW);
end;

procedure TSVGPolyLine.Clear;
begin
  inherited;

  SetLength(FPoints, 0);
  FPointCount := 0;
end;

procedure TSVGPolyLine.AssignTo(Dest: TPersistent);
var
  C: Integer;
begin
  inherited;
  if Dest is TSVGPolyLine then
  begin
    TSVGPolyLine(Dest).FPointCount := FPointCount;

    if Assigned(FPoints) then
    begin
      SetLength(TSVGPolyLine(Dest).FPoints, FPointCount);
      for C := 0 to FPointCount - 1 do
      begin
        TSVGPolyLine(Dest).FPoints[C].X := FPoints[C].X;
        TSVGPolyLine(Dest).FPoints[C].Y := FPoints[C].Y;
      end;
    end;
  end;
end;

function TSVGPolyLine.New(Parent: TSVGObject): TSVGObject;
begin
  Result := TSVGPolyLine.Create(Parent);
end;

procedure TSVGPolyLine.ConstructPoints(const S: string);
var
  SL: TStrings;
  C: Integer;
begin
  SL := TStringList.Create;
  SL.Delimiter := ' ';
  SL.DelimitedText := S;

  for C := SL.Count - 1 downto 0 do
    if SL[C] = '' then
      SL.Delete(C);

  if SL.Count mod 2 = 1 then
  begin
    SL.Free;
    Exit;
  end;

  SetLength(FPoints, 0);

  FPointCount := SL.Count div 2;
  SetLength(FPoints, FPointCount);

  for C := 0 to FPointCount - 1 do
  begin
    if not TryStrToTFloat(SL[C * 2], FPoints[C].X) then
      FPoints[C].X := 0;
    if not TryStrToTFloat(SL[C * 2 + 1], FPoints[C].Y) then
      FPoints[C].Y := 0;
  end;

  SL.Free;
end;

procedure TSVGPolyLine.ReadIn(const Node: IXMLNode);
var
  S: string;
begin
  inherited;

  LoadString(Node, 'points', S);

  S := StringReplace(S, ',', ' ', [rfReplaceAll]);
  S := StringReplace(S, '-', ' -', [rfReplaceAll]);

  ConstructPoints(S);

  ConstructPath;
end;

procedure TSVGPolyLine.ConstructPath;
var
  C: Integer;
begin
  inherited;
  if FPoints = nil then
    Exit;

  FPath := TGPGraphicsPath2.Create;

  for C := 1 to FPointCount - 1 do
    FPath.AddLine(FPoints[C - 1].X, FPoints[C - 1].Y, FPoints[C].X, FPoints[C].Y);
end;
{$ENDREGION}

{$REGION 'TSVGPolygon'}
function TSVGPolygon.New(Parent: TSVGObject): TSVGObject;
begin
  Result := TSVGPolygon.Create(Parent);
end;

procedure TSVGPolygon.ConstructPath;
begin
  inherited;

  if FPoints = nil then
    Exit;

  FPath.CloseFigure;
end;
{$ENDREGION}

{$REGION 'TSVGEllipse'}
procedure TSVGEllipse.ReadIn(const Node: IXMLNode);
begin
  inherited;

  LoadLength(Node, 'cx', FX);
  LoadLength(Node, 'cy', FY);

  if Node.NodeName = 'circle' then
  begin
    LoadLength(Node, 'r', FWidth);
    FHeight := FWidth;
  end else
  begin
    LoadLength(Node, 'rx', FWidth);
    LoadLength(Node, 'ry', FHeight);
  end;

  ConstructPath;
end;

function TSVGEllipse.New(Parent: TSVGObject): TSVGObject;
begin
  Result := TSVGEllipse.Create(Parent);
end;

procedure TSVGEllipse.CalcObjectBounds;
var
  SW: TFloat;
begin
  SW := Max(0, GetStrokeWidth) / 2;
  FBounds.TopLeft := Transform(X - Width - SW, Y - Height - SW);
  FBounds.TopRight := Transform(X + Width + SW, Y - Height - SW);
  FBounds.BottomRight := Transform(X + Width + SW, Y + Height + SW);
  FBounds.BottomLeft := Transform(X - Width - SW, Y + Height + SW);
end;

procedure TSVGEllipse.ConstructPath;
begin
  inherited;
  FPath := TGPGraphicsPath2.Create;
  FPath.AddEllipse(X - Width, Y - Height, 2 * Width, 2 * Height);
end;
{$ENDREGION}

{$REGION 'TSVGPath'}
procedure TSVGPath.CalcObjectBounds;
var
  C: Integer;
  R: TRectF;
  Left, Top, Right, Bottom: TFloat;
  Found: Boolean;
  SW: TFloat;
begin
  Left := MaxTFloat;
  Top := MaxTFloat;
  Right := -MaxTFloat;
  Bottom := -MaxTFloat;
  Found := False;

  for C := 0 to Count - 1 do
  begin
    R := TSVGPathElement(Items[C]).GetBounds;
    if (R.Width <> 0) or (R.Height <> 0) then
    begin
      Found := True;
      Left := Min(Left, R.Left);
      Top := Min(Top, R.Top);
      Right := Max(Right, R.Left + R.Width);
      Bottom := Max(Bottom, R.Top + R.Height);
    end;
  end;

  if not Found then
  begin
    Left := 0;
    Top := 0;
    Right := 0;
    Bottom := 0;
  end;

  SW := Max(0, GetStrokeWidth) / 2;
  FBounds.TopLeft := Transform(Left - SW, Top - SW);
  FBounds.TopRight := Transform(Right + SW, Top - SW);
  FBounds.BottomRight := Transform(Right + SW, Bottom + SW);
  FBounds.BottomLeft := Transform(Left - SW, Bottom + SW);
end;

procedure TSVGPath.ConstructPath;
var
  C: Integer;
  Element: TSVGPathElement;
begin
  inherited;

  FPath := TGPGraphicsPath2.Create(FillModeWinding);
  for C := 0 to Count - 1 do
  begin
    Element := TSVGPathElement(Items[C]);
    Element.AddToPath(FPath);
  end;
end;

function TSVGPath.New(Parent: TSVGObject): TSVGObject;
begin
  Result := TSVGPath.Create(Parent);
end;

procedure TSVGPath.PrepareMoveLineCurveArc(const ACommand: Char; SL: TStrings);
var
  C: Integer;
  D: Integer;
  Command: Char;
begin
  case ACommand of
    'M': Command := 'L';
    'm': Command := 'l';
  else
    Command := ACommand;
  end;

  case Command of
    'A', 'a':                     D := 7;
    'C', 'c':                     D := 6;
    'S', 's', 'Q', 'q':           D := 4;
    'T', 't', 'M', 'm', 'L', 'l': D := 2;
    'H', 'h', 'V', 'v':           D := 1;
  else
    D := 0;
  end;

  if (D = 0) or (SL.Count = D + 1) or ((SL.Count - 1) mod D = 1) then
    Exit;

  for C := SL.Count - D downto (D + 1) do
  begin
    if (C - 1) mod D = 0 then
      SL.Insert(C, Command);
  end;
end;

function TSVGPath.SeparateValues(const ACommand: Char;
  const S: string): TStrings;
var
  NumberStr: string;
  C: Char;
  HasDot: Boolean;
begin
  NumberStr := '';
  HasDot := False;

  Result := TStringList.Create;

  for C in S do
  begin
    case C of
      '.':
        begin
          if HasDot then
          begin
            HasDot := C = '.';
            Result.Add(NumberStr);
            NumberStr := C;
          end
          else
          begin
            NumberStr := NumberStr + C;
            HasDot := True;
          end;
        end;
      '0'..'9':
        begin
          NumberStr := NumberStr + C;
        end;
      '+', '-':
        begin
          if NumberStr <> '' then
          begin
            Result.Add(NumberStr);
            HasDot := False;
          end;
          NumberStr := C;
        end;
      ' ', #9, #$A, #$D:
        begin
          if NumberStr <> '' then
          begin
            Result.Add(NumberStr);
            NumberStr := '';
            HasDot := False;
          end;
        end;
    end;
  end;
  if NumberStr <> '' then
  begin
    Result.Add(NumberStr);
  end;

  Result.Insert(0, ACommand);

  if Result.Count > 0 then
  begin
    if ACommand.IsInArray(['M', 'm', 'L', 'l', 'H', 'h', 'V', 'v',
      'C', 'c', 'S', 's', 'Q', 'q', 'T', 't', 'A', 'a']) then
    begin
      PrepareMoveLineCurveArc(ACommand, Result);
    end
    else if (ACommand = 'Z') or (ACommand = 'z') then
    begin
      while Result.Count > 1 do
      begin
        Result.Delete(1);
      end;
    end;
  end;
end;

function TSVGPath.Split(const S: string): TStrings;
var
  Part: string;
  SL: TStrings;
  Found: Integer;
  StartIndex: Integer;
  SLength: Integer;
const
  IDs: array [0..19] of Char = ('M', 'm', 'L', 'l', 'H', 'h', 'V', 'v',
    'C', 'c', 'S', 's', 'Q', 'q', 'T', 't', 'A', 'a', 'Z', 'z');
begin
  Result := TStringList.Create;

  StartIndex := 0;
  SLength := Length(S);
  while StartIndex < SLength do
  begin
    Found := S.IndexOfAny(IDs, StartIndex + 1);
    if Found = -1 then
    begin
      Found := SLength;
    end;
    Part := S.Substring(StartIndex + 1, Found - StartIndex - 1).Trim;
    SL := SeparateValues(S[StartIndex + 1], Part);
    Result.AddStrings(SL);
    SL.Free;
    StartIndex := Found;
  end;
end;

procedure TSVGPath.ReadIn(const Node: IXMLNode);
var
  S: string;
  SL: TStrings;
  C: Integer;

  Element: TSVGPathElement;
  LastElement: TSVGPathElement;
begin
  inherited;

  LoadString(Node, 'd', S);
  S := StringReplace(S, ',', ' ', [rfReplaceAll]);
  SL := Split(S);

  try
    C := 0;
    LastElement := nil;

    if SL.Count > 0 then
      repeat
        case SL[C][1] of
          'M', 'm': Element := TSVGPathMove.Create(Self);

          'L', 'l': Element := TSVGPathLine.Create(Self);

          'H', 'h', 'V', 'v': Element := TSVGPathLine.Create(Self);

          'C', 'c': Element := TSVGPathCurve.Create(Self);

          'S', 's', 'Q', 'q': Element := TSVGPathCurve.Create(Self);

          'T', 't': Element := TSVGPathCurve.Create(Self);

          'A', 'a': Element := TSVGPathEllipticArc.Create(Self);

          'Z', 'z': Element := TSVGPathClose.Create(Self);

        else
          Element := nil;
        end;

        if Assigned(Element) then
        begin
          Element.Read(SL, C, LastElement);
          LastElement := Element;
        end;
        Inc(C);
      until C = SL.Count;
  finally
    SL.Free;
  end;

  ConstructPath;
end;
{$ENDREGION}

{$REGION 'TSVGImage'}
constructor TSVGImage.Create;
begin
  inherited;
  FImage := nil;
  FStream := nil;
end;

procedure TSVGImage.CalcObjectBounds;
var
  SW: TFloat;
begin
  SW := Max(0, GetStrokeWidth) / 2;
  FBounds.TopLeft := Transform(X - SW, Y - SW);
  FBounds.TopRight := Transform(X + Width + SW, Y - SW);
  FBounds.BottomRight := Transform(X + Width + SW, Y + Height + SW);
  FBounds.BottomLeft := Transform(X - SW, Y + Height - SW);
end;

procedure TSVGImage.Clear;
begin
  inherited;
  FreeAndNil(FImage);
  FreeAndNil(FStream);
  FFileName := '';
end;

procedure TSVGImage.AssignTo(Dest: TPersistent);
var
  SA: TStreamAdapter;
begin
  inherited;
  if Dest is TSVGImage then
  begin
    TSVGImage(Dest).FFileName := FFileName;
    if Assigned(FStream) then
    begin
      TSVGImage(Dest).FStream := TMemoryStream.Create;
      FStream.Position := 0;
      TSVGImage(Dest).FStream.LoadFromStream(FStream);
      TSVGImage(Dest).FStream.Position := 0;
      SA := TStreamAdapter.Create(TSVGImage(Dest).FStream, soReference);
      FImage := TGPImage.Create(SA);
    end
    else
    begin
      TSVGImage(Dest).FStream := TMemoryStream.Create;
      TSVGImage(Dest).FStream.LoadFromFile(FFileName);
      TSVGImage(Dest).FStream.Position := 0;
      SA := TStreamAdapter.Create(TSVGImage(Dest).FStream, soReference);
      FImage := TGPImage.Create(SA);
    end;
  end;
end;

function TSVGImage.New(Parent: TSVGObject): TSVGObject;
begin
  Result := TSVGImage.Create(Parent);
end;

procedure TSVGImage.PaintToGraphics(Graphics: TGPGraphics);
var
  //ClipPath: TGPGraphicsPath;
  TGP: TGPMatrix;
  ImAtt: TGPImageAttributes;
  ColorMatrix: TColorMatrix;

begin
  if FImage = nil then
    Exit;

  {ClipPath := GetClipPath;

  if ClipPath <> nil then
    Graphics.SetClip(ClipPath);}

  TGP := GetGPMatrix(Matrix);
  Graphics.SetTransform(TGP);
  TGP.Free;

  FillChar(ColorMatrix, Sizeof(ColorMatrix), 0);
  ColorMatrix[0, 0] := 1;
  ColorMatrix[1, 1] := 1;
  ColorMatrix[2, 2] := 1;
  ColorMatrix[3, 3] := GetFillOpacity;
  ColorMatrix[4, 4] := 1;

  ImAtt := TGPImageAttributes.Create;
  ImAtt.SetColorMatrix(colorMatrix, ColorMatrixFlagsDefault,
    ColorAdjustTypeDefault);

  Graphics.DrawImage(FImage, MakeRect(X, Y, Width, Height),
    0, 0, FImage.GetWidth, FImage.GetHeight, UnitPixel, ImAtt);

  ImAtt.Free;

  Graphics.ResetTransform;
  Graphics.ResetClip;

  //FreeAndNil(ClipPath);
end;

procedure TSVGImage.ReadIn(const Node: IXMLNode);
var
  S: string;
  SA: TStreamAdapter;

  function IsValid(var S: string): Boolean;
  var
    Semicolon: Integer;
  begin
    Result := False;
    if StartsStr('data:', S) then
    begin
      S := Copy(S, 6, MaxInt);
      Semicolon := Pos(';', S);
      if Semicolon = 0 then
        Exit;
      if Copy(S, Semicolon, 8) = ';base64,' then
      begin
        S := Copy(S, Semicolon + 8, MaxInt);
        Result := True;
      end;
    end;
  end;

var
  SS: TStringStream;
begin
  inherited;

  LoadString(Node, 'xlink:href', S);

  if IsValid(S) then
  begin
    SS := TStringStream.Create(S);
    try
      FStream := TMemoryStream.Create;
      TNetEncoding.Base64.Decode(SS, FStream);
      FStream.Position := 0;
      SA := TStreamAdapter.Create(FStream, soReference);
      FImage := TGPImage.Create(SA);
      FImage.GetLastStatus;
    finally
      SS.Free;
    end;
  end
  else
  begin
    FFileName := S;
    FStream := TMemoryStream.Create;
    FStream.LoadFromFile(FFileName);
    FStream.Position := 0;
    SA := TStreamAdapter.Create(FStream, soReference);
    FImage := TGPImage.Create(SA);
    FImage.GetLastStatus;
  end;
end;
{$ENDREGION}

{$REGION 'TSVGCustomText'}
constructor TSVGCustomText.Create;
begin
  inherited;
  FDX := 0;
  FDY := 0;
end;

procedure TSVGCustomText.BeforePaint(const Graphics: TGPGraphics;
  const Brush: TGPBrush; const Pen: TGPPen);
begin
  inherited;
  if Assigned(FUnderlinePath) then
  begin
    if Assigned(Brush) and (Brush.GetLastStatus = OK) then
    begin
      Graphics.FillPath(Brush, FUnderlinePath);
    end;

    if Assigned(Pen) and (Pen.GetLastStatus = OK) then
    begin
      Graphics.DrawPath(Pen, FUnderlinePath);
    end;
  end;
end;

procedure TSVGCustomText.CalcObjectBounds;
var
  SW: TFloat;
begin
  SW := Max(0, GetStrokeWidth) / 2;
  FBounds.TopLeft := Transform(X - SW, Y - FFontHeight - SW);
  FBounds.TopRight := Transform(X + Width + SW, Y - FFontHeight - SW);
  FBounds.BottomRight := Transform(X + Width + SW, Y - FFontHeight + Height + SW);
  FBounds.BottomLeft := Transform(X - SW, Y - FFontHeight + Height + SW);
end;

procedure TSVGCustomText.Clear;
begin
  inherited;
  FreeAndNil(FUnderlinePath);
  FreeAndNil(FStrikeOutPath);
  FText := '';
  FFontHeight := 0;
  FDX := 0;
  FDY := 0;
end;

function TSVGCustomText.GetCompleteWidth: TFloat;
var
  C: Integer;
begin
  Result := Width;
  for C := 0 to Count - 1 do
  begin
    if GetItem(C) is TSVGCustomText then
    begin
      Result := Result + TSVGCustomText(GetItem(C)).GetCompleteWidth;
    end;
  end;
end;

function TSVGCustomText.GetFont: TGPFont;
var
  FF: TGPFontFamily;
  FontStyle: TFontStyle;
  TD: TTextDecoration;
//  Font: HFont;

{  function CreateFont: HFont;
  var
    LogFont: TLogFont;
  begin
    with LogFont do
    begin
      lfHeight := Round(GetFont_Size);
      lfWidth := 0;
      lfEscapement := 0;
      lfOrientation := 0;
      lfWeight := GetFont_Weight;

      lfItalic := GetFont_Style;

      TD := GetText_Decoration;

      if tdUnderLine in TD then
        lfUnderline := 1
      else
        lfUnderline := 0;

      if tdStrikeOut in TD then
        lfStrikeOut := 1
      else
        lfStrikeOut := 0;

      lfCharSet := 1;
      lfOutPrecision := OUT_DEFAULT_PRECIS;
      lfClipPrecision := CLIP_DEFAULT_PRECIS;
      lfQuality := DEFAULT_QUALITY;
      lfPitchAndFamily := DEFAULT_PITCH;
      StrPCopy(lfFaceName, GetFont_Name);
    end;
    Result := CreateFontIndirect(LogFont);
  end;}

begin
  FF := GetFontFamily(GetFontName);

  FontStyle := FontStyleRegular;
  if GetFontWeight = FW_BOLD then
    FontStyle := FontStyle or FontStyleBold;

  if GetFontStyle = 1 then
    FontStyle := FontStyle or FontStyleItalic;

  TD := GetTextDecoration;

  if tdUnderLine in TD then
    FontStyle := FontStyle or FontStyleUnderline;

  if tdStrikeOut in TD then
    FontStyle := FontStyle or FontStyleStrikeout;

  FFontHeight := FF.GetCellAscent(FontStyle) / FF.GetEmHeight(FontStyle);
  FFontHeight := FFontHeight * GetFontSize;

  Result := TGPFont.Create(FF, GetFontSize, FontStyle, UnitPixel);
  FF.Free;
end;

function TSVGCustomText.GetFontFamily(const FontName: string): TGPFontFamily;
var
  FF: TGPFontFamily;
  C: Integer;
  FN: string;
begin
  FF := TGPFontFamily.Create(FontName);
  if FF.GetLastStatus <> OK then
  begin
    FreeAndNil(FF);

    C := Pos('-', FontName);
    if (C <> 0) then
    begin
      FN := Copy(FontName, 1, C - 1);
      FF := TGPFontFamily.Create(FN);
      if FF.GetLastStatus <> OK then
        FreeAndNil(FF);
    end;
  end;
  if not Assigned(FF) then
    FF := TGPFontFamily.Create('Arial');

  Result := FF;
end;

function TSVGCustomText.IsInTextPath: Boolean;
var
  Item: TSVGObject;
begin
  Result := True;
  Item := Self;
  while Assigned(Item) do
  begin
    if Item is TSVGTextPath then
      Exit;
    Item := Item.Parent;
  end;
  Result := False;
end;

procedure TSVGCustomText.SetSize;
var
  Graphics: TGPGraphics;
  SF: TGPStringFormat;
  Font: TGPFont;
  Rect: TGPRectF;
  Index: Integer;
  Previous: TSVGCustomText;
  DC: HDC;
begin
  DC := GetDC(0);
  Graphics := TGPGraphics.Create(DC);

  Font := GetFont;

  SF := TGPStringFormat.Create(StringFormatFlagsMeasureTrailingSpaces);

  Graphics.MeasureString(FText, -1, Font, MakePoint(0.0, 0), SF, Rect);

  Rect.Width := KerningText.MeasureText(FText, Font);

  SF.Free;

  Graphics.Free;
  ReleaseDC(0, DC);

  Font.Free;

  FWidth := 0;
  FHeight := 0;

  if Assigned(FParent) and (FParent is TSVGCustomText) then
  begin
    Index := FParent.IndexOf(Self);

    Previous := nil;
    if (Index > 0) and (FParent[Index - 1] is TSVGCustomText) then
      Previous := TSVGCustomText(FParent[Index - 1]);

    if (Index = 0) and (FParent is TSVGCustomText) then
      Previous := TSVGCustomText(FParent);

    if Assigned(Previous) then
    begin
      if not FHasX then
        FX := Previous.X + Previous.GetCompleteWidth;

      if not FHasY then
        FY := Previous.Y;
    end;
  end;

  FX := FX + FDX;
  FY := FY + FDY;

  FWidth := Rect.Width;
  FHeight := Rect.Height;
end;

procedure TSVGCustomText.AfterPaint(const Graphics: TGPGraphics;
  const Brush: TGPBrush; const Pen: TGPPen);
begin
  inherited;
  if Assigned(FStrikeOutPath) then
  begin
    if Assigned(Brush) and (Brush.GetLastStatus = OK) then
      Graphics.FillPath(Brush, FStrikeOutPath);

    if Assigned(Pen) and (Pen.GetLastStatus = OK) then
      Graphics.DrawPath(Pen, FStrikeOutPath);
  end;
end;

procedure TSVGCustomText.AssignTo(Dest: TPersistent);
begin
  inherited;
  if Dest is TSVGCustomText then
  begin
    TSVGCustomText(Dest).FText := FText;
    TSVGCustomText(Dest).FFontHeight := FFontHeight;
    TSVGCustomText(Dest).FDX := FDX;
    TSVGCustomText(Dest).FDY := FDY;
  end;
end;

function TSVGCustomText.New(Parent: TSVGObject): TSVGObject;
begin
  Result := TSVGCustomText.Create(Parent);
end;

procedure TSVGCustomText.ConstructPath;
var
  FF: TGPFontFamily;
  FontStyle: TFontStyle;
  SF: TGPStringFormat;
  TD: TTextDecoration;
begin
  inherited;
  FreeAndNil(FUnderlinePath);
  FreeAndNil(FStrikeOutPath);

  if IsInTextPath then
    Exit;

  if FText = '' then
    Exit;
  FPath := TGPGraphicsPath2.Create;

  FF := GetFontFamily(GetFontName);

  FontStyle := FontStyleRegular;
  if FFontWeight = FW_BOLD then
    FontStyle := FontStyle or FontStyleBold;

  if GetFontStyle = 1 then
    FontStyle := FontStyle or FontStyleItalic;

  TD := GetTextDecoration;

  if tdUnderLine in TD then
  begin
    FontStyle := FontStyle or FontStyleUnderline;
    FUnderlinePath := TGPGraphicsPath.Create;
  end;

  if tdStrikeOut in TD then
  begin
    FontStyle := FontStyle or FontStyleStrikeout;
    FStrikeOutPath := TGPGraphicsPath.Create;
  end;

  SF := TGPStringFormat.Create(TGPStringFormat.GenericTypographic);
  SF.SetFormatFlags(StringFormatFlagsMeasureTrailingSpaces);

  KerningText.AddToPath(FPath, FUnderlinePath, FStrikeOutPath,
    FText, FF, FontStyle, GetFontSize,
    MakePoint(X, Y - FFontHeight), SF);

  SF.Free;
  FF.Free;
end;

procedure TSVGCustomText.PaintToGraphics(Graphics: TGPGraphics);
{$IFDEF USE_TEXT}
var
  Font: TGPFont;
  SF: TGPStringFormat;
  Brush: TGPBrush;

  TGP: TGPMatrix;
  ClipRoot: TSVGBasic;
{$ENDIF}
begin
  if FText = '' then
    Exit;

{$IFDEF USE_TEXT}
  if FClipPath = nil then
    CalcClipPath;

  try
    if Assigned(FClipPath) then
    begin
      if ClipURI <> '' then
      begin
        ClipRoot := TSVGBasic(GetRoot.FindByID(ClipURI));
        if Assigned(ClipRoot) then
        begin
          TGP := GetGPMatrix(ClipRoot.Matrix);
          Graphics.SetTransform(TGP);
          TGP.Free;
        end;
      end;
      Graphics.SetClip(FClipPath);
      Graphics.ResetTransform;
    end;

    TGP := GetGPMatrix(Matrix);
    Graphics.SetTransform(TGP);
    TGP.Free;

    SF := TGPStringFormat.Create(TGPStringFormat.GenericTypographic);
    SF.SetFormatFlags(StringFormatFlagsMeasureTrailingSpaces);

    Brush := GetFillBrush;
    if Assigned(Brush) and (Brush.GetLastStatus = OK) then
    try
      Font := GetFont;
      try
        KerningText.AddToGraphics(Graphics, FText, Font, MakePoint(X, Y - FFontHeight), SF, Brush);
      finally
        Font.Free;
      end;
    finally
      Brush.Free;
    end;

    SF.Free;
  finally
    Graphics.ResetTransform;
    Graphics.ResetClip;
  end;
{$ELSE}
  inherited;
{$ENDIF}
end;

procedure TSVGCustomText.ParseNode(const Node: IXMLNode);
const
  TAB = #8;
var
  LText: TSVGText;
  TSpan: TSVGTSpan;
  TextPath: TSVGTextPath;
begin
  if Node.NodeName = '#text' then
  begin
    LText := TSVGTSpan.Create(Self);
    LText.Assign(Self);
    LText.FText := Node.Text;
    LText.SetSize;
    LText.ConstructPath;
  end
  else if Node.NodeName = 'text' then
  begin
    LText := TSVGTSpan.Create(Self);
    LText.Assign(Self);
    FillChar(LText.FPureMatrix, SizeOf(LText.FPureMatrix), 0);
    LText.ReadIn(Node);
  end
  else if Node.NodeName = 'tspan' then
  begin
    TSpan := TSVGTSpan.Create(Self);
    TSpan.Assign(Self);
    FillChar(TSpan.FPureMatrix, SizeOf(TSpan.FPureMatrix), 0);
    TSpan.ReadIn(Node);
  end
  else if Node.NodeName = 'textPath' then
  begin
    TextPath := TSVGTextPath.Create(Self);
    TextPath.Assign(Self);
    FillChar(TextPath.FPureMatrix, SizeOf(TextPath.FPureMatrix), 0);
    TextPath.ReadIn(Node);
  end;
end;

procedure TSVGCustomText.ReadIn(const Node: IXMLNode);
begin
  inherited;

  FHasX := Node.HasAttribute('x');
  FHasY := Node.HasAttribute('y');

  LoadLength(Node, 'dx', FDX);
  LoadLength(Node, 'dy', FDY);
end;


procedure TSVGCustomText.ReadTextNodes(const Node: IXMLNode);
var
  C: Integer;
begin
  if Node.nodeType = TNodeType.ntText then
  begin
    FText := Node.xml;
    SetSize;
    ConstructPath;
  end
  else if (Node.NodeType = TNodeType.ntElement) and (Node.NodeName = 'text')
  and (Node.ChildNodes.Count = 1) and (Node.ChildNodes[0].NodeType = TNodeType.ntText) then
  begin
    FText := Node.Text;
    SetSize;
    ConstructPath;
  end
  else
  begin
    ConstructPath;
    for C := 0 to Node.childNodes.count - 1 do
    begin
      ParseNode(Node.childNodes[C]);
    end;
  end;
end;
{$ENDREGION}

{$REGION 'TSVGClipPath'}
procedure TSVGClipPath.PaintToPath(Path: TGPGraphicsPath);
begin
end;

procedure TSVGClipPath.PaintToGraphics(Graphics: TGPGraphics);
begin
end;

procedure TSVGClipPath.Clear;
begin
  inherited;
  FreeAndNil(FClipPath);
end;

procedure TSVGClipPath.ConstructClipPath;

  procedure AddPath(SVG: TSVGBasic);
  var
    C: Integer;
  begin
    SVG.PaintToPath(FClipPath);

    for C := 0 to SVG.Count - 1 do
      AddPath(TSVGBasic(SVG[C]));
  end;

begin
  FClipPath := TGPGraphicsPath.Create;
  AddPath(Self);
end;

destructor TSVGClipPath.Destroy;
begin
  FreeAndNil(FClipPath);
  inherited;
end;

function TSVGClipPath.GetClipPath: TGPGraphicsPath;
begin
  if not Assigned(FClipPath) then
    ConstructClipPath;
  Result := FClipPath;
end;

function TSVGClipPath.New(Parent: TSVGObject): TSVGObject;
begin
  Result := TSVGClipPath.Create(Parent);
end;

procedure TSVGClipPath.ReadIn(const Node: IXMLNode);
begin
  inherited;
  ReadChildren(Node);
  Display := 0;
end;
{$ENDREGION}

{$REGION 'TSVGTextPath'}
procedure TSVGTextPath.Clear;
begin
  inherited;
  FOffset := 0;
  FPathRef := '';
  FMethod := tpmAlign;
  FSpacing := tpsAuto;
end;

procedure TSVGTextPath.ConstructPath;
var
  GuidePath: TSVGPath;
  Position: TFloat;
  Offset: TFloat;
  X, Y: TFloat;

  procedure RenderTextElement(const Element: TSVGCustomText);
  var
    C: Integer;
    FF: TGPFontFamily;
    FontStyle: TFontStyle;
    SF: TGPStringFormat;
    PT: TGPPathText;
    Matrix: TGPMatrix;
    Size: TFloat;
  begin
    FreeAndNil(Element.FUnderlinePath);
    FreeAndNil(Element.FStrikeOutPath);
    FreeAndNil(Element.FPath);
    if Element.FText <> '' then
    begin
      FF := GetFontFamily(Element.GetFontName);

      FontStyle := FontStyleRegular;
      if Element.FFontWeight = FW_BOLD then
        FontStyle := FontStyle or FontStyleBold;

      if Element.GetFontStyle = 1 then
        FontStyle := FontStyle or FontStyleItalic;

      SF := TGPStringFormat.Create(TGPStringFormat.GenericTypographic);
      SF.SetFormatFlags(StringFormatFlagsMeasureTrailingSpaces);

      PT := TGPPathText.Create(GuidePath.FPath);

      if Element.FPureMatrix.m33 = 1 then
        Matrix := GetGPMatrix(Element.FPureMatrix)
      else
        Matrix := nil;

      X := X + Element.FDX;
      Y := Y + Element.FDY;
      if (X <> 0) or (Y <> 0) then
      begin
        if not Assigned(Matrix) then
          Matrix := TGPMatrix.Create;
        Matrix.Translate(X, Y);
      end;

      PT.AdditionalMatrix := Matrix;
      Element.FPath := TGPGraphicsPath2.Create;

      Size := Element.GetFontSize;
      Position := Position +
        PT.AddPathText(Element.FPath, Trim(Element.FText), Offset + Position,
          FF, FontStyle, Size, SF);

      PT.Free;

      Matrix.Free;

      SF.Free;
      FF.Free;
    end;

    for C := 0 to Element.Count - 1 do
      if Element[C] is TSVGCustomText then
        RenderTextElement(TSVGCustomText(Element[C]));
  end;

begin
  inherited;

  GuidePath := nil;
  if FPathRef <> '' then
  begin
    if FPathRef[1] = '#' then
    begin
      GuidePath := TSVGPath(GetRoot.FindByID(Copy(FPathRef, 2, MaxInt)));
    end;
  end;

  if GuidePath = nil then
    Exit;

  Offset := 0;
  if FOffsetIsPercent and (FOffset <> 0) then
  begin
    Offset := TGPPathText.GetPathLength(GuidePath.FPath) / 100 * FOffset;
  end;

  X := FDX;
  Y := FDY;
  RenderTextElement(Self);
end;

procedure TSVGTextPath.ReadIn(const Node: IXMLNode);
var
  Value: string;
begin
  inherited;

  Value := Style.Values['startOffset'];
  if Value <> '' then
  begin
    FOffsetIsPercent := False;
    if RightStr(Value, 1) = '%' then
    begin
      FOffsetIsPercent := True;
      Value := LeftStr(Value, Length(Value) - 1);
    end;
    FOffset := ParseLength(Value);
  end;

  Value := Style.Values['method'];
  if Value = 'stretch' then
    FMethod := tpmStretch;

  Value := Style.Values['spacing'];
  if Value = 'exact' then
    FSpacing := tpsExact;

  LoadString(Node, 'xlink:href', FPathRef);

  ReadTextNodes(Node);
end;

procedure TSVGTextPath.ReadTextNodes(const Node: IXMLNode);
var
  C: Integer;
begin
  if Node.nodeType = TNodeType.ntText then
  begin
    FText := Node.xml;
    SetSize;
  end
  else
  begin
    for C := 0 to Node.childNodes.Count - 1 do
    begin
      ParseNode(Node.childNodes[C]);
    end;
  end;
  ConstructPath;
end;
{$ENDREGION}

{$REGION 'TSVGText'}
procedure TSVGText.ReadIn(const Node: IXMLNode);
begin
  inherited;

  ReadTextNodes(Node);
end;
{$ENDREGION}

{$REGION 'TSVGTSpan'}
procedure TSVGTSpan.ReadTextNodes(const Node: IXMLNode);
begin
  FText := Node.Text;
  SetSize;
  ConstructPath;

  // Again with only child
  if (Node.childNodes.count = 1) then
  begin
    ReadTextNodes(Node.childNodes[0]);
  end;
end;
{$ENDREGION}

procedure PatchINT3; 
var 
  NOP: Byte;
  NTDLL: THandle;
  BytesWritten: SIZE_T;
  Address: Pointer;
begin
  if Win32Platform <> VER_PLATFORM_WIN32_NT then
    Exit;
  NTDLL := GetModuleHandle('NTDLL.DLL');
  if NTDLL = 0 then
    Exit;
  Address := GetProcAddress(NTDLL, 'DbgBreakPoint');
  if Address = nil then
    Exit;
  try
    if Char(Address^) <> #$CC then
      Exit;

    NOP := $90;
    if WriteProcessMemory(GetCurrentProcess, Address, @NOP, 1, BytesWritten) and
       (BytesWritten = 1) then
      FlushInstructionCache(GetCurrentProcess, Address, 1);
  except
    //Do not panic if you see an EAccessViolation here, it is perfectly harmless!
    on EAccessViolation do ;
    else raise;
  end;
end;

initialization
  {$WARN SYMBOL_PLATFORM OFF}
// nur wenn ein Debugger vorhanden, den Patch ausf�hren
  if DebugHook <> 0 then
    PatchINT3;
  {$WARN SYMBOL_PLATFORM ON}
end.