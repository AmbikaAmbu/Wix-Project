@echo off

set WIXBIN=C:\Program Files (x86)\WiX Toolset v3.11\bin

"%WIXBIN%\heat.exe" dir "..\Publish" ^
-cg AppFiles ^
-dr INSTALLFOLDER ^
-gg ^
-g1 ^
-srd ^
-sfrag ^
-out AppFiles.wxs