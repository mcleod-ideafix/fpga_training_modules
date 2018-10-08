@echo off
magick %1.png -depth 1 gray:%1.bin
bin2hex %1.bin
del %1.bin
