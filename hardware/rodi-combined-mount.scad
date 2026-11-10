// RODI reservoir combined mount: float sender + ESP32-S3 box (print in PETG)
//
// One part that hooks over the rim of the Lowe's 5-gal bucket. Inside the
// bucket an arm holds the 350mm reed float sender 60mm in from the wall, with
// the flange seat raised so the rod tip hangs 1" off the floor. Outside the
// bucket a box hangs below the rim and holds the ESP32-S3 lying flat, header
// pins pointing DOWN, with a wiring bay underneath for the female Dupont
// jumpers, lever nuts, the 220R resistor and the 0.1uF cap.
//
// Replaces rodi-rim-mount.scad and rodi-controller-box.scad.
//
// Coordinates (same as the old parts): z = 0 is the top of the bucket rim,
// x = 0 is the inside face of the bucket wall, +x points into the bucket,
// y runs along the rim. The box sits at -x, the sender at +x.
//
// Two parts:
//   body - hook, arm, flange plate and box in one piece. Print UPSIDE DOWN:
//          the flange seat, arm top, bridge and box rim are all one flat
//          plane at the top, so that plane goes on the bed. No supports. The
//          box floor bridges ~39mm; the board ledges overhang 1.5mm. 4 walls,
//          40% infill.
//   lid  - flat top cover for the box, held by 4 x M3 x 10 self-tapping
//          screws (or #4 sheet-metal screws). Print flat.
// Set `part` below (or -D part="body") to export each one.
//
// Sender flange (from the sender's drawing): 69mm OD, 54mm bolt circle,
// 5.5mm holes, M5 x 16 screws. The 5 holes are NOT evenly spaced: going
// around, the gaps are 72, 68, 80, 68, 72 deg. The 80 deg gap is where the
// cable leaves the head; here it points back toward the wall/box (-x).
// M5 nuts sit in hex traps on the plate underside.
//
// Wiring (sender): brown = signal -> GPIO4 node, blue = negative -> GND.
//
// Measured: sender, flange, rim lip thickness, bucket height. Rim hook gap is
// the one from the controller box (0.6mm clearance on the outside of the lip,
// box back face is the outer jaw), which fit well.
// ASSUMED (check): rod tip 5mm past the bottom stop, inside depth 14",
// bucket inside radius at the rim (for the curved inner hook leg),
// ESP32-S3-DevKitC-1 size board (~70 x 25.4mm).

/* [Part] */
part = "assembly"; // [assembly, body, lid]
// Draw the lid in the assembly view
show_lid = true;

/* [Bucket] */
// Rim top to inside floor (14.5" tall bucket, ~0.5" base) - ASSUMED
inside_depth = 355.6;
// Thickness of the rim lip (measured 0.25")
lip_thickness = 6.35;
// Clearance on the outside of the lip (controller box value, fit well)
lip_clearance = 0.6;
// Inside radius of the bucket at the rim (11.25" dia) - ASSUMED. The inner
// leg is curved to this so a wide hook does not bind on the curved rim.
bucket_inner_r = 142.9;
// How far the inner leg reaches down the inside wall
inner_leg_drop = 30;
leg_thickness = 4;
// Width of the rim hook along the rim
hook_width = 40;

/* [Sender] */
// Flange underside -> top float stop (measured 3/4")
top_stop_below_flange = 19.05;
// Top stop -> bottom stop (measured 12.75")
stop_to_stop = 323.85;
// Rod tip below the bottom stop - ASSUMED, measure it
tip_below_bottom_stop = 5;
// Float diameter (measured 34.94mm); the bore must pass it
float_dia = 34.94;
// Flange outside diameter (drawing: 69)
flange_od = 69;
// Bolt circle diameter (drawing: 54)
bolt_circle_dia = 54;
// Bolt hole angles (deg). 0 = into the bucket (+x). Gaps 72/68/80/68/72,
// the 80 deg gap (cable side) centred on 180 = toward the wall.
bolt_angles = [0, 72, 140, 220, 288];
// Rotate the whole bolt pattern (deg)
bolt_rotation = 0;
// Through-hole for M5 (drawing: 5.5; printed holes run a bit small)
bolt_hole_dia = 5.6;
// M5 hex nut across flats (8.0) + print clearance
nut_af = 8.4;
// Nut trap depth from the plate underside (M5 nut is 4.0 thick)
nut_depth = 4.4;

/* [Arm] */
// Wall inside face -> sender centreline
arm_reach = 60;
// Gap the rod tip keeps off the floor
tip_floor_clearance = 25.4;
// Width of the arm along the rim
arm_width = 26;
// Flange plate thickness
plate_thickness = 8;
// Plate diameter
plate_dia = 80;
// Bore clearance around the float
bore_clearance = 3;

/* [Board] */
// Board length (USB end to antenna end), width, PCB thickness
board_len = 70;
board_w = 25.4;
pcb_t = 1.6;
// Free space from the PCB top to the lid (module, buttons, USB shells)
top_space = 6;
// Free space from the PCB bottom to the box floor. Header pins (~8.5mm)
// + female Dupont housings (~14mm) + wire bends + lever nuts lying on the
// floor beside them.
under_space = 48;
// Corner ledges the PCB corners rest on (how far under the PCB in x, and
// how far along it in y). Keep ledge_len short of the first header pin.
ledge_w = 1.5;
ledge_len = 3.5;
// USB-C cutout in the +y end wall: width across the board (24 covers both
// ports on a DevKitC-1) and centre height above the PCB top. The slot is
// open at the top so the plug drops in; the lid closes it.
usb_cut_w = 24;
usb_center_above_pcb = 1.6;
fit = 0.25;

/* [Box] */
wall = 2.4;
// Sender cable hole in the box floor (was 5.5 on the old box)
cable_hole_dia = 7;
// Lid
lid_t = 2.4;
// Corner screw columns (M3 self-tapping: 2.5 pilot, 3.4 clearance)
boss_dia = 6.5;
pilot_dia = 2.5;
pilot_depth = 12;
screw_clear_dia = 3.4;

$fn = 96;

// ---- derived: sender ----
rod_below_flange = top_stop_below_flange + stop_to_stop + tip_below_bottom_stop;
// Height of the flange seat (plate top) above the rim top.
seat_height = max(rod_below_flange + tip_floor_clearance - inside_depth,
                  plate_thickness);
bore_dia = float_dia + bore_clearance;
arm_end = arm_reach - plate_dia / 2 + 8;  // where the full-depth arm stops

// ---- derived: box ----
gap = lip_thickness + lip_clearance;
back_out = -gap;                          // box back outer face (outer jaw)
cav_x = board_w + 2 * fit + 2 * boss_dia; // board fits between the columns
cav_y = board_len + 2 * fit;
cav_z = top_space + pcb_t + under_space;
box_x = cav_x + 2 * wall;
box_y = cav_y + 2 * wall;
front_out = back_out - box_x;
z_top = seat_height;                      // box rim flush with the arm top
z_in = z_top - cav_z;                     // cavity floor
z_bot = z_in - wall;
z_pcb = z_in + under_space;               // PCB underside
x_in0 = front_out + wall;                 // cavity x range
x_in1 = back_out - wall;
x_mid = (x_in0 + x_in1) / 2;
col_bot = z_top - pilot_depth - 2;        // screw column bottom
col_xy = boss_dia / 2;                    // column centre inset from walls

echo(str("Flange seat ", seat_height, " mm above rim top"));
echo(str("Rod tip ", inside_depth + seat_height - rod_below_flange,
         " mm off the floor"));
echo(str("Box outside: ", box_x, " (out from bucket) x ", box_y,
         " (along rim) x ", z_top - z_bot + lid_t, " mm tall incl. lid"));
echo(str("Box hangs ", -z_bot, " mm below the rim top"));
echo(str("Rim gap ", gap, " mm"));
assert(bore_dia / 2 + 3 < bolt_circle_dia / 2 - nut_af / 2 / cos(30),
       "Bore too close to the nut traps");
assert(arm_reach - plate_dia / 2 > leg_thickness + 2,
       "Plate hits the inner leg");
assert(arm_end < arm_reach + bolt_circle_dia / 2 * cos(140) - nut_af,
       "Arm runs under a nut trap");
assert(col_bot < z_pcb - ledge_w, "Screw columns must reach below the PCB");

module hex(af, h) {
    cylinder(d = af / cos(30), h = h, $fn = 6);
}

// ---------------------------------------------------------------- hook/arm
module inner_leg() {
    // Curved to the bucket's inside wall so the whole hook width bears evenly.
    // Outer face is tangent to x = 0 at y = 0, like the old straight leg.
    translate([0, 0, -inner_leg_drop])
        intersection() {
            translate([bucket_inner_r, 0, 0]) difference() {
                cylinder(r = bucket_inner_r, h = inner_leg_drop + 0.01,
                         $fn = 720);
                translate([0, 0, -1])
                    cylinder(r = bucket_inner_r - leg_thickness,
                             h = inner_leg_drop + 2, $fn = 720);
            }
            translate([-1, -hook_width / 2, 0])
                cube([leg_thickness + 4, hook_width, inner_leg_drop + 0.01]);
        }
}

module hook_and_arm() {
    // Bridge over the rim, box back -> inner leg, full hook width
    translate([back_out - 0.01, -hook_width / 2, 0])
        cube([leg_thickness - back_out + 2, hook_width, seat_height]);
    inner_leg();
    // Arm out to the plate
    translate([0, -arm_width / 2, 0])
        cube([arm_end, arm_width, seat_height]);
    // Flange plate
    translate([arm_reach, 0, seat_height - plate_thickness])
        cylinder(d = plate_dia, h = plate_thickness);
}

module sender_cutouts() {
    translate([arm_reach, 0, 0]) {
        translate([0, 0, -1]) cylinder(d = bore_dia, h = seat_height + 2);
        for (a = bolt_angles) rotate([0, 0, bolt_rotation + a])
            translate([bolt_circle_dia / 2, 0, 0]) {
                translate([0, 0, -1])
                    cylinder(d = bolt_hole_dia, h = seat_height + 2, $fn = 32);
                translate([0, 0, seat_height - plate_thickness - 1])
                    rotate([0, 0, 30]) hex(nut_af, nut_depth + 1);
            }
    }
}

// --------------------------------------------------------------------- box
module column(sx, sy) {
    // Screw column in one corner, with a ledge the PCB corner rests on.
    cx = sx < 0 ? x_in0 + col_xy : x_in1 - col_xy;
    cy = sy < 0 ? -cav_y / 2 + col_xy : cav_y / 2 - col_xy;
    wx = sx < 0 ? x_in0 - 0.01 : x_in1 - col_xy;      // corner square origin
    wy = sy < 0 ? -cav_y / 2 - 0.01 : cav_y / 2 - col_xy;
    lx = boss_dia + fit + ledge_w;                    // ledge reach from wall
    difference() {
        union() {
            hull() {
                translate([cx, cy, col_bot])
                    cylinder(d = boss_dia, h = z_top - col_bot);
                translate([wx, wy, col_bot])
                    cube([col_xy + 0.01, col_xy + 0.01, z_top - col_bot]);
            }
            // PCB ledge: from the wall to ledge_w under the PCB edge
            translate([sx < 0 ? x_in0 - 0.01 : x_in1 - lx,
                       sy < 0 ? -cav_y / 2 - 0.01 : cav_y / 2 - fit - ledge_len,
                       col_bot])
                cube([lx + 0.01, fit + ledge_len + 0.01, z_pcb - col_bot]);
        }
        translate([cx, cy, z_top - pilot_depth])
            cylinder(d = pilot_dia, h = pilot_depth + 1, $fn = 24);
    }
}

module box() {
    difference() {
        translate([front_out, -box_y / 2, z_bot])
            cube([box_x, box_y, z_top - z_bot]);
        // Cavity, open at the top
        translate([x_in0, -cav_y / 2, z_in]) cube([cav_x, cav_y, cav_z + 1]);
        // USB-C slot in the +y end wall, open at the top
        translate([x_mid - usb_cut_w / 2, cav_y / 2 - 0.01,
                   z_pcb + pcb_t + usb_center_above_pcb - 4.5])
            cube([usb_cut_w, wall + 2, cav_z]);
        // Sender cable through the floor at the antenna (-y) end
        translate([x_mid, -cav_y / 2 + 10, z_bot - 1])
            cylinder(d = cable_hole_dia, h = wall + 2, $fn = 48);
    }
    for (sx = [-1, 1], sy = [-1, 1]) column(sx, sy);
}

module body() {
    difference() {
        union() {
            hook_and_arm();
            box();
        }
        sender_cutouts();
    }
}

module lid() {
    difference() {
        translate([front_out, -box_y / 2, z_top]) cube([box_x, box_y, lid_t]);
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx < 0 ? x_in0 + col_xy : x_in1 - col_xy,
                       sy < 0 ? -cav_y / 2 + col_xy : cav_y / 2 - col_xy,
                       z_top - 1])
                cylinder(d = screw_clear_dia, h = lid_t + 2, $fn = 24);
    }
}

// ------------------------------------------------------- assembly ghosts
module board_ghost() {
    color("seagreen") translate([x_mid - board_w / 2, -board_len / 2, z_pcb])
        cube([board_w, board_len, pcb_t]);
    color("silver") translate([x_mid - 9, -board_len / 2, z_pcb + pcb_t])
        cube([18, 25, 3.2]);
    // Header pins + Dupont housings hanging down
    color("black") for (sx = [-1, 1])
        translate([x_mid + sx * (board_w / 2 - 1.27) - 1.27, -28, z_pcb - 16.5])
            cube([2.54, 56, 16.5]);
}

module sender_ghost() {
    color("silver", 0.8) translate([arm_reach, 0, 0]) {
        translate([0, 0, seat_height]) cylinder(d = flange_od, h = 3.2);
        translate([0, 0, seat_height + 3.2]) cylinder(d = 22, h = 18);
        translate([-25, 0, seat_height + 14]) rotate([0, 90, 0])
            cylinder(d = 6, h = 25, $fn = 24);
        translate([0, 0, seat_height - 120]) cylinder(d = 12, h = 120);
        translate([0, 0, seat_height - top_stop_below_flange - 32])
            cylinder(d = float_dia, h = 32);
    }
}

module bucket_ghost() {
    // A slice of the bucket wall near the mount (lip shown full height)
    color("white", 0.4) intersection() {
        translate([bucket_inner_r, 0, -110]) difference() {
            cylinder(r = bucket_inner_r + lip_thickness, h = 110, $fn = 360);
            translate([0, 0, -1])
                cylinder(r = bucket_inner_r, h = 112, $fn = 360);
        }
        translate([-20, -70, -111]) cube([40, 140, 112]);
    }
}

if (part == "body") {
    // Flange seat / arm top / box rim plane on the bed
    translate([0, 0, seat_height]) rotate([180, 0, 0]) body();
} else if (part == "lid") {
    translate([0, 0, -z_top]) lid();
} else {
    color("steelblue") body();
    if (show_lid) color("lightsteelblue", 0.7) lid();
    board_ghost();
    sender_ghost();
    bucket_ghost();
}
