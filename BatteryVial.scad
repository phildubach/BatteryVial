// Customizable Battery Vial
// (c) 2018, Phil Dubach
//
// Creative Commons License
// Customizable Battery Vial by Phil Dubach is licensed under a Creative
// Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
// Based on a work at https://github.com/phildubach/BatteryVial.

// which part to generate
part = "cap"; // ["cap", "body"]

// battery size
size = "AA"; // ["AAA", "AA", "C", "D", "18650", "custom"]

// inner diameter (for custom size)
custom_d = 15.0;

// inner length (for custom size)
custom_l = 51;

function cat(nested) = [ for(a=nested) for (b=a) b ];


module helix(radius, height, pitch, poly, start=0) {
    maxr = max([for (i = poly) i[1]]);
    maxh = max([for (i = poly) i[0]]);
    degrees = 360 * (height - maxh) / pitch;
    vertices = len(poly);
    points = [ for (a = [0:$fa:degrees]) 
        let (z0 = a * pitch / 360,
             q = (a > (degrees/2)) ? degrees - a : a,
             offs = (q < 20) ? ((20 - q) / 20) * maxr : 0)
             //offs = 0)
        for (i = [0:vertices-1])
            let (pz = poly[i][0],
                 pr = radius - offs + poly[i][1]
                ) [pr * cos(a + start), pr * sin(a + start), pz + z0]
    ];
    steps = floor(degrees / $fa);
    // TODO: fan triangulation only works for convex polygons
    // Passing the polygon face directly to polyhedron (without explicit
    // triangulation) causes assertion failures on some versions of CGAL.
    cap1 = [ for (i = [1:vertices-2]) let (base = len(points) - vertices) [ base, base+i, base+i+1 ] ]; // list of triangle faces
    cap2 = [ for (i = [1:vertices-2]) [ 0, i+1, i ] ]; // list of triangle faces
    tri1 = [ for (s = [0:steps-1]) let (base = s * vertices) for (i = [0:vertices-1])
                [ base + i, base + (i + 1) % vertices, base + vertices + (i + 1) % vertices ]
           ]; // list of triangle faces
    tri2 = [ for (s = [0:steps-1]) let (base = s * vertices) for (i = [0:vertices-1])
                [ base + i, base + vertices + (i + 1) % vertices, base + vertices + i ]
           ];
    faces = cat([cap1, cap2, tri1, tri2]);

    polyhedron(points=points, faces=faces, convexity=2);
}

extra_d = 0.8; // oversize for inner diameter
extra_l = 1; // oversize for inner length

inner_d = extra_d + ((size == "AAA") ? 10.5 :
                     (size == "AA") ? 14.2 :
                     (size == "C") ? 26 :
                     (size == "D") ? 33 :
                     (size == "18650") ? 18 :
                     (custom_d - extra_d));

inner_l = extra_l + ((size == "AAA") ? 44.5 :
                     (size == "AA") ? 50 :
                     (size == "C") ? 46 :
                     (size == "D") ? 58 :
                     (size == "18650") ? 65 :
                     (custom_l - extra_l));

eps = 0.01; // epsilon for overlaps
pd = 0.8;   // thread depth
ps = 0.8;   // thread step height (will be multiplied by 4: /-\_)
gap = 0.1;  // radial gap between inner and outer thread

r_inner = inner_d/2;
r_outer = r_inner + 0.9;
r_cap = r_outer + pd + gap + 0.9; 
thread_l = 16;
n_threads = 3;
pitch = n_threads * ps * 4;
wall = 2;
grip_h = 8;

module bevel(amount) {
    difference() {
        $fn=100;
        translate([0,0,-eps]) cylinder(r=r_cap+eps, h=amount+eps);
        translate([0,0,-2*eps]) cylinder(r1=r_cap-amount-eps, r2=r_cap+2*eps, h=amount+3*eps);
    }
}

if (part == "cap") {
    profile = [[0, -1], [0,0], [ps, pd], [2*ps, pd], [3*ps, 0], [3*ps, -1]];
    difference() {
        $fn = 100;
        union() {
            for (a = [0:360/n_threads:359]) helix(r_outer, thread_l, pitch, profile, start=a, $fa=4);
            cylinder(r=r_outer, h=thread_l);
            translate([0,0,-grip_h]) cylinder(r=r_cap, h=grip_h);
        }
        translate([0,0,wall-grip_h]) cylinder(d=inner_d, h=thread_l+grip_h-wall+eps);
        translate([0,0,-grip_h-eps]) for (a = [0:30:359]) {
            rotate([0,0,a]) translate([r_cap+1.5,0,0]) cylinder(d=4, h=grip_h+2*eps);
        }
        translate([0,0,-grip_h]) bevel(0.6);
        rotate([180,0,0]) bevel(0.45);
    }
} else if (part == "body") {
    profile = [[-gap, -1], [-gap,gap], [ps-gap, pd+gap], [2*ps+gap, pd+gap], [3*ps+gap, gap], [3*ps+gap, -1]];
    difference() {
        $fn = 100;
        tube_h = inner_l+wall-grip_h+wall;
        cylinder(r=r_cap, h=tube_h);
        translate([0,0,tube_h-thread_l-1]) {
            for (a = [0:360/n_threads:359]) helix(r_outer, thread_l + 5, pitch, profile, start=a, $fa=4);
        }
        translate([0,0,wall]) cylinder(r=r_inner, h=tube_h+eps-wall);
        translate([0,0,tube_h-thread_l-1]) cylinder(r=r_outer+gap, h=thread_l+1+eps);
        translate([0,0,tube_h-2+gap]) cylinder(r1=r_outer, r2=r_outer+pd+gap, h=2);
        bevel(0.6);
        translate([0,0,tube_h]) rotate([180,0,0]) bevel(0.45);
    }
}

