// 'LAVACore_MultiGauge_OpenSCAD_GitHub_v001_2026-Feb-15'
// Gen2/Gen3 Hybrid Core, suitable for .STL exports
// License MiT open source

/*
Features:
- Precision energy "packetization" (IH mode), 100 Joules of convective aerial flux conversion
- Bi-Energy compatibility, impulse heating (250 ~ 550 °C) for flame/induction
- Suspension "floating" Open Ring for thermal decoupling with optional snap-fit
- Cradle Pads to accommodate 14 mm I.D. glass containment
*/

// ======================================================
// CONFIGURATION & FONTS
// ======================================================

ring   = true;   // Show optional Open Ring (Inconel X‑750)
labels = true;   // Show optional Labels
gauge  = 24;     // Permissible Gauge Options: 22, 23, 24, 25, 26
$fn    = 128;    

font_main = "Trebuchet MS:style=Bold";
font_ring = "JetBrains Mono:style=SemiBold";

// ======================================================
// GEOMETRY PARAMETERS
// ======================================================

base_unit      = 0.25;   
pad_unit       = 0.25;   
thickness      = 1.0;    
disk_diameter  = 12.55;  
hole_radius    = 0.75565;
pad_anchor     = 6.5047; 
cradle_width   = 0.70;   
cradle_radius  = cradle_width/2;

wire_radius = 
    (gauge == 22) ? 0.3226 : 
    (gauge == 23) ? 0.2867 : 
    (gauge == 24) ? 0.2555 : 
    (gauge == 25) ? 0.2274 : 0.2025;

cradle_standoff = 0.55;  
ring_orbit = (disk_diameter/2) + cradle_standoff + wire_radius - cradle_radius; 

ring_gap       = 0.75;   
angle_missing  = ring_gap * 180 / (PI * ring_orbit); 
angle_covered  = 360 - angle_missing; 
angle_start    = -23;    

// ======================================================
// UTILITY MODULES
// ======================================================

module pad_cube() { cube([pad_unit, pad_unit, thickness]); }

module pad_inter(ox, oy) {
    intersection() {
        pad_cube();
        translate([ox, oy, 0]) cylinder(r = pad_unit, h = thickness);
    }
}

module pad_diff(ox, oy) {
    difference() {
        pad_cube();
        translate([ox, oy, 0]) cylinder(r = pad_unit, h = thickness);
    }
}

module pad_leg() {
    translate([pad_anchor, 0, 0]) {
        translate([-pad_unit, -2*pad_unit, 0]) pad_diff(pad_unit, 0);
        translate([-pad_unit, -pad_unit, 0])   pad_cube();
        translate([ 0, -pad_unit, 0])          pad_inter(0, pad_unit);
        translate([-pad_unit,  0, 0])          pad_cube();
        translate([ 0,  0, 0])                 pad_inter(0, 0);
        translate([-pad_unit,  pad_unit, 0])   pad_diff(pad_unit, pad_unit);
    }
}

module arc_text(str, radius, angle_center, size, spacing=5, inverse=false, f_name) {
    n = len(str);
    for (i = [0 : n-1]) {
        angle = angle_center + (i - (n-1)/2) * spacing;
        rotate([0,0,angle])
            translate([radius, 0, 0])
                rotate([0,0, inverse ? 90 : -90])
                    text(str[i], font=f_name, size=size, halign="center", valign="center");
    }
}

// ======================================================
// DISK LABELS (SS430)
// ======================================================

module disk_labels_engraved() {
    engrave_depth = 0.07; 
    translate([0, 0, thickness - engrave_depth + 0.001])
    linear_extrude(height = engrave_depth) {
        arc_text("eroCAVAL", (disk_diameter/2)-0.34, 134, 0.35, 5.5, false, font_main);
        arc_text("034SS",    (disk_diameter/2)-0.34, 89,  0.35, 5.5, false, font_main);

        arc_text("1",  (disk_diameter/2)-0.34, 53, 0.35, 5.5, false, font_main);
        arc_text(".",  (disk_diameter/2)-0.46, 50, 0.35, 5.5, false, font_main);
        arc_text("0",  (disk_diameter/2)-0.34, 47, 0.35, 5.5, false, font_main);
        arc_text("mm", (disk_diameter/2)-0.34, 38, 0.35, 4.7, false, font_main);

        arc_text("By Egzoset", (disk_diameter/2)-0.32, 270, 0.35, 8, true, font_main);
    }
}

// ======================================================
// RING & RING LABELS (Inconel X-750)
// ======================================================

module ring_assembly() {
    // Porting CADQuery variables to OpenSCAD
    z_start_cut  = (thickness / 2) + wire_radius + 0.025;
    label_offset = 0.01 + ((26 - gauge) * 0.005);
    center_ring  = angle_start + (angle_covered / 1.597);
    
    // Dynamic settings per gauge
    h_ext   = (gauge == 22) ? 0.48 : (gauge == 23) ? 0.45 : (gauge == 24) ? 0.41 : (gauge == 25) ? 0.38 : 0.36;
    f_size  = 0.25; 
    f_space = 2.7;

    difference() {
        // The Ring Solid
        translate([0, 0, thickness/2])
            rotate([0, 0, angle_start - angle_missing/2])
                rotate_extrude(angle = angle_covered)
                    translate([ring_orbit, 0, 0]) circle(r = wire_radius);

        // The Labels (equivalent to ring_solid.cut(labels_vol))
        if (labels) {
            translate([0, 0, thickness/2 - 0.15]) 
            linear_extrude(height = h_ext) {
                arc_text("Inconel", ring_orbit + label_offset, center_ring - 6.6, f_size, 2.6, true, font_ring);
                arc_text("X-750",   ring_orbit + label_offset, center_ring + 13.1, f_size, 2.2, true, font_ring);
                arc_text(str("AWG#", gauge), ring_orbit + label_offset, center_ring + 31.4, f_size, 2.7, true, font_ring);
            }
        }
    }
}

// ======================================================
// FINAL ASSEMBLY (Core + Ring)
// ======================================================

union() {
    // Core Substrate (Disk + Pads - Holes - Cradle)
    difference() {
        union() {
            cylinder(d = disk_diameter, h = thickness, $fn = 512);
            for (i = [0:5]) rotate([0,0,i*60]) pad_leg();
        }
        
        // Holes
        hole_positions = [[0,0], [2.66,0], [1.8809,1.8809], [0,2.66], [-1.8809,1.8809],
                         [-2.66,0], [-1.8809,-1.8809], [0,-2.66], [1.8809,-1.8809],
                         [4.4437,1.8407], [1.8407,4.4437], [-1.8407,4.4437], [-4.4437,1.8407],
                         [-4.4437,-1.8407], [-1.8407,-4.4437], [1.8407,-4.4437], [4.4437,-1.8407]];
        for (p = hole_positions)
            translate([p[0], p[1], -0.1]) cylinder(r = hole_radius, h = thickness + 0.2);
        
        // Cradle groove
        translate([0, 0, thickness/2])
            rotate_extrude() translate([ring_orbit, 0, 0]) circle(r = cradle_radius);
            
        // Subtraction of Disk Labels
        if (labels) disk_labels_engraved();
    }

    // Addition of the (already cut) Ring
    if (ring) ring_assembly();
}

