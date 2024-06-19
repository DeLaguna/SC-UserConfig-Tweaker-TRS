Write-Output "##############################################################################################################################"
Write-Output "# Star Citizen User.cfg Optimizer Web                                                                                         "
Write-Output "# Version: 2024.06.11-1337-RC                                                                                                 "
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

$ScriptFromGitHub = Invoke-WebRequest https://raw.githubusercontent.com/DeLaguna/SC-UserConfig-Tweaker-TRS/main/SC-UserConfig-Tweaker-TRS.ps1
Invoke-Expression $($ScriptFromGitHub.Content)
