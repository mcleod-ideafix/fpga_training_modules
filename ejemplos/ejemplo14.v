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
   EJEMPLO 14
   ----------
   
   Este código contiene un ejemplo de uso de los módulos de entrenamiento para FPGA, y
   está escrito para ser incluido dentro de un módulo (ver tld_modulos_entrenamiento_*.v)
   No es por tanto un código Verilog completo.
   
   Dentro de este fichero se pueden definir wire y reg, así como instanciar al módulo
   "display" que es el módulo principal del conjunto de módulos de entrenamiento.
   
   Dentro de este fichero no se pueden definir otros módulos o entidades, ya que este 
   fichero en sí está dentro de un módulo preexistente.
   
   En este ejemplo nos centraremos en la generación de imágenes gráficas. Para que la imagen
   generada no se vea sobreimpresionada por el display, lo instanciamos, pero con un valor
   para la coordenada Y inicial más allá del límite de la pantalla (de 0 a 479 son los 
   valores válidos)

   La idea es mostrar en pantalla todos los colores disponibles. Tenemos 6 bits por color
   primario en UnAmiga y ZXDOS. Eso nos da 18 bits de color, o 262144 colores posibles.

   Para mostrarlos, usaremos un contador que irá contando de 0 a 262144 (00000h a 40000h).
   Los bits 17 a 0 de este contador nos darán las componentes roja, verde
   y azul, respectivamente. El bit 18 nos servirá para indicar que la cuenta debe parar y
   esperar al siguiente frame, donde el contador vuelve a ponerse a 0.

   El contador sólo se incrementa cuando hay que pintar píxeles. Esto es, cuando estamos
   dentro del área activa (display_activo == 1) y no hemos llegado al tope de la cuenta
   (el valor 262144 que es el único que tiene el bit 18 a 1)

   El resultado es una trama de gradientes de colores que muestra, efectivamente, los
   262144 colores distintos que estas placas pueden generar. Al no organizarse en un
   cuadrado con longitud de lado igual a potencia de 2, el efecto estético no es tan
   bonito como en otras representaciones de paletas que se pueden consultar. Lo trataremos
   de arreglar un poco en el siguiente ejemplo.

*/   

  wire [5:0] rojo, verde, azul;
  wire [10:0] posx, posy;
  wire display_activo;  
  
  reg [18:0] color = 19'd0;
  always @(posedge clk25m) begin
    if (display_activo == 1'b0 && posy > 10'd479)  // si se ha terminado de pintar la pantalla y estamos en retrazo vertical...
      color <= 19'd0;  // reseteamos contador de colores
    else if (display_activo == 1'b1 && color[18] == 1'b0)  // si no, si estamos pintando el área activa y no hemos llegado al tope
      color <= color + 19'd1;  // vamos incrementando el contador de color
  end

  assign rojo  = color[17:12];
  assign verde = color[11:6];
  assign azul  = color[5:0];
  
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
