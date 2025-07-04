Param(
    [string]$Choice,
    [string]$Location
)

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script must be run with administrator privileges. Please run the script as an administrator."
    Start-Sleep -Seconds 5
    Exit
}

if ([string]::IsNullOrWhiteSpace($Choice)) {
    while ($true) {
        $Choice = Read-Host "Enter 'RovoDev' to manage 'Run with RovoDev' or 'Gemini' to manage 'Run with Gemini'"
        if ($Choice -eq 'RovoDev' -or $Choice -eq 'Gemini') {
            break
        } else {
            Write-Warning "Invalid choice. Please enter 'RovoDev' or 'Gemini'."
        }
    }
}

if ([string]::IsNullOrWhiteSpace($Location)) {
    while ($true) {
        $Location = Read-Host "Enter 'Folder' to add to folder context menu or 'Background' to add to folder background context menu"
        if ($Location -eq 'Folder' -or $Location -eq 'Background') {
            break
        } else {
            Write-Warning "Invalid choice. Please enter 'Folder' or 'Background'."
        }
    }
}

$regPathRoot = "Registry::HKEY_CLASSES_ROOT\Directory"

if ($Location -eq 'Background') {
    $regPathRoot = "${regPathRoot}\Background\shell"
} else {
    $regPathRoot = "${regPathRoot}\shell"
}

$pwshPath = (Get-Command "pwsh.exe" -ErrorAction SilentlyContinue)?.Source
$executor = if ($pwshPath) { "pwsh.exe" } else { "powershell.exe" }

$regPathSuffix = ""
$menuName = ""
$commandToExecute = ""

switch ($Choice) {
    "RovoDev" {
        $regPathSuffix = "Run with RovoDev"
        $menuName = "Run with RovoDev"
        $acliPath = Join-Path $PSScriptRoot "acli.exe"
        if (-not (Test-Path $acliPath)) {
            $acliPath = Read-Host "Enter the full path to acli.exe (e.g., C:\Program Files\RovoDev\acli.exe)"
        }
        $commandToExecute = "$executor -NoExit -Command `"Set-Location -LiteralPath '%1'; & '$acliPath' rovodev run`""
    }
    "Gemini" {
        $regPathSuffix = "Run with Gemini"
        $menuName = "Run with Gemini"
        $commandToExecute = "$executor -NoExit -Command `"Set-Location -LiteralPath '%1'; gemini`""
    }
    default {
        Write-Error "Invalid choice. Exiting."
        Exit
    }
}

$regPath = "${regPathRoot}\$regPathSuffix"

if (Test-Path $regPath) {
    Write-Host "Menu entry '$menuName' found. Removing..." -ForegroundColor Yellow
    Remove-Item -Path $regPath -Recurse
    Write-Host "Removed '$menuName'." -ForegroundColor Green
} else {
    Write-Host "Menu entry '$menuName' not found. Adding..." -ForegroundColor Cyan

    New-Item -Path $regPath -Force | Out-Null
    Set-ItemProperty -Path $regPath -Name "(Default)" -Value $menuName
    Set-ItemProperty -Path $regPath -Name "Icon" -Value $executor

    $commandPath = Join-Path $regPath "command"
    New-Item -Path $commandPath -Force | Out-Null
    Set-ItemProperty -Path $commandPath -Name "(Default)" -Value $commandToExecute

    Write-Host "Added '$menuName'. Using PowerShell: $executor" -ForegroundColor Green
}
