# PROTOTYPE - NOT FOR PRODUCTION
# Runs ON THE VM as the cashier (phase 4: S301, S302, S305, S304 reads). Prints one JSON line of every clock and
# boot marker an unprivileged app can read, and (mark) sets a volatile per-logon marker.
#   clockprobe.py read|mark
import ctypes
import json
import subprocess
import sys
import time
import uuid
import winreg
from ctypes import wintypes

k32 = ctypes.windll.kernel32
k32.GetTickCount64.restype = ctypes.c_ulonglong
qpc, qpf = ctypes.c_longlong(), ctypes.c_longlong()
k32.QueryPerformanceCounter(ctypes.byref(qpc))
k32.QueryPerformanceFrequency(ctypes.byref(qpf))
unbiased = ctypes.c_ulonglong()
k32.QueryUnbiasedInterruptTime(ctypes.byref(unbiased))  # 100 ns units, excludes sleep and hibernate
interrupt = ctypes.c_ulonglong()
try:
    ctypes.windll.kernelbase.QueryInterruptTime(ctypes.byref(interrupt))  # 100 ns, includes sleep (Win10 1803+)
    interrupt_s = interrupt.value / 1e7
except (AttributeError, OSError):
    interrupt_s = None
tick_ms = k32.GetTickCount64()
wall = time.time()
out = {
    "wall": round(wall, 3),
    "tick_s": tick_ms / 1000,                        # GetTickCount64: since boot, includes sleep
    "qpc_s": qpc.value / qpf.value,                  # QueryPerformanceCounter
    "unbiased_s": unbiased.value / 1e7,              # QueryUnbiasedInterruptTime
    "interrupt_s": interrupt_s,                      # QueryInterruptTime
    "py_monotonic": time.monotonic(),
    "py_monotonic_impl": time.get_clock_info("monotonic").implementation,
    "py_perf_impl": time.get_clock_info("perf_counter").implementation,
    "boot_from_tick": round(wall - tick_ms / 1000),  # boot time derived from the tick count (S302 candidate)
}
try:  # BootId: a counter Windows increments at every boot (S302 candidate)
    with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
                        r"\PrefetchParameters") as k:
        out["boot_id"] = winreg.QueryValueEx(k, "BootId")[0]
except OSError as e:
    out["boot_id"] = f"unreadable: {e}"
KEY = r"Software\KodeeboSpikeVolatile"
try:
    with winreg.OpenKey(winreg.HKEY_CURRENT_USER, KEY) as k:
        out["volatile_marker"] = winreg.QueryValueEx(k, "nonce")[0]
except OSError:
    out["volatile_marker"] = None
if sys.argv[1] == "mark":
    # REG_OPTION_VOLATILE through the Win32 API (winreg has no volatile flag): lost when the hive unloads
    adv = ctypes.windll.advapi32
    hk = wintypes.HKEY()
    disp = wintypes.DWORD()
    rc = adv.RegCreateKeyExW(wintypes.HKEY(0x80000001), KEY, 0, None, 1, 0xF003F, None, ctypes.byref(hk),
                             ctypes.byref(disp))  # HKCU, REG_OPTION_VOLATILE = 1, KEY_ALL_ACCESS
    if rc == 0:
        nonce = uuid.uuid4().hex[:12]
        data = ctypes.create_unicode_buffer(nonce)
        adv.RegSetValueExW(hk, "nonce", 0, 1, data, ctypes.sizeof(data))
        adv.RegCloseKey(hk)
        out["volatile_marker_set"] = nonce
    else:
        out["volatile_marker_error"] = rc
# Kernel-Boot event 27 (boot type: 0 cold boot, 1 hybrid/Fast Startup, 2 resume from hibernate) and Kernel-General 1
# (system time changed): readable by the cashier?
for name, q in (("boot_event_27", "*[System[Provider[@Name='Microsoft-Windows-Kernel-Boot'] and (EventID=27)]]"),
                ("time_changed_event_1", "*[System[Provider[@Name='Microsoft-Windows-Kernel-General'] and (EventID=1)]]")):
    r = subprocess.run(["wevtutil", "qe", "System", f"/q:{q}", "/c:1", "/rd:true", "/f:text"], capture_output=True,
                       text=True)
    txt = (r.stdout or r.stderr).strip().replace("\r", "")
    out[name] = {"rc": r.returncode, "date": next((ln.split(":", 1)[1].strip() for ln in txt.splitlines()
                                                   if ln.strip().startswith("Date:")), None),
                 "desc": " ".join(txt.split("Description:", 1)[1].split())[:200] if "Description:" in txt else txt[:200]}
print(json.dumps(out))
