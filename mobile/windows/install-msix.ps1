#Requires -Version 5.1
<#
  install-msix.ps1 — Installs the HOM Windows MSIX package.

  HOM is signed with a self-signed certificate (CN=Hexadigitall). Windows only
  accepts a self-signed signature if its certificate is present in the machine's
  Trusted Root store, so this script:

    1. Elevates to Administrator (MSIX sideloading + cert install require it).
    2. Installs hom-sign.cer into LocalMachine\Root and LocalMachine\TrustedPublisher.
    3. Registers hom_mobile.msix via Add-AppxPackage.

  Keep this script next to hom_mobile.msix and hom-sign.cer (they ship together
  in the HOM-Msix-Installer artifact). Then run:  .\install-msix.ps1

  NOTE: If you previously installed an older HOM build signed with a different
  key, uninstall it first (see the failure message at the end of the script).
#>
param(
  [string]$MsixPath = "",
  [string]$CertPath = ""
)

$ErrorActionPreference = 'Stop'
$dir = $PSScriptRoot
if (-not $MsixPath) { $MsixPath = Join-Path $dir 'hom_mobile.msix' }
if (-not $CertPath) { $CertPath = Join-Path $dir 'hom-sign.cer' }

# --- Self-elevate to Administrator ---
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Host "HOM installer needs Administrator rights. Restarting elevated..." -ForegroundColor Yellow
  $hostPath = (Get-Process -Id $PID).Path
  $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath))
  if ($MsixPath) { $argList += '-MsixPath'; $argList += ('"{0}"' -f $MsixPath) }
  if ($CertPath) { $argList += '-CertPath'; $argList += ('"{0}"' -f $CertPath) }
  Start-Process -FilePath $hostPath -Verb RunAs -ArgumentList $argList
  exit
}

Write-Host ""
Write-Host "=== HOM Windows Installer ===" -ForegroundColor Cyan
Write-Host "  MSIX : $MsixPath"
Write-Host "  Cert : $CertPath"
if (-not (Test-Path -LiteralPath $MsixPath)) { throw "MSIX not found: $MsixPath" }
if (-not (Test-Path -LiteralPath $CertPath)) { throw "Certificate not found: $CertPath" }

Write-Host ""
Write-Host "Installing HOM signing certificate into the Trusted Root + Trusted Publisher stores..." -ForegroundColor Cyan
Import-Certificate -FilePath $CertPath -CertStoreLocation Cert:\LocalMachine\Root | Out-Null
Import-Certificate -FilePath $CertPath -CertStoreLocation Cert:\LocalMachine\TrustedPublisher | Out-Null
$signer = (New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertPath)).Subject
Write-Host "  Installed signer: $signer"

Write-Host ""
Write-Host "Registering the app package (this can take a minute)..." -ForegroundColor Cyan
try {
  Add-AppxPackage -Path $MsixPath -ForceUpdateFromAnyVersion
} catch {
  Write-Warning "Add-AppxPackage failed: $($_.Exception.Message)"
  Write-Warning ""
  Write-Warning "If you previously installed an older HOM build signed with a different key,"
  Write-Warning "uninstall it first, then run this script again:"
  Write-Warning "    Get-AppxPackage -Name com.hexadigitall.hom | Remove-AppxPackage"
  Write-Warning "    .\install-msix.ps1"
  throw
}

Write-Host ""
Write-Host "Done. HOM 2.0.1 is installed — launch it from the Start menu." -ForegroundColor Green
