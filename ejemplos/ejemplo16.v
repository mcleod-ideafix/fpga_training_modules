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
   EJEMPLO 16
   ----------
   
   Este código contiene un ejemplo de uso de los módulos de entrenamiento para FPGA, y
   está escrito para ser incluido dentro de un módulo (ver tld_modulos_entrenamiento_*.v)
   No es por tanto un código Verilog completo.
   
   Dentro de este fichero se pueden definir wire y reg, así como instanciar al módulo
   "display" que es el módulo principal del conjunto de módulos de entrenamiento.
   
   Dentro de este fichero no se pueden definir otros módulos o entidades, ya que este 
   fichero en sí está dentro de un módulo preexistente.
   
   En este ejemplo usamos los valores de posx, posy para pintar un gradiente de color
   para cada color primario. Es decir, todos los niveles de brillo para rojo, para verde,
   y para azul, disponibles en nuestra placa (64 niveles para ZXDOS, UnAmiga y ZXUNO con
   el addon de VGA 18 bits, o 8 niveles para el ZXUNO estándar)
   
   El valor de posy nos dice si estamos en el primer tercio, segundo tercio o tercer tercio
   de la pantalla, y según sea, pintaremos con rojo, con verde o con azul.
   
   El valor de posx, una vez referenciado al comienzo del cuadro (posxx), nos servirá para
   determinar el color a pintar. Los valores de posxx dentro del cuadro van desde 0 a 511.
   Si dividimos entre 8 (división entera), tenemos valores entre 0 y 63: precisamente el
   nivel de brillo que andamos buscando. Dividir entre 8 (o entre cualquier potencia de 2)
   es sumamente sencillo en hardware: para dividir entre 2^N basta con descartar los N bits
   menos significativos del dividendo.
*/   

  localparam XINIT = (640-512)/2;  // un cuadro de 512 puntos de largo,
  localparam XFIN  = XINIT + 512;  // centrado en pantalla

  reg [5:0] rojo, verde, azul;
  wire [10:0] posx, posy;
  wire display_activo;
  
  wire [10:0] posxx = posx - XINIT;  // posxx es la posición de pixel, referido al comienzo del cuadro

  always @* begin
    if (display_activo == 1'b1 && posx >= XINIT && posx < XFIN) begin  // si estamos en el área activa, y dentro del cuadro...
      if (posy >= 10'd0 && posy < 10'd160) begin   // si estamos en el primer tercio de pantalla...
        rojo  = posxx[9:3];   // esto es lo mismo que decir posxx/8. Cambiamos el color cada 8 pixeles.
        verde = 6'h00;        // Como hay 512 pixeles, 512/8 = 64, que son los niveles de brillo
        azul  = 6'h00;        // disponibles con 6 bits de color. Esto es el gradiente de rojo
      end
      else if (posy >= 10'd160 && posy < 10'd320) begin  // si estamos en el segundo tercio de pantalla, gradiente de verde
        rojo  = 6'h00;
        verde = posxx[9:3];
        azul  = 6'h00;
      end
      else begin     // si estamos en el tercer tercio de pantalla, gradiente de azul
        rojo  = 6'h00;
        verde = 6'h00;
        azul  = posxx[9:3];
      end
    end
    else if (display_activo == 1'b1)  // si estamos en el área activa, pero fuera del cuadro, pintamos un fondo grisaceo
      {rojo, verde, azul} = {6'h10, 6'h10, 6'h10};
    else   // y si estamos fuera del área activa, pintamos negro (como siempre y como debe ser)
      {rojo, verde, azul} = {6'h00, 6'h00, 6'h00};
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
