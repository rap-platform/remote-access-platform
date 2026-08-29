#ifndef MyAppVersion
  #define MyAppVersion "0.3.0"
#endif

#define MyAppName "Remote-Access-Platform"
#define MyAppPublisher "Remote-Desktop-Engineering"
#define MyAppExeName "rap-client.exe"
#define MyAppAgentExe "rap-agent.exe"
#define MyAppId "RemoteAccessPlatformApp"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
VersionInfoVersion={#MyAppVersion}
VersionInfoProductVersion={#MyAppVersion}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription=Remote Access Platform Enterprise Desktop Viewer & Host Agent
DefaultDirName={autopf32}\RemoteAccessPlatform\version-{#MyAppVersion}
DefaultGroupName={#MyAppName}
UninstallDisplayName={#MyAppName}

OutputDir=Output\version-{#MyAppVersion}
OutputBaseFilename=RemoteAccessPlatform-Setup-V{#MyAppVersion}

Compression=lzma
SolidCompression=yes
WizardStyle=modern

PrivilegesRequired=admin
AllowNoIcons=yes
DirExistsWarning=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create Desktop Icon"; Flags: unchecked
Name: "autostartagent"; Description: "Auto-start Host Agent Service on Windows startup"; Flags: unchecked

[Files]
Source: "..\..\..\deploy_windows\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\bin\{#MyAppExeName}"; WorkingDir: "{app}\bin"
Name: "{group}\Remote Access Agent Service"; Filename: "{app}\bin\{#MyAppAgentExe}"; WorkingDir: "{app}\bin"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\bin\{#MyAppExeName}"; WorkingDir: "{app}\bin"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "RemoteAccessHostAgent"; ValueData: """{app}\bin\{#MyAppAgentExe}"""; Flags: uninsdeletevalue; Tasks: autostartagent
