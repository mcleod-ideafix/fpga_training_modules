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
   EJEMPLO 2
   ---------
   
   Este código contiene un ejemplo de uso de los módulos de entrenamiento para FPGA, y
   está escrito para ser incluido dentro de un módulo (ver tld_modulos_entrenamiento_*.v)
   No es por tanto un código Verilog completo.
   
   Dentro de este fichero se pueden definir wire y reg, así como instanciar al módulo
   "display" que es el módulo principal del conjunto de módulos de entrenamiento.
   
   Dentro de este fichero no se pueden definir otros módulos o entidades, ya que este 
   fichero en sí está dentro de un módulo preexistente.
   
   En este ejemplo conectamos la salida de los interruptores (una señal de 8 bits) a la entrada
   de los leds y a dos de los 12 dígitos del display hexadecimal. Para ello definimos una señal
   de 8 bits llamada "switches" y al instanciar el módulo display, la usamos como salida del puerto
   "switches" de dicho módulo, y también como entrada en "leds" y los dígitos "d0" y "d1". El
   dígito "d0" contiene los 4 bits más significativos del valor de 8 bits contenido en "switches",
   y "d1" los 4 menos significativos. Así, a la izquierda del todo veremos la codificación en
   hexadecimal del valor introducido a través de los interruptores.
   
   Una vez enviado a la FPGA, es posible actuar sobre los 8 interruptores usando las 
   teclas de función F1 a F8. El estado de cada interruptor se verá en pantalla. El estado de los
   leds se actualizará automáticamente para reflejar el nuevo valor del interruptor, y el display
   hexadecimal también mostrará automáticamente dicho valor.
   
   El ejemplo tambien nos vale para ver como podemos modificar los dos parametros que tiene "display":
   YINIT, que nos permite indicar a que altura de la pantalla queremos que aparezca el dispaly, y
   FONTFILE, con el cual podemos indicar que use otra fuente de caracteres diferente a la que usa por
   defecto (la fuente IBM).
   Una fuente es originalmente un fichero que debe contener la definicion de 16 caracteres de 8x8 pixeles
   correspondientes a los digitos del 0 al 9 y de la A a la F. Consultar en el directorio "comun" las
   imagenes PNG de las que provienen estas fuentes para haceros una idea.
   Se puede usar otra fuente sin mas que generar un PNG con la misma estructura de los ejemplos
   incluidos, y ejecutar el archivo por lotes "genera_fuente_hex.bat".
   Para entornos Linux y OS X, crear un fichero shell script con los mismos comandos y compilar el 
   fichero bin2hex.c . Aseguraos de tener instalado ImageMagick. Si el comando "magick" no existe,
   probablemente se llame "convert".
   Para entorno Windows, instalar ImageMagick para Windows. Si es una version antigua, probablemente
   el programa "magick.exe" se llame "convert.exe". Modificar el .BAT si es el caso.
*/   

  // esta señal está conectada a la salida de los interruptores, y la conectamos a dos sitios más:
  // a la entrada de leds, y a los digitos d0 y d1. d0 mostrará el valor hexadecimal de los 4 
  // interruptores de más a la izquierda, y d1 los 4 de más a la derecha.
  wire [7:0] switches;

  display #(.YINIT(208), .FONTFILE("fuente_hexadecimal_sinclair.hex")) pantalla (
  // Los 12 digitos hexadecimales (de izquierda a derecha)
    .d0(switches[7:4]),  // bits 4 a 7 de switches
    .d1(switches[3:0]),  // bits 0 a 3 de switches
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
    .led(switches),   // conectamos los 8 interruptores a los leds.
  // Las salidas de los 8 interruptores (F1 es bit 7, F2 es bit 6, ...., F8 es bit 0)
    .switch(switches), // el estado de los interruptores va a esta señal de 8 bits
  // Acceso a la ultima tecla pulsada 
    .evento_teclado(),
    .scancode(),
    .soltada(),
    .extendida(),  
  // Acceso a la pantalla
    .ri(6'h00),  //
    .gi(6'h00),  // Fondo negro de pantalla. Cambialo al que
    .bi(6'h00),  // te guste más
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
