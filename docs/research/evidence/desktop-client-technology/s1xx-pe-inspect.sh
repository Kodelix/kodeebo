#!/usr/bin/env bash
# Tier-E probe (Linux host, no Windows): inspect PE headers and imports of Windows DLLs
# to see the declared minimum OS/subsystem version and which imported Win32 functions
# are newer than Windows 7. Usage: s1xx-pe-inspect.sh <extract-dir> <dll> [<dll>...]
# This shows what the binary DECLARES/IMPORTS; it does not prove it loads or runs on any Windows version.
set -u
OBJ=x86_64-w64-mingw32-objdump
dir="$1"; shift
for dll in "$@"; do
  f="$dir/$dll"
  echo "=== $dll"
  sha256sum "$f" | cut -c1-64
  $OBJ -p "$f" | grep -E "^(Magic|MajorOSystemVersion|MinorOSystemVersion|MajorSubsystemVersion|MinorSubsystemVersion|Subsystem)" | tr -s ' ' | tr '\n' ';'; echo
  $OBJ -p "$f" | grep -E "DLL Name:" | sort -u | tr -s ' ' | tr '\n' ';'; echo
  # Win32 functions introduced after Windows 7 (from Microsoft docs; list is a probe set, not exhaustive)
  $OBJ -p "$f" | grep -o -E "(GetSystemTimePreciseAsFileTime|PrefetchVirtualMemory|WaitOnAddress|WakeByAddress[A-Za-z]*|QueryUnbiasedInterruptTime[A-Za-z]*|MapViewOfFile3|VirtualAlloc2|CreateFile2|GetCurrentPackage[A-Za-z]*|SetThreadDescription|CreateFileMapping2|OfferVirtualMemory|DiscardVirtualMemory)" | sort -u | tr '\n' ' '; echo
done
