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
   EJEMPLO 12
   ----------
   
   Este código contiene un ejemplo de uso de los módulos de entrenamiento para FPGA, y
   está escrito para ser incluido dentro de un módulo (ver tld_modulos_entrenamiento_*.v)
   No es por tanto un código Verilog completo.
   
   Dentro de este fichero se pueden definir wire y reg, así como instanciar al módulo
   "display" que es el módulo principal del conjunto de módulos de entrenamiento.
   
   Dentro de este fichero no se pueden definir otros módulos o entidades, ya que este 
   fichero en sí está dentro de un módulo preexistente.

   En el EJEMPLO 11 fuimos capaces de almacenar la historia de los 6 ultimos eventos de teclado, y así
   comprobar la secuencia que generan algunas teclas especiales. Sin embargo, esta historia no está
   completa, ya que la información sobre si la tecla está pulsada o soltada, o si es extendida o normal
   sólo se muestra para el evento más reciente y no para los anteriores.
   
   Para solucionar esto vamos a usar los leds. Tenemos 8 leds y necesitamos 2 para almacenar los flags asociados
   a cada evento de teclado, así que con los que tenemos podemos almacenar los flags de los últimos 4 eventos
   
   Así, el diseño se ha cambiado para que se muestren en pantalla los 4 últimos eventos de teclado, pero esta
   vez completos. De esta forma se puede observar la secuencia completa de teclas como ImprPant.
*/   

  wire evento_teclado;        // conectado a "evento_teclado". Indica cuándo hay una tecla disponible, pulsada o soltada
  wire [7:0] codigo_tecla;    // conectado a la salida "scancode" del módulo display
  wire soltada;               // etc
  wire extendida;             // etc
  reg [3:0] r_soltada;        // En estos registros guardamos la información 
  reg [3:0] r_extendida;      // de la 4 últimas teclas
  reg [7:0] r_codigo[0:3];    // 
  
  always @(posedge clk25m) begin       // en cada ciclo de reloj...
    if (evento_teclado == 1'b1) begin  // ... miramos si evento_teclado vale 1
      r_codigo[3] <= codigo_tecla;
      r_codigo[2] <= r_codigo[3];
      r_codigo[1] <= r_codigo[2];
      r_codigo[0] <= r_codigo[1];
      
      r_soltada[3] <= soltada;       // hacemos con este array lo mismo
      r_soltada[2] <= r_soltada[3];  // que hacemos con r_codigo
      r_soltada[1] <= r_soltada[2];  // para guardar la historia de
      r_soltada[0] <= r_soltada[1];  // el estado pulsado/soltado
      
      r_extendida <= {extendida, r_extendida[3:1]};  // otra forma de hacer lo mismo, pero más compacta
    end
  end

  display pantalla (
  // Los 12 digitos hexadecimales (de izquierda a derecha)
    .d0 (4'd0),
    .d1 (4'd0),
    .d2 (4'd0),
    .d3 (4'd0),
    .d4 (r_codigo[0][7:4]),
    .d5 (r_codigo[0][3:0]),
    .d6 (r_codigo[1][7:4]),
    .d7 (r_codigo[1][3:0]),
    .d8 (r_codigo[2][7:4]),
    .d9 (r_codigo[2][3:0]),
    .d10(r_codigo[3][7:4]),
    .d11(r_codigo[3][3:0]),
  // Los 8 leds (MSb a la izquierda en pantalla)
    .led({r_extendida[0], r_soltada[0], r_extendida[1], r_soltada[1], r_extendida[2], r_soltada[2], r_extendida[3], r_soltada[3]}),
  // Las salidas de los 8 interruptores (F1 es bit 7, F2 es bit 6, ...., F8 es bit 0)
    .switch(),
  // Acceso a la ultima tecla pulsada 
    .evento_teclado(evento_teclado),
    .scancode(codigo_tecla),
    .soltada(soltada),
    .extendida(extendida),  
  // Acceso a la pantalla
    .ri(6'h00),
    .gi(6'h00),
    .bi(6'h00),
    .posx(),
    .posy(),
    .display_activo(),
    
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
