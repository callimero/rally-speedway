pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- rally speedway
-- nachbau des c64-originals
-- (john anderson, 1983/84)
-- doku: struktur.md,
--       revisionen.md
-- tab 0: einstellungen, _init,
--        _update60, _draw
-- tab 1: spiel (menue, rennen,
--        autos, blau, effekte)
-- tab 2: welt, technik, helfer

--== spielgefuehl ==

-- tempo
tempo_wahl={60,80,100,120,150}
                -- menue (mph)
px_mph=0.02     -- px/frame je mph
beschl_wahl={0.006,0.012,0.024}
                -- langsam/normal/
                -- schnell
bremse=0.03     -- bremsknopf

-- haftung: querkorrektur/frame,
-- darueber rutscht der wagen
grip_wahl={0.03,0.018,0.013}
                -- trocken/nass/eis
rutsch_ab=0.15  -- ab da quietscht
                -- es + bremsspur

-- lenkung: 32 richtungen,
-- einschlag sammelt sich
lenk_tempo=0.0055 -- umdr./frame
lenk_voll=0.5   -- ab tempo voll
lenk_erste=2    -- einschlag fuer
                -- 1. stufe (tipp
                -- = nur drift)
lenk_stufe=1    -- ... jede weitere
lenk_drift=0.7  -- fahrt geht vor-
                -- her mit (0..1)
lenk_rueck=0.05 -- einschlag zurueck
                -- je frame

-- gelaende (anteil vmax/grip)
gras_max=0.45
grip_gras=0.7
wasser_max=0.3
grip_wasser=0.5
gelaende_bremse=0.03
busch_crash=0.6 -- px/frame: ab da
                -- brennt es im busch
busch_max=0.25  -- tempo im busch
-- aquaplaning
aqua_ab=0.75    -- tempo beim rein-
                -- fahren (anteil)
aqua_bremse=0.02 -- verlust/frame
aqua_grip=0.3
aqua_lenk=0.3

-- blau (computergegner)
gegner_tempo=0.98 -- grundtempo
gegner_anpassen=0.025 -- gummi-
                -- band je feld
gegner_min=0.8  -- tempo-grenzen
gegner_max=1.08
gegner_blick=20 -- px voraus auf
                -- der ideallinie
gegner_kurve=0.9 -- bremst vor
                -- kurven
gegner_toleranz=0.008 -- lenkt ab
                -- dieser abweichung
gegner_brems=0.08 -- bremst ab
                -- dieser abweichung
rempel_abstand=7 -- px
rempel_stoss=0.4 -- abprall
rempel_pause=20 -- frames je knall

-- kamera
kam_folgen=0.05 -- 1 = starr
kam_vorschau=40 -- frames voraus
                -- (0 = original)
kam_rand=14     -- abstand zum rand

-- unfall
brenn_ab=0.7    -- anteil vmax: ab
                -- da brennt fahrer
fahrer_tempo=7  -- frames je bild
feuer_tempo=5   -- frames je bild
unfall_nach=30  -- frames bis neu
ziel_winken=120 -- frames winken,
                -- dann auswertung

--== optik + ton ==

gegner_farbe=12 -- blau statt gelb
overall_gelb=10 -- overall gelb
                -- (sprite: 12)
fahrer_farbe=7  -- haut/helm
belag_farbe={6,13,12} -- strasse
belag_spur={5,5,13}   -- spuren
bremsspur_ab=0.5 -- beim bremsen
spur_max=600    -- spurpunkte
gischt_menge=0.5 -- spritzwasser
gischt_max=80
rauch_auto=0.35 -- chance/frame
rauch_fahrer=0.2
rauch_steig=0.25
rauch_wind=0.12
rauch_wachs=0.04
rauch_gross=3.5
rauch_dauer=70
rauch_max=60
motor_min=3     -- tonhoehe stand
motor_max=32    -- ... bei vmax
motor_kurve=0.7 -- <1: erst schnell

--== menue-startwerte ==
start_wahl={gegner=2,runden=3,
 strecke=1,strasse=1,tempo=2,
 beschl=2}

--== testen ==
zeige_linie=false -- ideallinie
nur_blau=false  -- nur blau faehrt

--== ende einstellungen ==

function _init()
 -- bildschirm-farben: 1 wasser,
 -- 10 gelb (wie c64), 2 grau
 -- der haeuser, 4 mittelgruen
 pal(1,140,1)
 pal(10,135,1)
 pal(2,6,1)
 pal(4,139,1)
 opt={}
 for k,v in pairs(start_wahl) do opt[k]=v end
 menuitem(1,"zum menue",function() zum_menue() end)
 zum_menue()
end

function _update60()
 if modus=="menue" then
  update_menue()
 elseif modus=="hilfe" or modus=="info" then
  if (btnp(4) or btnp(5)) modus="menue"
 elseif modus=="ergebnis" then
  update_ergebnis()
 else
  update_rennen()
 end
end

function _draw()
 if modus=="menue" then
  draw_menue()
 elseif modus=="hilfe" then
  draw_hilfe()
 elseif modus=="info" then
  draw_info()
 else
  draw_rennen()
  if (modus=="ergebnis") draw_ergebnis()
 end
end
-->8
-- spiel

-- @strecken (erzeugt von original.py, nicht von hand aendern)
-- raster und ideallinien liegen im sfx-speicher (sfx 8-63),
-- s. lade_strecke. strassenpunkt je teil (px im teil, fuer neustart):
teil_punkt=split("32,28,58,22,30,26,30,26,30,26,30,26,30,34,34,34,30,22,34,22,26,30,38,30,26,26,38,26,46,18,18,38,46,38,18,18,38,26,26,26,30,34,30,22,32,28,32,28,32,28,32,28,32,28,32,28,32,28")
-- sprite des grauen strassen-zeichens (oeffnungen der teile)
strasse_spr=2
-- @ende

-- ====== menue ======
menue={
 {"hilfe","steuerung/hilfe",nil,"hilfe"},
 {"strecke","strecke",{"1","2","3","4","5","6"}},
 {"gegner","gegner",{"nein","ja"}},
 {"runden","runden",{1,2,3,4,5,6}},
 {"strasse","strasse",{"trocken","nass","eis"}},
 {"tempo","hoechst-tempo",tempo_wahl},
 {"beschl","beschleunigung",{"langsam","normal","schnell"}},
 {"info","ueber das spiel",nil,"info"},
}

function zum_menue()
 modus="menue"
 sfx(-1,0) sfx(-1,1)
 menue_zeile=2
 menue_oben=1
 menue_bild=0
 vorschau_fuer=nil
end

function update_menue()
 -- liste stoppt oben und unten
 if (btnp(2)) menue_zeile=max(menue_zeile-1,1)
 if (btnp(3)) menue_zeile=min(menue_zeile+1,#menue)
 menue_oben=mid(menue_zeile-menue_zeilen+1,menue_oben,menue_zeile)
 local m=menue[menue_zeile]
 if m[3] then
  local n=#m[3]
  if (btnp(0)) opt[m[1]]=(opt[m[1]]-2)%n+1
  if (btnp(1)) opt[m[1]]=opt[m[1]]%n+1
 end
 if btnp(4) or btnp(5) then
  if m[3] then
   neues_rennen()
  else
   modus=m[4]
  end
 end
 menue_bild+=1
 -- vorschau neu bei anderer
 -- strecke oder belag
 local k=opt.strecke*10+opt.strasse
 if k!=vorschau_fuer then
  vorschau_fuer=k
  lade_strecke(opt.strecke)
  karte_malen(vorschau_x,vorschau_y,belag_farbe[opt.strasse])
 end
end

function draw_menue()
 cls(11)
 -- banner, blau faehrt drueber
 rectfill(0,0,127,19,6)
 for x=0,127 do
  local c=x%4<2 and 8 or 7
  pset(x,0,c) pset(x,19,c)
 end
 print("\^w\^trally",26,5,0)
 print("\^w\^trally",25,4,10)
 print("speedway",71,8,0)
 pal(10,gegner_farbe)
 draw_auto(menue_bild%152-12,10,0.25)
 pal(10,10)
 -- scrollliste: menue_zeilen
 -- sichtbar, pfeile wenn mehr
 for j=1,menue_zeilen do
  local i=menue_oben+j-1
  local m=menue[i]
  local c=i==menue_zeile and 10 or 7
  local s=m[2]
  if m[3] then
   local w=m[3][opt[m[1]]]
   if (m[1]=="tempo") w..=" mph"
   if (i==menue_zeile) w="\139 "..w.." \145"
   s..="  "..w
  end
  mitte(s,22+j*8,c)
 end
 if (menue_oben>1) mitte("\148",22,6)
 if (menue_oben+menue_zeilen<=#menue) mitte("\131",22+(menue_zeilen+1)*8,6)
 if (not kurs) return
 karte_zeigen(vorschau_x,vorschau_y)
 -- punkt faehrt den kurs ab,
 -- start/ziel blinkt
 local f=kurs[flr(t()*12)%#kurs+1]
 local x,y=karte_xy(vorschau_x,vorschau_y,feld_punkt(f))
 circfill(x,y,1,10)
 if t()%0.8<0.5 then
  x,y=karte_xy(vorschau_x,vorschau_y,feld_punkt(kurs[1]))
  rectfill(x-1,y-2,x,y+2,7)
 end
 -- start-hinweis blinkt (1 hz)
 if (t()%1<0.5) mitte("rennen starten \151",vorschau_y+22,10)
end

-- seite: schwarz, kopfzeile mit
-- randsteinen, unten "zurueck"
function seite(titel)
 cls(0)
 rectfill(0,0,127,9,6)
 for x=0,127 do
  local c=x%4<2 and 8 or 7
  pset(x,0,c) pset(x,9,c)
 end
 mitte(titel,3,10)
 if (t()%1<0.6) mitte("\151/\142 = zurueck",118,6)
end

function draw_hilfe()
 seite("steuerung")
 local z={
  {"\139\145","lenken wie rc-car"},
  {"\151/\142","bremsen"},
  {"\148\131\139\145","losfahren"},
  {"\131+\142","zurueck ins menue"},
 }
 for i,l in ipairs(z) do
  schrift(l[1],4,8+i*9,10)
  schrift(l[2],42,8+i*9,7)
 end
 mitte("tipps",64,10)
 local tipps={
  "gas gibt der wagen allein",
  "kurz tippen: seitlich driften",
  "blau passt sich dir an",
  "+zeit rueckstand, -vorsprung",
 }
 for i,l in ipairs(tipps) do
  schrift(l,4,65+i*8,7)
 end
end

-- inhalt folgt noch
function draw_info()
 seite("ueber das spiel")
 local z={
  "rally speedway fuer pico-8",
  "",
  "nach dem c64-original von",
  "john anderson (1983/84)",
  "",
  "grafik: callimero",
  "",
  "(mehr folgt)",
 }
 for i,l in ipairs(z) do
  mitte(l,14+i*9,7)
 end
end

-- ====== streckenkarte ======
-- kurs als linie, 2 px je teil,
-- einmal in einen puffer gemalt

-- welt-px -> karten-px
function karte_xy(x0,y0,wx,wy)
 return x0+wx/32,y0+wy/28
end

function karte_malen(x0,y0,sc)
 poke(0x5f55,karte_puffer)
 camera()
 rectfill(x0-2,y0-2,x0+65,y0+52,3)
 for i=1,#kurs do
  local ax,ay=feld_punkt(kurs[i])
  local bx,by=feld_punkt(kurs[i%#kurs+1])
  -- nicht quer ueber die karte
  -- (sprung ueber den welt-rand)
  if abs(bx-ax)<teil_b*2 and abs(by-ay)<teil_h*2 then
   local x1,y1=karte_xy(x0,y0,ax,ay)
   local x2,y2=karte_xy(x0,y0,bx,by)
   line(x1,y1,x2,y2,sc)
  end
 end
 poke(0x5f55,0x60)
end

function karte_zeigen(x0,y0)
 local a=(x0-2)\2
 local n=(x0+65)\2-a+1
 for y=y0-2,min(y0+52,127) do
  local o=y*64+a
  memcpy(0x6000+o,karte_puffer*256+o,n)
 end
end

-- ====== rennen ======

function neues_rennen()
 modus="rennen"
 vmax=tempo_wahl[opt.tempo]*px_mph
 beschl=beschl_wahl[opt.beschl]
 grip=grip_wahl[opt.strasse]
 lade_strecke(opt.strecke)
 -- start im startteil (pfeile),
 -- faehrt nach rechts
 local x,y=feld_punkt(kurs[1])
 x-=teil_b\2-12
 auto=new_auto(x,y-6,0.25)
 auto.vmax=vmax
 gegner=nil
 if nur_blau then
  auto.vmax=vmax*gegner_tempo
 elseif opt.gegner==2 then
  gegner=new_auto(x,y+6,0.25)
  gegner.vmax=vmax*gegner_tempo
 end
 rennzeit=0
 gestartet=false
 kx,ky=auto.x-64,auto.y-64
 puffer_voll=true
 init_spur()
 rauch={}
 gischt={}
 quietscht=false
 motor_an=false
 sieger=nil
 ziel_t=nil
 sfx(-1,0) sfx(-1,1)
end

-- ein auto (gelb oder blau):
-- x,y   mitte (welt-px)
-- a     fahrtrichtung 0..1
--       (0 = hoch, im uhrzeiger)
-- k     sprite-richtung 0-31
-- l     lenk-einschlag (stufen)
-- vx,vy bewegung (px/frame)
-- v,vq  tempo laengs/quer
-- unfall frames seit crash
-- nxt   naechstes kurs-feld
-- runde, rz (rundenzeit),
-- zeiten (fertige runden),
-- beste
-- zb[fortschritt]=rennzeit
-- (fuer den abstand)
function new_auto(x,y,a)
 local k=flr(a*32+0.5)%32
 local t={x=x,y=y,a=k/32,k=k,l=0,
  vx=0,vy=0,v=0,vq=0,unfall=0,
  nxt=2,runde=1,rz=0,zeiten={},zb={}}
 t.pz=fortschritt(t)
 t.zb[t.pz]=0
 return t
end

function update_rennen()
 local t=auto
 -- runter + o: ins menue
 if btn(3) and btn(4) then
  zum_menue()
  return
 end
 if not gestartet then
  -- start: irgendeine richtung
  for b=0,3 do
   if (btn(b) or nur_blau) gestartet=true
  end
 else
  rennzeit+=1
  if (not t.fertig) t.rz+=1
  if (gegner and not gegner.fertig) gegner.rz+=1
  if t.unfall>0 then
   update_unfall(t)
  elseif t.fertig then
   im_ziel(t)
  else
   local turn,br=0,btn(4) or btn(5)
   if (btn(0)) turn-=1
   if (btn(1)) turn+=1
   if (nur_blau) turn,br=ki_eingabe(t)
   update_auto(t,turn,br)
   unfall_start(t,pruefe_unfall(t))
   pruefe_kurs(t)
  end
  if gegner then
   update_gegner(gegner)
   -- beide ausgestiegen: noch
   -- winken, dann auswertung
   if auto.fahrer and auto.fertig and gegner.fahrer and gegner.fertig then
    ziel_t=(ziel_t or 0)+1
    if (ziel_t>=ziel_winken) rennen_ende()
   end
  end
 end
 update_rauch()
 update_gischt()
 update_kamera(t)
 update_ton(t)
end

-- fahrphysik fuer beide autos.
-- turn -1/0/1 (relativ zur
-- fahrtrichtung), brems = knopf
function update_auto(t,turn,brems)
 local vmax=t.vmax
 local wirk=min(abs(t.v)/lenk_voll,1)
 if (t.aqua) wirk*=aqua_lenk
 -- einschlag sammeln; t.dreht:
 -- taste gehalten nach einer
 -- stufe -> kein anlauf mehr
 if turn!=0 then
  if (turn!=t.dreht) t.dreht=nil
  t.l+=turn*lenk_tempo*32*wirk
 else
  t.dreht=nil
  t.l=sgn(t.l)*max(abs(t.l)-lenk_rueck,0)
 end
 local schwelle=t.dreht and lenk_stufe or lenk_erste
 if abs(t.l)>=schwelle then
  local s=sgn(t.l)
  t.k=(t.k+s)%32
  t.l-=s*schwelle
  t.dreht=s
 end
 t.a=(t.k+mid(-1,t.l,1)*lenk_drift)/32%1

 -- bewegung laengs (f), quer (r)
 local fx,fy=-sin(t.a),-cos(t.a)
 local rx,ry=-fy,fx
 local v=t.vx*fx+t.vy*fy
 local vq=t.vx*rx+t.vy*ry

 -- untergrund; aquaplaning wenn
 -- schnell genug ins wasser
 local b=boden(t.x,t.y)
 local g,vm=grip,vmax
 if b==b_wasser then
  if (not t.aqua and not t.wasser_vor and v>=vmax*aqua_ab) t.aqua=true
  if (t.aqua and v<vmax*aqua_ab*0.6) t.aqua=false
 else
  t.aqua=false
 end
 t.wasser_vor=b==b_wasser
 if b==b_gras then
  g*=grip_gras vm*=gras_max
 elseif t.aqua then
  v=max(v-aqua_bremse,0)
  g*=aqua_grip vm=v
 elseif b==b_wasser then
  g*=grip_wasser vm*=wasser_max
 elseif b==b_busch then
  g*=grip_gras vm*=busch_max
 end

 -- gas automatisch, knopf bremst
 t.bremst=false
 if brems then
  t.bremst=v>bremsspur_ab
  v=v>0 and max(v-bremse,0) or min(v+bremse,0)
 elseif v<vm then
  v=min(v+beschl,vm)
 else
  v=max(v-gelaende_bremse,vm)
 end

 -- haftung: querbewegung nur bis
 -- grip weg, sonst rutscht er
 if abs(vq)<=g then
  vq=0
 else
  vq-=sgn(vq)*g
 end
 t.rutscht=abs(vq)>rutsch_ab
 t.v,t.vq=v,vq

 t.vx=fx*v+rx*vq
 t.vy=fy*v+ry*vq
 t.x+=t.vx
 t.y+=t.vy
 if (t==auto) welt_rum(t)

 if (t.rutscht or t.bremst) spur_stempeln(t)
 if (opt.strasse==2) spritzen(t,b_strasse)
 if (t.aqua) spritzen(t,b_wasser,3)
end

-- crash an einer der 4 ecken?
-- gibt tempo beim aufprall
function pruefe_unfall(t)
 local sp=sqrt(t.vx^2+t.vy^2)
 for e in all(auto_ecken) do
  local x,y=welt_punkt(t,e[1],e[2])
  local b=boden(x,y)
  if b==b_fest or b==b_busch and sp>busch_crash then
   t.unfall=1
   t.nach=unfall_nach
   t.vx,t.vy,t.v,t.vq=0,0,0,0
   t.rutscht=false
   return sp
  end
 end
end

-- fahrer springt raus, bei hohem
-- tempo brennt er
function unfall_start(t,sp)
 if (not sp) return
 t.fahrer={x=t.x,y=t.y,i=1,z=0,
  dir=rnd()<0.5 and -1 or 1,
  folge=sp>=t.vmax*brenn_ab
   and folge_brenn or folge_lauf}
 sfx(2,2)
end

function update_unfall(t)
 t.unfall+=1
 if (rnd()<rauch_auto) neuer_rauch(t.x,t.y-3)
 local f=t.fahrer
 if fahrer_brennt[f.folge[min(f.i,#f.folge)]]
 and rnd()<rauch_fahrer then
  neuer_rauch(f.x,f.y-3)
 end
 if f.i<=#f.folge then
  f.z+=1
  if f.z>=fahrer_tempo then
   f.z=0
   f.x+=fahrer_weg[f.folge[f.i]]*f.dir
   f.i+=1
  end
  return
 end
 t.nach-=1
 if t.nach<=0 then
  t.unfall=0
  t.fahrer=nil
  neustart(t)
 end
end

-- neu im letzten kurs-feld,
-- blick zum naechsten
function neustart(t)
 local ax,ay=feld_punkt(kurs[(t.nxt-2)%#kurs+1])
 local bx,by=feld_punkt(kurs[t.nxt])
 t.x,t.y=ax,ay
 t.k=flr(richtung(ax,ay,ax+welt_dx(bx-ax),ay+welt_dy(by-ay))*32+0.5)%32
 t.l=0 t.a=t.k/32
end

-- kurs-felder der reihe nach
-- (zwei duerfen fehlen), feld 1
-- = start/ziel
function pruefe_kurs(t)
 local f=feld(t.x,t.y)
 for s=0,2 do
  local i=(t.nxt-1+s)%#kurs+1
  if kurs[i]==f then
   if i==1 or i<t.nxt then
    runde_fertig(t)
   end
   t.nxt=i%#kurs+1
   -- zeit je feld merken
   local p=fortschritt(t)
   for q=t.pz+1,p do t.zb[q]=rennzeit end
   t.pz=max(t.pz,p)
   return
  end
 end
end

function runde_fertig(t)
 t.runde+=1
 add(t.zeiten,t.rz)
 if (not t.beste or t.rz<t.beste) t.beste=t.rz
 t.rz=0
 if (t==auto) sfx(3,2)
 -- im ziel: erster = sieger,
 -- ende wenn beide da sind
 if gegner and t.runde>opt.runden then
  t.fertig=true
  sieger=sieger or t
 end
end

-- im ziel: ausrollen, aussteigen,
-- winken bis der andere kommt
function im_ziel(t)
 local f=t.fahrer
 if not f then
  update_auto(t,0,true)
  if t.v<0.05 then
   t.vx,t.vy,t.v,t.vq=0,0,0,0
   local x,y=welt_punkt(t,10,0)
   t.fahrer={x=x,y=y,i=1,z=0,dir=1,folge=folge_wink}
  end
 else
  f.z+=1
  if f.z>=fahrer_tempo then
   f.z=0
   f.i=f.i%#f.folge+1
  end
 end
end

-- gefahrene felder insgesamt
function fortschritt(t)
 return t.runde*#kurs+t.nxt
end

function update_kamera(t)
 local zx=t.x+t.vx*kam_vorschau-64
 local zy=t.y+t.vy*kam_vorschau-64
 kx+=(zx-kx)*kam_folgen
 ky+=(zy-ky)*kam_folgen
 kx=mid(t.x-128+kam_rand,kx,t.x-kam_rand)
 ky=mid(t.y-128+kam_rand,ky,t.y-kam_rand)
end

function update_ton(t)
 -- motor aus, solange er brennt
 -- oder ausgestiegen ist
 local an=gestartet and t.unfall==0 and not (t.fertig and t.fahrer)
 if an!=motor_an then
  motor_an=an
  sfx(an and 0 or -1,0)
 end
 local p=motor_min+(motor_max-motor_min)*mid(0,abs(t.v)/vmax,1)^motor_kurve
 motor_ton(flr(p))
 local q=t.rutscht and t.unfall==0
 if q!=quietscht then
  quietscht=q
  sfx(q and 1 or -1,1)
 end
end

-- ====== zeichnen ======

function draw_rennen()
 -- kamera aus dem gerundeten
 -- abstand zum auto (kein
 -- 1-px-zittern)
 local t=auto
 local cx=flr(t.x)-flr(t.x-kx+0.5)
 local cy=flr(t.y)-flr(t.y-ky+0.5)
 puffer_nach(cx,cy)
 draw_puffer(cx,cy)
 camera(cx,cy)
 draw_spur()
 if (zeige_linie) draw_linie()
 local g=gegner
 if g then
  -- blau relativ zu gelb runden
  draw_wagen(g,flr(t.x)+flr(g.x-t.x+0.5),flr(t.y)+flr(g.y-t.y+0.5),true)
 end
 draw_wagen(t,t.x,t.y,nur_blau)
 draw_gischt()
 draw_rauch()
 camera()
 draw_anzeige()
 if (g) gegner_pfeil(g,cx,cy)
end

-- auto, beim crash mit feuer
-- und fahrer
function draw_wagen(t,x,y,blau)
 if (blau) pal(10,gegner_farbe)
 draw_auto(x,y,t.k/32)
 pal(10,10)
 if t.unfall>0 then
  palt(0,false) palt(15,true)
  spr(feuer_spr+t.unfall\feuer_tempo%3,flr(x)-4,flr(y)-4)
  palt()
  draw_fahrer(t.fahrer,not blau and overall_gelb)
 elseif t.fertig and t.fahrer then
  draw_fahrer(t.fahrer,not blau and overall_gelb)
 end
end

function draw_fahrer(f,overall)
 local n=f.folge[min(f.i,#f.folge)]
 palt(0,false) palt(15,true)
 pal(7,fahrer_farbe)
 pal(12,overall or 12)
 spr(fahrer_spr[n],flr(f.x)-4,flr(f.y)-4,1,1,f.dir<0)
 pal(7,7) pal(12,12) palt()
end

-- anzeige unten wie im original
function draw_anzeige()
 local w=auto
 schrift("time",9,114,7)
 schrift(zeit_text(w.rz),5,121,7)
 schrift("last",57,114,7)
 schrift(zeit_text(w.zeiten[#w.zeiten]),52,121,7)
 schrift("best",104,114,7)
 schrift(zeit_text(w.beste),99,121,7)
 if gegner then
  schrift("runde "..min(w.runde,opt.runden).."/"..opt.runden,2,2,7)
  -- abstand: + rueckstand,
  -- - vorsprung
  local d=abstand()
  local a=abs(d)
  local s=(d>0 and "+" or d<0 and "-" or " ")..a\60 .."."..a%60\6
  schrift(s,126-#s*4,2,d>0 and 7 or 10)
 else
  schrift("runde "..w.runde,2,2,7)
 end
 if not gestartet and t()%1<0.6 then
  schrift("joystick = start",33,56,10)
 end
 if w.fertig and t()%1<0.7 then
  mitte(sieger==w and "gewonnen!" or "ziel!",40,10)
 end
end

-- ====== blau ======

function update_gegner(g)
 local crash=g.unfall>0
 if crash then
  update_unfall(g)
 elseif g.fertig then
  im_ziel(g)
 else
  -- gummiband: vorn langsamer,
  -- hinten schneller
  local d=fortschritt(g)-fortschritt(auto)
  g.vmax=vmax*mid(gegner_min,gegner_tempo-d*gegner_anpassen,gegner_max)
  update_auto(g,ki_eingabe(g))
 end
 -- immer nahe am spieler
 -- rechnen (ring-welt)
 g.x=auto.x+welt_dx(g.x-auto.x)
 g.y=auto.y+welt_dy(g.y-auto.y)
 if (crash) return
 if (not g.fertig) unfall_start(g,pruefe_unfall(g)) pruefe_kurs(g)
 if (auto.unfall==0) rempeln(auto,g)
end

-- computer faehrt: ziel auf der
-- ideallinie gegner_blick
-- voraus, bremst vor kurven.
-- gibt turn, bremse zurueck
function ki_eingabe(g)
 local n=#kurs
 local i0=(g.nxt-3)%n+1
 local pts={}
 for s=0,11 do
  local x,y=linie_punkt((i0-1+s\4)%n+1,s%4/4,g.x,g.y)
  add(pts,{x,y,abs(x-g.x)+abs(y-g.y)})
 end
 -- erst ab dem naechsten punkt
 -- zum auto suchen
 local m=1
 for k=2,#pts do
  if (pts[k][3]<pts[m][3]) m=k
 end
 local z=pts[#pts]
 for k=m,#pts do
  if pts[k][3]>=gegner_blick then
   z=pts[k] break
  end
 end
 g.zx,g.zy=z[1],z[2]
 local w=(richtung(g.x,g.y,z[1],z[2])-g.a+0.5)%1-0.5
 local turn=w<-gegner_toleranz and -1 or w>gegner_toleranz and 1 or 0
 -- drehung der linie ueber die
 -- naechsten 3 felder
 local dreh,ra=0
 for s=0,3 do
  local i=(g.nxt-2+s)%n+1
  local j=i%n+1
  local r=richtung(0,0,welt_dx(linie_x[j]-linie_x[i]),welt_dy(linie_y[j]-linie_y[i]))
  if (ra) dreh+=abs((r-ra+0.5)%1-0.5)
  ra=r
 end
 local vz=g.vmax*max(0.35,1-dreh*gegner_kurve)
 return turn,g.v>vz or abs(w)>gegner_brems and g.v>g.vmax*0.5
end

-- ideallinie: catmull-rom-kurve
-- von punkt i nach i+1 bei u
-- (0..1), nahe rx,ry
function linie_punkt(i,u,rx,ry)
 local n=#kurs
 local px,py={},{}
 for k=-1,2 do
  local j=(i-1+k)%n+1
  px[k]=rx+welt_dx(linie_x[j]-rx)
  py[k]=ry+welt_dy(linie_y[j]-ry)
 end
 local u2=u*u
 local u3=u2*u
 local function cr(a,b,c,d)
  return 0.5*(2*b+(c-a)*u+(2*a-5*b+4*c-d)*u2+(3*b-a-3*c+d)*u3)
 end
 return cr(px[-1],px[0],px[1],px[2]),
  cr(py[-1],py[0],py[1],py[2])
end

-- abstand zu blau in frames:
-- + rueckstand, - vorsprung
function abstand()
 local pa,pg=fortschritt(auto),fortschritt(gegner)
 if (pa<pg) return rennzeit-(gegner.zb[pa] or rennzeit)
 if (pa>pg) return (auto.zb[pg] or rennzeit)-rennzeit
 return 0
end

-- autos stossen sich ab
function rempeln(a,b)
 local dx,dy=b.x-a.x,b.y-a.y
 if (abs(dx)>rempel_abstand or abs(dy)>rempel_abstand) return
 local d=sqrt(dx*dx+dy*dy)
 if (d>=rempel_abstand or d==0) return
 local nx,ny=dx/d,dy/d
 local o=(rempel_abstand-d)/2
 a.x-=nx*o a.y-=ny*o
 b.x+=nx*o b.y+=ny*o
 local va=a.vx*nx+a.vy*ny
 local vb=b.vx*nx+b.vy*ny
 if va>vb then
  -- bewegung tauschen, abprallen
  a.vx+=(vb-va)*nx-nx*rempel_stoss
  a.vy+=(vb-va)*ny-ny*rempel_stoss
  b.vx+=(va-vb)*nx+nx*rempel_stoss
  b.vy+=(va-vb)*ny+ny*rempel_stoss
  if t()>(rempel_t or 0) then
   sfx(4,3)
   rempel_t=t()+rempel_pause/60
  end
 end
end

-- blau ausser sicht: punkt am
-- bildrand (nicht in der schrift)
function gegner_pfeil(g,cx,cy)
 local x,y=g.x-cx,g.y-cy
 if (x>=0 and x<128 and y>=0 and y<128) return
 local px,py=mid(3,x,124),mid(11,y,110)
 circfill(px,py,2,0)
 circfill(px,py,1,gegner_farbe)
end

-- ====== rennende ======

function rennen_ende()
 modus="ergebnis"
 ergebnis_t=0
 sfx(-1,0) sfx(-1,1)
 sfx(3,2)
end

function update_ergebnis()
 ergebnis_t+=1
 update_rauch()
 if (ergebnis_t>60 and (btnp(4) or btnp(5))) zum_menue()
end

function draw_ergebnis()
 rectfill(8,22,119,109,0)
 rect(8,22,119,109,7)
 mitte(sieger==auto and "gelb gewinnt!" or "blau gewinnt!",28,sieger==auto and 10 or 12)
 schrift("runde",14,42,6)
 schrift("gelb",58,42,10)
 schrift("blau",92,42,12)
 local sa,sg=0,0
 for r=1,opt.runden do
  local y=42+r*7
  schrift(r,22,y,7)
  local a,b=auto.zeiten[r],gegner.zeiten[r]
  schrift(a and zeit_text(a) or "-",52,y,7)
  schrift(b and zeit_text(b) or "-",86,y,7)
  sa+=a or 0 sg+=b or 0
 end
 local y=46+opt.runden*7+4
 line(14,y-2,113,y-2,5)
 schrift("summe",14,y+1,6)
 schrift(#auto.zeiten>=opt.runden and zeit_text(sa) or "-",52,y+1,7)
 schrift(#gegner.zeiten>=opt.runden and zeit_text(sg) or "-",86,y+1,7)
 if (ergebnis_t>60 and t()%1<0.6) mitte("\151/\142 = menue",102,7)
end

-- ====== effekte ======

-- rauch: steigt, treibt, waechst
function neuer_rauch(x,y)
 if (#rauch>=rauch_max) return
 add(rauch,{x=x+rnd(4)-2,y=y,
  vx=rnd(0.2)-0.1,
  vy=-rauch_steig*(0.7+rnd(0.6)),
  r=0.5,l=0,
  dauer=rauch_dauer*(0.7+rnd(0.6))})
end

function update_rauch()
 for r in all(rauch) do
  r.vx+=(rauch_wind-r.vx)*0.03
  r.vy*=0.99
  r.x+=r.vx r.y+=r.vy
  r.r=min(r.r+rauch_wachs,rauch_gross)
  r.l+=1
  if (r.l>=r.dauer) del(rauch,r)
 end
end

-- dunkel -> grau -> hell, zum
-- schluss gerastert
function draw_rauch()
 for r in all(rauch) do
  local k=r.l/r.dauer
  local c=k<0.3 and 5 or k<0.65 and 13 or 6
  if (k>0.8) fillp(0b0101101001011010.1)
  circfill(r.x,r.y,r.r,c)
  fillp()
 end
end

-- spritzwasser von den hinter-
-- raedern (ub = untergrund,
-- m = mehr beim aquaplaning)
function spritzen(t,ub,m)
 local sp=sqrt(t.vx^2+t.vy^2)
 if (sp<0.3) return
 for e in all(spur_raeder) do
  if #gischt<gischt_max
  and rnd()<gischt_menge*(m or 1)*sp/vmax then
   local x,y=welt_punkt(t,e[1],e[2]+1)
   if boden(x,y)==ub then
    add(gischt,{x=x,y=y,z=0,
     vx=-t.vx*0.4+rnd(0.6)-0.3,
     vy=-t.vy*0.4+rnd(0.6)-0.3,
     vz=0.4+rnd(0.4)})
   end
  end
 end
end

function update_gischt()
 for g in all(gischt) do
  g.x+=g.vx g.y+=g.vy
  g.z+=g.vz g.vz-=0.08
  if (g.z<0) del(gischt,g)
 end
end

function draw_gischt()
 for g in all(gischt) do
  pset(g.x,g.y-g.z,g.vz>0 and 7 or 12)
 end
end

-- bremsspuren: ringpuffer
function init_spur()
 spx,spy,spc={},{},{}
 spi,spn=1,0
end

function spur_stempeln(t)
 for e in all(spur_raeder) do
  local x,y=welt_punkt(t,e[1],e[2])
  local b=boden(x,y)
  if b==b_strasse or b==b_gras then
   spx[spi],spy[spi]=flr(x),flr(y)
   spc[spi]=b==b_strasse and belag_spur[opt.strasse] or 3
   spi=spi%spur_max+1
   spn=min(spn+1,spur_max)
  end
 end
end

function draw_spur()
 for i=1,spn do
  pset(spx[i],spy[i],spc[i])
 end
end

-- test: ideallinie und ziel
-- von blau
function draw_linie()
 local n=#kurs
 local t=auto
 for s=-6,10 do
  local i=(t.nxt-1+s)%n+1
  local ax,ay=linie_punkt(i,0,t.x,t.y)
  for u=1,4 do
   local bx,by=linie_punkt(i,u/4,t.x,t.y)
   line(ax,ay,bx,by,9)
   ax,ay=bx,by
  end
  pset(t.x+welt_dx(linie_x[i]-t.x),t.y+welt_dy(linie_y[i]-t.y),8)
 end
 local c=nur_blau and auto or gegner
 if (c and c.zx) circ(c.zx,c.zy,1,8)
end
-->8
-- welt, technik, helfer

-- ====== technik ======
-- sprites: auto 2x2 in 9 rich-
-- tungen (rest gespiegelt),
-- feuer 98-100, fahrer 104-111
-- und 120-126, sonst c64-zeichen
richt_spr={[0]=64,66,68,70,72,74,76,78,96}
feuer_spr=98
-- fahrer: c64-bildnummer ->
-- sprite (laeuft nach rechts)
fahrer_spr={[4]=104,[5]=105,
 [2]=106,[3]=107,[6]=108,
 [10]=109,[11]=110,[13]=111,
 [14]=120,[15]=121,[16]=122,
 [17]=123,[18]=124,[19]=125,
 [20]=126}
fahrer_weg={[4]=2,[5]=2,[2]=0,
 [3]=0,[6]=3,[10]=2,[11]=2,
 [13]=3,[14]=1,[15]=1,[16]=1,
 [17]=1,[18]=1,[19]=1,[20]=1}
fahrer_brennt={[10]=true,[11]=true,
 [13]=true,[14]=true,[15]=true,
 [16]=true,[17]=true,[18]=true,
 [19]=true,[20]=true}
-- folgen aus dem c64-code
folge_lauf=split("4,5,4,5,4,5,4,5,4,5,4,5,4,5,4,5,4,5,4,5,2,3,2,3,2,3,2,3,2,3,2,3")
folge_wink=split("2,3")
folge_brenn=split("10,11,10,11,10,11,10,11,10,11,10,11,13,16,17,18,19,20,14,15,16,17,18,19,20,14,15,16,17,18,6,2,3,2,3,2,3,2,3,2")
-- auto-punkte (rechts,vorn) px
auto_ecken={{-3,-4},{3,-4},{-4,3},{4,3}}
spur_raeder={{-4,3},{4,3}}
-- untergrund
b_strasse,b_gras,b_wasser,b_fest,b_busch=0,1,2,3,4
-- welt: 32x25 teile a 64x56 px
-- (16x14 zeichen a 4x4 px),
-- ringsum geschlossen
teil_b,teil_h=64,56
welt_b,welt_h=32*64,25*56
-- oberer speicher: welt-puffer
-- (gerade/ungerade kamera-x),
-- karte im menue
puffer={0x80,0xa0}
karte_puffer=0xc0
menue_zeilen=4 -- sichtbare zeilen
vorschau_x,vorschau_y=32,73
pyo=0 -- zeilen-versatz puffer

-- ====== strecke laden ======
-- gitter[feld]=teil 0-28 (feld=
-- zeile*32+spalte), kurs = felder
-- in fahrtrichtung, linie_x/y =
-- ideallinie je kurs-feld

function lade_strecke(nr)
 -- bitstrom in sfx 8-63, kopf:
 -- je strecke 2 byte bit-start
 bit_pos=daten_byte(nr*2-2)*256+daten_byte(nr*2-1)
 gitter={}
 for i=0,799 do
  gitter[i]=bits_lesen(1)==0 and 22 or bits_lesen(5)
 end
 kurs=kurs_bauen()
 linie_x,linie_y={},{}
 for i,f in ipairs(kurs) do
  linie_x[i]=f%32*teil_b+bits_lesen(6)
  linie_y[i]=f\32*teil_h+bits_lesen(6)
 end
end

function daten_byte(i)
 return peek(0x3200+(8+i\64)*68+i%64)
end

function bits_lesen(n)
 local v=0
 for k=1,n do
  local b=daten_byte(bit_pos\8)
  v=v*2+((b>>(7-bit_pos%8))&1)
  bit_pos+=1
 end
 return v
end

-- vom startteil nach rechts los,
-- je teil durch die andere
-- oeffnung raus (kreuzung:
-- geradeaus). richtungen:
-- 1 links 2 rechts 3 oben 4 unten
function kurs_bauen()
 local dx,dy,gegen={-1,1,0,0},{0,0,-1,1},{2,1,4,3}
 local start
 for f=0,799 do
  if (gitter[f]==1) start=f
 end
 local k,f,rein={},start,1
 repeat
  add(k,f)
  local o=oeffnungen(gitter[f])
  local raus
  if #o>2 then
   raus=gegen[rein]
  else
   for r in all(o) do
    if (r!=rein) raus=r
   end
  end
  f=(f\32+dy[raus])%25*32+(f%32+dx[raus])%32
  rein=gegen[raus]
 until f==start or #k>2000
 return k
end

-- strassen-oeffnungen eines teils
-- (graues zeichen am rand)
function oeffnungen(p)
 local mx,my=teil_map(p)
 local o,r={},{}
 for y=0,13 do
  if (mget(mx,my+y)==strasse_spr) r[1]=true
  if (mget(mx+15,my+y)==strasse_spr) r[2]=true
 end
 for x=0,15 do
  if (mget(mx+x,my)==strasse_spr) r[3]=true
  if (mget(mx+x,my+13)==strasse_spr) r[4]=true
 end
 for i=1,4 do
  if (r[i]) add(o,i)
 end
 return o
end

-- ====== welt ======

-- teil p (1-28) -> map-zelle
-- links oben (8 teile je reihe)
function teil_map(p)
 return (p-1)%8*16,(p-1)\8*14
end

function feld(x,y)
 return y\teil_h%25*32+x\teil_b%32
end

-- strassenpunkt eines feldes
function feld_punkt(f)
 local p=gitter[f]
 return f%32*teil_b+teil_punkt[p*2+1],
  f\32*teil_h+teil_punkt[p*2+2]
end

-- kuerzester weg ueber den ring
function welt_dx(d)
 return (d+welt_b\2)%welt_b-welt_b\2
end
function welt_dy(d)
 return (d+welt_h\2)%welt_h-welt_h\2
end

-- gelb ueber den rand: alles
-- mit verschieben (zahlen
-- bleiben klein)
function welt_rum(t)
 local dx,dy=0,0
 if (t.x<0) dx=welt_b
 if (t.x>=welt_b) dx=-welt_b
 if (t.y<0) dy=welt_h
 if (t.y>=welt_h) dy=-welt_h
 if (dx==0 and dy==0) return
 t.x+=dx t.y+=dy kx+=dx ky+=dy
 if (t.fahrer) t.fahrer.x+=dx t.fahrer.y+=dy
 local g=gegner
 if g then
  g.x+=dx g.y+=dy
  if (g.fahrer) g.fahrer.x+=dx g.fahrer.y+=dy
 end
 pkx+=dx pky+=dy
 pyo=(pyo-dy)%128
 for i=1,spn do
  spx[i]+=dx spy[i]+=dy
 end
 for r in all(rauch) do
  r.x+=dx r.y+=dy
 end
 for g in all(gischt) do
  g.x+=dx g.y+=dy
 end
end

-- untergrund an welt-pos: pixel
-- im zeichen-sprite. flag 0 =
-- hart (ausser gruen), flag 1 =
-- busch
function boden(x,y)
 x,y=flr(x)%welt_b,flr(y)%welt_h
 local p=gitter[feld(x,y)]
 if (p==0) return b_gras
 local lx,ly=x%teil_b,y%teil_h
 local mx,my=teil_map(p)
 local s=mget(mx+lx\4,my+ly\4)
 local c=sget(s%16*8+lx%4*2,s\16*8+ly%4*2)
 if fget(s,0) and c!=11 then
  return fget(s,1) and b_busch or b_fest
 end
 if (c==1) return b_wasser
 if (c==11 or c==3 or c==4) return b_gras
 return b_strasse
end

-- ====== welt-puffer ======
-- zwei ring-puffer 128x128:
-- welt-px x,y bei (x+o)%128,
-- (y+pyo)%128, o=0/1 fuer
-- gerade/ungerade kamera-x.
-- je bild nur neue spalten/
-- zeilen per tline zeichnen

-- teil-ausschnitt ab welt-px
-- wx,wy als tline
function puffer_tline(x,y,x2,y2,wx,wy,dx,dy)
 local p=gitter[wy\teil_h%25*32+wx\teil_b%32]
 if p==0 then
  rectfill(x,y,x2,y2,11)
 else
  local mx,my=teil_map(p)
  tline(x,y,x2,y2,mx+wx%teil_b/4,my+wy%teil_h/4,dx,dy)
 end
end

function puffer_spalte(wx,wy)
 for o=0,1 do
  poke(0x5f55,puffer[o+1])
  local x=(wx+o)%128
  local y,n=wy,128
  while n>0 do
   -- bis teil-ende/puffer-rand
   local py=(y+pyo)%128
   local k=min(min(teil_h-y%teil_h,128-py),n)
   puffer_tline(x,py,x,py+k-1,wx,y,0,0.25)
   y+=k n-=k
  end
 end
 poke(0x5f55,0x60)
end

function puffer_zeile(wx,wy)
 local y=(wy+pyo)%128
 for o=0,1 do
  poke(0x5f55,puffer[o+1])
  local x,n=wx,128
  while n>0 do
   local px=(x+o)%128
   local k=min(min(teil_b-x%teil_b,128-px),n)
   puffer_tline(px,y,px+k-1,y,x,wy,0.25,0)
   x+=k n-=k
  end
 end
 poke(0x5f55,0x60)
end

-- puffer auf kamera cx,cy
-- bringen (strasse in belag-
-- farbe)
function puffer_nach(cx,cy)
 camera()
 pal(6,belag_farbe[opt.strasse])
 if puffer_voll or abs(cx-pkx)>=128 or abs(cy-pky)>=128 then
  for wy=cy,cy+127 do puffer_zeile(cx,wy) end
  puffer_voll=false
 else
  for wx=pkx+128,cx+127 do puffer_spalte(wx,cy) end
  for wx=cx,pkx-1 do puffer_spalte(wx,cy) end
  for wy=pky+128,cy+127 do puffer_zeile(cx,wy) end
  for wy=cy,pky-1 do puffer_zeile(cx,wy) end
 end
 pkx,pky=cx,cy
 pal(6,6)
end

-- puffer auf den schirm, je
-- zeile 2 memcpy (ring)
function draw_puffer(cx,cy)
 local o=cx%2
 local q0=puffer[o+1]*256
 local xs=(cx+o)%128\2
 for y=0,127 do
  local q=q0+(cy+y+pyo)%128*64
  local z=0x6000+y*64
  memcpy(z,q+xs,64-xs)
  if (xs>0) memcpy(z+64-xs,q,xs)
 end
end

-- ====== helfer ======

-- punkt im auto (q rechts,
-- l vorn) -> welt
function welt_punkt(t,q,l)
 local fx,fy=-sin(t.a),-cos(t.a)
 return t.x+fx*-l+-fy*q,
  t.y+fy*-l+fx*q
end

-- richtung a->b (0..1, 0 = hoch,
-- im uhrzeiger)
function richtung(ax,ay,bx,by)
 return (0.25-atan2(bx-ax,by-ay))%1
end

-- auto in naechster der 32
-- richtungen (9 sprites, rest
-- gespiegelt)
function draw_auto(x,y,a)
 local k=flr(a*32+0.5)%32
 local b,fx,fy
 if k<=8 then
  b,fx,fy=k,false,false
 elseif k<=16 then
  b,fx,fy=16-k,false,true
 elseif k<=24 then
  b,fx,fy=k-16,true,true
 else
  b,fx,fy=32-k,true,false
 end
 spr_15(richt_spr[b],x,y,fx,fy)
end

-- 16x16-sprite mit mitte (7,7)
-- auf x,y; schwarz = 0, durch-
-- sichtig = 15; gespiegelt 1 px
-- versetzt
function spr_15(n,x,y,fx,fy)
 palt(0,false) palt(15,true)
 spr(n,flr(x)-7-(fx and 1 or 0),
  flr(y)-7-(fy and 1 or 0),2,2,fx,fy)
 palt()
end

-- motor: tonhoehe der noten 0+1
-- von sfx 0 live aendern
function motor_ton(p)
 for n=0,1 do
  local ad=0x3200+n*2
  poke(ad,peek(ad)&0xc0|p)
 end
end

-- text mittig (print misst die
-- breite ausserhalb des bilds)
function mitte(s,y,c)
 local w=print(s,0,-20)
 schrift(s,64-w\2,y,c)
end

-- text mit schwarzem umriss
function schrift(s,x,y,c)
 print("\^o0ff"..s,x,y,c)
end

-- zeit (frames) -> m:ss:z wie
-- im original ("2:04:7")
function zeit_text(f)
 if (not f) return "0:00:0"
 local s=f\60
 local z=f%60\6
 return s\60 ..":"..(s%60<10 and "0" or "")..s%60 ..":"..z
end
__gfx__
bbbbbbbbbbbbbbbb666666667788778866666666bbbbbbbb66666666bbbbbbbb666666668866666666666677bbbb88666677bbbb88666666666677bbbb886666
bbbbbbbbbbbbbbbb666666667788778866666666bbbbbbbb66666666bbbbbbbb666666668866666666666677bbbb88666677bbbb88666666666677bbbb886666
bbbbbbbbbbbbbbbb6666666666666666666666667788778866666666bbbbbbbb887788777766666666666688bbbb77666688bbbb77666666666688bbbb776666
bbbbbbbbbbbbbbbb6666666666666666666666667788778866666666bbbbbbbb887788777766666666666688bbbb77666688bbbb77666666666688bbbb776666
bbbbbbbbbbbbbbbb666666666666666666666666666666668877887777887788bbbbbbbb8866666666666677bbbb88666677bbbbbb88666666666677bbbb8866
bbbbbbbbbbbbbbbb666666666666666666666666666666668877887777887788bbbbbbbb8866666666666677bbbb88666677bbbbbb88666666666677bbbb8866
bbbbbbbbbbbbbbbb66666666666666668877887766666666bbbbbbbb66666666bbbbbbbb7766666666666688bbbb77666688bbbbbb77666666666688bbbb7766
bbbbbbbbbbbbbbbb66666666666666668877887766666666bbbbbbbb66666666bbbbbbbb7766666666666688bbbb77666688bbbbbb77666666666688bbbb7766
6677bbbbbbbb88667bbbbbbbbbbb778877bbbbbb6666666666666666bbbbbbbbbbbbbbbb6666666666666666bbbbbbbbbbbbbbbb8877666666778866bbbbbb88
6677bbbbbbbb88667bbbbbbbbb8877887788bbbb6666666666666666bbbbbbbbbbbbbbbb6666666666666666bbbbbbbbbbbbbbbb8877666666778866bbbbbb88
6688bbbbbbbbb77688bbbbbb77886666668877886666666666666666bbbb77887788bbbb8877666666778877bbbbbbbbbbbbbbbbbbbb88778877bbbbbbbb7766
6688bbbbbbbbb77688bbbbbb77666666666677886666666666666666bbbb77887788bbbb8877666666778877bbbbbbbbbbbbbbbbbbbb88778877bbbbbbbb7766
666677bbbbbbbb88677bbbbb666666666666666688666666667788777788666666667788bbbb887788bbbbbbbbbb77887788bbbbbbbbbbbbbbbbbbbbbb886666
666677bbbbbbbb88677bbbbb666666666666666688776666667788777788666666667788bbbb887788bbbbbbbbbb77887788bbbbbbbbbbbbbbbbbbbbbb886666
666688bbbbbbbbb76688bbbb6666666666666666bb77886688bbbbbb6666666666666666bbbbbbbbbbbbbbbb7788666666667788bbbbbbbbbbbbbbbb77666666
666688bbbbbbbbb76688bbbb6666666666666666bbbb887788bbbbbb6666666666666666bbbbbbbbbbbbbbbb7788666666667788bbbbbbbbbbbbbbbb77666666
77bbbbbb88666666666666778888888888888822228888888822888888888888888888888888882288888888882288888822888888882288888888bb888888bb
77bbbbbb88666666666666778888888888888822228888888822888888888888888888888888882288888888882288888822888888882288888888bb888888bb
6688bbbbbb776666666688bb8888888888882288882288888888228888888888888888888888888822888888882288888822888888228888888888bb228888bb
6688bbbbbb776666666688bb8888888888882288882288888888228888888888888888888888888822888888882288888822888888228888888888bb228888bb
666677bbbbbb88666677bbbb8888888888228888888822888888882288888888888888888888888888228888882288888822888888222288888888bb882288bb
666677bbbbbb88666677bbbb8888888888228888888822888888882288888888888888888888888888228888882288888822888888222288888888bb882288bb
66666688bbbbbb7788bbbbbb8888888822888888888888228888888822888888222222228888888888882288882288882288228888228822888888bb888822bb
66666688bbbbbb7788bbbbbb8888888822888888888888228888888822888888222222228888888888882288882288882288228888228822888888bb888822bb
22888888888888888822888811111111bb222222222222bbbbbbbbbbbbbb2222222222222222bbbbbbbbbbbbbb22222222111111111111222211111111111122
22888888888888888822888811111111bb222222222222bbbbbbbbbbbbbb2222222222222222bbbbbbbbbbbbbb22222222111111111111222211111111111122
88228888888888888888228811111111bb222222222222bbbbbbbb2222222222222222222222222222bbbbbbbbbb222222221111111111222211111111112222
88228888888888888888228811111111bb222222222222bbbbbbbb2222222222222222222222222222bbbbbbbbbb222222221111111111222211111111112222
88882288888888888888882211111111bb222222222222bbbbbb22222222111111111111111122222222bbbbbbbbbb2222222222222211222211222222222222
88882288888888888888882211111111bb222222222222bbbbbb22222222111111111111111122222222bbbbbbbbbb2222222222222211222211222222222222
888888bbbbbbbbbbbbbbbbbb11111111bb222222222222bbbb222222221111111111111111111122222222bbbbbbbbbbbbbb222222221122221122222222bbbb
888888bbbbbbbbbbbbbbbbbb11111111bb222222222222bbbb222222221111111111111111111122222222bbbbbbbbbbbbbb222222221122221122222222bbbb
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffff0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffff0fff0ffffffffffff0fffffffffffffff00fff0fffffffffff00fffffffffffffff00fffffffffffffffff00fffffffffffffffffffffffffffffffffff
fffff0aaa0ffffffffffff0aaf0fffffffffff0aaf00ffffffffff00affffffffffffff00fffffffffff00ffff00ffffffff00fff000ffffffff000fffffffff
fffff0aaa0ffffffffffff0aaa0ffffffffffffaaa0ffffffff00ffaaaa00ffffffffffaaaffffffff0000fffaafffffff0000fff0aaffffffff000ff000ffff
ffffffaaaffffffffffffffaaa0ffffffff00faaaafffffffff00faaaa00ffffff00faaaaaa00fffff00aaaaaaaaffffff00aaaaaaaaafffffffaaaafaafffff
ffffffaaafffffffffffffaaaffffffffff00aaaafffffffff00aaaaaffffffff000a0aaaa00ffffffffa00aaaaa00fffffaa0aaaaaa00ffffffa0aaaaaaffff
fffffaa0aafffffffff00aaaaaffffffff00a00aafffffffff00a00aaffffffff00aa000afffffffffffa000aaf00ffffffaa00aaaaa0fffffffa00aaaaaffff
fff00a000a00fffffff00a00aa00ffffff00a000afffffffffffa000afffffffffffaa0aafffffffffffaa00affffffffffaaa00aaffffffffffaa0aaf000fff
fff00aa0aa00fffffff00aa00a00ffffffffaa00a00fffffffffaa0aa00fffffffffaaaafffffffffffffaaa00ffffffffffaaaaaffffffffffffaaaffffffff
fff00faaaf00ffffffffffaaaa00fffffffffaaaa00ffffffffffaaa000fffffffffffa00fffffffffffff0000ffffffffffffa00ffffffffffff000ffffffff
ffffffffffffffffffffffffffffffffffffffff00ffffffffffffff00ffffffffffff000fffffffffffff00fffffffffffff0000ffffffffffff000ffffffff
ffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffff00fffffffffffffffffffffffffffff00fffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffff8ffffff8fffffffffffff222222bb1111111111111111fffffffffffffffffffffffffffffffffffffffffff9a9fffffaaffffffa9fff
ffffffffffffffffff89af8fffa99f8fffff9fff222222bb1111111111111111fffcccfffffcccfffffcccffffcccffffffffffffaacccafffaa9aa9ff9aaaaf
fffffffffffffffff89a89a9ff9aa89fff98a9ff2222bbbb1111112222111111fffc77fffffc77fffff77ffffff77fefffffffff9a9c77a9ffa98cc9faaaaa9a
fff000ffffffffff89a77a9ff9a77a98ffa77a9f2222bbbb1111112222111111fef77ffffff77ffffff7fffffeff7fcf5cffffffae87789afa98c77a9a9a8ccc
fff000fffffffffff9a77a9ff98a7a98f9a77aff22bbbbbb1111112222111111fccccccffccccfefffcccccffcccccffc75c6ffffcccccca9ecc779aa888cc77
ffffaaaff000ffff89a77a9ff9a77a9ff9a7789f22bbbbbb1111112222111111fffccfeffefccccffcfccfeffffccfffc7cccccfff8ccaeafa8cccea90cccc7f
fffaa0aaaaaffffff89aa98ff89aa99ff9faaaffbbbbbbbb1111112222111111fffcccffffcccffffeccccffffccccffffcc5c6cfffcccffffacccaffcccccff
fffa000aaaafffffff89aaffff8998ffffff9fffbbbbbbbb1111112222111111ff0cf0ffff0fc0ffff0ff0ffff0ff0fffffccfc0ff0cf0ffff0cfc0f0cffcfef
fffaa0aaaaafffff882288882288888888888888888888228888228866666666fffffffffff9fffffff9ffffffffffaffffffaaffffffafffffff9ff88666666
ffffaaaff000ffff882288882288888888888888888888228888228866666666fffffa9fffafffffffaaaffffffffa9affffaaffffff9fffffff9aaf88666666
fff000ffffffffff882222228822222222222222222222882222228866666666ffffaaffffaaffffffa9afffffffaa9afffa9afffffa9afffff9aaff88886666
fff000ffffffffff882222228822222222222222222222882222228866666666fffa9aaf9a9aaaffff9a9aafffaaa9aaffa9a9ffff9aa9ffffaa9aff88886666
ffffffffffffffff882222888822888888888888888822888888882266888888faa9aaffa9a9eaafaa8aa9aafa9a88afa898a8aff9a8aa9ffa9aa89f88888866
ffffffffffffffff882222888822888888888888888822888888882266888888ca9ea8a9a878c9a9a9ccccc9a9cccc8a9ccccc9afaacce89a98aea7c88888866
ffffffffffffffff882288228822888888888888888822888888888866888888c78c89a09c7cc80a8c7ccc08a77cccca80ccc7c8a08cc7ca0a9cc87c88888888
ffffffffffffffff882288228822888888888888888822888888888866888888c7ccccccfc7cccc8fc7cffff8cc98c08aaffc7cf8cccc7c8cccccccc88888888
20202020202020202061e1101010101010101010d020202020202020202020a090202020202020202020202e1010101020202020303030303030303020202020
20202020202020202020202020202020cede10cede10cede10cede10cede0f5f101010aeaebe10108f9fcede8fcede10101010101010cebede4f33337f101010
2020202020202020221010101010101010101010b020202020202020202020a09020202020202020202020c01010101020202020202020202020202020202020
2020202020202020202020202020202010101010101010101010101010102f3f101010101010101010101010101010101010101010102f3f100f1f7fcede1010
2020202020202022101010101010101010101010b020202020202020202020a09020202020202020202020c01010101020202020202020202020202020202020
202020202020202020202020202020208e9e108e9e108e9e108e9e108e9e0f5f10101010101010102f3f108e9e101010101010108e9e7f9f108e9e1010101010
2020202020202210101010101010101010101010b020202020202020202020a09020202020202020202020c01010101020202020202020202020202020202020
20202020202020202020202020202020aebe10aebe10aebe10aebe10aebe2f3f101010101010102f335f10eefe10101010101010aebecede10aebede10101010
2020202020221010101010101010101010101010b020202020202020202020a09020202020202020202020c01010101020202020202020202020202020202020
20202020202020202020202020202020101010101010101010101010102f335f1010101010cede0f1f9f10feee1010101010101010101010108f6f9f10101010
20202020221010101010101010101010101010105e20202020202020202020a09020202020202020202020e01010101020202020202020202020202020202020
2020202040404040404040402020202010cede10cede10cede10cede8f33333f101010102f3f1010101010ee9e10101010101010108ebe8f6f6f335f10cede10
202020221010101010101010101010101010107e2020202020202020202020a09020202020202020202020202110101020202020202020202020202020202020
202061e11010101010101010d1512020101010101010101010101010104f335f101010108f9f10cede1010aebe10101010108e9e9efede2f7f331f1010101010
2061e1101010101010101010101010101010105e20202020202020202020202ed02020202020202020202020e010101020202020202020202020202020202020
2022101010101010101010101010122010108e9e108e9e108e9e108e9e0f333f1010101010101010101010101010101010ceae9efefebe4f5f8ebede10101010
221010101010101010101010101010101010f12020202020202020202020203ef020202020202020202020202002101020202020202020202020202020202020
221010101010101010101010101010121010aebe10aebe10aebe10aebe2f335f101010101010101010101010101010101010aebebe10104f5f10101010101010
1010101010101010101010101010101010f1202020202020202020202020204e11202020202020202020202020200210d191514040404040404040404061a1e1
1010101010101010101010101010101010101010101010101010101010bfbf1010101010101010101010101010101010101010101010108f9fcede1010101010
1010101010101010101010101010101010101010101010101010101010101010108e9e10ceee8eeefede10108e9e9e101010101010af10af10af10af10af1010
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010cf101010101052323232323232323232324210cede10aebe101010eebe1010cedeeefefe10101010af2f336f336f336f336f333f10
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
101010cf101010101010cefede1010101032523232323232323232423210cede101010101010101010101010cebe101010102f33333333333333339fbf4f5f10
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010ceeedeaf101010feeeee101010101032325282828282828242323210cede10cede637383838383838393a3101010108f3333333333333333333faf7f1f10
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
101010df10bf10afceeedfdf10101010103232d232323232323262723210cede1052323232323232323232323232421010100f333333333333333333336f1010
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010cf1010bf10af10af10cf1010103232b252323232323232627210cede1032523232323232323232323242321010108f333333339f0f33333333336f10
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010108eee9e102f6f7f9fbf10df1010103232b232031313131313132310cede1032325232323232323232324232321010102f3333331fcede4f3333337f9f10
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
101010aeeebe2f335f10cf1010101010103232b232e26373838393a31010cede1032323237474747474747573232321010104f3333333fee8f333333333f1010
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010df2f33335f10aede10cf1010103232b232e24333333333531010cede1032323227474747474747677232321010108f7f3333336f6f333333331f1010
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10af10108f3333336f9feede10df1010103232b232e24333333333531010cede10323232c2523232323232326272321010108e9e0f3333333333335fbfcede10
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10bf1010cf0f335fbfafdf1010101010103232c232e24333333333531010cede1032324292a2523232323232326272101010aebe8f333333333333333f2f9f10
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
101010ceee9e4f6f6f9f1010cede101010324292a2e243336676335310108e9e103242323292a20313131313131323101010102f333333331f0f333333339f10
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010aebe0f1fbf101010101010101042323292f2b3c3d3e3f3561010aebe10423232323292f210101010101010101010100f339fbf4f5f8f337f339f1010
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010101010101010101010cede101010cede10101010cede1010101010101010101010101010101010101010101010bf1010bf1010bf10bf101010
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6688888888888888666666776666677b66677bbbbb886666bbbb8866bbbbbb88bbbb33333344bbbb4433334433443344bbbb44333333bbbb4433443333443344
6688888888888888666666776666677b66677bbbbb886666bbbb8866bbbbbb88bbbb33333344bbbb4433334433443344bbbb44333333bbbb4433443333443344
668888888888886666666688666688bb6688bbbbb7766666bbb77666bbbbb776bb333333443333bb3333443333334433bb334433334433bb3333334433113344
668888888888886666666688666688bb6688bbbbb7766666bbb77666bbbbb776bb333333443333bb3333443333334433bb334433334433bb3333334433113344
6666666688886666666677bb66677bbb677bbbbb88666666bb886666bbbb88663344334433334433bb334433443344bbbb443333443333bb3333443333443333
6666666688886666666677bb66677bbb677bbbbb88666666bb886666bbbb88663344334433334433bb334433443344bbbb443333443333bb3333443333443333
6666666688666666666688bb6688bbbb88bbbbbb76666666b7766666bbb776663333333333333333bb443344334433bbbbbb33443344bbbb3344444444331133
6666666688666666666688bb6688bbbb88bbbbbb76666666b7766666bbb776663333333333333333bb443344334433bbbbbb33443344bbbb3344444444331133
bb111111111111bbbbbbbb111144bbbb11111111111111bb1144bb4411111111bbbb1111111111bbbbbbbbbb44111111bbbbbbbb443344330000000000000000
bb111111111111bbbbbbbb111144bbbb11111111111111bb1144bb4411111111bbbb1111111111bbbbbbbbbb44111111bbbbbbbb443344330000000000000000
bb111111111111bbbb4411111111bbbb44111111111144bb1111441111111111bb11111111bb44bbbbbbbbbbbb4444bbbbbbbbbbbb44bbbb0000000000000000
bb111111111111bbbb4411111111bbbb44111111111144bb1111441111111111bb11111111bb44bbbbbbbbbbbb4444bbbbbbbbbbbb44bbbb0000000000000000
bb111111111144bb11111111111144bbbb111111111144bb1111111111444411bb114411111111bbbb441144bbbbbbbbbb4433bbbbbbbbbb0000000000000000
bb111111111144bb11111111111144bbbb111111111144bb1111111111444411bb114411111111bbbb441144bbbbbbbbbb4433bbbbbbbbbb0000000000000000
bb4411111111bbbb11111111111111bbbb111111111144bb1111111111bb4411bbbb441111bb44bb11111111bbbbbbbb33114433bbbbbbbb0000000000000000
bb4411111111bbbb11111111111111bbbb111111111144bb1111111111bb4411bbbb441111bb44bb11111111bbbbbbbb33114433bbbbbbbb0000000000000000
__label__
rbbbbbb3r3r3rbbbbbb3r3r3rbbbbbb3r3r3rbbsrssrrsssrbbbbbbbbbb3r3r3rbbbbbb3r3r3rbbbbbb3r3r3rbbbbbb3r3r3rbbsrssrrsssrbbbbbbbbbb3r3r3
30000000000000000000003r30000bb0000000bbrssbrsssrbbbbbbbbbbr3r3r3bbbbbbr3r3r3bbbbbbr3r3r3bbbbbbr3r3r3bbbrssbrsssr00000bbb000003r
b077707070770077007770bbb0770b00707770bbbbbbbssrbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbssrb0nnn0bbb0nnn0bb
b070707070707070707000bbb0070b07000070bbbbbrssssbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbrssssb0n0n0bbb0n0n0bb
b07700707070707070770bbbbb070b070b0770bbbbssssssrbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbssssssr0n0n0bbb0n0n0bb
b070707070707070707000bbb0070007000070bbbbsssssssbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbsssssss0n0n00000n0n0bb
r070700770707077707770bbr077707000777033bbbssssssbbbr333bbbbbbbbr333bbbbbbbbr333bbbbbbbbr333bbbbbbbbr333bbbssssss0nnn00n00nnn0bb
r000000000000000000000b3r0000000b000003r3bbsssssrbb3r33r3bbbbbb3r33r3bbbbbb3r33r3bbbbbb3r33r3bbbbbb3r33r3bbsssssr0000000000000b3
33r33bbbbbbr33r33bbbbbbr33r33bbbbbbr33r33bbsssssrbbr33r33bbbbbbr33r33bbbbbbr33r33bbbbbbr33r33bbbbbbr33r33bbsssssrbbr33r33bbbbbbr
3r3rbbbbbbbb3r3rbbbbbbbb3r3rbbbbbbbb3r3rbbbrssssrbbb3r3rbbbbbbbb3r3rbbbbbbbb3r3rbbbbbbbb3r3rbbbbbbbb3r3rbbbrssssrbbb3r3rbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbssrbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbssrbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbrssssbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbrssssbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbssssssrbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbssssssrbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbsssssssbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbsssssssbbbbbbbbbbbbbbb
333rbbbbbbbb333rbbbbbbbb333rbbbbbbbb333rbbbssssssbbb333rbbbbbbbb333rbbbbbbbb333rbbbbbbbb333rbbbbbbbb333rbbbssssssbbb333rbbbbbbbb
33r33bbbbbb333r33bbbbbb333r33bbbbbb333r33bbsssssrbb333r33bbbbbb333r33bbbbbb333r33bbbbbb333r33bbbbbb333r33bbsssssrbb333r33bbbbbb3
3r33r3bbbb3r3r33r3bbbb3r3r33r3bbbb3r3r33r3bsssssrb3r3r33r3bbbb3r3r33r3bbbb3r3r33r3bbbb3r3r33r3bbbb3r3r33r3bsssssrb3r3r33r3bbbb3r
333333bbbb33333333bbbb33333333bbbb33333333brssssrb33333333bbbb33333333bbbb33333333bbbb33333333bbbb33333333brssssrb33333333bbbb33
3r3r3rbbbbr33r3r3rbbbbr33r3r3rbbbbr33r3r3rbbbssrbbr33r3r3rbbbbr33r3r3rbbbbr33r3r3rbbbbr33r3r3rbbbbr33r3r3rbbbssrbbr33r3r3rbbbbr3
r333r3bbbb33r333r3bbbb33r333r3bbbb33r333r3brssssbb33r333r3bbbb33r333r3bbbb33r333r3bbbb33r333r3bbbb33r333r3brssssbb33r333r3bbbb33
r3r3rbbbbbb3r3r3rbbbbbb3r3r3rbbbbbb3r3r3rbssssssrbb3r3r3rbbbbbb3r3r3rbbbbbb3r3r3rbbbbbb3r3r3rbbbbbb3r3r3rbssssssrbb3r3r3rbbbbbb3
3r3r3bbbbbbr3r3r3bbbbbbr3r3r3bbbbbbr3r3r3bsssssssbbr3r3r3bbbbbbr3r3r3bbbbbbr3r3r3bbbbbbr3r3r3bbbbbbr3r3r3bsssssssbbr3r3r3bbbbbbr
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbssssssssbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbssssssssbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbrssssssssrbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbrssssssssrbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbssssssssssrbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbssssssssssrbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbssssssssssrbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbssssssssssrbbbbbbbbbbbbbbb
bbbbr333bbbbbbbbr333bbbbbbbbr333bbbbsssssssssssrbbbbbbbbr333bbbbbbbbr333bbbbbbbbr333bbbbbbbbr333bbbbsssssssssssrbbbbbbbbr333bbbb
bbb3r33r3bbbbbb3r33r3bbbbbb3r33r3bbsssssssssssssbbbbbbb3r33r3bbbbbb3r33r3bbbbbb3r33r3bbbbbb3r33r3bbsssssssssssssbbbbbbb3r33r3bbb
bbbr33r33bbbbbbr33r33bbbbbbr33r33bbsrsssssssssssrbbbbbbr33r33bbbbbbr33r33bbbbbbr33r33bbbbbbr33r33bbsrsssssssssssrbbbbbbr33r33bbb
bbbb3r3rbbbbbbbb3r3rbbbbbbbb3r3rbbbbrssssssssssssbbbbbbb3r3rbbbbbbbb3r3rbbbbbbbb3r3rbbbbbbbb3r3rbbbbrssssssssssssbbbbbbb3r3rbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbsssssssssssbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbsssssssssssbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbrsssssssssrbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbrsssssssssrbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbsssssssssrbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbsssssssssrbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbsssssssssrbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbsssssssssrbbbbbbbbbbbbbbb
bbbbbbbb333rbbbbbbbb333rbbbbbbbb333rbbbssssssssrbbbbbbbbbbbb333rbbbbbbbb333rbbbbbbbb333rbbbbbbbb333rbbbssssssssrbbbbbbbbbbbb333r
3bbbbbb333r33bbbbbb333r33bbbbbb333r33bbsssssssssbbbbbbbbbbb333r33bbbbbb333r33bbbbbb333r33bbbbbb333r33bbsssssssssbbbbbbbbbbb333r3
r3bbbb3r3r33r3bbbb3r3r33r3bbbb3r3r33r3bsssssssssrbbbbbbbbb3r3r33r3bbbb3r3r33r3bbbb3r3r33r3bbbb3r3r33r3bsssssssssrbbbbbbbbb3r3r33
33bbbb33333333bbbb33333333bbbb33333333brsssssssssbbbbbbbbb33333333bbbb33333333bbbb33333333bbbb33333333brsssssssssbbbbbbbbb333333
3rbbbbr33r3r3rbbbbr33r3r3rbbbbr33r3r3rbbbssssssssbbbbbbbbbr33r3r3rbbbbr33r3r3rbbbbr33r3r3rbbbbr33r3r3rbbbssssssssbbbbbbbbbr33r3r
r3bbbb33r333r3bbbb33r333r3bbbb33r333r3brssssssssrbbbbbbbbb33r333r3bbbb33r333r3bbbb33r333r3bbbb33r333r3brssssssssrbbbbbbbbb33r333
rbbbbbb3r3r3rbbbbbb3r3r3rbbbbbb3r3r3rbssssssssssrbbbbbbbbbb3r3r3rbbbbbb3r3r3rbbbbbb3r3r3rbbbbbb3r3r3rbssssssssssrbbbbbbbbbb3r3r3
3bbbbbbr3r3r3bbbbbbr3r3r3bbbbbbr3r3r3bssssssssssrbbbbbbbbbbr3r3r3bbbbbbr3r3r3bbbbbbr3r3r3bbbbbbr3r3r3bssssssssssrbbbbbbbbbbr3r3r
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbrsssrsssbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbrsssrsssbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbrrbbrrbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbrrbbrrbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333300bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333bbbbbb0000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
7878787878787878787878787878787878787878557878787878n008787878787878787878787878787878787878787878787878787878787878787878787878
66666666666666666666666666666666666666666666666666nnnnn6666666666666666666666666666666666666666666666666666666666666666666666666
6666668666666686666666866666668666666686666666666nnn00nn666666666666666666666666666666666666666666666666666666666666666666666666
6666668866666688666666886666668866666688666666666nn00nnnnn0666666666666666666666666666666666666666666666666666666666666666666666
8668888886688888866888888668888886688888866666666nn0nnnnnn0066666666666666666666666666666666666666666666666666666666666666666666
88688888886888888868888888688888886888888866665500nnnnnnnnn666666666666666666666666666666666666666666666666666666666666666666666
88688888886888888868888888688888886888888855556600006660nn6666666666666666666666666666666666666666666666666666666666666666666666
86688888866888888668888886688888866888885566666666006660006666666666666666666666666666666666666666666666666666666666666666666666
66666688666666886666668866666688666666556666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666686666666866666668666666686666666856666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66866666668666666686666666866666668666665586666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66886666668866666688666666886666668866666558666666666666666666666666666666666666666666666666666666666666666666666666666666666666
88888668888886688888866888888668888886688885566666666666666666666666666666666666666666666666666666666666666666666666666666666666
88888868888888688888886888888868888888688888855666666666666666666666666666666666666666666666666666666666666666666666666666666666
88888868888888688888886888888868888888688888886555666666666666666666666666666666666666666666666666666666666666666666666666666666
88888668888886688888866888888668888886688888866666555006660006666666666666666666666666666666666666666666666666666666666666666666
66886666668866666688666666886666668866666688666666600006660cc6666666666666666666666666666666666666666666666666666666666666666666
66866666668666666686666666866666668666665686666666600ccccccccc666666666666666666666666666666666666666666666666666666666666666666
6666668666666686666666866666668666666686656666666666cc0cccccc0066666666666666666666666666666666666666666666666666666666666666666
6666668866666688666666886666668866666688665566666666cc00ccccc0666666666666666666666666666666666666666666666666666666666666666666
8668888886688888866888888668888886688888866655666666ccc00cc666666666666666666666666666666666666666666666666666666666666666666666
88688888886888888868888888688888886888888866665555666ccccc6666666666666666666666666666666666666666666666666666666666666666666666
8868888888688888886888888868888888688888886666666655555c006666666666666666666666666666666666666666666666666666666666666666666666
86688888866888888668888886688888866888888666666666666600006666666666666666666666666666666666666666666666666666666666666666666666
66666688666666886666668866666688666666886666666666666600666666666666666666666666666666666666666666666666666666666666666666666666
66666686666666866666668666666686666666866666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
87878787878787878787878787878787878787878787878787878787878787878787878787878787878787878787878787878787878787878787878787878787
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbb333rbbbbbbbb333rbbbbbbbb333rbbbbsssrbrsssbbbbb688888888888888888888888888888888888888888888886bbbbbbr333bbbbbbbbbbbbbbbb
3bbbbbb333r33bbbbbb333r33bbbbbb333r33bbsssssrssbrbbbbb868888888888888888888888888888888888888888888868bbbbb3r33r3bbbbbbbbbbbbbbb
r3bbbb3r3r33r3bbbb3r3r33r3bbbb3r3r33r3bsrssssssssbbbbb886888888888888888888888888888888888888888888688bbbbbr33r33bbbbbbbbbbbbbbb
33bbbb33333333bbbb33333333bbbb33333333bbrssssssbrbbbbb888688888888888888888888888888888888888888886888bbbbbb3r3rbbbbbbbbbbbbbbbb
3rbbbbr33r3r3rbbbbr33r3r3rbbbbr33r3r3rbbsssssssssbbbbb888868888888888888888888888888888888888888868888bbbbbbr333bbbbbbbbbbbbbbbb
r3bbbb33r333r3bbbb33r333r3bbbb33r333r3bsssssssssrbbbbb888886888888888888888888888888888888888888688888bbbbb3r33r3bbbbbbbbbbbbbbb
rbbbbbb3r3r3rbbbbbb3r3r3rbbbbbb3r3r3rbbsrssrrsssrbbbbb888888688888888888888888888888888888888886888888bbbbbr33r33bbbbbbbbbbbbbbr
3bbbbbbr00000000000000000bbbbbbr3r3r3bbbrssbrsssrbbbbb880008000000000000088888888888888888888868888888b00000000000000000bbbbbb3s
bbbbbbbb07770777077707770bbbbbbbbbbbbbbbbbbbbssrbbbbbb880708077700770777088888888888888888888688888888b07770777007707770bbbbr3r3
bbbbbbbb00700070077707000bbbbbbbbbbbbbbbbbbrssssbbbbbb880708070707000070088888888888888888886888888888b07070700070000700bbb3r333
bbbbbbbbb070b07007070770bbbbbbbbbbbbbbbbbbssssssrbbbbb880708077707770070888888888888888888868888888888b0770077007770070bbbbr3333
bbbbbbbbb0700070070707000bbbbbbbbbbbbbbbbbsssssssbbbbb880700070700070070666666666666666666688888888888b0707070000070070bbbbb3r3r
r333bbbbb0700777070707770333bbbbbbbbr333bbbssssssbbbbb880777070707700070888888888888888888868888888888b0777077707700070bbbbbbbr3
r33r3bbbb000000000000000033r3bbbbbb3r33r3bbsssssrbbbbb880000000000008000888888888888888888886888888888b000000000000b000bbbbbbbbr
33r300000bbr00000000bbbr00000bbbbbbr33r33bbsssssrbb0000088800000000088800000888888888888888886888800000bbb000000000bbb00000bbbbb
3r3r0777000007770770b00007770bbbbbbb3r3rbbbrssssrbb077700000777077700000777088888888888888888868880777000007770777000007770bbbbb
bbbb0707007007070070b07000070bbbbbbbbbbbbbbbbssrbbb070700700707070700700707088888888888888888886880707007007070707007007070bbbbb
bbbb0707000007070070b00007770bbbbbbbbbbbbbbrssssbbb070700000707070700000707088888888888888888888680707000007070707000007070bbbbb
bbbb0707007007070070007007000bbbbbbbbbbbbbssssssrbb070700700707070700700707088888888888888888888860707007007070707007007070bbbbb
bbbb0777000007770777000007770bbbbbbbbbbbbbsssssssbb077700000777077700000777088888888888888888888880777000007770777000007770bbbbb
333r00000bbb000000000bbb00000bbbbbbb333rbbbssssssbb0000088800000000088600000888888888888888888888800000bbb000000000bbb00000bbbbb
33r33bbbbbb333r33bbbbbb333r33bbbbbb333r33bbsssssrbbbbb888888888688888886888888888888888888888888888868bbbbb3r33r3bbbbbbbbbbbbbb3

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000010101010101010101010101010101010001010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000010101000000000000000000000101010101000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030303030303030000000000000000000000000000000000
__map__
01010101010101010101010101010101010101010101010101010101010101010101010101f2f6f3010101f2f301010101010101090202020202020a0101010101010101090202020202020a0101010101010101010101010101010101010101010101010101010101010101010101011b1705050505050505181c0101010101
010101010101010101010101010101010101010101010101010101010101010101010101f2f733f6f901f8f7f101010101010101090202020202020a0101010101010101090202020202020a01010101200101010101010101010101010101010101010101010101010101010101011f0202020202020202020202141c010101
010101010101010101010101010101010101010101010101010101010101010101010101fb01fcfbeced0101fc01010101010101090202020202020a0101010101010101090202020202020a0101010102141c01010101010101010101010101010101010101010101010101011b130202020202020202020202020202141c01
07070707070707070707070707070707070707070707070707070707070707071cecee0101ecefece9e901e8e901011b01010101090202020202020a0101010107070707020202020202020207070707020202030507070707070707070707070707070707070707070707050302020202020202020202020202020202020214
777f777f777f777f777f777f777f02020202020202020202020202020202020202141c0101efeb01eaeb01eeeb1b130201010101090202020202020a0101010102020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
e0e1e0e1e0e1e0e1e0e1e0e1e0e10202020202020202020202020202020202020202020303030303030303030302020201010101090202020202020a0101010102020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
02777f777f777f777f777f777f777f02020202020202020202020202020202020202020202020202020202020202020201010101090202020202020a0101010102020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
02e0e1e0e1e0e1e0e1e0e1e0e1e0e102020202020202020202020202020202020202020202020202020202020202020201010101090202020202020a0101010102020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
777f777f777f777f777f777f777f0202020202020202020202020202020202020202020404040404040404040402020201010101090202020202020a0101010102020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
e0e1e0e1e0e1e0e1e0e1e0e1e0e102020202020202020202020202020202020202161eeced01eced01eced01011d150201010101090202020202020a0101010102020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
08080808080808080808080808080808080808080808080808080808080808081eecedf2f6f901fa01fa010101eced1d01010101090202020202020a0101010108080808020202020202020208080808020202020202020202020202020202161502020202020202020202020202020202020204060808080808080808080808
01010101010101010101010101010101010101010101010101010101010101010101f83333f6f233f6f7f3fa01e8e90101010101090202020202020a0101010101010101090202020202020a0101010102020202020202020202020202161e01011d150202020202020202020202020202161e01010101010101010101010101
010101010101010101010101010101010101010101010101010101010101010101ecedf43333f7333333f7f901eeeb0101010101090202020202020a0101010101010101090202020202020a010101010202020202020202020202161e0101010101011d15020202020202020202020222010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101f0f7f7f9fbfbfb01010101010101010101090202020202020a0101010101010101090202020202020a010101011d19060606060606061a1e010101010101010101011d19060606060606061a1e01010101010101010101010101010101
01010101011b1705050505050505181c0101011f020202020202020a0101010101010101090202020202020220010101e702020202020202020202020202220101210202020202020202020202020212012102020202020202020202020202200101010101010101010101010101010101010101010101010101010101010101
0101011b13020202020202020202020201011f02020202020202020a0101010101010101090202020202020202200101e60202020202020202020202022201010101210202020202020202020202021001012102020202020202020202020202200101010101010101010101010101010101010101010101010101010101011f
011b130202020202020202020202020201e70202020202020202020a0101010101010101090202020202020202021201e50202020202020202020202e20101010101010d02020202020202020202020e010101210202020202020202020202020220010101010101010101010101010101010101010101010101010101011f02
1302020202020202020202020202020201e50202020202020202020a0101010101010101090202020202020202020e01090202020202020202020202e40101010101011102020202020202020202020a010101012102020202020202020202020202141c0101010101010101010101010101010101010101010101011b130202
02020202020202020202020202020202e7020202020202020202020a010101010101010109020202020202020202021209020202020202020202020a010101010101010109020202020202020202020a01010101011d150202020202020202020202020220010101010101010101010101010101010101010101011f02020202
02020202020202020202020202020202e6020202020202020202020a010101010101010109020202020202020202021009020202020202020202020a010101010101010109020202020202020202020a0101010101010121020202020202020202020202022001010101010101010101010101010101010101011f0202020202
02020202020202020202020202020202e5020202020202020202020a010101010101010109020202020202020202020e09020202020202020202020a010101010101010109020202020202020202020a01010101010101012102020202020202020202020202200101010101010101010101010101010101011f020202020202
0202020202020202020202020202020209020202020202020202020a010101010101010109020202020202020202020a0d020202020202020202020a01010101010101010902020202020202020202e2010101010101010101210202020202020202020202020220010101010101010101010101010101011f02020202020202
0202020202020202020202020202020209020202020202020202020a010101010101010109020202020202020202020a0f020202020202020202020a01010101010101010902020202020202020202e30101010101010101010121020202020202020202020202022001010101010101010101010101011f0202020202020202
0202020202020202020202020202020209020202020202020202020a010101010101010109020202020202020202020a11020202020202020202020a01010101010101010902020202020202020202e401010101010101010101012102020202020202020202020202200101010101010101010101011f020202020202020202
0808080808080808080808060402020209020202020202020202020212010101010101e702020202020202020202020a010d0202020202020202020a010101010101010109020202020202020202e2010101010101010101010101012102020202020202020202020202141c01010101010101011b1302020202020202020202
010101010101010101010101011d15020d02020202020202020202020e010101010101e50202020202020202020202e201110202020202020202020a010101010101010109020202020202020202e401010101010101010101010101011d1502020202020202020202020202200101010101011f020202020202020202020202
010101010101010101010101010101210f02020202020202020202020220010101011f020202020202020202020202e301012102020202020202020a0101010101010101090202020202020202220101010101010101010101010101010101210202020202020202020202020220010101011f02020202020202020202020202
0101010101010101010101010101010111020202020202020202020202022001011f02020202020202020202020202e401010121020202020202020a01010101010101010902020202020202220101010101010101010101010101010101010121020202020202020202020202022001011f0202020202020202020202020222
1f02020202020202020202020202220101210202020202020202020202020212e7020202020202020202020202022201010101010101010101010101010101011b17130303030303030303030314181c010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0202020202020202020202020222010101012102020202020202020202020210e60202020202020202020202022201012001010101010101010101010101011f020202020202020202020202020202020101e8e901e8e901e8e901e8e9f8f6f901010101010101010101010101010101010101e8e90101010101010101010101
020202020202020202020202220101010101010d02020202020202020202020ee50202020202020202020202e201010102200101010101010101010101011f02020202020202020202020202020202020101eaeb01eaeb01eaeb01eaebf8f7f5010101e8eee90101010101f2f3010101010101ecebed01f833f301ecebed0101
020202020202020202020222010101010101011102020202020202020202020a090202020202020202020202e40101010202141c01010101010101011b130202020202020202020202020202020202020101010101010101010101010101f2f3010101eaefefed010101f8f6f7f901010101010101010101f433f6f6f3010101
__sfx__
000100020c2300c230000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200043012232122311223312200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500001e6701d6701c6701b6601a660196601865017650166501564014640136401263011630106300f6200e6200d6200c6100b610000000000000000000000000000000000000000000000000000000000000
000600002d0502d0502d0500000039055390553905539055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001866014650106300c62000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000000612041284163c4250dd061b121004610990600853307303e51019253000611d7770057606e33383110040035906273601757511f260756133b3427b610d8763fe100c6032df6417b7622f4622a50
00010000388120a24229a63398533df37033011ef560f76139d731d9632ec7301e2417f460ea0626f5601b4530b562bf571c8653073017464144030512111d240dd5739a533ef300051003b7239d461af563b372
000100003c200004001df351be2620753037553b300008533634101a302bc72203000743329d702091703f512fa06000303e307070113454735906000001b8440bc7228b0700000240102bb47037553a30024710
000100002926307431299502bb753614303755387103955301c0605b552b577060412ea630f022283633034735d2417f760666317475386372740606e3330a353e3742ef151e07017175090531e4363da5523973
000100001e5301c2430375538f5401a641ce2017b6121b40060412f33718e30355071373739041239431cc071f61000a7529b120e24227a24302003aa77003713617612076008562bb0429f311964727a5139d32
000100001a647286063f063110143c270029620d0143c1303951606b722116421d022b90333b5600b262a804247520171133b301785139d321a64727a5139d321a647382311c7471c76727a5139d321af410e366
000100000cd572a12116361274302191434340391650801437f061f3501b806127562191208c0027d5139d321a647382311c7461b76727a5139d321a64727a5139d321a66729a652af2412c3427c020316211014
000100003c270029620e0142c270029620d0142c520391250881437f0203161100140c620395371f6141c001021670544714520023260d8143460103732216142c401029630e0732b6701a8331a0020762500b20
000100002f0571c017111722ce612ee64169610e1142c270029620e0142c270029620e0142c270029620d0143c13039126068143456002b220e8143460103732226142c401029630e0142c270029620d0142c524
000100003d5361a20000c0335d36176753e24100a0600407274502fe263da552394339c141b95731d36001442e8633c430186161df150516014d7520b7503d632ef73301702c0700e2723fe00234602f5653f106
00010000120173cc141bd573aa771cf4405f500bd721ff341b847085530372117b131cf01224641c76534405057642e32629b741884726f663184613e423b8013701725d73150472b3730e953337171921124846
0001000006041172751d577385563fd103955313e4300c750c0473ac5402e66318171034413e42384103f0301886137f15396331c44404f40008172bf3739d41063511fb530e11404d61099051cc65395272c703
00010000249360e930357271f1170046239c530c145239140dd34175460ae6307712096333ac6506653122171c807037113c6233fa120050608a560f5001e34134f360c4351e917019361881737c1110e170c437
000100002f9303b85309b241be51267201cd432f9303e053033711cf060f265087433aa7702d4622a5039c0737c141183022474074311f9051ff133197418c5121f7006917301711d5771ba6325b041f3603a103
0001000007b032c6602eb51288160a24222b5029c073cc1410406082703863339d54371750cc371bc060f2000046121d623c7533aa770c7031d0033330302377379223d1371e4622c113011702da000870502240
0001000024927181260224316f023df350356518a6218b6032b4413c202eb240e16038e170f1233377434c170f1233b71539a43303623377636c1730962389430cd003822501a451454716315318603ae170f123
000100003377434c170f1233377434c5404a0634755217530fa233377434c170f1233377434c5404a0132f55116130fa233377434c170f1233377434c170f1233377434c5713d433e67002b3018112052471cc20
0001000018161052451cc2018161052451a82018b503af7436c170f5230402220f1422d512d5441de653452319f4215746233450b77634c170f1233377434c170f1230bf121942627c61052441dc200855104a46
000100000c8171836004a471ae623dc510356516f0238b2501a4514d001832539935125422c2232d831240770f5240624423c2028561052441dc2008561052441dc200855104e340b2500f3333377434c170f123
000100003377434c170f1333ab450aa2018351052451ce223dc510356516f0238b2501a451454715b1529862360340ec240624421c200806032b450ca621df4103555167442c223055571b6132fa233377435613
000100003d1452224524b2708575096702ce1701d550da5723f330ec3323f331bd071bf421d4760035302b4022b50288120a24322a50288120a24222a5018d120ae5138363037112e6651da1728f762766224f76
000100001da570bf341841638a1408a120e24222a50288120a24322a50189120a2670c5032c7471f6633c02725f1613a211e2711d436003723f20700022014273e7303904700020006433aa770ea070430004800
000100001dc65399742e1741e7531e46109f54007311e91729f020a24222a50288120a24222a502901626a071e46539d0618f660bf031bb311e1002af561cf533c0003335022c711043017664144050512111515
00010000385760626300e071771613e342744338507066320e56522850288160a2522f9071d4060f27430f343c2420e24222a502ec5335d162626507a4123d552c60321d5013a03060410724723d543c60321d70
00010000205000e3413434123d05062623184600063033012f3603c10307b6331000030603a56121d702e90305b303d000070452217121d702604130a240006031030188302c503283001e036307060f6160bb23
0001000004300074370d121315740f20225b06004303d00000000074643cc150d36313f643cc150d36313f643cc150d36313f643cc150d36313f6401540380031132200d130df730e44320a70158023652120037
00010000150023652120037150023652120037150023652328477359050f3203e813034063a03021315074061253021115074061253021115074061a14023f5130b631bf643cc150d36313f643cc150d36313f64
000100003cc150d3631430113e100d8502d9211e237150023652120037150023652328477359050eb2600d530db631bf6402f0322f06320302131507406125302111507406125302111507406125302150527745
000100000893230e45384040bc643cc150d36313f643cc150db73362122123306c021653021035074021653021035274420f13610f35359423e52320037158020e6433f6500db6313f643cc150d36313f643cc15
000100000d36313f643cc150d36313f643cc150d36313f643cc150d36313f6401540380031171200f530db6313f643cc150d36313f643cc150d36313f643cc150d36313f643cc150d36313f6401170383051eb36
00010000136550d0112ed2710b7423b043020009905000000044310200000000e82228300000001bc440830000c560737038f760eb6313a333df473be34121271ff340315023830288120a24222a31288120e242
0001000022a5028c220a24322a323f7501d4370737535d343cd442776137f361bd37273152fd543e2763fa7224a06010322074001c6317f472041039200090001b924002702a5071f7641e311341373311200130
000100003776414405051211152414c03055213787613647380072df743cd270f36339b743df173f64237c563f213337471205302b4022a50288120a24222a50288120a24225a5028c3204f1129263233733af16
000100003e53723b74387070f3612ff3612507277632fd363582223f5426a50288160a24223a50288120a24222a50189120a24223e7114c300e43327b703be363e16327f6039f561ea261ff7237c172da672a774
000100001e4070f300000001dc2523b6435c7330100004502fe170cf473aa770000000427359771d5773747538200000702ef731ca611d57700000000533b2643b57635d570020000c162e630175750030000000
000100003782320300000003553220100070643ce540d36313f643cc150d36313f643cc150d36313f643cc150d36313f643cc150d36313f643cc150d363143031fe61297711dd300d6162d86313f643cc150d313
000100002171200f530db6313f643cc150d36313f643cc150d36313f643cc150d36313f643cc150d36313f643cc150d36313f643c8650b8763d4602f9201086313f643cc150d36313f643cc150d36313f643cc15
000100000d36313f643cc150d36313f643cc150d3631c750126530d411042013ce150d36313f643cc150d36313f643cc150d36313f643c8650b0763c8763ec150d36313f643cc150d36313f643cc150d31320b35
0001000018547353063252120117150063252120b50194730e84710d7506c111b560104142aa062a411201561501632921343260e37313f643cc150d36313f643cc150d36313f660c9363870403c640000000000
0001000000000000000000027b7400300004102c6233fa040000003863318562bb470000000c170c057315273db000040016341323533aa7700200018363dd100bf722c300004433aa771cc53375273cb0039d75
000100001ce270f761339753bf3735d6721d623d7311fd343d507273673532111524144050512114d750f73329d70374750bf5226a30288120a24237e560f2532fb7038d762ca632fd733e42717e303d4170f757
0001000031f35116241440505121115243e4532fb3037e37066633aa1408a120a24222e502e6572bb703ad163da472bb60318762d70321b7418c3716b6735f363c9000e80707f312e46121d700010001c7100c76
000100000c457000000e0723fe01063413830000430375751bb62318460000003c502fe160c45700000004433b26439100000000e8672830000000000000000000000000000000000000000000e85139d321a647
0001000027a5139d321a64727a5139d321a64727a5139d321a64727a51022113050622634016371b64727a5139d321a64727a5139d321a64727a5139d321a64727a5139d321a2771c417011612b0042c35200966
000100002a0042c352009662a0041c7320053616a042453200b252a824257422cb551a8763567006b2311c14278120296709447239342e6060c5062126631612323572c47200d3116a042453204f25299661a351
000100002ef230f8342427002b2311c142781203162110143c270029620e0142c270029620e0142c6600216605567205703980713207000000f00316f7737c110030000070338752bb672fa00000000f0723fe54
0001000034e340030000430394071bf613a776077632fd361bc17177510065121f500a0120e24222970288120a24222a501be5700c360c0671ef341d437077672fd751d6761f7612ff3100243033711df443e251
000100001e300379303c4001e3412e717228742d8070386031807074433073313e403cc113026121f70005611d7772711737132323002f36038100388533db65099260924307045239450042735d673713232707
0001000027406063413230006c371f9631d6443ce00163412e30001c643de441cf403845303371001001c4440cf5109b2507243239050040014f403ac012745721b702030003c4037c0127425359303d00000430
0001000012547270112f13718a17000000d826263241de4706b0600000351120e922243000040004f4037c113010000430155761f11300000000611d9323d44400300004000ff5131732001000e84139d311a647
0001000027a5139d321a64727a5139d321aa101200721d030d91313a7402b220e8142427002b220e8142427002b220e8142427002b220e8142427002b220d814341303d56608f4107b5539d321a64727a5139d32
000100001a647262652743022e75098653dd321a64727a5139d321a64727a5139d321a64727a5139d321a64727a5139d321a6260234435166060140c2010353222f160a4511cb152b5062166432e110eb1424270
0001000006f220f8763a2512cf25298242435200f162ab0331b6225d331a64727a5139d321a64727a5519e64087472214425d341a64727a5139d321a64727a5139d321a64727a5139d321a64727a551de6431b10
000100001785139d32192000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
