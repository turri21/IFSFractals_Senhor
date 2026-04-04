localparam FERNDEFINITIONCOUNT = 5;
localparam FERNPARAMETERCOUNT = 7;
localparam FERNFUNCTIONCOUNT = 4;
localparam FERNDEFINITIONSIZE = FERNPARAMETERCOUNT*FERNFUNCTIONCOUNT;
localparam S = 1<<FIXEDSHIFT;

wire signed [FIXEDBITS-1:0] ferndefinitions [0:FERNDEFINITIONCOUNT*FERNDEFINITIONSIZE-1] = '{

    // Barnsley Fern
    0.00*S,  0.00*S,  0.00*S,  0.16*S,  0.00*S,  0.00*S,  /*0.01*/ 0.01*S,
    0.85*S,  0.04*S, -0.04*S,  0.85*S,  0.00*S,  1.60*S,  /*0.85*/ 0.86*S,
    0.20*S, -0.26*S,  0.23*S,  0.22*S,  0.00*S,  1.60*S,  /*0.07*/ 0.93*S,
   -0.15*S,  0.28*S,  0.26*S,  0.24*S,  0.00*S,  0.44*S,  /*0.07*/ 1.00*S,

    // Sierpiński Triangle
    0.00*S,  0.00*S,  0.00*S,  0.00*S,  0.00*S,  0.00*S,  /*0.00*/ 0.00*S,
    0.50*S,  0.00*S,  0.00*S,  0.50*S,  0.00*S,  5.00*S,  /*0.33*/ 0.33*S,
    0.50*S,  0.00*S,  0.00*S,  0.50*S, -2.89*S,  0.00*S,  /*0.33*/ 0.66*S,
   -0.50*S,  0.00*S,  0.00*S,  0.50*S,  2.89*S,  0.00*S,  /*0.33*/ 1.00*S,

    // Mapel Leaf
    0.14*S,  0.01*S,  0.00*S,  0.51*S, -0.17*S,  0.58*S,  /*0.01*/ 0.01*S,
    0.49*S,  0.00*S,  0.00*S,  0.51*S,  0.03*S,  4.82*S,  /*0.33*/ 0.34*S,
    0.45*S, -0.49*S,  0.47*S,  0.47*S,  0.13*S,  1.60*S,  /*0.33*/ 0.67*S,
   -0.43*S,  0.52*S,  0.45*S,  0.50*S, -0.47*S,  1.44*S,  /*0.33*/ 1.00*S,

    // Lévy C Curve
    0.00*S,  0.00*S,  0.00*S,  0.00*S,  0.00*S,  7.50*S,  /*0.00*/ 0.00*S,
    0.00*S,  0.00*S,  0.00*S,  0.00*S,  0.00*S,  7.50*S,  /*0.00*/ 0.00*S,
    0.50*S, -0.50*S,  0.50*S,  0.50*S, -0.14*S,  2.82*S,  /*0.50*/ 0.50*S,
   -0.50*S,  0.50*S,  0.50*S,  0.50*S,  0.14*S,  2.82*S,  /*0.50*/ 1.00*S,

    // Spiral
    0.00*S,  0.00*S,  0.00*S,  0.00*S,  0.00*S,  7.50*S,  /*0.00*/ 0.00*S,
    0.00*S,  0.00*S,  0.00*S,  0.00*S,  0.00*S,  7.50*S,  /*0.00*/ 0.00*S,
    0.89*S, -0.41*S,  0.41*S,  0.89*S,  2.06*S,  0.56*S,  /*0.90*/ 0.90*S,
   -0.16*S,  0.00*S,  0.00*S,  0.16*S,  0.00*S,  8.20*S,  /*0.10*/ 1.00*S
};

wire [7:0] ferncolours [0:3*FERNDEFINITIONCOUNT-1] = '{
    8'h80, 8'hFF, 8'h40, // Barnsley Fern
    8'hFF, 8'hFF, 8'h40, // Sierpiński Triangle
    8'hFF, 8'h40, 8'h40, // Mapel Leaf
    8'h40, 8'hFF, 8'hFF, // Lévy C Curve
    8'hFF, 8'h40, 8'hFF  // Spiral
};
