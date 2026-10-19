# S12 (tier-E): candidate WebAuthn / TOTP libraries - latest version, release date, licence, OSV advisories.
# usage: python3 -I s12-libs.py   (stdlib only; network: GitHub API, Maven Central, npm registry, OSV; ~ a few hundred KB total)
import json, urllib.request, datetime, sys
def get(url, data=None):
    req=urllib.request.Request(url, data=data, headers={'User-Agent':'kodeebo-research','Accept':'application/json','Content-Type':'application/json'})
    return json.load(urllib.request.urlopen(req, timeout=40))
print('run (UTC):', datetime.datetime.now(datetime.timezone.utc).isoformat())
maven=[('com.webauthn4j','webauthn4j-core','webauthn4j/webauthn4j'),
       ('com.yubico','webauthn-server-core','Yubico/java-webauthn-server'),
       ('com.eatthepath','java-otp','jchambers/java-otp'),
       ('dev.samstevens.totp','totp','samdjstevens/java-totp')]
for g,a,repo in maven:
    print('\n==',g+':'+a,'repo',repo)
    try:
        r=get('https://search.maven.org/solrsearch/select?q=g:%22'+g+'%22+AND+a:%22'+a+'%22&rows=1&wt=json')
        d=r['response']['docs']
        if not d: print('maven: not found'); ver=None
        else:
            ver=d[0]['latestVersion']; ts=d[0]['timestamp']/1000
            print('maven latest',ver,datetime.datetime.fromtimestamp(ts,datetime.timezone.utc).date())
    except Exception as e: print('maven error',e); ver=None
    try:
        m=get('https://api.github.com/repos/'+repo)
        print('github licence',(m.get('license') or {}).get('spdx_id'),'archived',m.get('archived'),'pushed',m.get('pushed_at'))
    except Exception as e: print('github error',e)
    if ver:
        try:
            o=get('https://api.osv.dev/v1/query',json.dumps({'package':{'name':g+':'+a,'ecosystem':'Maven'},'version':ver}).encode())
            print('OSV hits at',ver,':',[v['id'] for v in o.get('vulns',[])])
        except Exception as e: print('osv error',e)
print('\n== npm @simplewebauthn/browser, @simplewebauthn/server')
for n in ('@simplewebauthn/browser','@simplewebauthn/server'):
    try:
        pk=get('https://registry.npmjs.org/'+n.replace('/','%2F'))
        v=pk['dist-tags']['latest']
        print(n,v,pk['time'][v][:10],'licence',pk['versions'][v].get('license'))
        o=get('https://api.osv.dev/v1/query',json.dumps({'package':{'name':n,'ecosystem':'npm'},'version':v}).encode())
        print('OSV hits at',v,':',[x['id'] for x in o.get('vulns',[])])
    except Exception as e: print(n,'error',e)
print('\n== control: OSV must return hits for a known-bad version')
o=get('https://api.osv.dev/v1/query',json.dumps({'package':{'name':'org.apache.logging.log4j:log4j-core','ecosystem':'Maven'},'version':'2.14.1'}).encode())
print('log4j-core 2.14.1 hits:',len(o.get('vulns',[])))
