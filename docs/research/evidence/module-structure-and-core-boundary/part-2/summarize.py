# SCRATCH / evidence script (part 2): summarise JUnit XML of the spike. Usage: python3 -I summarize.py <results-dir> <label>
import sys, glob, xml.etree.ElementTree as ET
d, label = sys.argv[1], sys.argv[2]
print(f"== {label}")
for f in sorted(glob.glob(d + "/*.xml")):
    r = ET.parse(f).getroot()
    print(f"suite {r.get('name')} tests={r.get('tests')} failures={r.get('failures')} errors={r.get('errors')} suite_seconds={r.get('time')}")
    for tc in r.findall("testcase"):
        st = "FAIL" if (tc.find("failure") is not None or tc.find("error") is not None) else ("SKIP" if tc.find("skipped") is not None else "PASS")
        print(f"  {st:4} {tc.get('name'):60} {tc.get('time')}s")
