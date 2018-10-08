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
   EJEMPLO 11
   ----------
   
   Este código contiene un ejemplo de uso de los módulos de entrenamiento para FPGA, y
   está escrito para ser incluido dentro de un módulo (ver tld_modulos_entrenamiento_*.v)
   No es por tanto un código Verilog completo.
   
   Dentro de este fichero se pueden definir wire y reg, así como instanciar al módulo
   "display" que es el módulo principal del conjunto de módulos de entrenamiento.
   
   Dentro de este fichero no se pueden definir otros módulos o entidades, ya que este 
   fichero en sí está dentro de un módulo preexistente.

   En el EJEMPLO 10, el diseño ofrecía la información del último evento de teclado. Hay teclas especiales que
   generan varios eventos (ImprPant y Pausa, por ejemplo) así que si queremos ver cuáles son, tenemos que poder
   recoger la "historia" de los últimos eventos que se hayan producido.
   
   Como tenemos un display que permite 6 valores de 8 bits (12 dígitos hexadecimales), podemos ver los últimos
   6 eventos. Para ello, en lugar de un registro de 8 bits donde guardar el último código de tecla, tendremos
   un array de 6 registros de 8 bits cada uno. Cada vez que se registre un evento de teclado, guardamos su
   código en el elemento 5 del array, y desplazamos todos los demás una posición a la izquierda (el anterior
   contenido del elemento 5 pasa a ser el nuevo contenido del elemento 4, el del 4 pasa al 3, el del 3 al 2, etc,
   hasta el del 1 que pasa al elemento 0.
   
   Todas estas asignaciones ocurren al mismo tiempo, no una detrás de otra (como se podría suponer por el orden
   en el código) y esto es una de las diferencias fundamentales con la escritura de software que se ejecuta
   en un procesador.
*/   

  wire evento_teclado;        // conectado a "evento_teclado". Indica cuándo hay una tecla disponible, pulsada o soltada
  wire [7:0] codigo_tecla;    // conectado a la salida "scancode" del módulo display
  wire soltada;               // etc
  wire extendida;             // etc
  reg r_soltada = 1'b0;       // En estos registros guardamos la información 
  reg r_extendida = 1'b0;     // de la última tecla cuando "evento_teclado" es 1
  reg [7:0] r_codigo[0:5];    // array de 6 valores de 8 bits (12 digitos hexadecimales)
  
  always @(posedge clk25m) begin       // en cada ciclo de reloj...
    if (evento_teclado == 1'b1) begin  // ... miramos si evento_teclado vale 1
      r_codigo[5] <= codigo_tecla;   // Entender que estas asignaciones
      r_codigo[4] <= r_codigo[5];    // funcionan y no machacan sus contenidos
      r_codigo[3] <= r_codigo[4];    // como alguien pudiera pensar, es la base
      r_codigo[2] <= r_codigo[3];    // para darse cuenta de que lo que estamos
      r_codigo[1] <= r_codigo[2];    // haciendo no es un programa que se ejecute
      r_codigo[0] <= r_codigo[1];    // en una CPU, sino un circuito
      r_soltada <= soltada;
      r_extendida <= extendida;
    end
  end

  display pantalla (
  // Los 12 digitos hexadecimales (de izquierda a derecha)
    .d0 (r_codigo[0][7:4]),
    .d1 (r_codigo[0][3:0]),
    .d2 (r_codigo[1][7:4]),
    .d3 (r_codigo[1][3:0]),
    .d4 (r_codigo[2][7:4]),
    .d5 (r_codigo[2][3:0]),
    .d6 (r_codigo[3][7:4]),
    .d7 (r_codigo[3][3:0]),
    .d8 (r_codigo[4][7:4]),
    .d9 (r_codigo[4][3:0]),
    .d10(r_codigo[5][7:4]),
    .d11(r_codigo[5][3:0]),
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
