# S10 helper (tier-E tool, not a finding): strip HTML to text, then print short context windows for regexes.
# usage: python3 -I s10-extract-context.py <html_in> <txt_out> <regex> [<regex> ...]
import sys, re, html
from html.parser import HTMLParser
class P(HTMLParser):
    def __init__(s): super().__init__(); s.o=[]; s.skip=0
    def handle_starttag(s,t,a):
        if t in('script','style'): s.skip+=1
    def handle_endtag(s,t):
        if t in('script','style'): s.skip-=1
        if t in('p','li','div','h1','h2','h3','h4','h5','dd','dt','tr','section'): s.o.append('\n')
    def handle_data(s,d):
        if not s.skip: s.o.append(d)
src,dst,*pats=sys.argv[1:]
p=P(); p.feed(open(src,encoding='utf-8',errors='replace').read())
t=re.sub(r'[ \t]+',' ',''.join(p.o)); t=re.sub(r'\n\s*\n+','\n',t)
open(dst,'w').write(t)
print('text chars',len(t))
for pat in pats:
    ms=list(re.finditer(pat,t))
    print('\n=== PATTERN',pat,'matches',len(ms))
    for m in ms[:3]:
        a=max(0,m.start()-250); b=min(len(t),m.end()+450)
        print('---'); print(t[a:b].replace('\n',' '))
