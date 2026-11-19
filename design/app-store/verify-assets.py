"""Verify source provenance and exported PNGs; build contact sheets and delivery ZIP."""
import hashlib, json, math
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from PIL import Image, ImageDraw, ImageFont
root=Path(__file__).resolve().parent
report={'sources':[],'exports':[],'expected':{'iphone':[1320,2868],'ipad':[2064,2752]},'localeUI':'Japanese and English headlines use corresponding native Japanese and English app UI captures.'}
source_keys=set()
for item in json.loads((root/'sources/manifest.json').read_text()):
 key=(item['device'],item['appearance'],item['locale'],item['slide']);assert key not in source_keys,key;source_keys.add(key)
 p=Path(item['copied']);digest=hashlib.sha256(p.read_bytes()).hexdigest();assert digest==item['sha256']
 public=root/'editor/public/screenshots/apple'/item['device']/item['appearance']/item['locale']/p.name
 assert hashlib.sha256(public.read_bytes()).hexdigest()==digest
 assert Path(item['xcresult']).exists()
 report['sources'].append({'path':str(p.relative_to(root)), 'locale':item['locale'],'sha256':digest,'dimensions':list(Image.open(p).size),'byteIdentical':True})
expected_sources={(d,m,l,s) for d in ['iphone','ipad'] for m in ['dark','light'] for l in ['ja','en'] for s in range(1,5)}
assert source_keys==expected_sources,{'missing':list(expected_sources-source_keys),'unexpected':list(source_keys-expected_sources)}
for mode in ['dark','light']:
 state=json.loads((root/f'projects/{mode}.json').read_text())
 assert sorted(k for k,v in state['slidesByDevice'].items() if v)==['ipad','iphone']
 for device,size in report['expected'].items():
  for locale in ['ja','en']:
   files=sorted((root/f'exports/{mode}/ios/{device}/{size[0]}x{size[1]}/{locale}').glob('*.png'));assert len(files)==4,(mode,device,locale,len(files))
   for p in files:
    im=Image.open(p);assert list(im.size)==size and im.mode=='RGB',(p,im.size,im.mode)
    report['exports'].append({'path':str(p.relative_to(root)),'dimensions':list(im.size),'mode':im.mode,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
assert len(report['sources'])==32 and len(report['exports'])==32
for appearance in ['dark','light']:
 for device in ['iphone','ipad']:
  with ZipFile(root/f'exports/{appearance}/{device}.zip','w',ZIP_DEFLATED) as bundle:
   for item in report['exports']:
    if item['path'].startswith(f'exports/{appearance}/ios/{device}/'):
     bundle.write(root/item['path'],Path(item['path']).relative_to(f'exports/{appearance}'))
font=ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc',24)
for device,(W,H) in report['expected'].items():
 for locale in ['ja','en']:
  thumbW=300;thumbH=round(thumbW*H/W);pad=18;top=64;label=48
  sheet=Image.new('RGB',(pad+4*(thumbW+pad),top+2*(thumbH+label+pad)),'#DDE8E4');d=ImageDraw.Draw(sheet)
  d.text((pad,18),f'QRReader / {device} / {locale.upper()} / DARK + LIGHT',font=font,fill='#173D37')
  for row,mode in enumerate(['dark','light']):
   y=top+row*(thumbH+label+pad);d.text((pad,y),mode.upper(),font=font,fill='#173D37')
   files=[r for r in report['exports'] if r['path'].startswith(f'exports/{mode}/ios/{device}/') and f'/{locale}/' in r['path']]
   for col,r in enumerate(files):
    im=Image.open(root/r['path']);im=im.resize((thumbW,thumbH),Image.Resampling.LANCZOS);sheet.paste(im,(pad+col*(thumbW+pad),y+label))
  sheet.save(root/f'preview-{device}-{locale}.png')
# Shared compact overview includes every image, without cropping a slide.
thumbW=220; gap=14; rowHs=[math.ceil(thumbW*H/W)+52 for W,H in [report['expected'][d] for d in ['iphone','iphone','ipad','ipad']]]
height=48+sum(h*2 for h in rowHs);allview=Image.new('RGB',(4*(thumbW+gap)+gap,height),'#DDE8E4');d=ImageDraw.Draw(allview);y=10
for device in ['iphone','ipad']:
 W,H=report['expected'][device];th=round(thumbW*H/W)
 for locale in ['ja','en']:
  for mode in ['dark','light']:
   d.text((gap,y),f'{device.upper()} / {locale.upper()} / {mode.upper()}',font=font,fill='#173D37');y+=36
   files=[r for r in report['exports'] if r['path'].startswith(f'exports/{mode}/ios/{device}/') and f'/{locale}/' in r['path']]
   for col,r in enumerate(files): allview.paste(Image.open(root/r['path']).resize((thumbW,th),Image.Resampling.LANCZOS),(gap+col*(thumbW+gap),y))
   y+=th+16
allview.save(root/'all-32-screens.png')
(root/'validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
with ZipFile(root/'QRReader-AppStore-Screenshots.zip','w',ZIP_DEFLATED) as archive:
 for r in report['exports']:
  p=root/r['path'];archive.write(p,Path(r['path']).relative_to('exports'))
 for p in [root/'validation.json',root/'editor/README.md',root/'sources/manifest.json', *root.glob('preview-*.png'),root/'all-32-screens.png']:
  archive.write(p,p.name if p.name!='README.md' else 'README.md')
print(f'Verified {len(report["sources"])} unmodified sources and {len(report["exports"])} RGB PNGs; wrote previews and ZIP.')
