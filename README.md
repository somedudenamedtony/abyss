# abyss

Saltwater tank automation.

## RODI reservoir level monitor

Watches the RODI top-off bucket that feeds the ATO, tracks how much water it
uses per day, and sends phone alerts before it runs dry.

| Path | What it is |
| --- | --- |
| `esphome/rodi-reservoir.yaml` | ESP32-S3 firmware (ESPHome) |
| `esphome/secrets.yaml.example` | Template for the git-ignored `secrets.yaml` |
| `homeassistant/packages/rodi_reservoir.yaml` | Usage/day, days remaining, alerts |
| `homeassistant/dashboards/rodi_reservoir_card.yaml` | Optional dashboard card |
| `hardware/rodi-combined-mount.scad` / `-body.stl` / `-lid.stl` | PETG rim mount for the sender + ESP32-S3 box in one part |
| `hardware/rodi-rim-mount.scad` / `.stl` | Older sender-only rim mount (superseded) |
| `hardware/calibration_estimate.py` | Geometry estimate of the calibration points |

### Hardware

- ESP32-S3 dev board, powered from a 5V USB-C brick
- 350mm reed float sender (SAE 5-hole flange). Listed as 0-190 Ω but
  measures ~33 Ω full (float up) and ~241 Ω empty (float down)
- 3D-printed combined mount (`hardware/`): sender rod tip about 1" off the
  floor of a 5-gal bucket, controller box hanging outside the rim
- 220 Ω 1% resistor, optional 0.1 µF cap, 2-conductor 22-24 AWG

```
3V3 ── 220Ω ──┬── GPIO4 (ADC1) ── sender brown (signal)
              │
           0.1µF (optional)
              │
GND ──────────┴──────────────── sender blue (negative)
```

Any ADC1 pin (GPIO1-GPIO10) works; change `adc_pin` in the substitutions if
you use a different one. Don't use ADC2 pins, they conflict with WiFi.

### Mount

`hardware/rodi-combined-mount.scad` is one part that hooks over the bucket
rim. Inside the bucket an arm holds the sender 60 mm in from the wall with the
flange seat ~18 mm above the rim, so the rod tip hangs 1" off the floor and the
float reads from ~1.8" to ~13.3" of water. Outside the bucket a box hangs
~40 mm below the rim and holds the ESP32-S3 lying flat with its header pins
pointing down, over a ~48 mm wiring bay for the Dupont jumpers, lever nuts,
resistor and cap. USB-C comes in through a slot in one end wall at board
height; the sender cable comes in through a 7 mm hole in the floor (leave a
drip loop). The lid is held by 4 x M3 x 10 self-tapping screws.

The sender flange bolts down with five M5 x 16 screws, nuts captive on the
plate underside. The holes are not evenly spaced (gaps 72/68/80/68/72 deg,
per the sender's drawing); the 80 deg gap is the cable side and faces the
wall. The rim hook gap is the one from the old controller box (6.95 mm).

Print the body upside down (flange seat, arm top and box rim are one flat
plane on the bed) in PETG, no supports. Print the lid flat.

Assumed (parameters at the top of the file): inside depth 14", rod tip 5 mm
past the bottom stop, bucket inside radius 142.9 mm at the rim (the inner hook
leg is curved to it), DevKitC-1 size board (~70 x 25.4 mm). Re-export with
`openscad -o rodi-combined-mount-body.stl -D 'part="body"' rodi-combined-mount.scad`
(and `part="lid"`).

### Flashing

```sh
cd esphome
cp secrets.yaml.example secrets.yaml   # fill it in
esphome run rodi-reservoir.yaml
```

After the first flash it updates over WiFi. The device also serves its own
web page at `http://rodi-reservoir.local/` (ESPHome `web_server`), which works
without Home Assistant and exposes a REST/event API for a future app.

### Calibration (refine once the sender is installed)

The `calibrate_linear` points in `esphome/rodi-reservoir.yaml` are an
**estimate** from the bucket geometry (`hardware/calibration_estimate.py`),
not a fill test. "Level" is **usable** gallons: 0 means the ATO pump can't
pull any more. The float bottoms out with ~0.3 gal still usable, so the level
never reads lower than that. To replace the estimate:

1. Mount the sender and flash the firmware. Open the device web page and
   watch **Sender Resistance**.
2. Fill the bucket to where the ATO pump stops pulling (about 1"). That is
   0 gal usable. The float is still sitting on its bottom stop (~241 Ω).
3. Add water in measured amounts (a 1 qt or 1 gal jug), counting the gallons
   you've added and noting the ohms after each once it settles. Use the
   reading just before the ohms start dropping as the `241 -> x` point. More
   points give a better fit, since the bucket tapers.
4. Replace the datapoints, e.g.

   ```yaml
   - calibrate_linear:
       method: exact
       datapoints:
         - 241.0 -> 0.3
         - 200.0 -> 1.0
         - 158.0 -> 2.0
         - 115.0 -> 3.0
         - 71.0 -> 4.0
   ```

5. Set `usable_capacity_gal` to the gallons at the top of the float's travel,
   then reflash.

This sender's resistance goes *down* as the bucket fills. The datapoints
handle that, nothing else needs changing.

### Home Assistant

1. Adopt the device in the ESPHome integration.
2. Copy `homeassistant/packages/rodi_reservoir.yaml` into `<config>/packages/`
   and enable packages in `configuration.yaml`:

   ```yaml
   homeassistant:
     packages: !include_dir_named packages
   ```

3. Edit `script.rodi_reservoir_notify` in the package to point at your phone
   (`notify.mobile_app_<phone>`), then restart Home Assistant.

You get:

- **Usage today / this week** (utility meters) and **average daily usage**
  over the last 7 days
- **Days remaining** at the current rate
- Alerts: low (default 1.0 gal, plus a 9am reminder while low), critical
  (0.4 gal, repeats every 4h), runaway usage (more than 0.5 gal in an hour,
  usually a stuck ATO or a siphon), and sender fault / device offline

Alert thresholds are `input_number` helpers, so you can tune them from the UI.

### How usage is counted

The firmware keeps a lifetime "Water Used" counter. Each drop in level larger
than `usage_deadband_gal` is added to it; a rise larger than
`refill_threshold_gal` is treated as a refill and ignored. Home Assistant's
utility meters turn that counter into per-day and per-week usage.
