(*
  Copyright 2015, MARS - REST Library

  Home: https://github.com/MARS-library

*)
unit MARS.Core.Registry;

{$I MARS.inc}

interface

uses
  SysUtils, Classes
  , Generics.Collections
;

type
  TMARSConstructorInfo = class
  private
    FConstructorFunc: TFunc<TObject>;
    FTypeTClass: TClass;
  public
    constructor Create(AClass: TClass; const AConstructorFunc: TFunc<TObject>);

    property TypeTClass: TClass read FTypeTClass;
    property ConstructorFunc: TFunc<TObject> read FConstructorFunc write FConstructorFunc;
    function Clone: TMARSConstructorInfo;
  end;

  TMARSResourceRegistry = class(TObjectDictionary<string, TMARSConstructorInfo>)
  private
  protected
    class function GetInstance: TMARSResourceRegistry; static;
  public
    constructor Create; virtual;
    function RegisterResource<T: class>: TMARSConstructorInfo; overload;
    function RegisterResource<T: class>(const AConstructorFunc: TFunc<TObject>): TMARSConstructorInfo; overload;

    function GetResourceClass(const AResource: string; out Value: TClass): Boolean;
    function GetResourceInstance<T: class>: T;

    class property Instance: TMARSResourceRegistry read GetInstance;
  end;

{$ifdef DelphiXE}
type
  TObjectHelper = class helper for TObject
    class function QualifiedClassName: string;
  end;
{$endif}

implementation

{$ifdef DelphiXE}
class function TObjectHelper.QualifiedClassName: string;
var
  LScope: string;
begin
  LScope := UnitName;
  if LScope = '' then
    Result := ClassName
  else
    Result := LScope + '.' + ClassName;
end;
{$endif}

var
  _Instance: TMARSResourceRegistry = nil;


{ TMARSResourceRegistry }

function TMARSResourceRegistry.GetResourceInstance<T>: T;
var
  LInfo: TMARSConstructorInfo;
begin
  if Self.TryGetValue(T.ClassName, LInfo) then
  begin
    if LInfo.ConstructorFunc <> nil then
      Result := LInfo.ConstructorFunc() as T;
  end;
end;

function TMARSResourceRegistry.RegisterResource<T>: TMARSConstructorInfo;
begin
  Result := RegisterResource<T>(nil);
end;

function TMARSResourceRegistry.RegisterResource<T>(
  const AConstructorFunc: TFunc<TObject>): TMARSConstructorInfo;
begin
  Result := TMARSConstructorInfo.Create(TClass(T), AConstructorFunc);
  Self.Add(T.QualifiedClassName, Result);
end;

constructor TMARSResourceRegistry.Create;
begin
  inherited Create([doOwnsValues]);
end;

class function TMARSResourceRegistry.GetInstance: TMARSResourceRegistry;
begin
  if not Assigned(_Instance) then
    _Instance := TMARSResourceRegistry.Create;
  Result := _Instance;
end;

function TMARSResourceRegistry.GetResourceClass(const AResource: string;
  out Value: TClass): Boolean;
var
  LInfo: TMARSConstructorInfo;
begin
  Value := nil;
  Result := Self.TryGetValue(AResource, LInfo);
  if Result then
    Value := LInfo.TypeTClass;
end;

{ TMARSConstructorInfo }

function TMARSConstructorInfo.Clone: TMARSConstructorInfo;
begin
  Result := TMARSConstructorInfo.Create(FTypeTClass, FConstructorFunc);
end;

constructor TMARSConstructorInfo.Create(AClass: TClass;
  const AConstructorFunc: TFunc<TObject>);
begin
  inherited Create;
  FConstructorFunc := AConstructorFunc;
  FTypeTClass := AClass;

  // provide a default constructor function
  if not Assigned(FConstructorFunc) then
    FConstructorFunc :=
      function: TObject
      begin
        Result := FTypeTClass.Create as TObject;
      end;
end;

initialization

finalization
  if Assigned(_Instance) then
    FreeAndNil(_Instance);


end.