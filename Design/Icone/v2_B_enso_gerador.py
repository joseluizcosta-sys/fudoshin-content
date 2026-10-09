import math, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter
def enso(size, color, seed=7, R=0.36, W=0.085, start=-50, sweep=325):
    S=size*3; img=Image.new('L',(S,S),0); d=ImageDraw.Draw(img)
    rnd=random.Random(seed); cx=cy=S/2; r0=R*S; w0=W*S
    nb=70; bristles=[(rnd.uniform(-0.5,0.5), rnd.uniform(0.55,1.0), rnd.uniform(0.80,1.0)) for _ in range(nb)]
    steps=1400
    for b,(off,dens,life) in enumerate(bristles):
        pts=[]
        for i in range(steps):
            t=i/(steps-1)
            if t>life: break
            ang=math.radians(start - sweep*t)   # sentido horário na tela
            wob=1+0.025*math.sin(t*9+seed)
            w=w0*(0.75+0.55*math.sin(math.pi*min(1,t*1.15))**0.6)*(1-0.55*t**3)
            r=r0*wob+off*w
            x=cx+r*math.cos(ang); y=cy+r*math.sin(ang)
            # falhas de pincel seco no fim
            gap = t>0.6 and rnd.random() < (t-0.6)*0.9*(1-dens)
            if gap:
                if len(pts)>1: d.line(pts,fill=255,width=max(2,int(S*0.004))); 
                pts=[]
            else: pts.append((x,y))
        if len(pts)>1: d.line(pts,fill=255,width=max(2,int(S*0.004)))
    # cabeça do traço: pincel pousando (gota arredondada)
    a=math.radians(start); bx=cx+r0*math.cos(a); by=cy+r0*math.sin(a)
    for k in range(30):
        rr=w0*0.52*(1-k/40); ox=rnd.uniform(-1,1)*w0*0.05; oy=rnd.uniform(-1,1)*w0*0.05
        d.ellipse((bx-rr+ox,by-rr+oy,bx+rr+ox,by+rr+oy),fill=255)
    img=img.filter(ImageFilter.GaussianBlur(S*0.0012)).resize((size,size),Image.LANCZOS)
    layer=Image.new('RGBA',(size,size),color); layer.putalpha(img); return layer
def kanji(size, color, scale=0.48, dy=0.0, font='/tmp/claude-0/fonts/YujiBoku-Regular.ttf'):
    ft=ImageFont.truetype(font,int(size*scale)); L=Image.new('RGBA',(size,size),(0,0,0,0)); d=ImageDraw.Draw(L)
    bb=d.textbbox((0,0),'動',font=ft); w=bb[2]-bb[0]; h=bb[3]-bb[1]
    d.text(((size-w)/2-bb[0],(size-h)/2-bb[1]+dy*size),'動',font=ft,fill=color); return L
def paper(size,base,seed=3,amp=6):
    rnd=random.Random(seed); n=Image.effect_noise((size,size),amp*4).filter(ImageFilter.GaussianBlur(1.2))
    bg=Image.new('RGB',(size,size),base); 
    return Image.blend(bg, Image.merge('RGB',[n,n,n]).point(lambda v: v), 0.03).convert('RGBA')
def icon(variant,size=1024):
    if variant=='claro':
        bg=paper(size,'#F2EDE4'); e=enso(size,(224,112,42,255)); k=kanji(size,(17,17,17,255))
    elif variant=='escuro':
        bg=Image.new('RGBA',(size,size),(18,20,23,255)); e=enso(size,(232,122,52,255)); k=kanji(size,(242,237,228,255))
    elif variant=='mono':
        bg=Image.new('RGBA',(size,size),(0,0,0,255)); e=enso(size,(150,150,150,255)); k=kanji(size,(255,255,255,255))
    bg.alpha_composite(e); bg.alpha_composite(k); return bg.convert('RGB')
if __name__=='__main__':
    for v in ['claro','escuro','mono']:
        icon(v).save(f'/tmp/claude-0/icon/B_{v}.png')
