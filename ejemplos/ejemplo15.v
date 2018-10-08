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
   EJEMPLO 15
   ----------
   
   Este código contiene un ejemplo de uso de los módulos de entrenamiento para FPGA, y
   está escrito para ser incluido dentro de un módulo (ver tld_modulos_entrenamiento_*.v)
   No es por tanto un código Verilog completo.
   
   Dentro de este fichero se pueden definir wire y reg, así como instanciar al módulo
   "display" que es el módulo principal del conjunto de módulos de entrenamiento.
   
   Dentro de este fichero no se pueden definir otros módulos o entidades, ya que este 
   fichero en sí está dentro de un módulo preexistente.
   
   En este ejemplo restringimos la paleta de colores a mostrar de 262144 originales, a 65536.
   Esto permite mostrarlos en una cuadrícula de 256x256 píxeles. Estéticamente es una mejora
   respecto al ejemplo anterior al apreciarse mejor los gradientes de color.
   
   El color de 16 bits a mostrar se forma agrupando los 8 bits menos significativos de las
   coordenadas X e Y, referenciadas al comienzo del gráfico (indx e indy). De ese color se toman
   los bits 15 a 11 para el rojo, del 10 al 5 para el verde, y del 4 al 0 para el azul.
   
   Cuando el número de bits a mostrar es inferior al número de bits que soporta fisicamente el
   dispositivo (aquí todas las componentes de color tienen 6 bits físicos pero en el ejemplo, el rojo y
   el azul tienen 5) lo que se hace es repetir tantas veces el valor a la derecha hasta completar el
   número de bits requerido.
   
   Por ejemplo, si el valor de rojo se guarda en 5 bits de la forma R4 R3 R2 R1 R0 pero el display
   donde lo queremos visualizar usa 6 bits para el rojo, el valor de 6 bits se forma así:
   R4 R3 R2 R1 R0 R4
   Si el display usara 8 bits por color, el rojo de 5 bits se codificaría así:
   R4 R3 R2 R1 R0 R4 R3 R2

*/   

  localparam XINIT = (640 - 256) / 2;  // para centrar el cuadro de
  localparam YINIT = (480 - 256) / 2;  // 256x256 en pantalla. Mostraremos 65536 colores (RGB 565)

  reg [5:0] rojo, verde, azul;
  wire [10:0] posx, posy;
  wire display_activo;  

  wire [10:0] indx = posx - XINIT;
  wire [10:0] indy = posy - YINIT;
  wire [15:0] color = {indy[7:0], indx[7:0]};
  
  always @* begin
    if (display_activo == 1'b1 && indx >= 10'd0 && indx < 10'd256 && indy >= 10'd0 && indy < 10'd256) begin
      rojo  = {color[15:11], color[15]};  // rojo, 5 bits
      verde = {color[10:5]};              // verde, 6 bits
      azul  = {color[4:0], color[4]};     // rojo, 5 bits
    end
    else
      {rojo, verde, azul} = 18'h00000;
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
