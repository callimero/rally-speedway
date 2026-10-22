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

--== spieler (gelb) ==

bremse=0.03     -- bremsknopf
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

--== blau (gegner) ==

gegner_tempo=0.98 -- grundtempo
gegner_anpassen=0.025 -- gummi-
                -- band je feld
gegner_min=0.85 -- tempo-grenzen
gegner_max=1.04
gegner_blick=20 -- px voraus auf
                -- der ideallinie
gegner_kurve={0.4,0.4,0.4} -- bremst
                -- vor kurven je
                -- belag (trocken/
                -- nass/eis)
gegner_toleranz=0.008 -- lenkt ab
                -- dieser abweichung
gegner_brems=0.023 -- bremst ab
                -- dieser abweichung
rempel_abstand=7 -- px
rempel_stoss=0.2 -- abprall

--== testen ==
zeige_linie=false -- ideallinie
nur_blau=false  -- nur blau faehrt


--== menue ==

tempo_wahl={60,80,100,120,150}
                -- mph
px_mph=0.02     -- px/frame je mph
beschl_wahl={0.006,0.012,0.024}
                -- langsam/normal/
                -- schnell
-- haftung je belag: querkorrek-
-- tur/frame, darueber rutscht er
grip_wahl={0.03,0.018,0.013}
                -- trocken/nass/eis
start_wahl={gegner=2,runden=3,linie=1,
 strecke=6,strasse=1,tempo=2,
 beschl=2}

--== umgebung ==

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
-- je belag (trocken/nass/eis)
belag_farbe={6,13,6} -- strasse
belag_spur={5,5,13}   -- spuren
gras_farbe={11,11,7} -- wiese
                -- (eis: schnee)
gras_spur={3,3,6} -- spuren darauf
busch_licht={4,4,7} -- helles gruen
                -- der buesche
                -- (eis: schnee)
-- regen (nass)
regen_menge=3   -- tropfen/frame
regen_fall=60   -- fallzeit frames
regen_wind_x=0.4 -- wind aus nord-
regen_wind_y=0.3 -- west (px/frame)
regen_farbe=12  -- fallender tropfen
-- schnee (eis): wie regen, faellt
-- langsamer, kein aufschlag
schnee_menge=2
schnee_fall=150
schnee_wind_x=0.25
schnee_wind_y=0.18
schnee_farbe=7

--== kamera + unfall ==

kam_folgen=0.05 -- 1 = starr
kam_vorschau=40 -- frames voraus
                -- (0 = original)
brenn_ab=0.7    -- anteil vmax: ab
                -- da brennt fahrer
ziel_winken=120 -- frames winken,
                -- dann auswertung

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
 {"linie","ideallinie",{"aus","an"}},
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
 pal(10,12)
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
 regen={}
 kx_alt,ky_alt=nil,nil
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
 if (opt.strasse>1) update_regen()
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
  t.bremst=v>0.5
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
   t.nach=30
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
 if (rnd()<0.35) neuer_rauch(t.x,t.y-3)
 local f=t.fahrer
 if f.folge[min(f.i,#f.folge)]>=10
 and rnd()<0.2 then
  neuer_rauch(f.x,f.y-3)
 end
 if f.i<=#f.folge then
  f.z+=1
  if f.z>=7 then
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
  t.ziel=rennzeit
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
  if f.z>=7 then
   f.z=0
   f.i=f.i%#f.folge+1
  end
 end
end

-- gefahrene felder insgesamt,
-- steigt stetig (nxt=1 heisst:
-- letztes feld der runde)
function fortschritt(t)
 return t.runde*#kurs+(t.nxt-2)%#kurs
end

function update_kamera(t)
 local zx=t.x+t.vx*kam_vorschau-64
 local zy=t.y+t.vy*kam_vorschau-64
 kx+=(zx-kx)*kam_folgen
 ky+=(zy-ky)*kam_folgen
 kx=mid(t.x-128+14,kx,t.x-14)
 ky=mid(t.y-128+14,ky,t.y-14)
end

function update_ton(t)
 -- motor aus, solange er brennt
 -- oder ausgestiegen ist
 local an=gestartet and t.unfall==0 and not (t.fertig and t.fahrer)
 if an!=motor_an then
  motor_an=an
  sfx(an and 0 or -1,0)
 end
 local p=3+(32-3)*mid(0,abs(t.v)/vmax,1)^0.7
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
 if (zeige_linie or opt.linie==2) draw_linie(zeige_linie)
 local g=gegner
 if g then
  -- blau relativ zu gelb runden
  draw_wagen(g,flr(t.x)+flr(g.x-t.x+0.5),flr(t.y)+flr(g.y-t.y+0.5),true)
 end
 draw_wagen(t,t.x,t.y,nur_blau)
 draw_gischt()
 draw_rauch()
 draw_regen()
 camera()
 draw_anzeige()
 if (g) gegner_pfeil(g,cx,cy)
end

-- auto, beim crash mit feuer
-- und fahrer
function draw_wagen(t,x,y,blau)
 if (blau) pal(10,12)
 draw_auto(x,y,t.k/32)
 pal(10,10)
 if t.unfall>0 then
  palt(0,false) palt(15,true)
  spr(feuer_spr+t.unfall\5%3,flr(x)-4,flr(y)-4)
  palt()
  draw_fahrer(t.fahrer,not blau and 10)
 elseif t.fertig and t.fahrer then
  draw_fahrer(t.fahrer,not blau and 10)
 end
end

function draw_fahrer(f,overall)
 local n=f.folge[min(f.i,#f.folge)]
 palt(0,false) palt(15,true)
 pal(7,7)
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
 local vz=g.vmax*max(0.35,1-dreh*gegner_kurve[opt.strasse])
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
 -- beide im ziel: differenz der
 -- zielzeiten
 if (auto.ziel and gegner.ziel) return auto.ziel-gegner.ziel
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
   rempel_t=t()+20/60
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
 circfill(px,py,1,12)
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
 if (opt.strasse>1) update_regen()
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
 if (#rauch>=60) return
 add(rauch,{x=x+rnd(4)-2,y=y,
  vx=rnd(0.2)-0.1,
  vy=-0.25*(0.7+rnd(0.6)),
  r=0.5,l=0,
  dauer=70*(0.7+rnd(0.6))})
end

function update_rauch()
 for r in all(rauch) do
  r.vx+=(0.12-r.vx)*0.03
  r.vy*=0.99
  r.x+=r.vx r.y+=r.vy
  r.r=min(r.r+0.04,3.5)
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
  if #gischt<80
  and rnd()<0.5*(m or 1)*sp/vmax then
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

-- regen: landepunkt dort, wo die
-- kamera nach der fallzeit ist
-- (beim fahren kommen die tropfen
-- so aus der fahrtrichtung),
-- start um den wind dagegen
-- versetzt. auf der strasse kurz
-- weiss (aufschlag), sonst weg
function update_regen()
 -- regen (nass) oder schnee (eis)
 local schnee=opt.strasse==3
 local menge,fall=regen_menge,regen_fall
 local wx,wy=regen_wind_x,regen_wind_y
 if (schnee) menge,fall,wx,wy=schnee_menge,schnee_fall,schnee_wind_x,schnee_wind_y
 local kvx,kvy=0,0
 if (kx_alt) kvx,kvy=kx-kx_alt,ky-ky_alt
 kx_alt,ky_alt=kx,ky
 for n=1,menge do
  if #regen<300 then
   local l=fall*(0.8+rnd(0.4))
   local x=kx+rnd(128)+kvx*l
   local y=ky+rnd(128)+kvy*l
   add(regen,{x=x-wx*l,y=y-wy*l,l=l,wx=wx,wy=wy})
  end
 end
 for r in all(regen) do
  if r.s then
   r.s-=1
   if (r.s<=0) del(regen,r)
  else
   r.x+=r.wx r.y+=r.wy
   r.l-=1
   if r.l<=0 then
    if not schnee and boden(r.x,r.y)==b_strasse then
     r.s=6
    else
     del(regen,r)
    end
   end
  end
 end
end

function draw_regen()
 local c=opt.strasse==3 and schnee_farbe or regen_farbe
 for r in all(regen) do
  pset(r.x,r.y,r.s and 7 or c)
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
   spc[spi]=b==b_strasse and belag_spur[opt.strasse] or gras_spur[opt.strasse]
   spi=spi%600+1
   spn=min(spn+1,600)
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
-- ideallinie um das auto herum:
-- fuer alle in spurfarbe, zum
-- testen orange mit punkten und
-- dem ziel von blau
function draw_linie(test)
 local n=#kurs
 local t=auto
 local c=test and 9 or belag_spur[opt.strasse]
 for s=-6,10 do
  local i=(t.nxt-1+s)%n+1
  local ax,ay=linie_punkt(i,0,t.x,t.y)
  for u=1,4 do
   local bx,by=linie_punkt(i,u/4,t.x,t.y)
   line(ax,ay,bx,by,c)
   ax,ay=bx,by
  end
  if (test) pset(t.x+welt_dx(linie_x[i]-t.x),t.y+welt_dy(linie_y[i]-t.y),8)
 end
 local z=nur_blau and auto or gegner
 if (test and z and z.zx) circ(z.zx,z.zy,1,8)
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
-- fahrer (laeuft nach rechts):
-- je c64-bild sprite, weg (px).
-- bilder ab 10: er brennt
fahrer_spr,fahrer_weg={},{}
local d=split("2,106,0,3,107,0,4,104,2,5,105,2,6,108,3,10,109,2,11,110,2,13,111,3,14,120,1,15,121,1,16,122,1,17,123,1,18,124,1,19,125,1,20,126,1")
for i=1,#d,3 do
 fahrer_spr[d[i]]=d[i+1]
 fahrer_weg[d[i]]=d[i+2]
end
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
 for l in all({rauch,gischt,regen}) do
  for r in all(l) do
   r.x+=dx r.y+=dy
  end
 end
 if (kx_alt) kx_alt+=dx ky_alt+=dy
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
 pal(11,gras_farbe[opt.strasse])
 pal(4,busch_licht[opt.strasse])
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
 pal(6,6) pal(11,11) pal(4,4)
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
