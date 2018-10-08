/*
 * This file is part of "Modulos de entrenamiento para FPGAs"
 * Copyright (c) 2018 Miguel Angel Rodriguez Jodar (integration with module framework).
             (c)      Juan Manuel Rico
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

/*
   EJEMPLO 99
   ----------
   
   Este código contiene un ejemplo de uso de los módulos de entrenamiento para FPGA, y
   está escrito para ser incluido dentro de un módulo (ver tld_modulos_entrenamiento_*.v)
   No es por tanto un código Verilog completo.
   
   Dentro de este fichero se pueden definir wire y reg, así como instanciar al módulo
   "display" que es el módulo principal del conjunto de módulos de entrenamiento.
   
   Dentro de este fichero no se pueden definir otros módulos o entidades, ya que este 
   fichero en sí está dentro de un módulo preexistente.

   No soy el autor de este ejemplo en concreto. El código es de Juan Manuel Rico.
   Más información en https://github.com/gundy/tinyfpga-bx-demos/tree/develop/examples/rotozoomer1
*/   

  reg [5:0] rojo, verde, azul;
  wire [10:0] posx, posy;
  wire display_activo;
  
  reg [8:0] angle;   /* angle that image is rotated (0..255) */
  reg signed [15:0] scale;   /* scale to draw at */

  localparam ROTATE_CENTRE_X = 320;
  localparam ROTATE_CENTRE_Y = 240;

  reg signed [15:0] unscaled_u_stride;
  reg signed [15:0] unscaled_v_stride;

  reg signed [32:0] u_stride;
  reg signed [32:0] v_stride;

  // todo check widths etc
  reg signed [32:0] u_offset;
  reg signed [32:0] v_offset;

  // start positions for u&v at the beginning of each line
  reg signed [16:0] u_start;
  reg signed [16:0] v_start;

  // current positions for u&v (fixed point 1.16 indexes into the texture space)
  reg signed [16:0] u;
  reg signed [16:0] v;

  reg signed[15:0] SINE_TABLE_ROM[0:255];
  initial $readmemh ("tabla_senos.hex", SINE_TABLE_ROM);
  always @(posedge clk25m) begin
    unscaled_v_stride <= SINE_TABLE_ROM[angle[7:0]];
    unscaled_u_stride <= SINE_TABLE_ROM[angle[7:0]+64];
    scale             <= SINE_TABLE_ROM[angle[8:1]];
  end

  reg [17:0] textura[0:16383];
  reg [17:0] pixel;
  initial $readmemh ("bart.hex", textura);
  always @(posedge clk25m) begin
    pixel <= textura[{v[16:10],~u[16:10]}];
  end

  always @(posedge clk25m)
  begin
    if (posx == 11'd0 && posy == 11'd480) begin
      // una vez en cada frame (por ejemplo, cuando se ha terminado de pintar el frame actual
      // actualizamos algunos valores que sólo hay que actualizar una vez por frame
      angle <= angle + 1;   // como por ejemplo, el angulo de giro
      u_stride <= (scale * unscaled_u_stride) >>> (16+5);  // actualizmos el valor del escalon en X e Y.
      v_stride <= (scale * unscaled_v_stride) >>> (16+5);  // 16 to account for scale, 5 to make textures bigger
      u_offset <= (ROTATE_CENTRE_X * unscaled_u_stride) >>> (16+5);
      v_offset <= (ROTATE_CENTRE_Y * unscaled_v_stride) >>> (16+5);
      u_start <= -u_offset[16:0];
      v_start <= v_offset[16:0];
    end
    if (display_activo) begin
      if (posx == 0) begin
        u_start <= u_start + v_stride[16:0];
        v_start <= v_start - u_stride[16:0];
        u <= u_start;
        v <= v_start;
      end else begin
        u <= u + u_stride[16:0];
        v <= v + v_stride[16:0];
        //if (u[16] == v[16])
        rojo <= pixel[17:12];
        verde <= pixel[11:6];
        azul <= pixel[5:0];
      end
    end else begin
      azul <= 6'h00;
      verde <= 6'h00;
      rojo <= 6'h00;
    end
  end

  display #(.YINIT(480)) pantalla (  // la Y inicial la ponemos a un valor más allá del limite (479) para esconder el display
  // Los 12 digitos hexadecimales (de izquierda a derecha)
    .d0(4'h0),
    .d1(4'h0),
    .d2(4'h0),
    .d3(4'h0),
    .d4(4'h0),
    .d5(4'h0),
    .d6(4'h0),
    .d7(4'h0),
    .d8(4'h0),
    .d9(4'h0),
    .d10(4'h0),
    .d11(4'h00),
  // Los 8 leds (MSb a la izquierda en pantalla)
    .led(8'b00000000),  // led 1 indica si tecla extendida (ON) o normal (OFF). Led 0 indica si pulsada (OFF) o soltada (ON)
  // Las salidas de los 8 interruptores (F1 es bit 7, F2 es bit 6, ...., F8 es bit 0)
    .switch(),
  // Acceso a la ultima tecla pulsada 
    .evento_teclado(),
    .scancode(),
    .soltada(),
    .extendida(),
  // Acceso a la pantalla
    .ri(rojo),
    .gi(verde),
    .bi(azul),
    .posx(posx),
    .posy(posy),
    .display_activo(display_activo),
    
  /////////////////////////////////////////////////////////////////////////  
  // Interfaz externa. No debería tener que tocarse nada de lo que hay aquí.
    .clk(clk25m),
    .clkps2(clkps2),
    .dataps2(dataps2),
    .r(r),
    .g(g),
    .b(b),
    .hs(hsync),
    .vs(vsync)
    );
