@echo off

rem Sample script to faciliate development.  X and Y positions are hard-coded
rem for my particular dual monitor setup.

cd ..\..\..
start t-engine.exe -Mqdz -uDefault -n --xpos -1920 --ypos -32 --home c:\temp\qdz
rem start t-engine.exe -Mqdz -uDefault -n --xpos -1920 --ypos -32 --home c:\temp\qdz --flush-stdout 
