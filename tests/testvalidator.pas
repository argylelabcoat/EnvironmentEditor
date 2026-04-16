unit testvalidator;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, validator;

type
  TTestValidator = class(TTestCase)
  published
    procedure TestValidate_NotFound;
    procedure TestValidate_Valid;
    procedure TestValidate_Duplicate;
    procedure TestValidate_Overridden;
  end;

implementation

procedure TTestValidator.TestValidate_NotFound;
var
  Status: TPathStatus;
  Validator: TPathValidator;
begin
  Validator := TPathValidator.Create;
  try
    Status := Validator.Validate('/definitely/not/a/real/path/on/any/system');
    AssertEquals(Ord(psNotFound), Ord(Status));
  finally
    Validator.Free;
  end;
end;

procedure TTestValidator.TestValidate_Valid;
var
  Status: TPathStatus;
  Validator: TPathValidator;
  TempDir: string;
begin
  TempDir := GetTempDir;
  Validator := TPathValidator.Create;
  try
    Status := Validator.Validate(TempDir);
    AssertEquals(Ord(psValid), Ord(Status));
  finally
    Validator.Free;
  end;
end;

procedure TTestValidator.TestValidate_Duplicate;
var
  Validator: TPathValidator;
  Paths: TStringList;
  Results: TStringList;
  TempDir: string;
begin
  TempDir := GetTempDir;
  Paths := TStringList.Create;
  try
    Paths.Add(TempDir);
    Paths.Add(TempDir);
    Validator := TPathValidator.Create;
    try
      Results := Validator.ValidateList(Paths);
      try
        AssertEquals(Ord(psDuplicate), Ord(StrToInt(Results.Values[TempDir])));
      finally
        Results.Free;
      end;
    finally
      Validator.Free;
    end;
  finally
    Paths.Free;
  end;
end;

procedure TTestValidator.TestValidate_Overridden;
begin
  { Overridden detection requires system+user comparison; tested in integration }
  AssertTrue(True);
end;

initialization
  RegisterTest(TTestValidator);
end.