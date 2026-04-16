unit pathutils;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils;

type
  TPathUtils = class
  public
    class function SplitPath(const APathStr: string; const ADelim: string): TStringList;
    class function JoinPath(APaths: TStringList; const ADelim: string): string;
    class function FindDuplicates(APaths: TStringList): TStringList;
    class function NormalizePath(const APath: string): string;
  end;

implementation

class function TPathUtils.SplitPath(const APathStr: string; const ADelim: string): TStringList;
var
  Parts: TStringArray;
  I: Integer;
begin
  Result := TStringList.Create;
  Parts := APathStr.Split([ADelim]);
  for I := Low(Parts) to High(Parts) do
  begin
    if Trim(Parts[I]) <> '' then
      Result.Add(Trim(Parts[I]));
  end;
end;

class function TPathUtils.JoinPath(APaths: TStringList; const ADelim: string): string;
var
  I: Integer;
begin
  Result := '';
  if APaths = nil then
    Exit;
  for I := 0 to APaths.Count - 1 do
  begin
    if I > 0 then
      Result := Result + ADelim;
    Result := Result + APaths[I];
  end;
end;

class function TPathUtils.FindDuplicates(APaths: TStringList): TStringList;
var
  I: Integer;
  Seen: TStringList;
begin
  Result := TStringList.Create;
  Seen := TStringList.Create;
  try
    Seen.Sorted := True;
    Seen.Duplicates := dupIgnore;
    for I := 0 to APaths.Count - 1 do
    begin
      if Seen.IndexOf(APaths[I]) >= 0 then
      begin
        if Result.IndexOf(APaths[I]) < 0 then
          Result.Add(APaths[I]);
      end
      else
      begin
        Seen.Add(APaths[I]);
      end;
    end;
  finally
    Seen.Free;
  end;
end;

class function TPathUtils.NormalizePath(const APath: string): string;
begin
  Result := Trim(APath);
  if (Length(Result) > 1) and ((Result[Length(Result)] = '\') or (Result[Length(Result)] = '/')) then
    SetLength(Result, Length(Result) - 1);
end;

end.
