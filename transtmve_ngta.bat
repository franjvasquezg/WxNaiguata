@ECHO OFF
setlocal EnableDelayedExpansion

set ARCH=%1 
set FECSES=%3
set USUARIOTMVE=TMVE\%4
set CLAVETMVE=%5
net use R: /delete

net use R: \\dskclu02dt1\GerenciaTST-1$ /USER:%USUARIOTMVE% %CLAVETMVE%

IF ERRORLEVEL 1 goto :EOFE

IF %2 == PROD set PREFIJO=Produccion
IF %2 == CCAL set PREFIJO=Calidad

md R:\Procesos\"Compensacion Naiguata-MC"\!PREFIJO!\T461NA\!FECSES!
copy E:\NAIGUATA\TDD\Entrada\%1 "R:\Procesos\Compensacion Naiguata-MC\!PREFIJO!\T461NA\!FECSES!\!ARCH!"

IF ERRORLEVEL 1 goto :EOFE
goto :eof


:eofe
net use R: /delete
exit 1
:eof
net use R: /delete
exit 0