#!/bin/bash
set -euo pipefail
app_name=''
app_uuid=''
while getopts ':i:n:s:' opt; do
 case "$opt" in i) app_uuid="$OPTARG" ;; n|s) app_name="$OPTARG" ;; *) exit 64 ;; esac
done
[[ "$(id -un)" == 'emprendeclaro' ]] || exit 77
[[ "$app_name" == 'emprendeclaro_update_v3' ]] || exit 64
[[ "$(pwd -P)" == '/home/emprendeclaro/apps/emprendeclaro_update_v3' ]] || exit 77
umask 077
/usr/local/bin/python3.11 - "$app_uuid" <<'UPDATE'
import base64,hashlib,io,json,os,pathlib,re,signal,stat,sys,tarfile,tempfile,time,urllib.request,subprocess
WEB=pathlib.Path('/home/emprendeclaro/apps/emprendeclaro_demo_v2')
API=pathlib.Path('/home/emprendeclaro/apps/emprendeclaro_ai_demo_v2')
RUN=pathlib.Path.cwd()
app_id=sys.argv[1]
if not re.fullmatch(r'[0-9a-f-]{36}',app_id): raise SystemExit('Unexpected app ID')
for folder in (WEB,API,RUN,WEB/'assets'):
    if folder.resolve()!=folder or folder.stat().st_uid!=os.getuid() or not folder.is_dir(): raise SystemExit('Unexpected application directory')
def owned(path):
    item=path.lstat()
    if not stat.S_ISREG(item.st_mode) or item.st_uid!=os.getuid() or item.st_nlink!=1: raise SystemExit('Unexpected file ownership')
def health():
    with urllib.request.urlopen('http://127.0.0.1:1090/api/status',timeout=3) as response:return json.load(response)
def reload_api():
    pidfile=API/'gunicorn.pid'
    if pidfile.exists():
        owned(pidfile)
        pid=int(pidfile.read_text().strip())
        if pid<=1:raise SystemExit('Unexpected process')
        proc=pathlib.Path('/proc')/str(pid)
        if proc.exists():
            if proc.stat().st_uid!=os.getuid() or (proc/'cwd').resolve()!=API or b'ai_wsgi:application' not in (proc/'cmdline').read_bytes():raise SystemExit('Unexpected API process')
            os.kill(pid,signal.SIGHUP)
            return
        pidfile.unlink()
    owned(API/'gunicorn.conf.py')
    owned(API/'venv/bin/gunicorn')
    subprocess.run([str(API/'venv/bin/gunicorn'),'--config',str(API/'gunicorn.conf.py'),'ai_wsgi:application'],cwd=str(API),check=True,timeout=20)
def atomic(path,data,mode):
    if path.exists() or path.is_symlink():owned(path)
    fd,name=tempfile.mkstemp(prefix='.update-v3-',dir=str(path.parent))
    with os.fdopen(fd,'wb') as output:output.write(data);output.flush();os.fsync(output.fileno())
    os.chmod(name,mode);os.replace(name,path)
try:original_status=health()
except Exception:
    reload_api()
    for attempt in range(20):
        time.sleep(.5)
        try:original_status=health();break
        except Exception:pass
    else:raise RuntimeError('Existing API could not be recovered')
parts=[{'name': 'part-00.b64', 'size': 80000, 'sha256': 'e61b6ec780cfc367d6c4152340c81e7d741e3ad0953cdc7de79d7cacebf997ae'}, {'name': 'part-01.b64', 'size': 80000, 'sha256': '47405f8cbaf4d2e6db2cee7552b4859ac5182dc640508f1b4401c05a5b21c551'}, {'name': 'part-02.b64', 'size': 80000, 'sha256': 'fa3500f1b5d4eb01ffd5f0ebe5da6f60c3de0edc5e18ff53b81df3cd511a9f3d'}, {'name': 'part-03.b64', 'size': 80000, 'sha256': '9e9d81aed955342e9e4f6fa03521a57550f1f8f8fbf246ac463de7632ce8db0c'}, {'name': 'part-04.b64', 'size': 80000, 'sha256': '9a479f0b454899a6e46aae1dee98c46d258b9c774918b73d9742a0641646dfc6'}, {'name': 'part-05.b64', 'size': 80000, 'sha256': 'd2d723a62cc17c74059e8052a1df03c2b58b152f177ed251a5ec698f9c672ba2'}, {'name': 'part-06.b64', 'size': 80000, 'sha256': '1665021d38b2246b1560431011300b64d3b74569104016ee4d411ca94a1b5bc9'}, {'name': 'part-07.b64', 'size': 80000, 'sha256': '638a8a9f07fdef3cb4ee7eaa488382c823ea6c2d236a99239088c9c9913cee3a'}, {'name': 'part-08.b64', 'size': 80000, 'sha256': 'aab38175c4f81e442dc784091c381118776293ffe452458ff343a5e22fa7f682'}, {'name': 'part-09.b64', 'size': 80000, 'sha256': 'c5f780ad0e6ea273ec5d5c5fc77e760cbe785646029c5929e894fcc865259813'}, {'name': 'part-10.b64', 'size': 80000, 'sha256': 'd3b549b788064a47094abd1bc0311058b25dcd7a5e20d65c6c169d3e54b3e324'}, {'name': 'part-11.b64', 'size': 80000, 'sha256': '49c50c1f55b006b0ae79bb7b3ca610ae73c8fd1610065805e6a38c056b130ee8'}, {'name': 'part-12.b64', 'size': 80000, 'sha256': '06c986b5b4f08e8383d88cdee8d44c4a84e43fa2b29c915cd8d9aa112d749e00'}, {'name': 'part-13.b64', 'size': 80000, 'sha256': 'b75bab1a641ba483c9206c295a38a9e72f2b9022c7be514e072528faae7ecdd1'}, {'name': 'part-14.b64', 'size': 80000, 'sha256': 'ace5a4dd771a2f6343e1fc88a059b24b5924687e96ae4bb9255e29e9019de55d'}, {'name': 'part-15.b64', 'size': 80000, 'sha256': 'f6ba63ce99cdf3c9e11bfb49236ab6eb55801e7a5aac8168aa361874fa2b23b1'}, {'name': 'part-16.b64', 'size': 80000, 'sha256': '7700a682258bcd868b3e24cb92ddc29d2745d2f6f7c4e723df9897cb95628639'}, {'name': 'part-17.b64', 'size': 80000, 'sha256': '69840482e5107fad9b8367bc8524720f10e1a5f0bdd3507b472ea38f02f15a81'}, {'name': 'part-18.b64', 'size': 80000, 'sha256': '3957353822759a848b216ee8733aa2f4d018ccbaaaad83c8e70b50764ee90600'}, {'name': 'part-19.b64', 'size': 80000, 'sha256': '2bde9d84b7143f23b6cbdc4008e4cbfad41d809f985d981f7c319725815c6db4'}, {'name': 'part-20.b64', 'size': 80000, 'sha256': '90d1b8501ecf31b5c3a4794af687922038502457c597acac7f0ebe544e43fe06'}, {'name': 'part-21.b64', 'size': 80000, 'sha256': '0bfe400c5474a215845daecaa687f505f6503215e33b55443dd896206b32699d'}, {'name': 'part-22.b64', 'size': 80000, 'sha256': '87dbfdc2288dce938176281365c902960cb61f2c19532d714b9df9c914457c3f'}, {'name': 'part-23.b64', 'size': 80000, 'sha256': '13d56e40b5219da0edd595192d5051f97c9fc96a39adbfbfdc4000178b11c42a'}, {'name': 'part-24.b64', 'size': 80000, 'sha256': '42f05cf33af09fe024460269fada365a074e140a900caa20feee704d374526be'}, {'name': 'part-25.b64', 'size': 46740, 'sha256': 'ce7be2a2164508d9d1165985ae153b894f547955ecc6ba7e8a6690f56cd8067b'}]
encoded=[]
for part in parts:
    url='https://raw.githubusercontent.com/proyectoretomarketing-del/emprendeclaro-deploy/215cb2f923df085c3b582b0bb09f575e2afa3b25/release-v3/'+part['name']
    with urllib.request.urlopen(url,timeout=30) as response:data=response.read(100001)
    if len(data)!=part['size'] or hashlib.sha256(data).hexdigest()!=part['sha256']:raise SystemExit('Invalid release part')
    encoded.append(data)
payload=base64.b64decode(b''.join(encoded),validate=True)
if hashlib.sha256(payload).hexdigest()!='3720440c07b452608c52402f0cdbb0c3dceaa943a1d1bc7c9089b90890e42848':raise SystemExit('Release checksum mismatch')
allowed=['index.html', 'revision.html', 'styles.css', 'experience.css', 'content.js', 'ideas.js', 'app.js', 'journey.js', 'bounded-ai.js', 'assets/Manrope-OFL.txt', 'assets/hero.webp', 'assets/ideas-1.webp', 'assets/ideas-2.webp', 'assets/ideas-3.webp', 'assets/ideas-4.webp', 'assets/ideas-5.webp', 'assets/manrope-400.woff', 'assets/manrope-500.woff', 'assets/manrope-600.woff', 'assets/manrope-700.woff', 'assets/manrope-800.woff', 'assets/teacher.webp', 'api/ai_wsgi.py']
contents={}
with tarfile.open(fileobj=io.BytesIO(payload),mode='r:gz') as archive:
    if set(m.name for m in archive.getmembers())!=set(allowed):raise SystemExit('Unexpected release files')
    for member in archive.getmembers():
        if not member.isfile() or member.size>2500000:raise SystemExit('Unexpected archive member')
        contents[member.name]=archive.extractfile(member).read()
backup=RUN/('backup-'+str(int(time.time())))
backup.mkdir(mode=0o700)
targets={name:(API/'ai_wsgi.py' if name=='api/ai_wsgi.py' else WEB/name) for name in allowed}
for name,path in targets.items():
    if path.exists():
        owned(path);copy=backup/name;copy.parent.mkdir(parents=True,exist_ok=True,mode=0o700);copy.write_bytes(path.read_bytes())
applied=[]
try:
    # Primero el backend; se conserva la clave, la cookie, la base de datos y la configuración privada.
    atomic(API/'ai_wsgi.py',contents['api/ai_wsgi.py'],0o600);applied.append('api/ai_wsgi.py');reload_api()
    for attempt in range(30):
        time.sleep(.5)
        try:
            updated=health()
            if updated.get('version')=='3.0.0' and updated.get('ai_available')==original_status.get('ai_available'):break
        except Exception:pass
    else:raise RuntimeError('Updated API health check failed')
    # index.html se escribe al final: no se sirve la nueva entrada antes de sus recursos.
    for name in [x for x in allowed if x not in ('api/ai_wsgi.py','index.html')]+['index.html']:
        atomic(targets[name],contents[name],0o644);applied.append(name)
    print('EmprendeClaro v3 installed. AI and images per access: 3. Existing site routes and secrets preserved.')
except Exception:
    for name in reversed(applied):
        old=backup/name
        if old.exists():atomic(targets[name],old.read_bytes(),0o600 if name=='api/ai_wsgi.py' else 0o644)
    reload_api()
    raise
host=os.environ.get('API_URL','').replace('https://','').rstrip('/')
token=os.environ.get('OPAL_TOKEN','')
if host!='my.opalstack.com' or not token:raise SystemExit('Update completed; installer notification unavailable')
req=urllib.request.Request('https://'+host+'/api/v1/app/installed/',data=json.dumps([{'id':app_id}]).encode(),headers={'Authorization':'Token '+token,'Content-Type':'application/json'},method='POST')
with urllib.request.urlopen(req,timeout=20) as response:
    if not 200<=response.status<300:raise SystemExit('Installer status could not be updated')
UPDATE
