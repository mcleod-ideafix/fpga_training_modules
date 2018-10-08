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
   EJEMPLO 18
   ----------
   
   Este código contiene un ejemplo de uso de los módulos de entrenamiento para FPGA, y
   está escrito para ser incluido dentro de un módulo (ver tld_modulos_entrenamiento_*.v)
   No es por tanto un código Verilog completo.
   
   Dentro de este fichero se pueden definir wire y reg, así como instanciar al módulo
   "display" que es el módulo principal del conjunto de módulos de entrenamiento.
   
   Dentro de este fichero no se pueden definir otros módulos o entidades, ya que este 
   fichero en sí está dentro de un módulo preexistente.
   
   En el EJEMPLO 17 vimos una forma de usar el teclado para mover una cruz por la pantalla,
   pero se podían observar algunas cosas:
   - El movimiento es lento, no es tan suave como podría ser.
   - No es posible mover la cruz en diagonal pulsando dos teclas
   Lo primero ocurre porque al escanear el teclado, sólo lo hacemos cuando se pulsa una tecla.
   El teclado PS/2, por defecto, tiene un modo de autorrepetición que hace que si una tecla
   se deja pulsada, el evento "tecla pulsada" se repite a un cierto ritmo. De ahí que al dejar
   pulsada una de las direcciones, la cruz se mueve un pixel en esa dirección, luego una pausa
   pequeña, y después sigue moviéndose a un ritmo más rápido.
   Lo segundo ocurre porque la elección de qué coordenada se actualiza la hacemos en una 
   estructura case...endcase, en donde sólo puede haber una elección posible
   
   Para solucionar lo primero, en este ejemplo optamos por guardar en 4 flipflops (registro "direcciones")
   el estado (pulsada o soltada) de cada una de las teclas del cursor.
   Ahora, en el escaneo de teclado, lo que hacemos es sencillamente actualizar el flipflop
   correspondiente con el estado de la tecla a la que se asocia.
   Este mecanismo es análogo al que se hace en cores de retroordenadores, en donde el conjunto
   de flipflops guarda el estado actual de la matriz de teclado original del microordenador.
   
   La actualización de las coordenadas cruz_x, cruz_y se hace ahora mirando el estado de
   estos flipflops, y no se hace con case...endcase, sino con if's independientes (no son
   estructuras if-else if). Al ser independientes, pueden ser ciertos más de uno de estos if's
   y por tanto actualizarse las dos coordenadas, permitiendo movimientos diagonales de la cruz.
   
   Pero recordemos que la actualización se hace en un always @(posedge clk25m). Así tal cual,
   esto significaría que con una tecla pulsada, la coordenada correspondiente se actualizaría
   25 millones de veces por segundo, haciendo imposible mover la cruz con precisión. Hay que
   limitar el número de actualizaciones por segundo para conseguir un movimiento rápido, pero preciso.
   Una buena opción es realizar una actualización de coordenadas en cada frame. Para ello tenemos
   que escoger en qué momento, dentro del frame, queremos realizar dicha actualización.
   Por ejemplo, se podría actualizar justo cuando se ha terminado de pintar la región activa, esto es,
   cuando posy es mayor de 479. Como hay un montón de ciclos de reloj en los que esto se cumple,
   hay que escoger un momento concreto. El que he escogido es el momento en el que las coordenadas
   (posx,posy) valen (0,480). Esto se corresponde con un punto a la izquierda de la pantalla, pero en una
   línea invisible. posx y posy tendrán estos valores sólo una vez (un ciclo) en cada frame, con lo que
   la actualización ahora no se hace 25 millones de veces por segundo, sino 60 veces por segundo.
*/   
  
  localparam COLOR_REJILLA = {6'h00, 6'h20, 6'h00};   // verde medio
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

  reg [3:0] direcciones = 4'b0000;   // 0:arriba, 1:abajo, 2:izquierda, 3:derecha
  
  always @(posedge clk25m) begin
    if (evento_teclado == 1'b1 && extendida == 1'b1) begin  // si se ha pulsado o soltado una tecla extendida...
      case (codigo_tecla)                                                      // miramos a ver qué tecla es...
        CURSOR_ARRIBA: direcciones[0] <= ~soltada;
        CURSOR_ABAJO:  direcciones[1] <= ~soltada;
        CURSOR_IZQDA:  direcciones[2] <= ~soltada;
        CURSOR_DRCHA:  direcciones[3] <= ~soltada;
      endcase
    end
  end

  always @(posedge clk25m) begin
    if (posx == 10'd0 && posy == 10'd480) begin  // esta situación sólo ocurre una vez en cada frame
      if (direcciones[0] == 1'b1)
        if (cruz_y != 10'd0) cruz_y <= cruz_y - 10'd1;
      if (direcciones[1] == 1'b1)
        if (cruz_y != 10'd479) cruz_y <= cruz_y + 10'd1;
      if (direcciones[2] == 1'b1)
        if (cruz_x != 10'd0) cruz_x <= cruz_x - 10'd1;
      if (direcciones[3] == 1'b1)
        if (cruz_x != 10'd639) cruz_x <= cruz_x + 10'd1;
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
