unit MARS.Utils.Parameters.IniFile;

interface

uses
  SysUtils, Classes, IniFiles
  , MARS.Utils.Parameters;

type
  TMARSParametersIniFileReaderWriter=class
  private
  protected
    class function GetActualFileName(const AFileName: string): string;
  public
    class procedure Load(const AParameters: TMARSParameters; const AIniFileName: string = '');
    class procedure Save(const AParameters: TMARSParameters; const AIniFileName: string = '');
  end;

  TMARSParametersIniFileReaderWriterHelper=class helper for TMARSParameters
  public
    procedure LoadFromIniFile(const AIniFileName: string = '');
  end;

implementation

uses
  StrUtils
  , Rtti
  ;

function GuessTValueFromString(const AString: string): TValue;
var
  LValueInteger: Integer;
  LErrorCode: Integer;
  LValueDouble: Double;
  LValueBool: Boolean;
begin
  Val(AString, LValueInteger, LErrorCode);
  if LErrorCode = 0 then
    Result := LValueInteger
  else if TryStrToFloat(AString, LValueDouble) then
    Result := LValueDouble
  else if TryStrToBool(AString, LValueBool) then
    Result := LValueBool
  else
    Result := TValue.From<string>(AString);
end;

{ TMARSParametersIniFileReaderWriter }

class function TMARSParametersIniFileReaderWriter.GetActualFileName(
  const AFileName: string): string;
begin
  Result := AFileName;
  if Result = '' then
    Result := ChangeFileExt(ParamStr(0), '.ini');
end;

class procedure TMARSParametersIniFileReaderWriter.Load(
  const AParameters: TMARSParameters; const AIniFileName: string);
var
  LIniFile: TIniFile;
  LSections: TStringList;
  LSection: string;
  LValues: TStringList;
  LIndex: Integer;
  LParameterName: string;
  LName: string;
  LValue: string;
begin
  LIniFile := TIniFile.Create(GetActualFileName(AIniFileName));
  try
    LValues := TStringList.Create;
    try
      LIniFile.ReadSectionValues(AParameters.Name, LValues);

      for LIndex := 0 to LValues.Count-1 do
      begin
        LName := LValues.Names[LIndex];
        LValue := LValues.ValueFromIndex[LIndex];

        AParameters.Values[LName] := GuessTValueFromString(LValue);
      end;


      LSections := TStringList.Create;
      try
        LIniFile.ReadSections(LSections);
        for LSection in LSections do
        begin
          if SameText(LSection, AParameters.Name) then
            Continue; // skip

          LIniFile.ReadSectionValues(LSection, LValues);
          for LIndex := 0 to LValues.Count-1 do
          begin
            LName := LValues.Names[LIndex];
            LValue := LValues.ValueFromIndex[LIndex];

            LParameterName := TMARSParameters.CombineSliceAndParamName(LSection, LName);

            AParameters.Values[LParameterName] := TValue.From<string>(LValue);
          end;
        end;
      finally
        LSections.Free;
      end;
    finally
      LValues.Free;
    end;
  finally
    LIniFile.Free;
  end;
end;

class procedure TMARSParametersIniFileReaderWriter.Save(
  const AParameters: TMARSParameters; const AIniFileName: string);
var
  LName: string;
  LIniFile: TIniFile;
  LSlice: string;
  LParamName: string;
begin
  LIniFile := TIniFile.Create(GetActualFileName(AIniFileName));
  try
    for LName in AParameters.ParamNames do
    begin
      TMARSParameters.GetSliceAndParamName(LName, LSlice, LParamName);
      LIniFile.WriteString(LSlice, LParamName, AParameters[LName].AsString);
    end;
  finally
    LIniFile.Free;
  end;
end;

{ TMARSParametersIniFileReaderWriterHelper }

procedure TMARSParametersIniFileReaderWriterHelper.LoadFromIniFile(
  const AIniFileName: string);
begin
  TMARSParametersIniFileReaderWriter.Load(Self, AIniFileName);
end;

end.