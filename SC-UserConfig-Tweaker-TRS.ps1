Write-Output "##############################################################################################"
Write-Output "# Star Citizen User.cfg Optimizer  - 4.0_PREVIEW_TEST                                         "
Write-Output "# Version: 2024.12.30-0438-Alpha"
Write-Output "# Created by TheRealSarcasmO                                                                  "
Write-Output "# https://linktr.ee/TheRealSarcasmO                                                           "
Write-Output "#                                                                                             "
Write-Output "# Inspired by ... emilwojcik93, and ... Isaard, and ...                                       "
Write-Output "# ORG: Affordable Multi Role Space Support                                                    "
Write-Output "# https://robertsspaceindustries.com/enlist?referral=STAR-BV4X-S3HG                           "
Write-Output "#                                                                                             "
Write-Output "# TRS bringing you a script with a graphical twist for the discerning meatbag.                "
Write-Output "# Depending on what cvars, CIG allow to be used, this script effects will work more or less.  "
Write-Output "# While this script does look for core count and optimize for it, it is assumed that the      "
Write-Output "# user has at least 4 physical cores.                                                         "
Write-Output "# Script is best Run from Administrator:Windows PowerShell                                    "
Write-Output "##############################################################################################"

# Load the necessary assembly for Windows Forms
Add-Type -AssemblyName System.Windows.Forms

#############################################################################################################
Write-Output "=============================================================================================="

# Pause the script for 5 seconds
Start-Sleep -Seconds 5

Write-Host @"
===============================================================================
DISCLAIMER OF ALL THE THINGS THAT COULD POSSIBLY GO WRONG (BUT PROBABLY WON'T)
===============================================================================

 Star Citizen User.cfg Optimizer  - 4.0_PREVIEW_TEST      

Hello, brave user! By running this script, you're embarking on a thrilling adventure filled with system tweaks, 
performance enhancements, and the occasional existential crisis when you wonder why you're trusting a script you 
found on the internet. But fear not! This script has been carefully crafted by a meatbag... err... I mean, developer.

Now, onto the serious stuff:

1. This script will make changes to your system. It's kind of the point. But hey, we're backing up some stuff, 
so that's nice, right?

2. We've done our best to ensure this script won't unleash a horde of nanobots to turn your computer into a 
fancy paperweight, but we can't make any guarantees. Computers are fickle beasts.

3. If something does go wrong (but remember, it probably won't), we're not liable. Like, at all. We're over here,
you're over there, and there's a whole lot of internet in between.

4. If you don't agree with these terms, or you suddenly feel a sense of impending doom, now would be a good time 
to press 'Ctrl+C' and walk away. Maybe go for a walk. Read a book. Contemplate the meaning of life.

5. Ideally SC should be installed or symlinked to default directories. If not you should do that now

Do you accept these terms and wish to continue? (y/n)
"@

$accept = Read-Host

if ($accept -ne 'y') {
    Write-Host "You chose not to continue. Exiting script. Have a nice day playing it safe!"
    return
}

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as an Administrator. Please re-run this script as an Administrator."
    return
}

# Check the current execution policy
$currentPolicy = Get-ExecutionPolicy
if ($currentPolicy -ne 'Unrestricted') {
    # Attempt to set the execution policy to unrestricted
    try {
        Set-ExecutionPolicy Unrestricted -Force
        Write-Host "Execution policy has been set to unrestricted."
    } catch {
        Write-Host "Failed to set execution policy to unrestricted. Attempting to set to RemoteSigned."
        try {
            Set-ExecutionPolicy RemoteSigned -Force
            Write-Host "Execution policy has been set to RemoteSigned."
        } catch {
            Write-Host "Failed to set execution policy to RemoteSigned."
            $choice = Read-Host "Do you want to continue anyway? (yes/no)"
            if ($choice -ne 'yes') {
                Write-Host "User chose not to continue. Exiting script."
                return
            }
        }
    }
}

#################################################
# Create Shortcut on the desktop
#
#$desktopPath = "$($env:USERPROFILE)\Desktop"

# Specify the target PowerShell command
#$command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command 'irm https://bit.ly/SC-user-cfg-TRS-web | iex'"

# Specify the path for the shortcut
#$shortcutPath = Join-Path $desktopPath 'SC-UserConfig-Tweaker-TRS-Web.lnk'

# Create a shell object
#$shell = New-Object -ComObject WScript.Shell

# Create a shortcut object
#$shortcut = $shell.CreateShortcut($shortcutPath)

# Set properties of the shortcut
#$shortcut.TargetPath = "powershell.exe"
#$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"$command`""

# Save the shortcut
#$shortcut.Save()

# Make the shortcut have 'Run as administrator' property on
#$bytes = [System.IO.File]::ReadAllBytes($shortcutPath)

# Set byte value at position 0x15 in hex, or 21 in decimal, from the value 0x00 to 0x20 in hex
#$bytes[0x15] = $bytes[0x15] -bor 0x20

#[System.IO.File]::WriteAllBytes($shortcutPath, $bytes)

#Write-Host "Shortcut created at: $shortcutPath"


# Shortcut created on the desktop
# ##################################################

$timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"

# Function to get system information
function Get-SystemInfo {
    $computerInfo = Get-CimInstance -ClassName Win32_ComputerSystem
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $cpu = Get-CimInstance -ClassName Win32_Processor

    return [PSCustomObject]@{
        Username = $computerInfo.UserName
        SystemName = $computerInfo.Name
        OperatingSystem = $os.Caption
        CPUNameAndBrand = $cpu.Name
        PhysicalCores = $cpu.NumberOfCores
        MaxCPUSpeedGHz = [math]::Round($cpu.MaxClockSpeed / 1000, 3)
    }
}

# Function to search for the 'Roberts Space Industries' folder in Program Files and drive roots
function Find-RSIPath {
    # Attempt to find the folder in the Program Files directories first
    $programFilesPaths = @(
        [Environment]::GetFolderPath('ProgramFiles'),[Environment]::GetFolderPath('ProgramFilesX86')
    )
    
    foreach ($path in $programFilesPaths) {
        $rsiPath = Get-ChildItem -Path $path -Recurse -Directory -Filter "Roberts Space Industries" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
        if ($rsiPath) {
            return $rsiPath
        }
    }

    # If not found, search the root of all drives
    $driveRoots = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root
    foreach ($root in $driveRoots) {
        $rsiPath = Get-ChildItem -Path $root -Recurse -Directory -Filter "Roberts Space Industries" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
        if ($rsiPath) {
            return $rsiPath
        }
    }

    # If still not found, prompt the user for the installation path
    while ($true) {
        $userInputPath = Read-Host "Unable to find the 'Roberts Space Industries' folder. Please enter the installation path or type 'exit' to cancel"
        if ($userInputPath -eq 'exit') {
            Write-Host "User canceled the operation."
            return $null
        } elseif (Test-Path -Path $userInputPath -PathType Container) {
            return $userInputPath
        } else {
            Write-Host "The path entered does not exist. Please check the path and try again."
        }
    }
}

# Function to backup the registry
function Backup-Registry {
    try {
        # Define the path for the backup file with a timestamp
        $backupFolderPath = "$env:USERPROFILE\Documents\RegistryBackups"
        if (-not (Test-Path -Path $backupFolderPath)) {
            New-Item -Path $backupFolderPath -ItemType Directory
        }
        
        $backupFilePath = Join-Path -Path $backupFolderPath -ChildPath "RegistryBackup_$timestamp.reg"

        # Export the entire registry to the backup file
        reg export HKLM $backupFilePath /y #Local Machine Backup
        reg export HKCU $backupFilePath /y #Current User Backup

        Write-Host "Registry has been backed up to: $backupFilePath"
    } catch {
        Write-Host "An error occurred while backing up the registry: $_"
    }
}

# Function to safely set registry properties
function Safe-SetRegistryProperty {
    param (
        [string]$Path,
        [string]$Name,
        [string]$Value
    )
    if (Test-Path $Path) {
        try {
            Set-ItemProperty -Path $Path -Name $Name -Value $Value
        } catch {
            Write-Host "An error occurred setting registry value: $_"
        }
    } else {
        Write-Host "Registry path does not exist: $Path"
    }
}

# Function to enable System Restore for all drives
function Enable-RestoreForAllDrives {
    # Get all non-removable drives
    $drives = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType = 3"

    # Get the drive letter of the RSI folder
    $rsiDrive = Split-Path -Qualifier $rsiPath

    foreach ($drive in $drives) {
        # Skip removable drives
        if ($drive.DriveType -eq 2) {
            continue
        }

        # Enable System Restore
        try {
            Enable-ComputerRestore -Drive $drive.DeviceID
            Write-Output "System Restore has been enabled for $($drive.DeviceID)."
        } catch {
            Write-Output "Failed to enable System Restore for $($drive.DeviceID). Error: $($_.Exception.Message)"
            continue
        }

        # Set the maximum usage to 1% of the drive's space
        $maxUsage = [math]::Round(($drive.Size / 100), 0)
        vssadmin resize shadowstorage /For=$drive.DeviceID /On=$drive.DeviceID /MaxSize=$maxUsage

        # Check if the drive is the one containing the RSI folder
        if ($drive.DeviceID -eq $rsiDrive) {
            Write-Output "System Restore has been enabled for the drive containing the RSI folder ($($drive.DeviceID)) with a maximum usage of 1% of the drive's space."
        }
    }
}

# Function to get the maximum refresh rate of the fastest monitor
function Get-MaxRefreshRate {
    $refreshRates = (Get-WmiObject Win32_VideoController).CurrentRefreshRate
    $maxRefreshRate = $refreshRates | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
    return $maxRefreshRate
}

# Function to get the maximum speed of HDD where the game is installed
function Get-HDDMaxReadSpeed {
    $driveInfo = Get-WmiObject Win32_LogicalDisk | Where-Object { $LiveFolderPath.StartsWith($_.DeviceID) }
    $diskPerformance = winsat disk -drive $driveInfo.DeviceID[0] | Out-String
    if ($diskPerformance -match 'Disk  Sequential 64.0 Read\s+(\d+\.\d+) MB/s') {
        $maxReadSpeedMB = [math]::Floor($matches[1])
        Write-Host "The maximum read speed of the drive where Star Citizen is installed is approximately **$maxReadSpeedMB MB/s**."
    } else {
        $maxReadSpeedMB = 60
        Write-Host "The maximum read speed defaulting to **$maxReadSpeedMB MB/s**."
    }
    
    return $maxReadSpeedMB
}

# Function to determine if the user has multiple GPUs
function Get-MultiGPUStatus {
    $videoControllers = Get-WmiObject Win32_VideoController
    $gpuCount = $videoControllers.Count
    $multiGPU = 0

    if ($gpuCount -gt 1) {
        Write-Host "Multiple GPUs detected: $gpuCount GPUs found."
        $multiGPU = 1
    } else {
        Write-Host "Single GPU detected."
    }

    return $multiGPU
}

# Function to backup keybinds and mappings
function Backup-KeybindsAndMappings {
    # Check if the backup directories exist, if not, create them
    if (!(Test-Path -Path $keybindBackups)) {
        New-Item -ItemType Directory -Path $keybindBackups
    }
    if (!(Test-Path -Path $mappingBackups)) {
        New-Item -ItemType Directory -Path $mappingBackups
    }

    # Define the source directories for keybinds and mappings
    $keybindsSource = Join-Path -Path $rsiFolderPath -ChildPath "StarCitizen\4.0_PREVIEW\USER\Client\0\Profiles\default"
    $mappingsSource = Join-Path -Path $rsiFolderPath -ChildPath "StarCitizen\4.0_PREVIEW\USER\Client\0\Controls\Mappings"

    # Copy the keybinds and mappings to the backup directories
    Copy-Item -Path $keybindsSource -Destination $keybindBackups -Recurse
    Copy-Item -Path $mappingsSource -Destination $mappingBackups -Recurse
}

# Function to create a CPU optimized section config string and add it to the $userCfgContent variable
function Add-CPUOptimizedSectionToUserConfigContent {
    # Retrieve the total number of logical processors (cores)
    $cpuInfo = Get-CimInstance -ClassName Win32_Processor
    $totalCores = $cpuInfo.NumberOfLogicalProcessors
    # Create a new variable that is half of $totalCores
    $halfCores = $totalCores / 2
    # Create an array to hold the even core numbers
    $evenCores = for ($i = 0; $i -lt $totalCores; $i += 2) { $i }

    # Initialize the index for cycling through even cores
    $coreIndex = 0

    # Define the list of cvars to be set for each even core
    $cvarsList = @(
        "sys_main_CPU",
        "sys_physics_CPU",
        "sys_streaming_CPU",
        "ca_thread",
        "e_ParticlesThread",
        "gfx_loadtimethread",
        "e_StatObjMergeUseThread"
        # Add more cvars as needed
    )

    # Initialize the cvars string to be added to the $userCfgContent variable
    $cvarsConfigString = ";--CPU Optimized Section--`r`n" +
    "r_MultiThreaded = 1`r`n" +
    "sys_limit_phys_thread_count = $halfCores`r`n" +
    "sys_job_system_enable = 1`r`n" +
    "sys_job_system_max_worker = $halfCores`r`n" +
    "ai_NavigationSystemMT = 1`r`n"

    # Loop through the cvars list and assign even cores in a cycle
    foreach ($cvar in $cvarsList) {
        # Get the current even core number
        $currentCore = $evenCores[$coreIndex]

        # Add the cvar setting to the config string
        $cvarsConfigString += "$cvar = $currentCore`r`n"

        # Increment the core index and reset if it reaches the end of the even cores array
        $coreIndex = ($coreIndex + 1) % $evenCores.Count
    }

    # Return the CPU optimized section config string
    return $cvarsConfigString
}

# Define function to safely set registry properties
function Safe-SetRegistryProperty {
    param (
        [string]$Path,
        [string]$Name,
        [string]$Value
    )
    if (Test-Path $Path) {
        try {
            Set-ItemProperty -Path $Path -Name $Name -Value $Value
            return $true
        } catch {
            Write-Host "An error occurred setting registry value: $_"
            return $false
        }
    } else {
        Write-Host "Registry path does not exist: $Path"
        return $false
    }
}

# Function to ask the user if they want to implement system tweaks for Star Citizen
function Implement-SystemTweaks {
    # Create a new form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'System Tweaks'
    $form.Size = New-Object System.Drawing.Size(350,150)
    $form.StartPosition = 'CenterScreen'

    # Create a label
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,10)
    $label.Size = New-Object System.Drawing.Size(300,30)
    $label.Text = 'XXX DANGEROUS ONLY DO THIS IF YOU ARE AN EXPERT XXX Implement system tweaks for Star Citizen?'
    $form.Controls.Add($label)

    # Create Yes button
    $yesButton = New-Object System.Windows.Forms.Button
    $yesButton.Location = New-Object System.Drawing.Point(50,50)
    $yesButton.Size = New-Object System.Drawing.Size(75,23)
    $yesButton.Text = 'Yes'
    $yesButton.DialogResult = [System.Windows.Forms.DialogResult]::Yes
    $form.Controls.Add($yesButton)

    # Create No button
    $noButton = New-Object System.Windows.Forms.Button
    $noButton.Location = New-Object System.Drawing.Point(150,50)
    $noButton.Size = New-Object System.Drawing.Size(75,23)
    $noButton.Text = 'No'
    $noButton.DialogResult = [System.Windows.Forms.DialogResult]::No
    $form.Controls.Add($noButton)

    # Set the accept and cancel buttons for the form
    $form.AcceptButton = $yesButton
    $form.CancelButton = $noButton

    # Show the form as a dialog and capture the result
    $result = $form.ShowDialog()

    # Check the result and perform actions based on the user's choice
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        # User chose to implement system tweaks
        
          # User chose to implement system tweaks
        # Backup the registry
        Backup-Registry

          # Check if System Restore is enabled and create a restore point
        $restoreEnabled = (Get-ComputerRestorePoint)
        if (-not $restoreEnabled) {
            Enable-RestoreForAllDrives
        }
        Checkpoint-Computer -Description "Pre-StarCitizen Tweaks Restore Point"

        # Disable background apps
        Safe-SetRegistryProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1

        # GameMode, GameBar, and Game DVR Settings
        Safe-SetRegistryProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0
        Safe-SetRegistryProperty "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode" 1
        Safe-SetRegistryProperty "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 1

        # Other system tweaks go here...

# Get the RSI path
$rsiPath = Find-RSIPath

# If the RSI path is not found, exit the script
if (!$rsiPath) {
    Write-Host "Unable to find the RSI path. Exiting the script."
    exit
}

# Paths to the StarCitizen.exe and launcher
$exePaths = @("$rsiInstallPath\Bin64\StarCitizen.exe", "$rsiLauncherPath\Launcher.exe")

# Registry path for the exes
#Computer\HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers
$regPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"

# Check if the registry key exists
if (!(Test-Path -Path $regPath)) {
    # Create the registry key if it doesn't exist
    New-Item -Path $regPath -Force | Out-Null
}

# Backup the registry before making changes
Backup-Registry

foreach ($exePath in $exePaths) {
    # Set the "Disable fullscreen optimizations" flag
    $success = Safe-SetRegistryProperty -Path $regPath -Name $exePath -Value "~ DISABLEDXMAXIMIZEDWINDOWEDMODE"

    if ($success) {
        Write-Output "Fullscreen optimizations have been disabled for $exePath"
    }
}


        # Scan Windows for any corrupt files
        sfc /scannow

        # Run Unattended Disk Cleanup
        Cleanmgr /sagerun:1

        # Stop and disable the Diagnostics Tracking Service
        $diagTrackService = Get-Service -Name diagtrack -ErrorAction SilentlyContinue
        if ($diagTrackService) {
            Stop-Service diagtrack
            Set-Service diagtrack -StartupType Disabled
        } else {
            Write-Host "Diagnostics Tracking Service not found."
        }

        # Set the Telemetry value to 0 (Security) in the registry to turn off telemetry
        Safe-SetRegistryProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0

        # Change System Responsiveness in Registry to 0
        Safe-SetRegistryProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0

        # In Multimedia scheduler, change Game and SFIO Priority to High and Priority to 6, GPU Priority to 8
        Safe-SetRegistryProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "GPU Priority" 8
        Safe-SetRegistryProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Priority" 6
        Safe-SetRegistryProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" "High"

        # In image file execution options, add StarCitizen.exe entry and create new key PerfOptions and add Dword32 CpuPriorityClass hexadecimal value 3
        $starCitizenKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\StarCitizen.exe"
        if (-not (Test-Path $starCitizenKeyPath)) {
            New-Item -Path $starCitizenKeyPath -Force
        }
        if (-not (Get-ItemProperty -Path $starCitizenKeyPath -Name "PerfOptions" -ErrorAction SilentlyContinue)) {
            New-ItemProperty -Path $starCitizenKeyPath -Name "PerfOptions" -Value 3 -PropertyType "DWord"
        } else {
            Write-Host "PerfOptions already set for StarCitizen.exe."
        }

        Write-Host "System tweaks have been implemented. Please restart your computer for the changes to take effect."

      } else {
        # User chose not to implement system tweaks
        Write-Host "No system tweaks have been made."
    }
}

# Function to get the 95% of biggest video card memory 
function Get-VideoCardMemory {
    # Get all video controllers
    $videoControllers = Get-CimInstance Win32_VideoController

    # Sort video controllers by VRAM size in descending order
    $sortedVideoControllers = $videoControllers | Sort-Object -Property AdapterRAM -Descending

    # Select the video card with the largest VRAM
    $largestVRAMVideoCard = $sortedVideoControllers | Select-Object -First 1

    # Attempt to get the VRAM size from the registry for all video controllers
    $qwMemorySizes = Get-ItemProperty -Path "HKLM:\SYSTEM\ControlSet001\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0*" -Name HardwareInformation.qwMemorySize -ErrorAction SilentlyContinue | Select-Object -ExpandProperty "HardwareInformation.qwMemorySize"

    # If there are multiple entries, select the largest one
    $largestQwMemorySize = if ($qwMemorySizes -and $qwMemorySizes.Count -gt 0) {
        ($qwMemorySizes | Measure-Object -Maximum).Maximum
    } else {
        $null
    }

    # If the registry query was successful and the VRAM size is larger than what Win32_VideoController reports, use it
    $videoCardMemoryMB = if ($largestQwMemorySize -and $largestQwMemorySize -gt $largestVRAMVideoCard.AdapterRAM) {
        [math]::round($largestQwMemorySize / 1MB)
    } else {
        [math]::round($largestVRAMVideoCard.AdapterRAM / 1MB)
    }

    # Calculate 95% of the video card memory
    $videoCardMemoryMB95 = [int][math]::truncate($videoCardMemoryMB * 0.95)

    # Return the video card information with the calculated VRAM size
    $videoCardInfo = [PSCustomObject] @{
        Model      = $largestVRAMVideoCard.Caption
        "VRAM, MB" =$videoCardMemoryMB
        "Selected VRAM, MB" = $videoCardMemoryMB95
    }

    return $videoCardInfo
}


function Get-SystemRAM {
    # Get the total memory and available memory
    $computerInfo = Get-CimInstance -ClassName CIM_OperatingSystem
    $totalMemoryMB = [math]::truncate($computerInfo.TotalVisibleMemorySize / 1024)
    $freeMemoryMB = [math]::truncate($computerInfo.FreePhysicalMemory / 1024)

    # Calculate 95% of the free memory
    $selectedRAM = [int][math]::truncate($freeMemoryMB * 0.95)

    # Create a custom object to hold the detected, free, and selected RAM in MB
    $ramInfo = [PSCustomObject] @{
        TotalRAM_MB = $totalMemoryMB
        FreeRAM_MB = $freeMemoryMB
        SelectedRAM_MB = $selectedRAM
    }

    # Return the custom object
    return $ramInfo
}

# Function to ask the user for their preference on FPS data display
function Get-FPSDisplayPreference {
    # Create a new form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'FPS Display Information'
    $form.Size = New-Object System.Drawing.Size(300,300)
    $form.StartPosition = 'CenterScreen'

    # Define the display information choices
    $displayInfoChoices = @("None", "Minimal", "Some", "More", "All")

    # Create radio buttons for each choice
    $y = 10
    foreach ($choice in $displayInfoChoices) {
        $radioButton = New-Object System.Windows.Forms.RadioButton
        $radioButton.Location = New-Object System.Drawing.Point(10, $y)
        $radioButton.Size = New-Object System.Drawing.Size(280,20)
        $radioButton.Text = $choice
        $radioButton.Checked = ($choice -eq "None") # Default selection
        $form.Controls.Add($radioButton)
        $y += 30
    }

    # Create OK button
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(110, $y)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    # Show the form as a dialog and capture the result
    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        # Find the selected radio button
        $selectedRadioButton = $form.Controls | Where-Object { $_ -is [System.Windows.Forms.RadioButton] -and $_.Checked }
        # Return the index of the selected choice
        return $displayInfoChoices.IndexOf($selectedRadioButton.Text)
    } else {
        return $null
    }
}

# Function to ask the user if they want the QR code
function Get-displaySessionInfoChoice {
    # Create a new form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Display Session Information'
    $form.Size = New-Object System.Drawing.Size(300,150)
    $form.StartPosition = 'CenterScreen'

    # Create a label
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,10)
    $label.Size = New-Object System.Drawing.Size(280,20)
    $label.Text = 'Do you want the QR in the right hand corner?'
    $form.Controls.Add($label)

    # Create Yes button
    $yesButton = New-Object System.Windows.Forms.Button
    $yesButton.Location = New-Object System.Drawing.Point(50,50)
    $yesButton.Size = New-Object System.Drawing.Size(75,23)
    $yesButton.Text = 'Yes'
    $yesButton.DialogResult = [System.Windows.Forms.DialogResult]::Yes
    $form.Controls.Add($yesButton)

    # Create No button
    $noButton = New-Object System.Windows.Forms.Button
    $noButton.Location = New-Object System.Drawing.Point(150,50)
    $noButton.Size = New-Object System.Drawing.Size(75,23)
    $noButton.Text = 'No'
    $noButton.DialogResult = [System.Windows.Forms.DialogResult]::No
    $form.Controls.Add($noButton)

    # Set the accept and cancel buttons for the form
    $form.AcceptButton = $yesButton
    $form.CancelButton = $noButton

    # Show the form as a dialog and capture the result
    $result = $form.ShowDialog()

    # Return 1 for Show and 0 for Hide based on the user's choice
    return $result -eq [System.Windows.Forms.DialogResult]::Yes
}

# Function to Get Graphics Quality Pref from User
function Get-GraphicsQualityPreference {
    # Create a new form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Graphics Quality'
    $form.Size = New-Object System.Drawing.Size(300,275) # Adjusted for radio buttons
    $form.StartPosition = 'CenterScreen'

    # Create a label
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,10)
    $label.Size = New-Object System.Drawing.Size(280,20)
    $label.Text = 'Select the graphics quality setting for your system:'
    $form.Controls.Add($label)

    # Define the graphics quality choices
    $graphicsQualityChoices = @("Low", "Medium", "High", "Very High")

    # Create radio buttons for each choice
    $y = 40 # Starting Y position for the first radio button
    $radioButtons = New-Object System.Collections.ArrayList
    foreach ($choice in $graphicsQualityChoices) {
        $radioButton = New-Object System.Windows.Forms.RadioButton
        $radioButton.Location = New-Object System.Drawing.Point(10, $y)
        $radioButton.Size = New-Object System.Drawing.Size(260,20)
        $radioButton.Text = $choice
        $form.Controls.Add($radioButton)
        $radioButtons.Add($radioButton) | Out-Null
        $y += 30 # Increment Y position for the next radio button
    }

    # Set default selection
    $radioButtons[2].Checked = $true # Default selection is "High"

    # Create OK button
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(110, $y)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    # Show the form as a dialog and capture the result
    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        # Find the selected radio button and return its index + 1
        for ($i = 0; $i -lt $radioButtons.Count; $i++) {
            if ($radioButtons[$i].Checked) {
                return $i + 1
            }
        }
    } else {
        return $null
    }
}

# Function to ask the user if they want to enable experimental Preload options
function Get-ExperimentalOptionPreference {
    # Create a new form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Experimental Options'
    $form.Size = New-Object System.Drawing.Size(300,150)
    $form.StartPosition = 'CenterScreen'

    # Create a label
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,10)
    $label.Size = New-Object System.Drawing.Size(280,20)
    $label.Text = 'Do you want to enable experimental Preload options?'
    $form.Controls.Add($label)

    # Create Yes button
    $yesButton = New-Object System.Windows.Forms.Button
    $yesButton.Location = New-Object System.Drawing.Point(50,50)
    $yesButton.Size = New-Object System.Drawing.Size(75,23)
    $yesButton.Text = 'Yes'
    $yesButton.DialogResult = [System.Windows.Forms.DialogResult]::Yes
    $form.Controls.Add($yesButton)

    # Create No button
    $noButton = New-Object System.Windows.Forms.Button
    $noButton.Location = New-Object System.Drawing.Point(150,50)
    $noButton.Size = New-Object System.Drawing.Size(75,23)
    $noButton.Text = 'No'
    $noButton.DialogResult = [System.Windows.Forms.DialogResult]::No
    $form.Controls.Add($noButton)

    # Set the accept and cancel buttons for the form
    $form.AcceptButton = $yesButton
    $form.CancelButton = $noButton

    # Show the form as a dialog and capture the result
    $result = $form.ShowDialog()

    # Return $true if the user clicked Yes, otherwise $false
    return $result -eq [System.Windows.Forms.DialogResult]::Yes
}

# Function to ask the user if they want top graphical settings
function Get-TopGraphicalSettings {
    # Create a new form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Top Graphical Settings'
    $form.Size = New-Object System.Drawing.Size(300,150)
    $form.StartPosition = 'CenterScreen'

    # Create a label
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,10)
    $label.Size = New-Object System.Drawing.Size(280,20)
    $label.Text = 'Do you want to enable top graphical settings?'
    $form.Controls.Add($label)

    # Create Yes button
    $yesButton = New-Object System.Windows.Forms.Button
    $yesButton.Location = New-Object System.Drawing.Point(50,50)
    $yesButton.Size = New-Object System.Drawing.Size(75,23)
    $yesButton.Text = 'Yes'
    $yesButton.DialogResult = [System.Windows.Forms.DialogResult]::Yes
    $form.Controls.Add($yesButton)

        # Create No button
    $noButton = New-Object System.Windows.Forms.Button
    $noButton.Location = New-Object System.Drawing.Point(150,50)
    $noButton.Size = New-Object System.Drawing.Size(75,23)
    $noButton.Text = 'No'
    $noButton.DialogResult = [System.Windows.Forms.DialogResult]::No
    $form.Controls.Add($noButton)

    # Set the accept and cancel buttons for the form
    $form.AcceptButton = $yesButton
    $form.CancelButton = $noButton

    # Show the form as a dialog and capture the result
    $result = $form.ShowDialog()

    # Return $true if the user clicked Yes, otherwise $false
    return $result -eq [System.Windows.Forms.DialogResult]::Yes
}

# Define the display information choices
$displayInfoChoices = @("None", "Minimal", "Some", "More", "All")

# Define the graphics quality choices
$graphicsQualityChoices = @("Low", "Medium", "High", "Very High")

# User Questions 
$selectedVRAMCardInfo = Get-VideoCardMemory
$ramInfo = Get-SystemRAM
$displayInfoSetting = Get-FPSDisplayPreference  # This will be 1 for Low, 2 for Medium, 3 for High, and 4 for Very High
$displaySessionInfoSetting = Get-displaySessionInfoChoice
$graphicsQualityPreference = Get-GraphicsQualityPreference
$enableExperimental = Get-ExperimentalOptionPreference
$enableTopGraphics = Get-TopGraphicalSettings

# Retrieve system information and user preferences
$rsiFolderPath = Find-RSIPath
$liveFolderPath = Join-Path -Path $rsiFolderPath -ChildPath "StarCitizen\4.0_PREVIEW\"

# Retrieve and set system information
$systemInfo = Get-SystemInfo
$systemRAMChoice = $($ramInfo.SelectedRAM_MB)
$videoCardMemoryMB = $($selectedVRAMCardInfo.'VRAM, MB')
$videoCardMemoryMB95 = $($selectedVRAMCardInfo.'Selected VRAM, MB')
$maxReadSpeedMB = Get-HDDMaxReadSpeed
$r_MultiGPU = Get-MultiGPUStatus
$maxRefreshRate = Get-MaxRefreshRate

# Call the function to create the CPU optimized section config string
$cpuOptimizedConfigString = Add-CPUOptimizedSectionToUserConfigContent

# FPS Display Preference
if ($displayInfoSetting -ne $null) {
    Write-Host "Selected FPS display preference: $($displayInfoChoices[$displayInfoSetting])"
} else {
    Write-Host "No FPS display preference was selected."
}

# System Memory
if ($systemRAMChoice -ne $null) {
    # Display the RAM information
Write-Host "Total System RAM: $($ramInfo.TotalRAM_MB) MB"
Write-Host "Free System RAM: $($ramInfo.FreeRAM_MB) MB"
Write-Host "95% of Free System RAM: $($ramInfo.SelectedRAM_MB) MB" 
} else {
    Write-Host "No RAM option was selected."    
}

# QR Code
if ($displaySessionInfoSetting -eq 1) {
    Write-Host "QR code will be shown."
} else {
    Write-Host "QR code will be hidden."
}

# Graphics Quality
if ($graphicsQualityPreference -ne $null) {
    Write-Host "Selected graphics quality preference: $($graphicsQualityChoices[$graphicsQualityPreference - 1])"
} else {
    Write-Host "No graphics quality preference was selected."
}

# VRAM Size
if ($selectedVRAMCardInfo -ne $null) {
    Write-Host "Selected VRAM size for $($selectedVRAMCardInfo.Model): $($selectedVRAMCardInfo.'Selected VRAM, MB') MB"
} else {
    Write-Host "No VRAM size was selected."
}

# TopGraphics Use Choice
if ($enableTopGraphics -eq 1) {
    Write-Host "Top graphical settings have been enabled."
    $enableTopGraphicsChoice = "Yes"
} else {
    Write-Host "Top graphical settings have not been enabled."
    $enableTopGraphicsChoice = "No"
}

$rsiInstallPath = "$rsiFolderPath\StarCitizen\4.0_PREVIEW"
$rsiLauncherPath = "$rsiFolderPath\RSI Launcher"
#$diskInfo = Get-DiskInfoForPath -Path $rsiInstallPath
 
# Show user information of system info properties:
Write-Host "                    Username: $($systemInfo.Username)"
Write-Host "                 System Name: $($systemInfo.SystemName)"
Write-Host "            Operating System: $($systemInfo.OperatingSystem)"
Write-Host "          CPU Name and Brand: $($systemInfo.CPUNameAndBrand)"
Write-Host "Number of Physical CPU Cores: $($systemInfo.PhysicalCores)"
Write-Host "                   CPU Speed: $($systemInfo.MaxCPUSpeedGHz) GHz"
Write-Host "            Total System RAM: $($ramInfo.TotalRAM_MB) MB"
Write-Host "             Free System RAM: $($ramInfo.FreeRAM_MB) MB"
Write-Host "      95% of Free System RAM: $($ramInfo.SelectedRAM_MB) MB"
Write-Host "         Display Info Choice: $displayInfoSetting (This will be 0 for hide, 1 for Low, 2 for Medium, 3 for High, and 4 for Very High)"
Write-Host " Display Session Info Choice: $displaySessionInfoSetting"
Write-Host "   The Max Refreshrate found: $maxRefreshRate Mhz"

# Info to user.
Write-Host "          :Video Card with the largest VRAM:"
Write-Host "                       Model: $($selectedVRAMCardInfo.Model)"
Write-Host "               Detected VRAM: $videoCardMemoryMB
Write-Host "               Selected VRAM: $videoCardMemoryMB95

if ($rsiFolderPath) {
    # Define the path to the User.cfg and Game.cfg file using the found RSI path
    $userCfgFilePath = Join-Path -Path $rsiFolderPath -ChildPath "StarCitizen\4.0_PREVIEW\user.cfg"
    
    #$userCfgFilePath = Join-Path -Path $rsiFolderPath -ChildPath "StarCitizen\4.0_PREVIEW\USER\Client\0\user.cfg"
    $gameCfgFilePath = Join-Path -Path $rsiFolderPath -ChildPath "StarCitizen\4.0_PREVIEW\USER\Client\0\game.cfg"
    
    # Check if the user.cfg file exists and is writable
    if (Test-Path -Path $gameCfgFilePath) {
        # Remove the ReadOnly attribute if it is set
        $fileAttributes = Get-ItemProperty -Path $gameCfgFilePath -Name Attributes
        if ($fileAttributes.Attributes -match 'ReadOnly') {
            Set-ItemProperty -Path $gameCfgFilePath -Name Attributes -Value ($fileAttributes.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly))
        }

# Define the backup directory using the existing $rsiFolderPath variable
$backupDirectory = Join-Path -Path $rsiFolderPath -ChildPath "StarCitizen\4.0_PREVIEW\Backups"

# Check if the backup directory exists, if not, create it
if (!(Test-Path -Path $backupDirectory)) {
    New-Item -ItemType Directory -Path $backupDirectory
}

# Now you can safely create a backup of the user.cfg file
$backupFilePath = Join-Path -Path $backupDirectory -ChildPath "User.cfg_$timestamp.bak"
Copy-Item -Path $userCfgFilePath -Destination $backupFilePath
    }
} else {
Write-Host "The 'Roberts Space Industries' folder could not be found."
}


#######################################################

# Check if the version file exists and read the version information
$versionFilePath = Join-Path -Path $liveFolderPath -ChildPath "f_win_game_client_release.id"
if (Test-Path -Path $versionFilePath) {
    $jsonContent = Get-Content -Path $versionFilePath | Out-String | ConvertFrom-Json
    $versionInfo = $jsonContent.Data.Branch
    $BuildDateStamp = $jsonContent.Data.BuildDateStamp
    $BuildTimeStamp = $jsonContent.Data.BuildTimeStamp
    $Type = $jsonContent.Data.Tag
} else {
    $versionInfo = "unknown"
    Write-Host "The version file does not exist at the specified path: $versionFilePath"
}

# Inform the user of the version information
Write-Host "Preparing to tweak settings for Star Citizen Version: $versionInfo"

# Define the backup directories with timestamp
$keybindBackups = "$rsiFolderPath\StarCitizen\Backups\USER\Keybinds\$timestamp"
$mappingBackups = "$rsiFolderPath\StarCitizen\Backups\USER\Mappings\$timestamp"
       $backups = "$rsiFolderPath\StarCitizen\Backups\$timestamp"

  #      DSR = $totalMemoryMB
  #      FR = $freeMemoryMB
  #      SR = $selectedRAM
  


# Create the user.cfg content with new settings and user choices
$userCfgContent = @"
;Super-Alpha USER.cfg for Star Citizen
;Created by TheRealSarcasmO
;v.$timestamp
;------------------------------
;Star Citizen Info
;Tested on  : $versionInfo    
;Build Date : $BuildDateStamp 
;Build Time : $BuildTimeStamp 
;------------------------------
;                    --Custom Tailored to User's Rig--
;                            Username: $($systemInfo.Username)
;                         System Name: $($systemInfo.SystemName)
;                    Operating System: $($systemInfo.OperatingSystem)

;                                 CPU: $($systemInfo.CPUNameAndBrand)
;                       Max CPU Speed: $($systemInfo.MaxCPUSpeedGHz) GHz
;        Number of physical CPU cores: $($systemInfo.PhysicalCores)

;                          System RAM: $($ramInfo.TotalRAM_MB) MB
;                     Free System RAM: $($ramInfo.FreeRAM_MB) MB
;              95% of Free System RAM: $($ramInfo.SelectedRAM_MB) MB

;                    Video Card Model: $($selectedVRAMCardInfo.Model)
;                       Detected VRAM: $videoCardMemoryMB
;         Video Card Memory allocated: $videoCardMemoryMB95
;        Graphics Preference Selected: $graphicsQualityPreference
;                    Top Graphics Set: $enableTopGraphicsChoice
;                     Fastest Monitor: $maxRefreshRate Mhz
;
;                Experimental Options: $enableExperimental
;
;                            TOS accepted by User
;                         --Enables in-game console--

;--By default, you are restricted to only a handful of console commands you can use.--
con_restricted = 0

R_DisplaySessionInfo = $displaySessionInfoSetting

;--0-- FPS Display
r_DisplayInfo = $displayInfoSetting
r_displayFrameGraph = $displayInfoSetting

;--1-- System RAM size (8GB="8192", 16GB="16384", 32GB="32768", 64GB="65536", 128GB="131072", 256GB="262144")
sys_budget_sysmem = $systemRAMChoice

;--2-- Video card memory (8GB="8192", 16GB="16384", 24GB="24560", 32GB="32768")
sys_budget_videomem = $videoCardMemoryMB

;--3-- Texture stream pool size
r_TexturesStreamPoolSize = $videoCardMemoryMB

;--4-- Maximum read speed of the drive
r_TexturesStreamingMaxRequestedMB = $maxReadSpeedMB

;--5-- Maximum Frames per Second in-engine
sys_maxfps = $maxRefreshRate

;--6-- Turns V-Sync off
r_VSync = 0

;--Performance Settings--
r_MultiGPU = $r_MultiGPU
sys_maxIdleFps = 30
                                                                                                                         
"@

# Append the CPU optimized section config string to the $userCfgContent variable
$userCfgContent += $cpuOptimizedConfigString

$ContinuingCfgContent = @"

;--Optimizations--
sys_PakStreamCache = 1
sys_preload = 0
e_PreloadMaterials = 0
e_StatObjPreload = 0

r_TesselationPreTesselateOnGPU = 1
sys_cigprofile_json_enable_logging = 0
sys_rad3_enable_logging = 0
r_Log = 0
cig_profile_auto_logging_enabled = 0
cig_profile_auto_logging_enabled_during_level_load = 0
r_gpudevicetextureenabletracking = 0
r_gpumarkers = 0
r_ProfileGPU = 0
r_RenderThreadDebugEventsEnable = 0

;--Graphics Settings--
sys_spec = $graphicsQualityPreference
sys_spec_Full = $graphicsQualityPreference
sys_spec_Quality = $graphicsQualityPreference
sys_spec_GameEffects = $graphicsQualityPreference
sys_spec_Light = $graphicsQualityPreference
sys_spec_ObjectDetail = $graphicsQualityPreference
sys_spec_Particles = $graphicsQualityPreference
sys_spec_Physics = $graphicsQualityPreference
sys_spec_PostProcessing = $graphicsQualityPreference
sys_spec_Shading = $graphicsQualityPreference
sys_spec_Shadows = $graphicsQualityPreference
sys_spec_Sound = $graphicsQualityPreference
sys_spec_Texture = $graphicsQualityPreference
sys_spec_TextureResolution = $graphicsQualityPreference
sys_spec_VolumetricEffects = $graphicsQualityPreference
sys_spec_Water = $graphicsQualityPreference

;--Individual Shader Tweaks--
q_Quality = $graphicsQualityPreference
q_Renderer = $graphicsQualityPreference
q_ShaderFX = $graphicsQualityPreference
q_ShaderGeneral = $graphicsQualityPreference
q_ShaderGlass = $graphicsQualityPreference
q_ShaderHDR = $graphicsQualityPreference
q_ShaderIce = $graphicsQualityPreference
q_ShaderMetal = $graphicsQualityPreference
q_ShaderPostProcess = $graphicsQualityPreference
q_ShaderShadow = $graphicsQualityPreference
q_ShaderSky = $graphicsQualityPreference
q_ShaderTerrain = $graphicsQualityPreference

;--ShaderVegetation--
q_ShaderWater = $graphicsQualityPreference
q_ShaderParticle = $graphicsQualityPreference
q_ShaderDecal = $graphicsQualityPreference

;--Texture Quality--
r_TexturesStreaming = 1
r_texturesstreamingJobUpdate = 1
r_texturesstreamingDeferred = 1
r_TexturesStreamingDisableNoStreamDuringLoad = 1
r_TexturesStreamingResidencyEnabled = 1
r_TexturesStreamingResidencyTime = 30
r_TexturesStreamingResidencyThrottle = 0.6
r_TexturesStreamingSkipMips = 0
r_TexturesStreamingMipBias = -4
r_TextureLodDistanceRatio = 0
r_DetailTextures = 1
r_TexMaxAnisotropy = 16
r_TexMinAnisotropy = 4

;--Misc Settings--
r_AntialiasingModeSCull = 1
r_DeferredShadingFilterGBuffer = 1
r_ssdoHalfRes = 1
r_SSAOQuality = 2
r_SSAODownscale = 1
e_GsmCache = 1
r_FogShadows = 0
r_FogShadowsWater = 0
e_Tessellation = 1
e_ParticlesShadows = 0
r_ParticlesTessellation = 1
r_SSReflHalfRes = 1
r_SilhouettePOM = 0
r_CloudsUpdateAlways = 0
r_Batching = 0 ; ? not sure what this is for 
e_DynamicLightsMaxCount = 16
r_PostProcessHUD3DCache = 1 ; set to 0 if issues

;--Visual Clarity--
r_OpticsQuality = 3
r_OpticsBloom = 0
r_HDRBloomRatio = 0
r_HDRBrightLevel = 0.25
r_HDREyeAdaptationMode = 0
r_HDREyeAdaptionFactor = 0
r_HDRRangeAdapt = 1
r_HDRRangeAdaptationSpeed = 1
r_HDREyeAdaptationSpeed = 1
r_HDRVignetting = 0
r_Flares = 0
r_Beams = 3
r_GlowAnamorphicFlares = 0
r_PostProcessHUD3DGlowAmount = 0
r_PostProcessHUD3DShadowAmount = 0
hud_bobHud = 0
r_ColorGrading = 0
r_ColorGradingFilters = 0
r_ColorGradingLevels = 0
r_ChromaticAberration = 0
r_Sharpening = 1
r_DepthOfField = 1
r_MotionBlur = 0
e_ParticlesMotionBlur = 0
r_MotionBlurQuality = 0
r_MotionBlurThreshold = 0
g_radialBlur = 0
r_Coronas = 0

;--LOD and Draw Distance Improvements--
e_ObjQuality = 4
e_DecalsLifeTimeScale = 2
e_MaxViewDistSpecLerp = 1
e_TerrainOcclusionCullingMaxDist = 255
e_ViewDistRatio = 255
e_ViewDistRatioDetail = 255
e_VegetationMinSize = 0.5
r_DetailDistance = 40
r_DrawNearZRange = 0.04
r_DrawNearFoV = 96
e_DynamicLightsForceDeferred = 1
v_vehicle_quality = 4
e_Dissolve = 2
e_DissolveDistband = 2
 
"@

# Combine all parts of the configuration
$userCfgContent += $ContinuingCfgContent

# Experimental Settings.
if ($enableExperimental) {
    # User chose to enable experimental options
    $experimentalCfgContent = @"
  
;--Experimental Settings--
;r_FourierShadowsPoolSize = 1024
;r_ShadowsPoolSize = 256
;r_gpumarkers = 0
;r_gpumarkersforceenableresmask = 0
;r_gpudevicetextureenabletracking = 0

sys_streaming_in_blocks = 1
sys_streaming_requests_grouping_time_period = 1
e_PreloadMaterials = 1
sys_PakStreamCache = 1
sys_preload = 1
e_StatObjPreload = 1
r_Gen12 = 2 ; Setting for the new Gen12 renderer. (0 = Off (use old renderer), 1 = Hybrid old and new Gen12 renderer, 2 = Gen12 renderer only)

"@

# Append the experimental settings to the user.cfg content
  $userCfgContent += $experimentalCfgContent
}

if ($enableTopGraphics -eq 0) {
# User chose to enable top graphical settings
    $topGraphicsCfgContent = @"

;--Top Graphics Settings--

r_Gen12	2	;Setting for the new Gen12 renderer.0 = Off (use old renderer), 1 = Hybrid old and new Gen12 renderer, 2 = Gen12 renderer only

;-- This Setting shows info on your FPS, Memory Usage & Frame Latency in-game, 1 shows just FPS, 4shows the most info.
r_DisplayInfo = $displayInfoSetting

;-- Tells the system cfg spec. (0=custom, 1=low, 2=med, 3=high, 4=very high)
sys_spec = 4
sys_spec_GameEffects = 4
sys_spec_ObjectDetail = 4
sys_spec_Particles = 4
sys_spec_Physics = 4
sys_spec_PostProcessing = 4
sys_spec_Shading = 4
sys_spec_Shadows = 4
sys_spec_Sound = 4
sys_spec_Texture = 4
sys_spec_TextureResolution = 4
sys_spec_VolumetricEffects = 4
sys_spec_Water = 4
sys_spec_light = 4

r_CloudsUpdateAlways = 1
r_ColorGrading = 1              ; Enables color grading.
r_ConditionalRendering = 1      ; Enables conditional rendering.
r_DeferredShadingSortLights = 1 ; Sorts light by influence
r_ssdo = 2                      ; SSDO is a lighting post process that makes stuff look prettier and more realistic.
r_SSReflections = 3             ; Glossy screen space reflections [0/1]
r_UseMergedPosts = 1            ; Enables motion blur merged with dof.
r_FullscreenWindow = 1
e_GsmCache = 1                  ; Saves GPU performance by updating distant shadows less often.
r_FogShadows = 1                ; Enables or disables Real-time Volumetric Cloud Shadows 0 = off | 1 = on
q_ShaderWater = 3               ; Shader water
e_GIIterations = 32             ; Maximum number of propagation iterations global illumination.
r_SSAOQuality = 3               ; SSAO shader quality[0 - Low spec, 1 - Medium spec, 2 - High spec, 3 - Highest spec]
r_DepthOfField = 2              ; Default is 0 (disabled). 1 enables, 2 hdr time of day dof enabled
r_TexMaxAnisotropy = 16         ; Specifies the maximum level allowed for anisotropic texture filtering.
r_DepthOfFieldBokehQuality = 1  ; Sets depth of field bokeh quality (samples multiplier).
r_DetailDistance = 20           ; Distance used for per-pixel detail layers blending.
r_FogShadowsWater = 1           ; Enables volumetric fog shadows for watervolumes
r_Glow = 1                      ; Toggles the glow effect.
r_MotionBlurQuality = 0         ; Set motion blur sample count.
r_ParticlesInstanceVertices = 1 ; Enable instanced-vertex rendering.
r_ParticlesRefraction = 1       ; Enables refractive particles.
r_ParticlesSoftIsec = 1         ; Enables particles soft intersections.
r_ParticlesTessellation = 1     ; Enables particle tessellation for higher quality lighting. (DX11 only)
r_Rain = 2                      ; Enables rain rendering 0 - disabled, 1 - enabled,  2 - enabled with rain occlusion
r_WaterReflectionsQuality = 3   ; Activates water reflections quality setting.
r_WaterVolumeCaustics = 1       ; Toggles advanced water caustics for watervolumes.
r_WaterTessellationHW = 1       ; Enables hw water tessellation.
r_ShadowBlur = 3                ; Selected shadow map screenspace blurring technique.
;r.TSAA = 1
"@

 # Append the top graphical settings to the user.cfg content
   $userCfgContent += $topGraphicsCfgContent
    
}

# Write the User.cfg content to the file
# To ensure the file uses UTF-8 encoding without BOM
$userCfgContent | Out-File -FilePath $userCfgFilePath -Encoding utf8

# Inform the user that the user.cfg has been updated
Write-Host "The user.cfg file has been updated with the new settings at $userCfgFilePath"

# Write the game.cfg content to the file
#$userCfgContent | Out-File -FilePath $gameCfgFilePath -Encoding utf8
# Inform the user that the user.cfg has been updated
#Write-Host "The Game.cfg file has been updated with the new settings at $gameCfgFilePath"
# Set the game.cfg file as read-only
#Set-ItemProperty -Path $gameCfgFilePath -Name IsReadOnly -Value $true
# Inform the user that the game.cfg has been updated
#Write-Host "The Game.cfg file has been updated with the new settings and set to read-only."

# Summary of changes
$summary = @"
                    Username: $($systemInfo.Username)
                 System Name: $($systemInfo.SystemName)
            Operating System: $($systemInfo.OperatingSystem)
          CPU Name and Brand: $($systemInfo.CPUNameAndBrand)
Number of Physical CPU Cores: $($systemInfo.PhysicalCores)
                   CPU Speed: $($systemInfo.MaxCPUSpeedGHz) GHz

        System RAM Allocated: $systemRAMChoice MB
 Video Card Memory Allocated: $videoCardMemoryMB MB
        Graphics Quality Set: $graphicsQualityPreference
     User Chose Top Graphics: $enableTopGraphicsChoice
user.cfg has been updated with the new settings at $userCfgFilePath
"@

# Display the summary of changes
Write-Host "Summary of Changes:"
Write-Host " "
Write-Host $summary

# Define the base path to the Star Citizen shader cache folder within the AppData directory for any user
$baseShaderCachePath = [System.IO.Path]::Combine($env:LOCALAPPDATA, "Star Citizen")

# Check if the base Star Citizen directory exists
if (Test-Path -Path $baseShaderCachePath) {
    # Get all sc-alpha-* directories
    $scAlphaDirectories = Get-ChildItem -Path $baseShaderCachePath -Directory -Filter "sc-alpha-*"

    # Loop through each sc-alpha-* directory and delete the Shaders folder
    foreach ($dir in $scAlphaDirectories) {
        $shaderCachePath = [System.IO.Path]::Combine($dir.FullName, "Shaders")
        if (Test-Path -Path $shaderCachePath) {
            Remove-Item -Path $shaderCachePath -Recurse -Force
            Write-Host "Deleted shader cache at: $shaderCachePath"
        }
    }
} else {
    Write-Host "Star Citizen directory does not exist in the current user's AppData\Local folder."
}

# Define the path to the Shader folder using the found RSI path
$shaderFolderPath = Join-Path -Path $rsiFolderPath -ChildPath "4.0_PREVIEW\Shader"

# Check if the Shader folder exists
if (Test-Path -Path $shaderFolderPath) {
    # Delete the Shader folder
    Remove-Item -Path $shaderFolderPath -Recurse -Force
    Write-Host "Shader folder has been deleted from the RSI path."
} else {
    Write-Host "Shader folder does not exist or has already been deleted from the RSI path."
}

    # Call the Implement-SystemTweaks function to apply system tweaks
    Implement-SystemTweaks

    # Open the user.cfg file with the default editor
    Invoke-Item -Path $userCfgFilePath


# Pause the script for 5 seconds
Start-Sleep -Seconds 60
# End of the script
