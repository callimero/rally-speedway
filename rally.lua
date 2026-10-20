-- rally speedway
-- (nach dem c64-original)
-- main: konstanten + _funktionen

--== konstanten zum spieltesten ==

-- auswahl im menue (wie original)
tempo_wahl={60,80,100,120,150} -- mph
px_mph=0.02    -- px/frame je mph
               -- (60 mph = 1.2)
beschl_wahl={0.006,0.012,0.024}
               -- langsam/normal/
               -- schnell (px/frame²)
-- haftung = max. querkorrektur
-- pro frame. zu wenig -> rutscht
grip_wahl={0.03,0.018,0.013}
               -- trocken/nass/eis
-- startwerte im menue
start_wahl={gegner=2,strecke=1,strasse=1,
 tempo=2,beschl=2}

-- fahren
bremse=0.03    -- feuerknopf
lenk_tempo=0.0055 -- umdr./frame
lenk_voll=0.5   -- ab diesem tempo
                -- volle lenkung
-- 32 richtungen wie im original:
-- der einschlag sammelt sich, erst
-- ab lenk_stufe dreht der wagen
-- (sprite) eine stufe weiter.
-- vorher zeigt die fahrt nur um
-- lenk_drift*einschlag zur seite
-- -> kurzer tipp = seitlich
-- driften, kein einlenken
lenk_stufe=1    -- einschlag fuer
                -- eine stufe
lenk_erste=2    -- ... fuer die
                -- erste stufe aus
                -- der geradeaus-
                -- fahrt (anlauf:
                -- kurzer tipp lenkt
                -- noch nicht ein)
lenk_drift=0.7  -- 0..1: wie weit
                -- die fahrt schon
                -- vorher mitgeht
lenk_rueck=0.05 -- einschlag zurueck
                -- je frame (los-
                -- gelassen)

-- gelaende (anteil von vmax
-- bzw. vom grip)
gras_max=0.45   -- tempo im gras
wasser_max=0.3  -- tempo im wasser
gelaende_bremse=0.03
grip_gras=0.7
grip_wasser=0.5

-- buesche: langsam darueber geht,
-- schnell hinein -> unfall
busch_crash=0.6  -- px/frame: ab
                 -- da brennt es
busch_max=0.25   -- tempo im busch
                 -- (anteil vmax)
-- aquaplaning: schnell genug ins
-- wasser -> gleitet darueber,
-- verliert dabei tempo; zu
-- langsam -> saeuft ab (bremst
-- wie normales wasser)
aqua_ab=0.75     -- anteil vmax
                 -- beim reinfahren
aqua_bremse=0.02  -- tempo-verlust
                  -- je frame
aqua_grip=0.3    -- anteil vom grip
aqua_lenk=0.3    -- lenkwirkung

-- quietschen + bremsspur ab
-- dieser querbewegung
rutsch_ab=0.15
bremsspur_ab=0.5 -- beim bremsen
                 -- ab diesem tempo
spur_max=600    -- spurpunkte

-- unfall: auto brennt, fahrer
-- springt raus und rennt weg
-- (bilder + folge aus dem c64-
-- original)
feuer_tempo=5   -- frames je bild
fahrer_tempo=7  -- frames je bild
fahrer_farbe=7  -- 7 weiss (wie
                -- spieler 1), 0 =
                -- schwarz (sp. 2)
brenn_ab=0.7    -- schneller als
                -- vmax*brenn_ab ->
                -- fahrer brennt und
                -- waelzt sich
unfall_nach=30  -- frames warten,
                -- dann neustart

-- rauch ueber auto + fahrer,
-- solange es brennt
rauch_auto=0.35   -- chance/frame
rauch_fahrer=0.2  -- chance/frame
rauch_steig=0.25  -- px/frame hoch
rauch_wind=0.12   -- px/frame seitw.
rauch_wachs=0.04  -- radius/frame
rauch_gross=3.5   -- max. radius
rauch_dauer=70    -- frames
rauch_max=60      -- max. wolken

-- kamera: folgt dem auto
-- traege (wie im original, das
-- auto ist nicht in der mitte)
kam_folgen=0.05 -- 1 = starr
kam_vorschau=40 -- frames voraus:
                -- ziel liegt vor dem
                -- auto -> mehr strecke
                -- in fahrtrichtung
                -- (0 = wie original)
kam_rand=14     -- auto bleibt so
                -- weit vom rand

-- computergegner (blaues auto)
gegner_farbe=12   -- statt gelb
overall_gelb=10   -- overall des
                  -- gelben fahrers
                  -- (blau: 12 wie
                  -- im sprite)
gegner_tempo=0.98 -- grund-tempo
                  -- (anteil vmax)
gegner_anpassen=0.025 -- je feld
                  -- vorsprung bzw.
                  -- rueckstand
gegner_min=0.8    -- grenzen fuer
gegner_max=1.08   -- das tempo
renn_runden=3     -- runden gegen
                  -- blau (ohne
                  -- gegner: endlos)
gegner_blick=20   -- px: zielt so
                  -- weit voraus auf
                  -- die ideallinie
gegner_kurve=0.9  -- bremst vor
                  -- kurven: tempo
                  -- 1-kurve*drehung
                  -- (umdrehungen der
                  -- naechsten 3
                  -- felder)
gegner_toleranz=0.008 -- lenkt erst
                  -- ab dieser
                  -- abweichung
gegner_brems=0.08 -- bremst auch ab
                  -- dieser abweich.
rempel_abstand=7  -- autos stossen
                  -- sich ab hier ab
rempel_stoss=0.4  -- abprall (px/f)
rempel_pause=20   -- frames bis zum
                  -- naechsten knall

-- zum testen/optimieren
zeige_linie=false -- ideallinie und
                  -- ziel von blau
                  -- einzeichnen
nur_blau=false    -- nur blau faehrt,
                  -- kamera folgt ihm

-- motorgeraeusch (tonhoehe
-- 0-63 der sfx-noten)
motor_min=3     -- im stand
motor_max=32    -- bei vmax
motor_kurve=0.7 -- <1: steigt
                -- erst schnell,
                -- dann flacher

-- strassenbelag (trocken/nass/
-- eis): farbe der strasse auf
-- dem schirm, farbe der brems-
-- spuren darauf
belag_farbe={6,13,12}
belag_spur={5,5,13}
-- spritzwasser bei naesse
gischt_menge=0.5 -- chance/frame
                 -- je rad bei vmax
gischt_max=80

--== ende konstanten ==

-- sprites: auto (je 2x2)
-- 64,66,..,78 = 0 bis 78.75 grad
-- in 11.25-grad-schritten, 96 =
-- 90 grad (rest gespiegelt, s.
-- tab 2). feuer 98-100 (8x8),
-- fahrer aus dem original
-- 104-111,120-126 (8x8).
-- alle anderen = zeichen der
-- original-strecke (original.py)
feuer_spr=98
-- welt: 32x25 teile a 64x56 px
-- (16x14 c64-zeichen a 4x4 px),
-- ringsum geschlossen. die teile
-- liegen als zeichen in der map
-- (8 nebeneinander, s. tab 1)
teil_b,teil_h=64,56
welt_b,welt_h=32*64,25*56
-- farbe 1 = wasser, auf dem
-- bildschirm geheime farbe 140
wasser_echt=140
-- farbe 10 = gelb (auto), auf
-- dem schirm blasser wie c64
gelb_echt=135

function _init()
 pal(1,wasser_echt,1)
 pal(10,gelb_echt,1)
 -- farbe 2 = grau der haeuser
 -- (strasse 6 wird je nach
 -- belag umgefaerbt)
 pal(2,6,1)
 -- farbe 4 = mittelgruen der
 -- pflanzen
 pal(4,139,1)
 opt={}
 for k,v in pairs(start_wahl) do opt[k]=v end
 menuitem(1,"zum menue",function() zum_menue() end)
 zum_menue()
end

function _update60()
 if modus=="menue" then
  update_menue()
 elseif modus=="ergebnis" then
  update_ergebnis()
 else
  update_rennen()
 end
end

function _draw()
 if modus=="menue" then
  draw_menue()
 else
  draw_rennen()
  if (modus=="ergebnis") draw_ergebnis()
 end
end
-->8
-- gamelogik

-- @strecken (erzeugt von original.py, nicht von hand aendern)
-- raster und ideallinien liegen im sfx-speicher (sfx 8-63),
-- s. lade_strecke. strassenpunkt je teil (px im teil, fuer neustart):
teil_punkt=split("32,28,58,22,30,26,30,26,30,26,30,26,30,34,34,34,30,22,34,22,26,30,38,30,26,26,38,26,46,18,18,38,46,38,18,18,38,26,26,26,30,34,30,22,32,28,32,28,32,28,32,28,32,28,32,28,32,28")
-- sprite des grauen strassen-zeichens (oeffnungen der teile)
strasse_spr=2
-- @ende

-- fahrer: original-bildnummer
-- -> sprite (alle laufen nach
-- rechts, links = gespiegelt)
fahrer_spr={[4]=104,[5]=105,
 [2]=106,[3]=107,[6]=108,
 [10]=109,[11]=110,[13]=111,
 [14]=120,[15]=121,[16]=122,
 [17]=123,[18]=124,[19]=125,
 [20]=126}
-- weg (px) je bild
fahrer_weg={[4]=2,[5]=2,[2]=0,
 [3]=0,[6]=3,[10]=2,[11]=2,
 [13]=3,[14]=1,[15]=1,[16]=1,
 [17]=1,[18]=1,[19]=1,[20]=1}
-- bilder, in denen er brennt
fahrer_brennt={[10]=true,[11]=true,
 [13]=true,[14]=true,[15]=true,
 [16]=true,[17]=true,[18]=true,
 [19]=true,[20]=true}
-- rennt weg, schimpft (arme)
folge_lauf=split("4,5,4,5,4,5,4,5,4,5,4,5,4,5,4,5,4,5,4,5,2,3,2,3,2,3,2,3,2,3,2,3")
-- brennt, wirft sich hin,
-- waelzt sich, steht auf,
-- schimpft
folge_brenn=split("10,11,10,11,10,11,10,11,10,11,10,11,13,16,17,18,19,20,14,15,16,17,18,19,20,14,15,16,17,18,6,2,3,2,3,2,3,2,3,2")

-- untergrund
b_strasse,b_gras,b_wasser,b_fest,b_busch=0,1,2,3,4

function zum_menue()
 modus="menue"
 sfx(-1,0) sfx(-1,1)
 menue_zeile=1
 menue_bild=0
 vorschau_fuer=nil
end

-- ====== menue ======
menue={
 {"strecke","strecke",{"1","2","3","4","5","6"}},
 {"gegner","gegner",{"nein","ja"}},
 {"strasse","strasse",{"trocken","nass","eis"}},
 {"tempo","hoechst-tempo",tempo_wahl},
 {"beschl","beschleunigung",{"langsam","normal","schnell"}},
}

function update_menue()
 if (btnp(2)) menue_zeile=(menue_zeile-2)%#menue+1
 if (btnp(3)) menue_zeile=menue_zeile%#menue+1
 local m=menue[menue_zeile]
 local n=#m[3]
 if (btnp(0)) opt[m[1]]=(opt[m[1]]-2)%n+1
 if (btnp(1)) opt[m[1]]=opt[m[1]]%n+1
 if (btnp(4) or btnp(5)) neues_rennen()
 -- auto im banner: 1 px je
 -- frame (sonst ruckelt es)
 menue_bild+=1
 -- vorschau neu, wenn strecke
 -- oder belag gewechselt
 local k=opt.strecke*10+opt.strasse
 if k!=vorschau_fuer then
  vorschau_fuer=k
  lade_strecke(opt.strecke)
  karte_malen(vorschau_x,vorschau_y,belag_farbe[opt.strasse])
 end
end

function draw_menue()
 cls(11)
 -- banner: strasse, schrift,
 -- auto faehrt darueber
 rectfill(0,0,127,19,6)
 for x=0,127,2 do
  pset(x,0,8) pset(x,19,8)
 end
 print("\^w\^trally",26,5,0)
 print("\^w\^trally",25,4,10)
 print("speedway",71,8,0)
 pal(10,gegner_farbe)
 draw_auto(menue_bild%152-12,10,0.25)
 pal(10,10)
 for i,m in ipairs(menue) do
  local c=i==menue_zeile and 10 or 7
  local w=m[3][opt[m[1]]]
  if (m[1]=="tempo") w..=" mph"
  if (i==menue_zeile) w="\139 "..w.." \145"
  mitte(m[2].."  "..w,15+i*8,c)
 end
 mitte("\151/\142 = bremse",64,7)
 if (not kurs) return
 karte_zeigen(vorschau_x,vorschau_y)
 -- punkt faehrt den kurs ab,
 -- start/ziel blinkt weiss
 local f=kurs[flr(t()*12)%#kurs+1]
 local x,y=karte_xy(vorschau_x,vorschau_y,feld_punkt(f))
 circfill(x,y,1,10)
 if t()%0.8<0.5 then
  x,y=karte_xy(vorschau_x,vorschau_y,feld_punkt(kurs[1]))
  rectfill(x-1,y-2,x,y+2,7)
 end
end

-- ====== streckenkarte ======
-- kurs als linie, 2 px je teil
-- (auch fuer einen editor
-- gedacht). gemalt wird einmal
-- in einen puffer im oberen
-- speicher, gezeigt per memcpy.
karte_puffer=0xc0
vorschau_x,vorschau_y=32,74

-- welt-px -> karten-px
function karte_xy(x0,y0,wx,wy)
 return x0+wx/32,y0+wy/28
end

-- kurs der aktuellen strecke in
-- den puffer, linie in farbe sc
function karte_malen(x0,y0,sc)
 poke(0x5f55,karte_puffer)
 camera()
 rectfill(x0-2,y0-2,x0+65,y0+51,3)
 for i=1,#kurs do
  local ax,ay=feld_punkt(kurs[i])
  local bx,by=feld_punkt(kurs[i%#kurs+1])
  -- ueber den welt-rand: nicht
  -- quer ueber die karte ziehen
  if abs(bx-ax)<teil_b*2 and abs(by-ay)<teil_h*2 then
   local x1,y1=karte_xy(x0,y0,ax,ay)
   local x2,y2=karte_xy(x0,y0,bx,by)
   line(x1,y1,x2,y2,sc)
  end
 end
 poke(0x5f55,0x60)
end

-- karte aus dem puffer zeigen
function karte_zeigen(x0,y0)
 local a=(x0-2)\2
 local n=(x0+65)\2-a+1
 for y=y0-2,y0+51 do
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
 -- start: im startteil (pfeile)
 -- links, faehrt nach rechts
 local x,y=feld_punkt(kurs[1])
 auto=new_auto(x-teil_b\2+12,y-6,0.25)
 auto.vmax=vmax
 gegner=nil
 if nur_blau then
  -- das "eigene" auto faehrt
  -- der computer
  auto.vmax=vmax*gegner_tempo
 elseif opt.gegner==2 then
  gegner=new_auto(x-teil_b\2+12,y+6,0.25)
  gegner.vmax=vmax*gegner_tempo
 end
 rennzeit=0
 rundenzeit=0
 letzte,beste=nil,nil
 runde=1
 gestartet=false
 kx,ky=auto.x-64,auto.y-64
 puffer_voll=true
 init_spur()
 rauch={}
 gischt={}
 quietscht=false
 sfx(-1,1)
end

-- x,y = mitte des autos (px)
-- a   = blickrichtung 0..1
--       (0 = hoch, im uhrzeiger)
-- vx,vy = bewegung (px/frame)
-- v   = tempo laengs, vq = quer
-- unfall = frames bis neustart
-- k = richtung 0-31 (sprite),
-- l = einschlag (in stufen)
-- nxt = naechstes kurs-feld,
-- runde = runde (fuer gegner)
-- rz = laufende rundenzeit,
-- zeiten = fertige runden,
-- zb[fortschritt] = rennzeit beim
-- erreichen (fuer den abstand)
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
 -- runter + o: zurueck ins menue
 if btn(3) and btn(4) then
  zum_menue()
  return
 end
 if not gestartet then
  -- start: joystick in
  -- irgendeine richtung
  for b=0,3 do
   if btn(b) or nur_blau then
    gestartet=true
    sfx(0,0)
   end
  end
 else
  rundenzeit+=1
  rennzeit+=1
  t.rz+=1
  if (gegner) gegner.rz+=1
  if t.unfall>0 then
   update_unfall(t)
  else
   local turn,br=0,btn(4) or btn(5)
   if (btn(0)) turn-=1
   if (btn(1)) turn+=1
   if (nur_blau) turn,br=ki_eingabe(t)
   update_auto(t,turn,br)
   unfall_start(t,pruefe_unfall(t))
   pruefe_kurs(t)
  end
  if (gegner) update_gegner(gegner)
 end
 update_rauch()
 update_gischt()
 update_kamera(t)
 update_ton(t)
end

-- turn = -1/0/1 (links/rechts,
-- relativ zur fahrtrichtung wie
-- ein rc-car), brems = knopf
function update_auto(t,turn,brems)
 local vmax=t.vmax
 local wirk=min(abs(t.v)/lenk_voll,1)
 if (t.aqua) wirk*=aqua_lenk
 -- einschlag in stufen (1 =
 -- 11.25 grad)
 -- t.dreht: schon eine stufe
 -- gedreht, taste noch gehalten
 -- -> weitere stufen ohne anlauf
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
 -- fahrt geht hoechstens eine
 -- stufe vorher mit
 t.a=(t.k+mid(-1,t.l,1)*lenk_drift)/32%1

 -- bewegung zerlegen in laengs
 -- (f) und quer (r)
 local fx,fy=-sin(t.a),-cos(t.a)
 local rx,ry=-fy,fx
 local v=t.vx*fx+t.vy*fy
 local vq=t.vx*rx+t.vy*ry

 -- untergrund
 local b=boden(t.x,t.y)
 local g,vm=grip,vmax
 -- aquaplaning: beim reinfahren
 -- schnell genug, haelt bis das
 -- tempo zu klein wird
 if b==b_wasser then
  if (not t.aqua and t.wasser_vor!=true and v>=vmax*aqua_ab) t.aqua=true
  if (t.aqua and v<vmax*aqua_ab*0.6) t.aqua=false
 else
  t.aqua=false
 end
 t.wasser_vor=b==b_wasser
 if b==b_gras then
  g*=grip_gras vm*=gras_max
 elseif t.aqua then
  -- kein gas, wasser zehrt
  v=max(v-aqua_bremse,0)
  g*=aqua_grip vm=v
 elseif b==b_wasser then
  g*=grip_wasser vm*=wasser_max
 elseif b==b_busch then
  g*=grip_gras vm*=busch_max
 end

 -- gas gibt er von selbst,
 -- knopf = bremse
 t.bremst=false
 if brems then
  t.bremst=v>bremsspur_ab
  v=v>0 and max(v-bremse,0) or min(v+bremse,0)
 elseif v<vm then
  v=min(v+beschl,vm)
 else
  v=max(v-gelaende_bremse,vm)
 end

 -- haftung: querbewegung wird
 -- nur bis grip weggebremst,
 -- darueber rutscht er
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

 -- bremsspur: beim rutschen und
 -- beim bremsen in fahrt
 if (t.rutscht or t.bremst) spur_stempeln(t)
 if (opt.strasse==2) spritzen(t,b_strasse)
 if (t.aqua) spritzen(t,b_wasser,3)
end

-- vier ecken pruefen: haus,
-- busch -> feuer
function pruefe_unfall(t)
 local sp=sqrt(t.vx^2+t.vy^2)
 for e in all(auto_ecken) do
  local x,y=welt_punkt(t,e[1],e[2])
  local b=boden(x,y)
  if b==b_fest or b==b_busch and sp>busch_crash then
   t.unfall=1 -- zaehlt hoch
   t.nach=unfall_nach
   t.vx,t.vy,t.v,t.vq=0,0,0,0
   t.rutscht=false
   -- tempo beim aufprall
   return sp
  end
 end
end

-- crash (sp = tempo beim
-- aufprall, nil = kein crash):
-- fahrer springt raus, bei hohem
-- tempo brennt er. gilt fuer
-- gelb und blau gleich
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
 -- fahrer: naechstes bild
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
  neustart(t)
 end
end

-- neu im letzten feld des
-- kurses, blick zum naechsten
function neustart(t)
 local ax,ay=feld_punkt(kurs[(t.nxt-2)%#kurs+1])
 local bx,by=feld_punkt(kurs[t.nxt])
 t.x,t.y=ax,ay
 t.k=flr(richtung(ax,ay,ax+welt_dx(bx-ax),ay+welt_dy(by-ay))*32+0.5)%32
 t.l=0 t.a=t.k/32
end

-- kurs: die felder der reihe
-- nach abfahren (bis zu zwei
-- duerfen beim abkuerzen
-- fehlen). feld 1 = start ->
-- runde fertig
function pruefe_kurs(t)
 local f=feld(t.x,t.y)
 for s=0,2 do
  local i=(t.nxt-1+s)%#kurs+1
  if kurs[i]==f then
   if i==1 or i<t.nxt then
    t.runde+=1
    add(t.zeiten,t.rz)
    t.rz=0
    if (t==auto) runde_fertig()
    if gegner and t.runde>renn_runden then
     rennen_ende(t)
    end
   end
   t.nxt=i%#kurs+1
   -- zeit fuer jedes erreichte
   -- feld merken (auch
   -- uebersprungene)
   local p=fortschritt(t)
   for q=t.pz+1,p do t.zb[q]=rennzeit end
   t.pz=max(t.pz,p)
   return
  end
 end
end

function runde_fertig()
 letzte=rundenzeit
 if (not beste or letzte<beste) beste=letzte
 rundenzeit=0
 runde+=1
 sfx(3,2)
end

function update_kamera(t)
 local zx=t.x+t.vx*kam_vorschau-64
 local zy=t.y+t.vy*kam_vorschau-64
 kx+=(zx-kx)*kam_folgen
 ky+=(zy-ky)*kam_folgen
 -- auto nie aus dem bild
 kx=mid(t.x-128+kam_rand,kx,t.x-kam_rand)
 ky=mid(t.y-128+kam_rand,ky,t.y-kam_rand)
end

function update_ton(t)
 -- motor: tonhoehe nach tempo
 local p=motor_min+(motor_max-motor_min)*mid(0,abs(t.v)/vmax,1)^motor_kurve
 if (t.unfall>0) p=0
 motor_ton(flr(p))
 local q=t.rutscht and t.unfall==0
 if q!=quietscht then
  quietscht=q
  sfx(q and 1 or -1,1)
 end
end

-- rauchwolke: steigt auf,
-- treibt mit dem wind, waechst
-- und wird heller
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

-- dunkel -> grau -> hell, am
-- ende nur noch gerastert
function draw_rauch()
 for r in all(rauch) do
  local k=r.l/r.dauer
  local c=k<0.3 and 5 or k<0.65 and 13 or 6
  if (k>0.8) fillp(0b0101101001011010.1)
  circfill(r.x,r.y,r.r,c)
  fillp()
 end
end

function draw_rennen()
 -- kamera-pixel aus dem
 -- gerundeten abstand zum auto,
 -- sonst springt das auto beim
 -- abrunden um 1 px hin und her
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
  -- abstand zum spieler runden,
  -- sonst zittert blau beim
  -- scrollen (wie frueher gelb)
  local gx=flr(t.x)+flr(g.x-t.x+0.5)
  local gy=flr(t.y)+flr(g.y-t.y+0.5)
  pal(10,gegner_farbe)
  draw_auto(gx,gy,g.k/32)
  pal(10,10)
  if g.unfall>0 then
   palt(0,false) palt(15,true)
   spr(feuer_spr+g.unfall\feuer_tempo%3,gx-4,gy-4)
   palt()
   draw_fahrer(g.fahrer)
  end
 end
 if (nur_blau) pal(10,gegner_farbe)
 if t.unfall>0 then
  draw_auto(t.x,t.y,t.k/32)
  pal(10,10)
  draw_feuer(t)
  draw_fahrer(t.fahrer,not nur_blau and overall_gelb)
 else
  draw_auto(t.x,t.y,t.k/32)
  pal(10,10)
 end
 draw_gischt()
 draw_rauch()
 camera()
 draw_anzeige()
 if (g) gegner_pfeil(g,cx,cy)
end

-- anzeige unten wie im original
function draw_anzeige()
 schrift("time",9,114,7)
 schrift(zeit_text(rundenzeit),5,121,7)
 schrift("last",57,114,7)
 schrift(zeit_text(letzte),52,121,7)
 schrift("best",104,114,7)
 schrift(zeit_text(beste),99,121,7)
 if gegner then
  schrift("runde "..min(runde,renn_runden).."/"..renn_runden,2,2,7)
  -- abstand: + rueckstand,
  -- - vorsprung (sek.zehntel)
  local d=abstand()
  local a=abs(d)
  local s=(d>0 and "+" or d<0 and "-" or " ")..a\60 .."."..a%60\6
  schrift(s,126-#s*4,2,d>0 and 7 or 10)
 else
  schrift("runde "..runde,2,2,7)
 end
 if not gestartet and t()%1<0.6 then
  schrift("joystick = start",33,56,10)
 end
end

-- feuer ueber dem auto
-- (3 bilder)
function draw_feuer(t)
 palt(0,false) palt(15,true)
 spr(feuer_spr+t.unfall\feuer_tempo%3,flr(t.x)-4,flr(t.y)-4)
 palt()
end

-- overall: im sprite hellblau
-- (12), fuer gelb umgefaerbt
function draw_fahrer(f,overall)
 local n=f.folge[min(f.i,#f.folge)]
 palt(0,false) palt(15,true)
 pal(7,fahrer_farbe)
 pal(12,overall or 12)
 spr(fahrer_spr[n],flr(f.x)-4,flr(f.y)-4,1,1,f.dir<0)
 pal(7,7) pal(12,12) palt()
end

-- ====== computergegner ======

-- gefahrene felder insgesamt
function fortschritt(t)
 return t.runde*#kurs+t.nxt
end

function update_gegner(g)
 if g.unfall>0 then
  -- wie beim spieler: fahrer-
  -- animation, dann weiter
  update_unfall(g)
  g.x=auto.x+welt_dx(g.x-auto.x)
  g.y=auto.y+welt_dy(g.y-auto.y)
  return
 end
 -- gummiband: vorn langsamer,
 -- hinten schneller
 local d=fortschritt(g)-fortschritt(auto)
 g.vmax=vmax*mid(gegner_min,gegner_tempo-d*gegner_anpassen,gegner_max)
 update_auto(g,ki_eingabe(g))
 -- immer in der naehe des
 -- spielers rechnen (ring-welt)
 g.x=auto.x+welt_dx(g.x-auto.x)
 g.y=auto.y+welt_dy(g.y-auto.y)
 unfall_start(g,pruefe_unfall(g))
 pruefe_kurs(g)
 if (auto.unfall==0) rempeln(auto,g)
end

-- punkt der ideallinie: kurve
-- (catmull-rom) von linienpunkt
-- i nach i+1 bei u (0..1),
-- koordinaten nahe rx,ry
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

-- computer faehrt: ziel auf der
-- ideallinie gegner_blick voraus
-- (erst ab dem naechsten punkt
-- zum auto), bremst vor kurven.
-- gibt turn, bremse zurueck
function ki_eingabe(g)
 local n=#kurs
 local i0=(g.nxt-3)%n+1
 local pts={}
 for s=0,11 do
  local x,y=linie_punkt((i0-1+s\4)%n+1,s%4/4,g.x,g.y)
  add(pts,{x,y,abs(x-g.x)+abs(y-g.y)})
 end
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
 -- kurve voraus: drehung der
 -- linie ueber die naechsten
 -- 3 felder
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

-- abstand zu blau in frames:
-- + rueckstand, - vorsprung
function abstand()
 local pa,pg=fortschritt(auto),fortschritt(gegner)
 if (pa<pg) return rennzeit-(gegner.zb[pa] or rennzeit)
 if (pa>pg) return (auto.zb[pg] or rennzeit)-rennzeit
 return 0
end

-- ====== rennende ======
function rennen_ende(t)
 modus="ergebnis"
 sieger=t
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
 rectfill(8,22,119,106,0)
 rect(8,22,119,106,7)
 mitte(sieger==auto and "gelb gewinnt!" or "blau gewinnt!",28,sieger==auto and 10 or 12)
 schrift("runde",14,42,6)
 schrift("gelb",58,42,10)
 schrift("blau",92,42,12)
 local sa,sg=0,0
 for r=1,renn_runden do
  local y=42+r*9
  schrift(r,22,y,7)
  local a,b=auto.zeiten[r],gegner.zeiten[r]
  schrift(a and zeit_text(a) or "-",52,y,7)
  schrift(b and zeit_text(b) or "-",86,y,7)
  sa+=a or 0 sg+=b or 0
 end
 local y=46+renn_runden*9+4
 line(14,y-2,113,y-2,5)
 schrift("summe",14,y+1,6)
 schrift(#auto.zeiten>=renn_runden and zeit_text(sa) or "-",52,y+1,7)
 schrift(#gegner.zeiten>=renn_runden and zeit_text(sg) or "-",86,y+1,7)
 if (ergebnis_t>60 and t()%1<0.6) mitte("\151/\142 = menue",98,7)
end

-- autos stossen sich ab: aus-
-- einander schieben, bewegung
-- in stossrichtung tauschen
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
  -- bewegung in stossrichtung
  -- tauschen und abprallen
  local st=(va-vb)*nx
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

-- gegner ausserhalb: punkt am
-- bildrand in seiner richtung
function gegner_pfeil(g,cx,cy)
 local x,y=g.x-cx,g.y-cy
 if (x>=0 and x<128 and y>=0 and y<128) return
 -- nicht in den textzeilen
 local px,py=mid(3,x,124),mid(11,y,110)
 circfill(px,py,2,0)
 circfill(px,py,1,gegner_farbe)
end

-- ====== spritzwasser ======
-- von den hinterraedern nach
-- hinten-oben, faellt wieder
-- ub = untergrund, auf dem es
-- spritzt, m = mehr (aquaplaning)
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

-- debug: ideallinie um das auto
-- herum, ziel von blau als punkt
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

-- ====== bremsspuren ======
-- ringpuffer: spx/spy/spc

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
-->8
-- hilfsfunktionen

-- auto-punkte (rechts,vorn)
-- relativ zur mitte, in px
auto_ecken={{-3,-4},{3,-4},{-4,3},{4,3}}
spur_raeder={{-4,3},{4,3}}

-- ====== welt ======

-- strecke aus strecken[] holen:
-- gitter[feld] = teil 0-28
-- (feld = zeile*32+spalte),
-- kurs = felder in fahrtrichtung
function lade_strecke(nr)
 -- bitstrom im sfx-speicher
 -- (original.py): kopf = je
 -- strecke 2 byte bit-start
 bit_pos=daten_byte(nr*2-2)*256+daten_byte(nr*2-1)
 gitter={}
 for i=0,799 do
  gitter[i]=bits_lesen(1)==0 and 22 or bits_lesen(5)
 end
 kurs=kurs_bauen()
 -- ideallinie: je feld ein punkt
 -- im feld
 linie_x,linie_y={},{}
 for i,f in ipairs(kurs) do
  linie_x[i]=f%32*teil_b+bits_lesen(6)
  linie_y[i]=f\32*teil_h+bits_lesen(6)
 end
end

-- streckendaten: ab sfx 8, je sfx
-- 64 byte (die noten)
function daten_byte(i)
 return peek(0x3200+(8+i\64)*68+i%64)
end

-- n bits ab bit_pos lesen
function bits_lesen(n)
 local v=0
 for k=1,n do
  local b=daten_byte(bit_pos\8)
  v=v*2+((b>>(7-bit_pos%8))&1)
  bit_pos+=1
 end
 return v
end

-- kurs abfahren: vom startteil
-- (teil 1) nach rechts los, je
-- teil durch die andere strassen-
-- oeffnung raus (kreuzung:
-- geradeaus), bis zurueck
-- richtungen: 1 links, 2 rechts,
-- 3 oben, 4 unten
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

-- teil p (1-28) -> map-zelle
-- links oben (zeichen)
function teil_map(p)
 return (p-1)%8*16,(p-1)\8*14
end

-- feld an welt-pos (px)
function feld(x,y)
 return y\teil_h%25*32+x\teil_b%32
end

-- strassenpunkt eines feldes
-- (welt-px)
function feld_punkt(f)
 local p=gitter[f]
 return f%32*teil_b+teil_punkt[p*2+1],
  f\32*teil_h+teil_punkt[p*2+2]
end

-- kuerzester abstand ueber den
-- ring (welt ist geschlossen)
function welt_dx(d)
 return (d+welt_b\2)%welt_b-welt_b\2
end
function welt_dy(d)
 return (d+welt_h\2)%welt_h-welt_h\2
end

-- auto ueber den rand: alles
-- (kamera, spuren, rauch) mit
-- verschieben, damit die
-- zahlen klein bleiben
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
 -- puffer passt sich an (welt-
 -- hoehe ist kein vielfaches
 -- von 128 -> zeilen-versatz)
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

-- ====== welt-puffer ======
-- tline ueber den ganzen schirm
-- ist zu teuer (~50% cpu). darum
-- liegt die welt in zwei ring-
-- puffern (128x128) im oberen
-- speicher: welt-pixel x,y bei
-- (x+o)%128,y%128, o=0 fuer
-- gerade, o=1 fuer ungerade
-- kamera-x (memcpy kopiert nur
-- ganze bytes = 2 pixel). pro
-- bild werden nur die neuen
-- spalten/zeilen gezeichnet.
puffer={0x80,0xa0}
-- zeilen-versatz im puffer (beim
-- sprung ueber den welt-rand)
pyo=0

-- teil-ausschnitt ab welt-px
-- wx,wy als tline von x,y bis
-- x2,y2 im puffer. dx,dy =
-- schritt (0.25 zeichen/pixel)
function puffer_tline(x,y,x2,y2,wx,wy,dx,dy)
 local p=gitter[wy\teil_h%25*32+wx\teil_b%32]
 if p==0 then
  rectfill(x,y,x2,y2,11)
 else
  local mx,my=teil_map(p)
  tline(x,y,x2,y2,mx+wx%teil_b/4,my+wy%teil_h/4,dx,dy)
 end
end

-- welt-spalte wx, zeilen wy..
-- wy+127 in beide puffer
function puffer_spalte(wx,wy)
 for o=0,1 do
  poke(0x5f55,puffer[o+1])
  local x=(wx+o)%128
  local y,n=wy,128
  while n>0 do
   -- bis teil-ende oder
   -- puffer-unterkante
   local py=(y+pyo)%128
   local k=min(min(teil_h-y%teil_h,128-py),n)
   puffer_tline(x,py,x,py+k-1,wx,y,0,0.25)
   y+=k n-=k
  end
 end
 poke(0x5f55,0x60)
end

-- welt-zeile wy, spalten wx..
-- wx+127 in beide puffer
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
-- bringen: nur neue spalten und
-- zeilen zeichnen
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

-- puffer auf den schirm (je
-- zeile 2 memcpy wegen ring)
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

-- untergrund an welt-pos (px):
-- zeichen-sprite in der map,
-- pixel darin. flag 0 = hart
-- (haus, pool, busch), ausser
-- auf gruenen pixeln
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

-- punkt im auto (q rechts,
-- l vorn) -> welt
function welt_punkt(t,q,l)
 local fx,fy=-sin(t.a),-cos(t.a)
 return t.x+fx*-l+-fy*q,
  t.y+fy*-l+fx*q
end

-- richtung von a nach b (0..1,
-- 0 = hoch, im uhrzeiger)
function richtung(ax,ay,bx,by)
 return (0.25-atan2(bx-ax,by-ay))%1
end

function dist(ax,ay,bx,by)
 local dx,dy=(bx-ax)/16,(by-ay)/16
 return sqrt(dx*dx+dy*dy)*16
end

-- richtungs-sprites: 0 bis 90
-- grad in 11.25-grad-schritten,
-- die anderen 3 viertel
-- entstehen durch spiegeln
-- (zusammen 32 richtungen)
richt_spr={[0]=64,66,68,70,72,74,76,78,96}

-- auto in naechster der 32
-- richtungen (k: 0 = hoch,
-- im uhrzeiger)
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

-- 16x16-sprite, mitte (pixel
-- 7,7) auf x,y. schwarz = farbe
-- 0, durchsichtig = farbe 15.
-- gespiegelt liegt pixel 7 auf
-- pixel 8 -> 1 px zurueck
function spr_15(n,x,y,fx,fy)
 palt(0,false) palt(15,true)
 spr(n,flr(x)-7-(fx and 1 or 0),
  flr(y)-7-(fy and 1 or 0),2,2,fx,fy)
 palt()
end

-- motor: tonhoehe von sfx 0
-- (noten 0+1) live aendern
function motor_ton(p)
 for n=0,1 do
  local ad=0x3200+n*2
  poke(ad,peek(ad)&0xc0|p)
 end
end

-- text mittig (breite misst
-- print ausserhalb des bilds)
function mitte(s,y,c)
 local w=print(s,0,-20)
 schrift(s,64-w\2,y,c)
end

-- text mit schwarzem rand
-- (\^o = umriss: farbe 0, alle
-- 8 nachbarn)
function schrift(s,x,y,c)
 print("\^o0ff"..s,x,y,c)
end

-- zeit (frames) -> m:ss:z
-- (wie original "2:04:7")
function zeit_text(f)
 if (not f) return "0:00:0"
 local s=f\60
 local z=f%60\6
 return s\60 ..":"..(s%60<10 and "0" or "")..s%60 ..":"..z
end
