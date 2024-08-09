(@(& 'C:/Users/hclar/AppData/Local/Programs/oh-my-posh/bin/oh-my-posh.exe' init pwsh --config='C:\Users\hclar\AppData\Local\Programs\oh-my-posh\themes\pure.omp.json' --print) -join "`n") | Invoke-Expression
Import-Module Terminal-Icons
Set-PSReadLineOption -PredictionViewStyle ListView

# Define Var
$PROJECTS = "D:\Projects"

# Custom Aliases
Set-Alias ll Get-ChildItem
Set-Alias cls Clear-Host
Set-Alias grep Select-String
Set-Alias wget Invoke-WebRequest
Set-Alias curl Invoke-RestMethod

# Location
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function ~ { Set-Location ~ }
function Get-AllItems { Get-ChildItem -Force }
Set-Alias la Get-AllItems

# Git Aliases
function gaa { git add -A }
function gc { & "$env:DOTLY_PATH/bin/dot" git commit }
function gca { git add --all; git commit --amend --no-edit }
function gco { git checkout }
function gd { & "$env:DOTLY_PATH/bin/dot" git pretty-diff }
function gs { git status -sb }
function gf { git fetch --all -p }
function gps { git push }
function gpsf { git push --force }
function gpl { git pull }
function gpll { git pull --rebase --autostash }
function gb { git branch }
function gl { & "$env:DOTLY_PATH/bin/dot" git pretty-log }

# Utils
function c. { Start-Process code $PWD }
function ws. { Start-Process webstorm.bat $PWD }
function phs. { Start-Process phpstorm.bat $PWD }
function r. { Start-Process rider.bat $PWD }
function open { param ([string]$path = "."); Start-Process explorer.exe -ArgumentList (Resolve-Path $path) }
function o. { open }
function k { param ([int]$pid); Stop-Process -Id $pid -Force }
function reload! { . $PROFILE; Write-Output "PowerShell profile reloaded" }

# own documents code
function cdp { Set-Location "$PROJECTS" }
function cdc { cdp; Set-Location "code" }
function cdw { cdp; Set-Location "work" }
function cdt2 { cdw; Set-Location "trip2-cms" }
function cdtas { cdw; Set-Location "ta-lsf-scheduler" }
function cdrh { cdw; Set-Location "soft-g-net/rh" }
function cdinv { cdw; Set-Location "soft-g-net/inventario" }
function cdjb { cdw; Set-Location "ta-jobs" }
function cdinc { cdw; Set-Location "ta-incident" }
function dotfiles { cdc; Set-Location .dotfiles-mac }

# own nvm
function nad { nvm alias default }
function nl { nvm list }
# Function to read .nvmrc and use the specified Node.js version
function nu {
    $nvmrcPath = ".\.nvmrc"

    if (-not (Test-Path $nvmrcPath)) {
        Write-Error ".nvmrc file not found in the current directory."
        return
    }

    $nodeVersion = Get-Content $nvmrcPath -Raw
    $nodeVersion = $nodeVersion.Trim()

    if (-not (Get-Command nvm -ErrorAction SilentlyContinue)) {
        Write-Error "NVM is not installed. Please install NVM for Windows."
        return
    }

    # Check if the specified Node version is installed
    $installedVersions = nvm list | Select-String -Pattern $nodeVersion
    if ($installedVersions.Count -eq 0) {
        Write-Output "Node version $nodeVersion is not installed. Installing..."
        nvm install $nodeVersion

        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to install Node version $nodeVersion"
            return
        }
    }

    # Use the specified Node version
    nvm use $nodeVersion

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to switch to Node version $nodeVersion"
        return
    }

    $nodeVersionUsed = node -v
    Write-Output "Using Node version $nodeVersionUsed"
}

# Function to list all custom aliases
function help_aliases {
    Get-Alias | Where-Object {
        $_.Definition -match "^[A-Za-z]+(-[A-Za-z]+)*$" -and
        ($_.Definition -notmatch "Get-Alias|Set-Alias|Remove-Alias|List-CustomAliases")
    } | Format-Table -AutoSize
}

function save-profile {
    Copy-Item -Path $PROFILE -Destination 'D:\Projects\code\.dotfiles-mac\tools\power-shell\Microsoft.PowerShell_profile.ps1'
}

function start-profile {
    Copy-Item -Path 'D:\Projects\code\.dotfiles-mac\tools\power-shell\Microsoft.PowerShell_profile.ps1' -Destination $PROFILE
}

function start-script-git-front {
    $scriptPath = 'D:\Projects\code\.dotfiles-mac\tools\git\git-branch-updater.sh'
    $subdirectory = '\dist\git\'
    $currentLocation = Get-Location
    $frontendLocation = Join-Path -Path $currentLocation -ChildPath $subdirectory
    if (-not (Test-Path -Path $frontendLocation)) {
        New-Item -ItemType Directory -Path $frontendLocation -Force
    }
    Copy-Item -Path $scriptPath -Destination $frontendLocation -Force
    Write-Output $frontendLocation
    Set-Location $frontendLocation; la
    Set-Location $currentLocation
}

# Function to copy script to backend location
function start-script-git-back {
    $scriptPath = 'D:\Projects\code\.dotfiles-mac\tools\git\git-branch-updater.sh'
    $subdirectory = '\storage\logs\git\'
    $currentLocation = Get-Location
    $frontendLocation = Join-Path -Path $currentLocation -ChildPath $subdirectory
    if (-not (Test-Path -Path $frontendLocation)) {
        New-Item -ItemType Directory -Path $frontendLocation -Force
    }
    Copy-Item -Path $scriptPath -Destination $frontendLocation -Force
    Write-Output $frontendLocation
    Set-Location $frontendLocation; la
    Set-Location $currentLocation
}