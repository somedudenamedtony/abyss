// RODI reservoir controller box (print in PETG)
//
// A small box for the ESP32-S3 that hooks over the bucket rim next to the
// float-sender mount and hangs on the OUTSIDE of the bucket, so it stays dry
// when the bucket is refilled. Both cables (sender wire and USB-C power)
// enter from the bottom, so drips run off instead of in. Leave a drip loop in
// each cable below the box.
//
// Coordinates match rodi-rim-mount.scad: z = 0 is the top of the bucket rim,
// x = 0 is the inside face of the bucket wall, +x points into the bucket,
// y runs along the rim. The box sits at -x (outside the bucket).
//
// Two parts:
//   body - 5-sided box with the rim hook. Print on its closed side (the
//          "floor", y = 0) with the open side up. No supports.
//   lid  - flat side cover, held by 4 x M3 x 10 self-tapping screws
//          (or #4 sheet-metal screws). Print outside face down.
// Set `part` below (or -D part="body") to export each one.
//
// The board stands upright with its USB-C end down. It is held at the top
// (antenna) end by short slots in the floor and lid, and at the bottom by
// the USB-C plug through the bottom wall. A strip of foam tape on the back
// of the board works too, if your board differs.
//
// BOARD SIZE IS ASSUMED: ESP32-S3-DevKitC-1 class board, ~70 x 25.4mm,
// headers soldered pointing toward the bucket. Change [Board] for others.

/* [Part] */
part = "assembly"; // [assembly, body, lid]
// Draw the lid in the assembly view
show_lid = false;

/* [Board] */
// Board length (USB end to antenna end)
board_len = 70;
// Board width
board_w = 25.4;
// PCB thickness
pcb_t = 1.6;
// Header pins + plastic sticking out the back (0 if no headers)
pin_depth = 11.5;
// Tallest part on the front (module, buttons, USB shell)
front_depth = 5;
// Length of the slot segments that grip the antenna end
grip_len = 10;
// USB-C plug cutout in the bottom wall (width along the board, depth)
usb_cut_w = 24;
usb_cut_d = 9;
// USB-C receptacle height above the PCB front face (centre of the cutout)
usb_center_above_pcb = 1.6;
// Board raised off the bottom wall (USB shells often overhang the edge)
board_lift = 0.5;

/* [Box] */
wall = 2.4;
// Free space above the board for the 220R resistor and a 2-pole lever nut
top_space = 22;
// Free space between the back wall and the header pin tips. 12mm leaves
// room for female Dupont jumpers pushed onto the pins (~14mm housing + bend)
back_space = 12;
// Free space in front of the board components
front_space = 8;
// Cable hole for the 2-conductor sender wire
cable_hole_dia = 5.5;
// Lid thickness
lid_t = 2.4;
// Corner screw bosses (M3 self-tapping: 2.5 pilot, 3.4 clearance)
boss_dia = 6.5;
pilot_dia = 2.5;
screw_clear_dia = 3.4;
// Slot rib size
rib_t = 1.6;
rib_h = 2;
fit = 0.25;

/* [Rim hook] */
// Same as rodi-rim-mount.scad
lip_thickness = 6.35;
lip_clearance = 0.6;
inner_leg_drop = 30;
leg_thickness = 4;
// Bridge height above the rim (box top is flush with it)
bridge_t = 4;
// Gap between the rim and the box back. Increase if ridges under the rim
// push the bottom of the box outward; the spacer then bears on the lip only.
standoff = 0;
// How far the spacer reaches down the lip (only used when standoff > 0)
spacer_drop = 12;

$fn = 64;

// ---- derived ----
gap = lip_thickness + lip_clearance;
// Cavity, measured from the back (bucket side) inner face: u
board_u = back_space + pin_depth;                 // PCB back face
cav_x = board_u + pcb_t + front_depth + front_space;
cav_y = board_w + 2 * fit;
cav_z = board_lift + board_len + top_space;

back_out = -gap - standoff;                      // box back outer face (x)
front_out = back_out - cav_x - 2 * wall;
z_top = bridge_t;
z_bot = z_top - cav_z - 2 * wall;
z_in = z_bot + wall;                             // cavity floor (bottom wall)
body_w = wall + cav_y;                           // open side at y = body_w

function ux(u) = back_out - wall - u;            // cavity u -> global x

boss_inset = boss_dia / 2 - 0.25;
boss_u = [boss_inset, cav_x - boss_inset];
boss_z = [z_in + boss_inset, z_in + cav_z - boss_inset];

board_z0 = z_in + board_lift;
board_z1 = board_z0 + board_len;
usb_u = board_u + pcb_t + usb_center_above_pcb;

echo(str("Box outside: ", cav_x + 2 * wall, " x ", body_w + lid_t, " x ",
         cav_z + 2 * wall, " mm (out from bucket x along rim x tall)"));
echo(str("Box hangs ", -z_bot, " mm below the rim top"));
assert(boss_u[0] + boss_dia / 2 < board_u - pin_depth + 0.01,
       "Back bosses hit the header pins; increase back_space");
assert(usb_u + usb_cut_d / 2 < boss_u[1] - boss_dia / 2,
       "USB cutout cuts into the front bosses; increase front_space");

module hook() {
    // Bridge over the rim, from the box back to the inner leg
    translate([back_out - 0.01, 0, 0])
        cube([leg_thickness - back_out + 0.01, body_w, bridge_t]);
    // Inner leg on the inside wall
    translate([0, 0, -inner_leg_drop])
        cube([leg_thickness, body_w, inner_leg_drop + bridge_t]);
    // Spacer that bears on the outside of the lip
    if (standoff > 0)
        translate([back_out - 0.01, 0, -spacer_drop])
            cube([standoff + 0.01, body_w, spacer_drop + bridge_t]);
}

// Slot that grips one edge of the board at the antenna end.
// y0 = face the ribs stand on, dir = +1 / -1 (direction the ribs point).
module grip(y0, dir) {
    for (u = [board_u - fit - rib_t, board_u + pcb_t + fit])
        translate([ux(u + rib_t), dir > 0 ? y0 : y0 - rib_h,
                   board_z1 - grip_len])
            cube([rib_t, rib_h, grip_len]);
}

module body() {
    difference() {
        union() {
            // Shell
            translate([front_out, 0, z_bot])
                cube([cav_x + 2 * wall, body_w, cav_z + 2 * wall]);
            hook();
        }
        // Cavity, open at y = body_w
        translate([ux(cav_x), wall, z_in])
            cube([cav_x, cav_y + 1, cav_z]);
        // USB-C plug
        translate([ux(usb_u + usb_cut_d / 2), wall + cav_y / 2 - usb_cut_w / 2,
                   z_bot - 1])
            cube([usb_cut_d, usb_cut_w, wall + 2]);
        // Sender cable
        translate([ux(back_space / 2 + pin_depth / 2), wall + cav_y / 2, z_bot - 1])
            cylinder(d = cable_hole_dia, h = wall + 2);
    }
    // Screw bosses, full height of the cavity in y
    for (u = boss_u, z = boss_z)
        difference() {
            translate([ux(u), wall - 0.01, z]) rotate([-90, 0, 0])
                cylinder(d = boss_dia, h = cav_y + 0.01);
            translate([ux(u), wall + 2, z]) rotate([-90, 0, 0])
                cylinder(d = pilot_dia, h = cav_y);
        }
    grip(wall, 1);
}

module lid() {
    difference() {
        translate([front_out, body_w, z_bot])
            cube([cav_x + 2 * wall, lid_t, cav_z + 2 * wall]);
        for (u = boss_u, z = boss_z)
            translate([ux(u), body_w - 1, z]) rotate([-90, 0, 0])
                cylinder(d = screw_clear_dia, h = lid_t + 2);
    }
    grip(body_w, -1);
}

// Board, for the assembly view only
module board_ghost() {
    color("seagreen") translate([ux(board_u + pcb_t), wall + fit, board_z0])
        cube([pcb_t, board_w, board_len]);
    color("silver") translate([ux(board_u + pcb_t + front_depth),
                               wall + fit + 3.7, board_z1 - 25])
        cube([front_depth, 18, 25]);
}

// Bucket wall section, for the assembly view only
module bucket_ghost() {
    color("white", 0.35) translate([-lip_thickness, -20, -120])
        cube([lip_thickness, body_w + 40, 120]);
}

if (part == "body") {
    // Floor (y = 0) on the bed, open side up
    rotate([90, 0, 0]) body();
} else if (part == "lid") {
    // Outside face on the bed, ribs up
    translate([0, 0, body_w + lid_t]) rotate([-90, 0, 0]) lid();
} else {
    color("steelblue") body();
    if (show_lid) color("lightsteelblue", 0.6) lid();
    board_ghost();
    bucket_ghost();
}
