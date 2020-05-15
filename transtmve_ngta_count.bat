@ECHO OFF
setlocal EnableDelayedExpansion

rem set ARCH=SWCHD363NA_0313_0502_0_087
set ARCH=%1 

set count=0
for %%x in (E:\NAIGUATA\TDD\Entrada\!ARCH!) do set /a count+=1
rem echo "0 no hay ninguno, 1 solo por omision, 2 o mas de uno"

IF EXIST "E:\NAIGUATA\TDD\Entrada\!ARCH!" (
  set ex=1
  echo !ex!!count! > E:\NAIGUATA\SWCHDcount
  exit 0
) ELSE (
  set ex=0
  echo !ex!!count! > E:\NAIGUATA\SWCHDcount
  exit 0
)

