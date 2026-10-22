#requires -Version 5.1
<# ProScan - Diagnóstico somente leitura para Windows. #>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
$Script:Version   = '2.2'
$Script:BuildDate = '2026-10-22'

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
try { chcp 65001 | Out-Null } catch {}

# ─────────────────────────────────────────────
#  HELPERS DE CONSOLE
# ─────────────────────────────────────────────

function Get-ConsoleWidth  { try { $Host.UI.RawUI.WindowSize.Width  } catch { 80 } }
function Get-ConsoleHeight { try { $Host.UI.RawUI.WindowSize.Height } catch { 30 } }
function Write-Blank       { Write-Host }

function Write-Centered {
    param([string]$Text, [ConsoleColor]$Color = [ConsoleColor]::Gray)
    $w   = Get-ConsoleWidth
    $pad = [Math]::Max(0, [int](($w - $Text.Length) / 2))
    Write-Host ((' ' * $pad) + $Text) -ForegroundColor $Color
}

function Write-Safe {
    param([scriptblock]$Action, [object]$Fallback = 'Indisponível')
    try {
        $result = & $Action
        if ($null -eq $result -or ($result -is [string] -and [string]::IsNullOrWhiteSpace($result))) {
            return $Fallback
        }
        return $result
    }
    catch { return $Fallback }
}

# ─────────────────────────────────────────────
#  PRIMITIVOS DE LAYOUT — CAIXA
# ─────────────────────────────────────────────

function Get-BoxWidth {
    $w = Get-ConsoleWidth
    [Math]::Min(62, $w - 4)
}

function Get-BoxLeft {
    $w  = Get-ConsoleWidth
    $bw = Get-BoxWidth
    [Math]::Max(0, [int](($w - $bw - 2) / 2))
}

function Write-BoxTop {
    param([string]$Label = '')
    $bw  = Get-BoxWidth
    $pad = Get-BoxLeft
    if ($Label) {
        $bar = '═' * [Math]::Max(0, ($bw - $Label.Length - 3))
        Write-Host ((' ' * $pad) + '╔═ ') -NoNewline -ForegroundColor Cyan
        Write-Host $Label -NoNewline -ForegroundColor White
        Write-Host (' ' + $bar + '╗') -ForegroundColor Cyan
    } else {
        Write-Host ((' ' * $pad) + '╔' + ('═' * $bw) + '╗') -ForegroundColor Cyan
    }
}

function Write-BoxBottom {
    $bw  = Get-BoxWidth
    $pad = Get-BoxLeft
    Write-Host ((' ' * $pad) + '╚' + ('═' * $bw) + '╝') -ForegroundColor Cyan
}

function Write-BoxDivider {
    $bw  = Get-BoxWidth
    $pad = Get-BoxLeft
    Write-Host ((' ' * $pad) + '╠' + ('═' * $bw) + '╣') -ForegroundColor Cyan
}

function Write-BoxLine {
    param([string]$Text = '', [ConsoleColor]$Color = [ConsoleColor]::Gray, [switch]$Center)
    $bw    = Get-BoxWidth
    $pad   = Get-BoxLeft
    $inner = $bw - 2
    if ($Text.Length -gt $inner) { $Text = $Text.Substring(0, $inner) }
    if ($Center) {
        $total    = $inner - $Text.Length
        $leftPad  = [Math]::Max(0, [int]($total / 2))
        $rightPad = [Math]::Max(0, $total - $leftPad)
        $display  = (' ' * $leftPad) + $Text
        $trailing = ' ' * $rightPad
    } else {
        $display  = $Text
        $trailing = ' ' * ($inner - $Text.Length)
    }
    Write-Host ((' ' * $pad) + '║ ') -NoNewline -ForegroundColor Cyan
    Write-Host $display -NoNewline -ForegroundColor $Color
    Write-Host ($trailing + ' ║') -ForegroundColor Cyan
}

function Write-BoxEmpty { Write-BoxLine '' }

function Write-Heading {
    param([string]$Text)
    Write-Blank
    Write-BoxTop $Text
}

function Write-HeadingClose { Write-BoxBottom }

function Write-Field {
    param([string]$Text, [ConsoleColor]$ForceColor = [ConsoleColor]::Gray, [switch]$UseForce)
    $color = [ConsoleColor]::Gray
    if ($UseForce) {
        $color = $ForceColor
    } elseif ($Text -match '\b(OK|CONECTADO|Running|DISPONÍVEL|ONLINE)\b') { $color = [ConsoleColor]::Green  }
    elseif ($Text -match '\b(Falhou|FALHOU|INDISPONÍVEL|CRÍTICO)\b')        { $color = [ConsoleColor]::Red    }
    elseif ($Text -match 'NÃO DETECTADA|Stopped|não encontrado|SEM RESPOSTA|ATENÇÃO') { $color = [ConsoleColor]::Yellow }

    $bw    = Get-BoxWidth
    $pad   = Get-BoxLeft
    $inner = $bw - 4
    $line  = "  $Text"
    if ($line.Length -gt $inner) { $line = $line.Substring(0, $inner) }
    $spaces = ' ' * ($inner - $line.Length)
    Write-Host ((' ' * $pad) + '║ ') -NoNewline -ForegroundColor Cyan
    Write-Host $line -NoNewline -ForegroundColor $color
    Write-Host ($spaces + '   ║') -ForegroundColor Cyan
}

function Write-DiskField {
    param([string]$Text, [double]$FreePct)
    $color = if ($FreePct -lt 10) { [ConsoleColor]::Red }
             elseif ($FreePct -lt 20) { [ConsoleColor]::Yellow }
             else { [ConsoleColor]::Gray }
    Write-Field $Text -ForceColor $color -UseForce
}

function Get-DiskBar {
    param([double]$Percent)
    $filled = [Math]::Round($Percent / 10)
    $empty  = 10 - $filled
    '[' + ('█' * $filled) + ('░' * $empty) + ']'
}

function Start-Spinner {
    param([string]$Message = 'Processando...')
    $Script:SpinRow = [Console]::CursorTop
    Write-Host ''
    $bw  = Get-BoxWidth
    $pad = Get-BoxLeft

    $Script:SpinRunspace = [runspacefactory]::CreateRunspace()
    $Script:SpinRunspace.Open()
    $Script:SpinRunspace.SessionStateProxy.SetVariable('SpinRow', $Script:SpinRow)
    $Script:SpinRunspace.SessionStateProxy.SetVariable('SpinMsg', $Message)
    $Script:SpinRunspace.SessionStateProxy.SetVariable('SpinPad', $pad)
    $Script:SpinRunspace.SessionStateProxy.SetVariable('SpinBw',  $bw)

    $Script:SpinPS = [PowerShell]::Create()
    $Script:SpinPS.Runspace = $Script:SpinRunspace
    [void]$Script:SpinPS.AddScript({
        $frames = [char[]]@(0x280B,0x2819,0x2839,0x2838,0x283C,0x2834,0x2826,0x2827,0x2807,0x280F)
        $i = 0
        $orig = [Console]::CursorVisible
        [Console]::CursorVisible = $false
        try {
            while ($true) {
                $c    = [string][char]$frames[$i % $frames.Count]
                $line = (' ' * $SpinPad) + "  $c  $SpinMsg"
                $fill = ' ' * [Math]::Max(0, $SpinBw + $SpinPad + 2 - $line.Length)
                [Console]::SetCursorPosition(0, $SpinRow)
                [Console]::ForegroundColor = [ConsoleColor]::DarkCyan
                [Console]::Write($line + $fill)
                [Console]::ResetColor()
                $i++
                Start-Sleep -Milliseconds 80
            }
        } finally { [Console]::CursorVisible = $orig }
    })
    $Script:SpinHandle = $Script:SpinPS.BeginInvoke()
}

function Stop-Spinner {
    if ($Script:SpinPS) {
        $Script:SpinPS.Stop()
        try { $Script:SpinPS.EndInvoke($Script:SpinHandle) } catch {}
        $Script:SpinPS.Dispose()
        $Script:SpinRunspace.Close()
        $Script:SpinRunspace.Dispose()
        $Script:SpinPS = $null
        [Console]::SetCursorPosition(0, $Script:SpinRow)
        [Console]::Write(' ' * ([Math]::Max(1, [Console]::WindowWidth - 1)))
        [Console]::SetCursorPosition(0, $Script:SpinRow)
        [Console]::CursorVisible = $true
    }
}

function Show-ReturnPrompt {
    Write-Blank
    $bw    = Get-BoxWidth
    $pad   = Get-BoxLeft
    $sep   = '─' * $bw
    Write-Host ((' ' * $pad) + $sep) -ForegroundColor DarkGray
    Write-Centered '[0]  Voltar ao menu  |  Enter' DarkGray
    Write-Host ((' ' * $pad) + $sep) -ForegroundColor DarkGray
    Write-Blank
    $prompt = 'Escolha › '
    $pPad   = [Math]::Max(0, $pad + [int]($bw / 2) - [int]($prompt.Length / 2))
    do {
        Write-Host ((' ' * $pPad) + $prompt) -NoNewline -ForegroundColor Yellow
        $key = [Console]::ReadLine().Trim()
    } until ($key -eq '0' -or $key -eq '')
}

# ─────────────────────────────────────────────
#  SEÇÕES DE DIAGNÓSTICO
# ─────────────────────────────────────────────

function Show-Identity {
    Write-Heading 'IDENTIDADE DO COMPUTADOR E BIOS'
    $comp = Get-CimInstance Win32_ComputerSystem
    $os   = Get-CimInstance Win32_OperatingSystem
    $bios = Write-Safe { Get-CimInstance Win32_BIOS }
    Write-BoxEmpty
    Write-Field "Computador  :  $env:COMPUTERNAME"
    Write-Field "Usuário     :  $env:USERDOMAIN\$env:USERNAME"
    Write-Field "Domínio     :  $(if ($comp.PartOfDomain) { $comp.Domain } else { 'Grupo de trabalho' })"
    Write-Field "Fabricante  :  $($comp.Manufacturer)"
    Write-Field "Modelo      :  $($comp.Model)"
    Write-Field "Windows     :  $($os.Caption) ($($os.Version))"
    Write-Field "Serial      :  $(if ($bios -and $bios.SerialNumber) { $bios.SerialNumber } else { 'Indisponível' })"
    Write-Field "BIOS        :  $(if ($bios -and $bios.SMBIOSBIOSVersion) { $bios.SMBIOSBIOSVersion } else { 'Indisponível' })"

    Start-Spinner 'Consultando último login...'
    $lastLogin = Write-Safe {
        $adsi = [ADSI]"WinNT://$env:USERDOMAIN/$env:USERNAME,user"
        $dt   = $adsi.LastLogin.Value
        if ($dt -and $dt -gt [datetime]'1970-01-01') {
            $dt.ToString('dd/MM/yyyy HH:mm:ss')
        } else { $null }
    } -Fallback $null
    if (-not $lastLogin) {
        $lastLogin = Write-Safe {
            $evt = Get-WinEvent -FilterHashtable @{ LogName='Security'; Id=4624 } -MaxEvents 50 -ErrorAction Stop |
                Where-Object { $_.Properties[5].Value -eq $env:USERNAME -and $_.Properties[8].Value -in @(2,10) } |
                Select-Object -First 1
            if ($evt) { $evt.TimeCreated.ToString('dd/MM/yyyy HH:mm:ss') } else { $null }
        } -Fallback $null
    }
    Stop-Spinner
    Write-Field "Último login  :  $(if ($lastLogin) { $lastLogin } else { 'não foi possível obter' })"
    Write-BoxEmpty
    Write-HeadingClose
}

function Show-Hardware {
    Write-Heading 'HARDWARE E DISCOS'
    $comp = Get-CimInstance Win32_ComputerSystem
    $os   = Get-CimInstance Win32_OperatingSystem
    $cpu  = Get-CimInstance Win32_Processor | Select-Object -First 1

    $totalRamGB = $comp.TotalPhysicalMemory / 1GB
    $freeRamGB  = $os.FreePhysicalMemory / 1MB
    $usedRamGB  = $totalRamGB - $freeRamGB
    $ramPct     = [Math]::Round($usedRamGB / $totalRamGB * 100)
    $ramBar     = Get-DiskBar -Percent $ramPct
    $cpuLoad    = $cpu.LoadPercentage

    Write-BoxEmpty
    Write-Field "Processador  :  $($cpu.Name.Trim())"
    Write-Field "Núcleos      :  $($cpu.NumberOfCores) físicos / $($cpu.NumberOfLogicalProcessors) lógicos"
    Write-Field "CPU atual    :  $cpuLoad%"
    Write-BoxEmpty
    Write-Field ('RAM total    :  {0:N1} GB' -f $totalRamGB)
    Write-Field ('RAM em uso   :  {0:N1} GB de {1:N1} GB  {2}  {3}%' -f $usedRamGB, $totalRamGB, $ramBar, $ramPct)
    Write-BoxEmpty
    Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object {
        $pct  = if ($_.Size) { $_.FreeSpace / $_.Size * 100 } else { 0 }
        $bar  = Get-DiskBar -Percent $pct
        $aviso = if ($pct -lt 10) { '  !! CRÍTICO' } elseif ($pct -lt 20) { '  ! ATENÇÃO' } else { '' }
        Write-DiskField ('Disco {0}  :  {1:N1} GB livres de {2:N1} GB  {3}  {4:N0}%{5}' -f `
            $_.DeviceID, ($_.FreeSpace / 1GB), ($_.Size / 1GB), $bar, $pct, $aviso) -FreePct $pct
    }
    Write-BoxEmpty
    Write-HeadingClose
}

function Show-Network {
    Write-Heading 'REDE E INTERNET'
    $comp = Get-CimInstance Win32_ComputerSystem
    Write-BoxEmpty
    if ($comp.PartOfDomain) {
        Write-Field "Domínio corporativo  :  $($comp.Domain)"
        if ($comp.Domain -ieq 'exsa.local') { Write-Field 'Rede EXSA.LOCAL  :  CONECTADO' }
        else                                { Write-Field 'Rede EXSA.LOCAL  :  NÃO DETECTADA' }
    } else {
        Write-Field 'Domínio corporativo  :  computador não ingressado em domínio'
        Write-Field 'Rede EXSA.LOCAL      :  NÃO DETECTADA'
    }
    Write-BoxEmpty
    $gateways = Write-Safe {
        Get-NetRoute -DestinationPrefix '0.0.0.0/0' |
        Where-Object { $_.NextHop -ne '0.0.0.0' } |
        Sort-Object RouteMetric | Select-Object -First 2
    } -Fallback @()
    if ($gateways -is [array] -and $gateways.Count -eq 0) { Write-Field 'Gateway padrão  :  não localizado' }
    else { @($gateways) | ForEach-Object { Write-Field "Gateway  :  $($_.NextHop) via $($_.InterfaceAlias)" } }
    Write-BoxEmpty
    foreach ($addr in @('1.1.1.1', '8.8.8.8')) {
        Start-Spinner "Testando conectividade $addr..."
        $online = Write-Safe { Test-Connection -ComputerName $addr -Count 1 -Quiet -ErrorAction Stop } $false
        Stop-Spinner
        Write-Field "Teste $addr  :  $(if ($online) { 'OK' } else { 'Falhou' })"
    }
    Start-Spinner 'Resolvendo DNS...'
    $dns = Write-Safe { Resolve-DnsName -Name 'www.microsoft.com' -Type A -ErrorAction Stop | Select-Object -First 1 } $null
    Stop-Spinner
    Write-Field "DNS Microsoft  :  $(if ($dns) { 'OK' } else { 'Falhou' })"
    Write-BoxEmpty
    Write-HeadingClose

    Write-Heading 'ADAPTADORES DE REDE'
    Write-BoxEmpty
    $adapters = Get-NetAdapter -Physical | Sort-Object Status, Name
    if ($adapters) { $adapters | ForEach-Object { Write-Field "$($_.Name)  :  $($_.Status) | MAC $($_.MacAddress) | $($_.LinkSpeed)" } }
    else           { Write-Field 'Nenhum adaptador físico encontrado.' }
    Write-BoxEmpty
    Write-HeadingClose
}

function Show-Health {
    Write-Heading 'SAÚDE DO SISTEMA'
    $os     = Get-CimInstance Win32_OperatingSystem
    $uptime = (Get-Date) - $os.LastBootUpTime
    Write-BoxEmpty
    Write-Field ('Tempo ligado  :  {0} dia(s), {1:00}:{2:00}:{3:00}' -f `
        [int]$uptime.TotalDays, $uptime.Hours, $uptime.Minutes, $uptime.Seconds)
    Write-BoxEmpty
    $svcs = @(
        @{ Name='wuauserv'; Label='Windows Update'    }
        @{ Name='bits';     Label='BITS'               }
        @{ Name='cryptsvc'; Label='Cryptographic Svc' }
        @{ Name='Winmgmt';  Label='WMI'                }
        @{ Name='Dhcp';     Label='DHCP Client'        }
        @{ Name='Dnscache'; Label='DNS Client'         }
    )
    foreach ($s in $svcs) {
        $svc = Get-Service -Name $s.Name -ErrorAction SilentlyContinue
        if ($svc) { Write-Field "$($s.Label)  :  $($svc.Status)" }
        else      { Write-Field "$($s.Label)  :  não encontrado" }
    }
    Write-BoxEmpty
    $rdpDeny = Write-Safe {
        (Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections).fDenyTSConnections
    } -Fallback $null
    $rdpSvc = Get-Service -Name 'TermService' -ErrorAction SilentlyContinue
    if ($null -eq $rdpDeny) {
        Write-Field 'Remote Desktop (RDP)  :  não foi possível verificar'
    } elseif ($rdpDeny -eq 0) {
        $svcStatus = if ($rdpSvc -and $rdpSvc.Status -eq 'Running') { 'serviço ativo' } else { 'serviço parado' }
        Write-Field "Remote Desktop (RDP)  :  DISPONÍVEL  ($svcStatus)"
    } else {
        Write-Field 'Remote Desktop (RDP)  :  desabilitado'
    }
    Write-BoxEmpty
    Start-Spinner 'Verificando atualizações do Windows...'
    $pendingUpdates = Write-Safe {
        $session = New-Object -ComObject Microsoft.Update.Session
        $searcher = $session.CreateUpdateSearcher()
        $result   = $searcher.Search('IsInstalled=0 and Type=''Software'' and IsHidden=0')
        $result.Updates.Count
    } -Fallback $null
    Stop-Spinner
    if ($null -ne $pendingUpdates -and $pendingUpdates -is [int]) {
        if ($pendingUpdates -eq 0)      { Write-Field 'Atualizações pendentes  :  Nenhuma' }
        elseif ($pendingUpdates -le 5)  { Write-Field "Atualizações pendentes  :  $pendingUpdates  — ATENÇÃO" }
        else                            { Write-Field "Atualizações pendentes  :  $pendingUpdates  — CRÍTICO" }
    } else {
        Write-Field 'Atualizações pendentes  :  não foi possível verificar'
    }
    Write-BoxEmpty
    Start-Spinner 'Lendo Event Log (últimos 7 dias)...'
    $winErrors = Write-Safe {
        Get-WinEvent -FilterHashtable @{ LogName='System'; Level=2; StartTime=(Get-Date).AddDays(-7) } -MaxEvents 5
    } -Fallback @()
    Stop-Spinner
    if (@($winErrors).Count -eq 0) { Write-Field 'Nenhum erro nos últimos 7 dias.' }
    else { @($winErrors) | ForEach-Object { Write-Field "[$($_.TimeCreated.ToString('dd/MM HH:mm'))] $($_.ProviderName) — ID $($_.Id)" } }
    Write-BoxEmpty
    Write-HeadingClose
}

function Show-RecentPrograms {
    Write-Heading 'PROGRAMAS INSTALADOS RECENTEMENTE'
    $paths = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $progs = Get-ItemProperty -Path $paths -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -and $_.InstallDate -match '^\d{8}$' } |
        ForEach-Object {
            [pscustomobject]@{
                Nome  = $_.DisplayName
                Versão = $_.DisplayVersion
                Data  = [datetime]::ParseExact($_.InstallDate, 'yyyyMMdd', $null)
            }
        } | Sort-Object Data -Descending | Select-Object -First 15
    Write-BoxEmpty
    if ($progs) { $progs | ForEach-Object { Write-Field ('{0:dd/MM/yyyy}  —  {1} {2}' -f $_.Data, $_.Nome, $_.Versão) } }
    else        { Write-Field 'O Windows não informou datas de instalação para os programas encontrados.' }
    Write-BoxEmpty
    Write-HeadingClose
}

function Show-RemoteMachine {
    Write-Heading 'BUSCAR MÁQUINA NA REDE LOCAL'
    Write-BoxEmpty
    Write-BoxLine 'Digite o nome da máquina ou endereço IP:' Yellow -Center
    $bw  = Get-BoxWidth
    $pad = Get-BoxLeft
    $pPad = [Math]::Max(0, $pad + [int]($bw / 2) - 2)
    Write-Host ((' ' * $pPad) + '> ') -NoNewline -ForegroundColor Yellow
    $target = [Console]::ReadLine().Trim()

    if ([string]::IsNullOrWhiteSpace($target)) {
        Write-BoxEmpty
        Write-Field 'Nenhum nome ou endereço IP informado.'
        Write-BoxEmpty
        Write-HeadingClose
        return
    }

    Write-BoxEmpty
    Write-Field "Pesquisa  :  $target"
    Start-Spinner "Resolvendo DNS de $target..."
    $dnsResult = Write-Safe { Resolve-DnsName -Name $target -Type A -ErrorAction Stop | Select-Object -First 1 } $null
    Stop-Spinner
    if ($dnsResult) { Write-Field "IP resolvido  :  $($dnsResult.IPAddress)" }
    else            { Write-Field 'Resolução DNS  :  não encontrada' }

    Start-Spinner "Pingando $target..."
    $ping = Test-Connection -ComputerName $target -Count 2 -ErrorAction SilentlyContinue
    Stop-Spinner
    if ($ping) {
        $avg = [Math]::Round((($ping | Measure-Object -Property ResponseTime -Average).Average), 1)
        Write-Field 'Status  :  ONLINE'
        Write-Field "Endereço respondendo  :  $($ping[0].Address)"
        Write-Field "Tempo médio  :  $avg ms"
    } else {
        Write-Field 'Status  :  SEM RESPOSTA (desligada, inacessível ou ICMP bloqueado)'
    }
    Write-BoxEmpty
    Write-HeadingClose

    Start-Spinner "Conectando via CIM/WMI em $target..."
    try { $remSys = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $target -ErrorAction Stop 2>$null }
    catch { $remSys = $null }
    Stop-Spinner

    if (-not $remSys) {
        Write-Heading 'ACESSO REMOTO'
        Write-BoxEmpty
        Write-Field 'Acesso remoto  :  indisponível.'
        Write-Field 'A máquina precisa permitir CIM/WMI e sua conta precisa ter permissão.'
        Write-BoxEmpty
        Write-HeadingClose
        return
    }

    try {
        Start-Spinner "Coletando dados remotos de $target..."
        $remOs   = Get-CimInstance Win32_OperatingSystem -ComputerName $target -ErrorAction Stop -OperationTimeoutSec 10 2>$null
        $remBios = Get-CimInstance Win32_BIOS            -ComputerName $target -ErrorAction Stop -OperationTimeoutSec 10 2>$null
        $remCpu  = Get-CimInstance Win32_Processor       -ComputerName $target -ErrorAction Stop -OperationTimeoutSec 10 2>$null | Select-Object -First 1
        $remDisk = Get-CimInstance Win32_LogicalDisk     -ComputerName $target -Filter 'DriveType=3' -ErrorAction Stop -OperationTimeoutSec 10 2>$null
        $remNet  = Get-CimInstance Win32_NetworkAdapterConfiguration -ComputerName $target -Filter 'IPEnabled=True' -ErrorAction Stop -OperationTimeoutSec 10 2>$null
        $remSvc  = Get-CimInstance Win32_Service         -ComputerName $target -ErrorAction Stop -OperationTimeoutSec 10 2>$null |
                   Where-Object { $_.Name -in @('wuauserv','bits','cryptsvc','Winmgmt','Dhcp','Dnscache','TermService') }
        Stop-Spinner

        Write-Heading 'DADOS REMOTOS DA MÁQUINA'
        Write-BoxEmpty
        Write-Field 'Acesso remoto  :  DISPONÍVEL'
        Write-Field "Nome         :  $($remSys.Name)"
        Write-Field "Domínio      :  $(if ($remSys.PartOfDomain) { $remSys.Domain } else { 'Grupo de trabalho' })"
        if ($remSys.PartOfDomain) {
            if ($remSys.Domain -ieq 'exsa.local') { Write-Field 'Rede EXSA.LOCAL  :  CONECTADO' }
            else                                   { Write-Field 'Rede EXSA.LOCAL  :  NÃO DETECTADA' }
        }
        Write-Field "Fabricante   :  $($remSys.Manufacturer) — $($remSys.Model)"
        Write-Field "Windows      :  $($remOs.Caption) ($($remOs.Version))"
        Write-Field "BIOS         :  $($remBios.SMBIOSBIOSVersion) | Serial: $($remBios.SerialNumber)"
        Write-Field "Processador  :  $($remCpu.Name.Trim())"
        Write-Field ('Memória      :  {0:N2} GB' -f ($remSys.TotalPhysicalMemory / 1GB))
        $remUptime = (Get-Date) - $remOs.LastBootUpTime
        Write-Field ('Tempo ligado :  {0} dia(s), {1:00}:{2:00}:{3:00}' -f `
            [int]$remUptime.TotalDays, $remUptime.Hours, $remUptime.Minutes, $remUptime.Seconds)

        $remRdpDeny = Write-Safe {
            $regVal = Invoke-CimMethod -ComputerName $target -ClassName StdRegProv -MethodName GetDWORDValue -Arguments @{
                hDefKey     = [uint32]2147483650  # HKLM
                sSubKeyName = 'System\CurrentControlSet\Control\Terminal Server'
                sValueName  = 'fDenyTSConnections'
            } -OperationTimeoutSec 10 -ErrorAction Stop
            $regVal.uValue
        } -Fallback $null
        $remRdpSvc = @($remSvc) | Where-Object { $_.Name -eq 'TermService' } | Select-Object -First 1
        if ($null -eq $remRdpDeny) {
            Write-Field 'RDP  :  não foi possível verificar'
        } elseif ($remRdpDeny -eq 0) {
            $svcStatus = if ($remRdpSvc -and $remRdpSvc.State -eq 'Running') { 'serviço ativo' } else { 'serviço parado' }
            Write-Field "RDP  :  DISPONÍVEL  ($svcStatus)"
        } else {
            Write-Field 'RDP  :  desabilitado'
        }

        $loggedUsers = Write-Safe {
            $sessions = Get-CimInstance Win32_LogonSession -ComputerName $target -OperationTimeoutSec 10 -ErrorAction Stop |
                Where-Object { $_.LogonType -in @(2, 10) }
            $users = foreach ($s in $sessions) {
                Get-CimInstance -Query "ASSOCIATORS OF {Win32_LogonSession.LogonId='$($s.LogonId)'} WHERE AssocClass=Win32_LoggedOnUser" `
                    -ComputerName $target -OperationTimeoutSec 10 -ErrorAction Stop |
                    Select-Object -ExpandProperty Name
            }
            $list = ($users | Where-Object { $_ } | Select-Object -Unique) -join ', '
            if ([string]::IsNullOrWhiteSpace($list)) { $null } else { $list }
        } -Fallback $null
        if ($loggedUsers) {
            Write-Field "Usuário(s)   :  $loggedUsers"
        } else {
            Write-Field 'Usuário(s)   :  não foi possível consultar'
        }
        Write-BoxEmpty
        Write-HeadingClose

        Write-Heading 'DISCOS REMOTOS'
        Write-BoxEmpty
        @($remDisk) | ForEach-Object {
            $pct    = if ($_.Size) { $_.FreeSpace / $_.Size * 100 } else { 0 }
            $bar    = Get-DiskBar -Percent $pct
            $aviso  = if ($pct -lt 10) { '  !! CRÍTICO' } elseif ($pct -lt 20) { '  ! ATENÇÃO' } else { '' }
            Write-DiskField ('Disco {0}  :  {1:N1} GB livres de {2:N1} GB  {3}  {4:N0}%{5}' -f `
                $_.DeviceID, ($_.FreeSpace / 1GB), ($_.Size / 1GB), $bar, $pct, $aviso) -FreePct $pct
        }
        Write-BoxEmpty
        Write-HeadingClose

        Write-Heading 'REDE REMOTA'
        Write-BoxEmpty
        @($remNet) | ForEach-Object {
            Write-Field "IP       :  $($_.IPAddress -join ', ') | MAC: $($_.MACAddress)"
            Write-Field "Gateway  :  $($_.DefaultIPGateway -join ', ') | DNS: $($_.DNSServerSearchOrder -join ', ')"
        }
        Write-BoxEmpty
        Write-HeadingClose

        Write-Heading 'SERVIÇOS REMOTOS'
        Write-BoxEmpty
        @($remSvc) | Sort-Object Name | ForEach-Object { Write-Field "$($_.DisplayName)  :  $($_.State)" }
        Write-BoxEmpty
        Write-HeadingClose

        Write-Heading 'PROGRAMAS INSTALADOS RECENTEMENTE'
        Write-BoxEmpty
        $remPrograms = $null
        Start-Spinner 'Lendo registro remoto de programas instalados...'
        try {
            $remReg  = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $target)
            $regPaths = @(
                'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
                'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
            )
            $remPrograms = foreach ($rp in $regPaths) {
                $key = $remReg.OpenSubKey($rp)
                if (-not $key) { continue }
                foreach ($subName in $key.GetSubKeyNames()) {
                    $sub  = $key.OpenSubKey($subName)
                    if (-not $sub) { continue }
                    $name = $sub.GetValue('DisplayName')
                    $date = $sub.GetValue('InstallDate')
                    $ver  = $sub.GetValue('DisplayVersion')
                    if ($name -and $date -match '^\d{8}$') {
                        [pscustomobject]@{
                            Nome  = $name
                            Versão = $ver
                            Data  = [datetime]::ParseExact($date, 'yyyyMMdd', $null)
                        }
                    }
                }
            }
            $remReg.Close()
        } catch { $remPrograms = $null }
        Stop-Spinner

        if ($remPrograms) {
            $remPrograms | Sort-Object Data -Descending | Select-Object -First 10 |
                ForEach-Object { Write-Field ('{0:dd/MM/yyyy}  —  {1} {2}' -f $_.Data, $_.Nome, $_.Versão) }
        } else {
            Write-Field 'Registro remoto indisponível ou sem datas de instalação.'
        }
        Write-BoxEmpty
        Write-HeadingClose
    }
    catch {
        Stop-Spinner
        Write-Heading 'AVISO'
        Write-BoxEmpty
        Write-Field 'Acesso remoto  :  disponível parcialmente.'
        Write-Field "Detalhe  :  $($_.Exception.Message)"
        Write-BoxEmpty
        Write-HeadingClose
    }
}

# ─────────────────────────────────────────────
#  MENU PRINCIPAL
# ─────────────────────────────────────────────

$menuEntries = @(
    @{ Key='1'; Label='Diagnóstico completo'              }
    @{ Key='2'; Label='Identidade do computador e BIOS'   }
    @{ Key='3'; Label='Hardware e discos'                 }
    @{ Key='4'; Label='Rede e internet'                   }
    @{ Key='5'; Label='Saúde do sistema'                  }
    @{ Key='6'; Label='Programas instalados recentemente' }
    @{ Key='7'; Label='Buscar máquina na rede'            }
)

do {
    Clear-Host

    $h      = Get-ConsoleHeight
    $topPad = [Math]::Max(1, [int](($h - $menuEntries.Count - 12) / 2))
    for ($i = 0; $i -lt $topPad; $i++) { Write-Blank }

    Write-BoxTop
    Write-BoxEmpty
    Write-BoxLine 'P R O S C A N' Cyan -Center
    Write-BoxLine 'Diagnóstico do Windows' DarkGray -Center
    Write-BoxEmpty
    Write-BoxDivider
    Write-BoxEmpty

    $maxLen  = ($menuEntries | ForEach-Object { "[$($_.Key)]  $($_.Label)".Length } | Measure-Object -Maximum).Maximum
    $maxLen  = [Math]::Max($maxLen, '[0]  Sair'.Length)
    $bw      = Get-BoxWidth
    $pad     = Get-BoxLeft
    $inner   = $bw - 2
    $blkPad  = [Math]::Max(0, [int](($inner - $maxLen) / 2))

    foreach ($entry in $menuEntries) {
        $text    = "[$($entry.Key)]  $($entry.Label)"
        $filling = ' ' * ($inner - $blkPad - $text.Length)
        Write-Host ((' ' * $pad) + '║ ' + (' ' * $blkPad)) -NoNewline -ForegroundColor Cyan
        Write-Host "[$($entry.Key)]" -NoNewline -ForegroundColor Cyan
        Write-Host "  $($entry.Label)$filling" -NoNewline -ForegroundColor White
        Write-Host ' ║' -ForegroundColor Cyan
    }

    Write-BoxEmpty
    Write-BoxDivider
    $sairText = '[0]  Sair'
    $sairFill = ' ' * ($inner - $blkPad - $sairText.Length)
    Write-Host ((' ' * $pad) + '║ ' + (' ' * $blkPad)) -NoNewline -ForegroundColor Cyan
    Write-Host '[0]' -NoNewline -ForegroundColor DarkGray
    Write-Host "  Sair$sairFill" -NoNewline -ForegroundColor DarkGray
    Write-Host ' ║' -ForegroundColor Cyan
    Write-BoxBottom

    Write-Blank

    $validKeys = (@($menuEntries | ForEach-Object { $_.Key }) + @('0'))
    $choice    = $null
    do {
        $pPad   = [Math]::Max(0, $pad + [int]($bw / 2) - 4)
        if ($null -ne $choice) { Write-Centered "Opção inválida. Digite 0 a $($menuEntries.Count)." Red }
        Write-Host ((' ' * $pPad) + 'Escolha › ') -NoNewline -ForegroundColor Yellow
        $choice = [Console]::ReadLine().Trim()
    } until ($choice -in $validKeys)

    if ($choice -eq '0') { break }

    Clear-Host
    Write-Blank
    Write-BoxTop
    Write-BoxLine "ProScan  —  Diagnóstico do Windows" Cyan -Center
    Write-BoxLine "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')  ·  Somente leitura" DarkGray -Center
    Write-BoxBottom

    switch ($choice) {
        '1' {
            $steps = @(
                @{ Label='Identidade';         Fn={ Show-Identity       } }
                @{ Label='Hardware';           Fn={ Show-Hardware       } }
                @{ Label='Rede';               Fn={ Show-Network        } }
                @{ Label='Saúde';              Fn={ Show-Health         } }
                @{ Label='Programas recentes'; Fn={ Show-RecentPrograms } }
            )
            $total = $steps.Count; $n = 0
            foreach ($step in $steps) {
                $n++
                Write-Blank
                Write-Centered "[ $n / $total ]  Coletando: $($step.Label)..." DarkGray
                & $step.Fn
            }
        }
        '2' { Show-Identity       }
        '3' { Show-Hardware       }
        '4' { Show-Network        }
        '5' { Show-Health         }
        '6' { Show-RecentPrograms }
        '7' { Show-RemoteMachine  }
    }

    Show-ReturnPrompt

} while ($true)

Clear-Host
Write-Blank
Write-BoxTop
Write-BoxLine 'ProScan encerrado. Até logo.' DarkGray -Center
Write-BoxBottom
Write-Blank
