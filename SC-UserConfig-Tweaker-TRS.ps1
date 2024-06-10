# Star Citizen User.cfg Optimizer
# Version: 2024.06.10-0543-Alpha
# Created by TheRealSarcasmO
# https://linktr.ee/TheRealSarcasmO

# Inspired by ... emilwojcik93, and ... Isaard, and ...
# ORG: Affordable Multi Role Space Support
# https://robertsspaceindustries.com/enlist?referral=STAR-BV4X-S3HG
#
# TRS bringing you a script with a graphical twist for the discerning meatbag.
# Depending on what cvars, CIG allow to be used, this script effects will work more or less.
# While this script does look for core count and optimize for it, it is assumed that the user has at least 4 physical cores.

# Script is best Run from Administrator:Windows PowerShell

##############################################################################################################################
# Load the necessary assembly for Windows Forms
Add-Type -AssemblyName System.Windows.Forms

# Set $PSScriptRoot to the directory of the running script
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Function to get the version of a script
function Get-ScriptVersion {
    param($scriptContent)

    # Extract the version from the script
    if ($scriptContent -match '# Version: ([\d\.]+-\d{4}-\w+)') {
        return $matches[1]
    } else {
        throw "Could not find version in script."
    }
}

# Define the URL of the remote script on GitHub
$remoteScriptUrl = "https://raw.githubusercontent.com/DeLaguna/SC-UserConfig-Tweaker-TRS/main/SC-UserConfig-Tweaker-TRS.ps1"

# Define the path to the local script
$localScriptPath = Join-Path $PSScriptRoot "SC-UserConfig-Tweaker-TRS.ps1"

# Get the content of the local script
$localScriptContent = Get-Content -Path $localScriptPath -Raw

# Get the version of the local script
$localVersion = Get-ScriptVersion -scriptContent $localScriptContent

# Download the script content from GitHub
$webClient = New-Object System.Net.WebClient
$remoteScriptContent = $webClient.DownloadString($remoteScriptUrl)

# Get the version of the remote script
$remoteVersion = Get-ScriptVersion -scriptContent $remoteScriptContent

# Compare the remote version with the local version
if ($remoteVersion -gt $localVersion) {
    Write-Output "A new version of the script is available on GitHub. Updating to version $remoteVersion."

    # Update the local script with the content from GitHub
    Set-Content -Path $localScriptPath -Value $remoteScriptContent

    Write-Output "The script has been updated. The script will now close and relaunch."

 # Relaunch the script
    Start-Sleep -Seconds 2
    Start-Process powershell -ArgumentList "-File `"$localScriptPath`""
    exit

} else {
    Write-Output "You are running the latest version ($localVersion) of the script."
}
##############################################################################################################################
Write-Output "==============================================================================="

Write-Host @"
===============================================================================
DISCLAIMER OF ALL THE THINGS THAT COULD POSSIBLY GO WRONG (BUT PROBABLY WON'T)
===============================================================================

Hello, brave user! By running this script, you're embarking on a thrilling adventure filled with system tweaks, performance enhancements, and the occasional existential crisis when you wonder why you're trusting a script you found on the internet. But fear not! This script has been carefully crafted by a team of highly trained meatbag... err... I mean, professional developer.

Now, onto the serious stuff:

1. This script will make changes to your system. It's kind of the point. But hey, we're backing up some stuff, so that's nice, right?

2. We've done our best to ensure this script won't unleash a horde of nanobots to turn your computer into a fancy paperweight, but we can't make any guarantees. Computers are fickle beasts.

3. If something does go wrong (but remember, it probably won't), we're not liable. Like, at all. We're over here, you're over there, and there's a whole lot of internet in between.

4. If you don't agree with these terms, or you suddenly feel a sense of impending doom, now would be a good time to press 'Ctrl+C' and walk away. Maybe go for a walk. Read a book. Contemplate the meaning of life.

Do you accept these terms and wish to continue? (y/n)
"@

$accept = Read-Host
if ($accept -ne 'y') {
    Write-Host "You chose not to continue. Exiting script. Have a nice day playing it safe!"
    return
}

# Continue with the rest of script...

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

# Continue with the rest of script...

# Get the path to the desktop
$desktopPath = [Environment]::GetFolderPath("Desktop")

# Define the shortcut file path
$shortcutFilePath = Join-Path -Path $desktopPath -ChildPath "PowerShell ISE.lnk"

# Check if the shortcut already exists
if (!(Test-Path -Path $shortcutFilePath)) {
    try {
        # Create a new WScript Shell object
        $wshShell = New-Object -ComObject WScript.Shell

        # Create a new shortcut
        $shortcut = $wshShell.CreateShortcut($shortcutFilePath)

        # Set the target path to PowerShell ISE
        $shortcut.TargetPath = "C:\Windows\System32\cmd.exe"

        # Set the arguments to run PowerShell ISE as administrator
        $shortcut.Arguments = "/c start powershell_ise.exe"

        # Save the shortcut
        $shortcut.Save()

        Write-Host "Shortcut created at: $shortcutFilePath"
    } catch {
        Write-Host "Failed to create shortcut at: $shortcutFilePath"
    }
} else {
    Write-Host "Shortcut already exists at: $shortcutFilePath"
}


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
        reg export HKLM $backupFilePath /y
        reg export HKCU $backupFilePath /y

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

# Function to ask the user if they want to implement system tweaks for Star Citizen
function Implement-SystemTweaks {
    # Create a new form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'System Tweaks'
    $form.Size = New-Object System.Drawing.Size(300,150)
    $form.StartPosition = 'CenterScreen'

    # Create a label
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,10)
    $label.Size = New-Object System.Drawing.Size(280,20)
    $label.Text = 'Do you want to implement system tweaks for Star Citizen?'
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
        # ... [rest of your script for implementing system tweaks] ...
        Write-Host "System tweaks have been implemented. Please restart your computer for the changes to take effect."
    } else {
        # User chose not to implement system tweaks
        Write-Host "No system tweaks have been made."
    }
}

# Call the function to prompt the user
Implement-SystemTweaks



# Function to get the total physical memory size and present options to the user
function Get-SystemRAM {
    # Get the total memory and available memory
    $computerInfo = Get-CimInstance -ClassName CIM_OperatingSystem
    $totalMemoryMB = [math]::truncate($computerInfo.TotalVisibleMemorySize / 1024)
    $freeMemoryMB = [math]::truncate($computerInfo.FreePhysicalMemory / 1024)
    Write-Host "      Detected system memory: $totalMemoryMB MB"
    Write-Host "          Free System memory: $freeMemoryMB MB"

    # Create a new form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'System RAM'
    $form.Size = New-Object System.Drawing.Size(300,200)
    $form.StartPosition = 'CenterScreen'

    # Create a label
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,10)
    $label.Size = New-Object System.Drawing.Size(280,40)
    $label.Text = "We detected $totalMemoryMB MB of RAM with $freeMemoryMB MB free. Select a RAM option or specify a percentage of free memory:"
    $form.Controls.Add($label)

    # Create a combo box for RAM options
    $comboBox = New-Object System.Windows.Forms.ComboBox
    $comboBox.Location = New-Object System.Drawing.Point(10,60)
    $comboBox.Size = New-Object System.Drawing.Size(130,21)
    $comboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $comboBox.Items.Add("Auto Detected: $totalMemoryMB MB")
    $ramOptions = @("8192", "16384", "32768", "65536", "131072", "262144")
    foreach ($option in $ramOptions) {
        $comboBox.Items.Add("$option MB")
    }
    $comboBox.SelectedIndex = 0
    $form.Controls.Add($comboBox)

    # Create a text box for specifying percentage
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(150,60)
    $textBox.Size = New-Object System.Drawing.Size(50,21)
    $form.Controls.Add($textBox)

    # Create a label for the text box
    $percentLabel = New-Object System.Windows.Forms.Label
    $percentLabel.Location = New-Object System.Drawing.Point(210,60)
    $percentLabel.Size = New-Object System.Drawing.Size(80,20)
    $percentLabel.Text = "% of free memory"
    $form.Controls.Add($percentLabel)

    # Create OK button
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(110,120)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    # Show the form as a dialog and capture the result
    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        if ($comboBox.SelectedItem -match "Auto Detected") {
            return $totalMemoryMB
        } elseif ($textBox.Text -match '^\d+$') {
            $percentage = [int]$textBox.Text
            if ($percentage -gt 0 -and $percentage -le 100) {
                return [math]::truncate($freeMemoryMB * ($percentage / 100))
            } else {
                [System.Windows.Forms.MessageBox]::Show('Please enter a valid percentage (1-100).', 'Invalid Input', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                return $null
            }
        } else {
            return $comboBox.SelectedItem -replace ' MB', ''
        }
    } else {
        return $null
    }
}

# Call the function to prompt the user
$selectedRAM = Get-SystemRAM
if ($selectedRAM -ne $null) {
    Write-Host "Selected RAM option: $selectedRAM MB"
} else {
    Write-Host "No RAM option was selected."
}


# Function to list video cards and get the video card memory size
# Function to get the video card memory and present options to the user
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

    # Common VRAM sizes in MB
    $vramOptions = @("2048", "4096", "6144", "8192", "11264", "16384", "24576")

    # Auto-detected option
    $autoOption = if ($videoCardMemoryMB -lt 4096) {
        "4096"
    } else {
        $videoCardMemoryMB.ToString()
    }

    # Create a new form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Video Card VRAM'
    $form.Size = New-Object System.Drawing.Size(300,200)
    $form.StartPosition = 'CenterScreen'

    # Create a combo box for VRAM options
    $comboBox = New-Object System.Windows.Forms.ComboBox
    $comboBox.Location = New-Object System.Drawing.Point(10,60)
    $comboBox.Size = New-Object System.Drawing.Size(130,21)
    $comboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $comboBox.Items.Add("Auto Detected: $autoOption MB")
    foreach ($option in $vramOptions) {
        $comboBox.Items.Add("$option MB")
    }
    $comboBox.SelectedIndex = 0
    $form.Controls.Add($comboBox)

    # Create a text box for specifying percentage
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(150,60)
    $textBox.Size = New-Object System.Drawing.Size(50,21)
    $form.Controls.Add($textBox)

    # Create a label for the text box
    $percentLabel = New-Object System.Windows.Forms.Label
    $percentLabel.Location = New-Object System.Drawing.Point(210,60)
    $percentLabel.Size = New-Object System.Drawing.Size(80,20)
    $percentLabel.Text = "% of free memory"
    $form.Controls.Add($percentLabel)

    # Create OK button
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(110,120)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    # Show the form as a dialog and capture the result
    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        if ($comboBox.SelectedItem -match "Auto Detected") {
            $selectedVramSize = $autoOption
        } elseif ($textBox.Text -match '^\d+$') {
            $percentage = [int]$textBox.Text
            if ($percentage -gt 0 -and $percentage -le 100) {
                $selectedVramSize = [math]::truncate($videoCardMemoryMB * ($percentage / 100))
            } else {
                [System.Windows.Forms.MessageBox]::Show('Please enter a valid percentage (1-100).', 'Invalid Input', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                return $null
            }
        } else {
            $selectedVramSize = $comboBox.SelectedItem -replace ' MB', ''
        }
    } else {
        return $null
    }

    # Create a custom object to hold the model and selected VRAM in MB
    $videoCardInfo = [PSCustomObject] @{
        Model      = $largestVRAMVideoCard.Caption
        "Selected VRAM, MB" = $selectedVramSize
    }

    # Return the video card information with the selected VRAM size
    return $videoCardInfo
}

# Call the function to prompt the user
$videoCardDetails = Get-VideoCardMemory
if ($videoCardDetails -ne $null) {
    Write-Host "Selected VRAM size for $($videoCardDetails.Model): $($videoCardDetails.'Selected VRAM, MB') MB"
} else {
    Write-Host "No VRAM size was selected."
}


# Function to get the maximum refresh rate of the fastest monitor
function Get-MaxRefreshRate {
    $refreshRates = (Get-WmiObject Win32_VideoController).CurrentRefreshRate
    $maxRefreshRate = $refreshRates | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
    return $maxRefreshRate
}

# Function to get the maximum speed of HDD where the game is installed
function Get-HDDMaxReadSpeed {
    $driveInfo = Get-WmiObject Win32_LogicalDisk | Where-Object { $liveFolderPath.StartsWith($_.DeviceID) }
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

# Function to ask the user for their preference on FPS data display
function Get-FPSDisplayPreference {
    # Create a new form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'FPS Display Information'
    $form.Size = New-Object System.Drawing.Size(300,200)
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

# Call the function to prompt the user
$displayPreferenceIndex = Get-FPSDisplayPreference
if ($displayPreferenceIndex -ne $null) {
    Write-Host "Selected FPS display preference: $($displayInfoChoices[$displayPreferenceIndex])"
} else {
    Write-Host "No FPS display preference was selected."
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
    return int
}

# Call the function to prompt the user
$displaySessionInfoChoice = Get-displaySessionInfoChoice
if ($displaySessionInfoChoice -eq 1) {
    Write-Host "QR code will be shown."
} else {
    Write-Host "QR code will be hidden."
}

# Function to ask the user for their graphics quality preference
function Get-GraphicsQualityPreference {
    # Create a new form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Graphics Quality'
    $form.Size = New-Object System.Drawing.Size(300,150)
    $form.StartPosition = 'CenterScreen'

    # Create a label
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,10)
    $label.Size = New-Object System.Drawing.Size(280,20)
    $label.Text = 'Select the graphics quality setting for your system:'
    $form.Controls.Add($label)

    # Create a combo box for graphics quality options
    $comboBox = New-Object System.Windows.Forms.ComboBox
    $comboBox.Location = New-Object System.Drawing.Point(10,40)
    $comboBox.Size = New-Object System.Drawing.Size(260,21)
    $comboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $graphicsQualityChoices = @("Low", "Medium", "High", "Very High")
    foreach ($choice in $graphicsQualityChoices) {
        $comboBox.Items.Add($choice)
    }
    $comboBox.SelectedIndex = 2 # Default selection is "High"
    $form.Controls.Add($comboBox)

    # Create OK button
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(110,90)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    # Show the form as a dialog and capture the result
    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        # Return the index of the selected choice + 1
        return $comboBox.SelectedIndex + 1
    } else {
        return $null
    }
}

# Call the function to prompt the user
$graphicsQualityPreference = Get-GraphicsQualityPreference
if ($graphicsQualityPreference -ne $null) {
    Write-Host "Selected graphics quality preference: $($graphicsQualityChoices[$graphicsQualityPreference - 1])"
} else {
    Write-Host "No graphics quality preference was selected."
}

# Retrieve system information and user preferences
$selectedVRAMCardInfo = Get-VideoCardMemory
$rsiFolderPath = Find-RSIPath
$liveFolderPath = Join-Path -Path $rsiFolderPath -ChildPath "StarCitizen\LIVE\"

# Retrieve system information
$systemInfo = Get-SystemInfo


$rsiInstallPath = "$rsiFolderPath\StarCitizen\LIVE"
$rsiLauncherPath = "$rsiFolderPath\RSI Launcher"
#$diskInfo = Get-DiskInfoForPath -Path $rsiInstallPath

# Show user information of system info properties:
Write-Host "                    Username: $($systemInfo.Username)"
Write-Host "                 System Name: $($systemInfo.SystemName)"
Write-Host "            Operating System: $($systemInfo.OperatingSystem)"
Write-Host "          CPU Name and Brand: $($systemInfo.CPUNameAndBrand)"
Write-Host "Number of Physical CPU Cores: $($systemInfo.PhysicalCores)"
Write-Host "               Max CPU Speed: $($systemInfo.MaxCPUSpeedGHz) GHz"

# Now you can access the disk and controller info like this:
#Write-Host "                   Disk Info: $($diskInfo.Disk | Format-List | Out-String)"
#Write-Host "             Controller Info: $($diskInfo.Controller | Format-List | Out-String)"

$systemRAMChoice = Get-SystemRAM
$videoCardMemoryMB = $selectedVRAMCardInfo.'Selected VRAM, MB'
$maxReadSpeedMB = Get-HDDMaxReadSpeed
$r_MultiGPU = Get-MultiGPUStatus
$displayInfoSetting = Get-FPSDisplayPreference  # This will be 1 for Low, 2 for Medium, 3 for High, and 4 for Very High
$displaySessionInfoSetting = Get-displaySessionInfoChoice
$graphicsQuality = Get-GraphicsQualityPreference
$maxRefreshRate = Get-MaxRefreshRate

# Info to user.
Write-Host "Video Card with the largest VRAM:"
Write-Host "        Model: $($selectedVRAMCardInfo.Model)"
Write-Host "Selected VRAM: $($selectedVRAMCardInfo.'Selected VRAM, MB') MB"
if ($rsiFolderPath) {
    # Define the path to the User.cfg and Game.cfg file using the found RSI path
    $userCfgFilePath = Join-Path -Path $rsiFolderPath -ChildPath "StarCitizen\LIVE\user.cfg"
    
    #$userCfgFilePath = Join-Path -Path $rsiFolderPath -ChildPath "StarCitizen\LIVE\USER\Client\0\user.cfg"
    $gameCfgFilePath = Join-Path -Path $rsiFolderPath -ChildPath "StarCitizen\LIVE\USER\Client\0\game.cfg"
    
    # Check if the user.cfg file exists and is writable
    if (Test-Path -Path $gameCfgFilePath) {
        # Remove the ReadOnly attribute if it is set
        $fileAttributes = Get-ItemProperty -Path $gameCfgFilePath -Name Attributes
        if ($fileAttributes.Attributes -match 'ReadOnly') {
            Set-ItemProperty -Path $gameCfgFilePath -Name Attributes -Value ($fileAttributes.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly))
        }

# Define the backup directory using the existing $rsiFolderPath variable
$backupDirectory = Join-Path -Path $rsiFolderPath -ChildPath "StarCitizen\LIVE\Backups"

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

Write-Host "         Display Info Choice: $displayInfoSetting (This will be 1 for Low, 2 for Medium, 3 for High, and 4 for Very High)"
Write-Host " Display Session Info Choice: $displaySessionInfoSetting"
Write-Host "   The Max Refreshrate found: $maxRefreshRate Mhz"
Write-Host "Number of physical CPU cores: $($systemInfo.PhysicalCores)"
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
    $keybindsSource = Join-Path -Path $rsiFolderPath -ChildPath "StarCitizen\LIVE\USER\Client\0\Profiles\default"
    $mappingsSource = Join-Path -Path $rsiFolderPath -ChildPath "StarCitizen\LIVE\USER\Client\0\Controls\Mappings"

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

# Main script execution starts here

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

;       System RAM allocated Detected: $systemRAMChoice MB
;Video Card Memory allocated Detected: $videoCardMemoryMB MB
;        Graphics Preference Selected: $graphicsQuality
;                Graphics Quality Set: $graphicsQuality
;                     Fastest Monitor: $maxRefreshRate Mhz
; TOS accepted by User
;--Enables in-game console--
;--By default, you are restricted to only a handful of console commands you can use.--
con_restricted = 0

R_DisplaySessionInfo = $displaySessionInfoSetting

;--0-- FPS Display
r_DisplayInfo = $displayInfoSetting

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

# Call the function to create the CPU optimized section config string
$cpuOptimizedConfigString = Add-CPUOptimizedSectionToUserConfigContent

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
sys_spec = $graphicsQuality
sys_spec_Full = $graphicsQuality
sys_spec_Quality = $graphicsQuality
sys_spec_GameEffects = $graphicsQuality
sys_spec_Light = $graphicsQuality
sys_spec_ObjectDetail = $graphicsQuality
sys_spec_Particles = $graphicsQuality
sys_spec_Physics = $graphicsQuality
sys_spec_PostProcessing = $graphicsQuality
sys_spec_Shading = $graphicsQuality
sys_spec_Shadows = $graphicsQuality
sys_spec_Sound = $graphicsQuality
sys_spec_Texture = $graphicsQuality
sys_spec_TextureResolution = $graphicsQuality
sys_spec_VolumetricEffects = $graphicsQuality
sys_spec_Water = $graphicsQuality

;--Individual Shader Tweaks--
q_Quality = $graphicsQuality
q_Renderer = $graphicsQuality
q_ShaderFX = $graphicsQuality
q_ShaderGeneral = $graphicsQuality
q_ShaderGlass = $graphicsQuality
q_ShaderHDR = $graphicsQuality
q_ShaderIce = $graphicsQuality
q_ShaderMetal = $graphicsQuality
q_ShaderPostProcess = $graphicsQuality
q_ShaderShadow = $graphicsQuality
q_ShaderSky = $graphicsQuality
q_ShaderTerrain = $graphicsQuality

;--ShaderVegetation--
q_ShaderWater = $graphicsQuality
q_ShaderParticle = $graphicsQuality
q_ShaderDecal = $graphicsQuality

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

# Call the function to prompt the user
$enableExperimental = Get-ExperimentalOptionPreference

if ($enableExperimental) {
    # User chose to enable experimental options
    $experimentalCfgContent = @"
  
;--Experimental--
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

"@

    # Append the experimental settings to the user.cfg content
    $userCfgContent += $experimentalCfgContent
}
$enableTopGraphicsChoice = "No"


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

# Ask the user if they want top graphical settings using the GUI function
$enableTopGraphics = Get-TopGraphicalSettings

# Output the result
if ($enableTopGraphics) {
    Write-Host "Top graphical settings have been enabled."
} else {
    Write-Host "Top graphical settings have not been enabled."
}
if ($enableTopGraphics -eq 0) {
# User chose to enable top graphical settings
    $topGraphicsCfgContent = @"

;--Top Graphics Settings--

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

    $enableTopGraphicsChoice = "Yes"
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
        Graphics Quality Set: $graphicsQuality
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
$shaderFolderPath = Join-Path -Path $rsiFolderPath -ChildPath "LIVE\Shader"

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
# End of the script