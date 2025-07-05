Param(
    [string]$Action,
    [string]$Choice,
    [string]$Location
)

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script must be run with administrator privileges. Please run the script as an administrator."
    Start-Sleep -Seconds 5
    Exit
}

function Show-Menu {
    param (
        [string]$Title,
        [System.Collections.ArrayList]$Options
    )

    Clear-Host
    Write-Host "--- $Title ---" -ForegroundColor Cyan
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "$($i + 1). $($Options[$i])"
    }
    Write-Host "------------------"

    $selection = Read-Host "Enter your choice (number)"
    return $selection
}

# --- Get Action --- #
if ([string]::IsNullOrWhiteSpace($Action)) {
    $actionOptions = [System.Collections.ArrayList]@("Install", "Uninstall")
    $actionSelection = Show-Menu -Title "Choose Action" -Options $actionOptions
    
    while ($true) {
        if ($actionSelection -ge 1 -and $actionSelection -le $actionOptions.Count) {
            $Action = $actionOptions[$actionSelection - 1]
            break
        } else {
            Write-Warning "Invalid choice. Please enter a number from the menu."
            $actionSelection = Read-Host "Enter your choice (number)"
        }
    }
}

# --- Get Choice (RovoDev/Gemini/Claude) --- #
if ([string]::IsNullOrWhiteSpace($Choice)) {
    $choiceOptions = [System.Collections.ArrayList]@("RovoDev", "Gemini", "Claude")
    $choiceSelection = Show-Menu -Title "Choose Command" -Options $choiceOptions
    
    while ($true) {
        if ($choiceSelection -ge 1 -and $choiceSelection -le $choiceOptions.Count) {
            $Choice = $choiceOptions[$choiceSelection - 1]
            break
        } else {
            Write-Warning "Invalid choice. Please enter a number from the menu."
            $choiceSelection = Read-Host "Enter your choice (number)"
        }
    }
}

# --- Get Location (Folder/Background) --- #
if ([string]::IsNullOrWhiteSpace($Location)) {
    $locationOptions = [System.Collections.ArrayList]@("Folder", "Background")
    $locationSelection = Show-Menu -Title "Choose Context Menu Location" -Options $locationOptions

    while ($true) {
        if ($locationSelection -ge 1 -and $locationSelection -le $locationOptions.Count) {
            $Location = $locationOptions[$locationSelection - 1]
            break
        } else {
            Write-Warning "Invalid choice. Please enter a number from the menu."
            $locationSelection = Read-Host "Enter your choice (number)"
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
        if ($Action -eq "Install") {
            $acliPath = Join-Path $PSScriptRoot "acli.exe"
            if (-not (Test-Path $acliPath)) {
                $acliPath = Read-Host "Enter the full path to acli.exe (e.g., C:\Program Files\RovoDev\acli.exe)"
            }
        }
        if ($Location -eq 'Background') {
            $commandToExecute = "$executor -NoExit -Command `"Set-Location -LiteralPath '%V'; & '$acliPath' rovodev run`""
        } else {
            $commandToExecute = "$executor -NoExit -Command `"Set-Location -LiteralPath '%1'; & '$acliPath' rovodev run`""
        }
    }
    "Gemini" {
        $regPathSuffix = "Run with Gemini"
        $menuName = "Run with Gemini"
        if ($Location -eq 'Background') {
            $commandToExecute = "$executor -NoExit -Command `"Set-Location -LiteralPath '%V'; gemini`""
        } else {
            $commandToExecute = "$executor -NoExit -Command `"Set-Location -LiteralPath '%1'; gemini`""
        }
    }
    "Claude" {
        $regPathSuffix = "Run with Claude"
        $menuName = "Run with Claude"
        # Convert Windows path to WSL path and run claude command
        if ($Location -eq 'Background') {
            $commandToExecute = "$executor -NoExit -Command `"Set-Location -LiteralPath '%V'; `$wslPath = (wsl wslpath -a '%V'); wsl -e bash -c \`"cd \`"`$wslPath\`" && claude\`"`""
        } else {
            $commandToExecute = "$executor -NoExit -Command `"Set-Location -LiteralPath '%1'; `$wslPath = (wsl wslpath -a '%1'); wsl -e bash -c \`"cd \`"`$wslPath\`" && claude\`"`""
        }
    }
    default {
        Write-Error "Invalid choice. Exiting."
        Exit
    }
}

$regPath = "${regPathRoot}\$regPathSuffix"

if ($Action -eq "Uninstall") {
    if (Test-Path $regPath) {
        Write-Host "Menu entry '$menuName' found. Removing..." -ForegroundColor Yellow
        Remove-Item -Path $regPath -Recurse
        Write-Host "Removed '$menuName'." -ForegroundColor Green
    } else {
        Write-Host "Menu entry '$menuName' not found. Nothing to remove." -ForegroundColor Green
    }
} else { # Action is Install
    if (Test-Path $regPath) {
        Write-Host "Menu entry '$menuName' already exists. Skipping installation." -ForegroundColor Yellow
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
}
