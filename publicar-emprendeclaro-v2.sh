#!/bin/bash
set -euo pipefail
app_name=''
app_uuid=''
while getopts ':i:n:s:' opt; do
 case "$opt" in i) app_uuid="$OPTARG" ;; n|s) app_name="$OPTARG" ;; *) exit 64 ;; esac
done
[[ "$(id -un)" == 'emprendeclaro' ]] || exit 77
[[ "$app_name" == 'emprendeclaro_publicar_v2' ]] || exit 64
[[ "$(pwd -P)" == '/home/emprendeclaro/apps/emprendeclaro_publicar_v2' ]] || exit 77
[[ ! -e private && ! -L private ]] || exit 73
umask 077
/usr/local/bin/python3.11 -m venv venv
./venv/bin/python -m pip install opalstack
./venv/bin/python - "$app_uuid" <<'PUBLISH'
import hashlib, json, os, pathlib, re, sys, urllib.request
import opalstack
app_id=sys.argv[1]
if not re.fullmatch(r'[0-9a-f-]{36}',app_id): raise SystemExit('Invalid app identifier')
if os.environ.get('API_URL','').replace('https://','').rstrip('/')!='my.opalstack.com': raise SystemExit('Unexpected API origin')
token=os.environ.get('OPAL_TOKEN','')
if not token: raise SystemExit('Installer authorization missing')
api=opalstack.Api(token=token)
site_id='a57682b3-645b-4fd2-bb71-54346a762c45'
site=api.sites.read(site_id)
if isinstance(site,list): site=site[0]
if site['name']!='emprendeclaro' or site['domains']!=['b0424c10-655d-4b73-9551-b0be83a7e385']:
    raise SystemExit('Site identity changed; no changes applied')
if site['server']!='90c96461-ad20-4323-95c4-ed1c98ce385f' or not site['redirect'] or not site['generate_le']:
    raise SystemExit('HTTPS or server settings changed; no changes applied')
routes=site['routes']
if len(routes)!=1 or routes[0]['uri']!='/' or routes[0]['app']!='2a044437-0bc7-4726-bf0a-a1fe6fafcbc5':
    raise SystemExit('Existing route changed; no changes applied')
apps=api.apps.list_all()
def find_app(name):
    found=[a for a in apps if a['name']==name]
    if len(found)!=1: raise SystemExit('Ambiguous application')
    return found[0]
front=find_app('emprendeclaro_demo_v2')
back=find_app('emprendeclaro_ai_demo_v2')
if front['osuser']!=back['osuser'] or front['type']!='STA' or back['type']!='CUS':
    raise SystemExit('Application ownership/type mismatch')
front_index=pathlib.Path('/home/emprendeclaro/apps/emprendeclaro_demo_v2/index.html')
if hashlib.sha256(front_index.read_bytes()).hexdigest()!='eefc707fa055adad3d35e80c6b654fef556edc69b057762fac4c78ed661d7173': raise SystemExit('Frontend verification failed')
with urllib.request.urlopen('http://127.0.0.1:'+str(back['port'])+'/api/status',timeout=5) as response:
    health=json.load(response)
if health.get('ai_available') is not False: raise SystemExit('Unexpected AI activation')
private=pathlib.Path('private');private.mkdir(mode=0o700)
(private/'previous-site.json').write_text(json.dumps(site,indent=2))
# Only the two authorized routes change. Domain, certificates, IP and HTTPS remain untouched.
api.sites.update([{'id':site_id,'routes':[{'app':front['id'],'uri':'/'},{'app':back['id'],'uri':'/api'}]}])
verified=api.sites.read(site_id)
if isinstance(verified,list): verified=verified[0]
expected={'/':front['id'],'/api':back['id']}
if {r['uri']:r['app'] for r in verified['routes']}!=expected: raise SystemExit('Route verification failed')
for key in ('domains','ip4','redirect','generate_le','cert','server'):
    if verified.get(key)!=site.get(key): raise SystemExit('Unexpected site metadata change')
request=urllib.request.Request('https://my.opalstack.com/api/v1/app/installed/',data=json.dumps([{'id':app_id}]).encode(),headers={'Authorization':'Token '+token,'Content-Type':'application/json'},method='POST')
with urllib.request.urlopen(request,timeout=30) as response: response.read()
print('EmprendeClaro routes connected. Unrelated sites were not modified.')
PUBLISH
