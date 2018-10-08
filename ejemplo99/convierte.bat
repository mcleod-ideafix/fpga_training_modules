@echo off
magick %1 rgb:%~n1.bin
rgb242hex18 %~n1.bin
del %~n1.bin