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
- **Titel-Banner** mit rot-weißen Randsteinen.
