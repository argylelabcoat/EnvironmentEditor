unit testpathutils;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, pathutils;

type
  TTestPathUtils = class(TTestCase)
  published
    procedure TestSplitPath_Windows;
    procedure TestSplitPath_Unix;
    procedure TestJoinPath_Windows;
    procedure TestJoinPath_Unix;
    procedure TestFindDuplicates;
    procedure TestNormalizePath;
  end;

implementation

procedure TTestPathUtils.TestSplitPath_Windows;
var
  Actual: TStringList;
begin
  Actual := TPathUtils.SplitPath('C:\Windows;C:\Users', ';');
  try
    AssertEquals(2, Actual.Count);
    AssertEquals('C:\Windows', Actual[0]);
    AssertEquals('C:\Users', Actual[1]);
  finally
    Actual.Free;
  end;
end;

procedure TTestPathUtils.TestSplitPath_Unix;
var
  Actual: TStringList;
begin
  Actual := TPathUtils.SplitPath('/usr/bin:/usr/local/bin', ':');
  try
    AssertEquals(2, Actual.Count);
    AssertEquals('/usr/bin', Actual[0]);
    AssertEquals('/usr/local/bin', Actual[1]);
  finally
    Actual.Free;
  end;
end;

procedure TTestPathUtils.TestJoinPath_Windows;
var
  List: TStringList;
begin
  List := TStringList.Create;
  try
    List.Add('C:\Windows');
    List.Add('C:\Users');
    AssertEquals('C:\Windows;C:\Users', TPathUtils.JoinPath(List, ';'));
  finally
    List.Free;
  end;
end;

procedure TTestPathUtils.TestJoinPath_Unix;
var
  List: TStringList;
begin
  List := TStringList.Create;
  try
    List.Add('/usr/bin');
    List.Add('/usr/local/bin');
    AssertEquals('/usr/bin:/usr/local/bin', TPathUtils.JoinPath(List, ':'));
  finally
    List.Free;
  end;
end;

procedure TTestPathUtils.TestFindDuplicates;
var
  Paths: TStringList;
  Dups: TStringList;
begin
  Paths := TStringList.Create;
  try
    Paths.Add('C:\Windows');
    Paths.Add('C:\Users');
    Paths.Add('C:\Windows');
    Dups := TPathUtils.FindDuplicates(Paths);
    try
      AssertEquals(1, Dups.Count);
      AssertEquals('C:\Windows', Dups[0]);
    finally
      Dups.Free;
    end;
  finally
    Paths.Free;
  end;
end;

procedure TTestPathUtils.TestNormalizePath;
begin
  AssertEquals('C:\Windows\System32',
    TPathUtils.NormalizePath('C:\Windows\System32\'));
  AssertEquals('/usr/local/bin',
    TPathUtils.NormalizePath('/usr/local/bin/'));
end;

initialization
  RegisterTest(TTestPathUtils);
end.