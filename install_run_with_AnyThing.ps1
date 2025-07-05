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

function Show-WelcomeScreen {
    Clear-Host
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "|                                                                             |" -ForegroundColor Cyan
    Write-Host "|                   >>> RUN WITH ANYTHING INSTALLER <<<                      |" -ForegroundColor Yellow
    Write-Host "|                                                                             |" -ForegroundColor Cyan
    Write-Host "|            Add powerful context menu entries to Windows Explorer!          |" -ForegroundColor White
    Write-Host "|                                                                             |" -ForegroundColor Cyan
    Write-Host "| This tool helps you integrate RovoDev, Gemini, and Claude commands into    |" -ForegroundColor Gray
    Write-Host "| your Windows right-click context menu for quick access from any folder.    |" -ForegroundColor Gray
    Write-Host "|                                                                             |" -ForegroundColor Cyan
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Green
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-Menu {
    param (
        [string]$Title,
        [System.Collections.ArrayList]$Options
    )

    Clear-Host
    $width = 75
    $titlePadding = [Math]::Max(0, ($width - $Title.Length - 4) / 2)
    $titleLine = "|" + (" " * $titlePadding) + ">> $Title" + (" " * ($width - $titlePadding - $Title.Length - 5)) + "|"
    
    Write-Host "===========================================================================" -ForegroundColor Cyan
    Write-Host $titleLine -ForegroundColor Yellow
    Write-Host "===========================================================================" -ForegroundColor Cyan
    Write-Host "|                                                                         |" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $Options.Count; $i++) {
        $optionNumber = $i + 1
        $optionText = $Options[$i]
        $emoji = switch ($optionText) {
            "Install" { "[+]" }
            "Uninstall" { "[-]" }
            "RovoDev" { "[R]" }
            "Gemini" { "[G]" }
            "Claude" { "[C]" }
            "Folder" { "[F]" }
            "Background" { "[B]" }
            default { "[>]" }
        }
        $optionLine = "|  $optionNumber. $emoji $optionText"
        $padding = $width - $optionLine.Length + 1
        Write-Host ($optionLine + (" " * $padding) + "|") -ForegroundColor White
    }
    
    Write-Host "|                                                                         |" -ForegroundColor Cyan
    Write-Host "===========================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host ">> " -NoNewline -ForegroundColor Yellow
    $selection = Read-Host "Enter your choice (number)"
    return $selection
}

# Show welcome screen if running interactively
if ([string]::IsNullOrWhiteSpace($Action) -and [string]::IsNullOrWhiteSpace($Choice) -and [string]::IsNullOrWhiteSpace($Location)) {
    Show-WelcomeScreen
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

$pwshPath = Get-Command "pwsh.exe" -ErrorAction SilentlyContinue
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
        # Get claude path from user during installation
        if ($Action -eq "Install") {
            Write-Host "To find your claude command path, run this in WSL:" -ForegroundColor Yellow
            Write-Host "  which claude" -ForegroundColor Cyan
            Write-Host ""
            $claudePath = Read-Host "Enter the full path to claude command in WSL (e.g., /home/username/.nvm/versions/node/v22.17.0/bin/claude)"
            while ([string]::IsNullOrWhiteSpace($claudePath)) {
                Write-Warning "Claude path cannot be empty. Please enter the full path."
                $claudePath = Read-Host "Enter the full path to claude command in WSL"
            }
        }
        # Convert Windows path to WSL path and run claude command with user-provided path
        if ($Location -eq 'Background') {
            $commandToExecute = "$executor -NoExit -Command `"Set-Location -LiteralPath '%V'; wsl --cd '%V' '$claudePath'`""
        } else {
            $commandToExecute = "$executor -NoExit -Command `"Set-Location -LiteralPath '%1'; wsl --cd '%1' '$claudePath'`""
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
        Write-Host ""
        Write-Host "*** UNINSTALLED! ***" -ForegroundColor Red
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
        Write-Host "[-] Successfully removed '$menuName' from your context menu!" -ForegroundColor Green
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
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

        Write-Host ""
        Write-Host "*** SUCCESS! ***" -ForegroundColor Green
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
        Write-Host "[+] Added '$menuName' to your Windows context menu!" -ForegroundColor Green
        Write-Host "[*] Using PowerShell: $executor" -ForegroundColor Cyan
        Write-Host ""
        Write-Host ">> How to use:" -ForegroundColor Yellow
        Write-Host "   * Right-click on any folder in Windows Explorer" -ForegroundColor White
        Write-Host "   * Select '$menuName' from the context menu" -ForegroundColor White
        Write-Host "   * Enjoy your new productivity boost!" -ForegroundColor White
        Write-Host ""
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    }
}
