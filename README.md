# Rally Speedway (PICO-8)

Ein Nachbau des C64-Klassikers **Rally Speedway** (John Anderson, Adventure
International, 1983/84) für die Fantasy-Konsole [PICO-8](https://www.lexaloffle.com/pico-8.php).

**[▶ Im Browser spielen](https://callimero.github.io/rally-speedway/)**

![Rally Speedway](rally.p8.png)

## Spiel

- Die 6 Original-Strecken, ringsum geschlossene Welt, Verengungen inklusive
- Gas gibt der Wagen von selbst – der Knopf **bremst** nur
- Lenken wie ein RC-Car: links/rechts relativ zur Fahrtrichtung, 32 Richtungen
- Rutschen, Bremsspuren, nasse und vereiste Straße, Aquaplaning (für Profis)
- Crash: Feuer, der Fahrer springt raus, brennt, wälzt sich und schimpft
- Computergegner **Blau** auf der Ideallinie, 3 Runden, Abstand in Sekunden

## Steuerung

| Taste | Funktion |
|---|---|
| ⬅️ ➡️ | lenken |
| 🅾️ / ❎ | bremsen |
| beliebige Richtung | Start |
| ⬇️ + 🅾️ | zurück ins Menü |

Im Browser: Pfeiltasten, **Z**/**X** (oder **C**/**V**) als Knöpfe; Gamepads
werden erkannt.

## Dateien

| Datei | Inhalt |
|---|---|
| `index.html`, `index.js` | Web-Player (GitHub Pages) |
| `rally.p8` | die Cart (in PICO-8: `load rally`) |
| `rally.p8.png` | dieselbe Cart als Bild-Datei |
| `rally.lua` | der Quellcode zum Lesen |
| `STRUKTUR.md` | Aufbau des Programms (Tabs, Ablauf, Physik, Welt, Speicher) |
| `REVISIONEN.md` | Entstehung und Begründungen, Version für Version |

Die Streckendaten (Raster und Ideallinie) liegen als Bitstrom im
Sound-Speicher (SFX 8–63) der Cart, nicht im Quellcode.

## Hinweis

Fan-Projekt ohne kommerzielle Absichten. Strecken, Zeichensatz und Figuren
sind dem C64-Original nachempfunden bzw. daraus übernommen; die Rechte daran
liegen bei den ursprünglichen Rechteinhabern.
