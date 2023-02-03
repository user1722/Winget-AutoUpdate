@echo off

::::::::::::::::::::::::::::
:: Put WAU Arguments here ::
::::::::::::::::::::::::::::

SET arguments=-UpdatesAtLogon -UpdatesInterval Weekly -InstallUserContext -StartMenuShortcut -DesktopShortcut -RunOnMetered -NotificationLevel SuccessOnly -UseWhiteList -ListPath https://raw.githubusercontent.com/user1722/Winget-AutoUpdate/main/included_apps.txt -DoNotUpdate -Silent


::::::::::::::::::::::::::::
:: Run Powershell Script  ::
::::::::::::::::::::::::::::

SET PowershellCmd=Start-Process powershell.exe -Argument '-noprofile -executionpolicy bypass -file "%~dp0Winget-AutoUpdate-Install.ps1" %arguments%
powershell -Command "& {Get-ChildItem -Path '%~dp0' -Recurse | Unblock-File; %PowershellCmd%'}" -Verb RunAs
