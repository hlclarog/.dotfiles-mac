<#
.SYNOPSIS
  Cleans and re-organizes the PSReadLine history file into categorized sections.
  Deduplicates, drops paste-fragments / prose / typos, writes UTF-8 (no BOM).

.NOTES
  Reusable: run it again whenever the history gets messy.
  Overwrites the live file in place without creating any backup (by design).
#>
param(
    [string]$SourcePath = (Join-Path $env:APPDATA 'Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt'),
    [string]$OutPath,                 # if omitted, writes a *.clean.txt sibling for review
    [switch]$InPlace                  # overwrite the live history file (after backup)
)

if (-not (Test-Path $SourcePath)) { throw "History file not found: $SourcePath" }

# --- 0. Curated seed: base commands always present for autocomplete ----------
# Edit this list to grow the base. Seeds survive every clean and a full wipe.
# Keep each entry as the exact text you want PSReadLine to predict.
$seed = @(
    # Missing aliases / functions worth predicting
    'cdn8n'
    'cdtest'
    'cdprism'
    'clean-history'

    # Git -- forms WITHOUT an alias (aliased ones fold to gs/gaa/gca/gf/gpl/gpll/gps/gb)
    'git add .'
    'git commit -m ""'
    'git checkout -b '
    'git switch '
    'git branch -d '
    'git push -u origin HEAD'
    'git merge '
    'git rebase '
    'git rebase -i HEAD~3'
    'git stash'
    'git stash pop'
    'git stash list'
    'git log --oneline --graph --decorate --all'
    'git diff'
    'git diff --staged'
    'git reset --soft HEAD~1'
    'git restore '
    'git restore --staged '
    'git cherry-pick '
    'git revert '
    'git reflog'
    'git remote -v'
    'git tag'

    # Node toolchain (pnpm / npm / fnm)
    'pnpm install'
    'pnpm dev'
    'pnpm build'
    'pnpm add '
    'pnpm add -D '
    'pnpm remove '
    'pnpm up -r'
    'pnpm store prune'
    'pnpm dlx '
    'npm install'
    'npm run dev'
    'npm run build'
    'npx '
    'fnm install '
    'node -v'

    # engram
    'engram status'
    'engram stats'
    'engram sync --import'
    'engram sync --cloud --import --project '
    'engram sync --cloud --status --project '
    'engram cloud upgrade doctor --project '

    # prism
    'prism guard check'
    'prism guard check --verbose'
    'prism rules bootstrap --dry-run'

    # Docker / WSL
    'docker ps'
    'docker logs -f '
    'docker compose up -d'
    'docker compose down'
    'wsl --shutdown'
    'wsl -l -v'

    # PowerShell utils
    'Get-Process '
    'Stop-Process -Name '
    'Test-NetConnection -ComputerName '
    'Resolve-DnsName '
    'Get-Service '
    'Restart-Service '
)

$raw = @($seed) + (Get-Content -LiteralPath $SourcePath)

# --- 1. Garbage / prose / fragment patterns to DROP outright ------------------
$dropRegex = @(
    '^\s',                       # leading whitespace = pasted block fragment
    '^#',                        # old section headers (we regenerate them)
    '^- ',                       # markdown bullets
    '^\* ',
    '^\d+\.\s',                  # numbered list lines ("1. First, show me...")
    '^"',                        # quoted commit-message fragments
    '`$',                        # lines ending in backtick = multi-line continuation
    '^\+`?$',
    '^Help me ',
    '^Stay focused',
    '^Provide clear',
    '^Example (good|bad) commit',
    '^Select-Object FullName$',
    '^\$opencodeExe',
    '^& \$opencodeExe',
    '^\$data =',
    '^\$udp',
    '^\}$',
    'SetEnvironmentVariable\(\s*"ENGRAM_CLOUD_TOKEN"\s*,\s*"[^"]+"'   # never persist secret values
) -join '|'

# --- 2. Exact junk / typos to DROP (case-insensitive) -------------------------
$dropExact = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
@(
    'fnmcluade','prims','cdca','cdcc','cdjd','cl','cs','gente','New',
    'cd .\test\q','cd  test\',"cd 'AppData'",
    'pnpm buid-prod','pnpm buid-pprod','prism guard check --verboso',
    'nvm ---help','npm -version','pnpm -version','CLS','LS','prism guard check --verboso',
    'cdm8n','cdtrip2','wsl list','wsl -d list',
    'ping admin.jobs.transportationamerica.com+',
    'engram sync --cloud --Project prism','engram sync --cloud --status --Project prism'
) | ForEach-Object { [void]$dropExact.Add($_) }

# --- 2b. Canonical folds: collapse different spellings of the SAME action ----
# Applied before dedup, so every variant becomes its one canonical form.
# Rule: prefer your defined alias; otherwise pick one spelling.
$canonical = @{
    # Navigation -> alias / one spelling
    'cd n8n\'                       = 'cdn8n'
    'cdc n8n\'                      = 'cdn8n'
    'cd ..'                         = '..'
    "cd '..'"                       = '..'
    'cd test'                       = 'cdtest'
    'cd test\'                      = 'cdtest'
    'cd .\test\'                    = 'cdtest'
    'cdc && cd test'                = 'cdtest'
    'cd prism'                      = 'cdprism'
    'cd prism\'                     = 'cdprism'
    'cd .\prism\'                   = 'cdprism'
    'cdc prism'                     = 'cdprism'
    # Git full form -> your alias
    'git status'                    = 'gs'
    'git status -sb'                = 'gs'
    'git fetch --all -p'            = 'gf'
    'git pull'                      = 'gpl'
    'git pull --rebase --autostash' = 'gpll'
    'git push'                      = 'gps'
    'git branch'                    = 'gb'
    'git add -A'                    = 'gaa'
    'git commit --amend --no-edit'  = 'gca'
    'git push --force-with-lease'   = 'gpsf'
    'git push --force'              = 'gpsf'
    # fnm/nvm full form -> your alias
    'fnm use 24'                    = 'fnmd'
    'fnm list'                      = 'fnml'
    'nvm list'                      = 'nl'
    # Flag variants -> one form
    'node --version'                = 'node -v'
    'npm --version'                 = 'npm -v'
    'pnpm run build'                = 'pnpm build'
    'pnpm run dev'                  = 'pnpm dev'
    'pnpm i'                        = 'pnpm install'
    'npm i'                         = 'npm install'
    # engram invalid syntax -> valid
    'engram sync import'            = 'engram sync --import'
    'engram sync help'              = 'engram sync --help'
}

# --- 3. Ordered categories (first match wins) ---------------------------------
$categories = [ordered]@{
    'Navegacion / cd'                 = '^(cd|\.\.|~|dotfiles)'
    'Editores'                        = '^(nano|notepad|vim|code |Invoke-Item \$)'
    'Git'                             = '^git |^(gaa|gca|gco|gc|gd|gs|gf|gpsf|gps|gpll|gpl|gb|gl)$'
    'engram'                          = '^engram'
    'prism'                           = '^prism'
    'gentle-ai / Go'                  = 'gentle-ai|^go install'
    'opencode'                        = '(^|\W)opencode'
    'fnm / nvm / Node'                = '^(fnm|nvm|node|nu|nl|nad)'
    'pnpm'                            = '^pnpm'
    'npm / npx'                       = '^(npm|npx)\b'
    'oh-my-posh'                      = 'oh-my-posh|OhMyPosh|Get-PoshThemes'
    'Install / Web (irm / winget / curl)' = '^(irm|winget|Install-Module|Invoke-WebRequest|curl)'
    'WSL / Docker'                    = '^(wsl|docker)\b'
    'Red / Ping'                      = '^(ping|ipconfig)\b'
    'Archivos (ls / mkdir / mv / rm)' = '^(ls|dir|mkdir|mv|rm|la|ll|Remove-Item|Get-ChildItem|Get-AllItems|Select-Object)\b'
    'Entorno / PowerShell'            = '.*'   # catch-all, must be last
}

# --- 4. Filter + dedupe (case-sensitive after junk removal) -------------------
$seen = [System.Collections.Generic.HashSet[string]]::new()
$clean = foreach ($line in $raw) {
    $t = $line.TrimEnd()
    if ($t -eq '') { continue }
    if ($t -match $dropRegex) { continue }
    if ($dropExact.Contains($t)) { continue }
    if ($canonical.ContainsKey($t)) { $t = $canonical[$t] }   # fold to canonical form
    if ($seen.Add($t)) { $t }      # keep first occurrence
}

# --- 5. Bucket into categories ------------------------------------------------
$buckets = [ordered]@{}
foreach ($k in $categories.Keys) { $buckets[$k] = [System.Collections.Generic.List[string]]::new() }
foreach ($cmd in $clean) {
    foreach ($k in $categories.Keys) {
        if ($cmd -match $categories[$k]) { $buckets[$k].Add($cmd); break }
    }
}

# --- 6. Emit categorized output -----------------------------------------------
$out = [System.Text.StringBuilder]::new()
foreach ($k in $buckets.Keys) {
    if ($buckets[$k].Count -eq 0) { continue }
    [void]$out.AppendLine("# === $k ===")
    foreach ($c in ($buckets[$k] | Sort-Object)) { [void]$out.AppendLine($c) }
    [void]$out.AppendLine('')
}

# --- 7. Decide target + write (UTF-8 no BOM) ----------------------------------
if (-not $OutPath) {
    if ($InPlace) { $OutPath = $SourcePath }
    else { $OutPath = [IO.Path]::ChangeExtension($SourcePath, 'clean.txt') }
}
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($OutPath, $out.ToString(), $utf8NoBom)

# --- 8. Report ----------------------------------------------------------------
Write-Host ""
Write-Host "Wrote: $OutPath" -ForegroundColor Green
Write-Host ("Lines in: {0}  ->  unique commands kept: {1}" -f $raw.Count, $clean.Count)
Write-Host ""
Write-Host "Per-category counts:" -ForegroundColor Cyan
foreach ($k in $buckets.Keys) {
    if ($buckets[$k].Count -gt 0) { "{0,3}  {1}" -f $buckets[$k].Count, $k }
}
