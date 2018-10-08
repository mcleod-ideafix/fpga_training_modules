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
   EJEMPLO 20
   ----------
   
   Este código contiene un ejemplo de uso de los módulos de entrenamiento para FPGA, y
   está escrito para ser incluido dentro de un módulo (ver tld_modulos_entrenamiento_*.v)
   No es por tanto un código Verilog completo.
   
   Dentro de este fichero se pueden definir wire y reg, así como instanciar al módulo
   "display" que es el módulo principal del conjunto de módulos de entrenamiento.
   
   Dentro de este fichero no se pueden definir otros módulos o entidades, ya que este 
   fichero en sí está dentro de un módulo preexistente.

   Este core de ejemplo os permitirá saber cuál es el grado de rollover de vuestro teclado (es decir,
   cuántas teclas simultáneamente es capaz de procesar). También os permitirá detectar qué
   combinaciones de teclas pueden pulsarse a la vez y cuáles no. Esto os permitirá, si usais ese
   teclado en algún core de microordenador, poder redefinir las teclas de un juego para que use
   una combinación de teclas que permita cualquier acción.
   Por ejemplo, con el teclado que he usado, he descubierto que la combinación teclas del
   cursor + barra espaciadora me permite moverme y disparar en todas direcciones EXCEPTO
   en la dirección arriba-izquierda. Si pulso arriba, izquierda y disparo (el espacio), el 
   teclado sólo me devuelve dos teclas.
   
   Usaremos algo de memoria (un array de 128 bits) para almacenar el estado ya no sólo de 
   los cursores, sino en realidad de todo el teclado. La idea es mostrar en tiempo
   real en pantalla qué teclas están pulsadas y cuáles no.
   
   En el always @(posedge... ) donde se escanea el teclado, el código de tecla se comprueba que
   esté entre 1 y 127 y si es así, se actualiza la posición del array correspondiente con el
   valor 1 (tecla pulsada) o 0 (tecla soltada).
   La posición 0 es "especial". No hay de hecho ninguna tecla que produzca el código 0 de teclado,
   y por otra parte, hay una tecla, F7, que produce un código mayor de 127, así que como caso
   especial, si la tecla pulsada es F7, le asignamos la posición 0 del array.
   Este array será el que se muestre visualmente por pantalla.
   
   Este ejemplo genera una rejilla de 512x256 pixeles, con 16x8 casillas. Cada casilla es por
   tanto de 16x16 pixeles. La rejilla se genera de la misma forma que en ejemplos anteriores.
   Ahora, quien decide si una casilla se pone de un color u otro es lo que haya en la posición
   correspondiente del array.
   Esta posición se calcula en base a las coordenadas actuales, referidas al comienzo del cuadro,
   que son posxx y posyy. posxx varía de 0 a 511 y posyy, de 0 a 255.
   Si la posición que indican posxx,posyy no se corresponde a una posición de marco de rejilla (azul),
   entonces la posición del array a la que se corresponden viene dada por la fórmula 
   indice = ((posyy/32) * 16 + (posxx/32)
   Gracias a la "magia" de las potencias de 2, que son las mejores amigas del hardware, este valor se
   puede codificar en hardware sin más que tomar ciertos bits de posxx y posyy, y concatenándolos:
   (posyy/32) es lo mismo que coger de posyy todos sus bits hasta el bit 5. Como sabemos que posyy va
   de 0 a 255, posyy/32 irá de 0 a 7. Esto son 3 bits, así que tengo que coger desde el bit 5 hasta el 7,
   inclusive: posyy[7:5]
   Análogamente, (posxx/32) es igual a coger los bits 5 a 8, inclusive (posxx va de 0 a 511, así que
   posxx/32 va de 0 a 15, o sea, 4 bits). Esto es, posxx[8:5]
   Multiplicar (posyy/32) por 16 no es más que añadir cuatro 0's por la derecha: {posyy[7:5],4'b0000}
   Sumar a esto el valor (posxx/32), que sabemos que es de 4 bits, no es más que sustituir esos
   mismos cuatro ceros que acabamos de poner, por el valor posxx[8:5].
   Lo que nos queda: indice = {posyy[7:5],posxx[8:5]}
   Esto en hardware no es más que recablear. No hay ni una sola puerta lógica gastada para hacer esto.
*/   

  wire evento_teclado;        // conectado a "evento_teclado". Indica cuándo hay una tecla disponible, pulsada o soltada
  wire [7:0] codigo_tecla;    // conectado a la salida "scancode" del módulo display
  wire soltada;               // etc
  reg teclado[0:127];         // array de 128 entradas que indica si una tecla con cierto scancode está pulsada (1) o soltada (0)

  reg [5:0] rojo, verde, azul;
  wire [10:0] posx, posy;
  wire display_activo;  
  
  always @(posedge clk25m) begin       // en cada ciclo de reloj...
    if (evento_teclado == 1'b1)        // si hay una tecla pulsada...
      if (codigo_tecla > 8'h00 && codigo_tecla[7] == 1'b0)  // y su código está entre 1 y 127...
        teclado[codigo_tecla] <= ~soltada;  // actualizamos el array con su estado
      else if (codigo_tecla == 8'h83)   // caso especial F7, cuyo código > 127
        teclado[0] <= ~soltada;         // guardamos su estado en la posición 0 del array
  end
  
  localparam COLOR_TECLA_PULSADA     = {6'h20, 6'h20, 6'h00};
  localparam COLOR_TECLA_SOLTADA     = 18'h00000;
  localparam COLOR_REJILLA           = {6'h00, 6'h00, 6'h3F};
  localparam COLOR_FONDO             = {6'h08, 6'h00, 6'h08};
  localparam COLOR_NEGRO             = 18'h00000;

  localparam XINIT = (640 - 512) / 2;  // cuadro de 512x256 centrado
  localparam YINIT = (480 - 256) / 2;  // en pantalla
  localparam XFIN  = XINIT + 11'd512;
  localparam YFIN  = YINIT + 11'd256;
  
  wire [10:0] posxx = posx - XINIT;  // posxx,posyy son las coordenadas del punto
  wire [10:0] posyy = posy - YINIT;  // actual, referidas al comienzo del cuadro
  always @* begin
    if (display_activo == 1'b1) begin
      if (posx >= XINIT && posx < XFIN && posy >= YINIT && posy < YFIN) begin
        if (posyy[4:0] != 5'b11111 && posxx[4:0] != 5'b11111 && posxx != 11'd0 && posyy != 11'd0) begin  // si estamos dentro de una casilla, pero no en sus bordes...
          if (teclado[{posyy[7:5],posxx[8:5]}] == 1'b1)            //    miramos el estado de la tecla correspondiente a esa casilla
            {rojo,verde,azul} = COLOR_TECLA_PULSADA;               //    y la pintamos de un color...
          else
            {rojo,verde,azul} = COLOR_TECLA_SOLTADA;               //    ... u otro, según sea el caso
        end
        else
          {rojo,verde,azul} = COLOR_REJILLA;           // si estamos en un borde de casilla, pintamos del color de rejilla
      end
      else
        {rojo,verde,azul} = COLOR_FONDO;               // si estamos fuera del cuadro, pero aún en la región activa, ponemos un color de fondo
    end
    else
      {rojo,verde,azul} = COLOR_NEGRO;            // y por último, si estamos fuera de la región activa, pues de negro
  end

  display #(.YINIT(480)) pantalla (   // escondemos el display
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
