# PROTOTYPE - NOT FOR PRODUCTION
# Question: Do A (Compose Desktop) and B (Electron) render and accept Egyptian Arabic correctly on Windows 10 22H2 (G3, S6/S46, OQ22)?
# Date: 2026-10-17
# Adds Arabic (Egypt) with the Arabic 101 keyboard (input tip 0C01:00000401) to the CURRENT user's language list,
# after English (United States), and makes Arabic 101 the default input method (takes effect at the next logon:
# tools/g3.sh relogon). Runs as cashier (HKCU only, no elevation). Prints the list before and after.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
function Show($label) { $label + ": " + ($(foreach ($l in (Get-WinUserLanguageList)) { "$($l.LanguageTag)[$($l.InputMethodTips -join ',')]" }) -join ' ') }
# Get-WinUserLanguageList returns ONE list object in the pipeline: iterate with foreach, not ForEach-Object
# (the first two runs printed both languages as one entry; the list itself was right: .cache/g3-20261017.txt)
Show before
# Build a fresh list: en-US with the US keyboard, ar-EG with Arabic 101 only (explicit, not edited in place).
$list = New-WinUserLanguageList 'en-US'
$list[0].InputMethodTips.Clear()
$list[0].InputMethodTips.Add('0409:00000409')
$list.Add('ar-EG')
$list[1].InputMethodTips.Clear()
$list[1].InputMethodTips.Add('0C01:00000401')
Set-WinUserLanguageList -LanguageList $list -Force
# Make Arabic 101 the default input method, so apps start in Arabic after the next logon. First run switched with
# Alt+Shift instead: Windows showed a first-use "Input language switching" toast that took the keyboard focus and
# the typed keys were lost (evidence/g3/a-naskh-03-typed.png); the switch could not be confirmed either (no indicator).
Set-WinDefaultInputMethodOverride -InputTip '0C01:00000401'
Show after
"default input override: " + (Get-WinDefaultInputMethodOverride | ForEach-Object { "$($_.InputMethodTip) $($_.Description)" })
