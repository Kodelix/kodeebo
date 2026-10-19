# S51 analysis: look for a result count in each saved Wuzzuf HTML. usage: python3 -I s51-count-extract.py <dir>
import sys, re, os
d = sys.argv[1]
for f in sorted(os.listdir(d)):
    if not f.endswith('.html'): continue
    t = open(os.path.join(d, f), encoding='utf-8', errors='replace').read()
    pats = [r'(\d[\d,]*)\s+[A-Za-z\-\. ]{0,30}jobs? in', r'"(?:total|totalCount|totalResults|numberOfJobs|jobsCount)"\s*:\s*(\d+)', r'<h1[^>]*>([^<]{0,120})</h1>', r'<meta[^>]+name="description"[^>]+content="([^"]{0,200})"']
    print(f, '|', [m.group(0)[:100] for p in pats for m in list(re.finditer(p, t))[:2]])
