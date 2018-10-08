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
   EJEMPLO 1
   ---------
   
   Este código contiene un ejemplo de uso de los módulos de entrenamiento para FPGA, y
   está escrito para ser incluido dentro de un módulo (ver tld_modulos_entrenamiento_*.v)
   No es por tanto un código Verilog completo.
   
   Dentro de este fichero se pueden definir wire y reg, así como instanciar al módulo
   "display" que es el módulo principal del conjunto de módulos de entrenamiento.
   
   Dentro de este fichero no se pueden definir otros módulos o entidades, ya que este 
   fichero en sí está dentro de un módulo preexistente.
   
   Este ejemplo es el más simple de todos. Simplemente instancia el módulo display en su
   ubicación por defecto (a partir de la linea 392 en pantalla, contando con que la linea 0
   está en la parte superior, y que hay 480 lineas, de la 0 a la 479)
   y da algunos valores fijos a las señales de entrada. En concreto:
   - Fija los 12 dígitos con los valores 0123456789AF
   - Fija los 8 leds con esta secuencia binaria: 10101010
   - Fija el color de todos los píxeles de la pantalla con el mismo color: 0,0,63 (azul)
   Este ejemplo no usa ninguna de las salidas que ofrece el módulo
   Una vez enviado a la FPGA, es posible actuar sobre los 8 interruptores usando las 
   teclas de función F1 a F8. El estado del interruptor se verá en pantalla.
*/   

  display pantalla (
  // Los 12 digitos hexadecimales (de izquierda a derecha)
    .d0(4'h0),
    .d1(4'h1),
    .d2(4'h2),
    .d3(4'h3),
    .d4(4'h4),
    .d5(4'h5),
    .d6(4'h6),
    .d7(4'h7),
    .d8(4'h8),
    .d9(4'h9),
    .d10(4'hA),
    .d11(4'hF),
  // Los 8 leds (MSb a la izquierda en pantalla)
    .led(8'b10101010),    
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
    .bi(6'h3F),
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
