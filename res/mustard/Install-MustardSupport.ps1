[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [uri]$MsiUri,
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-fA-F0-9]{64}$')]
    [string]$Sha256
)

$ErrorActionPreference = 'Stop'
if ($MsiUri.Scheme -ne 'https') {
    throw 'The MSI download URL must use HTTPS.'
}
$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this script as System or an administrator.'
}

$downloadDirectory = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
$logDirectory = Join-Path $env:ProgramData 'Mustard\Logs'
New-Item -ItemType Directory -Path $downloadDirectory, $logDirectory -Force | Out-Null
$package = Join-Path $downloadDirectory 'MustardSupport.msi'
$log = Join-Path $logDirectory 'MustardSupport-install.log'

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $MsiUri -OutFile $package -UseBasicParsing
    if ((Get-FileHash -Path $package -Algorithm SHA256).Hash -ne $Sha256) {
        throw 'The MSI checksum does not match the selected Mustard Support release.'
    }
    $process = Start-Process -FilePath "$env:WINDIR\System32\msiexec.exe" `
        -ArgumentList "/i `"$package`" /qn /norestart /L*v `"$log`"" `
        -Wait -PassThru
    if ($process.ExitCode -notin @(0, 3010)) {
        throw "Mustard Support installation failed with code $($process.ExitCode). Log: $log"
    }
    Write-Output "Mustard Support installed. MSI exit code: $($process.ExitCode). Log: $log"
} finally {
    Remove-Item -Path $downloadDirectory -Recurse -Force
}
