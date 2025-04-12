use <src/core/gridfinity-rebuilt-utility.scad>
use <src/core/gridfinity-rebuilt-holes.scad>

// ===== PARAMETERS ===== //

/* [Setup Parameters] */

// ===== IMPLEMENTATION ===== //
/* [DXF file path] */
// Define a variable for the DXF file path
dxf_file_path = "examples/example.dxf";

/* [DXF Position] */
// Array to adjust the x and y position of the DXF file
dxf_position = [0, 0]; // [x, y]

// [DXF Rotation]
// Variable to adjust the rotation of the DXF file
dxf_rotation = 0; // Rotation angle in degrees

/* [General Settings] */
// number of bases along x-axis
gridx = 5; //.5
// number of bases along y-axis
gridy = 2; //.5
// bin height. See bin height information and "gridz_define" below.
gridz = 6; //1
style_lip = 1; //[0: Regular lip, 1:remove lip subtractively]

/* [Finger Slot Options] */
// Number of finger slots
num_slots = 1; //[0:1:4] //.5
// Width of each slot
slot_width = 40; // 10
// Radius of the rounded ends of the slot
slot_radius = 10; // Adjust as needed
// Vertical offset of the finger slot from the top of the DXF cut
slot_vertical_offset = 0; // Adjust this to fine-tune the vertical position
// Depth of the finger slot (how far it extends downwards)
slot_depth = 15; // Adjust as needed
// Array of start positions relative to the x-axis
start_positions = [0, -50, 100, 0]; // .1
// Rotation angle of the slots
slot_rotation = 90; // 10
/* [Cut Depth] */
// Variable for cut depth
cut_depth = 10; // 1

/* [Label Cutout] */
include_cutout = false; // true or false
cutout_height = 1.8;
include_label = false; // true or false
label_height = 11; // 1
label_width = 80; // 5
label_thickness = 4;
label_clearance = 0.1; //
label_position_x = 0; // 10
label_position_y = 0; // 10

text_thickness = 0.6; // height of the text in mm
text_size = 9; // size of the text
input_text_value = "Custom Text"; // Input text value

// Label Rotation
label_rotation = 0;

// Label Position Options
label_position_option = "bottom"; // ["bottom", "top", "right", "left"]

/* [Hidden] */
text_font = "Arial Rounded MT Bold:style=Regular";
$fa = 8;
$fs = 0.25; // .01
// number of X Divisions (set to zero to have solid bin)
divx = 0;
// number of Y Divisions (set to zero to have solid bin)
divy = 0;
// number of cylindrical X Divisions (mutually exclusive to Linear Compartments)
cdivx = 0;
// number of cylindrical Y Divisions (mutually exclusive to Linear Compartments)
cdivy = 0;
// orientation
c_orientation = 2; // [0: x direction, 1: y direction, 2: z direction]
// diameter of cylindrical cut outs
cd = 10; // .1
// cylinder height
ch = 1;  //.1
// spacing to lid
c_depth = 1;
// chamfer around the top rim of the holes
c_chamfer = 0.5; // .1

style_tab = 1; //[0:Full,1:Auto,2:Left,3:Center,4:Right,5:None]
place_tab = 0;
//style_lip = 1; //[0: Regular lip, 1:remove lip subtractively, 2: remove lip and retain height]
scoop = 1; //[0:0.1:1]
only_corners = false;
refined_holes = false;
magnet_holes = false;
screw_holes = false;
crush_ribs = true;
chamfer_holes = true;
printable_hole_top = true;
enable_thumbscrew = false;
hole_options = bundle_hole_options(refined_holes, magnet_holes, screw_holes, crush_ribs, chamfer_holes, printable_hole_top);
// determine what the variable "gridz" applies to based on your use case
gridz_define = 0;
height_internal = 0;
enable_zsnap = false;

// Function to create a finger slot with a rounded bottom
module rounded_finger_slot(width = 80, radius = 10, depth = 15, start_pos = 0, rotation = 0, vertical_offset = 0) {
    translate([start_pos, 0, (gridz * 7 - (include_cutout ? cutout_height : 0)) - vertical_offset - depth + radius + 0.01]) {
        rotate([0, 0, rotation]) {
            hull() {
                // Bottom half-cylinder (rounded part)
                translate([-width/2 + radius, 0, 0]) cylinder(r = radius, h = 0.01, center = false, $fn = 32);
                translate([width/2 - radius, 0, 0]) cylinder(r = radius, h = 0.01, center = false, $fn = 32);

                // Top flat part (approximated with short cylinders)
                translate([-width/2 + radius, 0, depth - 2 * radius]) cylinder(r = radius, h = 0.01, center = false, $fn = 32);
                translate([width/2 - radius, 0, depth - 2 * radius]) cylinder(r = radius, h = 0.01, center = false, $fn = 32);

                // Connecting cylinders (sides)
                translate([-width/2 + radius, 0, 0]) cylinder(r = radius, h = depth - radius, center = false, $fn = 32);
                translate([width/2 - radius, 0, 0]) cylinder(r = radius, h = depth - radius, center = false, $fn = 32);
            }
        }
    }
}

difference() {
    // Base object to cut from
    gridfinityInit(gridx, gridy, height(gridz, gridz_define, style_lip, enable_zsnap), height_internal, sl = style_lip) {
        if (divx > 0 && divy > 0) {
            cutEqual(n_divx = divx, n_divy = divy, style_tab = style_tab, scoop_weight = scoop, place_tab = place_tab);
        } else if (cdivx > 0 && cdivy > 0) {
            cutCylinders(n_divx = cdivx, n_divy = cdivy, cylinder_diameter = cd, cylinder_height = ch, coutout_depth = c_depth, orientation = c_orientation, chamfer = c_chamfer);
        }
    }

    // Position, rotate, and extrude the DXF shape to perform the cut
    translate([dxf_position[0], dxf_position[1], gridz*7-cut_depth-+ (include_cutout ? cutout_height : 0)]) { // Use the array to adjust the x and y position
        rotate([0, 0, dxf_rotation]) { // Rotate the DXF file
            linear_extrude(height = cut_depth+1+ (include_cutout ? cutout_height : 0)) { // Cut downward by the variable cut_depth
                scale([25.4, 25.4, 1]) { // Scale from inches to mm
                    import(dxf_file_path);
                }
            }
        }
    }

    // Add the rounded finger slots with controlled depth and vertical positioning
    for (i = [0 : num_slots - 1]) {
        rounded_finger_slot(slot_width, slot_radius, slot_depth, start_positions[i], slot_rotation, slot_vertical_offset);
    }

    // Create rounding elements at the intersection (example: a torus section)
    if (include_cutout && num_slots > 0) {
        for (i = [0 : num_slots - 1]) {
            // Rounding at one side of the slot
            translate([start_positions[i] - slot_width/2 + rounding_radius, 0, (gridz * 7 - cutout_height) - rounding_radius]) {
                rotate([90, 0, slot_rotation])
                linear_extrude(height = rounding_radius)
                offset(r = -0.1)
                offset(delta = rounding_radius)
                circle(r = 1, $fn = 16);
            }
            // Rounding at the other side of the slot
            translate([start_positions[i] + slot_width/2 - rounding_radius, 0, (gridz * 7 - cutout_height) - rounding_radius]) {
                rotate([90, 0, slot_rotation])
                linear_extrude(height = rounding_radius)
                offset(r = -0.1)
                offset(delta = rounding_radius)
                circle(r = 1, $fn = 16);
            }
        }
    }

    // Add label slot if include_label is true
    if (include_label) {
        if (label_position_option == "bottom") {
            translate([0 + label_position_x, -gridy * 42 / 2 + label_height / 2 + 5 + label_position_y, gridz * 7 - label_thickness / 2]) {
                rotate([0, 0, label_rotation]) {
                    cube([label_width + label_clearance, label_height + label_clearance, label_thickness], center = true);
                }
            }
        } else if (label_position_option == "top") {
            translate([0 + label_position_x, gridy * 42 / 2 - label_height / 2 - 5 + label_position_y, gridz * 7 - label_thickness / 2]) {
                rotate([0, 0, label_rotation]) {
                    cube([label_width + label_clearance, label_height + label_clearance, label_thickness], center = true);
                }
            }
        } else if (label_position_option == "right") {
            translate([gridx * 42 / 2 - label_height / 2 - 5 + label_position_x, 0 + label_position_y, gridz * 7 - label_thickness / 2]) {
                rotate([0, 0, label_rotation]) {
                    cube([label_height + label_clearance, label_width + label_clearance, label_thickness], center = true);
                }
            }
        } else if (label_position_option == "left") {
            translate([-gridx * 42 / 2 + label_height / 2 + 5 + label_position_x, 0 + label_position_y, gridz * 7 - label_thickness / 2]) {
                rotate([0, 0, label_rotation]) {
                    cube([label_height + label_clearance, label_width + label_clearance, label_thickness], center = true);
                }
            }
        }
    }
}

// Conditionally extrude the DXF at x=0 y=gridy*42+5
if (include_cutout) {
    translate([0, gridy*42+5, 0]) {
        linear_extrude(height = cutout_height) {
            scale([25.4, 25.4, 1]) {
                import(dxf_file_path);
            }
        }
    }
}

render(convexity = 2)
// Conditionally extrude the label at x=0 y=-gridy*42+5
if (include_label) {
    // Adjust the position of the label based on gridy
    translate([0, -gridy*42/2-5-label_height/2, label_thickness/2]) {
        union() {
            cube([label_width, label_height, label_thickness], center = true);
            // Add text on top of the label
            translate([0, 0,label_thickness/2]) {
                linear_extrude(height = text_thickness) {
                    text(input_text_value, size = text_size, font = text_font, halign = "center", valign = "center");
                }
            }
        }
    }
}

render(convexity = 2)
// Draw the base with holes
gridfinityBase([gridx, gridy], hole_options = hole_options, only_corners = only_corners, thumbscrew = enable_thumbscrew);