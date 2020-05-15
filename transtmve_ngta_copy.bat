@ECHO OFF
setlocal EnableDelayedExpansion

rem set ARCH=SWCHD363NA_0313_0502_0_087
set ARCH=%1 
set ACCI=%2


if %ACCI% EQU C1 goto COPIA1
if %ACCI% EQU C2 goto COPIA2  
if %ACCI% EQU D1 goto BORRAR
if %ACCI% EQU D2 goto BORRAR2 

:COPIA1 
    copy  E:\naiguata\TDD\Entrada\!ARCH! E:\NAIGUATA\!ARCH!
    IF ERRORLEVEL 1 goto :EOFE
    goto :eof    

:COPIA2 
    copy  E:\naiguata\TDD\Entrada\!ARCH! E:\naiguata\TDD\Entrada\RESPALDO\!ARCH!
    IF ERRORLEVEL 1 goto :EOFE
    goto :eof

:BORRAR 
    del  E:\naiguata\TDD\Entrada\!ARCH!
    del  E:\naiguata\!ARCH!
    IF ERRORLEVEL 1 goto :EOFE
    goto :eof
    
:BORRAR2 
    del  E:\naiguata\!ARCH!
    IF ERRORLEVEL 1 goto :EOFE
    goto :eof

:eofe
exit 1

:eof
exit 0




