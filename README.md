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

### Hardware

- ESP32-S3 dev board, powered from a 5V USB-C brick
- 350mm 0-190 Ω reed float sender (SAE 5-hole flange) on a 3D-printed rim
  mount, rod bottom about 1" off the floor of a 5-gal bucket
- 220 Ω 1% resistor, optional 0.1 µF cap, 2-conductor 22-24 AWG

```
3V3 ── 220Ω ──┬── GPIO4 (ADC1)
              │
            sender
              │
GND ──────────┘
```

Any ADC1 pin (GPIO1-GPIO10) works; change `adc_pin` in the substitutions if
you use a different one. Don't use ADC2 pins, they conflict with WiFi.

### Flashing

```sh
cd esphome
cp secrets.yaml.example secrets.yaml   # fill it in
esphome run rodi-reservoir.yaml
```

After the first flash it updates over WiFi. The device also serves its own
web page at `http://rodi-reservoir.local/` (ESPHome `web_server`), which works
without Home Assistant and exposes a REST/event API for a future app.

### Calibration (needed once the sender is installed)

The `calibrate_linear` points in `esphome/rodi-reservoir.yaml` are
placeholders (marked `TODO CALIBRATE`). "Level" is **usable** gallons: 0 means
the ATO pump can't pull any more.

1. Mount the sender and flash the firmware. Open the device web page and
   watch **Sender Resistance**.
2. Fill the bucket to where the ATO pump stops pulling (about 1"). Wait for
   the reading to settle and note the ohms. That is `-> 0.0`.
3. Add water in measured amounts (a 1 qt or 1 gal jug), noting the ohms
   after each. More points give a better fit, since the bucket tapers.
4. Replace the datapoints, e.g.

   ```yaml
   - calibrate_linear:
       method: least_squares
       datapoints:
         - 12.0 -> 0.0
         - 55.0 -> 1.0
         - 98.0 -> 2.0
         - 140.0 -> 3.0
         - 181.0 -> 4.0
   ```

5. Set `usable_capacity_gal` to the gallons at the top of the float's travel,
   then reflash.

If the resistance goes *down* as the bucket fills, the sender is wired the
other way round. The datapoints handle that, nothing else needs changing.

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
