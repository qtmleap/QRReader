"""Import four successful native English UI captures with locale provenance."""
import hashlib,json,shutil,sys
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parent
run=Path(sys.argv[1]).resolve();device,appearance=sys.argv[2:4]
assert device in ['iphone','ipad'] and appearance in ['dark','light']
assert '** TEST SUCCEEDED **' in (run/'xcode-tests.log').read_text()
assert (run/'ui-language.txt').read_text()=='language=en\nlocale=en_US\n'
assert 'Owned device deleted:' in (run/'cleanup.log').read_text()
attachments=run/'attachments';records=json.loads((root/'sources/manifest.json').read_text())
records=[r for r in records if (r['device'],r['appearance'],r['locale'])!=(device,appearance,'en')]
seen=set();mapping={'camera-portrait_':1,'result-url_':2,'history-portrait_':3,'system-share_':4}
for group in json.loads((attachments/'manifest.json').read_text()):
 for a in group['attachments']:
  n=next((n for prefix,n in mapping.items() if a['suggestedHumanReadableName'].startswith(prefix)),None)
  if n is None:continue
  assert n not in seen;seen.add(n)
  assert not a['isAssociatedWithFailure']
  src=attachments/a['exportedFileName'];dst=root/'sources'/device/appearance/'en'/f'{n:02}.png';dst.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src,dst)
  public=root/'editor/public/screenshots/apple'/device/appearance/'en'/dst.name;public.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src,public)
  im=Image.open(src);assert im.mode=='RGB'
  records.append({'device':device,'appearance':appearance,'locale':'en','slide':n,'source':str(src),'copied':str(dst),'sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'xcresult':str(run/'Tests.xcresult'),'testLanguage':'en','testLocale':'en_US','dimensions':list(im.size)})
assert seen=={1,2,3,4},seen
(root/'sources/manifest.json').write_text(json.dumps(records,ensure_ascii=False,indent=2)+'\n')
print(f'Imported four verified English UI images: {device}/{appearance}')
