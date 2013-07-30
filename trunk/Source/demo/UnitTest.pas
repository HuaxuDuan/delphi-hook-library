unit UnitTest;

interface

uses
  Windows, Messages, SysUtils, Variants, ShlObj,
  Graphics, ComObj, ActiveX,
  Controls, Forms, Dialogs, StdCtrls, Classes;

type

  TForm4 = class(TForm)
    Label1: TLabel;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure CheckBox1Click(Sender: TObject);
    procedure CheckBox2Click(Sender: TObject);
    procedure CheckBox3Click(Sender: TObject);
  private
    FShellLink: IShellLink;
  public

  end;

var
  Form4: TForm4;

implementation

{$R *.dfm}

uses
  HookUtils;

var
  old_DrawTextEx: function(DC: HDC; lpchText: LPCTSTR; cchText: Integer;
    var p4: TRect; dwDTFormat: UINT; DTParams: PDrawTextParams)
    : Integer; stdcall;

function _DrawTextEx(DC: HDC; lpchText: LPCTSTR; cchText: Integer;
  var p4: TRect; dwDTFormat: UINT; DTParams: PDrawTextParams): Integer; stdcall;
var
  s: string;
begin
  if copy(lpchText, 1, 5) = 'Label' then
    s := '�Ұ�Label��ͷ�����ָĳ����ڵ�������,�����!'
  else
    s := lpchText;

  Result := old_DrawTextEx(DC, PChar(s), Length(s), p4, dwDTFormat, DTParams);
end;

var // ���IShellLink.Setpath����
  Old_SetPath: function(Self: IShellLink; pszFile: LPTSTR): HResult; stdcall;

  // Hook��IShellLink.SetPath����
function _SetPath(Self: IShellLink; pszFile: LPTSTR): HResult; stdcall;
begin
  ShowMessage(Format('����õ�ISHellLink($%x)��SetPath������,����"%s"',
    [NativeInt(Pointer(Self)), string(pszFile)]));
  Result := Old_SetPath(Self, 'd:\Windows');
end;

var // ���IShellLink.Setpath����
  Old_FreeInstance: procedure(Self: TObject);

  // Hook��IShellLink.SetPath����
procedure _FreeInstance(Self: TObject);
begin
  if Self <> nil then
    OutputDebugString(PChar(Format('"%s"ʵ��[%x]���ͷ�!', [Self.ClassName,
      NativeInt(Self)])));
  Old_FreeInstance(Self);
end;

procedure TForm4.CheckBox1Click(Sender: TObject);
const
{$IFDEF UNICODE}
  DrawTextExRealName = 'DrawTextExW';
{$ELSE}
  DrawTextExRealName = 'DrawTextExA';
{$ENDIF}
begin

  if CheckBox1.Checked then
  begin
    // ����API����,DrawtextEx,��Ϊ����Unicode�汾Delphi
    if not Assigned(old_DrawTextEx) then
    begin
      @old_DrawTextEx := HookProc(user32, DrawTextExRealName, @_DrawTextEx);
      // �ػ�,�����������־ͻ������.
    end
    else
    begin
      ShowMessage('������,����Ҫ�ظ�����!');
    end;
  end
  else
  begin
    if Assigned(old_DrawTextEx) then
      UnHook(@old_DrawTextEx);
    @old_DrawTextEx := nil;
  end;
  // ˢ�½���,��Form�ػ�Label
  Invalidate();
end;

procedure TForm4.CheckBox2Click(Sender: TObject);
begin
  if CheckBox2.Checked then
  begin
    if not Assigned(Old_SetPath) then
    begin
      @Old_SetPath := HookInterface(FShellLink, 20, @_SetPath);
      FShellLink.SetPath('c:\Windows');
    end
    else
    begin
      ShowMessage('������,����Ҫ�ظ�����!');
    end;
  end
  else
  begin
    if Assigned(Old_SetPath) then
      UnHook(@Old_SetPath);
    @Old_SetPath := nil;
  end;
end;

procedure TForm4.CheckBox3Click(Sender: TObject);
begin
  if CheckBox3.Checked then
  begin
    if not Assigned(Old_FreeInstance) then
    begin
      @Old_FreeInstance := HookProc(@TObject.FreeInstance, @_FreeInstance);
      ShowMessage('�����EventLog�����￴������Щ�����ͷ��� :-)');
    end
    else
    begin
      ShowMessage('������,����Ҫ�ظ�����!');
    end;
  end
  else
  begin
    if Assigned(Old_FreeInstance) then
      UnHook(@Old_FreeInstance);
    @Old_FreeInstance := nil;
  end;
end;

procedure TForm4.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(Old_SetPath) then
    UnHook(@Old_SetPath);
  if Assigned(old_DrawTextEx) then
    UnHook(@old_DrawTextEx);
  if Assigned(Old_FreeInstance) then
    UnHook(@Old_FreeInstance);
end;

procedure TForm4.FormCreate(Sender: TObject);
begin
  FShellLink := CreateComObject(CLSID_ShellLink) as IShellLink;
end;

end.
