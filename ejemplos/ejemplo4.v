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
   EJEMPLO 4
   ---------
   
   Este código contiene un ejemplo de uso de los módulos de entrenamiento para FPGA, y
   está escrito para ser incluido dentro de un módulo (ver tld_modulos_entrenamiento_*.v)
   No es por tanto un código Verilog completo.
   
   Dentro de este fichero se pueden definir wire y reg, así como instanciar al módulo
   "display" que es el módulo principal del conjunto de módulos de entrenamiento.
   
   Dentro de este fichero no se pueden definir otros módulos o entidades, ya que este 
   fichero en sí está dentro de un módulo preexistente.

   En este ejemplo vemos una variación del EJEMPLO 3. Aquí, en lugar de invertir el valor de un
   bit en un flipflop, lo que hacemos es rotar el contenido de un registro de 8 bits a la derecha.
   El registro inicialmente tiene el valor 10000000. Al rotarse, este registro irá tomando los valores
   01000000, 00100000, 00010000, 00001000, 00000100, 00000010, 000000001, y de nuevo 10000000.
   Al mostrarse en los leds, el efecto es el de una luz moviéndose de izquierda a derecha y vuelta
   a empezar
*/   

  reg [7:0] leds = 8'b10000000;   
  reg [23:0] contador = 24'd0;  // contador que cuenta de 0 hasta 12500000 (medio segundo, a 25 MHz)

  always @(posedge clk25m) begin   // en cada ciclo de reloj del reloj de 25 MHz hacemos lo siguiente:
    if (contador == 24'd12500000) begin  // si hemos llegado a medio segundo de tiempo...
      contador <= 24'd0;                 //    ponemos el contador a 0, e
      leds <= {leds[0], leds[7:1]};      // Rotamos el valor de leds un bit a la derecha (bit 7 al 6, 6 al 5, etc. El bit 0 pasa al bit 7.
    end
    else                                 // en otro caso
      contador <= contador + 24'd1;      //    incrementamos el contador
  end
  
  display pantalla (
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
    .d11(4'h0),
  // Los 8 leds (MSb a la izquierda en pantalla)
    .led(leds),    
  // Las salidas de los 8 interruptores (F1 es bit 7, F2 es bit 6, ...., F8 es bit 0)
    .switch(),
  // Acceso a la ultima tecla pulsada 
    .evento_teclado(),
    .scancode(),
    .soltada(),
    .extendida(),  
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
