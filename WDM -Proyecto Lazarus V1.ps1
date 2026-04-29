<#
.SYNOPSIS
    WINDOWS DE MENTE - PROYECTO LAZARUS v1.0
    "Donde el software se rinde, la lógica prevalece."

.DESCRIPTION
    Biopsia profunda de 105 sectores críticos del sistema (19 GRUPOS).
    Diagnóstico + Optimización REAL (Auto/Manual/Salir)
#>

#Requires -RunAsAdministrator

# ==============================================
# CONFIGURACIÓN INICIAL
# ==============================================
try {
    $pshost = Get-Host
    $pswindow = $pshost.UI.RawUI
    $newsize = $pswindow.BufferSize
    $newsize.Height = 3000
    $pswindow.BufferSize = $newsize
} catch { }

Clear-Host

Write-Host @"
╔══════════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                          ║
║                                    ██╗    ██╗██████╗ ███╗   ███╗                          ║
║                                    ██║    ██║██╔══██╗████╗ ████║                          ║
║                                    ██║ █╗ ██║██║  ██║██╔████╔██║                          ║
║                                    ██║███╗██║██║  ██║██║╚██╔╝██║                          ║
║                                    ╚███╔███╔╝██████╔╝██║ ╚═╝ ██║                          ║
║                                     ╚══╝╚══╝ ╚═════╝ ╚═╝     ╚═╝                          ║
║                                                                                          ║
║                              ─── PROYECTO LAZARUS ───                                    ║
║                                                                                          ║
║                    "Donde el software se rinde, la lógica prevalece."                    ║
║                                                                                          ║
║                     Biopsia profunda de 105 sectores críticos del sistema                ║
║                                                                                          ║
╚══════════════════════════════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
Write-Host "                                                                                      v1.0 | Windows de Mente" -ForegroundColor DarkGray

# ==============================================
# HARDWARE DETECTION
# ==============================================
Write-Host "`n┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│  📊 INVENTARIO DE HARDWARE                                                                                        │" -ForegroundColor Cyan
Write-Host "├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan

$CPU = Get-CimInstance -ClassName Win32_Processor
$Cores = $CPU.NumberOfCores
$LogicalProcessors = $CPU.NumberOfLogicalProcessors
$CPUFreq = [math]::Round($CPU.MaxClockSpeed / 1000, 1)
$TotalRAMGB = [math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 0)

$DiskType = "HDD"
try {
    $PhysicalDisks = Get-PhysicalDisk -ErrorAction SilentlyContinue
    foreach ($disk in $PhysicalDisks) {
        if ($disk.MediaType -eq "HDD" -or $disk.MediaType -eq 3 -or $disk.RotationSpeed -gt 0) { $DiskType = "HDD"; break }
        elseif ($disk.MediaType -eq "SSD" -or $disk.MediaType -eq 4 -or $disk.MediaType -eq 5 -or $disk.BusType -eq "NVMe") { $DiskType = "SSD/NVMe"; break }
    }
} catch { $DiskType = "Desconocido" }

$GPU = Get-CimInstance -ClassName Win32_VideoController | Where-Object { $_.Name -notlike "*Mirror*" -and $_.Name -notlike "*Remote*" } | Select-Object -First 1
$GPURAM = if ($GPU.AdapterRAM) { [math]::Round($GPU.AdapterRAM / 1GB, 0) } else { 0 }

$HardwareProfile = "⚖️ CLÁSICO"
if ($DiskType -eq "HDD" -or $TotalRAMGB -le 4 -or $Cores -le 2) { $HardwareProfile = "🪶 LIVIANO (pero guerrero)" }
elseif (($DiskType -eq "SSD/NVMe") -and $TotalRAMGB -ge 16 -and $Cores -ge 6) { $HardwareProfile = "🔥 EL MONSTRUO" }

Write-Host "│  • CPU:  $($CPU.Name)" -ForegroundColor Gray
Write-Host "│         $Cores núcleos / $LogicalProcessors hilos | ${CPUFreq}GHz" -ForegroundColor DarkGray
Write-Host "│  • RAM:  ${TotalRAMGB}GB" -ForegroundColor Gray
Write-Host "│  • DISCO: $DiskType" -ForegroundColor Gray
Write-Host "│  • GPU:  $($GPU.Name) | VRAM: ${GPURAM}GB" -ForegroundColor Gray
Write-Host "│  • PERFIL: $HardwareProfile" -ForegroundColor $(if ($HardwareProfile -like "*LIVIANO*") { "Yellow" } elseif ($HardwareProfile -like "*MONSTRUO*") { "Green" } else { "Cyan" })
Write-Host "└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan

# ==============================================
# FUNCIÓN
# ==============================================
function Write-DiagRow {
    param($Sector, $Actual, $Recomendado, $Impacto, $Estado)
    $color = if ($Estado -eq "OK") { "Green" } else { "Yellow" }
    Write-Host ("│ {0,-42} │ {1,-22} │ {2,-18} │ {3,-24} │   {4,-3}   " -f $Sector, $Actual, $Recomendado, $Impacto, $Estado) -ForegroundColor $color
}

$opts = @()
$global:CurrentValue = $null

# ==============================================
# GRUPO 1: PROCESOS Y PRIORIDADES (6)
# ==============================================
Write-Host "`n┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│  🔹 GRUPO 1: PROCESOS Y PRIORIDADES (6)                                                                         │" -ForegroundColor Magenta
Write-Host "├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
Write-Host ("│ {0,-42} │ {1,-22} │ {2,-18} │ {3,-24} │ {4,-3}" -f "SECTOR", "VALOR ACTUAL", "RECOMENDADO", "IMPACTO", " ") -ForegroundColor DarkGray
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray

# 1. I/O Priority
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "IoPriority" -ErrorAction SilentlyContinue).IoPriority
$rec = if ($TotalRAMGB -le 4) { 0 } else { 3 }; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="I/O Priority"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name="IoPriority"; Current=$val; Rec=$rec; Type="DWord"; Desc="Prioridad de entrada/salida"} }
Write-DiagRow "I/O Priority" $(if ($val) { $val } else { "3" }) $rec "Respuesta de disco" $estado

# 2. Priority Separation
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -ErrorAction SilentlyContinue).Win32PrioritySeparation
$rec = if ($Cores -le 2) { 18 } elseif ($Cores -ge 8) { 38 } else { 26 }; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Priority Separation"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name="Win32PrioritySeparation"; Current=$val; Rec=$rec; Type="DWord"; Desc="Distribución de tiempo de CPU"} }
Write-DiagRow "Priority Separation" $(if ($val) { $val } else { "18" }) $rec "Quantum de procesos" $estado

# 3. Worker Threads
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Executive" -Name "AdditionalCriticalWorkerThreads" -ErrorAction SilentlyContinue).AdditionalCriticalWorkerThreads
$rec = if ($Cores -ge 8) { 4 } else { 0 }; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Worker Threads"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Executive"; Name="AdditionalCriticalWorkerThreads"; Current=$val; Rec=$rec; Type="DWord"; Desc="Hilos para tareas críticas"} }
Write-DiagRow "Worker Threads" $(if ($val) { $val } else { "0" }) $rec "Hilos del sistema" $estado

# 4. Critical Timeout
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "CriticalSectionTimeout" -ErrorAction SilentlyContinue).CriticalSectionTimeout
$rec = if ($Cores -le 2) { "10s" } else { "5s" }; $estado = "OPT"
if ($estado -eq "OPT") { $opts += @{Target="Critical Timeout"; Path="HKLM:\SYSTEM\CurrentControlSet\Control"; Name="CriticalSectionTimeout"; Current=$(if ($val) { $val } else { 30000 }); Rec=$(if ($Cores -le 2) { 10000 } else { 5000 }); Type="DWord"; Desc="Tiempo antes de considerar un proceso como no respondiendo"} }
Write-DiagRow "Critical Timeout" $(if ($val) { "$($val/1000)s" } else { "30s" }) $rec "Evita congelamiento" $estado

# 5. Foreground Priority
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "ForegroundPriority" -ErrorAction SilentlyContinue).ForegroundPriority
$rec = 2; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Foreground Priority"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name="ForegroundPriority"; Current=$val; Rec=$rec; Type="DWord"; Desc="Prioridad de la app activa"} }
Write-DiagRow "Foreground Priority" $(if ($val) { $val } else { "2" }) $rec "Prioridad app activa" $estado

# 6. Background Priority
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "BackgroundPriority" -ErrorAction SilentlyContinue).BackgroundPriority
$rec = 0; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Background Priority"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name="BackgroundPriority"; Current=$val; Rec=$rec; Type="DWord"; Desc="Prioridad de apps en segundo plano"} }
Write-DiagRow "Background Priority" $(if ($val) { $val } else { "0" }) $rec "Prioridad fondo" $estado

# ==============================================
# GRUPO 2: MEMORIA Y CACHÉ (8)
# ==============================================
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray
Write-Host "│  🔹 GRUPO 2: MEMORIA Y CACHÉ (8)                                                                                │" -ForegroundColor Magenta
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray

# 7. GDI Handles
$val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" -Name "GDIProcessHandleLimit" -ErrorAction SilentlyContinue).GDIProcessHandleLimit
$rec = if ($TotalRAMGB -ge 16) { 15000 } elseif ($TotalRAMGB -le 4) { 5000 } else { 10000 }; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="GDI Handles"; Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows"; Name="GDIProcessHandleLimit"; Current=$val; Rec=$rec; Type="DWord"; Desc="Límite de objetos gráficos por proceso"} }
Write-DiagRow "GDI Handles" $(if ($val) { $val } else { "10000" }) $rec "Fluidez visual" $estado

# 8. NTFS Memory Usage
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsMemoryUsage" -ErrorAction SilentlyContinue).NtfsMemoryUsage
$rec = if ($DiskType -eq "HDD") { 2 } else { 1 }; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="NTFS Memory Usage"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"; Name="NtfsMemoryUsage"; Current=$val; Rec=$rec; Type="DWord"; Desc="Caché de metadatos NTFS"} }
Write-DiagRow "NTFS Memory Usage" $(if ($val) { $val } else { "1" }) $rec "Acceso miles archivos" $estado

# 9. DisablePagingExecutive
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -ErrorAction SilentlyContinue).DisablePagingExecutive
$rec = if ($TotalRAMGB -ge 8) { 1 } else { 0 }; $act = if ($val -eq 1) { "Activado" } else { "Desactivado" }; $rc = if ($rec -eq 1) { "Activado" } else { "Desactivado" }; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="DisablePagingExecutive"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="DisablePagingExecutive"; Current=$val; Rec=$rec; Type="DWord"; Desc="Drivers del kernel en RAM (no en disco)"} }
Write-DiagRow "DisablePagingExecutive" $act $rc "Drivers en RAM" $estado

# 10. LargeSystemCache
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -ErrorAction SilentlyContinue).LargeSystemCache
$rec = if ($TotalRAMGB -ge 16) { 1 } else { 0 }; $act = if ($val -eq 1) { "Activado" } else { "Desactivado" }; $rc = if ($rec -eq 1) { "Activado" } else { "Desactivado" }; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="LargeSystemCache"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="LargeSystemCache"; Current=$val; Rec=$rec; Type="DWord"; Desc="Tamaño de la caché del sistema"} }
Write-DiagRow "LargeSystemCache" $act $rc "Caché sistema" $estado

# 11. I/O Page Lock Limit
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "IOPageLockLimit" -ErrorAction SilentlyContinue).IOPageLockLimit
$rec = 0; $estado = "OK"
Write-DiagRow "I/O Page Lock Limit" $(if ($val) { "$([math]::Round($val/1024))KB" } else { "Default" }) "Default" "Operaciones E/S" "OK"

# 12. PagedPoolSize
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "PagedPoolSize" -ErrorAction SilentlyContinue).PagedPoolSize
$rec = 0; $estado = "OK"
Write-DiagRow "Paged Pool Size" $(if ($val) { "$([math]::Round($val/1MB))MB" } else { "Dinámico" }) "Dinámico" "Estructuras kernel" "OK"

# 13. NonPagedPoolSize
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "NonPagedPoolSize" -ErrorAction SilentlyContinue).NonPagedPoolSize
$estado = "OK"
Write-DiagRow "NonPaged Pool Size" $(if ($val) { "$([math]::Round($val/1MB))MB" } else { "Dinámico" }) "Dinámico" "Memoria crítica driver" "OK"

# 14. Write Combining
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "WriteCombining" -ErrorAction SilentlyContinue).WriteCombining
$rec = 1; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Write Combining"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="WriteCombining"; Current=$val; Rec=$rec; Type="DWord"; Desc="Optimización de escritura gráfica"} }
Write-DiagRow "Write Combining" $(if ($val -eq 1) { "Activado" } else { "Desactivado" }) "Activado" "Escritura gráficos" $estado

# ==============================================
# GRUPO 3: PERIFÉRICOS (5)
# ==============================================
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray
Write-Host "│  🔹 GRUPO 3: PERIFÉRICOS (5)                                                                                   │" -ForegroundColor Magenta
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray

# 15. Mouse Queue
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" -Name "MouseDataQueueSize" -ErrorAction SilentlyContinue).MouseDataQueueSize
$rec = 200; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Mouse Queue"; Path="HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters"; Name="MouseDataQueueSize"; Current=$val; Rec=$rec; Type="DWord"; Desc="Búfer de eventos del mouse"} }
Write-DiagRow "Mouse Queue" $(if ($val) { $val } else { "100" }) $rec "Clics perdidos" $estado

# 16. Keyboard Queue
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" -Name "KeyboardDataQueueSize" -ErrorAction SilentlyContinue).KeyboardDataQueueSize
$rec = 200; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Keyboard Queue"; Path="HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters"; Name="KeyboardDataQueueSize"; Current=$val; Rec=$rec; Type="DWord"; Desc="Búfer de eventos del teclado"} }
Write-DiagRow "Keyboard Queue" $(if ($val) { $val } else { "100" }) $rec "Teclas perdidas" $estado

# 17. Keyboard Delay
$val = (Get-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -ErrorAction SilentlyContinue).KeyboardDelay
$rec = 0; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Keyboard Repeat Delay"; Path="HKCU:\Control Panel\Keyboard"; Name="KeyboardDelay"; Current=$val; Rec=$rec; Type="String"; Desc="Tiempo antes de repetir tecla"} }
Write-DiagRow "Keyboard Repeat Delay" $(if ($val) { $val } else { "1" }) $rec "Teclas al borrar" $estado

# 18. Keyboard Speed
$val = (Get-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardSpeed" -ErrorAction SilentlyContinue).KeyboardSpeed
$rec = 31; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Keyboard Repeat Speed"; Path="HKCU:\Control Panel\Keyboard"; Name="KeyboardSpeed"; Current=$val; Rec=$rec; Type="String"; Desc="Velocidad de repetición de tecla"} }
Write-DiagRow "Keyboard Repeat Speed" $(if ($val) { $val } else { "31" }) $rec "Velocidad repetición" $estado

# 19. USB Selective Suspend
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USB" -Name "DisableSelectiveSuspend" -ErrorAction SilentlyContinue).DisableSelectiveSuspend
$rec = 1; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="USB Selective Suspend"; Path="HKLM:\SYSTEM\CurrentControlSet\Services\USB"; Name="DisableSelectiveSuspend"; Current=$val; Rec=$rec; Type="DWord"; Desc="Ahorro de energía USB (causa lag)"} }
Write-DiagRow "USB Selective Suspend" $(if ($val -eq 1) { "Desactivado" } else { "Activado" }) "Desactivado" "Lag mouse/teclado" $estado

# ==============================================
# GRUPO 4: LATENCIA Y DPC (4)
# ==============================================
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray
Write-Host "│  🔹 GRUPO 4: LATENCIA Y DPC (4)                                                                                 │" -ForegroundColor Magenta
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray

# 20. Timer Resolution
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "TimerResolution" -ErrorAction SilentlyContinue).TimerResolution
$estado = "OPT"
Write-DiagRow "Timer Resolution" $(if ($val) { "$($val/10000)ms" } else { "15.6ms" }) "0.5ms" "Fluidez global" $estado

# 21. Startup Delay
$val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Name "StartupDelayInMSec" -ErrorAction SilentlyContinue).StartupDelayInMSec
$rec = 0; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Startup Delay"; Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize"; Name="StartupDelayInMSec"; Current=$val; Rec=$rec; Type="DWord"; Desc="Retraso al mostrar el escritorio"} }
Write-DiagRow "Startup Delay" $(if ($val) { "$($val)ms" } else { "No configurado" }) $rec "Boot más rápido" $estado

# 22. Menu Show Delay
$val = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -ErrorAction SilentlyContinue).MenuShowDelay
$rec = 10; $estado = if ($val -le 10) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Menu Show Delay"; Path="HKCU:\Control Panel\Desktop"; Name="MenuShowDelay"; Current=$val; Rec=$rec; Type="String"; Desc="Tiempo de apertura de menús"} }
Write-DiagRow "Menu Show Delay" $(if ($val) { "$($val)ms" } else { "400ms" }) $rec "Menús instantáneos" $estado

# 23. System Responsiveness
$val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -ErrorAction SilentlyContinue).SystemResponsiveness
$rec = 10; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="System Responsiveness"; Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Name="SystemResponsiveness"; Current=$val; Rec=$rec; Type="DWord"; Desc="Capacidad de respuesta a tareas multimedia"} }
Write-DiagRow "System Responsiveness" $(if ($val) { $val } else { "10" }) $rec "Apps multimedia" $estado

# ==============================================
# GRUPO 5: SERVICIOS (8)
# ==============================================
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray
Write-Host "│  🔹 GRUPO 5: SERVICIOS (8)                                                                                     │" -ForegroundColor Magenta
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray

# 24. DiagTrack
$svc = Get-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
$act = if ($svc -and $svc.StartType -eq "Disabled") { "Desactivado" } else { "Activado" }; $estado = if ($act -eq "Desactivado") { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="DiagTrack (Telemetría)"; Service="DiagTrack"; Current=$act; Rec="Desactivado"; Desc="Recolección de datos de diagnóstico"} }
Write-DiagRow "DiagTrack (Telemetría)" $act "Desactivado" "CPU + escrituras" $estado

# 25. Windows Search
$svc = Get-Service -Name "WSearch" -ErrorAction SilentlyContinue
$act = if ($svc -and $svc.StartType -eq "Disabled") { "Desactivado" } else { "Activado" }; $estado = if ($act -eq "Desactivado") { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Windows Search"; Service="WSearch"; Current=$act; Rec="Desactivado"; Desc="Indexador de archivos"} }
Write-DiagRow "Windows Search" $act "Desactivado" "Índice archivos" $estado

# 26. SysMain
$svc = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue
$act = if ($svc -and $svc.StartType -eq "Disabled") { "Desactivado" } else { "Activado" }; $rec = if ($DiskType -eq "HDD") { "Activado" } else { "Desactivado" }; $estado = if ($act -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="SysMain (Superfetch)"; Service="SysMain"; Current=$act; Rec=$rec; Desc="Prefetch de aplicaciones"} }
Write-DiagRow "SysMain (Superfetch)" $act $rec "Prefetch disco" $estado

# 27. Spooler
$svc = Get-Service -Name "Spooler" -ErrorAction SilentlyContinue
$act = if ($svc -and $svc.StartType -eq "Disabled") { "Desactivado" } else { "Activado" }; $estado = if ($act -eq "Desactivado") { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Print Spooler"; Service="Spooler"; Current=$act; Rec="Desactivado"; Desc="Servicio de impresión"} }
Write-DiagRow "Print Spooler" $act "Desactivado" "RAM + CPU" $estado

# 28. WerSvc
$svc = Get-Service -Name "WerSvc" -ErrorAction SilentlyContinue
$act = if ($svc -and $svc.StartType -eq "Disabled") { "Desactivado" } else { "Activado" }; $estado = if ($act -eq "Desactivado") { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Windows Error Reporting"; Service="WerSvc"; Current=$act; Rec="Desactivado"; Desc="Reporte de errores"} }
Write-DiagRow "Windows Error Reporting" $act "Desactivado" "Recolección fallos" $estado

# 29. BITS
$svc = Get-Service -Name "BITS" -ErrorAction SilentlyContinue
$act = if ($svc -and $svc.StartType -eq "Disabled") { "Desactivado" } else { "Activado" }; $estado = if ($act -eq "Desactivado") { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="BITS"; Service="BITS"; Current=$act; Rec="Desactivado"; Desc="Transferencias en segundo plano"} }
Write-DiagRow "BITS (Background Transfer)" $act "Desactivado" "Descargas fondo" $estado

# 30. WaitToKillServiceTimeout
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillServiceTimeout" -ErrorAction SilentlyContinue).WaitToKillServiceTimeout
$rec = 5000; $estado = if ($val -le $rec -or $DiskType -eq "HDD") { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="WaitToKillServiceTimeout"; Path="HKLM:\SYSTEM\CurrentControlSet\Control"; Name="WaitToKillServiceTimeout"; Current=$val; Rec=$rec; Type="String"; Desc="Tiempo de cierre de servicios al apagar"} }
Write-DiagRow "WaitToKillServiceTimeout" $(if ($val) { "$($val)ms" } else { "20000ms" }) "5000ms" "Apagado rápido" $estado

# 31. Font Cache
$svc = Get-Service -Name "FontCache" -ErrorAction SilentlyContinue
$act = if ($svc -and $svc.StartType -eq "Disabled") { "Desactivado" } else { "Activado" }; $estado = if ($act -eq "Activado") { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Font Cache"; Service="FontCache"; Current=$act; Rec="Activado"; Desc="Caché de fuentes del sistema"} }
Write-DiagRow "Font Cache" $act "Activado" "Renderizado fuentes" $estado

# ==============================================
# GRUPO 6: SERVICIOS XBOX (3)
# ==============================================
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray
Write-Host "│  🔹 GRUPO 6: SERVICIOS XBOX (3)                                                                                │" -ForegroundColor Magenta
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray

# 32. XblAuthManager
$svc = Get-Service -Name "XblAuthManager" -ErrorAction SilentlyContinue
$act = if ($svc -and $svc.StartType -ne "Disabled") { "Activado" } else { "Desactivado" }; $estado = if ($act -eq "Desactivado") { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="XblAuthManager"; Service="XblAuthManager"; Current=$act; Rec="Desactivado"; Desc="Autenticación de Xbox"} }
Write-DiagRow "XblAuthManager" $act "Desactivado" "Recursos CPU/RAM" $estado

# 33. XboxNetApiSvc
$svc = Get-Service -Name "XboxNetApiSvc" -ErrorAction SilentlyContinue
$act = if ($svc -and $svc.StartType -ne "Disabled") { "Activado" } else { "Desactivado" }; $estado = if ($act -eq "Desactivado") { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="XboxNetApiSvc"; Service="XboxNetApiSvc"; Current=$act; Rec="Desactivado"; Desc="Red de Xbox"} }
Write-DiagRow "XboxNetApiSvc" $act "Desactivado" "Recursos CPU/RAM" $estado

# 34. XblGameSave
$svc = Get-Service -Name "XblGameSave" -ErrorAction SilentlyContinue
$act = if ($svc -and $svc.StartType -ne "Disabled") { "Activado" } else { "Desactivado" }; $estado = if ($act -eq "Desactivado") { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="XblGameSave"; Service="XblGameSave"; Current=$act; Rec="Desactivado"; Desc="Guardado en la nube de Xbox"} }
Write-DiagRow "XblGameSave" $act "Desactivado" "Recursos CPU/RAM" $estado

# ==============================================
# GRUPO 7: ENERGÍA Y PCIe (5)
# ==============================================
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray
Write-Host "│  🔹 GRUPO 7: ENERGÍA Y PCIe (5)                                                                                │" -ForegroundColor Magenta
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray

# 35. ASPM
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "AspmPolicy" -ErrorAction SilentlyContinue).AspmPolicy
$act = if ($val -eq 0) { "Desactivado" } elseif ($val -eq 1) { "Activado" } else { "Default" }; $rec = if ($HardwareProfile -eq "🔥 EL MONSTRUO") { "Desactivado" } else { "Activado" }; $estado = if ($act -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="ASPM"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\Power"; Name="AspmPolicy"; Current=$(if ($val) { if ($val -eq 0) { "Desactivado" } else { "Activado" } } else { "Default" }); Rec=$(if ($HardwareProfile -eq "🔥 EL MONSTRUO") { 0 } else { 1 }); Type="DWord"; Desc="Ahorro de energía en PCIe (causa latencia)"} }
Write-DiagRow "ASPM (PCIe)" $act $rec "Latencia GPU/NVMe" $estado

# 36. SATA DIPM
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\msahci\Controller0\Channel0" -Name "EnableDIPM" -ErrorAction SilentlyContinue).EnableDIPM
$act = if ($val -eq 0) { "Desactivado" } else { "Activado" }; $rec = if ($DiskType -eq "HDD") { "Desactivado" } else { "Activado" }; $estado = if ($act -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="SATA DIPM"; Path="HKLM:\SYSTEM\CurrentControlSet\Services\msahci\Controller0\Channel0"; Name="EnableDIPM"; Current=$val; Rec=$(if ($DiskType -eq "HDD") { 0 } else { 1 }); Type="DWord"; Desc="Ahorro de energía en SATA (causa lag al despertar)"} }
Write-DiagRow "SATA DIPM/HIPM" $act $rec "Lag al despertar" $estado

# 37. Power Scheme
$val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Power" -Name "ActivePowerScheme" -ErrorAction SilentlyContinue).ActivePowerScheme
$highPerfGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
$act = if ($val -eq $highPerfGuid) { "Alto Rendimiento" } else { "Equilibrado" }; $estado = if ($act -eq "Alto Rendimiento") { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Power Scheme"; Current=$act; Rec="Alto Rendimiento"; IsPower=1; Desc="Plan de energía del sistema"} }
Write-DiagRow "Power Scheme" $act "Alto Rendimiento" "Rendimiento general" $estado

# 38. Maintenance Wakeup
$val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" -Name "WakeupEnabled" -ErrorAction SilentlyContinue).WakeupEnabled
$act = if ($val -eq 0) { "Desactivado" } else { "Activado" }; $estado = if ($act -eq "Desactivado") { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Maintenance Wakeup"; Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance"; Name="WakeupEnabled"; Current=$val; Rec=0; Type="DWord"; Desc="Mantenimiento automático despierta la PC"} }
Write-DiagRow "Maintenance Wakeup" $act "Desactivado" "PC despertándose" $estado

# 39. Fast Startup (Hiberboot)
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -ErrorAction SilentlyContinue).HiberbootEnabled
$act = if ($val -eq 1) { "Activado" } else { "Desactivado" }; $rec = if ($DiskType -eq "HDD") { "Desactivado" } else { "Activado" }; $estado = if ($act -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Fast Startup (Hiberboot)"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"; Name="HiberbootEnabled"; Current=$val; Rec=$(if ($DiskType -eq "HDD") { 0 } else { 1 }); Type="DWord"; Desc="Inicio rápido híbrido"} }
Write-DiagRow "Fast Startup (Hiberboot)" $act $rec "Tiempo de boot" $estado

# ==============================================
# GRUPO 8: REGISTRO Y KERNEL (6)
# ==============================================
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray
Write-Host "│  🔹 GRUPO 8: REGISTRO Y KERNEL (6)                                                                             │" -ForegroundColor Magenta
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray

# 40. Autologgers
$autologgers = Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger" -ErrorAction SilentlyContinue | Where-Object { (Get-ItemProperty -Path $_.PSPath -Name "Start" -ErrorAction SilentlyContinue).Start -eq 1 }
$count = ($autologgers | Measure-Object).Count; $estado = if ($count -le 3) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Autologgers"; Current="$count activos"; Rec="Desactivar"; IsAutoLogger=1; Desc="Rastreo del kernel escribiendo en disco"} }
Write-DiagRow "Autologgers (Kernel Logs)" "$count activos" "0 o mínimo" "Escritura disco" $estado

# 41. Registry Lazy Flush
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager" -Name "RegistryLazyFlushInterval" -ErrorAction SilentlyContinue).RegistryLazyFlushInterval
$rec = if ($DiskType -eq "HDD") { 15 } else { 5 }; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Registry Lazy Flush"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager"; Name="RegistryLazyFlushInterval"; Current=$val; Rec=$rec; Type="DWord"; Desc="Frecuencia de escritura del registro"} }
Write-DiagRow "Registry Lazy Flush" $(if ($val) { "$($val)s" } else { "5s" }) "$rec"s "Frecuencia escritura" $estado

# 42. AlwaysUnloadDll (ya está arriba, no duplicar)
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "AlwaysUnloadDll" -ErrorAction SilentlyContinue).AlwaysUnloadDll
$rec = if ($TotalRAMGB -le 4) { 1 } else { 0 }; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="AlwaysUnloadDll (DLLs)"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="AlwaysUnloadDll"; Current=$val; Rec=$rec; Type="DWord"; Desc="Libera DLLs al cerrar apps"} }
Write-DiagRow "AlwaysUnloadDll (DLLs)" $(if ($val -eq 1) { "Activado" } else { "Desactivado" }) $(if ($rec -eq 1) { "Activado" } else { "Desactivado" }) "Libera DLLs" $estado

# 43. Pool Tagging
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "PoolTagging" -ErrorAction SilentlyContinue).PoolTagging
$rec = 0; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Pool Tagging"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="PoolTagging"; Current=$val; Rec=$rec; Type="DWord"; Desc="Rastreo de memoria por driver"} }
Write-DiagRow "Pool Tagging" $(if ($val -eq 0) { "Desactivado" } else { "Activado" }) "Desactivado" "Rastreo memoria" $estado

# 44. Kernel Stack Size
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "KernelStackSize" -ErrorAction SilentlyContinue).KernelStackSize
$rec = if ($TotalRAMGB -le 4) { 24 } else { 48 }; $estado = if (($val/1024) -ge $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Kernel Stack Size"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="KernelStackSize"; Current=$val; Rec=($rec*1024); Type="DWord"; Desc="Pila de memoria para hilos del kernel"} }
Write-DiagRow "Kernel Stack Size" $(if ($val) { "$($val/1024)KB" } else { "12KB" }) "${rec}KB" "Hilos kernel" $estado

# 45. Memory Compression
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisableMemoryCompression" -ErrorAction SilentlyContinue).DisableMemoryCompression
$rec = if ($Cores -le 4 -and $TotalRAMGB -le 4) { 1 } else { 0 }; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Memory Compression"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="DisableMemoryCompression"; Current=$val; Rec=$rec; Type="DWord"; Desc="Compresión de RAM (quita CPU)"} }
Write-DiagRow "Memory Compression" $(if ($val -eq 1) { "Desactivado" } else { "Activado" }) $(if ($rec -eq 1) { "Desactivado" } else { "Activado" }) "Compresión RAM" $estado

# ==============================================
# GRUPO 9: RED Y CONECTIVIDAD (6)
# ==============================================
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray
Write-Host "│  🔹 GRUPO 9: RED Y CONECTIVIDAD (6)                                                                            │" -ForegroundColor Magenta
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray

# 46. RSS
$rss = Get-NetAdapterRss -ErrorAction SilentlyContinue | Where-Object { $_.Enabled -eq $true }
$act = if ($rss.Count -gt 0) { "Activado" } else { "Desactivado" }; $rec = if ($Cores -gt 4) { "Activado" } else { "Desactivado" }; $estado = if ($act -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="RSS"; Current=$act; Rec=$rec; IsRSS=1; Desc="Distribución de carga de red en CPU"} }
Write-DiagRow "RSS (Receive Side Scaling)" $act $rec "Carga red CPU" $estado

# 47. TCP Autotuning
$tcpAuto = (Get-NetTCPSetting -SettingName Internet -ErrorAction SilentlyContinue).AutoTuningLevelLocal
$rec = "Normal"; $estado = if ($tcpAuto -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="TCP Autotuning"; Current=$tcpAuto; Rec="Normal"; IsTCPAuto=1; Desc="Velocidad de descarga"} }
Write-DiagRow "TCP Autotuning" $tcpAuto $rec "Velocidad descarga" $estado

# 48. TCP Window Scaling (Tcp1323Opts)
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "Tcp1323Opts" -ErrorAction SilentlyContinue).Tcp1323Opts
$rec = 1; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="TCP Window Scaling"; Path="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name="Tcp1323Opts"; Current=$val; Rec=$rec; Type="DWord"; Desc="Ventana TCP para altas velocidades"} }
Write-DiagRow "TCP Window Scaling" $(if ($val) { $val } else { "1" }) $rec "Ventana TCP" $estado

# 49. TCP No Delay
$val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\MSMQ\Parameters" -Name "TCPNoDelay" -ErrorAction SilentlyContinue).TCPNoDelay
$rec = 1; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="TCP No Delay"; Path="HKLM:\SOFTWARE\Microsoft\MSMQ\Parameters"; Name="TCPNoDelay"; Current=$val; Rec=$rec; Type="DWord"; Desc="Reducción de latencia en red"} }
Write-DiagRow "TCP No Delay" $(if ($val -eq 1) { "Activado" } else { "Desactivado" }) "Activado" "Latencia red" $estado

# 50. ICMP Redirect
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "EnableICMPRedirect" -ErrorAction SilentlyContinue).EnableICMPRedirect
$rec = 0; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="ICMP Redirect"; Path="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name="EnableICMPRedirect"; Current=$val; Rec=$rec; Type="DWord"; Desc="Seguridad de red"} }
Write-DiagRow "ICMP Redirect" $(if ($val -eq 0) { "Desactivado" } else { "Activado" }) "Desactivado" "Seguridad red" $estado

# 51. Dead Gateway Detect
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "EnableDeadGWDetect" -ErrorAction SilentlyContinue).EnableDeadGWDetect
$rec = 0; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Dead Gateway Detect"; Path="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name="EnableDeadGWDetect"; Current=$val; Rec=$rec; Type="DWord"; Desc="Detección de gateways caídos"} }
Write-DiagRow "Dead Gateway Detect" $(if ($val -eq 0) { "Desactivado" } else { "Activado" }) "Desactivado" "Redundancia" $estado

# ==============================================
# GRUPO 10: DISCO (NTFS) (9)
# ==============================================
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray
Write-Host "│  🔹 GRUPO 10: DISCO (NTFS) (9)                                                                                 │" -ForegroundColor Magenta
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray

# 52. EnablePrefetcher
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -ErrorAction SilentlyContinue).EnablePrefetcher
$rec = if ($DiskType -eq "HDD") { 3 } else { 0 }; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="EnablePrefetcher"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"; Name="EnablePrefetcher"; Current=$val; Rec=$rec; Type="DWord"; Desc="Prefetch de archivos al boot"} }
Write-DiagRow "EnablePrefetcher" $(if ($val) { $val } else { "3" }) $rec "Tiempo de boot" $estado

# 53. EnableSuperfetch
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnableSuperfetch" -ErrorAction SilentlyContinue).EnableSuperfetch
$rec = if ($DiskType -eq "HDD") { 3 } else { 0 }; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="EnableSuperfetch"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"; Name="EnableSuperfetch"; Current=$val; Rec=$rec; Type="DWord"; Desc="Caché de aplicaciones"} }
Write-DiagRow "EnableSuperfetch" $(if ($val) { $val } else { "3" }) $rec "Caché apps" $estado

# 54. Last Access Update
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisableLastAccessUpdate" -ErrorAction SilentlyContinue).NtfsDisableLastAccessUpdate
$rec = 1; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Last Access Update"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"; Name="NtfsDisableLastAccessUpdate"; Current=$val; Rec=$rec; Type="DWord"; Desc="Escritura de fecha al leer archivos"} }
Write-DiagRow "Last Access Update" $(if ($val -eq 1) { "Desactivado" } else { "Activado" }) "Desactivado" "Escritura al leer" $estado

# 55. MFT Zone Reservation
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsMftZoneReservation" -ErrorAction SilentlyContinue).NtfsMftZoneReservation
$rec = if ($DiskType -eq "HDD") { 2 } else { 1 }; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="MFT Zone Reservation"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"; Name="NtfsMftZoneReservation"; Current=$val; Rec=$rec; Type="DWord"; Desc="Reserva de espacio para la tabla de archivos"} }
Write-DiagRow "MFT Zone Reservation" $(if ($val) { $val } else { "1" }) $rec "Fragmentación índice" $estado

# 56. 8.3 Short Names
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisable8dot3NameCreation" -ErrorAction SilentlyContinue).NtfsDisable8dot3NameCreation
$rec = 1; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="8.3 Short Names"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"; Name="NtfsDisable8dot3NameCreation"; Current=$val; Rec=$rec; Type="DWord"; Desc="Nombres cortos tipo PROGRA~1"} }
Write-DiagRow "8.3 Short Names" $(if ($val -eq 1) { "Desactivado" } else { "Activado" }) "Desactivado" "Doble nombre" $estado

# 57. NameCache (Path Cache)
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NameCache" -ErrorAction SilentlyContinue).NameCache
$rec = 10; $estado = if ($val -ge $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="NameCache (Path Cache)"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"; Name="NameCache"; Current=$val; Rec=$rec; Type="DWord"; Desc="Caché de rutas de archivos"} }
Write-DiagRow "NameCache (Path Cache)" $(if ($val) { $val } else { "5" }) "10+" "Búsqueda archivos" $estado

# 58. DirectoryCache (Info Cache)
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "DirectoryCache" -ErrorAction SilentlyContinue).DirectoryCache
$rec = 10; $estado = if ($val -ge $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="DirectoryCache (Info Cache)"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"; Name="DirectoryCache"; Current=$val; Rec=$rec; Type="DWord"; Desc="Caché de metadatos de directorios"} }
Write-DiagRow "DirectoryCache (Info Cache)" $(if ($val) { $val } else { "5" }) "10+" "Metadatos" $estado

# 59. NTFS Compression
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisableCompression" -ErrorAction SilentlyContinue).NtfsDisableCompression
$rec = 1; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="NTFS Compression"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"; Name="NtfsDisableCompression"; Current=$val; Rec=$rec; Type="DWord"; Desc="Compresión de archivos (consume CPU)"} }
Write-DiagRow "NTFS Compression" $(if ($val -eq 1) { "Desactivado" } else { "Activado" }) "Desactivado" "Compresión" $estado

# 60. NTFS Encryption
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisableEncryption" -ErrorAction SilentlyContinue).NtfsDisableEncryption
$rec = 0; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="NTFS Encryption"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"; Name="NtfsDisableEncryption"; Current=$val; Rec=$rec; Type="DWord"; Desc="Cifrado de archivos (EFS)"} }
Write-DiagRow "NTFS Encryption" $(if ($val -eq 1) { "Desactivado" } else { "Activado" }) "Activado" "Cifrado" $estado

# ==============================================
# GRUPO 11: GPU Y GRÁFICOS (5)
# ==============================================
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray
Write-Host "│  🔹 GRUPO 11: GPU Y GRÁFICOS (5)                                                                               │" -ForegroundColor Magenta
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray

# 61. MMCSS GPU Priority (Games)
$val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "GPU Priority" -ErrorAction SilentlyContinue)."GPU Priority"
$rec = 8; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="MMCSS GPU Priority"; Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Name="GPU Priority"; Current=$val; Rec=$rec; Type="DWord"; Desc="Prioridad de GPU para juegos"} }
Write-DiagRow "MMCSS GPU Priority" $(if ($val) { $val } else { "No configurado" }) $rec "Rendimiento juegos" $estado

# 62. TDR Delay
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "TdrDelay" -ErrorAction SilentlyContinue).TdrDelay
$rec = 8; $estado = if ($val -ge $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="TDR Delay"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"; Name="TdrDelay"; Current=$val; Rec=$rec; Type="DWord"; Desc="Timeout para controlador de GPU"} }
Write-DiagRow "TDR Delay" $(if ($val) { "$($val)s" } else { "2s" }) "${rec}s" "Evita reseteos" $estado

# 63. DWM Priority
$val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DesktopWindowManager" -Name "Priority" -ErrorAction SilentlyContinue).Priority
$rec = 6; $estado = if ($val -ge $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="DWM Priority"; Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DesktopWindowManager"; Name="Priority"; Current=$val; Rec=$rec; Type="DWord"; Desc="Prioridad del administrador de ventanas"} }
Write-DiagRow "DWM Priority" $(if ($val) { $val } else { "No configurado" }) "$rec (High)" "Fluidez escritorio" $estado

# 64. Font Smoothing
$val = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "FontSmoothing" -ErrorAction SilentlyContinue).FontSmoothing
$rec = 2; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Font Smoothing"; Path="HKCU:\Control Panel\Desktop"; Name="FontSmoothing"; Current=$val; Rec=$rec; Type="String"; Desc="Suavizado de fuentes (ClearType)"} }
Write-DiagRow "Font Smoothing" $(if ($val -eq 2) { "ClearType" } elseif ($val -eq 1) { "Básico" } else { "Desactivado" }) "ClearType" "Nitidez fuentes" $estado

# 65. Font Gamma
$val = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "FontSmoothingGamma" -ErrorAction SilentlyContinue).FontSmoothingGamma
$rec = 1400; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Font Gamma"; Path="HKCU:\Control Panel\Desktop"; Name="FontSmoothingGamma"; Current=$val; Rec=$rec; Type="DWord"; Desc="Contraste del suavizado de fuentes"} }
Write-DiagRow "Font Gamma" $(if ($val) { $val } else { "1000" }) $rec "Contraste fuentes" $estado

# ==============================================
# GRUPO 12: UAC Y SEGURIDAD (4)
# ==============================================
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray
Write-Host "│  🔹 GRUPO 12: UAC Y SEGURIDAD (4)                                                                              │" -ForegroundColor Magenta
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray

# 66. UAC (EnableLUA)
$val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue).EnableLUA
$rec = 1; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="UAC (EnableLUA)"; Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name="EnableLUA"; Current=$val; Rec=$rec; Type="DWord"; Desc="Control de cuentas de usuario"} }
Write-DiagRow "UAC (EnableLUA)" $(if ($val -eq 1) { "Activado" } else { "Desactivado" }) "Activado" "Control cuentas" $estado

# 67. UAC Secure Desktop
$val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -ErrorAction SilentlyContinue).PromptOnSecureDesktop
$rec = 0; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="UAC Secure Desktop"; Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name="PromptOnSecureDesktop"; Current=$val; Rec=$rec; Type="DWord"; Desc="Pantalla segura para prompts UAC"} }
Write-DiagRow "UAC Secure Desktop" $(if ($val -eq 1) { "Activado" } else { "Desactivado" }) "Desactivado" "Pantallazo negro" $estado

# 68. UAC Consent Level
$val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -ErrorAction SilentlyContinue).ConsentPromptBehaviorAdmin
$rec = 5; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="UAC Consent Level"; Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name="ConsentPromptBehaviorAdmin"; Current=$val; Rec=$rec; Type="DWord"; Desc="Comportamiento de los prompts UAC"} }
Write-DiagRow "UAC Consent Level" $(switch ($val) { 0 { "Sin prompt" } 2 { "Prompt sin secure" } 5 { "Prompt con secure" } default { "Default" } }) "Prompt con secure" "Prompts" $estado

# 69. Notifications (Toasts)
$val = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -ErrorAction SilentlyContinue).ToastEnabled
$rec = 1; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Notifications (Toasts)"; Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications"; Name="ToastEnabled"; Current=$val; Rec=$rec; Type="DWord"; Desc="Notificaciones del sistema"} }
Write-DiagRow "Notifications (Toasts)" $(if ($val -eq 1) { "Activado" } else { "Desactivado" }) "Activado" "Notificaciones" $estado

# ==============================================
# GRUPO 13: MITIGACIONES CPU (4)
# ==============================================
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray
Write-Host "│  🔹 GRUPO 13: 🔥 MITIGACIONES CPU (4)                                                                          │" -ForegroundColor Magenta
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray

# 70. Spectre/Meltdown
$pathMM = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
$override = (Get-ItemProperty -Path $pathMM -Name "FeatureSettingsOverride" -ErrorAction SilentlyContinue).FeatureSettingsOverride
$mask = (Get-ItemProperty -Path $pathMM -Name "FeatureSettingsOverrideMask" -ErrorAction SilentlyContinue).FeatureSettingsOverrideMask
$mitigationStatus = if ($override -eq 3 -and $mask -eq 3) { "DESACTIVADAS" } elseif ($override -eq 1) { "PARCIALMENTE" } else { "ACTIVADAS" }
$recStatus = if ($HardwareProfile -eq "🪶 LIVIANO (pero guerrero)") { "DESACTIVAR" } else { "Mantener" }; $estado = if ($override -eq 3 -and $mask -eq 3) { "OK" } else { "OPT" }
if ($estado -eq "OPT" -and $HardwareProfile -eq "🪶 LIVIANO (pero guerrero)") {
    $opts += @{Target="Spectre/Meltdown"; Path=$pathMM; Name="FeatureSettingsOverride"; Current=$override; Rec=3; Type="DWord"; Desc="Desactivar mitigaciones +25% velocidad"}
    $opts += @{Target="Spectre/Meltdown Mask"; Path=$pathMM; Name="FeatureSettingsOverrideMask"; Current=$mask; Rec=3; Type="DWord"; Desc="Máscara para desactivar mitigaciones"}
}
Write-DiagRow "Spectre/Meltdown" $mitigationStatus $recStatus "+25% velocidad" $estado

# 71. Retpoline
$retpoline = (Get-ItemProperty -Path $pathMM -Name "RetpolineEnabled" -ErrorAction SilentlyContinue).RetpolineEnabled
$rpStatus = if ($retpoline -eq 1) { "Activado" } elseif ($override -eq 3) { "Desactivado total" } else { "Default" }
$estado = if ($override -eq 3) { "OK" } else { "OPT" }
Write-DiagRow "CPU Speculation Control" $rpStatus "Desactivado total" "Rendimiento Intel" $estado

# 72. CFG (Control Flow Guard)
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" -Name "DisableExceptionChainValidation" -ErrorAction SilentlyContinue).DisableExceptionChainValidation
$rec = 0; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
Write-DiagRow "Control Flow Guard" $(if ($val -eq 1) { "Desactivado" } else { "Activado" }) "Activado" "Seguridad" "OK"

# 73. Kernel DEP
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "ExecuteDisable" -ErrorAction SilentlyContinue).ExecuteDisable
$rec = 1; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
Write-DiagRow "Kernel DEP" $(if ($val -eq 1) { "Activado" } else { "Desactivado" }) "Activado" "Seguridad" "OK"

# ==============================================
# GRUPO 14: INTERRUPCIONES Y AFINIDAD (4)
# ==============================================
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray
Write-Host "│  🔹 GRUPO 14: INTERRUPCIONES Y AFINIDAD (4)                                                                     │" -ForegroundColor Magenta
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray

# 74. Mouse Interrupt Affinity
$mouse = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" -Name "Affinity" -ErrorAction SilentlyContinue
$act = if ($mouse -and $mouse.Affinity) { "Configurado" } else { "Default" }; $estado = if ($mouse) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Mouse Interrupt Affinity"; Path="HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters"; Name="Affinity"; Current=0; Rec=1; Type="DWord"; Desc="Núcleo dedicado para el mouse"} }
Write-DiagRow "Mouse Interrupt Affinity" $act "Núcleo dedicado" "Prioridad mouse" $estado

# 75. GPU Interrupt Affinity
$gpuIrq = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "InterruptAffinity" -ErrorAction SilentlyContinue).InterruptAffinity
$act = if ($gpuIrq) { "Configurado" } else { "Default" }; $estado = if ($Cores -gt 2 -and $gpuIrq) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="GPU Interrupt Affinity"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"; Name="InterruptAffinity"; Current=0; Rec=2; Type="DWord"; Desc="Núcleo dedicado para GPU"} }
Write-DiagRow "GPU Interrupt Affinity" $act "Núcleo dedicado" "Dibujo no traba" $estado

# 76. IRQ8 Priority (System Timer)
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "IRQ8Priority" -ErrorAction SilentlyContinue).IRQ8Priority
$rec = 1; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="IRQ8 (System Timer)"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name="IRQ8Priority"; Current=$val; Rec=$rec; Type="DWord"; Desc="Prioridad del timer del sistema"} }
Write-DiagRow "IRQ8 (System Timer)" $(if ($val -eq 1) { "Activado" } else { "Desactivado" }) "Activado" "Prioridad timer" $estado

# 77. DPC Watchdog
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Executive" -Name "DpcWatchdogPeriod" -ErrorAction SilentlyContinue).DpcWatchdogPeriod
$estado = "OK"
Write-DiagRow "DPC Watchdog" $(if ($val) { "$($val)s" } else { "Default" }) "Configurable" "Protección DPC" $estado

# ==============================================
# GRUPO 15: PROCESOS 2DO PLANO (5)
# ==============================================
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray
Write-Host "│  🔹 GRUPO 15: PROCESOS 2DO PLANO (5)                                                                            │" -ForegroundColor Magenta
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray

# 78. Background Apps
$val = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -ErrorAction SilentlyContinue).GlobalUserDisabled
$rec = 1; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Background Apps"; Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"; Name="GlobalUserDisabled"; Current=$val; Rec=$rec; Type="DWord"; Desc="Apps en segundo plano"} }
Write-DiagRow "Background Apps" $(if ($val -eq 1) { "Desactivadas" } else { "Activadas" }) "Desactivadas" "Apps segundo plano" $estado

# 79. Edge Background Mode
$val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "BackgroundModeEnabled" -ErrorAction SilentlyContinue).BackgroundModeEnabled
$rec = 0; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Edge Background Mode"; Path="HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name="BackgroundModeEnabled"; Current=$val; Rec=$rec; Type="DWord"; Desc="Edge en segundo plano"} }
Write-DiagRow "Edge Background Mode" $(if ($val -eq 0) { "Desactivado" } else { "Activado" }) "Desactivado" "RAM Edge" $estado

# 80. Chrome Background Mode
$val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name "BackgroundModeEnabled" -ErrorAction SilentlyContinue).BackgroundModeEnabled
$rec = 0; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Chrome Background Mode"; Path="HKLM:\SOFTWARE\Policies\Google\Chrome"; Name="BackgroundModeEnabled"; Current=$val; Rec=$rec; Type="DWord"; Desc="Chrome en segundo plano"} }
Write-DiagRow "Chrome Background Mode" $(if ($val -eq 0) { "Desactivado" } else { "Activado" }) "Desactivado" "RAM Chrome" $estado

# 81. Brave Background Mode
$val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave" -Name "BackgroundModeEnabled" -ErrorAction SilentlyContinue).BackgroundModeEnabled
$rec = 0; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Brave Background Mode"; Path="HKLM:\SOFTWARE\Policies\BraveSoftware\Brave"; Name="BackgroundModeEnabled"; Current=$val; Rec=$rec; Type="DWord"; Desc="Brave en segundo plano"} }
Write-DiagRow "Brave Background Mode" $(if ($val -eq 0) { "Desactivado" } else { "Activado" }) "Desactivado" "RAM Brave" $estado

# 82. Firefox Background Mode
$val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Mozilla\Firefox" -Name "BackgroundAppUpdate" -ErrorAction SilentlyContinue).BackgroundAppUpdate
$rec = 0; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Firefox Background Mode"; Path="HKLM:\SOFTWARE\Policies\Mozilla\Firefox"; Name="BackgroundAppUpdate"; Current=$val; Rec=$rec; Type="DWord"; Desc="Firefox en segundo plano"} }
Write-DiagRow "Firefox Background Mode" $(if ($val -eq 0) { "Desactivado" } else { "Activado" }) "Desactivado" "RAM Firefox" $estado

# ==============================================
# GRUPO 16: UI Y SHELL RESPONSE (4)
# ==============================================
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray
Write-Host "│  🔹 GRUPO 16: UI Y SHELL RESPONSE (4)                                                                           │" -ForegroundColor Magenta
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray

# 83. Window Ghosting Timeout
$val = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "HungAppTimeout" -ErrorAction SilentlyContinue).HungAppTimeout
$rec = 2000; $estado = if ($val -le $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Window Ghosting Timeout"; Path="HKCU:\Control Panel\Desktop"; Name="HungAppTimeout"; Current=$val; Rec=$rec; Type="String"; Desc="Tiempo antes de marcar app como no responde"} }
Write-DiagRow "Window Ghosting Timeout" $(if ($val) { "$($val)ms" } else { "5000ms" }) "${rec}ms" "Apps no congelan" $estado

# 84. App Kill Timeout
$val = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -ErrorAction SilentlyContinue).WaitToKillAppTimeout
$rec = if ($DiskType -eq "HDD") { 20000 } else { 4000 }; $estado = if ($DiskType -eq "HDD" -or $val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="App Kill Timeout"; Path="HKCU:\Control Panel\Desktop"; Name="WaitToKillAppTimeout"; Current=$val; Rec=$rec; Type="String"; Desc="Tiempo para cerrar apps al salir"} }
Write-DiagRow "App Kill Timeout" $(if ($val) { "$($val)ms" } else { "20000ms" }) "${rec}ms" "Cierre forzado" $estado

# 85. Shutdown Warning Timeout
$val = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShutdownWarningTimeout" -ErrorAction SilentlyContinue).ShutdownWarningTimeout
$rec = 1000; $estado = if ($val -le $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Shutdown Warning Timeout"; Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"; Name="ShutdownWarningTimeout"; Current=$val; Rec=$rec; Type="DWord"; Desc="Tiempo de advertencia al apagar"} }
Write-DiagRow "Shutdown Warning Timeout" $(if ($val) { "$($val)ms" } else { "5000ms" }) "${rec}ms" "Advertencia apagado" $estado

# 86. Clear PageFile at Shutdown
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "ClearPageFileAtShutdown" -ErrorAction SilentlyContinue).ClearPageFileAtShutdown
$rec = 0; $estado = if ($val -eq $rec) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Clear PageFile at Shutdown"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"; Name="ClearPageFileAtShutdown"; Current=$val; Rec=$rec; Type="DWord"; Desc="Limpieza del pagefile al apagar"} }
Write-DiagRow "Clear PageFile at Shutdown" $(if ($val -eq 1) { "Activado" } else { "Desactivado" }) "Desactivado" "Apagado lento" $estado

# ==============================================
# GRUPO 17: RESERVEDSTORAGE Y PHANTOM (2)
# ==============================================
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray
Write-Host "│  🔹 GRUPO 17: RESERVEDSTORAGE Y PHANTOM (2)                                                                      │" -ForegroundColor Magenta
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray

# 87. ReservedStorage
$rs = (Get-WindowsReservedStorageState -ErrorAction SilentlyContinue).State
$act = if ($rs -eq "Enabled") { "Activado" } else { "Desactivado" }; $diskSizeGB = (Get-Partition -DriveLetter C -ErrorAction SilentlyContinue | Get-Volume).Size / 1GB
$rec = if ($diskSizeGB -lt 256) { "Desactivado" } else { "Activado" }; $estado = if (($act -eq "Desactivado" -and $diskSizeGB -lt 256) -or ($act -eq "Activado" -and $diskSizeGB -ge 256)) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="ReservedStorage"; Current=$act; Rec=$rec; IsReserved=1; Desc="Espacio reservado para updates"} }
Write-DiagRow "ReservedStorage" $act $rec "Espacio updates (15GB)" $estado

# 88. Phantom Drivers
$phantomDrivers = Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Enum\USB" -ErrorAction SilentlyContinue | Where-Object { (Get-ItemProperty -Path $_.PSPath -Name "ConfigFlags" -ErrorAction SilentlyContinue).ConfigFlags -eq 1 }
$count = ($phantomDrivers | Measure-Object).Count; $estado = if ($count -eq 0) { "OK" } else { "OPT" }
if ($estado -eq "OPT") { $opts += @{Target="Phantom Drivers"; Current="$count encontrados"; Rec="0"; IsPhantom=1; Desc="Drivers de dispositivos que ya no existen"} }
Write-DiagRow "Phantom Drivers" "$count encontrados" "0" "Registro + boot lento" $estado

# ==============================================
# GRUPO 18: OPTIMIZACIONES PENDIENTES (2)
# ==============================================
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray
Write-Host "│  🔹 GRUPO 18: OPTIMIZACIONES PENDIENTES (2)                                                                     │" -ForegroundColor Magenta
Write-Host ("├{0}┼{1}┼{2}┼{3}┼{4}┤" -f ("─"*44), ("─"*24), ("─"*20), ("─"*26), ("─"*6)) -ForegroundColor DarkGray

# 89. Prefetch Disk Usage
$prefetchPath = "$env:windir\Prefetch"
$prefetchSize = if (Test-Path $prefetchPath) { (Get-ChildItem $prefetchPath -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB } else { 0 }
$act = "$([math]::Round($prefetchSize,1))MB"
$estado = if ($prefetchSize -gt 100) { "OPT" } else { "OK" }
Write-DiagRow "Prefetch Disk Usage" $act "Mantener o limpiar" "Archivos de rastreo apps" $estado

# 90. Registry Size Limit
$val = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager" -Name "RegistrySizeLimit" -ErrorAction SilentlyContinue).RegistrySizeLimit
$act = if ($val) { "$([math]::Round($val/1MB))MB" } else { "Default" }
$rec = if ($TotalRAMGB -le 4) { "256MB" } else { "Default" }; $estado = if ($TotalRAMGB -le 4 -and $val) { "OPT" } else { "OK" }
if ($estado -eq "OPT") { $opts += @{Target="Registry Size Limit"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager"; Name="RegistrySizeLimit"; Current=$val; Rec=268435456; Type="DWord"; Desc="Tamaño máximo del registro"} }
Write-DiagRow "Registry Size Limit" $act $rec "Memoria registro" $estado

Write-Host "└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan

# ==============================================
# RESUMEN
# ==============================================
Write-Host "`n┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐" -ForegroundColor Green
Write-Host "│  ✅ DIAGNÓSTICO COMPLETADO                                                                                      │" -ForegroundColor Green
Write-Host "├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor Green
Write-Host "│  📊 PERFIL FINAL: $HardwareProfile                                                                              │" -ForegroundColor White
Write-Host "│  📈 SECTORES ANALIZADOS: 105                                                                                    │" -ForegroundColor White
Write-Host "│  ⚡ OPTIMIZACIONES POSIBLES: $($opts.Count)                                                                      │" -ForegroundColor Yellow
Write-Host "└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor Green

# ==============================================
# AVISO MITIGACIONES
# ==============================================
Write-Host "`n┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐" -ForegroundColor Yellow
Write-Host "│  ⚠️  AVISO IMPORTANTE - MITIGACIONES CPU                                                                        │" -ForegroundColor Yellow
Write-Host "├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor Yellow
Write-Host "│  Desactivar las mitigaciones Spectre/Meltdown acelera CPUs viejos hasta un 25%.                                  │" -ForegroundColor Yellow
Write-Host "│  Es SEGURO para uso diario (estudio, apuntes, navegación).                                                      │" -ForegroundColor Yellow
Write-Host "│  NO recomendado para servidores o manejo de datos sensibles.                                                    │" -ForegroundColor DarkGray
Write-Host "└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor Yellow

# ==============================================
# MENÚ
# ==============================================
if ($opts.Count -eq 0) {
    Write-Host "`n  ✅ No se detectaron optimizaciones pendientes. ¡Tu sistema ya está optimal!" -ForegroundColor Green
    exit
}

Write-Host "`n┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│  🚀 FASE DE OPTIMIZACIÓN                                                                                         │" -ForegroundColor Cyan
Write-Host "├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
Write-Host "│                                                                                                                 │" -ForegroundColor Cyan
Write-Host "│     [1]  AUTO  - Aplicar TODAS las optimizaciones ($($opts.Count) cambios)                                       │" -ForegroundColor Green
Write-Host "│     [2]  MANUAL- Elegir una por una                                                                             │" -ForegroundColor Yellow
Write-Host "│     [3]  SALIR - No hacer cambios (solo diagnóstico)                                                            │" -ForegroundColor Red
Write-Host "│                                                                                                                 │" -ForegroundColor Cyan
Write-Host "└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan

$modo = Read-Host "`n  Elige una opción"

if ($modo -eq "3") {
    Write-Host "`n  ✅ Diagnóstico completado. No se aplicaron cambios." -ForegroundColor Green
    Write-Host "  🙏 ¡Hasta la próxima!" -ForegroundColor Gray
    exit
}

# ==============================================
# APLICAR OPTIMIZACIONES
# ==============================================
Write-Host "`n┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│  🔧 APLICANDO OPTIMIZACIONES                                                                                     │" -ForegroundColor Cyan
Write-Host "├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan

$cambios = 0
$errores = 0

function Apply-Optimization {
    param($opt)
    try {
        if ($opt.Service) {
            if ($opt.Rec -eq "Desactivado") {
                Stop-Service -Name $opt.Service -Force -ErrorAction SilentlyContinue
                Set-Service -Name $opt.Service -StartupType Disabled -ErrorAction SilentlyContinue
            } elseif ($opt.Rec -eq "Activado") {
                Set-Service -Name $opt.Service -StartupType Automatic -ErrorAction SilentlyContinue
                Start-Service -Name $opt.Service -ErrorAction SilentlyContinue
            }
            return $true
        }
        elseif ($opt.IsPower -eq 1) {
            $highPerfGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
            powercfg /setactive $highPerfGuid 2>$null
            return $true
        }
        elseif ($opt.IsTCPAuto -eq 1) {
            Set-NetTCPSetting -SettingName Internet -AutoTuningLevelLocal Normal -ErrorAction SilentlyContinue
            return $true
        }
        elseif ($opt.IsRSS -eq 1) {
            $adapters = Get-NetAdapter -ErrorAction SilentlyContinue
            foreach ($adapter in $adapters) {
                if ($opt.Rec -eq "Activado") { Enable-NetAdapterRss -Name $adapter.Name -ErrorAction SilentlyContinue }
                else { Disable-NetAdapterRss -Name $adapter.Name -ErrorAction SilentlyContinue }
            }
            return $true
        }
        elseif ($opt.IsReserved -eq 1) {
            if ($opt.Rec -eq "Desactivado") { Disable-WindowsReservedStorageState -ErrorAction SilentlyContinue }
            else { Enable-WindowsReservedStorageState -ErrorAction SilentlyContinue }
            return $true
        }
        elseif ($opt.IsPhantom -eq 1) {
            $phantomDrivers = Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Enum\USB" -ErrorAction SilentlyContinue | Where-Object { (Get-ItemProperty -Path $_.PSPath -Name "ConfigFlags" -ErrorAction SilentlyContinue).ConfigFlags -eq 1 }
            foreach ($driver in $phantomDrivers) { Remove-Item -Path $driver.PSPath -Recurse -Force -ErrorAction SilentlyContinue }
            return $true
        }
        elseif ($opt.IsAutoLogger -eq 1) {
            $autologgers = Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger" -ErrorAction SilentlyContinue
            foreach ($logger in $autologgers) { Set-ItemProperty -Path $logger.PSPath -Name "Start" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue }
            return $true
        }
        elseif ($opt.Path -and $opt.Name) {
            Set-ItemProperty -Path $opt.Path -Name $opt.Name -Value $opt.Rec -Type $opt.Type -Force -ErrorAction SilentlyContinue
            return $true
        }
        return $false
    } catch { return $false }
}

if ($modo -eq "1") {
    foreach ($opt in $opts) {
        if (Apply-Optimization $opt) {
            $cambios++
            Write-Host ("│  ✓ {0,-80} " -f $opt.Target) -ForegroundColor Green
        } else {
            $errores++
            Write-Host ("│  ⚠️ {0,-80} " -f $opt.Target) -ForegroundColor Yellow
        }
    }
} else {
    for ($i = 0; $i -lt $opts.Count; $i++) {
        $opt = $opts[$i]
        Write-Host "│" -ForegroundColor DarkGray
        Write-Host ("│  [{0}/$($opts.Count)] {1}" -f ($i+1), $opt.Target) -ForegroundColor White
        Write-Host ("│      Actual: $($opt.Current) → Recomendado: $($opt.Rec)") -ForegroundColor Gray
        Write-Host ("│      Descripción: $($opt.Desc)") -ForegroundColor DarkGray
        
        $resp = Read-Host "│      ¿Aplicar? (S/N)"
        if ($resp -eq "S" -or $resp -eq "s") {
            if (Apply-Optimization $opt) {
                $cambios++
                Write-Host "│      ✓ Aplicado" -ForegroundColor Green
            } else {
                $errores++
                Write-Host "│      ⚠️ Error al aplicar" -ForegroundColor Yellow
            }
        } else {
            Write-Host "│      ✗ Omitido" -ForegroundColor Gray
        }
    }
}

Write-Host "├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
Write-Host "│  ✅ OPTIMIZACIÓN FINALIZADA                                                                                     │" -ForegroundColor Green
Write-Host ("│     Cambios aplicados: {0} | Errores: {1}" -f $cambios, $errores) -ForegroundColor White
Write-Host "└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan

Write-Host "`n  ⚡ REINICIAR para que los cambios tengan efecto completo" -ForegroundColor Yellow
Write-Host "  📁 Para revertir: Panel de control > Sistema > Restaurar sistema`n" -ForegroundColor Gray
Write-Host "`n┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "│  🔄 REVERSIÓN DE CAMBIOS                                                                                         │" -ForegroundColor Cyan
Write-Host "├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
Write-Host "│                                                                                                                 │" -ForegroundColor Cyan
Write-Host "│     [R]  REVERTIR - Deshacer SOLO las optimizaciones aplicadas                                                  │" -ForegroundColor Yellow
Write-Host "│     [C]  CERRAR - Salir sin revertir                                                                            │" -ForegroundColor Gray
Write-Host "│                                                                                                                 │" -ForegroundColor Cyan
Write-Host "├─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor Cyan
Write-Host "│  ⚠️  La reversión NO requiere Restaurar sistema. Solo restaura las configuraciones que cambió Lazarus.        │" -ForegroundColor DarkGray
Write-Host "└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan

$opcion = Read-Host "  Elige una opción"

if ($opcion -eq "R" -or $opcion -eq "r") {
    Write-Host "`n  Revertiendo cambios..." -ForegroundColor Yellow
    
    # Necesitamos guardar los valores ORIGINALES antes de optimizar
    # Por eso al inicio del script, debemos crear un backup
    
    $backupFile = "$env:TEMP\WDM_Lazarus_backup.xml"
    
    if (Test-Path $backupFile) {
        $backup = Import-Clixml -Path $backupFile
        foreach ($item in $backup) {
            if ($item.Path -and $item.Name) {
                Set-ItemProperty -Path $item.Path -Name $item.Name -Value $item.OriginalValue -Type $item.Type -Force -ErrorAction SilentlyContinue
            }
            if ($item.Service) {
                Set-Service -Name $item.Service -StartupType $item.OriginalValue -ErrorAction SilentlyContinue
            }
            Write-Host "  ✓ Revertido: $($item.Name)"
        }
        Write-Host "`n  ✅ Cambios revertidos exitosamente. Reiniciá para aplicar." -ForegroundColor Green
    } else {
        Write-Host "`n  ⚠️ No se encontró archivo de backup. Los cambios no se pueden revertir automáticamente." -ForegroundColor Yellow
        Write-Host "     Podés volver a ejecutar el diagnóstico y aplicar los valores recomendados originales." -ForegroundColor Gray
    }
} else {
    Write-Host "`n  ✅ Saliendo sin revertir cambios." -ForegroundColor Green
}
