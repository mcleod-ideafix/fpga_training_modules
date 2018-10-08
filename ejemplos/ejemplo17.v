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

/*
   EJEMPLO 17
   ----------
   
   Este código contiene un ejemplo de uso de los módulos de entrenamiento para FPGA, y
   está escrito para ser incluido dentro de un módulo (ver tld_modulos_entrenamiento_*.v)
   No es por tanto un código Verilog completo.
   
   Dentro de este fichero se pueden definir wire y reg, así como instanciar al módulo
   "display" que es el módulo principal del conjunto de módulos de entrenamiento.
   
   Dentro de este fichero no se pueden definir otros módulos o entidades, ya que este 
   fichero en sí está dentro de un módulo preexistente.
   
   En este ejemplo usamos posx y posy para pintar una rejilla y una cruz controlada
   por el usuario con las teclas del cursor.
   Son dos gráficos independientes (dos planos). 
   La rejilla se pinta cuando las coordenadas de pantalla (posx,posy) 
   cumplen alguna de estas condiciones:
   - Que estemos pintando la primera linea (posy == 10'd0), o bien
   - que estemos pintando la última linea (posy == 10'd479), o bien
   - que estemos pintando la primera columna (posx == 10'd0), o bien
   - que estemos pintando la última columna (posx == 10'd639), o bien
   - que el valor de posx sea múltiplo de 32 (posx[4:0] == 5'd0), o bien
   - que el valor de posy sea múltiplo de 32 (posy[4:0] == 5'd0)
   La cruz se pinta cuando posx,posy cumplen alguna de estas condiciones:
   - Que posx sea igual a la coordenada X del centro de la cruz (cruz_x), o bien
   - que posy sea igual a la coordenada Y del centro de la cruz (cruz_y)
   
   Por otra parte, las coordenadas de la cruz (cruz_x, cruz_y) se controlan
   mediante el teclado, con las teclas del cursor.
*/   
  
  localparam COLOR_REJILLA = {6'h00, 6'h3F, 6'h00};   // verde
  localparam COLOR_CRUZ    = {6'h3F, 6'h3F, 6'h3F};   // blanco
  localparam COLOR_NEGRO   = {6'h00, 6'h00, 6'h00};   // pues eso, el negro
  
  localparam CURSOR_ARRIBA = 8'h75;  //
  localparam CURSOR_ABAJO  = 8'h72;  // scancodes de las teclas del cursor.
  localparam CURSOR_IZQDA  = 8'h6B;  // Todas estas teclas son extendidas.
  localparam CURSOR_DRCHA  = 8'h74;  //

  reg [5:0] rojo, verde, azul;
  wire [10:0] posx, posy;
  wire display_activo;
  
  reg [10:0] cruz_x = 10'd320;  // Registros que guardan la 
  reg [10:0] cruz_y = 10'd240;  // posición de la cruceta
  wire evento_teclado;
  wire [7:0] codigo_tecla;
  wire soltada, extendida;
  
  always @(posedge clk25m) begin
    if (evento_teclado == 1'b1 && soltada == 1'b0 && extendida == 1'b1) begin  // si se ha pulsado una tecla extendida...
      case (codigo_tecla)                                                      // miramos a ver qué tecla es...
        CURSOR_ARRIBA: if (cruz_y != 10'd0) cruz_y <= cruz_y - 10'd1;          // 
        CURSOR_ABAJO:  if (cruz_y != 10'd479) cruz_y <= cruz_y + 10'd1;        // Y según qué tecla sea, se actualiza
        CURSOR_IZQDA:  if (cruz_x != 10'd0) cruz_x <= cruz_x - 10'd1;          // cruz_x o cruz_y
        CURSOR_DRCHA:  if (cruz_x != 10'd639) cruz_x <= cruz_x + 10'd1;        // 
      endcase
    end
  end
  
  always @* begin
    if (display_activo == 1'b1) begin
      if (posx == cruz_x || posy == cruz_y)  // alguna de estas dos condiciones ha de cumplirse para pintar la cruz
        {rojo,verde,azul} = COLOR_CRUZ;
      else if 
        (posy == 10'd0 ||             //
         posy == 10'd479 ||           // Alguna de estas condiciones ha de
         posx == 10'd0 ||             // cumplirse para que se pinte
         posx == 10'd639 ||           // la rejilla en pantalla
         posx[4:0] == 5'd0 ||         //
         posy[4:0] == 5'd0)           //
          {rojo,verde,azul} = COLOR_REJILLA;
      else
        {rojo,verde,azul} = COLOR_NEGRO;
    end
    else
      {rojo,verde,azul} = COLOR_NEGRO;      
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
    .evento_teclado(evento_teclado),
    .scancode(codigo_tecla),
    .soltada(soltada),
    .extendida(extendida),
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
