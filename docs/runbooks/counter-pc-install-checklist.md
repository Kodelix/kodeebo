# Counter PC — on-site install checklist

**Status:** started 2026-10-20 with the first decided item. More items are gathered here as they are decided.
**Used by:** Kodelix staff during the on-site install of the cashier app on a venue's counter PC (guided installs: ADR-0004 Decision 8).
**Needs:** a Windows administrator account on the counter PC, used only during the install. The cashier never works as an administrator (sync note OQ27).

## 1. Keep the PC booting after power flickers (founder decision 2026-10-20, sync spike finding P4-F1)

**Why.** Windows starts its Recovery environment automatically after "Two consecutive unexpected shutdowns that occur within two minutes of boot completion" ([Windows RE technical reference](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-recovery-environment--windows-re--technical-reference)). The power at a venue often comes back and drops again within minutes. When that happens the PC stops at "Recovery — It looks like Windows didn't load correctly" and waits for someone to press "Restart my PC", so the counter stays down. Reproduced on the spike VM. With the two settings below it booted normally through three such cuts (`prototypes/local-first-sync-spike/README.md`, "Phase 4", P4-F1).

**Apply** (administrator command prompt):

```bat
bcdedit /set {current} recoveryenabled No
bcdedit /set {current} bootstatuspolicy IgnoreAllFailures
```

**Check:** `bcdedit /enum {current}` shows `recoveryenabled No` and `bootstatuspolicy IgnoreAllFailures`.

**Revert** (for example before a repair visit, or when the venue changes PCs):

```bat
bcdedit /set {current} recoveryenabled Yes
bcdedit /deletevalue {current} bootstatuspolicy
```

`bcdedit /deletevalue` restores the Windows default policy ([BCDEdit /set](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set); "Any change to a boot option requires a restart to take effect").

**Cost, to tell the owner:** a PC that genuinely cannot boot no longer opens automatic repair by itself. A repair then needs the Advanced startup menu or recovery media.

**If BitLocker is on:** "Before setting BCDEdit options you might need to disable or suspend BitLocker and Secure Boot on the computer" (BCDEdit /set page). Suspend BitLocker before the two commands and resume it after.

**Recommend to the owner:** a small UPS for the counter PC, so that short cuts do not reach the PC at all. These settings are the fallback, not the fix.

**Record in the install report:** the two settings were applied (yes / no), BitLocker state, and whether the owner was told about the UPS.
