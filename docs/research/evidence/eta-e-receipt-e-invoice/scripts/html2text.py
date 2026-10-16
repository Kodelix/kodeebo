#!/usr/bin/env python3
"""Strip HTML to plain text (tier-E helper). Usage: python3 -I html2text.py <in.html> <out.txt>"""
import sys
from html.parser import HTMLParser

class P(HTMLParser):
    def __init__(self):
        super().__init__(); self.out=[]; self.skip=0
    def handle_starttag(self,t,a):
        if t in("script","style"): self.skip+=1
        if t in("tr","p","li","h1","h2","h3","h4","br","div","pre","table"): self.out.append("\n")
        if t in("td","th"): self.out.append(" | ")
    def handle_endtag(self,t):
        if t in("script","style"): self.skip-=1
    def handle_data(self,d):
        if not self.skip: self.out.append(d)

p=P(); p.feed(open(sys.argv[1],encoding="utf-8",errors="replace").read())
import re
txt=re.sub(r"\n\s*\n+","\n","".join(p.out))
open(sys.argv[2],"w",encoding="utf-8").write(txt)
