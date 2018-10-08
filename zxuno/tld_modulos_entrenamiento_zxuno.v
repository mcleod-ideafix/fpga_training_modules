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

`timescale 1ns / 1ps
`default_nettype none

module tld_modulos_entrenamiento_zxuno (
  input wire clk50mhz,
  input wire clkps2,
  input wire dataps2,
  output wire [2:0] ro,
  output wire [2:0] go,
  output wire [2:0] bo,
  output wire hsync,
  output wire vsync
  );

  wire clk25m;
  relojes reloj25mhz (
    .CLK_IN1(clk50mhz),
    .CLK_OUT1(clk25m)
    );
    
  wire [5:0] r, g, b;
  assign ro = r[5:3];
  assign go = g[5:3];
  assign bo = b[5:3];

  `include "../ejemplos/ejemplo1.v"
  // `include "../ejemplos/ejemplo2.v"
  // `include "../ejemplos/ejemplo3.v"
  // `include "../ejemplos/ejemplo4.v"
  // `include "../ejemplos/ejemplo5.v"
  // `include "../ejemplos/ejemplo6.v"
  // `include "../ejemplos/ejemplo7.v"
  // `include "../ejemplos/ejemplo8.v"
  // `include "../ejemplos/ejemplo9.v"
  // `include "../ejemplos/ejemplo10.v"
  // `include "../ejemplos/ejemplo11.v"
  // `include "../ejemplos/ejemplo12.v"
  // `include "../ejemplos/ejemplo13.v"
  // `include "../ejemplos/ejemplo14.v"
  // `include "../ejemplos/ejemplo15.v"
  // `include "../ejemplos/ejemplo16.v"
  // `include "../ejemplos/ejemplo17.v"
  // `include "../ejemplos/ejemplo18.v"
  // `include "../ejemplos/ejemplo19.v"
  // `include "../ejemplos/ejemplo20.v"
  // `include "../ejemplo99/ejemplo99.v"

endmodule

`default_nettype wire
