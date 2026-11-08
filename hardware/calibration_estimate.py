#!/usr/bin/env python3
"""Estimate ESPHome calibration points (sender ohms -> usable gallons).

Geometry-only ESTIMATE. Replace with a real fill test (see README.md).
Keep the values below in sync with hardware/rodi-rim-mount.scad.
All lengths in mm.
"""
import math

IN = 25.4
GAL_L = 3.785411784

# Bucket (Lowe's 5 gal). Inner diameters are typical values, not measured.
inside_depth = 14.0 * IN        # rim top -> inside floor
top_inner_dia = 11.25 * IN      # at the rim
bottom_inner_dia = 10.25 * IN   # at the floor
pump_cutoff = 1.0 * IN          # ATO pump can't pull below this

# Sender (measured 2026-11-07)
ohm_full = 33.0                 # float at top stop
ohm_empty = 241.0               # float at bottom stop
top_stop_below_flange = 0.75 * IN
stop_to_stop = 12.75 * IN
float_height = 1.25 * IN
float_waterline = 0.5           # fraction of float height under water (guess)

# Mount (must match the .scad file): flange underside height above rim top
flange_above_rim = 17.7   # from the .scad echo


def radius_at(h):
    """Inner radius at height h above the floor."""
    r0, r1 = bottom_inner_dia / 2, top_inner_dia / 2
    return r0 + (r1 - r0) * h / inside_depth


def volume_gal(h):
    """Gallons from the floor up to height h (truncated cone)."""
    r0, r = bottom_inner_dia / 2, radius_at(h)
    return math.pi * h / 3 * (r0 * r0 + r0 * r + r * r) / 1e6 / GAL_L


def main():
    flange_h = inside_depth + flange_above_rim  # flange underside above floor
    sub = float_waterline * float_height
    # Waterline when the float rests on each stop.
    wl_top = flange_h - top_stop_below_flange - float_height + sub
    wl_bot = flange_h - top_stop_below_flange - stop_to_stop + sub
    v0 = volume_gal(pump_cutoff)

    print(f"Bottom stop {flange_h - top_stop_below_flange - stop_to_stop:.1f} mm off floor")
    print(f"Float reads from {wl_bot / IN:.2f}\" to {wl_top / IN:.2f}\" of water")
    print(f"Brim-full volume {volume_gal(inside_depth):.2f} gal; "
          f"below pump cutoff {v0:.2f} gal")
    print("\n- calibrate_linear:\n    method: exact\n    datapoints:")
    n = 6
    for i in range(n + 1):
        f = i / n                      # 0 = float at bottom, 1 = at top
        ohm = ohm_empty + (ohm_full - ohm_empty) * f
        wl = wl_bot + (wl_top - wl_bot) * f
        print(f"      - {ohm:.1f} -> {volume_gal(wl) - v0:.2f}")


if __name__ == "__main__":
    main()
