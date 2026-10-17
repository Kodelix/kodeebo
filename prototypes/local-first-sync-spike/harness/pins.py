# PROTOTYPE - NOT FOR PRODUCTION
# Guard against a silent change of a suite's cell list (found when SC-25a's toxic leaked into phase 2 through a
# shared table and gave phase 2 an untested cell, seen only at the end of a 1 h 40 min regression).
# The pinned lists live in README.md, section "Pinned cell lists", as lines of the form
#   `pinned <name>: a, b, c`
# A suite calls check() before it runs anything; a mismatch stops it with a clear message.
import os
import re

README = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "README.md")


class PinMismatch(SystemExit):
    pass


def pinned(name):
    m = re.search(rf"`pinned {re.escape(name)}: ([^`]*)`", open(README, encoding="utf-8").read())
    if not m:
        raise PinMismatch(f"README.md has no pinned list '{name}' (section 'Pinned cell lists')")
    return [x.strip() for x in m.group(1).split(",") if x.strip()]


def check(name, actual):
    want = pinned(name)
    actual = list(actual)
    if actual != want:
        added = [x for x in actual if x not in want]
        removed = [x for x in want if x not in actual]
        raise PinMismatch(
            f"PINNED LIST MISMATCH for '{name}': README.md pins {want}, the code has {actual}. "
            f"Added: {added or 'none'}; removed: {removed or 'none'}"
            f"{'; same names, different order' if not added and not removed else ''}. "
            "If the change is intended, update the pinned list in README.md (section 'Pinned cell lists') in the "
            "same commit; otherwise keep the new case out of the shared table.")
