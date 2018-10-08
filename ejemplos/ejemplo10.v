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
   EJEMPLO 10
   ----------
   
   Este código contiene un ejemplo de uso de los módulos de entrenamiento para FPGA, y
   está escrito para ser incluido dentro de un módulo (ver tld_modulos_entrenamiento_*.v)
   No es por tanto un código Verilog completo.
   
   Dentro de este fichero se pueden definir wire y reg, así como instanciar al módulo
   "display" que es el módulo principal del conjunto de módulos de entrenamiento.
   
   Dentro de este fichero no se pueden definir otros módulos o entidades, ya que este 
   fichero en sí está dentro de un módulo preexistente.

   En este ejemplo usamos toda la información que nos suministra el teclado PS/2. Este
   dispositivo es mucho más versátil que los pulsadores que ofrecen las placas entrenadoras,
   y gracias a que el módulo display encapsula toda la operatividad del teclado, su compli-
   cación pasa desapercibida al usuario. Aun así, el manejo del teclado es un poco más
   complicado que el de un pulsador normal de entrenadora. Por otra parte, con el teclado
   no es necesario incluir un circuito para anular los rebotes, que sí suele ser necesario
   con los pulsadores mecánicos.
   
   El ejemplo conecta las salidas que suministra la parte del módulo que maneja el teclado
   a los leds y al display hexadecimal, para así mostrar cuál ha sido la última tecla pulsada
   o soltada, y su estado (pulsada o soltada, y si es extendida o normal).
   
   El código mostrado no es el código ASCII del carácter impreso en la tecla. Los teclados PS/2
   no funcionan así, sino que independientemente de la localización del teclado, éstos
   devuelven un código posicional de la tecla, que en los ordenadores deberá ser traducido al carácter
   correspondiente mediante un driver que sí sabe qué carácter corresponde en cada posición de tecla
   
   Para más info, consultar la tabla "scancode set 2" aquí:
   https://wiki.osdev.org/PS/2_Keyboard#Scan_Code_Set_2
   
   Nótese que este módulo no ofrece los valores F0 y E0 como scancodes, ya que estos códigos van
   incluidos en la información suministrada en las señales "soltada" y "extendida". De esa forma,
   con el módulo el usuario sólo ve un scancode de 8 bits y no una ristra de ellos, para cada
   tecla.
*/   

  wire evento_teclado;        // conectado a "evento_teclado". Indica cuándo hay una tecla disponible, pulsada o soltada
  wire [7:0] codigo_tecla;    // conectado a la salida "scancode" del módulo display
  wire soltada;               // etc
  wire extendida;             // etc
  reg r_soltada = 1'b0;       // En estos registros guardamos
  reg r_extendida = 1'b0;     // la información de la última tecla
  reg [7:0] r_codigo = 8'h00; // cuando "evento_teclado" es 1
  
  always @(posedge clk25m) begin       // en cada ciclo de reloj...
    if (evento_teclado == 1'b1) begin  // ... miramos si evento_teclado vale 1
      r_codigo <= codigo_tecla;        // y si es así, guardamos los datos de la tecla (codigo, 
      r_soltada <= soltada;            // si está pulsada o soltada, y si
      r_extendida <= extendida;        // es una tecla extendida o no)
    end
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
    .d10(r_codigo[7:4]),  // los dos dígitos hexadecimales
    .d11(r_codigo[3:0]),  // del codigo de scan de la tecla
  // Los 8 leds (MSb a la izquierda en pantalla)
    .led({6'b0, r_extendida, r_soltada}),  // led 1 indica si tecla extendida (ON) o normal (OFF). Led 0 indica si pulsada (OFF) o soltada (ON)
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
