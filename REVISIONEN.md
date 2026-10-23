# Rally Speedway (PICO-8) – Revisionen

Wie das Spiel entstanden ist und warum manches so gebaut ist. Die aktuelle
Programmstruktur steht in [`STRUKTUR.md`](STRUKTUR.md).

## Vorlauf (2026-10-20)

- **Erste Version mit eigener Strecke** (Generator heute in `alt/`). Optik
  nach Screenshots der C64-Wiki: hellgraue Straße mit rot gepunktetem Rand,
  Büsche, Seen, rote Walmdächer.
  - **Steuerung wie im Original:** Gas automatisch, der Knopf bremst nur;
    gelenkt wird relativ zur Fahrtrichtung wie bei einem RC-Car.
  - **Kamera:** folgt träge, das Auto steht nicht in der Mitte.
- **Auto als 2 × 2-Sprites:** C64-Multicolor-Sprites sind 12 Pixel breit,
  8 × 8 war zu klein. Ein Multicolor-Pixel ist 1 PICO-Pixel breit, je zwei
  Zeilen werden zusammengefasst.
- **32 Richtungen** wie im Original. Gespeichert sind 9 Sprites (0–90°),
  der Rest entsteht durch Spiegeln. Die Sprites hat callimero von Hand
  gemalt.
- **Original ausgelesen** (`c64werkzeug/`): Die T64-Datei ist zweifach
  gepackt; entpackt wurde sie mit py65 (6502-Emulation). Gefunden wurden:
  - Auto-Sprites $C0–$DF (32 Richtungen, n und 32−n sind Spiegelbilder)
  - Fahrer- und Feuer-Animation mit Bildfolgen aus dem C64-Code
  - Zeichensatz $3800
  - 29 Streckenteile ab $A000 (16 × 14 Zeichen)
  - 6 Strecken als Bitstrom (32 × 25 Teile, ringsum geschlossene Welt)
- **Alle Sprites neu gezeichnet** von callimero: Auto, Fahrer und die
  Zeichen mit den Randsteinen. C64-Multicolor-Pixel sind doppelt so breit wie
  hoch (2:1). Die automatische Umrechnung auf quadratische PICO-8-Pixel (je
  zwei Zeilen zusammengefasst) traf zwar die Proportionen, verlor aber zu viele
  Details. Die umgerechneten Sprites dienten nur als Vorlage.
- **Feuer:** Die Original-Flamme gefiel nicht, das 8 × 8-Feuer aus der
  ersten Version ist geblieben.
- **Fahrer:** aus dem Original übernommen und von callimero nachgezeichnet
  (Overall, Helm, Schuhe, Flammen).

## v1 – `rally_v1.p8`

- **Original-Strecken:** Die Zeichen werden Sprites, die Teile liegen als
  Zeichen-Raster in der Map, gezeichnet wird mit `tline` im halben Maßstab.
- **Welt-Puffer:** `tline` über den ganzen Schirm kostete etwa 50 % CPU.
  Deshalb gibt es zwei Ring-Puffer im oberen Speicher (gerade/ungerade
  Kamera-x), und pro Frame werden nur neue Spalten und Zeilen gezeichnet.
  Gesamt etwa 16 % CPU.
- **Gras-Sprite:** `tline` zeichnet Sprite 0 nicht, darum hat das grüne
  Zeichen ein eigenes Sprite (sonst bleiben alte Pixel im Puffer stehen).
- **Kamera-Rundung:** Gerundet wird der Abstand zum Auto, nicht die
  Kameraposition. Sonst sprang das Auto beim Scrollen um 1 Pixel.
- **Kamera-Vorausschau:** `kam_vorschau`, damit mehr Strecke in
  Fahrtrichtung zu sehen ist.
- **Rauch:** Partikel über brennendem Auto und Fahrer.

## v2 – `rally_v2.p8`

- **Menü:** Banner oben, Streckenvorschau als Kurslinie (Puffer `0xC000`),
  „Schaden“ entfernt (Crash zählt immer).
- **Pflanzen:** dunkelgrün statt rot. Farbe 4 wird auf dem Schirm zu 139.
- **Bremsspuren** auch beim Bremsen, nicht nur beim Rutschen.
- **Straßenbelag** trocken/nass/eis: Farbe 6 wird beim Zeichnen in den
  Puffer umgefärbt. Die Häuser-Grautöne sind dafür auf Farbe 2 gelegt
  (auf dem Schirm grau), sonst wären die Dachlinien mit umgefärbt worden.
- **Spritzwasser** bei Nässe.
- **Motorton:** beginnt tiefer, Tonhöhe über eine Kurve.

## v3 – `rally_v3.p8`

- **Lenkung in 32 Stufen mit Einschlag:** Ein kurzer Tipp soll den Wagen nur
  seitlich driften lassen, nicht einlenken (wie im Original).
  - `lenk_erste` ist ein Anlauf für die erste Stufe; vorher lenkte ein
    normaler Tipp von 6–10 Frames schon ein.
- **Büsche:** Langsam darüber geht ohne Crash (Sprite-Flag 1).
- **Aquaplaning:** Schnell genug ins Wasser, dann gleitet der Wagen und
  verliert dabei Tempo. Bewusst ein Profi-Trick, weil die Seen voller
  Busch-Inseln sind.
- **Fehler behoben:** Das Wasser-Zeichen 64 war als hart markiert, weil es
  auch im Pool vorkommt – jeder See war tödlich.

## v4 – `rally_v4.p8`

- **Computergegner Blau:**
  - gleiche Physik wie Gelb
  - Gummiband über den Fortschritt in Feldern
  - Rempeln mit Knall (SFX 4) und Abprall
  - Punkt am Bildrand, wenn Blau nicht zu sehen ist
- **Ideallinie** (`original.py`):
  - Straßenmaske und Abstandskarte, geglättet wie ein Gummiband mit 7 px
    Randabstand
  - Blau folgt einer Catmull-Rom-Kurve durch die Punkte. Vorher zielte er
    auf Punkte im Abstand von etwa 60 px, die Sehne schnitt in Kurven durchs
    Gras.
  - Kleinere `gegner_toleranz`: keine Crashes mehr in den Verengungen
- **Zittern von Blau** behoben: relativ zu Gelb gerundet.
- **3 Runden gegen Blau**, Ergebnis-Bildschirm, Abstand in Sekunden
  (+ Rückstand, − Vorsprung).
- **Testschalter:** `zeige_linie`, `nur_blau`.
- **Speicher:** Der komprimierte Code wurde zu groß, `.p8.png`/HTML ließen
  sich nicht exportieren. Deshalb:
  - Der Kurs wird beim Laden aus dem Raster abgefahren (`kurs_bauen`).
  - Raster und Ideallinie liegen als Bitstrom in SFX 8–63.

## v5 – `rally_v5.p8`

- **Rot-weiße Randsteine:** Die automatische Umwandlung klappte an den
  Schrägen nicht, callimero hat sie von Hand gezeichnet.
  `original.py` behält seitdem alle Zeichen-Sprites (`--zeichen` erzeugt
  sie neu).
- **Crash fair:** Blau bekommt dieselbe Fahrer-Animation wie Gelb.
  Vorher brannte er nur 100 Frames und war schneller wieder unterwegs.
- **Gelber Overall** für den Fahrer von Gelb (Farbe 12 → 10 beim Zeichnen).
- **Menü:** `tempo_wahl` direkt als Liste, „ mph“ wird angehängt.
- **Blau fährt im Titel.**
- **⬇️+🅾️** springt im Rennen zurück ins Menü.
- **Veröffentlicht:** Label-Bild, Repo und GitHub Pages
  (https://callimero.github.io/rally-speedway/).

## Nach v5 – Aufräumen (2026-10-21)

- **Einstellungen in Tab 0 neu geordnet:** zuerst das Spielgefühl (Tempo,
  Haftung, Lenkung, Gelände, Blau, Kamera, Unfall), dann Optik und Ton,
  Menü-Startwerte und zuletzt die Testschalter.
- **Technische Festwerte** (Sprite-Nummern, Weltmaße, Tabellen,
  Puffer-Adressen) liegen jetzt in Tab 2.
- **Rundendaten nur noch pro Auto:** Die doppelt geführten globalen
  `runde`, `rundenzeit`, `letzte`, `beste` sind entfernt; die Anzeige liest
  `auto.rz`, `auto.zeiten`, `auto.beste`.
- **`draw_wagen`** zeichnet Auto, Feuer und Fahrer für Gelb und Blau
  gemeinsam.
- **Unbenutzt und entfernt:** `dist()`, eine Variable in `rempeln`,
  Palettenkonstanten (die Werte stehen jetzt direkt in `_init`).
- **Lange Erklär-Kommentare** sind in diese Datei und `STRUKTUR.md` gewandert
  (Code 16 % kürzer).
- **Geprüft:** gleiche Rundenzeiten auf allen 6 Strecken (Blau allein und
  gegen den Autopiloten) wie vorher.
- **Fehler nach dem Aufräumen behoben:** In `draw_anzeige` hat
  `local t=auto` die PICO-8-Zeitfunktion `t()` verdeckt. Vor dem Start gab es
  deshalb einen Laufzeitfehler (blinkendes „joystick = start“). Die Testtreiber
  hatten das nicht gefunden, weil sie sofort losfahren; jetzt wird auch der
  Zustand vor dem Start geprüft. Merke: In Funktionen, die `t()` benutzen,
  das Auto nie `t` nennen.

## Nach v5 – Zieleinlauf, Motor (2026-10-21)

- **Zieleinlauf:** Wer die letzte Runde beendet, rollt hinter der Ziellinie
  aus, der Fahrer steigt aus und winkt (Bilder 2/3), bis der Zweite im Ziel
  ist. Auf dem Schirm stehen „gewonnen!“ oder „ziel!“. Wenn beide
  ausgestiegen sind, wird noch `ziel_winken` Frames (2 s) gewunken, erst
  dann kommt der Ergebnis-Bildschirm. Vorher kam er sofort, und man sah die
  Szene gar nicht.
- **Motor:** Bei einem Crash und nach dem Aussteigen ist der Motor-Sound ganz
  aus. Vorher wurde nur die Tonhöhe auf 0 gesetzt, und das brummte weiter.
- **Fehler behoben:** Der Fahrer eines Crashs blieb nach dem Neustart im Auto
  gespeichert (`t.fahrer`). Er wird jetzt gelöscht.
- **Titel-Banner** mit rot-weißen Randsteinen, durchgehend je 2 Pixel rot
  und 2 Pixel weiß.
- **Menü:**
  - Rundenzahl wählbar (1–6, `opt.runden` statt der Konstante
    `renn_runden`)
  - neue Zeile „steuerung/hilfe“ mit eigener Hilfeseite (Steuerung und
    Tipps); dafür ist die Zeile „❎/🅾️ = bremse“ weggefallen
  - Scrollliste: `menue_zeilen` (4) Zeilen sichtbar, ⬆️/⬇️ zeigen an, dass
    es weitergeht. Sie stoppt oben und unten (kein Überlauf).
  - Reihenfolge: zuerst „steuerung/hilfe“, zuletzt „ueber das spiel“
    (eigene Seite, Inhalt folgt). Die Auswahl startet auf „strecke“.
  - „rennen starten ❎“ blinkt mit 1 Hz über der Karte.
  - Hilfeseite ohne die Tipps zu Büschen und Wasser (die sollen Spieler
    selbst entdecken). Zeilenabstand 8, Text mit Umriss, Karte im dunkelgrünen
    Kasten darunter. (Zwischenschritte mit 7 Zeilen und Text ohne Umriss
    waren zu eng bzw. gefielen nicht.)
  - Behoben: Der Kopierbereich der Karte lief bis zu 1 Zeile über den
    Bildschirm hinaus in den Welt-Puffer.
- **Ergebnistafel** auch für 6 Runden.

## Feinschliff von callimero (2026-10-21)

- **Sounds:** Motor, Quietschen und Crash (SFX 0–2) neu abgestimmt.
- **Blau:**
  - engeres Gummiband (`gegner_min` 0.85, `gegner_max` 1.04)
  - bremst etwas weniger vor Kurven (`gegner_kurve` 0.8)
- **Menü:** startet mit Strecke 6.

## Fehlerkorrekturen (2026-10-21)

- **Rundenwechsel:** `fortschritt()` zählte am Rundenende falsch. Auf dem
  letzten Feld (`nxt=1`) fiel der Wert zurück, statt weiter zu steigen. Das
  störte an jedem Rundenwechsel Gummiband und Abstandsanzeige. Jetzt steigt
  der Wert stetig.
- **Zieleinlauf:** Sind beide im Ziel, zeigt die Anzeige die Differenz der
  Zielzeiten (`t.ziel`). Vorher sprang sie auf 0.0.

(Versuche mit besserem Bremsen für Blau bei Nässe und Eis, geglätteter
Anzeige und Temperament im Zweikampf liegen in `rally_versuch_blau.p8`; sie
sind vorerst nicht übernommen.)

## Regen (2026-10-21)

- **Regen bei nasser Straße:** Hellblaue Tropfen fallen etwa 1 s
  (`regen_fall`). Der Wind aus Nordwest treibt sie nach Südosten
  (`regen_wind_x/y`).
  - **Landepunkt:** Er liegt dort, wo die Kamera nach der Fallzeit sein
    wird. Beim Fahren kommen die Tropfen dadurch aus der Fahrtrichtung.
  - **Aufschlag:** Auf der Straße wird der Tropfen für `regen_spritz`
    Frames ein fester weißer Pixel, sonst verschwindet er.
  - **Kosten:** etwa 9 % CPU (`regen_menge` 3 je Frame, bis `regen_max`
    300).
- **Winter bei Eis:** Die vereiste Straße war hellblau, also genauso wie das
  blaue Auto. Jetzt bleibt die Straße grau, die Wiese wird weiß
  (`gras_farbe`, beim Zeichnen in den Welt-Puffer umgefärbt; die Physik
  bleibt gleich), und Reifenspuren im Schnee sind grau (`gras_spur`).
  Dazu fällt Schnee: wie der Regen, aber langsamer und ohne Aufschlag
  (`schnee_*`).

## Versuch: Blau bremst nach Haftung (2026-10-21, wieder entfernt)

- **Kurventempo physikalisch:** Blau misst die Krümmung der Ideallinie über
  die nächsten 3 Felder (Drehung je Pixel). Daraus ergibt sich zusammen mit
  der Haftung des Belags die Haftgrenze `v = sqrt(grip / Krümmung)`, mal
  `gegner_mut`. Damit sind Straßenzustand und Endgeschwindigkeit
  automatisch berücksichtigt. `gegner_kurve` ist dadurch entfallen.
- **Rutschen:** Ab einer Querbewegung von `gegner_rutsch` bremst Blau.
- **Testreihe** (Blau allein, Strecken 1 und 5, trocken/nass/Eis, 80 und
  120 mph): Mit `gegner_mut=0.8` gab es keinen einzigen Crash, bei 1.0 und
  1.2 auf Nässe/Eis mit 120 mph 1–4. Trocken ist Blau etwa 2 % langsamer
  als vorher.
- **Wieder entfernt:** Im Spiel wirkte es unrund. Blau bremste viel zu weit
  vor der Kurve, lenkte ein, bremste erneut, stand quer mit Tempo 0 und
  konnte nicht driften. Die Testreihe hatte nur Crashs gezählt, nicht das
  Fahrgefühl. Blau fährt wieder wie vorher (`gegner_kurve`).

## Einstellungen sortiert (2026-10-21)

Tab 0 ist jetzt so aufgebaut: Spieler (Gelb), Blau, Menü (Tempo-, Beschleunigungs-
und Haftungswerte, Startwerte), Umgebung (Gelände, Beläge, Regen, Schnee),
Kamera + Unfall, Effekte + Ton, Testen. Die Werte sind unverändert.

## Ideallinie für alle, Kurvenbremse je Belag (2026-10-21)

- **Feinschliff von callimero:** `gegner_brems` 0.023, `rempel_stoss` 0.2,
  Testschalter weiter nach oben.
- **`gegner_kurve` je Belag** (trocken/nass/eis), zunächst überall 0.4.
- **Menüpunkt „ideallinie“** (aus/an): Die Linie wird ohne Punkte in der
  Farbe der Bremsspuren gezeichnet, unter den Autos. Die Testansicht mit
  `zeige_linie` (orange, mit Punkten und Blaus Ziel) gibt es weiterhin.

## v6 – `rally_v6.p8` (2026-10-22)

- **Winter:** Bei Eis wird auch das helle Grün der Büsche weiß, wie Schnee
  auf den Büschen (`busch_licht`).
- **Sicherung als v6:** Regen, Schnee, Ideallinie im Menü, Kurvenbremse
  von Blau je Belag, sortierte Einstellungen, Fehlerkorrekturen bei
  Fortschritt und Zielabstand.

## Token-Diät, Stufe 1 (2026-10-22)

- **Zählskript** `tokens.py` (rechnet wie PICO-8).
- **25 unveränderte Effekt- und Technikwerte** stehen jetzt direkt im Code
  (Liste mit Fundstelle in `STRUKTUR.md`, „Fest eingebaute Werte“).
- **Fahrer-Tabellen** als ein String; „brennt“ heißt jetzt einfach Bild ab 10.
- **`welt_rum`** verschiebt Rauch, Spritzwasser und Regen in einer Schleife.
- **Ergebnis:** 7161 → 6936 Tokens (225 gespart). Das Verhalten ist
  unverändert (gleiche Rundenzeiten im Testrennen).

## Demo-Modus, Fahrprofile, Log (2026-10-22)

- **Demo (Attract Mode):** nach `demo_warten` Frames Ruhe im Menü
  (zum Testen 300 = 5 s, später 1800 = 30 s) oder über den Menüpunkt
  „zuschauen“.
  - Beide Autos fahren computergesteuert, mit den Menüwerten (Strecke,
    Belag, mph, Runden, Beschleunigung), ohne Gummiband.
  - 🅾️ schaltet die Kamera zum anderen Auto, eine andere Taste führt ins
    Menü. Nach der Ergebnistafel geht es von selbst zurück, die eigenen
    Menüwerte sind wiederhergestellt.
  - Dafür tauschen `auto` und `gegner` die Rolle, die Farbe hängt am Auto
    (`t.blau`).
- **Fahrprofile** ersetzen `gegner_blick`, `gegner_kurve`,
  `gegner_toleranz` und `gegner_brems`: `profil[1]` = Gelb (Demo),
  `profil[2]` = Blau (Rennen und Demo).
  Jedes Profil hat `blick`, `kurve` (je Belag), `toleranz`, `brems`.
- **Log:** Nach jedem Rennen mit Gegner (auch in der Demo) schreibt das Spiel
  eine Zeile in `rally_log.p8l` im carts-Ordner. Format:
  `modus;strecke;belag;mph;sieger;rundenzeiten gelb,...,crashs;rundenzeiten blau,...,crashs`
  (Zeiten in Frames, 60 = 1 s).
- **`nur_blau` entfernt**, die Demo ersetzt es.
- **Startaufstellung:** beide Autos stehen gleich weit neben der
  Ideallinie (vorher stand Gelb 2 px vom oberen Rand, Blau fast auf der
  Linie).
- **Windschatten** (beide Autos): bis `windschatten_laenge` px hinter dem
  Heck des anderen steigt die Höchstgeschwindigkeit linear bis auf
  `1+windschatten_max` am Heck; seitlich fällt der Effekt linear bis
  `windschatten_breite` px auf 0.
- **Überholen (Computer):** liegt das andere Auto bis `ueberhol_abstand` px
  vorn auf der Linie, zielt der Computer `ueberhol_versatz` px daneben –
  nur wenn dort Straße ist. Sonst bleibt er dahinter und bremst, wenn er
  schneller ist.
- **Tokens:** 6936 → 7542.
- **Aufhol-Bonus** (`hinten_bonus`, beide Autos): wer nach Kursfeldern
  hinten liegt, darf 10 % schneller fahren („mehr Drehzahl“). Leichter
  aufholen, aber mehr Risiko in Kurven. Bei Blau kommt das Gummiband dazu.
- **Demo** startet nach 10 s Ruhe im Menü (`demo_warten=600`).
- **Computer sucht Windschatten:** liegt das andere Auto im Windschatten-
  Bereich vor ihm, zielt er auf der Geraden direkt dahinter. Dreht die
  Linie voraus stärker als `ki_gerade` (Kurve kommt), schert er schon dort
  zum Überholen aus, sonst erst bei `ueberhol_abstand`.
- **Motor des anderen Autos hörbar:** Kopie von SFX 0 in SFX 5 auf Kanal 3,
  `ton2_tiefer` Halbtöne tiefer, leiser mit dem Abstand bis `ton2_weite` px
  (still). Das Rempel-Geräusch läuft jetzt auf Kanal 2.
- **Tokens:** 7563 → 7734.
- **Demo:** Nach Ruhe im Menü eine Runde auf zufälliger Strecke mit
  zufälligem Belag (`demo_zufall=false`: Menüwerte). Der Menüpunkt
  „zuschauen“ fährt genau die eingestellten Werte, auch die Runden.
