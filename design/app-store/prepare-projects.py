"""Build editable appearance decks using the installed skill's existing renderer."""
import json
from pathlib import Path
root=Path(__file__).resolve().parent
copy=[('QRコードを','かざすだけ','Point. Scan.','Done.','QR READER'),('開く前に','内容を確認','See the link.','Then open it.','CHECK FIRST'),('読み取ったら','履歴で見返す','Your scans,','kept in history.','SCAN HISTORY'),('コピーも','共有もすぐ','Copy it.','Share it.','COPY & SHARE')]
for mode in ['dark','light']:
 accent='#4FD6BF' if mode=='dark' else '#00796B'
 fg='#F2F7F6' if mode=='dark' else '#112E2B'
 bg='#0B1013' if mode=='dark' else '#EAF3F0'
 decks={d:[] for d in ['iphone','ipad','duo-outer','duo-outer-landscape','duo-inner','duo-inner-landscape','tvos','watchos','carplay','mac','android','android-7','android-10','feature-graphic','creative-universal','creative-header','creative-search']}
 for device,(W,H,ratio) in {'iphone':(1320,2868,1022/2082),'ipad':(2064,2752,.7123)}.items():
  slides=[]
  fs=128 if device=='iphone' else 186
  for i,(ja1,ja2,en1,en2,label) in enumerate(copy):
   captionY=150 if i!=2 else H*.793
   devH=H*.725 if i!=3 else H*.68
   devW=devH*ratio
   x=(W-devW)/2; y=H-devH-65
   if i==2: y=55
   if i==3:x=W*.042
   s={'id':f'{device}-{mode}-{i+1}','layout':['hero','device-bottom','device-top','two-devices'][i], 'label':{'ja':label,'en':label},'headline':{'ja':ja1,'en':en1},'screenshot':f'/screenshots/apple/{device}/{mode}/{{locale}}/{i+1:02}.png','backgroundColor':bg,'typography':{'headlineScale':fs/(W*.092),'labelScale':1.1},'transforms':{'caption':{'x':W*.07,'y':captionY,'width':W*.86,'height':fs*2.6,'zIndex':5},'device':{'x':x,'y':y,'width':devW,'height':devH,'rotation':0,'zIndex':3}},'textElements':[{'id':'accent-line','text':{'ja':ja2,'en':en2},'fontSize':fs,'fontWeight':700,'color':accent,'align':'center','transform':{'x':W*.07,'y':captionY+W*.051+fs*.98,'width':W*.86,'height':fs*1.25,'zIndex':5}}]}
   if i==3:
    sh=H*.585; sw=sh*ratio
    s['screenshotSecondary']=f'/screenshots/apple/{device}/{mode}/{{locale}}/02.png'
    s['transforms']['deviceSecondary']={'x':W-sw-W*.025,'y':H-sh-100,'width':sw,'height':sh,'rotation':0,'zIndex':2}
   slides.append(s)
  decks[device]=slides
 p={'schemaVersion':3,'appName':'QRReader','themeId':'qrreader-teal' if mode=='dark' else 'qrreader-light','fontId':'system-sans','connectedCanvas':True,'locales':['ja','en'],'locale':'ja','device':'iphone','orientation':'portrait','appIcon':'/app-icon.png','slidesByDevice':decks,'scene':{'backdrop':'spotlight' if mode=='dark' else 'gradient','span':False,'decoration':'rings','shadow':40,'glow':14 if mode=='dark' else 0,'tilt':0,'headlineWeight':700,'headlineScale':1,'headlineCase':'as-typed','captionAlign':'center'}}
 (root/'projects'/f'{mode}.json').write_text(json.dumps(p,ensure_ascii=False,indent=2)+'\n')
print('Prepared Japanese/English, light/dark decks for iPhone and iPad')
