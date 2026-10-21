# Rally Speedway (PICO-8) – Programmstruktur

Nachbau von *Rally Speedway* (C64, John Anderson, 1983/84). Dieses Dokument
beschreibt den Aufbau von `rally.p8`. Die Entstehungsgeschichte steht in
[`REVISIONEN.md`](REVISIONEN.md). Was sich vom Original unterscheidet,
steht in der `README.md` des Repos (Abschnitt „Unterschiede zum Original“).

## Dateien

| Datei | Zweck |
|---|---|
| `rally.p8` | die Cart (Arbeitsversion), Kopie in `~/.lexaloffle/pico-8/carts/` |
| `rally.lua` | Lua-Teil der Cart zum Lesen (wird nach jeder Änderung exportiert) |
| `rally_v1.p8` … `rally_v5.p8` | gesicherte Stände |
| `original.py` | baut Zeichen, Map, Flags und Streckendaten aus den C64-Daten |
| `c64_zeichensatz.bin`, `c64_teile.bin`, `c64_strecken.json` | aus dem Original ausgelesen |
| `c64daten.py`, `c64_*.png` | Feuer-/Fahrerdaten und Vorschaubilder aus dem Original |
| `c64werkzeug/` | Skripte zum Entpacken der T64-Datei (6502-Emulation mit py65) |
| `alt/` | alter Generator für eine eigene Strecke (gesperrt) |

Im öffentlichen Repo liegen nur Cart, Quellcode, Web-Player und diese Dokumente;
Werkzeuge und ausgelesene C64-Daten bleiben lokal.

## Tabs der Cart

| Tab | Inhalt |
|---|---|
| 0 | **Einstellungen**: alle Werte zum Spieltesten, dann `_init`, `_update60`, `_draw` |
| 1 | **Spiel**: Menü, Streckenkarte, Rennen, Fahrphysik, Unfall, Kurs/Runden, Zeichnen, Blau, Rennende, Effekte |
| 2 | **Welt, Technik, Helfer**: feste Tabellen, Strecke laden, Welt-Koordinaten, Untergrund, Welt-Puffer, Hilfsfunktionen |

### Tab 0 – Einstellungen

Geordnet nach Wichtigkeit fürs Spielgefühl:

1. **Spielgefühl**: Tempo/Beschleunigung/Bremse, Haftung, Lenkung, Gelände
   (Gras, Wasser, Busch, Aquaplaning), Blau, Rempeln, Kamera, Unfall
2. **Optik + Ton**: Farben, Spuren, Spritzwasser, Rauch, Motorton
3. **Menü-Startwerte** (`start_wahl`)
4. **Testen**: `zeige_linie` (Ideallinie einzeichnen), `nur_blau` (nur der
   Computer fährt, Kamera folgt ihm)

Geschwindigkeiten sind in Pixel pro Frame (60 Frames/s). Alles, was „Anteil“
heißt, ist ein Faktor auf die Höchstgeschwindigkeit bzw. die Haftung.

## Grafik

Alle Sprites hat **callimero von Hand neu gezeichnet**: das Auto in allen
Richtungen, den Fahrer mit allen Bildern und die Zeichen mit den Randsteinen.
Grund ist das andere Seitenverhältnis der Pixel. Ein C64-Multicolor-Pixel ist
doppelt so breit wie hoch (2:1), PICO-8-Pixel sind quadratisch. Bei der
automatischen Umrechnung (ein Multicolor-Pixel = ein PICO-Pixel, je zwei
Zeilen zusammengefasst) stimmten zwar die Proportionen, aber Details wie Kopf,
Arme, Räder und die Randsteine an Schrägen gingen verloren. Die Werkzeuge
liefern deshalb nur Vorlagen; `original.py` überschreibt die gemalten Sprites
nicht.

## Ablauf

`modus` steuert das Spiel:

```
"menue" ──❎/🅾️──> "rennen" ──beide im ziel (mit blau)──> "ergebnis"
   ^                 │  ⬇️+🅾️ / pausenmenue              │ ❎/🅾️
   └─────────────────┴──────────────────────────────────┘
```

Ein Frame im Rennen (`update_rennen`):

1. vor dem Start: warten, bis eine Richtung gedrückt wird
2. Zeiten zählen (`rennzeit`, `t.rz`)
3. Gelb: `update_unfall` **oder** Eingabe → `update_auto` → `pruefe_unfall`
   → `unfall_start` → `pruefe_kurs`
4. Blau: `update_gegner` (gleiche Physik, Eingabe von `ki_eingabe`)
   - Wer `renn_runden` Runden hat, ist `fertig`. Der Erste ist `sieger`.
     `im_ziel` lässt das Auto ausrollen, der Fahrer steigt aus und winkt.
     Sind beide ausgestiegen, folgt nach `ziel_winken` Frames
     `rennen_ende`.
5. Rauch, Spritzwasser, Kamera, Ton. Der Motor ist aus, solange Gelb brennt
   oder ausgestiegen ist (`motor_an`).

Zeichnen (`draw_rennen`): Welt-Puffer nachziehen → auf den Schirm kopieren →
Bremsspuren → (Ideallinie) → Blau → Gelb → Spritzwasser → Rauch → Anzeige.

## Ein Auto

Gelb (`auto`) und Blau (`gegner`) sind Tabellen gleicher Form (`new_auto`):

| Feld | Bedeutung |
|---|---|
| `x,y` | Mitte in Welt-Pixeln |
| `k` | Sprite-Richtung 0–31 (0 = hoch, im Uhrzeigersinn) |
| `l` | gesammelter Lenk-Einschlag in Stufen |
| `a` | tatsächliche Fahrtrichtung 0..1 = `(k + l·lenk_drift)/32` |
| `vx,vy` / `v,vq` | Bewegung bzw. Tempo längs/quer |
| `vmax` | eigene Höchstgeschwindigkeit (Blau: Gummiband) |
| `unfall`, `nach`, `fahrer` | Crash-Zähler, Wartezeit, Fahrer-Animation |
| `nxt`, `runde`, `rz`, `zeiten`, `beste` | Kurs-Fortschritt und Zeiten |
| `zb`, `pz` | Rennzeit je erreichtem Kursfeld (für den Abstand) |
| `aqua`, `rutscht`, `bremst`, `dreht` | Zustände für Physik und Effekte |

### Fahrphysik (`update_auto`)

1. **Lenkung**: Links/rechts sammelt Einschlag `l`. Erst ab `lenk_erste`
   (danach `lenk_stufe`) dreht der Wagen um eine von 32 Stufen. Davor weicht
   nur die Fahrt um `l·lenk_drift` ab, ein kurzer Tipp lässt ihn also seitlich
   driften. Loslassen baut `l` mit `lenk_rueck` ab.
2. **Zerlegen** der Bewegung in längs (`v`) und quer (`vq`).
3. **Untergrund** (`boden`) bestimmt Haftung und Höchsttempo; Aquaplaning
   bei schnellem Einfahren ins Wasser.
4. **Gas** automatisch bis zum Höchsttempo, der Knopf bremst.
5. **Haftung**: Querbewegung wird höchstens um `grip` abgebaut, der Rest
   rutscht (Quietschen, Bremsspuren).

## Welt

- Die Welt besteht aus **32 × 25 Teilen** (Feldern), jedes Teil aus
  **16 × 14 C64-Zeichen**, jedes Zeichen ist **4 × 4 Pixel** groß.
  Ein Teil ist damit 64 × 56 Pixel groß, die ganze Welt 2048 × 1400.
- Die Welt ist **ringsum geschlossen**. `welt_dx/welt_dy` liefern den
  kürzesten Weg. Fährt Gelb über den Rand, verschiebt `welt_rum` alles mit,
  damit die Zahlen klein bleiben. Blau wird jedes Frame nahe Gelb gerechnet.
- `gitter[feld]` = Teilnummer (Feld = Zeile·32 + Spalte).
- **Teile in der Map**: die 28 benutzten Teile als Zeichen-Raster,
  8 nebeneinander (`teil_map`). Map-Zeilen 0–55.
- **Zeichen = Sprites**: Jedes C64-Zeichen ist ein Sprite, gespeichert
  2-fach (8 × 8), gezeichnet mit `tline` im halben Maßstab.
- `boden(x,y)` liest das Pixel im Zeichen-Sprite:
  - Sprite-Flag 0 = hart (Haus, Pool-Rand, Busch), außer auf grünen Pixeln
  - Flag 1 = Busch (langsam befahrbar)
  - blau = Wasser, grün = Gras, sonst Straße

### Kurs und Runden

- `kurs_bauen` fährt beim Laden vom Startteil (Teil 1) nach rechts los und
  verlässt jedes Teil durch die andere Straßenöffnung (`oeffnungen`), an der
  Kreuzung geradeaus. Ergebnis: Liste der Felder in Fahrtrichtung.
- `pruefe_kurs`: Die Felder müssen der Reihe nach erreicht werden, zwei
  dürfen beim Abkürzen fehlen. Feld 1 = Start/Ziel → `runde_fertig`.
- `fortschritt(t)` = gefahrene Felder insgesamt. Daraus kommen das
  Gummiband und der Abstand in Sekunden (`abstand`).

## Darstellung

- `tline` über den ganzen Schirm kostet etwa 50 % CPU. Deshalb liegt die Welt
  in **zwei Ring-Puffern** (128 × 128) im oberen Speicher, einer für gerade
  und einer für ungerade Kamera-x, weil `memcpy` nur ganze Bytes (2 Pixel)
  kopiert. Pro Frame werden nur neue Spalten/Zeilen gezeichnet
  (`puffer_nach`); `draw_puffer` kopiert mit 2 `memcpy` je Zeile auf den
  Schirm. `pyo` gleicht den Sprung über den Welt-Rand aus (1400 ist kein
  Vielfaches von 128).
- Die **Kamera** folgt träge mit Vorausschau. Gerundet wird der Abstand zum
  Auto, nicht die Kameraposition, damit das Auto nicht zittert. Blau wird
  ebenso relativ zu Gelb gerundet.
- **Bildschirm-Palette**: 1 → 140 (Wasser), 10 → 135 (C64-Gelb),
  2 → 6 (Grau der Häuser), 4 → 139 (Mittelgrün der Pflanzen). Die
  Straßenfarbe 6 wird beim Zeichnen in den Puffer je nach Belag umgefärbt.

## Blau (Computergegner)

- Fährt mit derselben Physik wie Gelb; `ki_eingabe` liefert Lenkung und
  Bremse.
- **Ideallinie**: `original.py` berechnet sie offline (geglättete Linie mit
  7 px Randabstand) und speichert pro Kursfeld einen Punkt. `linie_punkt`
  legt eine Catmull-Rom-Kurve durch diese Punkte; Blau zielt `gegner_blick`
  Pixel voraus auf die Kurve.
- **Kurvenbremse**: Drehung der Linie über die nächsten Felder →
  Zieltempo.
- **Gummiband**: Höchsttempo = `vmax · (gegner_tempo − Vorsprung ·
  gegner_anpassen)`, begrenzt auf `gegner_min … gegner_max`.
- **Rempeln** (`rempeln`): Autos werden auseinandergeschoben, die Bewegung in
  Stoßrichtung getauscht, dazu Abprall und Knall.

## Unfall

`pruefe_unfall` testet die 4 Ecken. Bei einem Crash startet `unfall_start`
die Fahrer-Animation: Laufen und Schimpfen, oder bei Tempo über `brenn_ab`
Brennen, Hinwerfen, Wälzen, Aufstehen und Schimpfen. Die Bildfolgen stammen
aus dem C64-Code. Danach wartet das Auto `unfall_nach` Frames und `neustart`
setzt es ins letzte Kursfeld. Für Gelb und Blau gilt dasselbe.

## Speicherbelegung

| Bereich | Inhalt |
|---|---|
| Sprites 64–79, 80–95, 96, 97, 112, 113 | Auto, 9 Richtungen à 2 × 2 (von callimero gemalt) |
| Sprites 98–100 | Feuer |
| Sprites 104–111, 120–126 | Fahrer, 15 Bilder (von callimero gemalt) |
| übrige Sprites 1–127, 224–255 | C64-Zeichen (Randsteine von callimero gemalt) |
| Sprites 128–223 | belegt durch Map-Zeilen 32–55 – **nicht bemalen** |
| Map-Zeilen 0–55 | die 28 Teile als Zeichen-Raster |
| SFX 0–4 | Motor, Quietschen, Crash, Runde, Rempeln (5–7 frei) |
| SFX 8–63 | **Streckendaten** (Raster + Ideallinie als Bitstrom) – nicht ändern |
| `0x8000`, `0xA000` | Welt-Puffer (gerade/ungerade) |
| `0xC000` | Streckenkarte im Menü |

`lade_strecke` liest den Bitstrom: Kopf mit 2 Byte Bitstart je Strecke, dann
800 Teile (1 Bit für Teil 22, sonst 1 + 5 Bit), dann je Kursfeld der
Linienpunkt im Feld (je 6 Bit).

## Werkzeuge

```
python3 original.py rally.p8            # map, flags, streckendaten, @strecken-block
python3 original.py rally.p8 --zeichen  # zusaetzlich zeichen neu (randsteine weg!)
pico8 rally.p8 -export x.p8.png         # pruefen, ob der code noch komprimierbar ist
```

`original.py` behält Auto, Feuer, Fahrer, alle Zeichen-Sprites und das Label
aus der Cart. Getestet wird headless: Ein Testtreiber wird als letzter Tab
angehängt (z. B. Autopilot über `ki_eingabe`, Bildschirm per `printh` als
Hex), dann `pico8 -x test.p8`.

## Grenzen

- **Komprimierter Code** (15 616 Byte): Kommentare zählen mit. Deshalb liegen
  die Streckendaten im SFX-Speicher. Nach größeren Änderungen den Export
  prüfen („could not compress code“).
- **Sprites**: 103 von 105 freien Plätzen sind mit Zeichen belegt.
