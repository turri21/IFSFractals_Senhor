module Ferns
(
    input  wire clk,
    input  wire reset,
    input  wire [31:0] joystick_0,

    output reg ce_pix,

    output reg HBlank,
    output reg HSync,
    output reg VBlank,
    output reg VSync,

    output reg [7:0] videor,
    output reg [7:0] videog,
    output reg [7:0] videob
);

localparam H_VISIBLE = 640;
localparam H_FP      = 16;
localparam H_SYNC    = 96;
localparam H_BP      = 48;
localparam H_TOTAL   = 800;

localparam V_VISIBLE = 480;
localparam V_FP      = 10;
localparam V_SYNC    = 2;
localparam V_BP      = 33;
localparam V_TOTAL   = 525;

reg [1:0] clockDivider;

(* ramstyle = "no_rw_check" *)
reg [7:0] screen[0:H_VISIBLE*V_VISIBLE-1];

reg [9:0] pixelx;
reg [9:0] pixely;

reg [18:0] readwriteAddress;
reg pendingWriteEnable;
reg writeEnable;
reg [7:0] readValue;

reg [18:0] displayAddress;
reg [7:0] displayValue;
reg [7:0] displayLatch;

always @(posedge clk) begin
    clockDivider <= clockDivider + 1;
    ce_pix <= ~clockDivider[1];
end

always @(posedge clk) begin
    if (clockDivider == 0 && (clearFlag || movingFlag || tween > 0)) screen[displayAddress] <= 0;
    displayValue <= screen[displayAddress];
end
always @(posedge clk) begin
    if (writeEnable && readValue < 255) screen[readwriteAddress] <= shadesFlag ? readValue + 1 : 255;
    readValue <= screen[readwriteAddress];
end
always @(posedge ce_pix) begin
    displayLatch <= displayValue;
end

always @(posedge ce_pix) begin
    if (reset) begin
        pixelx <= 0;
        pixely <= 0;
    end else if (pixelx == H_TOTAL-1) begin
        pixelx <= 0;
        pixely <= (pixely == V_TOTAL-1) ? 0 : pixely + 1;
    end else begin
        pixelx <= pixelx + 1;
    end
end

always @(posedge ce_pix) begin
    if (reset) begin
        displayAddress <= 0;
    end else if (pixelx < H_VISIBLE && pixely < V_VISIBLE) begin
        if (displayAddress == H_VISIBLE*V_VISIBLE-1) begin
            displayAddress <= 0;
        end else begin
            displayAddress <= displayAddress + 1;
        end
    end
end

always @(posedge ce_pix) begin
    HBlank <= (pixelx >= H_VISIBLE);
    VBlank <= (pixely >= V_VISIBLE);
    HSync <= (pixelx >= H_VISIBLE + H_FP && pixelx < H_VISIBLE + H_FP + H_SYNC);
    VSync <= (pixely >= V_VISIBLE + V_FP && pixely < V_VISIBLE + V_FP + V_SYNC);
end

`include "lut.v"

assign videor = HBlank || VBlank ? 0 : (lut[displayLatch < LUTENTRIES ? displayLatch : LUTENTRIES-1] * currentCol[0]) >> 8;
assign videog = HBlank || VBlank ? 0 : (lut[displayLatch < LUTENTRIES ? displayLatch : LUTENTRIES-1] * currentCol[1]) >> 8;
assign videob = HBlank || VBlank ? 0 : (lut[displayLatch < LUTENTRIES ? displayLatch : LUTENTRIES-1] * currentCol[2]) >> 8;

// -------------------------------------------------------------------------

localparam FIXEDBITS = 24;
localparam FIXEDSHIFT = 18;
`include "ferndefinitions.v"

localparam RENDERSHIFT = 8;
localparam MINSCALE = 1 << RENDERSHIFT;
localparam signed [63:0] INITSCALE = (V_VISIBLE/10) << RENDERSHIFT;
localparam signed [63:0] INITOFFSETX = 0;
localparam signed [63:0] INITOFFSETY = (V_VISIBLE/2) << (RENDERSHIFT+FIXEDSHIFT);
localparam signed [63:0] OFFSETSPEED = 8 << (RENDERSHIFT+FIXEDSHIFT);
localparam ZOOMSPEEDSHIFT = 5;
localparam SCREENCENTRE = (H_VISIBLE*V_VISIBLE+H_VISIBLE)>>1;
localparam TWEENBITS = 6;

reg [31:0] oldJoystick_0;
reg [1:0] stage;

reg resetStage;
reg movingFlag;
reg clearFlag;
reg randomFlag;
reg shadesFlag;

reg [7:0] definitionIndex;
reg signed [FIXEDBITS-1:0] current [0:FERNDEFINITIONSIZE-1];
reg signed [FIXEDBITS-1:0] startPos [0:FERNDEFINITIONSIZE-1];
reg signed [FIXEDBITS-1:0] endPos [0:FERNDEFINITIONSIZE-1];
reg [7:0] currentCol [0:2];
reg [7:0] startCol [0:2];
reg [7:0] endCol [0:2];
reg signed [TWEENBITS:0] tween;
reg signed [7:0] tweenStep;

reg signed [FIXEDBITS-1:0] x;
reg signed [FIXEDBITS-1:0] y;
reg [FIXEDBITS-1:0] r;
reg [FIXEDBITS-1:0] p;

reg signed [63:0] pX;
reg signed [63:0] pY;
reg signed [63:0] scale;
reg signed [63:0] offsetX;
reg signed [63:0] offsetY;


function signed [FIXEDBITS-1:0] FixedMultiply (input signed [FIXEDBITS-1:0] a, input signed [FIXEDBITS-1:0] b);
  reg signed [2*FIXEDBITS-1:0] product;
begin
  product = a * b;
  FixedMultiply = product >>> FIXEDSHIFT;
end
endfunction


reg [31:0] rnd;
reg [31:0] seed;
always @(posedge clk) begin
    if (reset) begin
        rnd <= 1;
        seed <= 1;
    end else if (~randomFlag && pixelx == 0 && pixely == 0 && clockDivider == 0) begin
        rnd <= seed;
    end else begin
        rnd = rnd ^ (rnd << 13);
        rnd = rnd ^ (rnd >> 17);
        rnd = rnd ^ (rnd << 5);
        if (randomFlag) seed <= rnd;
    end
end

always @(posedge clk) begin
    if (reset) begin
        stage <= 0;
    end else if (stage == 0 || resetStage) begin
        for (int i = 0; i < FERNDEFINITIONSIZE; ++i) begin
            startPos[i] <= current[i];
            endPos[i] <= ferndefinitions[definitionIndex * FERNDEFINITIONSIZE + i];
        end
        for (int i = 0; i < 3; ++i) begin
            startCol[i] <= currentCol[i];
            endCol[i] <= ferncolours[definitionIndex * 3 + i];
        end
        x <= 0;
        y <= 0;
        stage <= 1;
    end else if (stage == 1) begin
        r <= rnd[FIXEDSHIFT-1:0];
        for (int parameterIndex = 0; parameterIndex < FERNFUNCTIONCOUNT*FERNPARAMETERCOUNT; parameterIndex += FERNPARAMETERCOUNT) begin
            if (r <= current[parameterIndex + 6]) begin
                x <= FixedMultiply(x, current[parameterIndex + 0]) + FixedMultiply(y, current[parameterIndex + 1]) + current[parameterIndex + 4];
                y <= FixedMultiply(x, current[parameterIndex + 2]) + FixedMultiply(y, current[parameterIndex + 3]) + current[parameterIndex + 5];
                break;
            end
        end
        pX <= (offsetX + x * scale) >>> (FIXEDSHIFT+RENDERSHIFT);
        pY <= (offsetY - y * scale) >>> (FIXEDSHIFT+RENDERSHIFT);
        readwriteAddress <= SCREENCENTRE + pY * H_VISIBLE + pX;
        writeEnable <= 0;
        pendingWriteEnable <= pX >= -(H_VISIBLE>>1) && pY >= -(V_VISIBLE>>1) && pX < (H_VISIBLE>>1) && pY < (V_VISIBLE>>1);
        stage <= 2;
    end else if (stage == 2) begin
        writeEnable <= pendingWriteEnable;
        stage <= 1;
    end
end

always @(posedge clk) begin
    if (reset) begin
        offsetX <= INITOFFSETX;
        offsetY <= INITOFFSETY;
        scale <= INITSCALE;
        resetStage <= 0;
        definitionIndex <= 0;
        movingFlag <= 0;
        clearFlag <= 1;
        randomFlag <= 1;
        shadesFlag <= 1;
        tween <= (1<<TWEENBITS)-1;
        tweenStep <= 0;
    end else begin
        if (pixelx == 0 && pixely == 0 && clockDivider == 0) begin
            if (joystick_0[11]) begin
                offsetX <= INITOFFSETX;
                offsetY <= INITOFFSETY;
                scale <= INITSCALE;
                movingFlag <= 1;
            end else begin
                offsetX = offsetX - (joystick_0[0] ? OFFSETSPEED : 0) + (joystick_0[1] ? OFFSETSPEED : 0);
                offsetY = offsetY - (joystick_0[2] ? OFFSETSPEED : 0) + (joystick_0[3] ? OFFSETSPEED : 0);
                offsetX = offsetX + (joystick_0[4] ? (offsetX >>> ZOOMSPEEDSHIFT) : 0) - (joystick_0[5] && scale > MINSCALE ? (offsetX >>> ZOOMSPEEDSHIFT) : 0);
                offsetY = offsetY + (joystick_0[4] ? (offsetY >>> ZOOMSPEEDSHIFT) : 0) - (joystick_0[5] && scale > MINSCALE ? (offsetY >>> ZOOMSPEEDSHIFT) : 0);
                scale <= scale + (joystick_0[4] ? (scale >>> ZOOMSPEEDSHIFT) : 0) - (joystick_0[5] && scale > MINSCALE ? (scale >>> ZOOMSPEEDSHIFT) : 0);
                movingFlag <= joystick_0[5:0] != 0 || tween > 0;
            end
        end
        clearFlag <= clearFlag ^ (joystick_0[6] && !oldJoystick_0[6]);
        randomFlag <= randomFlag ^ (joystick_0[7] && !oldJoystick_0[7]);
        shadesFlag <= shadesFlag ^ (joystick_0[8] && !oldJoystick_0[8]);
        if ((joystick_0[9] && !oldJoystick_0[9] && definitionIndex != FERNDEFINITIONCOUNT-1) || (joystick_0[10] && !oldJoystick_0[10] && definitionIndex != 0)) begin
            if (joystick_0[9] && !oldJoystick_0[9] && definitionIndex != FERNDEFINITIONCOUNT-1) begin
                definitionIndex <= definitionIndex + 1;
            end else begin
                definitionIndex <= definitionIndex - 1;
            end
            tween <= (1<<TWEENBITS)-1;
            tweenStep <= -3;
        end else if (!resetStage) begin
            if (pixelx == 0 && pixely == 0 && clockDivider == 0) begin
                tween <= (tween > 0) ? tween - 1 : 0;
            end
            if (tweenStep < 0) begin
                currentCol[tweenStep+3] <= endCol[tweenStep+3] + FixedMultiply(startCol[tweenStep+3] - endCol[tweenStep+3], tween << (FIXEDSHIFT-TWEENBITS));
            end else begin
                current[tweenStep] <= endPos[tweenStep] + FixedMultiply(startPos[tweenStep] - endPos[tweenStep], tween << (FIXEDSHIFT-TWEENBITS));
            end
            tweenStep <= (tweenStep == FERNDEFINITIONSIZE-1) ? -3 : tweenStep + 1;
        end
        resetStage <= (joystick_0[9] && !oldJoystick_0[9] && definitionIndex != FERNDEFINITIONCOUNT-1) || (joystick_0[10] && !oldJoystick_0[10] && definitionIndex != 0);

        oldJoystick_0 <= joystick_0;
    end
end

endmodule
