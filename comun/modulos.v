/*
 * This file is part of "Modulos de entrenamiento para FPGAs"
 * Copyright (c) 2018 Miguel Angel Rodriguez Jodar.
 * 
 * This program is free software: you can redistribute it and/or modify  
 * it under the terms of the GNU General Public License as published by  
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but 
 * WITHOUT ANY WARRANTY; without even the implied warranty of 
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License 
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

`timescale 1ns / 1ns
`default_nettype none

module display (
  input wire clk,

  // Display hexadecimal de 12 digitos
  input wire [3:0] d0,
  input wire [3:0] d1,
  input wire [3:0] d2,
  input wire [3:0] d3,

  input wire [3:0] d4,
  input wire [3:0] d5,
  input wire [3:0] d6,
  input wire [3:0] d7,

  input wire [3:0] d8,
  input wire [3:0] d9,
  input wire [3:0] d10,
  input wire [3:0] d11,

  // 8 LEDs
  input wire [7:0] led,
  
  // 8 switches
  output wire [7:0] switch,
  
  // Acceso a la ultima tecla pulsada
  output wire evento_teclado,
  output wire [7:0] scancode,
  output wire soltada,
  output wire extendida,
  
  // Acceso a la pantalla
  input wire [5:0] ri,
  input wire [5:0] gi,
  input wire [5:0] bi,
  output wire [10:0] posx,
  output wire [10:0] posy,
  output wire display_activo,  
    
  // Interface teclado
  input wire clkps2,
  input wire dataps2,
  
  // Interface VGA
  output wire [5:0] r,
  output wire [5:0] g,
  output wire [5:0] b,
  output wire hs,
  output wire vs
  );
  
  parameter YINIT = 392;
  parameter FONTFILE = "fuente_hexadecimal_ibm.hex";
  
  wire [10:0] hc, vc;
  wire den;
  
  wire [5:0] rdigits, gdigits, bdigits;
  wire [5:0] rleds, gleds, bleds;
  wire [5:0] rswitch, gswitch, bswitch;
  
  ps2_port el_teclado (
    .clk(clk),  // se recomienda 1 MHz <= clk <= 600 MHz
    .enable_rcv(1'b1),  // habilitar la maquina de estados de recepcion
    .kb_or_mouse(1'b0),
    .ps2clk_ext(clkps2),
    .ps2data_ext(dataps2),
    .kb_interrupt(evento_teclado),  // a 1 durante 1 clk para indicar nueva tecla recibida
    .scancode(scancode), // make o breakcode de la tecla
    .released(soltada),  // soltada=1, pulsada=0
    .extended(extendida)  // extendida=1, no extendida=0
  );  
  
  videosyncs sincronismos (
    .clk(clk),
    .hs(hs),
    .vs(vs),
 	  .hc(hc),
	  .vc(vc),
    .display_enable(den)
    );
    
  switches #(.YINIT(YINIT)) los_interruptores (
    .clk(clk),
    .evento_teclado(evento_teclado),
    .scancode(scancode),
    .extended(extendida),
    .released(soltada),
    .switch(switch),
    .hc(hc),
    .vc(vc),
    .r(rswitch),
    .g(gswitch),
    .b(bswitch)
    );

  leds #(.YINIT(YINIT+32)) display_leds (
    .led(led),
    .hc(hc),
    .vc(vc),
    .r(rleds),
    .g(gleds),
    .b(bleds)
    );
    
  digits #(.YINIT(YINIT+56), .FONTFILE(FONTFILE)) display_digitos (
    .clk(clk),
    .d0(d0),
    .d1(d1),
    .d2(d2),
    .d3(d3),
    .d4(d4),
    .d5(d5),
    .d6(d6),
    .d7(d7),
    .d8(d8),
    .d9(d9),
    .d10(d10),
    .d11(d11),
    .hc(hc),
    .vc(vc),
    .r(rdigits),
    .g(gdigits),
    .b(bdigits)
    );

  // Los valores RGB combinados de los tres módulos    
  wire [5:0] ro = rdigits | rleds | rswitch;
  wire [5:0] go = gdigits | gleds | gswitch;
  wire [5:0] bo = bdigits | bleds | bswitch;
  
  wire es_negro = ({ro,go,bo} == 18'h00000);
  
  // Si hay algo que mostrar del módulo, éste tiene prioridad. Si no, se muestra lo que haya
  // en ri,gi,bi por parte del usuario. Si la señal den vale 0, entonces no se pinta nada.
  assign r = (den == 1'b1)? ((es_negro)? ri : ro) : 6'h00;
  assign g = (den == 1'b1)? ((es_negro)? gi : go) : 6'h00;
  assign b = (den == 1'b1)? ((es_negro)? bi : bo) : 6'h00;

  assign posx = hc;
  assign posy = vc;
  assign display_activo = den;

endmodule

//////////////////////////////////////////////////////////////

module videosyncs (
  input wire clk,        // reloj de 25 MHz (mirar abajo en el "ModeLine")
  output reg hs,         // salida sincronismo horizontal
  output reg vs,         // salida sincronismo vertical
 	output wire [10:0] hc, // salida posicion X actual de pantalla
	output wire [10:0] vc, // salida posicion Y actual de pantalla
  output reg display_enable // hay que poner un color en pantalla (1) o hay que poner negro (0)
  );
	
  // Visita esta URL si pretendes cambiar estos valores para generar otro modo de pantalla. Atrevete!!!
  // https://www.mythtv.org/wiki/Modeline_Database#VESA_ModePool
  // El que he usado aqui es:
  // ModeLine "640x480" 25.18 640 656 752 800 480 490 492 525 -HSync -VSync
  //                      ^
  //                      +---- Frecuencia de reloj de pixel en MHz
  parameter HACTIVE = 640;
  parameter HFRONTPORCH = 656;
  parameter HSYNCPULSE = 752;
	parameter HTOTAL = 800;
  parameter VACTIVE = 480;
  parameter VFRONTPORCH = 490;
  parameter VSYNCPULSE = 492;
  parameter VTOTAL = 525;
  parameter HSYNCPOL = 0;  // 0 = polaridad negativa, 1 = polaridad positiva
  parameter VSYNCPOL = 0;  // 0 = polaridad negativa, 1 = polaridad positiva

  reg [10:0] hcont = 0;
  reg [10:0] vcont = 0;
	
  assign hc = hcont;
  assign vc = vcont;

  always @(posedge clk) begin
      if (hcont == HTOTAL-1) begin
         hcont <= 11'd0;
         if (vcont == VTOTAL-1) begin
            vcont <= 11'd0;
         end
         else begin
            vcont <= vcont + 11'd1;
         end
      end
      else begin
         hcont <= hcont + 11'd1;
      end
  end
   
  always @* begin
    if (hcont>=0 && hcont<HACTIVE && vcont>=0 && vcont<VACTIVE)
      display_enable = 1'b1;
    else
      display_enable = 1'b0;

    if (hcont>=HFRONTPORCH && hcont<HSYNCPULSE)
      hs = HSYNCPOL;
    else
      hs = ~HSYNCPOL;

    if (vcont>=VFRONTPORCH && vcont<VSYNCPULSE)
      vs = VSYNCPOL;
    else
      vs = ~VSYNCPOL;
  end
endmodule   

//////////////////////////////////////////////////////////////

module ps2_port (
    input wire clk,  // se recomienda 1 MHz <= clk <= 600 MHz
    input wire enable_rcv,  // habilitar la maquina de estados de recepcion
    input wire kb_or_mouse,  // 0: kb, 1: mouse
    input wire ps2clk_ext,
    input wire ps2data_ext,
    output wire kb_interrupt,  // a 1 durante 1 clk para indicar nueva tecla recibida
    output reg [7:0] scancode, // make o breakcode de la tecla
    output wire released,  // soltada=1, pulsada=0
    output wire extended  // extendida=1, no extendida=0
    );
    
    `define RCVSTART    2'b00
    `define RCVDATA     2'b01 
    `define RCVPARITY   2'b10
    `define RCVSTOP     2'b11

    reg [7:0] key = 8'h00;

    // Fase de sincronizacion de se�ales externas con el reloj del sistema
    reg [1:0] ps2clk_synchr;
    reg [1:0] ps2dat_synchr;
    wire ps2clk = ps2clk_synchr[1];
    wire ps2data = ps2dat_synchr[1];
    always @(posedge clk) begin
        ps2clk_synchr[0] <= ps2clk_ext;
        ps2clk_synchr[1] <= ps2clk_synchr[0];
        ps2dat_synchr[0] <= ps2data_ext;
        ps2dat_synchr[1] <= ps2dat_synchr[0];
    end

    // De-glitcher. S�lo detecto flanco de bajada
    reg [15:0] negedgedetect = 16'h0000;
    always @(posedge clk) begin
        negedgedetect <= {negedgedetect[14:0], ps2clk};
    end
    wire ps2clkedge = (negedgedetect == 16'hF000)? 1'b1 : 1'b0;
    
    // Paridad instant�nea de los bits recibidos
    wire paritycalculated = ^key;
    
    // Contador de time-out. Al llegar a 65536 ciclos sin que ocurra
    // un flanco de bajada en PS2CLK, volvemos al estado inicial
    reg [15:0] timeoutcnt = 16'h0000;

    reg [1:0] state = `RCVSTART;
    reg [1:0] regextended = 2'b00;
    reg [1:0] regreleased = 2'b00;
    reg rkb_interrupt = 1'b0;
    assign released = regreleased[1];
    assign extended = regextended[1];
    assign kb_interrupt = rkb_interrupt;
    
    always @(posedge clk) begin
        if (rkb_interrupt == 1'b1) begin
            rkb_interrupt <= 1'b0;
        end
        if (ps2clkedge && enable_rcv) begin
            timeoutcnt <= 16'h0000;
            case (state)
                `RCVSTART: begin
                    if (ps2data == 1'b0) begin
                        state <= `RCVDATA;
                        key <= 8'h80;
                    end
                end
                `RCVDATA: begin
                    key <= {ps2data, key[7:1]};
                    if (key[0] == 1'b1) begin
                        state <= `RCVPARITY;
                    end
                end
                `RCVPARITY: begin
                    if (ps2data^paritycalculated == 1'b1) begin
                        state <= `RCVSTOP;
                    end
                    else begin
                        state <= `RCVSTART;
                    end
                end
                `RCVSTOP: begin
                    state <= `RCVSTART;                
                    if (ps2data == 1'b1) begin                        
                        scancode <= key;
                        if (kb_or_mouse == 1'b1) begin
                            rkb_interrupt <= 1'b1;  // no se requiere mirar E0 o F0
                        end
                        else begin
                            if (key == 8'hE0) begin
                                regextended <= 2'b01;
                            end
                            else if (key == 8'hF0) begin
                                regreleased <= 2'b01;
                            end
                            else begin
                                regextended <= {regextended[0], 1'b0};
                                regreleased <= {regreleased[0], 1'b0};
                                rkb_interrupt <= 1'b1;
                            end
                        end
                    end
                end    
                default: state <= `RCVSTART;
            endcase
        end           
        else begin
            timeoutcnt <= timeoutcnt + 1;
            if (timeoutcnt == 16'hFFFF) begin
                state <= `RCVSTART;
            end
        end
    end
endmodule

//////////////////////////////////////////////////////////////

module digits (
  input wire clk,

  // Digitos
  input wire [3:0] d0,
  input wire [3:0] d1,
  input wire [3:0] d2,
  input wire [3:0] d3,

  input wire [3:0] d4,
  input wire [3:0] d5,
  input wire [3:0] d6,
  input wire [3:0] d7,

  input wire [3:0] d8,
  input wire [3:0] d9,
  input wire [3:0] d10,
  input wire [3:0] d11,

  // Interface VGA
  input wire [10:0] hc,
  input wire [10:0] vc,
  output reg [5:0] r,
  output reg [5:0] g,
  output reg [5:0] b
  );
  
  parameter YINIT = 448;                  // multiplo de 16!
  parameter FONTFILE = "fuente_hexadecimal_ibm.hex";

  localparam ANCHO = (12 + 4)*8*2;       // 12 digitos en tres grupos de cuatro hacen 4 espacios de separacion en total. 8 pixeles por scan, 2 veces de ancho
  localparam XINIT = (640 - ANCHO) / 2;  // que sea multiplo de 16!!!
  localparam XFIN  = XINIT + ANCHO - 1;
  localparam YFIN  = YINIT + 15;
  localparam COLOR_TEXTO = {6'h00, 6'h2F, 6'h00};
  
  reg [7:0] chars[0:127];
  initial begin
    $readmemh (FONTFILE, chars);
  end
  
  reg [3:0] posicion_caracter_en_pantalla;
  reg pintando_texto;
  always @* begin
    if (vc >= YINIT && vc <= YFIN && hc >= (XINIT - 1) && hc <= (XFIN - 1))
      pintando_texto = 1'b1;
    else
      pintando_texto = 1'b0;
    posicion_caracter_en_pantalla = (hc - XINIT + 1)>>4;
  end    
  
  reg [7:0] scan_actual;
  wire [7:0] posx = hc - XINIT;  // posicion del haz de electrones relativa al comienzo del cuadro de interruptores
  wire [7:0] posy = vc - YINIT;  // lo mismo pero para las lineas (coordenada Y)

  reg [7:0] charaddr;
  always @* begin
    if (pintando_texto == 1'b1 && posx[3:0] == 4'b1111) begin // a punto de comenzar un nuevo caracter...
      case (posicion_caracter_en_pantalla)
        4'd0:  charaddr = 8'h80;  // espacio en blanco
        4'd1:  charaddr = {1'b0, d0,  posy[3:1]};
        4'd2:  charaddr = {1'b0, d1,  posy[3:1]};
        4'd3:  charaddr = {1'b0, d2,  posy[3:1]};
        4'd4:  charaddr = {1'b0, d3,  posy[3:1]};
        4'd5:  charaddr = 8'h80;  // espacio en blanco
        4'd6:  charaddr = {1'b0, d4,  posy[3:1]};
        4'd7:  charaddr = {1'b0, d5,  posy[3:1]};
        4'd8:  charaddr = {1'b0, d6,  posy[3:1]};
        4'd9:  charaddr = {1'b0, d7,  posy[3:1]};
        4'd10: charaddr = 8'h80;  // espacio en blanco
        4'd11: charaddr = {1'b0, d8,  posy[3:1]};
        4'd12: charaddr = {1'b0, d9,  posy[3:1]};
        4'd13: charaddr = {1'b0, d10, posy[3:1]};
        4'd14: charaddr = {1'b0, d11, posy[3:1]};
        4'd15: charaddr = 8'h80;  // espacio en blanco
        default : charaddr = 8'h80;  // para evitar que se infiera un CKE en este registro
      endcase
    end
    else
      charaddr = 8'h80;
  end

  always @(posedge clk) begin
    if (pintando_texto == 1'b1 && posx[3:0] == 4'b1111) begin // a punto de comenzar un nuevo caracter...
      if (charaddr[7] == 1'b0)
        scan_actual <= chars[charaddr];
      else
        scan_actual <= 8'h00;
    end
    else if (hc[0] == 1'b1)
      scan_actual <= {scan_actual[6:0],1'b0};
  end

//  always @(posedge clk) begin
//    if (pintando_texto == 1'b1 && posx[3:0] == 4'b1111) begin // a punto de comenzar un nuevo caracter...
//      case (posicion_caracter_en_pantalla)
//        4'd0:  scan_actual <= 8'h00;  // espacio en blanco
//        4'd1:  scan_actual <= chars[{d0, posy[3:1]}];
//        4'd2:  scan_actual <= chars[{d1, posy[3:1]}];
//        4'd3:  scan_actual <= chars[{d2, posy[3:1]}];
//        4'd4:  scan_actual <= chars[{d3, posy[3:1]}];
//        4'd5:  scan_actual <= 8'h00;  // espacio en blanco
//        4'd6:  scan_actual <= chars[{d4, posy[3:1]}];
//        4'd7:  scan_actual <= chars[{d5, posy[3:1]}];
//        4'd8:  scan_actual <= chars[{d6, posy[3:1]}];
//        4'd9:  scan_actual <= chars[{d7, posy[3:1]}];
//        4'd10: scan_actual <= 8'h00;  // espacio en blanco
//        4'd11: scan_actual <= chars[{d8, posy[3:1]}];
//        4'd12: scan_actual <= chars[{d9, posy[3:1]}];
//        4'd13: scan_actual <= chars[{d10,posy[3:1]}];
//        4'd14: scan_actual <= chars[{d11,posy[3:1]}];
//        4'd15: scan_actual <= 8'h00;  // espacio en blanco
//        default : scan_actual <= 8'h00;  // para evitar que se infiera un CKE en este registro
//      endcase
//    end
//      else if (hc[0] == 1'b1) begin
//        scan_actual <= {scan_actual[6:0],1'b0};
//    end
//  end
          
  always @* begin
    if (scan_actual[7] == 1'b1)
      {r,g,b} = COLOR_TEXTO;
    else
      {r,g,b} = 18'h00000;
  end  
endmodule

//////////////////////////////////////////////////////////////

module leds (
  // 8 leds
  input wire [7:0] led,

  // Interface VGA
  input wire [10:0] hc,
  input wire [10:0] vc,
  output reg [5:0] r,
  output reg [5:0] g,
  output reg [5:0] b
  );
  
  parameter YINIT = 424;
  
  localparam COLOR_LED_ON  = {6'h3F, 6'h3F, 6'h1F};
  localparam COLOR_LED_OFF = {6'h10, 6'h00, 6'h00};
  
  localparam ANCHO = 8*16 + 7*16;  // 8 cuadros de 16x4 + 7 separaciones de 16x4
  localparam XINIT = (640 - ANCHO) / 2;  // que sea multiplo de 8!!!
  localparam XFIN  = XINIT + ANCHO - 1;
  localparam YFIN  = YINIT + 5;
  
  wire [7:0] pos = hc - XINIT;  // posicion de pixel relativa al comienzo de esta sección
  always @* begin
    if (hc >= XINIT && hc <= XFIN && vc >= YINIT && vc <= YFIN) begin
      if (pos[4] == 1'b0)
        if (led[~pos[7:5]] == 1'b1)
          {r,g,b} = COLOR_LED_ON;
        else
          {r,g,b} = COLOR_LED_OFF;
      else
        {r,g,b} = 18'h00000;
    end
    else
      {r,g,b} = 18'h00000;
  end
endmodule

//////////////////////////////////////////////////////////////

module switches (
  input wire clk,
  input wire evento_teclado,
  input wire [7:0] scancode,
  input wire extended,
  input wire released,

  // Estado de los switches
  output reg [7:0] switch,

  // Interface VGA
  input wire [10:0] hc,
  input wire [10:0] vc,
  output reg [5:0] r,
  output reg [5:0] g,
  output reg [5:0] b
  );
  
  parameter YINIT = 392;
  
  localparam ANCHO = 8*8 + 7*24;  // 8 cuadros de 8x24 + 7 separaciones de 16x24
  localparam XINIT = (640 - ANCHO) / 2;
  localparam XFIN  = XINIT + ANCHO - 1;
  localparam YFIN  = YINIT + 15;
  
  localparam COLOR_CONTORNO   = {6'h3F, 6'h3F, 6'h3F};
  localparam COLOR_SW_ON      = {6'h20, 6'h20, 6'h20};
  localparam COLOR_SW_OFF     = {6'h00, 6'h00, 6'h20};
  
  initial begin
    switch[0] = 1'b0;
    switch[1] = 1'b0;
    switch[2] = 1'b0;
    switch[3] = 1'b0;
    switch[4] = 1'b0;
    switch[5] = 1'b0;
    switch[6] = 1'b0;
    switch[7] = 1'b0;
  end
  
  always @(posedge clk) begin
    if (evento_teclado == 1'b1 && released == 1'b0 && extended == 1'b0) begin
      case (scancode)
        8'h05: switch[7] <= ~switch[7];  // F1
        8'h06: switch[6] <= ~switch[6];  // F2
        8'h04: switch[5] <= ~switch[5];  // F3
        8'h0C: switch[4] <= ~switch[4];  // F4
        8'h03: switch[3] <= ~switch[3];  // F5
        8'h0B: switch[2] <= ~switch[2];  // F6
        8'h83: switch[1] <= ~switch[1];  // F7
        8'h0A: switch[0] <= ~switch[0];  // F8
      endcase
    end
  end

  wire [7:0] posx = hc - XINIT;  // posicion del haz de electrones relativa al comienzo del cuadro de interruptores
  wire [7:0] posy = vc - YINIT;  // lo mismo pero para las lineas (coordenada Y)
  always @* begin
    {r,g,b} = 18'h00000;
    if (hc >= XINIT && hc <= XFIN && vc >= YINIT && vc <= YFIN) begin
      if (posx[4:3] == 2'b00) begin  // columnas donde se pinta el switch
        if (vc == YINIT || vc == YFIN || posx[2:0] == 3'b000 || posx[2:0] == 3'b111) // si es el contorno del switch...
          {r,g,b} = COLOR_CONTORNO;  // pinta contorno de blanco
        else if (posy[3] == 1'b0) begin   // si es la mitad superior del switch
          if (switch[~posx[7:5]] == 1'b1)
            {r,g,b} = COLOR_SW_ON;
          else
            {r,g,b} = COLOR_SW_OFF;
        end
        else begin
          if (switch[~posx[7:5]] == 1'b0)  // en la mitad inferior, invertimos los papeles
            {r,g,b} = COLOR_SW_ON;
          else
            {r,g,b} = COLOR_SW_OFF;
        end
      end
    end
  end
  
endmodule  

`default_nettype wire
