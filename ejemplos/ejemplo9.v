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
   EJEMPLO 9
   ---------
   
   Este código contiene un ejemplo de uso de los módulos de entrenamiento para FPGA, y
   está escrito para ser incluido dentro de un módulo (ver tld_modulos_entrenamiento_*.v)
   No es por tanto un código Verilog completo.
   
   Dentro de este fichero se pueden definir wire y reg, así como instanciar al módulo
   "display" que es el módulo principal del conjunto de módulos de entrenamiento.
   
   Dentro de este fichero no se pueden definir otros módulos o entidades, ya que este 
   fichero en sí está dentro de un módulo preexistente.

   En esta ocasión, la mejora al cronómetro consiste en dos interruptores: el interruptor 7,
   controlado por la tecla F1, pausa o reanuda la cuenta del cronómetro. El interruptor 6,
   controlado por la tecla F2, pone a 0 el cronómetro.
*/   

  reg sentido = 1'b0;  // en este flipflop guardamos el sentido: 0=derecha, 1=izquierda
  reg [7:0] leds = 8'b10000000;   
  reg [23:0] contador = 24'd0;  // contador que cuenta de 0 hasta 2500000 (una décima de segundo, a 25 MHz)

  // Valores iniciales del cronómetro
  reg [3:0] decimas  = 4'd0;
  reg [3:0] unidades = 4'd0;
  reg [3:0] decenas  = 4'd0;
  reg [3:0] centenas = 4'd0;
  reg [3:0] millares = 4'd0;
  
  // Interruptores
  wire [7:0] sw;
  
  always @(posedge clk25m) begin   // en cada ciclo de reloj del reloj de 25 MHz hacemos lo siguiente:
    if (contador == 24'd2500000) begin   // si hemos llegado a una décima de segundo de tiempo...
      contador <= 24'd0;                 //    ponemos el contador a 0, y

      // Gestión del cronómetro
      if (sw[7] == 1'b0) begin       // si el interruptor 7 (F1) está apagado, se permite la cuenta del cronómetro
        if (sw[6] == 1'b1) begin     // si el interruptor 6 (F2) está encendido, se pone a 0 el cronómetro
          decimas <= 4'd0;
          unidades <= 4'd0;
          decenas <= 4'd0;
          centenas <= 4'd0;
          millares <= 4'd0;
        end
        else begin  // aquí llegamos cuando sw[7] es 0 y sw[6] también es 0, o sea, cuando dejamos que el cronómetro funcione
          if (decimas == 4'd9) begin         // Vamos a pasar de 9 a 10 en las decimas? Si es que si,
            decimas <= 4'd0;                 //    ponemos las décimas a 0
            if (unidades == 4'd9) begin      //    Vamos a pasar de 9 a 10 en las unidades? Si es que sí,
              unidades <= 4'd0;              //        ponemos las unidades a 0
              if (decenas == 4'd9) begin     //        Vamos a pasar de 9 a 10 en las decenas? .... etc .....
                decenas <= 4'd0;
                if (centenas == 4'd9) begin
                  centenas <= 4'd0;
                  if (millares == 4'd9) begin
                    millares <= 4'd0;
                  end
                  else
                    millares <= millares + 4'd1;
                end
                else
                  centenas <= centenas + 4'd1;
              end
              else
                decenas <= decenas + 4'd1;   //        Si es que no, incrementamos las decenas
            end
            else
              unidades <= unidades + 4'd1;   //    Si es que no, incrementamos las unidades
          end
          else
            decimas <= decimas + 4'd1;       // Si es que no, incrementamos las decimas
        end  // del IF del interruptor 6
      end  // del IF del interruptor 7
                  
      // Gestión de la tira de leds
      if (sentido == 1'b0)               //    miramos en qué sentido hemos de rotar
        leds <= {leds[0], leds[7:1]};    //      rotamos a la derecha si es 0
      else                               //      si no,
        leds <= {leds[6:0], leds[7]};    //      entonces rotamos a la izquierda
      if (leds[1] == 1'b1 && sentido == 1'b0)       // si estamos a punto de llegar a la esquina derecha y estábamos rotando a la derecha...
        sentido <= 1'b1;                            //    pasamos a rotar a la izquierda
      else if (leds[6] == 1'b1 && sentido == 1'b1)  // si no, si estamos a punto de llegar a la esquina izquierda y estábamos rotando a la izquierda...
        sentido <= 1'b0;                            //    pasamos a rotar a la derecha
    end

    else                                 // en otro caso
      contador <= contador + 24'd1;      //    incrementamos el contador de ciclos de reloj
  end
  
  display pantalla (
  // Los 12 digitos hexadecimales (de izquierda a derecha)
    .d0(4'h0),
    .d1(4'h0),
    .d2(4'h0),
    .d3(4'h0),
    .d4(millares),
    .d5(centenas),
    .d6(decenas),
    .d7(unidades),
    .d8(decimas),
    .d9(4'h0),
    .d10(4'h0),
    .d11(4'h0),
  // Los 8 leds (MSb a la izquierda en pantalla)
    .led(leds),    
  // Las salidas de los 8 interruptores (F1 es bit 7, F2 es bit 6, ...., F8 es bit 0)
    .switch(sw),
  // Acceso a la ultima tecla pulsada 
    .evento_teclado(),
    .scancode(),
    .soltada(),
    .extendida(),  
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
