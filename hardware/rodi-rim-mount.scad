// RODI reservoir float-sender rim mount (print in PETG)
//
// Hooks over the rim of a Lowe's 5-gal bucket and holds a 350mm reed float
// sender (SAE 5-bolt flange) about 60mm inside the wall. The flange plate is
// raised above the rim so the rod tip hangs ~1" off the bucket floor.
//
// Coordinates: z = 0 is the top of the bucket rim, x = 0 is the inside face
// of the bucket wall, +x points into the bucket, y runs along the rim.
//
// Print upside down (flange seat on the bed, hook legs pointing up). No
// supports needed. 4 walls, 40% infill.
//
// Measured: sender, flange OD/thickness, rim lip thickness, bucket height.
// ASSUMED (check before printing): SAE bolt pattern (54mm circle, 5 x 72deg),
// rod tip 5mm past the bottom stop, inside depth 14", outer leg drop.

/* [Bucket] */
// Rim top to inside floor (14.5" tall bucket, ~0.5" base) - ASSUMED
inside_depth = 355.6;
// Thickness of the rim lip the hook clamps (measured 0.25")
lip_thickness = 6.35;
// Extra room in the hook channel
lip_clearance = 0.6;
// How far the outer leg reaches down the outside. Keep it above any skirt
// or ridge under the rim - ASSUMED
outer_leg_drop = 12;
// How far the inner leg reaches down the inside wall
inner_leg_drop = 30;

/* [Sender] */
// Flange underside -> top float stop (measured 3/4")
top_stop_below_flange = 19.05;
// Top stop -> bottom stop (measured 12.75")
stop_to_stop = 323.85;
// Rod tip below the bottom stop - ASSUMED, measure it
tip_below_bottom_stop = 5;
// Float diameter (measured 34.94mm); the bore must pass it
float_dia = 34.94;
// Flange outside diameter (measured)
flange_od = 68.84;
// SAE 5-bolt circle diameter - ASSUMED standard
bolt_circle_dia = 54;
// Through-hole for #10 / M5 screws
bolt_hole_dia = 5.3;
// Hex nut across flats on the underside (#10 = 9.6, M5 = 8.1)
nut_af = 9.6;
// Nut trap depth (0 for none, e.g. if using heat-set inserts)
nut_depth = 3.4;
// Rotate the bolt pattern (deg). 0 points one hole into the bucket so none
// sit over the arm.
bolt_rotation = 0;

/* [Mount] */
// Wall inside face -> sender centreline
arm_reach = 60;
// Gap the rod tip keeps off the floor
tip_floor_clearance = 25.4;
// Width of the hook and arm along the rim
arm_width = 26;
// Hook leg thickness
leg_thickness = 4;
// Flange plate thickness
plate_thickness = 6;
// Plate diameter
plate_dia = 80;
// Bore clearance around the float
bore_clearance = 3;

$fn = 96;

// ---- derived ----
rod_below_flange = top_stop_below_flange + stop_to_stop + tip_below_bottom_stop;
// Height of the flange seat (plate top) above the rim top.
seat_height = max(rod_below_flange + tip_floor_clearance - inside_depth,
                  plate_thickness);
bore_dia = float_dia + bore_clearance;
gap = lip_thickness + lip_clearance;
outer_x = -gap - leg_thickness;           // outside face of the outer leg
arm_end = arm_reach - plate_dia / 2 + 8;  // where the full-depth arm stops

echo(str("Flange seat ", seat_height, " mm above rim top"));
echo(str("Rod tip ", inside_depth + seat_height - rod_below_flange,
         " mm off the floor"));
echo(str("Bottom stop ", inside_depth + seat_height - rod_below_flange
         + tip_below_bottom_stop, " mm off the floor"));
assert(bore_dia < bolt_circle_dia - bolt_hole_dia - 4,
       "Bore too big for the bolt circle");
assert(arm_reach - plate_dia / 2 > leg_thickness + 2,
       "Plate hits the inner leg; increase arm_reach or shrink plate_dia");

module hex(af, h) {
    cylinder(d = af / cos(30), h = h, $fn = 6);
}

module hook_and_arm() {
    // Bridge + arm: one solid beam from the outer leg to the plate.
    translate([outer_x, -arm_width / 2, 0])
        cube([arm_end - outer_x, arm_width, seat_height]);
    // Outer leg
    translate([outer_x, -arm_width / 2, -outer_leg_drop])
        cube([leg_thickness, arm_width, outer_leg_drop + 0.01]);
    // Inner leg, bears on the inside wall
    translate([0, -arm_width / 2, -inner_leg_drop])
        cube([leg_thickness, arm_width, inner_leg_drop + 0.01]);
}

module plate() {
    translate([arm_reach, 0, seat_height - plate_thickness])
        cylinder(d = plate_dia, h = plate_thickness);
}

module cutouts() {
    translate([arm_reach, 0, 0]) {
        // Rod / float bore
        translate([0, 0, -1]) cylinder(d = bore_dia, h = seat_height + 2);
        for (i = [0:4]) rotate([0, 0, bolt_rotation + i * 72])
            translate([bolt_circle_dia / 2, 0, 0]) {
                translate([0, 0, -1])
                    cylinder(d = bolt_hole_dia, h = seat_height + 2);
                // Nut trap opens on the plate underside
                if (nut_depth > 0)
                    translate([0, 0, seat_height - plate_thickness - 1])
                        rotate([0, 0, 30]) hex(nut_af + 0.3, nut_depth + 1);
            }
    }
}

difference() {
    union() {
        hook_and_arm();
        plate();
    }
    cutouts();
}
