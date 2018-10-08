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
   EJEMPLO 13
   ----------
   
   Este código contiene un ejemplo de uso de los módulos de entrenamiento para FPGA, y
   está escrito para ser incluido dentro de un módulo (ver tld_modulos_entrenamiento_*.v)
   No es por tanto un código Verilog completo.
   
   Dentro de este fichero se pueden definir wire y reg, así como instanciar al módulo
   "display" que es el módulo principal del conjunto de módulos de entrenamiento.
   
   Dentro de este fichero no se pueden definir otros módulos o entidades, ya que este 
   fichero en sí está dentro de un módulo preexistente.
   
   En este ejemplo vamos a poder entrar un valor de 8 bits desde el teclado. Para ello
   cada vez que hay un evento de teclado se mira a ver si es alguna de las teclas numéricas,
   o las teclas de la A a la F, o la tecla INTRO.
   
   Dos registros, d10 y d11, que están conectados a los dígitos 10 y 11 del display hexadecimal,
   van tomando los valores tecleados. Para ello, cuando se pulsa una tecla, si ésta es un
   carácter válido en hexadecimal, se pasa el valor correspondiente a d11, mientras que el valor
   de d11 pasa a d10. De esta forma, en los dos dígitos de la derecha podemos ver el último
   valor introducido.
   Si se pulsa INTRO, el valor actual combinado de {d10,d11}, que es un valor de 8 bits,
   se copia en el registro "leds" que está conectado a las entradas de los leds, con lo que
   vemos inmediatamente el valor en binario.
   Además, el registro "leds" está conectado a las entradas R,G,B de la siguiente forma:
   - Los bits 7 a 5 de "leds" se replican dos veces para formar un valor de 6 bits, que pasa
     a ser el valor de la componente roja del color que se verá como fondo en pantalla.
   - Los bits 4 a 2 de "leds" se replican también dos veces, esta vez para formar el valor de
     la componente verde.
   - Los bits 1 y 0 de "leds" se replican tres veces para formar un valor de 6 bits que se
     aplicará a la componente azul.
   El color que se verá en pantalla será por tanto del tipo RRRGGGBB, o RGB 332

   Para averiguar qué códigos de scan hay que usar para identificar las teclas numéricas se
   puede optar por usar alguno de los ejemplos anteriores, que da esa información, o consultar
   la tabla de códigos en:
   https://wiki.osdev.org/PS/2_Keyboard#Scan_Code_Set_2
*/   

  wire evento_teclado;        // conectado a "evento_teclado". Indica cuándo hay una tecla disponible, pulsada o soltada
  wire [7:0] codigo_tecla;    // conectado a la salida "scancode" del módulo display
  wire soltada;               // etc
  wire extendida;             // etc
  
  reg [3:0] d10,d11;
  reg [7:0] leds;
  
  wire [5:0] rojo, verde, azul;
  assign rojo = {leds[7:5], leds[7:5]};
  assign verde = {leds[4:2], leds[4:2]};
  assign azul = { {3{leds[1:0]}} };
  
  always @(posedge clk25m) begin       // en cada ciclo de reloj...
    if (evento_teclado == 1'b1 && soltada == 1'b0) begin
      case (codigo_tecla)
        8'h45, 8'h70: begin   // 0
                        d11 <= 4'h0;
                        d10 <= d11;
                      end
        8'h16, 8'h69: begin   // 1
                        d11 <= 4'h1;
                        d10 <= d11;
                      end
        8'h1E, 8'h72: begin   // 2
                        d11 <= 4'h2;
                        d10 <= d11;
                      end
        8'h26, 8'h7A: begin   // 3
                        d11 <= 4'h3;
                        d10 <= d11;
                      end
        8'h25, 8'h6B: begin   // 4
                        d11 <= 4'h4;
                        d10 <= d11;
                      end
        8'h2E, 8'h73: begin   // 5
                        d11 <= 4'h5;
                        d10 <= d11;
                      end
        8'h36, 8'h74: begin   // 6
                        d11 <= 4'h6;
                        d10 <= d11;
                      end
        8'h3D, 8'h6C: begin   // 7
                        d11 <= 4'h7;
                        d10 <= d11;
                      end
        8'h3E, 8'h75: begin   // 8
                        d11 <= 4'h8;
                        d10 <= d11;
                      end
        8'h46, 8'h7D: begin   // 9
                        d11 <= 4'h9;
                        d10 <= d11;
                      end
               8'h1C: begin   // A
                        d11 <= 4'hA;
                        d10 <= d11;
                      end
               8'h32: begin   // B
                        d11 <= 4'hB;
                        d10 <= d11;
                      end
               8'h21: begin   // C
                        d11 <= 4'hC;
                        d10 <= d11;
                      end
               8'h23: begin   // D
                        d11 <= 4'hD;
                        d10 <= d11;
                      end
               8'h24: begin   // E
                        d11 <= 4'hE;
                        d10 <= d11;
                      end
               8'h2B: begin   // F
                        d11 <= 4'hF;
                        d10 <= d11;
                      end
               8'h5A: leds <= {d10,d11};   // INTRO
      endcase
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
    .d10(d10),
    .d11(d11),
  // Los 8 leds (MSb a la izquierda en pantalla)
    .led(leds),  // led 1 indica si tecla extendida (ON) o normal (OFF). Led 0 indica si pulsada (OFF) o soltada (ON)
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
