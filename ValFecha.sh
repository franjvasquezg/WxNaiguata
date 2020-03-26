#!/bin/ksh
################################################################################
gNomScript="ValFecha.sh"
gVerScript=1.00; export VerScript
gUltModScript="20040113"; export UltModScript
################################################################################

################################################################################
##
##        Nombre del Script : ValFecha.sh
##                  Version : 1.00
##                    Autor : MRA/SSM
##                   Codigo : 13/01/2004
##      Ultima Modificacion : 13/01/2004
##  Nombre del Script en PC : ValFecha.sh
##
##                Proposito : Validar una Fecha de Formato AAAAMMDD
##
##     Ejemplo de Ejecucion : ValFecha.sh 20040113
##
################################################################################

################################################################################
##  Modificaciones :
################################################################################
##     Fecha        Autor      Funcion       Cambios
################################################################################
##     13/01/2004   MRA/SSM                  Version Original (1.0)
################################################################################

################################################################################
## DECLARACION DE PARAMETROS
################################################################################

pFecha="$1"

################################################################################
## PROCEDIMIENTO PRINCIPAL
################################################################################

   # Validacion de valor numerico

   /usr/sadm/bin/valrange "$pFecha" > /dev/null 2> /dev/null
   vRet=$?
   if [  $vRet != 0 ]; then
      # echo " ERROR: La Fecha debe contener solo NUMEROS."
      exit 1
   fi

   # Validacion de longitud

   if [ ${#pFecha} != 8 ]; then
      # echo " ERROR: La Fecha debe tener como formato AAAAMMDD"
      exit 1
   fi

   # Identificacion de valores

   typeset -i anio mes dia bis
   anio=`echo "$pFecha" | awk '{print substr($0,1,4)}'`
   mes=`echo "$pFecha" | awk '{print substr($0,5,2)}'`
   dia=`echo "$pFecha" | awk '{print substr($0,7,2)}'`

   # Validacion de Anio

   if [ $anio -lt 1980 ] || [ $anio -gt 2040 ]; then
      # echo " ERROR: Fecha Incorrecta"
      exit 1
   fi
   bis=`expr $anio % 4`

   # Validacion de Mes

   if [ $mes -lt 1 ] || [ $mes -gt 12 ]; then
      # echo " ERROR: Fecha Incorrecta"
      exit 1
   fi

   # Validacion de Dia

   case $mes in
      1|3|5|7|8|10|12)
         if [ $dia -lt 1 ] || [ $dia -gt 31 ]; then
            # echo " ERROR: Fecha Incorrecta"
            exit 1
         fi;;
      4|6|9|10)
         if [ $dia -lt 1 ] || [ $dia -gt 30 ]; then
            # echo " ERROR: Fecha Incorrecta"
            exit 1
         fi;;
      2)
         if [ $bis = 0 ]; then
            if [ $dia -lt 1 ] || [ $dia -gt 29 ]; then
               # echo " ERROR: Fecha Incorrecta"
               exit 1
            fi
         else
            if [ $dia -lt 1 ] || [ $dia -gt 28 ]; then
               # echo " ERROR: Fecha Incorrecta"
               exit 1
            fi
         fi;;
   esac
