unit validator;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils;

type
  TPathStatus = (psValid, psNotFound, psDuplicate, psOverridden);

  TPathValidator = class
  public
    function Validate(const APath: string): TPathStatus;
    function ValidateList(APaths: TStringList): TStringList;
  end;

implementation

function TPathValidator.Validate(const APath: string): TPathStatus;
begin
  if DirectoryExists(APath) or FileExists(APath) then
    Result := psValid
  else
    Result := psNotFound;
end;

function TPathValidator.ValidateList(APaths: TStringList): TStringList;
var
  I: Integer;
  Seen: TStringList;
  Path: string;
  Status: TPathStatus;
begin
  Result := TStringList.Create;
  Seen := TStringList.Create;
  try
    Seen.Sorted := True;
    for I := 0 to APaths.Count - 1 do
    begin
      Path := APaths[I];
      Status := Validate(Path);
      if (Status = psValid) and (Seen.IndexOf(Path) >= 0) then
        Status := psDuplicate;
      if Seen.IndexOf(Path) < 0 then
        Seen.Add(Path);
      Result.Values[Path] := IntToStr(Ord(Status));
    end;
  finally
    Seen.Free;
  end;
end;

end.