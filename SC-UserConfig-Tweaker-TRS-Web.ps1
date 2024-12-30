Write-Output "##############################################################################################################################"
Write-Output "# Star Citizen User.cfg Optimizer Web                                                                                         "
Write-Output "# Version: 2024.12.30-0453-RC                                                                                                   "
Write-Output "# Created by TheRealSarcasmO                                                                                                  "
Write-Output "# https://linktr.ee/TheRealSarcasmO                                                                                           "
Write-Output "#                                                                                                                             "
Write-Output "# Inspired by ... emilwojcik93, and ... Isaard, and ...                                                                       "
Write-Output "# ORG: Affordable Multi Role Space Support                                                                                    "
Write-Output "# https://robertsspaceindustries.com/enlist?referral=STAR-BV4X-S3HG                                                           "
Write-Output "#                                                                                                                             "
Write-Output "# TRS bringing you a script with a graphical twist for the discerning meatbag.                                                "
Write-Output "# Depending on what cvars, CIG allow to be used, this script effects will work more or less.                                  "
Write-Output "# While this script does look for core count and optimize for it, it is assumed that the user has at least 4 physical cores.  "
Write-Output "#                                                                                                                             "
Write-Output "# Script is best Run from Administrator:Windows PowerShell                                                                    "
Write-Output "##############################################################################################################################"
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
$tempFolder = "C:\temp"

$Logfile = "$tempFolder\Star Citizen User.cfg Optimizer Web-$timestamp.txt"
# Start Log
Start-Transcript -Path $Logfile

Write-Host "Logging started Started: " $Logfile


Add-Type -AssemblyName System.Windows.Forms

$form = New-Object Windows.Forms.Form
$form.Text = "Choose Environment"
$form.Size = New-Object Drawing.Size(300,300)

$buttonLive = New-Object Windows.Forms.Button
$buttonLive.Text = "Live"
$buttonLive.Location = New-Object Drawing.Point(10,20)
$buttonLive.Size = New-Object Drawing.Size(100,40)
$buttonLive.Add_Click({
    $ScriptFromGitHub = Invoke-WebRequest  https://raw.githubusercontent.com/DeLaguna/SC-UserConfig-Tweaker-TRS/main/SC-UserConfig-Tweaker-TRS.ps1
    Invoke-Expression $($ScriptFromGitHub.Content)
    $form.Close()
})
$form.Controls.Add($buttonLive)

$buttonPTU = New-Object Windows.Forms.Button
$buttonPTU.Text = "PTU - Coming Soon"
$buttonPTU.Location = New-Object Drawing.Point(10,60)
$buttonPTU.Size = New-Object Drawing.Size(100,40)
$buttonPTU.Add_Click({
    $ScriptFromGitHub = Invoke-WebRequest #irm https://raw.githubusercontent.com/DeLaguna/SC-UserConfig-Tweaker-TRS/refs/heads/PTU/SC-UserConfig-Tweaker-TRS.ps1 | iex"
    Invoke-Expression $($ScriptFromGitHub.Content)
    $form.Close()
})
$form.Controls.Add($buttonPTU)

$buttonEPTU = New-Object Windows.Forms.Button
$buttonEPTU.Text = "EPTU - Coming Soon"
$buttonEPTU.Location = New-Object Drawing.Point(10,100)
$buttonEPTU.Size = New-Object Drawing.Size(100,40)
$buttonEPTU.Add_Click({
    $ScriptFromGitHub = Invoke-WebRequest "" #https://raw.githubusercontent.com/DeLaguna/SC-UserConfig-Tweaker-TRS/refs/heads/EPTU/SC-UserConfig-Tweaker-TRS.ps1
    Invoke-Expression $($ScriptFromGitHub.Content)
    $form.Close()
})
$form.Controls.Add($buttonEPTU)

$buttonPreview = New-Object Windows.Forms.Button
$buttonPreview.Text = "4.0_PREVIEW"
$buttonPreview.Location = New-Object Drawing.Point(10,140)
$buttonPreview.Size = New-Object Drawing.Size(100,40)
$buttonPreview.Add_Click({
    $ScriptFromGitHub = Invoke-WebRequest https://raw.githubusercontent.com/DeLaguna/SC-UserConfig-Tweaker-TRS/refs/heads/4.0_PREVIEW-TEST/SC-UserConfig-Tweaker-TRS.ps1
    Invoke-Expression $($ScriptFromGitHub.Content)
    $form.Close()
})
$form.Controls.Add($buttonPreview)

# Uncomment the following section when ready to launch
<# $buttonComingSoon = New-Object Windows.Forms.Button
$buttonComingSoon.Text = "Coming Soon"
$buttonComingSoon.Location = New-Object Drawing.Point(10,180)
$buttonComingSoon.Size = New-Object Drawing.Size(100,30)
$form.Controls.Add($buttonComingSoon)<#  #>    #>

[void]$form.ShowDialog()

#$ScriptFromGitHub = Invoke-WebRequest https://raw.githubusercontent.com/DeLaguna/SC-UserConfig-Tweaker-TRS/main/SC-UserConfig-Tweaker-TRS.ps1
Invoke-Expression $($ScriptFromGitHub.Content)
