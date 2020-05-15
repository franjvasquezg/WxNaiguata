#!/bin/ksh 

################################################################################
##
##  Nombre del Programa : SGCPINCMCADQmenu_ngta.sh
##                Autor : SSM
##       Codigo Inicial : 11/01/2008
##          Descripcion : Menu de Incoming de MasterCard
##
##  ======================== Registro de Modificaciones ========================
##
##  Fecha      Autor Version Descripcion de la Modificacion
##  ---------- ----- ------- ---------------------------------------------------
##  11/01/2008 SSM   1.00    Codigo Inicial
##  25/03/2008 SSM   1.50    Mostrar codigo de ambiente
##  26/05/2008 JMG   2.00    Cambio de Fecha Carga por Fecha Proceso
##  06/03/2013 DCB   2.50    Modificacion para Automatizar Incoming
##  03/02/2020 FJV   3.00    Incoming Naiguata IPR 1302
##  13/05/2020 FJV   3.40    Ajustes 464 y SWCHD-461 Incoming Naiguata IPR 1302
##
################################################################################

################################################################################
## DECLARACION DE DATOS, PARAMETROS DE EJECUCION Y VARIABLES DEL PROGRAMA
################################################################################


## Datos del Programa
################################################################################

dpNom="SGCPINCMCADQmenu_ngta"      # Nombre del Programa
dpDesc=""                     # Descripcion del Programa
dpVer=3.40                    # Ultima Version del Programa
dpFec="20200513"              # Fecha de Ultima Actualizacion [Formato:AAAAMMDD]

## Variables del Programa
################################################################################

vpValRet=""                   # Valor de Retorno (funciones)
vpFH=`date '+%Y%m%d%H%M%S'`   # Fecha y Hora [Formato:AAAAMMDDHHMMSS]
vpFileLOG=""                  # Nombre del Archivo LOG del Programa


## Parametros
################################################################################

pEntAdq="$1"                  # Entidad Adquirente [BM/BP/TODOS]
pFecProc="$2"                 # Fecha de Proceso [Formato:AAAAMMDD]
pFecSes="$3"


## Variables de Trabajo
################################################################################

vFileCTL=""                   # Archivo de Control del Proceso
vNumSec=""                    # Numero de Secuencia
vOpcRepro=""                  # Opcion de Reproceso
vCTAMC=""                     # Codigo de Tipo de Archivo de MasterCard


################################################################################
## DECLARACION DE FUNCIONES
################################################################################


# f_msg | muestra mensaje en pantalla
# Parametros
#   pMsg    : mensaje a mostrar
#   pRegLOG : registra mensaje en el LOG del Proceso [S=Si(default)/N=No]
################################################################################
f_msg ()
{
pMsg="$1"
pRegLOG="$2"
if [ "${pMsg}" = "" ]; then
   echo
   if [ "${vpFileLOG}" != "" ]; then
      echo >> ${vpFileLOG}
   fi
else
   echo "${pMsg}"
   if [ "${vpFileLOG}" != "" ]; then
      if [ "${pRegLOG}" = "S" ] || [ "${pRegLOG}" = "" ]; then
         echo "${pMsg}" >> ${vpFileLOG}
      fi
   fi
fi
}


# f_fhmsg | muestra mensaje con la fecha y hora del sistema
# Parametros
#   pMsg    : mensaje a mostrar
#   pFlgFH  : muestra fecha y hora [S=Si(default)/N=No]
#   pRegLOG : registra mensaje en el LOG del Proceso [S=Si(default)/N=No]
################################################################################
f_fhmsg ()
{
pMsg="$1"
pFlgFH="$2"
pRegLOG="$3"
if [ "$pMsg" = "" ]; then
   f_msg
else
   if [ "$pFlgFH" = "S" ] || [ "$pFlgFH" = "" ]; then
      pMsg="`date '+%H:%M:%S'` > ${pMsg}"
   else
      pMsg="         > ${pMsg}"
   fi
   f_msg "${pMsg}" ${pRegLOG}
fi
}

# f_msgtit | muestra mensaje de titulo
# Parametros
#   pTipo : tipo de mensaje de titulo [I=Inicio/F=Fin OK/E=Fin Error]
################################################################################
f_msgtit ()
{
pTipo="$1"
#Tswchd="$2"
if [ "${dpDesc}" = "" ]; then
   vMsg="${dpNom}"
else
   vMsg="${dpNom} - ${dpDesc}"
fi
if [ "${pTipo}" = "I" ]; then
   vMsg="INICIO | ${vMsg} - Transferencia Archivo T464"  #Reporte SWCHD${Tswchd}"
elif [ "${pTipo}" = "F" ]; then
     vMsg="FIN OK | ${vMsg}"
elif [ "${pTipo}" = "OKF" ]; then
     vMsg="FIN OK | ${vMsg}"
else
   vMsg="FIN ERROR | ${vMsg}"
fi
vMsg="\n\
********************************************************** [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]
 ${vMsg}\n\
********************************************************************************"
#\n\
#"
f_msg "${vMsg}" S
if [ "${pTipo}" = "E" ]; then
   exit 1;
elif [ "${pTipo}" = "F" ]; then
   exit 0;
fi
}

# f_msgtit | muestra mensaje de titulo Naiguata
# Parametros
#   pTipo : tipo de mensaje de titulo [I=Inicio/F=Fin OK/E=Fin Error]
################################################################################
f_msgtit2 ()
{
pTipo="$1"
Tswchd="$2"
if [ "${dpDesc}" = "" ]; then
   vMsg="${dpNom}"
else
   vMsg="${dpNom} - ${dpDesc}"
fi
if [ "${pTipo}" = "I" ]; then
   vMsg="INICIO | ${vMsg} - Reporte SWCHD${Tswchd}"
elif [ "${pTipo}" = "F" ]; then
     vMsg="FIN OK | ${vMsg}"
else
   vMsg="FIN ERROR | ${vMsg}"
fi
vMsg="\n\
********************************************************** [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]
 ${vMsg}\n\
********************************************************************************"
#\n\
#"
f_msg "${vMsg}" S
if [ "${pTipo}" = "E" ]; then
   exit 1;
elif [ "${pTipo}" = "F" ]; then
   exit 0;
fi
}

# f_fechora | cambia el formato de la fecha y hora
#             YYYYMMDD > DD/MM/YYYY
#             HHMMSS > HH:MM:SS
#             YYYYMMDDHHMMSS > DD/MM/YYYY HH:MM:SS
# Parametros
#   pFH : fecha/hora
################################################################################
f_fechora ()
{
pFH="$1"
vLong=`echo ${pFH} | awk '{print length($0)}'`
case ${vLong} in
     8)  # Fecha
         vDia=`echo $pFH | awk '{print substr($0,7,2)}'`
         vMes=`echo $pFH | awk '{print substr($0,5,2)}'`
         vAno=`echo $pFH | awk '{print substr($0,1,4)}'`
         vpValRet="${vDia}/${vMes}/${vAno}";;
     6)  # Hora
         vHra=`echo $pFH | awk '{print substr($0,1,2)}'`
         vMin=`echo $pFH | awk '{print substr($0,3,2)}'`
         vSeg=`echo $pFH | awk '{print substr($0,5,2)}'`
         vpValRet="${vHra}:${vMin}:${vSeg}";;
     14) # Fecha y Hora
         vDia=`echo $pFH | awk '{print substr($0,7,2)}'`
         vMes=`echo $pFH | awk '{print substr($0,5,2)}'`
         vAno=`echo $pFH | awk '{print substr($0,1,4)}'`
         vHra=`echo $pFH | awk '{print substr($0,9,2)}'`
         vMin=`echo $pFH | awk '{print substr($0,11,2)}'`
         vSeg=`echo $pFH | awk '{print substr($0,13,2)}'`
         vpValRet="${vDia}/${vMes}/${vAno} ${vHra}:${vMin}:${vSeg}";;
esac
}


# f_menuCAB () | administra el Archivo de Control (lee/escribe)
################################################################################
f_menuCAB ()
{

   clear
   echo "*******************************************************************************"
   echo "*                       SISTEMA DE GESTION DE COMERCIOS                  ${COD_AMBIENTE} *"
   if [ "$pEntAdq" = "BM" ]; then
      echo "*         Incoming de Naiguata MasterCard (Banco Mercantil)                   *"
   elif [ "$pEntAdq" = "BP" ]; then
        echo "*         Incoming de Naiguata MasterCard (Banco Provincial)                  *"
   elif [ "$pEntAdq" = "TODOS" ]; then
        echo "*         Incoming de Naiguata MasterCard (GENERAL)                           *"
   fi
   echo "*******************************************************************************"

}


# f_menuDAT () | menu de informacion
################################################################################
f_menuDAT ()
{

   if [ "$vOpcRepro" = "S" ]; then
      vRepro="SI"
   else
      vRepro="NO"
   fi

   f_fechora ${vFecProc}
   vFecProcF=${vpValRet}
   echo " Fecha de Proceso: ${vFecProcF}                                   Reproceso: $vRepro"

}


# f_getCTAMC () | codigo de tipo de archivo
################################################################################
f_getCTAMC ()
{

pTipo="$1"

#if [ "${pTipo}" = "TC" ]; then
#   vpValRet=`echo $COD_TIPOARCHMC | awk '{print substr($0,1,3)}'`
#elif [ "${pTipo}" = "BINESD" ]; then
#     vpValRet=`echo $COD_TIPOARCHMC | awk '{print substr($0,4,3)}'`
#elif [ "${pTipo}" = "BINESE" ]; then
#     vpValRet=`echo $COD_TIPOARCHMC | awk '{print substr($0,7,3)}'`
if [ "${pTipo}" = "INCOMING" ]; then
     vpValRet=`echo $COD_TIPOARCHMC_NGTA | awk '{print substr($0,1,3)}'`
elif [ "${pTipo}" = "INCRET" ]; then
     vpValRet=`echo $COD_TIPOARCHMC_NGTA | awk '{print substr($0,4,3)}'`
elif [ "${pTipo}" = "INCMATCH" ]; then
     vpValRet=`echo $COD_TIPOARCHMC_NGTA | awk '{print substr($0,7,3)}'`
elif [ "${pTipo}" = "INCMAESTRONGTA" ]; then
     vpValRet=`echo $COD_TIPOARCHMC_NGTA | awk '{print substr($0,10,3)}'`
elif [ "${pTipo}" = "REPCREDMC" ]; then
     vpValRet=`echo $COD_TIPOARCHMC_NGTA | awk '{print substr($0,13,3)}'`
elif [ "${pTipo}" = "REPDEBMAESTRO" ]; then
     vpValRet=`echo $COD_TIPOARCHMC_NGTA | awk '{print substr($0,16,3)}'`
elif [ "${pTipo}" = "REPDEBMAESTROSW" ]; then
     vpValRet=`echo $COD_TIPOARCHMC_NGTA | awk '{print substr($0,19,5)}'`
fi

}


# f_menuOPC () | menu de opciones
################################################################################
f_menuOPC ()
{

   #f_getCTAMC BINESD
   #vpValRet_1=${vpValRet}
   #f_getCTAMC TC
   #vpValRet_2=${vpValRet}
   f_getCTAMC INCOMING
   vpValRet_3=${vpValRet}
   f_getCTAMC INCRET
   vpValRet_4=${vpValRet}
   f_getCTAMC INCMATCH
   vpValRet_5=${vpValRet}
   f_getCTAMC INCMAESTRONGTA
   vpValRet_6=${vpValRet}
   #f_getCTAMC BINESE
   #vpValRet_7=${vpValRet}
   f_getCTAMC REPCREDMC
   vpValRet_8=${vpValRet}
   f_getCTAMC REPDEBMAESTRO
   vpValRet_9=${vpValRet}
   f_getCTAMC REPDEBMAESTROSW
   vpValRet_10=${vpValRet}

   echo "-------------------------------------------------------------------------------"
   echo "CARGA DE ENTRANTES                           REPORTES"
   echo "-----------------------------------------    ----------------------------------"

   echo "[ 1] INC NGTA Debito Maestro (T${vpValRet_6}NA)        [ 5] Debito NGTA Maestro (${vpValRet_10})"
   echo "[ 2] INC y Retornos NGTA Credito (${vpValRet_3}-${vpValRet_4})   [ 6] Credito MC (${vpValRet_8})"
   ## La Carga de Bines y Tipos de Cambio Es omitido para NAIGUATA
   echo
   echo "                                             CONSULTAS"
   echo "                                             ----------------------------------"
   echo "                                             [ 7] Log de Procesos"
   echo ""
   echo "                                             REPROCESO"
   echo "                                             ----------------------------------"
   echo "                                             [ 8] Reproceso"
   echo
   echo "-------------------------------------------------------------------------------"
   echo " Ver $dpVer | Telefonica Servicios Transaccionales                  [Q] Salir"
   echo "-------------------------------------------------------------------------------"

}

find_footer ()
{
fT464="$1"
for sec in 1 251 501 751
do
    pie=`awk -F '/FTRL/' ${DIRIN}/${fT464} | awk '{print substr($0,'${sec}',250)}' | grep -i 'FTRL' | grep -v 'STRL' | awk '{print substr($0,0,4)}'`
    if [ "${pie}" = "FTRL" ]; then
     vFOOTER=${pie}
    fi
done
}

################################################################################
## INICIO | PROCEDIMIENTO PRINCIPAL
################################################################################

echo


## Entidad Adquirente
################################################################################

if [ "$pEntAdq" = "BM" ]; then
   vEntidad="BANCO MERCANTIL"
elif [ "$pEntAdq" = "BP" ]; then
     vEntidad="BANCO PROVINCIAL"
elif [ "$pEntAdq" = "TODOS" ]; then
     vEntidad="GENERAL"
else
     f_msg "Codigo de Entidad Incorrecto [BM/BP/TODOS]"
     f_msg
     exit 1;
fi


## Fecha de Proceso
################################################################################

if [ "${pFecProc}" = "" ]; then
   vFecProc=`getdate`
else
   ValFecha.sh ${pFecProc}
   vRet="$?"
   if [ "$vRet" != "0" ]; then
      f_msg "Fecha de Proceso Incorrecta (FecProc=${pFecProc})"
      f_msg
      exit 1;
   fi
   vFecProc=${pFecProc}
fi

## Fecha de Sesion
################################################################################

if [ "${pFecSes}" = "" ]; then
   vFecSes=`getdate -1`
else
   ValFecha.sh ${pFecSes}
   vRet="$?"
   if [ "$vRet" != "0" ]; then
      f_msg "Fecha de Sesion Incorrecta (FecProc=${pFecSes})"
      f_msg
      exit 1;
   fi
   vFecSes=${pFecSes}
fi


## Opcion de Reproceso
################################################################################

vOpcRepro="N"


## Archivo de Control
################################################################################

while ( test -z "$vOpcion" || true ) do

   #vFileBINESD="SGCPINCMC${pEntAdq}.BINESD.${vFecProc}"
   #vFileBINESE="SGCPINCMC${pEntAdq}.BINESE.${vFecProc}"
   #vFileTC="SGCPINCMC${pEntAdq}.TC.${vFecProc}"
   vFileINCOMING="SGCPINCMC${pEntAdq}.INCOMINGMC.${vFecProc}"
   vFileINCRET="SGCPINCMC${pEntAdq}.INCRET.${vFecProc}"
   vFileINCMATCH="SGCPINCMC${pEntAdq}.INCMATCH.${vFecProc}"
   vFileINCMAESTRO="SGCPINCMC${pEntAdq}.INCMAESTRONGTA.${vFecProc}"
   vFileREPCREDMC="SGCPINCMC${pEntAdq}.REPCREDMC.${vFecProc}"
   vFileREPDEBMAESTRO="SGCPINCMC${pEntAdq}.REPDEBMAESTRO.${vFecProc}"

   f_menuCAB
   f_menuDAT
   f_menuOPC

   if [ "${vOpcion}" = "" ]; then
      echo
      echo "   Seleccione Opcion => \c"
      read vOpcion
      if [ "$vOpcion" = "q" ] || [ "$vOpcion" = "Q" ]; then
         echo
         exit 0
      fi
   fi

   vFlgOpcErr="S"

   if [ "$vOpcion" = "" ]; then
      # Vuelve a mostrar el menu
      vFlgOpcErr="N"
   fi


   # CARGA DE INCOMING DEBITO NAIGUATA MAESTRO
   ###########################################################################################
   #  INICIO OPCION "TODOS"
   ###########################################################################################

   if [ "$vOpcion" = "1" ]; then

      vFlgOpcErr="N"
      vOpcion=""

      # Verifica el Estado del Proceso en el Archivo de Control

      #vFileCTL="${DIRDAT}/${vFileINCMAESTRO}.CTL"
      # vEstProc=`awk '{print substr($0,13,1)}' $vFileCTL`

      # Confirmacion de Ejecucion
      if [ "$vOpcRepro" = "S" ]; then
         f_msg
         f_msg "--------------------------------------------------------------------------------" N S
         f_msg " CONFIRMACION DE REPROCESO" N S
         f_msg "--------------------------------------------------------------------------------" N S
         f_msg
         f_msg " El REPROCESO puede involucrar la ejecucion de acciones adicionales para" N S
         f_msg " realizar correctamente la REVERSION de la ejecucion anterior, por lo que" N S
         f_msg " puede ser NECESARIA una AUTORIZACION por parte del ADMINISTRADOR DEL SISTEMA." N S
      else
         f_msg
         f_msg "--------------------------------------------------------------------------------" N S
         f_msg " CONFIRMACION DE EJECUCION DE PROCESO" N S
         f_msg "--------------------------------------------------------------------------------" N S
      fi
      f_msg
      f_msg " Proceso: CARGA DE INCOMING NAIGUATA DEBITO MAESTRO" N S
      f_msg
      f_msg
      f_fechora $vFecProc
      f_msg "    Fecha de Proceso: $vpValRet" N S
      f_msg
      echo " Desea Continuar? (S=Si/N=No/<Enter>=No) => \c"
      read ValConf
      f_msg

      if [ "$ValConf" = "s" ] || [ "$ValConf" = "S" ]
      then
         case $COD_AMBIENTE in
            DESA)
              COD_AMBIENTEm="ccal"
              vPrefijo="/TDD/Entrada"
              vPrefijo_Res="/TDD/Entrada/Respaldo";;
            CCAL)
              COD_AMBIENTEm="ccal"
              vPrefijo="/TDD/Entrada"
              vPrefijo_Res="/TDD/Entrada/Respaldo";;
            PROD)
              COD_AMBIENTEm="prod"
              vPrefijo="/TDD/Entrada"
              vPrefijo_Res="/TDD/Entrada/Respaldo";;
         esac
         ## Se carga las variable para todos las opciones TODOS ó BP & BM Independiente 
         ## Ibteniendo Fecha Juliana MENOS 1 
         vFecJul=`dayofyear ${vFecProc}`    
         vFecJul=`expr ${vFecJul} - 1`      #Ajuste T464NA Este archivo es del dia de AYER ipr1302 
         vFecJul=`printf "%03d" $vFecJul`   #Ajuste T464NA Este archivo es del dia de AYER ipr1302 

         ## Corresponde al último dígito del año al que corresponde el bulk, 
         ## Es decir, el cero corresponde al año 2020 para el año venidero el valor deberá ser 1.
         vNomFile_SecA=`echo ${vFecProc} | awk '{print substr($0,4,1)}'`

         if [ "$pEntAdq" = "TODOS" ] 
         then
            stty intr 
            vADQIDX=0
            f_fechora $vFecProc
            ##vFecArch="$vAno-$vMes-$vDia"

            for vEntAdq in BM BP
            do
              case $vEntAdq in
                 BM)
                   vEntAdqm=bm
                   vEndPoint=0275;;
                 BP)
                   vEntAdqm=bp
                   vEndPoint=0313;;
              esac
              vFileINCMAESTRO="SGCPINCMC${vEntAdq}.INCMAESTRONGTA.${vFecProc}"
              vFileCTL="${DIRDAT}/${vFileINCMAESTRO}.CTL"
              vEstProc=`awk '{print substr($0,13,1)}' $vFileCTL 2>/dev/null`
              if [ "$vEstProc" = "F" ] && [ "$vOpcRepro" != "S" ]
              then
                 tput setf 8
                 echo "el Incoming de Debito Maestro Naiguata para este dia ya ha sido procesado"
                 tput setf 7
                 echo " "
                 continue
              fi
              vFileLOG="${DIRLOG}/${vFileINCMAESTRO}.`date '+%Y%m%d%H%M%S'`.LOG"
              vFileLOG1="${DIRLOG}/${vFileINCMAESTRO}.`date '+%Y%m%d%H%M%S'`.LOG.tmp"
              if [ -f "$vFileLOG" ]; then
                 rm -f $vFileLOG
              fi
              if [ -f "$vFileLOG1" ]; then
                 rm -f $vFileLOG1
              fi
              touch $vFileLOG
              touch $vFileLOG1
              ###########################################################################################
              #  INICIO BUSQUEDA DE ARCHIVOS EN SERVIDOR NAIGUATA
              ###########################################################################################

              echo "cd $vPrefijo/" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
              echo "ls T${vpValRet_6}"NA"_${vEndPoint}_"0502"_${vNomFile_SecA}_${vFecJul}*" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
              vARCHINC[$vADQIDX]=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\> | wc -l`
              if [ "${vARCHINC[$vADQIDX]}" -lt "1" ]
              then
                 tput setf 8
                 echo "No existe el Archivo de Incoming Debito Naiguata Maestro para el Adquiriente $vEntAdq"| tee -a $vFileLOG
                 tput setf 7
                 sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Archivo_de_Debito_NAiguata_Maestro_Adquiriente_$vEntAdq_No_Existe"
              fi
              if [ "${vARCHINC[$vADQIDX]}" -gt "1" ]
              then
                 tput setf 8
                 echo "Existe mas de Un Archivo de Incoming Debito Maestro Naiguata para el Adquiriente $vEntAdq, favor revisar" | tee -a $vFileLOG
                 tput setf 7
                 sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Numero_Incorrecto_de_Archivos_de_Debito_Naiguata_Maestro_Adquiriente_$vEntAdq_No_Existe"
              fi
              if [ "${vARCHINC[$vADQIDX]}" -eq "1" ]
              then
                 echo
                 f_msgtit I 
                 echo                                 
                 echo "Transferencia de archivos desde el servidor MQFTE de Naiguata" >> $vFileLOG 2>&1
                 f_fhmsg "Transferencia de archivos desde el servidor MQFTE de Naiguata"
                 #echo
                 vARCHINC[$vADQIDX]=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\>`
                 #vNumSec=`echo ${vARCHINC[$vADQIDX]} | cut -d. -f3`
                 #vNumSec=`printf "%02d" $vNumSec`
                 #vArchDest="${vpValRet_6}${vEndPoint}_${vFecJul}_${vNumSec}_conv"
                 vArchDest="T${vpValRet_6}"NA"_${vEndPoint}_"0502"_${vNomFile_SecA}_${vFecJul}"
                 vArchDest_conv="T${vpValRet_6}"NA"_${vEndPoint}_"0502"_${vNomFile_SecA}_${vFecJul}_conv"
                 echo "cd $vPrefijo/" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                 echo "get ${vARCHINC[$vADQIDX]} $DIRIN/$vArchDest" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                 sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} | grep -v Fetching >> $vFileLOG 2>&1
                 vSTATT=$?
                 if [ "$vSTATT" != "0" ]
                 then
                    tput setf 8
                    echo "error en la transferencia del archivo Ngta ${vARCHINC[$vADQIDX]}, favor revisar" >> $vFileLOG 2>&1
                    f_fhmsg "error en la transferencia del archivo Ngta ${vARCHINC[$vADQIDX]}, favor revisar"
                    tput setf 7
                    sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Error_Transferencia_de_Archivo_${vARCHINC[$vADQIDX]}_Adquiriente_$vEntAdq - ${vEndPoint}"
                 else  
                    #echo 
                    echo "Archivo ${vArchDest} Transferido Correctamente" >> $vFileLOG 2>&1
                    f_fhmsg "Archivo ${vArchDest} Transferido Correctamente" 
                    #echo                    
                    echo "Moviendo archivos ${vArchDest} a Respaldo" >> $vFileLOG 2>&1
                    f_fhmsg "Moviendo archivos ${vArchDest} a Respaldo"
                    echo "rm ${vPrefijo_Res}/${vARCHINC[$vADQIDX]}" > $DIRTMP/$dpNom$vFecProc.PARRM.SFTP
                    sftp -b $DIRTMP/$dpNom$vFecProc.PARRM.SFTP ${SFTP_USER}@$SFTP_IMC_NGTA} >> $vFileLOG 2>&1
                    #echo $?
                    #echo
                    echo "rename ${vPrefijo}/${vArchDest} ${vPrefijo_Res}/${vArchDest}" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                    sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} >> $vFileLOG 2>&1
                    #echo $?
                    #echo               
                    ###echo "Eliminando Archivo en servidor MQFTE de Naiguata" >> $vFileLOG 2>&1
                    ###f_fhmsg "Eliminando Archivo en servidor MQFTE de Naiguata"
                    #echo 
                    #echo "Eliminando Archivo ${vARCHINC[$vADQIDX]} - en - ${vPrefijo} en Servidor MQFTE" >> $vFileLOG 2>&1
                    #f_fhmsg "Eliminando Archivo ${vARCHINC[$vADQIDX]}"
                    #f_fhmsg " - En - ${vPrefijo} en Servidor MQFTE"
                    #echo "rm $vPrefijo/${vARCHINC[$vADQIDX]}" > $DIRTMP/$dpNom$vFecProc.PARRM.SFTP
                    #sftp -b $DIRTMP/$dpNom$vFecProc.PARRM.SFTP ${SFTP_USER}@$SFTP_IMC_NGTA} >> $vFileLOG 2>&1
                    #echo $?
                    #echo                                
                    echo "Analizando los datos el Archivo original de 1000 byte" >> $vFileLOG 2>&1
                    f_fhmsg "Analizando los datos el Archivo original de 1000 byte"
                    #echo
                    echo "Analisis archivo ${vArchDest}" >> $vFileLOG 2>&1
                    echo "Analisis ${vArchDest} Encabezado y Fin de Archivo" >> $vFileLOG 2>&1
                    f_fhmsg "Analisis ${vArchDest} Encabezado y Fin de Archivo"
                    #echo
                    vENCABEZADO=`head -1 $DIRIN/$vArchDest | awk '{print substr($0,0,4)}'`
                    # Buscar el footer y lo almacena en la variable --> vFOOTER
                    find_footer $vArchDest           

                    if [ "$vENCABEZADO" = "FHDR" ] && [ "$vFOOTER" = "FTRL" ]
                    then
                       echo "Verificacion de Encabezado y Fin de Archivo Completada - OK" >> $vFileLOG 2>&1
                       f_fhmsg "Verificacion de Encabezado y Fin de Archivo Completada - OK"
                       vCONSIST=1
                    else
                       tput setf 8
                       echo "Verificacion de Encabezado y Fin de Archivo Fallida" >> $vFileLOG 2>&1
                       f_fhmsg "Verificacion de Encabezado y Fin de Archivo Fallida"
                       tput setf 7
                       sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Error_Consistencia_de_Archivo_${vARCHINC[$vADQIDX]}_Adquiriente_$vEntAdq - ${vEndPoint}"
                       vCONSIST=0
                    fi
                 fi
              
               #  PROCESAMIENTO Y CARGA EN BD DE ARCHIVOS T464NA  NAIGUATA
				 
                 if [ "$vCONSIST" = "0" ]
                 then
                       tput setf 8
                       #echo
                       echo "Archivo original de 1000 byte NO contiene datos" >> $vFileLOG 2>&1
                       f_fhmsg "Archivo original de 1000 byte NO contiene datos"                     
                       echo "No se Procesara el Archivo ${vArchDest}" | tee -a $vFileLOG
                       tput setf 7
                       sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Archivo_${vARCHINC[$vADQIDX]}_Adquiriente_${vEndPoint}_$vEntAdq_No_Procesado"
                 else
                     #echo
                     echo "Archivo original de 1000 byte SI contiene datos" >> $vFileLOG 2>&1
                     f_fhmsg "Archivo original de 1000 byte SI contiene datos"
                     #echo
                     echo "Convirtiendo archivos T464NA de 1000 bytes a 250 bytes" >> $vFileLOG 2>&1  #IPR1302 18032020
                     f_fhmsg "Convirtiendo archivos T464NA de 1000 bytes a 250 bytes"
                     #echo
                     trap "trap '' 2" 2
                     ${DIRBIN}/conver_NGTA_T464NA.sh $vArchDest
                     ###trap ""               #En caso que falle IPR1302 fjvg 25082020
                     #echo " "
                     echo "Carga Archivo ${vArchDest} en base de datos" >> $vFileLOG 2>&1
                     f_fhmsg "Carga Archivo ${vArchDest} en base de datos"
                     echo
                     #f_fhmsg "En tabla Temp Conciliacion y Compensacion Naiguata respectivamente"
                     f_msg "--------------------------------------------------------------------------------" N S
                     f_msg
                     echo
                     echo "         Archivo de Control : `basename ${vFileCTL}`"
                     echo "                 Directorio : `dirname ${vFileCTL}`"
                     echo "           LOG de Ejecucion : `basename ${vFileLOG}`"
                     echo "                 Directorio : `dirname ${vFileLOG}`"
                     echo "    Archivo LOG del Proceso : ${vFileINCMAESTRO}.LOG"
                     echo "                 Directorio : ${DIRLOG}"
                     echo
                     ${DIRBIN}/SGCPINCMCADQproc.sh ${vEntAdq} ${vFecProc} INCMAESTRONGTA ${vOpcRepro} S 1>>${vFileLOG1} 2>&1
                     vPROCSTAT=$?
                     cat $vFileLOG1 | grep -v 'PRESIONE' | grep -v 'presione' | tee -a $vFileLOG
                     rm $vFileLOG1
                     if [ "$vPROCSTAT" -eq "0" ]
                        then
                        #Se envía transferencia al XCOM del archivo convertido - Retomado en el IPR 1156 Fase IV
                        f_fhmsg "Se envia archivo T464NA a platino2 (X4200)" >> $vFileLOG 2>&1
                        f_fhmsg "Se envia archivo T464NA a platino2 (X4200)"
                        scp -Bq $DIRIN/$vArchDest $SSSH_USER@$FTP_HOSTXCOM:/file_transfer/${COD_AMBIENTEm}/${vEntAdqm}/file_out
                        vSTATT=$?
                        if [ "$vSTATT" != "0" ]
                           then
                              tput setf 8
                              echo "Error en la transferencia del archivo $vArchDest del adquiriente $vEntAdq al area de acceso de los Bancos, favor revisar" | tee -a $vFileLOG
                              tput setf 7
                              sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Error_Transferencia_de_Archivo_$vArchDest_Adquiriente_$vEntAdq"
                        else
                           #echo
                           echo "Archivo Naiguata Transferido al area de acceso de los Bancos" >> $vFileLOG 2>&1
                           f_fhmsg "Archivo Naiguata Transferido al area de acceso de los Bancos"
                        fi  ####Fin de la modificación GlobalR IPR1156
                        #echo
                        echo "Proceso de carga T464NA Finalizado creardo Backup de Archivo" >> $vFileLOG 2>&1
                        f_fhmsg "Proceso de carga T464NA Finalizado creardo Backup de Archivo"
                        echo "Creardo Backup de Archivo T464NA" >> $vFileLOG 2>&1
                        f_fhmsg "Creardo Backup de Archivo T464NA"
                        mv $DIRIN/$vArchDest $DIRIN/${vArchDest}_bkp
                        mv $DIRIN/$vArchDest_conv $DIRIN/${vArchDest_conv}_bkp
                        #echo
                        echo "Backup de Archivo T464NA Realizado" >> $vFileLOG 2>&1
                        f_fhmsg "Backup de Archivo T464NA Realizado"
                        f_msgtit OKF
                        echo
                     fi
                 fi
              fi
              vADQIDX=`expr $vADQIDX + 1`
            done
            rm $DIRTMP/$dpNom$vFecProc.PAR.SFTP 2>/dev/null
            rm $DIRTMP/$dpNom$vFecProc.PARRM.SFTP 2>/dev/null
            rm $DIRIN/$vArchDest 2>/dev/null                 #Nos aseguramos que ya no esta disponible
            rm $DIRIN/$vArchDest_conv 2>/dev/null
            DUMMY=0
            while [ "$DUMMY" != "Q" ] && [ "$DUMMY" != "q" ]
            do
               echo "Oprima Q o q <ENTER> para volver al Menu \c"
               read DUMMY
            done
            stty intr 
         else         ## INICIO OPCION POR ADQUIRIENTES MAESTRO NAIGATA
            stty intr 
            case $pEntAdq in
               BM)
                 pEntAdqm=bm
                 vEndPoint=0275;;
               BP)
                 pEntAdqm=bp
                 vEndPoint=0313;;
            esac
            f_fechora $vFecProc
            ## Se carga las variable para todos las opciones TODOS ó BP & BM Independiente 
            ## Ibteniendo Fecha Juliana MENOS 1 
            vFecJul=`dayofyear ${vFecProc}`    
            vFecJul=`expr ${vFecJul} - 1`      #Ajuste T464NA Este archivo es del dia de AYER ipr1302 
            vFecJul=`printf "%03d" $vFecJul`   #Ajuste T464NA Este archivo es del dia de AYER ipr1302 

            ## Corresponde al último dígito del año al que corresponde el bulk, 
            ## Es decir, el cero corresponde al año 2020 para el año venidero el valor deberá ser 1.
            vNomFile_SecA=`echo ${vFecProc} | awk '{print substr($0,4,1)}'`

            #vFecArch="$vAno-$vMes-$vDia"
            vFileINCMAESTRO="SGCPINCMC${pEntAdq}.INCMAESTRONGTA.${vFecProc}"
            vFileCTL="${DIRDAT}/${vFileINCMAESTRO}.CTL"
            vFileLOG="${DIRLOG}/${vFileINCMAESTRO}.`date '+%Y%m%d%H%M%S'`.LOG"
            vFileLOG1="${DIRLOG}/${vFileINCMAESTRO}.`date '+%Y%m%d%H%M%S'`.LOG.tmp"
            vEstProc=`awk '{print substr($0,13,1)}' $vFileCTL 2>/dev/null`
            if [ "$vEstProc" = "F" ] && [ "$vOpcRepro" != "S" ]
            then
               tput setf 8
               echo "el Incoming de Debito Naiguata Maestro para este dia ya ha sido procesado"
               tput setf 7
               echo " "
            else
               if [ -f "$vFileLOG" ]; then
                  rm -f $vFileLOG
               fi
               if [ -f "$vFileLOG1" ]; then
                  rm -f $vFileLOG1
               fi
               touch $vFileLOG
               touch $vFileLOG1
               echo "cd $vPrefijo/" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
               echo "ls T${vpValRet_6}"NA"_${vEndPoint}_"0502"_${vNomFile_SecA}_${vFecJul}*" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
               vARCHINC=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\> | wc -l`
               if [ "$vARCHINC" -lt "1" ]
               then
                  tput setf 8
                  echo "No existe el Archivo de Incoming Debito Naiguata Maestro para el Adquiriente $pEntAdq - ${vEndPoint}" | tee -a $vFileLOG
                  tput setf 7
                  sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Archivo_de_Debito_Maestro_Adquiriente_$pEntAdq_No_Existe"
               fi
               if [ "$vARCHINC" -gt "1" ]
               then
                  tput setf 8
                  echo "Existe mas de Un Archivo de Incoming Debito Naiguata Maestro para el Adquiriente $pEntAdq, favor revisar" | tee -a $vFileLOG
                  tput setf 7
                  sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Numero_Incorrecto_de_Archivos_de_Debito_Naiguata_Maestro_Adquiriente_$pEntAdq_No_Existe"
               fi
               if [ "$vARCHINC" -eq "1" ]
               then
                  echo
                  f_msgtit I  
                  echo                                
                  echo "Transferencia de archivos desde el servidor MQFTE de Naiguata" >> $vFileLOG 2>&1
                  f_fhmsg "Transferencia de archivos desde el servidor MQFTE de Naiguata"
                  #echo
                  vARCHINC=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\>`

                  vArchDest="T${vpValRet_6}"NA"_${vEndPoint}_"0502"_${vNomFile_SecA}_${vFecJul}"
                  vArchDest_conv="T${vpValRet_6}"NA"_${vEndPoint}_"0502"_${vNomFile_SecA}_${vFecJul}_conv"
                  echo "cd $vPrefijo/" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                  echo "get $vARCHINC $DIRIN/$vArchDest" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                  sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} | grep -v Fetching >> $vFileLOG 2>&1
                  vSTATT=$?
                  if [ "$vSTATT" != "0" ]
                  then
                     tput setf 8
                     echo "error en la transferencia del archivo Ngta $vARCHINC, favor revisar" >> $vFileLOG 2>&1
                     f_fhmsg "error en la transferencia del archivo Ngta $vARCHINC, favor revisar" 
                     tput setf 7
                     sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Error_Transferencia_de_Archivo_${vARCHINC}_Adquiriente_$pEntAdq - ${vEndPoint}"
                  else
                    #echo
                    echo "Archivo $vArchDest Transferido Correctamente" >> $vFileLOG 2>&1
                    f_fhmsg "Archivo $vArchDest Transferido Correctamente " 
                    #echo
                    echo "Moviendo archivo $vArchDest a respaldo" >> $vFileLOG 2>&1
                    f_fhmsg "Moviendo archivo $vArchDest a respaldo"
                    echo "rm ${vPrefijo_Res}/${vARCHINC}" > $DIRTMP/$dpNom$vFecProc.PARRM.SFTP
                    sftp -b $DIRTMP/$dpNom$vFecProc.PARRM.SFTP ${SFTP_USER}@$SFTP_IMC_NGTA} >> $vFileLOG 2>&1
                    #echo $?
                    echo
                    echo "rename ${vPrefijo}/${vARCHINC} ${vPrefijo_Res}/${vARCHINC}" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                    sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} >> $vFileLOG 2>&1
                    #echo $?   
                    #echo
                    ###echo "Eliminando Archivo en servidor MQFTE de Naiguata" >> $vFileLOG 2>&1
                    ###f_fhmsg "Eliminando Archivo en servidor MQFTE de Naiguata"
                    #echo
                    echo "Analizando los datos el Archivo original de 1000 byte" >> $vFileLOG 2>&1
                    f_fhmsg "Analizando los datos el Archivo original de 1000 byte"
                    #echo
                    echo "Analisis $vArchDest Encabezado y Fin de Archivo" >> $vFileLOG 2>&1
                    f_fhmsg "Analisis $vArchDest Encabezado y Fin de Archivo"
                    #echo
                    vENCABEZADO=`head -1 $DIRIN/$vArchDest | awk '{print substr($0,0,4)}'`
                    #vFOOTER=`tail -2 $DIRIN/$vArchDest | head -1 | awk '{print substr($0,0,4)}'`
                    find_footer $vArchDest  #FUNCION QUE VALIDA SI TRAE FIN DE ARCHIVO

                    if [ "$vENCABEZADO" = "FHDR" ] && [ "$vFOOTER" = "FTRL" ]
                    then
                       echo "Verificacion de Encabezado y Fin de Archivo Completa - OK" >> $vFileLOG 2>&1
                       f_fhmsg "Verificacion de Encabezado y Fin de Archivo Completa - OK" 
                       vCONSIST=1
                    else
                       tput setf 8
                       echo "Verificacion de Encabezado y Fin de Archivo Fallida" >> $vFileLOG 2>&1
                       f_fhmsg "Verificacion de Encabezado y Fin de Archivo Fallida"
                       tput setf 7
                       sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Error_Consistencia_de_Archivo_${vARCHINC}_Adquiriente_$pEntAdq - ${vEndPoint}"
                       vCONSIST=0
                    fi
                  fi
            
               #  PRECESAMIENTO Y CARGA EN BD DE ARCHIVOS T464NA  NAIGUATA POR ADQUIRIENTE

               if [ "$vCONSIST" = "0" ]
               then
                     tput setf 8
                     #echo
                     echo "Archivo original de 1000 byte NO Trae datos" >> $vFileLOG 2>&1
                     f_fhmsg "Archivo original de 1000 byte NO Trae datos" 
                     echo "No se Procesara el Archivo $vArchDest}" | tee -a $vFileLOG
                     tput setf 7
                     sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Archivo_${vARCHINC}_Adquiriente_${vEndPoint}_$pEntAdq_No_Procesado"
               else
                  #echo
                  echo "Archivo original de 1000 byte SI Trae datos" >> $vFileLOG 2>&1
                  f_fhmsg "Archivo original de 1000 byte SI Trae datos"
                  #echo
                  echo "Convirtiendo archivos T464NA de 1000 bytes a 250 bytes" >> $vFileLOG 2>&1  #IPR1302 18032020
                  f_fhmsg "Convirtiendo archivos T464NA de 1000 bytes a 250 bytes"
                  #echo
                  trap "trap '' 2" 2
                  ${DIRBIN}/conver_NGTA_T464NA.sh $vArchDest
                  #########trap ""                                             #En caso que falle IPR1302 fjvg 25082020
                     #echo " "
                     echo "Carga Archivo ${vArchDest} en base de datos" >> $vFileLOG 2>&1
                     f_fhmsg "Carga Archivo ${vArchDest} en base de datos"
                     echo
                     #f_fhmsg "En tabla temporales Conciliacion y Compensacion Naiguata respectivamente"
                     f_msg "--------------------------------------------------------------------------------" N S
                     f_msg
                     echo
                     echo "         Archivo de Control : `basename ${vFileCTL}`"
                     echo "                 Directorio : `dirname ${vFileCTL}`"
                     echo "           LOG de Ejecucion : `basename ${vFileLOG}`"
                     echo "                 Directorio : `dirname ${vFileLOG}`"
                     echo "    Archivo LOG del Proceso : ${vFileINCMAESTRO}.LOG"
                     echo "                 Directorio : ${DIRLOG}"
                     echo
                     ${DIRBIN}/SGCPINCMCADQproc.sh ${pEntAdq} ${vFecProc} INCMAESTRONGTA ${vOpcRepro} S 1>>${vFileLOG1} 2>&1
                     vPROCSTAT=$?
                     cat $vFileLOG1 | grep -v 'PRESIONE' | grep -v 'presione' | tee -a $vFileLOG
                     rm $vFileLOG1
                     if [ "$vPROCSTAT" -eq "0" ]
                     then
                         #vArchDestB="${vpValRet_6}${vEndPoint}_${vFecJul}_01_conv"
			                #IPR 1156 GlobalR Fase IV se descomenta Elimininado por IPR1156
                         #Se envía transferencia al XCOM del archivo convertido - Retomado en el IPR 1156 Fase IV
                         echo "Se envia archivo T464NA a platino2 (X4200)" >> $vFileLOG 2>&1
                         f_fhmsg "Se envia archivo T464NA a platino2 (X4200)"
                         scp -Bq $DIRIN/$vArchDest $SSSH_USER@$FTP_HOSTXCOM:/file_transfer/${COD_AMBIENTEm}/${pEntAdqm}/file_out
                         vSTATT=$?
                         if [ "$vSTATT" != "0" ]
                         then
                           tput setf 8
                           echo "Error en la transferencia del archivo $vArchDest al X4200, favor revisar" >> $vFileLOG 2>&1 #| tee -a $vFileLOG
                           f_fhmsg "Error en la transferencia del archivo $vArchDest al X4200, favor revisar"
                           tput setf 7
                           sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Error_Transferencia_de_Archivo_$vArchDest_Adquiriente_$pEntAdq"
                         else
                           #echo
                           echo "Archivo Transferido al area de acceso de los Bancos" >> $vFileLOG 2>&1
                           f_fhmsg "Archivo Transferido al area de acceso de los Bancos"
                           echo
                         fi # Fin de la eliminación de transferencia de archivo convertido al area de los bancos IPR1156
                          #echo
                          echo "Proceso de carga T464NA Finalizado creando Backup de Archivo" >> $vFileLOG 2>&1
                          f_fhmsg "Proceso de carga T464NA Finalizado creando Backup de Archivo"
                          echo "Creando Backup de Archivo" >> $vFileLOG 2>&1
                          f_fhmsg "Creando Backup de Archivo"
                          mv $DIRIN/$vArchDest $DIRIN/${vArchDest}_bkp
                          mv $DIRIN/$vArchDest_conv $DIRIN/${vArchDest_conv}_bkp
                          #echo
                          echo "Backup de Archivo T464NA Realizado" >> $vFileLOG 2>&1
                          f_fhmsg "Backup de Archivo T464NA Realizado"
                          f_msgtit OKF
                          echo
                     fi
                     rm $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                     rm $DIRTMP/$dpNom$vFecProc.PARRM.SFTP
                  fi
               fi
            fi
            DUMMY=0
            while [ "$DUMMY" != "Q" ] && [ "$DUMMY" != "q" ]
            do
               echo "Oprima Q o q <ENTER> para volver al Menu \c"
               read DUMMY
            done
            stty intr 
         fi
      fi

   fi # Opcion 1 - INCOMING DEBITO MAESTRO


   # CARGA DE INCOMING Y RETORNOS CREDITO 

   if [ "$vOpcion" = "2" ]; then

      vFlgOpcErr="N"
      vOpcion=""

      # Confirmacion de Ejecucion
      if [ "$vOpcRepro" = "S" ]; then
         f_msg
         f_msg "--------------------------------------------------------------------------------" N S
         f_msg " CONFIRMACION DE REPROCESO" N S
         f_msg "--------------------------------------------------------------------------------" N S
         f_msg
         f_msg " El REPROCESO puede involucrar la ejecucion de acciones adicionales para" N S
         f_msg " realizar correctamente la REVERSION de la ejecucion anterior, por lo que" N S
         f_msg " puede ser NECESARIA una AUTORIZACION por parte del ADMINISTRADOR DEL SISTEMA." N S
      else
         f_msg
         f_msg "--------------------------------------------------------------------------------" N S
         f_msg " CONFIRMACION DE EJECUCION DE PROCESO" N S
         f_msg "--------------------------------------------------------------------------------" N S
      fi
      f_msg
      f_msg " Proceso: CARGA DE INCOMING Y RETORNOS CREDITO" N S
      f_msg
      f_msg
      f_fechora $vFecProc
      f_msg "    Fecha de Proceso: $vpValRet" N S
      f_msg
      echo " Desea Continuar? (S=Si/N=No/<Enter>=No) => \c"
      read ValConf
      f_msg

      if [ "$ValConf" = "s" ] || [ "$ValConf" = "S" ]
      then
         vTRANS112=0
         vTRANS113=0
         vERRORTRANS112=0
         vERRORTRANS113=0
		 vFileParSSH="${DIRTMP}/SSH${dpNom}_${vFecProc}.PAR.SSH"   #GlobalR Agregado IPR1156
         case $COD_AMBIENTE in
            DESA)
              vPrefijo="/TEST";;
            CCAL)
              vPrefijo="/TEST";;
            PROD)
              vPrefijo="/PROD";;
         esac
         DiaSemana=`date +%u`
#         DiaSemana=`sqlplus -s $DB << !
#set head off
#set pagesize 0000
#select to_char(to_date('$vFecProc','YYYYMMDD'),'D') from dual;
#! #########################################`
#`  No olvidar la comilla ###########################################3

         if [ "$pEntAdq" = "TODOS" ]
         then
            stty intr 
            vADQIDX=0
            f_fechora $vFecProc
            vFecArch="$vAno-$vMes-$vDia"
            vFecJul=`dayofyear ${vFecProc}`
            vFecJul=`printf "%03d" $vFecJul`
            for vEntAdq in BM BP
            do
              case $vEntAdq in
                 BM)
                   vEndPoint=01857;;
                 BP)
                   vEndPoint=01858;;
              esac
              vFileINCOMING="SGCPINCMC${vEntAdq}.INCOMINGMC.${vFecProc}"
              vFileCTL="${DIRDAT}/${vFileINCOMING}.CTL"
              vEstProc=`awk '{print substr($0,13,1)}' $vFileCTL 2>/dev/null`
              if [ "$vEstProc" = "F" ] && [ "$vOpcRepro" != "S" ]
              then
                 tput setf 8
                 echo "La Carga de Incoming y Retornos Credito para este dia y Adquiriente $vEntAdq ya ha sido efectuada"
                 tput setf 7
                 echo " "
                 continue
              fi
              vFileLOG="${DIRLOG}/${vFileINCOMING}.`date '+%Y%m%d%H%M%S'`.LOG"
              vFileLOG1="${DIRLOG}/${vFileINCOMING}.`date '+%Y%m%d%H%M%S'`.LOG.tmp"
              if [ -f "$vFileLOG" ]; then
                 rm -f $vFileLOG
              fi
              if [ -f "$vFileLOG1" ]; then
                 rm -f $vFileLOG1
              fi
              touch $vFileLOG
              touch $vFileLOG1
              vTRANS112=0
              vTRANS113=0
			     echo "Va evaluar si los archivos existen TT${vpValRet_3}T0.${vFecArch}*" | tee -a $vFileLOG   #GlobalR IPR1156
              echo "cd $vPrefijo/$vEntAdq/T$vpValRet_3" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
              echo "ls TT${vpValRet_3}T0.${vFecArch}*" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
              vARCHINC[$vADQIDX]=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\> | wc -l`
              if [ "${vARCHINC[$vADQIDX]}" -eq "0" ] && [ "$DiaSemana" -eq "1" ]
              then
                 echo "Dia Domingo, No hay Archivos ${vpValRet_3} para procesar" | tee -a $vFileLOG
                 vTRANS112=1
              fi
              if [ "${vARCHINC[$vADQIDX]}" -ne "4" ] && [ "$DiaSemana" -ne "1" ]
              then
                 vTRANS112=0
                 tput setf 8
                 echo "Numero Incorrecto de Archivos de INCOMING MASTERCARD para el Adquiriente $vEntAdq" | tee -a $vFileLOG
                 tput setf 7
                 sqlplus -s $DB @$DIRBIN/alertacie INC MASTERCARD "Archivo_de_Debito_MasterCard_Adquiriente_$vEntAdq_Nro_Archivos_Incorrecto"
              fi
              if [ "${vARCHINC[$vADQIDX]}" -ne "0" ] && [ "$DiaSemana" -eq "1" ]
              then
                 vTRANS112=0
                 tput setf 8
                 echo "Se encontraron Archivos con Transacciones recibidos un dia Domingo para el Adquiriente $vEntAdq" | tee -a $vFileLOG
                 tput setf 7
                 sqlplus -s $DB @$DIRBIN/alertacie INC MASTERCARD "Archivo_de_Debito_MasterCard_Adquiriente_$vEntAdq_Archivos_a_Destiempo"
              fi
              if [ "${vARCHINC[$vADQIDX]}" -eq "4" ] && [ "$DiaSemana" -ne "1" ]
              then
                 vTRANS112=1
                 vARCHINC[$vADQIDX]=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\> | sort`
                 echo "cd $vPrefijo/$vEntAdq/T$vpValRet_3" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                 for vARCHIVOSINC in ${vARCHINC[$vADQIDX]}
                 do
                    echo "get $vARCHIVOSINC $DIRIN/$vARCHIVOSINC" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                 done
                 sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} | grep -v Fetching >> $vFileLOG 2>&1
                 vSTATT=$?
	             if [ "$vSTATT" -ne "0" ]
                 then
                    vERRORTRANS112=1
                    tput setf 8
                    echo "error en la transferencia de los archivos ${vARCHINC[$vADQIDX]} del adquiriente $vEntAdq, favor revisar" | tee -a $vFileLOG
                    tput setf 7
                    sqlplus -s $DB @$DIRBIN/alertacie INC MASTERCARD "Error_Transferencia_de_Archivos_${vARCHINC[$vADQIDX]}_Adquiriente_$vEntAdq"
                 else 
                    echo "Archivo ${vARCHINC[$vADQIDX]} Transferido Correctamente"
                    vERRORTRANS112=0
                 fi
              fi 

              if [ "$vTRANS112" -eq "1" ] && [ "$vERRORTRANS112" -eq "0" ] && [ "$DiaSemana" -ne "1" ]
              then
                    vCONTADORSEQ=1
                    rm $DIRTMP/$dpNom$vFecProc.PAR.SFTP 2>/dev/null
                    rm $DIRTMP/$dpNom$vFecProc.PARRM.SFTP 2>/dev/null
                    for vARCHIVOSINC in ${vARCHINC[$vADQIDX]}
                    do
                       case $vCONTADORSEQ in
                          1)
                             vNumSec=01;;
                          2)
                             vNumSec=02;;
                          3)
                             vNumSec=04;;
                          4)
                             vNumSec=06;;
                       esac
                       vArchDest="${vpValRet_3}${vEndPoint}_${vFecJul}_${vNumSec}_conv"
                       echo " "
                       echo "Archivo $vARCHIVOSINC Movido al Directorio Procesado(E)" | tee -a $vFileLOG
                       echo "rm $vPrefijo/$vEntAdq/T$vpValRet_3/RESPALDO/$vARCHIVOSINC" >> $DIRTMP/$dpNom$vFecProc.PARRM.SFTP
                       echo "rename $vPrefijo/$vEntAdq/T$vpValRet_3/$vARCHIVOSINC  $vPrefijo/$vEntAdq/T$vpValRet_3/RESPALDO/$vARCHIVOSINC" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                       /UTILIDADES/lecturan.exe $DIRIN/$vARCHIVOSINC $DIRIN/$vArchDest
                       vCONTADORSEQ=`expr $vCONTADORSEQ + 1`
                    done
                    sftp -b $DIRTMP/$dpNom$vFecProc.PARRM.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} >> $vFileLOG 2>&1
                    sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} >> $vFileLOG 2>&1
              fi
			  #empieza proceso con el archivo 121
              echo "cd $vPrefijo/$vEntAdq/T$vpValRet_4" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
              echo "ls TT${vpValRet_4}T0.${vFecArch}*" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
              vARCHINC[$vADQIDX]=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\> | wc -l`
              if [ "${vARCHINC[$vADQIDX]}" -lt "2" ]
              then
                 tput setf 8
                 echo "Advertencia: Normalmente deben haber DOS archivos ${vpValRet_4} para procesar" | tee -a $vFileLOG
                 echo "Numero de Archivos Encontrados: ${vARCHINC[$vADQIDX]}" | tee -a $vFileLOG
                 echo " Desea Continuar? (S=Si/N=No/<Enter>=No) => \c"
                 read RetConf
                 if [ "$RetConf" = "S" ] || [ "$RetConf" = "s" ]
                 then
                    echo "Operador Acepto Procesar sin el numero de archivos ${vpValRet_4} correcto, se continuara el proceso" | tee -a $vFileLOG
                    sqlplus -s $DB @$DIRBIN/alertacie INC MASTERCARD "No_se_encontraron__Todos_los_Archivos_${vpValRet_4}_Adquiriente_$pEntAdq_Operador_Continuo_Proceso"
                    if [ "${vARCHINC[$vADQIDX]}" -eq "0" ] && [ "$DiaSemana" -eq "1" ]
                    then
                       echo "Dia Domingo, y no hay archivos ${vpValRet_4} para procesar, se abortara el proceso" | tee -a $vFileLOG
                       sqlplus -s $DB @$DIRBIN/alertacie INC MASTERCARD "No_se_encontraron_Archivos_${vpValRet_4}_Adquiriente_$pEntAdq_en_dia_domingo"
                       vTRANS113=0
                    else
                       vTRANS113=1
                    fi
                 else
                    vTRANS112=0
                    vTRANS113=0
                    echo "Operador NO Acepto Procesar sin el numero de archivos ${vpValRet_4} correcto, se Abortara el Proceso" | tee -a $vFileLOG
                    sqlplus -s $DB @$DIRBIN/alertacie INC MASTERCARD "No_se_encontraron__Todos_los_Archivos_${vpValRet_4}_Adquiriente_$pEntAdq_Operador_Aborto_Proceso"
                    echo "cd $vPrefijo/$vEntAdq/T$vpValRet_3/RESPALDO" > $DIRTMP/U$dpNom$vFecProc.PAR.SFTP
                    echo "ls TT${vpValRet_3}T0.${vFecArch}*" >> $DIRTMP/U$dpNom$vFecProc.PAR.SFTP
                    vUARCHINC[$vADQIDX]=`sftp -b $DIRTMP/U$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\> | sort`
                    for vUARCHIVOSINC in ${vUARCHINC[$vADQIDX]}
                    do
                       echo "rename $vPrefijo/$vEntAdq/T$vpValRet_3/RESPALDO/$vUARCHIVOSINC  $vPrefijo/$vEntAdq/T$vpValRet_3/$vUARCHIVOSINC" >> $DIRTMP/U$dpNom$vFecProc.PAR.SFTP
                    done
                    sftp -b $DIRTMP/U$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} >> $vFileLOG 2>&1
                    rm $DIRTMP/U$dpNom$vFecProc.PAR.SFTP
                 fi
              else
                 vTRANS113=1
              fi
              tput setf 7
              if [ "$vTRANS113" = "1" ] && [ "$vTRANS112" = "1" ]
              then
                 vARCHINC[$vADQIDX]=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\> | sort`
                 echo "cd $vPrefijo/$vEntAdq/T$vpValRet_4" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                 for vARCHIVOSINC in ${vARCHINC[$vADQIDX]}
                 do
                    echo "get $vARCHIVOSINC $DIRIN/$vARCHIVOSINC" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                 done
                 sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} | grep -v Fetching >> $vFileLOG>&1
                 vSTATT=$?
                 if [ "$vSTATT" -ne "0" ]
                 then
                    vERRORTRANS113=1
                    tput setf 8
                    echo "error en la transferencia de los archivos ${vARCHINC[$vADQIDX]} del adquiriente $vEntAdq, favor revisar" | tee -a $vFileLOG
                    tput setf 7
                    sqlplus -s $DB @$DIRBIN/alertacie INC MASTERCARD "Error_Transferencia_de_Archivos_${vARCHINC[$vADQIDX]}_Adquiriente_$vEntAdq"
                 else
                    echo "Archivos ${vARCHINC[$vADQIDX]} Transferidos Correctamente" | tee -a $vFileLOG
                    vERRORTRANS113=0
                 fi
              fi

			  
              if [ "$vTRANS113" -eq "1" ] && [ "$vERRORTRANS113" -eq "0" ]
              then
                    rm $DIRTMP/$dpNom$vFecProc.PAR.SFTP 2>/dev/null
                    rm $DIRTMP/$dpNom$vFecProc.PARRM.SFTP 2>/dev/null
                    vNumSec=7
                    for vARCHIVOSINC in ${vARCHINC[$vADQIDX]}
                    do
                       vNumSec=`printf "%02d" $vNumSec`
                       vArchDest="${vpValRet_3}${vEndPoint}_${vFecJul}_${vNumSec}_conv"
                       echo " "
                       echo "Archivo $vARCHIVOSINC Movido al Directorio Procesado(E)" | tee -a $vFileLOG
                       echo "rm $vPrefijo/$vEntAdq/T$vpValRet_4/RESPALDO/$vARCHIVOSINC" >> $DIRTMP/$dpNom$vFecProc.PARRM.SFTP
                       echo "rename $vPrefijo/$vEntAdq/T$vpValRet_4/$vARCHIVOSINC  $vPrefijo/$vEntAdq/T$vpValRet_4/RESPALDO/$vARCHIVOSINC" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                       /UTILIDADES/lecturan.exe $DIRIN/$vARCHIVOSINC $DIRIN/$vArchDest | tee -a $vFileLOG 2>&1
                       vNumSec=`expr $vNumSec + 1`
                    done
                    sftp -b $DIRTMP/$dpNom$vFecProc.PARRM.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} >> $vFileLOG 2>&1
                    sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} >> $vFileLOG 2>&1
              fi
              vRESTRANS=`expr $vTRANS112 + $vTRANS113`
              if [ "$vRESTRANS" -gt "1" ] && [ "$vERRORTRANS112" -eq "0" ] && [ "$vERRORTRANS113" -eq "0" ]
              then
                 f_msg "--------------------------------------------------------------------------------" N S
                 f_msg
                 echo
                 echo "         Archivo de Control : `basename ${vFileCTL}`"
                 echo "                 Directorio : `dirname ${vFileCTL}`"
                 echo "   Archivo LOG de Ejecucion : `basename ${vFileLOG}`"
                 echo "                 Directorio : `dirname ${vFileLOG}`"
                 echo "    Archivo LOG del Proceso : ${vFileINCOMING}.LOG"
                 echo "                 Directorio : ${DIRLOG}"
                 ${DIRBIN}/SGCPINCMCADQproc.sh ${vEntAdq} ${vFecProc} INCOMINGMC ${vOpcRepro} S 1 >>${vFileLOG1} 2>&1
                 cat $vFileLOG1 | grep -v 'PRESIONE' | grep -v 'presione' | tee -a $vFileLOG
                 rm $vFileLOG1
              fi
              vEstProc=`awk '{print substr($0,13,1)}' $vFileCTL 2>/dev/null`
              if [ "$vEstProc" = "F" ] && [ "$vTRANS113" -eq "1" ] && [ "$vERRORTRANS113" -eq "0" ]
              then
			  #GlobalR Se descomenta transferencia de archivo convertido al XCOM IPR1156 Fase IV
                 if [ "$vEntAdq" = "BP" ]
                 then
                    for vARCHXCOM in `ls $DIRIN/${vpValRet_3}${vEndPoint}_${vFecJul}_??_conv_bkp`
                    do
                       vNumSec=`basename $vARCHXCOM | awk '{print substr($0,14,2)}'`
                       if [ "$vNumSec" -lt "7" ]
                       then
                          vArchDest=`basename $vARCHXCOM | sed -e 's/_bkp//'`
                          scp -Bq $vARCHXCOM  $SSSH_USER@$FTP_HOSTXCOM:${vEntAdq}pu_fileout/$vArchDest
                          vSTATT=$?
                          if [ "$vSTATT" != "0" ]
                          then
                            tput setf 8
                            echo "error en la transferencia del archivo $vArchDest del adquiriente $vEntAdq al area de acceso de los Bancos, favor revisar" | tee -a $vFileLOG
                            tput setf 7
                            sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO "Error_Transferencia_de_Archivo_$vArchDest_Adquiriente_$vEntAdq"
                         else
                            echo "Archivo $vArchDest transferido al area de acceso de los Bancos"
                          fi
                          echo "\n"
                       fi
                    done
                 fi  #Fin descomentar de la transferencia de archivo IPR1156
                 vNumSec=1
                 for vARCHIVOSINC in ${vARCHINC[$vADQIDX]}
                 do  
                   vNumSec=`printf "%02d" $vNumSec`
                    vArchDest="${vpValRet_4}${vEndPoint}_${vFecJul}_${vNumSec}_conv"
                    /UTILIDADES/lecturan.exe $DIRIN/$vARCHIVOSINC $DIRIN/$vArchDest
                    vNumSec=`expr $vNumSec + 1`
                 done
                 f_msg "--------------------------------------------------------------------------------" N S
                 f_msg
                 vFileINCRET="SGCPINCMC${vEntAdq}.INCRET.${vFecProc}"
                 vFileLOG="${DIRLOG}/${vFileINCRET}.`date '+%Y%m%d%H%M%S'`.LOG"
                 vFileLOG1="${DIRLOG}/${vFileINCRET}.`date '+%Y%m%d%H%M%S'`.LOG.tmp"
                 vFileCTL="${DIRDAT}/${vFileINCRET}.CTL"
                 if [ -f "$vFileLOG" ]; then
                    rm -f $vFileLOG
                 fi
                 if [ -f "$vFileLOG1" ]; then
                    rm -f $vFileLOG1
                 fi
                 touch $vFileLOG1
                 echo
                 echo "         Archivo de Control : `basename ${vFileCTL}`"
                 echo "                 Directorio : `dirname ${vFileCTL}`"
                 echo "   Archivo LOG de Ejecucion : `basename ${vFileLOG}`"
                 echo "                 Directorio : `dirname ${vFileLOG}`"
                 echo "    Archivo LOG del Proceso : ${vFileINCRET}.LOG"
                 echo "                 Directorio : ${DIRLOG}"
                 ${DIRBIN}/SGCPINCMCADQproc.sh ${vEntAdq} ${vFecProc} INCRET ${vOpcRepro} S 1 >> ${vFileLOG1} 2>&1
                 cat $vFileLOG1 | grep -v 'PRESIONE' | grep -v 'presione' | tee -a $vFileLOG
                 rm $vFileLOG1
                 vEstProc=`awk '{print substr($0,13,1)}' $vFileCTL 2>/dev/null`
				 # GlobalR Descomentar  transferecia de archivo convertido al XCOM IPR 1156
                 if [ "$vEstProc" = "F" ]
                 then
                    if [ "$vEntAdq" = "BP" ]
                    then
                       for vARCHXCOM in `ls $DIRIN/${vpValRet_4}${vEndPoint}_${vFecJul}_??_conv_bkp`
                       do
                          vArchDest=`basename $vARCHXCOM | sed -e 's/_bkp//'`
                          scp -Bq $vARCHXCOM  $SSSH_USER@$FTP_HOSTXCOM:${vEntAdq}pu_fileout/$vArchDest
                          vSTATT=$?
                          if [ "$vSTATT" != "0" ]
                          then
                            tput setf 8
                            echo "error en la transferencia del archivo $vArchDest del adquiriente $vEntAdq al area de acceso de los Bancos, favor revisar" | tee -a $vFileLOG
                            tput setf 7
                            sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO "Error_Transferencia_de_Archivo_$vArchDest_Adquiriente_$vEntAdq"
                          else
                            echo "Archivo $vArchDest transferido al area de acceso de los Bancos"
                          fi
                          echo "\n"
                       done
                    fi
                 fi   #Fin descomentar el proceso de transferencia de archivo convertido al XCOM IPR1156
              fi
              vADQIDX=`expr $vADQIDX + 1`
            done
            rm $DIRTMP/$dpNom$vFecProc.PAR.SFTP 2>/dev/null
            rm $DIRTMP/$dpNom$vFecProc.PARRM.SFTP 2>/dev/null
            rm $DIRIN/TT${vpValRet_3}T0.${vFecArch}*.001 2>/dev/null
            rm $DIRIN/TT${vpValRet_4}T0.${vFecArch}*.001 2>/dev/null
            DUMMY=0
            while [ "$DUMMY" != "Q" ] && [ "$DUMMY" != "q" ]
            do
               echo "Oprima Q o q <ENTER> para volver al Menu \c"
               read DUMMY
            done
            stty intr 
         else   #Caso de que sea un adquieriente en particular
            stty intr 
            vADQIDX=0
            f_fechora $vFecProc
            vFecArch="$vAno-$vMes-$vDia"
            vFecJul=`dayofyear ${vFecProc}`
            vFecJul=`printf "%03d" $vFecJul`
            case $pEntAdq in
               BM)		   
                 vEndPoint=01857;;
               BP)			   
                 vEndPoint=01858;;
            esac
            vFileINCOMING="SGCPINCMC${pEntAdq}.INCOMINGMC.${vFecProc}"
            vFileCTL="${DIRDAT}/${vFileINCOMING}.CTL"
            vEstProc=`awk '{print substr($0,13,1)}' $vFileCTL 2>/dev/null`
            if [ "$vEstProc" = "F" ] && [ "$vOpcRepro" != "S" ]
            then
               tput setf 8
               echo "La Carga de Incoming y Retornos Credito para este dia ya ha sido efectuada"
               tput setf 7
               echo " "
            else
               vFileLOG="${DIRLOG}/${vFileINCOMING}.`date '+%Y%m%d%H%M%S'`.LOG"
               vFileLOG1="${DIRLOG}/${vFileINCOMING}.`date '+%Y%m%d%H%M%S'`.LOG.tmp"
               if [ -f "$vFileLOG" ]; then
                  rm -f $vFileLOG
               fi
               if [ -f "$vFileLOG1" ]; then
                  rm -f $vFileLOG1
               fi
               touch $vFileLOG
               touch $vFileLOG1
               vTRANS112=0
               vTRANS113=0
               echo "cd $vPrefijo/$pEntAdq/T$vpValRet_3" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
               echo "ls TT${vpValRet_3}T0.${vFecArch}*" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
               vARCHINC=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\> | wc -l`
               if [ "${vARCHINC}" -eq "0" ] && [ "$DiaSemana" -eq "1" ]
               then
                  tput setf 8
                  echo "Dia Domingo, No hay Archivos ${vpValRet_3} para procesar" | tee -a $vFileLOG
                  tput setf 7
                  vTRANS112=1
               fi
               if [ "${vARCHINC}" -ne "4" ] && [ "$DiaSemana" -ne "1" ]
               then
                  vTRANS112=0
                  tput setf 8
                  echo "Numero Incorrecto de Archivos de INCOMING MASTERCARD para el Adquiriente $pEntAdq" | tee -a $vFileLOG
                  tput setf 7
                  sqlplus -s $DB @$DIRBIN/alertacie INC MASTERCARD "Archivo_de_Debito_MasterCard_Adquiriente_$pEntAdq_Nro_Archivos_Incorrecto"
               fi
               if [ "${vARCHINC}" -ne "0" ] && [ "$DiaSemana" -eq "1" ]
               then
                  vTRANS112=0
                  tput setf 8
                  echo "Se encontraron Archivos con Transacciones recibidos un dia Domingo para el Adquiriente $pEntAdq" | tee -a $vFileLOG
                  tput setf 7
                  sqlplus -s $DB @$DIRBIN/alertacie INC MASTERCARD "Archivo_de_Debito_MasterCard_Adquiriente_$pEntAdq_Archivos_a_Destiempo"
               fi
               if [ "${vARCHINC}" -eq "4" ] && [ "$DiaSemana" -ne "1" ]
               then
                  vTRANS112=1
                  vARCHINC=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\> | sort`
                  echo "cd $vPrefijo/$pEntAdq/T$vpValRet_3" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                  for vARCHIVOSINC in ${vARCHINC}
                  do
                     echo "get $vARCHIVOSINC $DIRIN/$vARCHIVOSINC" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                  done
                  sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} | grep -v Fetching >> $vFileLOG 2>&1
                  vSTATT=$?
                  if [ "$vSTATT" -ne "0" ]
                  then
                     vERRORTRANS112=1
                     tput setf 8
                     echo "error en la transferencia de los archivos ${vARCHINC} del adquiriente $pEntAdq, favor revisar" | tee -a $vFileLOG
                     tput setf 7
                     sqlplus -s $DB @$DIRBIN/alertacie INC MASTERCARD "Error_Transferencia_de_Archivos_${vARCHINC}_Adquiriente_$pEntAdq"
                  else 
                     echo "Archivos ${vARCHINC} transferidos Correctamente"
                     vERRORTRANS112=0
                  fi
               fi

			   
               if [ "$vTRANS112" -eq "1" ] && [ "$vERRORTRANS112" -eq "0" ]  && [ "$DiaSemana" -ne "1" ]
               then
                     vCONTADORSEQ=1
                     rm $DIRTMP/$dpNom$vFecProc.PAR.SFTP 2>/dev/null
                     for vARCHIVOSINC in ${vARCHINC}
                     do
                        case $vCONTADORSEQ in
                           1)
                              vNumSec=01;;
                           2)
                              vNumSec=02;;
                           3)
                              vNumSec=04;;
                           4)
                              vNumSec=06;;
                        esac
                        vArchDest="${vpValRet_3}${vEndPoint}_${vFecJul}_${vNumSec}_conv"
                        echo " "
                        echo "Archivo $vARCHIVOSINC Movido al Directorio Procesado(E)" | tee -a $vFileLOG
                        echo "rm $vPrefijo/$pEntAdq/T$vpValRet_3/RESPALDO/$vARCHIVOSINC" >> $DIRTMP/$dpNom$vFecProc.PARRM.SFTP 
                        echo "rename $vPrefijo/$pEntAdq/T$vpValRet_3/$vARCHIVOSINC  $vPrefijo/$pEntAdq/T$vpValRet_3/RESPALDO/$vARCHIVOSINC" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                        /UTILIDADES/lecturan.exe $DIRIN/$vARCHIVOSINC $DIRIN/$vArchDest | tee -a $vFileLOG 2>&1
                        vCONTADORSEQ=`expr $vCONTADORSEQ + 1`
                     done
                     sftp -b $DIRTMP/$dpNom$vFecProc.PARRM.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} >> $vFileLOG 2>&1
                     sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} >> $vFileLOG 2>&1
               fi
               echo "cd $vPrefijo/$pEntAdq/T$vpValRet_4" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
               echo "ls TT${vpValRet_4}T0.${vFecArch}*" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
               vARCHINC=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\> | wc -l`
              if [ "${vARCHINC}" -lt "2" ]
              then
                 tput setf 8
                 echo "Advertencia: Normalmente deben haber DOS archivos ${vpValRet_4} para procesar" | tee -a $vFileLOG
                 echo "Numero de Archivos Encontrados: ${vARCHINC}" | tee -a $vFileLOG
                 echo " Desea Continuar? (S=Si/N=No/<Enter>=No) => \c"
                 read RetConf
                 if [ "$RetConf" = "S" ] || [ "$RetConf" = "s" ]
                 then
                    echo "Operador Acepto Procesar sin el numero de archivos ${vpValRet_4} correcto, se continuara el proceso" | tee -a $vFileLOG
                    sqlplus -s $DB @$DIRBIN/alertacie INC MASTERCARD "No_se_encontraron__Todos_los_Archivos_${vpValRet_4}_Adquiriente_$pEntAdq_Operador_Continuo_Proceso"
                    if [ "${vARCHINC}" -eq "0" ] && [ "$DiaSemana" -eq "1" ]
                    then
                       echo "Dia Domingo, y no hay archivos ${vpValRet_4} para procesar, se abortara el proceso" | tee -a $vFileLOG
                       sqlplus -s $DB @$DIRBIN/alertacie INC MASTERCARD "No_se_encontraron_Archivos_${vpValRet_4}_Adquiriente_$pEntAdq_en_dia_domingo"
                       vTRANS113=0
                    else
                       vTRANS113=1
                    fi
                 else
                    vTRANS112=0
                    vTRANS113=0
                    echo "Operador NO Acepto Procesar sin el numero de archivos ${vpValRet_4} correcto, se Abortara el Proceso" | tee -a $vFileLOG
                    sqlplus -s $DB @$DIRBIN/alertacie INC MASTERCARD "No_se_encontraron__Todos_los_Archivos_${vpValRet_4}_Adquiriente_$pEntAdq_Operador_Aborto_Proceso"
                    echo "cd $vPrefijo/$pEntAdq/T$vpValRet_3/RESPALDO" > $DIRTMP/U$dpNom$vFecProc.PAR.SFTP
                    echo "ls TT${vpValRet_3}T0.${vFecArch}*" >> $DIRTMP/U$dpNom$vFecProc.PAR.SFTP
                    vUARCHINC=`sftp -b $DIRTMP/U$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\> | sort`
                    for vUARCHIVOSINC in ${vUARCHINC}
                    do
                       echo "rename $vPrefijo/$pEntAdq/T$vpValRet_3/RESPALDO/$vUARCHIVOSINC  $vPrefijo/$pEntAdq/T$vpValRet_3/$vUARCHIVOSINC" >> $DIRTMP/U$dpNom$vFecProc.PAR.SFTP
                    done
                    sftp -b $DIRTMP/U$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} >> $vFileLOG 2>&1
                    rm $DIRTMP/U$dpNom$vFecProc.PAR.SFTP
                 fi
               else
                  vTRANS113=1
               fi
               if [ "$vTRANS113" = "1" ] && [ "$vTRANS112" = "1" ]
               then
                  vARCHINC=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\> | sort`
                  echo "cd $vPrefijo/$pEntAdq/T$vpValRet_4" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                  for vARCHIVOSINC in ${vARCHINC}
                  do
                     echo "get $vARCHIVOSINC $DIRIN/$vARCHIVOSINC" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                  done
                  sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} | grep -v Fetching >> $vFileLOG>&1
                  vSTATT=$?
                  if [ "$vSTATT" -ne "0" ]
                  then
                     vERRORTRANS113=1
                     tput setf 8
                     echo "error en la transferencia de los archivos ${vARCHINC} del adquiriente $vEntAdq, favor revisar" | tee -a $vFileLOG
                     tput setf 7
                     sqlplus -s $DB @$DIRBIN/alertacie INC MASTERCARD "Error_Transferencia_de_Archivos_${vARCHINC[$vADQIDX]}_Adquiriente_$vEntAdq"
                  else
                     echo "Archivos ${vARCHINC} Transferidos Correctamente" | tee -a $vFileLOG
                     vERRORTRANS113=0
                  fi
               fi
			   
               if [ "$vTRANS113" -eq "1" ] && [ "$vERRORTRANS113" -eq "0" ]
               then
                     rm $DIRTMP/$dpNom$vFecProc.PAR.SFTP 2> /dev/null
                     rm $DIRTMP/$dpNom$vFecProc.PARRM.SFTP 2> /dev/null
                     vNumSec=7
                     for vARCHIVOSINC in ${vARCHINC}
                     do
                        vNumSec=`printf "%02d" $vNumSec`
                        vArchDest="${vpValRet_3}${vEndPoint}_${vFecJul}_${vNumSec}_conv" #Parece un error deber�a ser vpValRet_4
                        echo " "
                        echo "Archivo $vARCHIVOSINC Movido al Directorio Procesado(E)"
                        echo "rm $vPrefijo/$pEntAdq/T$vpValRet_4/RESPALDO/$vARCHIVOSINC" >> $DIRTMP/$dpNom$vFecProc.PARRM.SFTP
                        echo "rename $vPrefijo/$pEntAdq/T$vpValRet_4/$vARCHIVOSINC  $vPrefijo/$pEntAdq/T$vpValRet_4/RESPALDO/$vARCHIVOSINC" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                        /UTILIDADES/lecturan.exe $DIRIN/$vARCHIVOSINC $DIRIN/$vArchDest
                        vNumSec=`expr $vNumSec + 1`
                     done
                     sftp -b $DIRTMP/$dpNom$vFecProc.PARRM.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} >> $vFileLOG 2>&1
                     sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} >> $vFileLOG 2>&1
               fi
               vRESTRANS=`expr $vTRANS112 + $vTRANS113`
               if [ "$vRESTRANS" -gt "1" ] && [ "$vERRORTRANS112" -eq "0" ] && [ "$vERRORTRANS113" -eq "0" ]
               then
                  f_msg "--------------------------------------------------------------------------------" N S
                  f_msg
                  echo
                  echo "         Archivo de Control : `basename ${vFileCTL}`"
                  echo "                 Directorio : `dirname ${vFileCTL}`"
                  echo "   Archivo LOG de Ejecucion : `basename ${vFileLOG}`"
                  echo "                 Directorio : `dirname ${vFileLOG}`"
                  echo "    Archivo LOG del Proceso : ${vFileINCOMING}.LOG"
                  echo "                 Directorio : ${DIRLOG}"
                  ${DIRBIN}/SGCPINCMCADQproc.sh ${pEntAdq} ${vFecProc} INCOMINGMC ${vOpcRepro} S 1 >> ${vFileLOG1} 2>&1
                  cat $vFileLOG1 | grep -v 'PRESIONE' | grep -v 'presione' | tee -a $vFileLOG
                  rm $vFileLOG1
               fi
               vEstProc=`awk '{print substr($0,13,1)}' $vFileCTL 2>/dev/null`
               if [ "$vEstProc" = "F" ] && [ "$vTRANS113" -eq "1" ] && [ "$vERRORTRANS113" -eq "0" ]
               then
				  #Global Descomentar transferencia de archivo convertido al XCOM IPR1156 Fase IV
                  if [ "$pEntAdq" = "BP" ]
                  then
                     for vARCHXCOM in `ls $DIRIN/${vpValRet_3}${vEndPoint}_${vFecJul}_??_conv_bkp`
                     do
                       vNumSec=`basename $vARCHXCOM | awk '{print substr($0,14,2)}'`
                       if [ "$vNumSec" -lt "7" ]
                       then
                           vArchDest=`basename $vARCHXCOM | sed -e 's/_bkp//'`
                           scp -Bq $vARCHXCOM  $SSSH_USER@$FTP_HOSTXCOM:${pEntAdq}pu_fileout/$vArchDest
                           vSTATT=$?
                           if [ "$vSTATT" != "0" ]
                           then
                             tput setf 8
                             echo "error en la transferencia del archivo $vArchDest del adquiriente $pEntAdq al area de acceso de los Bancos, favor revisar" | tee -a $vFileLOG
                             tput setf 7
                             sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO "Error_Transferencia_de_Archivo_$vArchDest_Adquiriente_$pEntAdq"
                           else
                             echo "Archivo $vArchDest transferido al area de acceso de los Bancos"
                           fi
                           echo "\n"
                       fi
                     done
                  fi  #FIN descomentar IPR1156
                  vNumSec=1
                  for vARCHIVOSINC in ${vARCHINC[$vADQIDX]}
                  do
                     vNumSec=`printf "%02d" $vNumSec`
                     vArchDest="${vpValRet_4}${vEndPoint}_${vFecJul}_${vNumSec}_conv"
                     /UTILIDADES/lecturan.exe $DIRIN/$vARCHIVOSINC $DIRIN/$vArchDest | tee -a $vFileLOG 2>&1
                     vNumSec=`expr $vNumSec + 1`
                  done
                  f_msg "--------------------------------------------------------------------------------" N S
                  f_msg
                  vFileINCRET="SGCPINCMC${pEntAdq}.INCRET.${vFecProc}"
                  vFileLOG="${DIRLOG}/${vFileINCRET}.`date '+%Y%m%d%H%M%S'`.LOG"
                  vFileCTL="${DIRDAT}/${vFileINCRET}.CTL"
                  if [ -f "$vFileLOG" ]; then
                     rm -f $vFileLOG
                  fi
                  touch $vFileLOG
                  echo
                  echo "         Archivo de Control : `basename ${vFileCTL}`"
                  echo "                 Directorio : `dirname ${vFileCTL}`"
                  echo "   Archivo LOG de Ejecucion : `basename ${vFileLOG}`"
                  echo "                 Directorio : `dirname ${vFileLOG}`"
                  echo "    Archivo LOG del Proceso : ${vFileINCRET}.LOG"
                  echo "                 Directorio : ${DIRLOG}"
                  ${DIRBIN}/SGCPINCMCADQproc.sh ${pEntAdq} ${vFecProc} INCRET ${vOpcRepro} S 1 >> ${vFileLOG} 2>&1
                  cat $vFileLOG | grep -v 'PRESIONE' | grep -v 'presione' 
                  vEstProc=`awk '{print substr($0,13,1)}' $vFileCTL 2>/dev/null`
					#Descomentar de la tranferencia de archivo convertido al XCOM IPR1156 - Fase IV
                  if [ "$vEstProc" = "F" ]
                  then
                     if [ "$pEntAdq" = "BP" ]
                     then
                        for vARCHXCOM in `ls $DIRIN/${vpValRet_4}${vEndPoint}_${vFecJul}_??_conv_bkp`
                        do
                           vArchDest=`basename $vARCHXCOM | sed -e 's/_bkp//'`
                           scp -Bq $vARCHXCOM  $SSSH_USER@$FTP_HOSTXCOM:${pEntAdq}pu_fileout/$vArchDest
                           vSTATT=$?
                           if [ "$vSTATT" != "0" ]
                           then
                             tput setf 8
                             echo "error en la transferencia del archivo $vArchDest del adquiriente $vEntAdq al area de acceso de los Bancos, favor revisar" | tee -a $vFileLOG
                             tput setf 7
                             sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO "Error_Transferencia_de_Archivo_$vArchDest_Adquiriente_$vEntAdq"
                           else
                             echo "Archivo $vArchDest transferido al area de acceso de los Bancos"
                           fi
                           echo "\n"
                        done
                     fi
                  fi
               fi
               rm $DIRTMP/$dpNom$vFecProc.PAR.SFTP
               rm $DIRTMP/$dpNom$vFecProc.PARRM.SFTP 2>/dev/null
               rm $DIRIN/TT${vpValRet_3}T0.${vFecArch}*.001 2>/dev/null  
               rm $DIRIN/TT${vpValRet_4}T0.${vFecArch}*.001 2>/dev/null 
            fi
            DUMMY=0
            while [ "$DUMMY" != "Q" ] && [ "$DUMMY" != "q" ]
            do
               echo "Oprima Q o q <ENTER> para volver al Menu \c"
               read DUMMY
            done
            stty intr 
         fi
      fi
   fi # Opcion 2 - Carga de Incoming y Retornos Credito


   # CARGA DE BINES Omitida para naiguata
   # CARGA DE TIPOS DE CAMBIO Omitida pra Naiguata

   #####################################################################
   # PROCESO DE REPORTE DEBITO MAESTRO NAIGUATA Carga de archivos SWCHD
   #####################################################################
   if [ "$vOpcion" = "5" ]; then

      vFlgOpcErr="N"
      vOpcion=""

      f_msg
      f_msg " Proceso: REPORTE DEBITO NAIGUATA MAESTRO - SWCHD " N S
      f_msg
      f_msg
      f_fechora $vFecProc
      f_msg "    Fecha de Proceso: $vpValRet" N S
      f_msg
      echo " Desea Continuar? (S=Si/N=No/<Enter>=No) => \c"
      read ValConf
      f_msg
      echo "Ingresar Usuario Windows para Transferencia Disco R: \c"
      read USUARIOTMVE
      echo "Ingresar Clave Windows para Transferencia Disco R: \c"
      stty -echo
      read CLAVETMVE
      stty echo
#      echo $CLAVETMVE
      f_msg

      if [ "$ValConf" = "s" ] || [ "$ValConf" = "S" ]
      then
         case $COD_AMBIENTE in
            DESA)
              COD_AMBIENTEm="ccal"
              COD_AMBIENTE2="Calidad"
              vPrefijo="/TDD/Entrada"
              vPrefijo_Res="/TDD/Entrada/Respaldo";;
            CCAL)
              COD_AMBIENTEm="ccal"
              COD_AMBIENTE2="Calidad"
              vPrefijo="/TDD/Entrada"
              vPrefijo_Res="/TDD/Entrada/Respaldo";;
            PROD)
              COD_AMBIENTEm="prod"
              COD_AMBIENTE2="Produccion"
              vPrefijo="/TDD/Entrada"
              vPrefijo_Res="/TDD/Entrada/Respaldo";;
         esac
         vPrefijoWin=`echo $vPrefijo_Res | sed -e 's/\///'`   ## quita la primera "/"
         #vPrefijoWin="\Procesos\Compensacion Naiguata-MC"
         if [ "$pEntAdq" = "TODOS" ]
         then
            stty intr 
            vADQIDX=0
            f_fechora $vFecProc
            #vFecArch="$vAno-$vMes-$vDia"
            #vFecJul=`dayofyear ${vFecProc}`
            #vFecJul=`printf "%03d" $vFecJul`
 
            ## Ibteniendo Fecha Juliana MENOS 1 
            vFecJul=`dayofyear ${vFecProc}`    
            vFecJul=`expr ${vFecJul} - 1`      #Ajuste T464NA Este archivo es del dia de AYER ipr1302 
            vFecJul=`printf "%03d" $vFecJul`   #Ajuste T464NA Este archivo es del dia de AYER ipr1302 

            ## Corresponde al último dígito del año al que corresponde el bulk, 
            ## Es decir, el cero corresponde al año 2020 para el año venidero el valor deberá ser 1.
            vNomFile_SecA=`echo ${vFecProc} | awk '{print substr($0,4,1)}'`

            for vEntAdq in BM BP
            do
               case $vEntAdq in
                  BM)
                     vEntAdqm=bm
                     vEndPoint=0275
                     vEntAdq2=0105;;
                  BP)
                     vEntAdqm=bp
                     vEndPoint=0313
                     vEntAdq2=0108;;
               esac

               for SWTIPO in 53 353 363 412  # Procesamos los 4 reportes SWCHD Debito MC Naiguata Opcion Todos  --- 53 353
               do
               
                     vFileREPDEBMAESTRO="SGCPINCMC${vEntAdq}.REPDEBMAESTRONGTA.${vFecProc}"
                     vFileLOG="${DIRLOG}/${vFileREPDEBMAESTRO}.`date '+%Y%m%d%H%M%S'`.LOG"
                     #echo "cd $vPrefijo" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                     #echo "ls ${vpValRet_10}${SWTIPO}NA_${vEndPoint}_0502_${vNomFile_SecA}_${vFecJul}*" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                     #vARCHINC[$vADQIDX]=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\> | wc -l`
                     vArchDest="${vpValRet_10}${SWTIPO}NA_${vEndPoint}_0502_${vNomFile_SecA}_${vFecJul}"
                     vCWINLIN=`ssh ${SFTP_USER}@${SFTP_IMC_NGTA} cmd.exe /C "C:\\NAIGUATA\\transtmve_ngta_count $vArchDest"`
                     echo 
                     scp ${SFTP_USER}@${SFTP_IMC_NGTA}:/SWCHDcount $DIRIN  >> $vFileLOG 2>&1
                     vARCHINC[$vADQIDX]=`cat $DIRIN/SWCHDcount | awk '{print substr($0,1,1)}'` # SWCHDcount  primer digito 1 existe 0 no existe
                     if [ "${vARCHINC[$vADQIDX]}" -lt "1" ]
                     then
                        #echo
                        f_fhmsg "No existe el Reporte Naiguata Maestro SWCHD${SWTIPO}" >> $vFileLOG 2>&1
                        f_fhmsg "No existe el Reporte Naiguata Maestro SWCHD${SWTIPO}"     
                        sqlplus -s $DB @$DIRBIN/alertacie INC REPMAESTRO-NGTA "Reporte_de_Debito_Maestro_NGTA_Adquiriente_$vEntAdq_No_Existe"
                     fi
                     vARCHINC[$vADQIDX]=`cat $DIRIN/SWCHDcount | awk '{print substr($0,2,2)}'` # SWCHDcount  segundo digito 2 mas de uno,  0 no hay
                     if [ "${vARCHINC[$vADQIDX]}" -gt "1" ]
                     then
                        #echo
                        #echo "Existe mas de Un Reporte Naiguata Maestro ${vpValRet_10}${SWTIPO} para el Adquiriente $vEntAdq, favor revisar" | tee -a $vFileLOG
                        echo "Existe mas de Un Reporte ${vpValRet_10}${SWTIPO}, favor revisar" >> $vFileLOG 2>&1
                        sqlplus -s $DB @$DIRBIN/alertacie INC REPMAESTRO "Numero_Incorrecto_de_Archivos_de_Reporte_Debito_Maestro_Adquiriente_$vEntAdq_No_Existe"
                     fi
                     vARCHINC[$vADQIDX]=`cat $DIRIN/SWCHDcount | awk '{print substr($0,1,1)}'` # SWCHDcount  primer digito 1 existe 0 no existe
                     if [ "${vARCHINC[$vADQIDX]}" -eq "1" ]
                     then
                        #echo
                        f_msgtit2 I ${SWTIPO}
                        echo                                
                        echo "Transferencia de SWCHD desde el servidor MQFTE Naiguata a PLATINO" >> $vFileLOG 2>&1
                        f_fhmsg "Transferencia de SWCHD desde el servidor MQFTE Naiguata a PLATINO"
                        #echo
                        #vARCHINC[$vADQIDX]=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\>`
                        vARCHINC[$vADQIDX]="${vpValRet_10}${SWTIPO}NA_${vEndPoint}_0502_${vNomFile_SecA}_${vFecJul}"
                        #vArchDest=`echo ${vARCHINC[$vADQIDX]} | cut -d. -f1`
                        #vArchDest=${vArchDest}_${vEndPoint}.001
                        #vArchDest="${vpValRet_10}${SWTIPO}NA_${vEndPoint}_0502_${vNomFile_SecA}_${vFecJul}"
                        ##echo "cd $vPrefijo" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                        ##echo "get ${vARCHINC[$vADQIDX]} $DIRIN/$vArchDest" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                        #sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} | grep -v Fetching >> $vFileLOG 2>&1
                        TACCI="C1" #copia pragramada en transtmve_ngta_copy.bat
                        vCWINLIN=`ssh ${SFTP_USER}@${SFTP_IMC_NGTA} cmd.exe /C "C:\\NAIGUATA\\transtmve_ngta_copy $vArchDest $TACCI"`
                        vSTATT=$?
                        f_fhmsg  "Resibiendo desde MQFTE a PLATINO " >> $vFileLOG 2>&1
                        f_fhmsg  "Resibiendo desde MQFTE a PLATINO "
                        #echo
                        scp ${SFTP_USER}@${SFTP_IMC_NGTA}:/$vARCHINC[$vADQIDX] $DIRIN  
                        vSTATT2=$?
                        if [ "$vSTATT" != "0" ] || [ "$vSTATT2" != "0" ]; then
                           tput setf 8
                           echo "error en la transferencia ${vARCHINC[$vADQIDX]}, favor revisar" >> $vFileLOG 2>&1
                           f_fhmsg "error en la transferencia ${vARCHINC[$vADQIDX]}, favor revisar "
                           #echo 
                           tput setf 7
                           sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Error_Transferencia_de_Archivo_${vARCHINC[$vADQIDX]}_Adquiriente_$vEntAdq"
                        else
                           #vArchDestB="${vpValRet_9}${vEndPoint}_${vFecJul}_01_conv"
                           echo "Recibiendo Reporte  ${vARCHINC[$vADQIDX]} en PLATINO " >> $vFileLOG 2>&1
                           f_fhmsg "Recibiendo Reporte  ${vARCHINC[$vADQIDX]} en PLATINO " 
                           #echo
                           echo "Se envia Reporte SWCHD${SWTIPO} a platino2 (X4200)" >> $vFileLOG 2>&1
                           f_fhmsg "Se envia Reporte SWCHD${SWTIPO} a platino2 (X4200)"
                           #echo
                           #vArchDestB="${vpValRet_10}${SWTIPO}NA_${vEndPoint}_0502_${vNomFile_SecA}_${vFecJul}"                   ## Con la fecha de proceso IPR1302
                           scp -Bq $DIRIN/$vArchDest $SSSH_USER@$FTP_HOSTXCOM:/file_transfer/$COD_AMBIENTEm/${vEntAdqm}/file_out  ##/$vArchDest
                           vSTATT=$?
                           if [ "$vSTATT" != "0" ]
                           then
                              tput setf 8
                              echo "error en la transferencia al area de acceso de los Bancos, favor revisar" >> $vFileLOG 2>&1
                              f_fhmsg "error en la transferencia al area de acceso de los Bancos, favor revisar"
                              #echo
                              #f_fhmsg "Reporte $vArchDest"  
                              tput setf 7
                              sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Error_Transferencia_de_Archivo_$vArchDest_Adquiriente_$vEntAdq"
                           else
                              echo "Reporte ${vARCHINC[$vADQIDX]} enviado a platino2 (X4200)" >> $vFileLOG 2>&1
                              f_fhmsg "Reporte ${vARCHINC[$vADQIDX]} enviado a platino2 (X4200)" 
                              #echo
                              echo "Transfiriendo Reporte al disco R de GERENCIATST"  >> $vFileLOG 2>&1
                              f_fhmsg "Transfiriendo Reporte al disco R de GERENCIATST"
                              #echo
                              #vRUTAWIN1="${vARCHINC[$vADQIDX]}"                                                 ## $COD_AMBIENTE2   NUEVA VARIABLE DE AMBIENTE IPR1302
                              #vRUTAWIN2="\\T461NA\\$vArchDest"                                                  ## $vpValRet_910\\$vArchDestB"
                              vCOPIAWIN=`ssh ${SFTP_USER}@${SFTP_IMC_NGTA} cmd.exe /C "C:\\NAIGUATA\\transtmve_ngta $vArchDest $COD_AMBIENTE $vFecSes $USUARIOTMVE $CLAVETMVE"`   
                              vSTATT=$?
                              if [ "$vSTATT" != "0" ]
                              then
                                 tput setf 8
                                 echo "Error en la transferencia al Disco R, favor revisar" >> $vFileLOG 2>&1
                                 f_fhmsg "Error en la transferencia al Disco R, favor revisar"
                                 #echo
                                 #f_fhmsg "Reporte $vArchDest"
                                 echo $vCOPIAWIN | tee -a $vFileLOG
                                 tput setf 7
                                 sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Error_Transferencia_de_Archivo_$vArchDest_Adquiriente_$vEntAdq"
                              else
                                 echo "Reporte ${vARCHINC[$vADQIDX]} transferido al Disco (R)" >> $vFileLOG 2>&1
                                 f_fhmsg "Reporte ${vARCHINC[$vADQIDX]} transferido al Disco (R)"
                                 #echo 
                              fi     
                           fi
                           echo "Moviendo Reporte ${vARCHINC[$vADQIDX]} - a respaldo Naiguata" >> $vFileLOG 2>&1
                           f_fhmsg "Moviendo Reporte ${vARCHINC[$vADQIDX]}- a Respaldo Naiguata"
                           #echo
                           TACCI="C2" #copia pragramada en transtmve_ngta_copy.bat
                           vCWINLIN=`ssh ${SFTP_USER}@${SFTP_IMC_NGTA} cmd.exe /C "C:\\NAIGUATA\\transtmve_ngta_copy $vArchDest $TACCI"`
                           #echo
                           #echo "Moviendo Reporte a ${vPrefijo_Res} en Servidor MQFTE" >> $vFileLOG 2>&1
                           #f_fhmsg "Moviendo Reporte a ${vPrefijo_Res} en Servidor MQFTE"
                           #echo "rm ${vPrefijo_Res}/${vARCHINC[$vADQIDX]}" > $DIRTMP/$dpNom$vFecProc.PARRM.SFTP
                           #sftp -b $DIRTMP/$dpNom$vFecProc.PARRM.SFTP ${SFTP_USER}@$SFTP_IMC_NGTA} >> $vFileLOG 2>&1
                           #echo
                           #echo "rename ${vPrefijo}/${vARCHINC[$vADQIDX]} ${vPrefijo_Res}/${vARCHINC[$vADQIDX]}" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                           #sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} >> $vFileLOG 2>&1
                           TACCI="D1" #Borrado pragramada en transtmve_ngta_copy.bat
                           vCWINLIN=`ssh ${SFTP_USER}@${SFTP_IMC_NGTA} cmd.exe /C "C:\\NAIGUATA\\transtmve_ngta_copy $vArchDest $TACCI"`
                           #echo
                           echo "Reporte ${vARCHINC[$vADQIDX]} Movido al Direc. Respaldo" >> $vFileLOG 2>&1 #| tee -a $vFileLOG
                           f_fhmsg "Reporte ${vARCHINC[$vADQIDX]} Movido al Direc. Respaldo"  
                           echo    
                           echo "Borrando marcador SWCHDcount de archvios " >> $vFileLOG 2>&1
                           MARCA="SWCHDcount"
                           TACCI="D2" #Borrado pragramada en transtmve_ngta_copy.bat
                           vCWINLIN=`ssh ${SFTP_USER}@${SFTP_IMC_NGTA} cmd.exe /C "C:\\NAIGUATA\\transtmve_ngta_copy $MARCA $TACCI"`
                           MARPLA=`rm -rf $DIRIN/SWCHDcount` >> $vFileLOG 2>&1
                        fi
                       
                     fi
                     f_msgtit OKF
                     echo
                     vADQIDX=`expr $vADQIDX + 1`
               done
            done
            #rm $DIRTMP/$dpNom$vFecProc.PAR.SFTP
            #rm $DIRTMP/$dpNom$vFecProc.PARRM.SFTP
            DUMMY=0
            while [ "$DUMMY" != "Q" ] && [ "$DUMMY" != "q" ]
            do
               echo "Oprima Q o q <ENTER> para volver al Menu \c"
               read DUMMY
            done
            stty intr 
         else                    #Proceso por ADQUIRIENTE  IPR1302
            case $pEntAdq in
               BM)
                  vEntAdqm=bm
                  vEndPoint=0275
                  vEntAdq2=0105;;
               BP)
                 vEntAdqm=bp
                 vEndPoint=0313
                 vEntAdq2=0108;;
            esac
            f_fechora $vFecProc
            #vFecJul=`dayofyear ${vFecProc}`
            #vFecJul=`printf "%03d" $vFecJul`
            #vFecArch="$vAno-$vMes-$vDia"

            ## Ibteniendo Fecha Juliana MENOS 1 
            vFecJul=`dayofyear ${vFecProc}`    
            vFecJul=`expr ${vFecJul} - 1`      #Ajuste T464NA Este archivo es del dia de AYER ipr1302 
            vFecJul=`printf "%03d" $vFecJul`   #Ajuste T464NA Este archivo es del dia de AYER ipr1302 

            ## Corresponde al último dígito del año al que corresponde el bulk, 
            ## Es decir, el cero corresponde al año 2020 para el año venidero el valor deberá ser 1.
            vNomFile_SecA=`echo ${vFecProc} | awk '{print substr($0,4,1)}'`

            for SWTIPO in 53 353 363 412  # Procesamos los 4 reportes SWCHD Debito MC Naiguata  -- 53 353 
            do
               vFileREPDEBMAESTRO="SGCPINCMC${pEntAdq}.REPDEBMAESTRONGTA.${vFecProc}"
               vFileLOG="${DIRLOG}/${vFileREPDEBMAESTRO}.`date '+%Y%m%d%H%M%S'`.LOG"
               #echo "cd $vPrefijo" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
               #echo "ls ${vpValRet_10}${SWTIPO}NA_${vEndPoint}_0502_${vNomFile_SecA}_${vFecJul}*" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
               #vARCHINC=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\> | wc -l`
               vArchDest="${vpValRet_10}${SWTIPO}NA_${vEndPoint}_0502_${vNomFile_SecA}_${vFecJul}"
               vCWINLIN=`ssh ${SFTP_USER}@${SFTP_IMC_NGTA} cmd.exe /C "C:\\NAIGUATA\\transtmve_ngta_count $vArchDest"` 
               scp ${SFTP_USER}@${SFTP_IMC_NGTA}:/SWCHDcount $DIRIN  >> $vFileLOG 2>&1
               vARCHINC=`cat $DIRIN/SWCHDcount | awk '{print substr($0,1,1)}'` # SWCHDcount  primer digito 1 existe 0 no existe
               if [ "$vARCHINC" -lt "1" ]
               then
                  #echo
                  #echo "No existe el Reporte Debito Naiguata Maestro SWCHD$SWTIPO para el Adquiriente $pEntAdq" | tee -a $vFileLOG 
                  echo "No existe el Reporte Naiguata Maestro SWCHD$SWTIPO" >> $vFileLOG 2>&1
                  f_fhmsg "No existe el Reporte Naiguata Maestro SWCHD$SWTIPO"
                  #echo
                  sqlplus -s $DB @$DIRBIN/alertacie INC REPMAESTRO-NGTA "Reporte_de_Debito_Maestro_Adquiriente_$vEntAdq_No_Existe"
               fi
               vARCHINC=`cat $DIRIN/SWCHDcount | awk '{print substr($0,2,2)}'` # SWCHDcount  segundo digito 2 mas de uno,  0 no hay
               if [ "$vARCHINC" -gt "1" ]
               then
                  #echo
                  #echo "Existe mas de Un Archivo SWCHD$SWTIPO de Reporte Debito Maestro para el Adquiriente $pEntAdq, favor revisar" | tee -a $vFileLOG
                  echo "Existe mas de un reporte SWCHD$SWTIPO, favor revisar"  >> $vFileLOG 2>&1
                  f_fhmsg "Existe mas de un reporte SWCHD$SWTIPO, favor revisar" 
                  #echo
                  sqlplus -s $DB @$DIRBIN/alertacie INC REPMAESTRO-NGTA "Numero_Incorrecto_de_Archivos_de_Reporte_Debito_Maestro_Adquiriente_$vEntAdq_No_Existe"
               fi
               vARCHINC=`cat $DIRIN/SWCHDcount | awk '{print substr($0,1,1)}'` # SWCHDcount  primer digito 1 existe 0 no existe
               if [ "$vARCHINC" -eq "1" ]
               then
                  f_msgtit2 I ${SWTIPO}  
                  echo                                
                  echo "Transferencia de SWCHD${SWTIPO} desde MQFTE Naiguata a PLATINO" >> $vFileLOG 2>&1
                  f_fhmsg "Transferencia de SWCHD${SWTIPO} desde MQFTE Naiguata a PLATINO"
                  #echo
                  #vARCHINC=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\>`
                  vARCHINC="${vpValRet_10}${SWTIPO}NA_${vEndPoint}_0502_${vNomFile_SecA}_${vFecJul}"
                  #vArchDest=`echo ${vARCHINC} | cut -d. -f1`
                  #vArchDest=${vArchDest}_${vEndPoint}.001
                  #vArchDest="${vpValRet_10}${SWTIPO}NA_${vEndPoint}_0502_${vNomFile_SecA}_${vFecJul}"
                  #echo "cd $vPrefijo" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                  #echo "get ${vARCHINC} $DIRIN/$vArchDest" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                  #sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} | grep -v Fetching >> $vFileLOG 2>&1
                  TACCI="C1" #copia pragramada en transtmve_ngta_copy.bat
                  vCWINLIN=`ssh ${SFTP_USER}@${SFTP_IMC_NGTA} cmd.exe /C "C:\\NAIGUATA\\transtmve_ngta_copy $vArchDest $TACCI"`
                  vSTATT=$?
                  echo "Recibiendo desde MQFTE a PLATINO" >> $vFileLOG 2>&1
                  f_fhmsg "Recibiendo desde MQFTE a PLATINO" 
                  #echo
                  scp ${SFTP_USER}@${SFTP_IMC_NGTA}:/$vARCHINC $DIRIN  >> $vFileLOG 2>&1
                  vSTATT2=$?
                  if [ "$vSTATT" != "0" ] || [ "$vSTATT2" != "0" ]; then
                     tput setf 8
                     echo "error en la transferencia del reporte $vARCHINC, favor revisar" | tee -a $vFileLOG
                     f_fhmsg "error en la transferencia del reporte ${vARCHINC}, favor revisar" 
                     #echo
                     tput setf 7
                     sqlplus -s $DB @$DIRBIN/alertacie INC REPMAESTRO-NGTA "Error_Transferencia_de_Archivo_${vARCHINC[$vADQIDX]}_Adquiriente_$pEntAdq"
                  else
                     ##vArchDestB="${vpValRet_9}${vEndPoint}_${vFecJul}_01_conv"
                     echo "Recibiendo Reporte $vARCHINC en PLATINO " >> $vFileLOG 2>&1
                     f_fhmsg "Recibiendo Reporte $vARCHINC en PLATINO " 
                     #echo
                     echo "Se envia Reporte SWCHD${SWTIPO} a platino2 (X4200)" >> $vFileLOG 2>&1
                     f_fhmsg "Se envia Reporte SWCHD${SWTIPO} a platino2 (X4200)"
                     #echo
                     #vArchDestB="${vpValRet_10}${SWTIPO}NA_${vEndPoint}_0502_${vNomFile_SecA}_${vFecJul}_$vFecProc" ## Con la fecha de proceso IPR1302
                     scp -Bq $DIRIN/$vArchDest $SSSH_USER@$FTP_HOSTXCOM:/file_transfer/$COD_AMBIENTEm/${vEntAdqm}/file_out
                     vSTATT=$?
                     if [ "$vSTATT" != "0" ]
                     then
                        tput setf 8
                        echo "error en la transferencia al area de acceso de los Bancos, favor revisar"  >> $vFileLOG 2>&1
                        f_fhmsg "error en la transferencia al area de acceso de los Bancos, favor revisar"
                        #echo
                        tput setf 7
                        sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO "Error_Transferencia_de_Archivo_$vArchDest_Adquiriente_$pEntAdq"
                     else
                        echo "Reporte ${vARCHINC} enviado a platino2 (X4200)" >> $vFileLOG 2>&1
                        f_fhmsg "Reporte ${vARCHINC} enviado a platino2 (X4200)" 
                        #echo
                        echo "Transfiriendo Reporte al disco R de GERENCIATST" >> $vFileLOG 2>&1
                        f_fhmsg "Transfiriendo Reporte al disco R de GERENCIATST"
                        #echo
                        vCOPIAWIN=`ssh ${SFTP_USER}@${SFTP_IMC_NGTA} cmd.exe /C "C:\\NAIGUATA\\transtmve_ngta ${vARCHINC} $COD_AMBIENTE $vFecSes $USUARIOTMVE $CLAVETMVE"`
                        vSTATT=$?
                        if [ "$vSTATT" != "0" ]
                        then
                           tput setf 8
                           echo "error en la transferencia del reporte al Disco R, favor revisar" >> $vFileLOG 2>&1
                           f_fhmsg "error en la transferencia del reporte al Disco R, favor revisar"
                           #echo
                           echo $vCOPIAWIN | tee -a $vFileLOG
                           tput setf 7
                           sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Error_Transferencia_de_Archivo_$vArchDest_Adquiriente_$vEntAdq"
                        else
                           echo "Reporte ${vARCHINC} enviado al Disco (R)" >> $vFileLOG 2>&1
                           f_fhmsg "Reporte ${vARCHINC} enviado al Disco (R)"
                           #echo
                        fi                            
                     fi
                     echo "Moviendo Reporte ${vARCHINC} a respaldo Naiguata" >> $vFileLOG 2>&1
                     f_fhmsg "Moviendo Reporte ${vARCHINC} a Respaldo Naiguata"
                     #echo
                     TACCI="C2" #copia pragramada en transtmve_ngta_copy.bat
                     vCWINLIN=`ssh ${SFTP_USER}@${SFTP_IMC_NGTA} cmd.exe /C "C:\\NAIGUATA\\transtmve_ngta_copy $vArchDest $TACCI"`
                     #echo "rm ${vPrefijo_Res}/${vARCHINC}" > $DIRTMP/$dpNom$vFecProc.PARRM.SFTP
                     #sftp -b $DIRTMP/$dpNom$vFecProc.PARRM.SFTP ${SFTP_USER}@$SFTP_IMC_NGTA} >> $vFileLOG 2>&1
                     #echo
                     #echo "rename ${vPrefijo}/${vARCHINC} ${vPrefijo_Res}/${vARCHINC}" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                     #sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} >> $vFileLOG 2>&1
                     TACCI="D1" #Borrado pragramada en transtmve_ngta_copy.bat
                     vCWINLIN=`ssh ${SFTP_USER}@${SFTP_IMC_NGTA} cmd.exe /C "C:\\NAIGUATA\\transtmve_ngta_copy $vArchDest $TACCI"`
                     #echo
                     echo "Reporte $vARCHINC Movido al Direc. Respaldo MQFTE" >> $vFileLOG 2>&1  #| tee -a $vFileLOG
                     f_fhmsg "Reporte $vARCHINC Movido al Direc. Respaldo MQFTE"
                     echo
                     echo "Borrando marcador SWCHDcount de archivos " >> $vFileLOG 2>&1
                     MARCA="SWCHDcount"
                     TACCI="D2" #Borrado pragramada en transtmve_ngta_copy.bat
                     vCWINLIN=`ssh ${SFTP_USER}@${SFTP_IMC_NGTA} cmd.exe /C "C:\\NAIGUATA\\transtmve_ngta_copy $MARCA $TACCI"`
                     MARPLA=`rm -rf $DIRIN/SWCHDcount`   >> $vFileLOG 2>&1
                     f_msgtit OKF
                  fi
               fi
            done
            #rm $DIRTMP/$dpNom$vFecProc.PAR.SFTP
            DUMMY=0
            while [ "$DUMMY" != "Q" ] && [ "$DUMMY" != "q" ]
            do
               echo "Oprima Q o q <ENTER> para volver al Menu \c"
               read DUMMY
            done
         fi
      fi

   fi # Opcion 5 - Proceso Reporte Debito Maestro


   # PROCESO DE REPORTE CREDITO MASTERCARD

   if [ "$vOpcion" = "6" ]; then

      vFlgOpcErr="N"
      vOpcion=""

      # Verifica el Estado del Proceso en el Archivo de Control

      f_msg
      f_msg " Proceso: REPORTE DE CREDITO MASTERCARD" N S
      f_msg
      f_msg
      f_fechora $vFecProc
      f_msg "    Fecha de Proceso: $vpValRet" N S
      f_msg
      echo " Desea Continuar? (S=Si/N=No/<Enter>=No) => \c"
      read ValConf
      echo "Ingresar Usuario Windows para Transferencia Disco J: \c"
      read USUARIOTMVE
      echo "Ingresar Clave Windows para Transferencia Disco J: \c"
      stty -echo
      read CLAVETMVE
      stty echo
#      echo $CLAVETMVE
      f_msg
      f_msg

      if [ "$ValConf" = "s" ] || [ "$ValConf" = "S" ]
      then
         case $COD_AMBIENTE in
            DESA)
              vPrefijo="/TEST";;
            CCAL)
              vPrefijo="/TEST";;
            PROD)
              vPrefijo="/PROD";;
         esac
         vPrefijoWin=`echo $vPrefijo | sed -e 's/\///'`
         DiaSemana=`date +%u`
#         DiaSemana=`sqlplus -s $DB << !
#set head off
#set pagesize 0000
#select to_char(to_date('$vFecProc','YYYYMMDD'),'D') from dual;
#!` #

         if [ "$pEntAdq" = "TODOS" ]
         then
            stty intr 
            vADQIDX=0
            vTRANS150=0
            vERRORTRANS150=0
            f_fechora $vFecProc
            vFecArch="$vAno-$vMes-$vDia"
            vFecJul=`dayofyear ${vFecProc}`
            vFecJul=`printf "%03d" $vFecJul`
            for vEntAdq in BM BP
            do
              case $vEntAdq in
                 BM)
                   vEndPoint=01857;;
                 BP)
                   vEndPoint=01858;;
              esac
              vFileREPCREDMC="SGCPINCMC${vEntAdq}.REPCREDMC.${vFecProc}"
              vFileLOG="${DIRLOG}/${vFileREPCREDMC}.`date '+%Y%m%d%H%M%S'`.LOG"
              echo "cd $vPrefijo/$vEntAdq/T$vpValRet_8" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
              echo "ls TT${vpValRet_8}T0.${vFecArch}*" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
              vARCHINC[$vADQIDX]=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\> | wc -l`
              if [ "${vARCHINC[$vADQIDX]}" -eq "0" ] && [ "$DiaSemana" -eq "1" ]
              then
                 echo "Dia Domingo, No hay Archivos $vpValRet_8 para Transferir" | tee -a $vFileLOG
                 vTRANS150=0
              fi
              if [ "${vARCHINC[$vADQIDX]}" -ne "6" ] && [ "$DiaSemana" -ne "1" ]
              then
#                 echo ${vARCHINC[$vADQIDX]}
                 echo "Numero Incorrecto de Archivos de REPORTE CREDITO MASTERCARD para el Adquiriente $vEntAdq" | tee -a $vFileLOG
                 sqlplus -s $DB @$DIRBIN/alertacie INC REPMASTERCARD "Archivo_de_Reporte_Credito_MasterCard_Adquiriente_$vEntAdq_Nro_Archivos_Incorrecto"
                 vTRANS150=0
              fi
              if [ "${vARCHINC[$vADQIDX]}" -eq "6" ] && [ "$DiaSemana" -eq "1" ]
              then
                 echo "Se encontraron Archivos de Reporte recibidos un dia Domingo para el Adquiriente $vEntAdq" | tee -a $vFileLOG
                 sqlplus -s $DB @$DIRBIN/alertacie INC REPMASTERCARD "Archivo_de_Reporte_Credito_MasterCard_Adquiriente_$vEntAdq_Archivos_a_Destiempo"
                 vTRANS150=0
              fi
              if [ "${vARCHINC[$vADQIDX]}" -eq "6" ] && [ "$DiaSemana" -ne "1" ]
              then
                 vTRANS150=1
                 vARCHINC[$vADQIDX]=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\> | sort`
                 echo "cd $vPrefijo/$vEntAdq/T$vpValRet_8" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                 for vARCHIVOSINC in ${vARCHINC[$vADQIDX]}
                 do
                    echo "get $vARCHIVOSINC $DIRIN/$vARCHIVOSINC" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                 done
                 sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} | grep -v Fetching >> $vFileLOG 2>&1
                 vSTATT=$?
                 if [ "$vSTATT" -ne "0" ]
                 then
                    vERRORTRANS150=1
                    tput setf 8
                    echo "error en la transferencia de los archivos ${vARCHINC[$vADQIDX]} del adquiriente $vEntAdq, favor revisar" | tee -a $vFileLOG
                    tput setf 7
                    sqlplus -s $DB @$DIRBIN/alertacie INC REPMASTERCARD "Error_Transferencia_de_Archivos_${vARCHINC[$vADQIDX]}_Adquiriente_$vEntAdq"
                 else
                    vERRORTRANS150=0
                 fi
              fi
              if [ "$vTRANS150" -eq "1" ] && [ "$vERRORTRANS150" -eq "0" ]
              then
                    vCONTADORSEQ=1
                    rm $DIRTMP/$dpNom$vFecProc.PAR.SFTP 
                    for vARCHIVOSINC in ${vARCHINC[$vADQIDX]}
                    do
                       vNumSec=`printf "%02d" $vCONTADORSEQ`
                       vArchDest=${vpValRet_8}${vEndPoint}_${vFecJul}_${vNumSec}_conv
                       mv $DIRIN/$vARCHIVOSINC $DIRIN/$vArchDest
                       echo " "
                       echo "Archivo $vARCHIVOSINC Transferido a $vArchDest" | tee -a $vFileLOG
                       echo "Transfiriendo Archivo al disco J de SRVCCSALC" | tee -a $vFileLOG
                       vRUTAWIN1="$vPrefijoWin\\${vEntAdq}\\T$vpValRet_8\\${vARCHIVOSINC}"
                       vRUTAWIN2="\\$vpValRet_8\\$vArchDest"
                       vCOPIAWIN=`ssh ${SFTP_USER}@${SFTP_IMC_NGTA} cmd.exe /C "C:\\MFESFTP\\transtmve $vRUTAWIN1 $vPrefijoWin $vRUTAWIN2 $USUARIOTMVE $CLAVETMVE"`
                       vSTATT=$?
                       if [ "$vSTATT" != "0" ]
                       then
                          tput setf 8
                          echo "error en la transferencia del archivo $vArchDest del adquiriente $vEntAdq al Disco J de SRVCCSALC, favor revisar" | tee -a $vFileLOG
                          echo $vCOPIAWIN | tee -a $vFileLOG
                          tput setf 7
                          sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO "Error_Transferencia_de_Archivo_$vArchDest_Adquiriente_$vEntAdq"
                       else
                         echo "Archivo ${vARCHIVOSINC} transferido correctamente al Servidor SRVCCSALC (J)"
                       fi
                       echo "rename $vPrefijo/$vEntAdq/T$vpValRet_8/$vARCHIVOSINC  $vPrefijo/$vEntAdq/T$vpValRet_8/RESPALDO/$vARCHIVOSINC" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
#                       ls -l $DIRIN/$vArchDest
                       vCONTADORSEQ=`expr $vCONTADORSEQ + 1`
                    done
                    sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} > /dev/null 2>&1
              fi
              vADQIDX=`expr $vADQIDX + 1`
            done
            rm $DIRTMP/$dpNom$vFecProc.PAR.SFTP
            DUMMY=0
            while [ "$DUMMY" != "Q" ] && [ "$DUMMY" != "q" ]
            do
               echo "Oprima Q o q <ENTER> para volver al Menu \c"
               read DUMMY
            done
            stty intr 
         else
            stty intr 
            vTRANS150=0
            vERRORTRANS150=0
            f_fechora $vFecProc
            vFecArch="$vAno-$vMes-$vDia"
            vFecJul=`dayofyear ${vFecProc}`
            vFecJul=`printf "%03d" $vFecJul`
            vFileREPCREDMC="SGCPINCMC${pEntAdq}.REPCREDMC.${vFecProc}"
            vFileLOG="${DIRLOG}/${vFileREPCREDMC}.`date '+%Y%m%d%H%M%S'`.LOG"
            case $pEntAdq in
               BM)
                 vEndPoint=01857;;
               BP)
                 vEndPoint=01858;;
            esac
            echo "cd $vPrefijo/$pEntAdq/T$vpValRet_8" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
            echo "ls TT${vpValRet_8}T0.${vFecArch}*" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
            vARCHINC=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\> | wc -l`
            if [ "${vARCHINC}" -eq "0" ] && [ "$DiaSemana" -eq "1" ]
            then
               echo "Dia Domingo, No hay Archivos 150 para Transferir" | tee -a $vFileLOG
               vTRANS150=0
            fi
            if [ "${vARCHINC}" -ne "6" ] && [ "$DiaSemana" -ne "1" ]
            then
               echo "Numero Incorrecto de Archivos de REPORTE CREDITO MASTERCARD para el Adquiriente $pEntAdq" | tee -a $vFileLOG
               sqlplus -s $DB @$DIRBIN/alertacie INC REPMASTERCARD "Archivo_de_Reporte_Credito_MasterCard_Adquiriente_$pEntAdq_Nro_Archivos_Incorrecto"
            fi
            if [ "${vARCHINC}" -eq "6" ] && [ "$DiaSemana" -eq "1" ]
            then
               echo "Se encontraron Archivos de Reporte recibidos un dia Domingo para el Adquiriente $pEntAdq" | tee -a $vFileLOG
               sqlplus -s $DB @$DIRBIN/alertacie INC REPMASTERCARD "Archivo_de_Reporte_Credito_MasterCard_Adquiriente_$pEntAdq_Archivos_a_Destiempo"
               vTRANS150=0
            fi
            if [ "${vARCHINC}" -eq "6" ] && [ "$DiaSemana" -ne "1" ]
            then
               vTRANS150=1
               vARCHINC=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\> | sort`
               echo "cd $vPrefijo/$pEntAdq/T$vpValRet_8" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
               for vARCHIVOSINC in ${vARCHINC}
               do
                  echo "get $vARCHIVOSINC $DIRIN/$vARCHIVOSINC" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
               done
               sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} | grep -v Fetching >> $vFileLOG 2>&1
               vSTATT=$?
               if [ "$vSTATT" -ne "0" ]
               then
                  vERRORTRANS150=1
                  tput setf 8
                  echo "error en la transferencia de los archivos ${vARCHINC} del adquiriente $pEntAdq, favor revisar" | tee -a $vFileLOG
                  tput setf 7
                  sqlplus -s $DB @$DIRBIN/alertacie INC REPMASTERCARD "Error_Transferencia_de_Archivos_${vARCHINC}_Adquiriente_$pEntAdq"
               else
                  vERRORTRANS150=0
               fi
            fi
            if [ "$vTRANS150" -eq "1" ] && [ "$vERRORTRANS150" -eq "0" ]
            then
                  vCONTADORSEQ=1
                  rm $DIRTMP/$dpNom$vFecProc.PAR.SFTP 
                  for vARCHIVOSINC in ${vARCHINC}
                  do
                     vNumSec=`printf "%02d" $vCONTADORSEQ`
                     vArchDest=${vpValRet_8}${vEndPoint}_${vFecJul}_${vNumSec}_conv
                     mv $DIRIN/$vARCHIVOSINC $DIRIN/$vArchDest
                     echo " "
                     echo "Archivo $vARCHIVOSINC Transferido a $vArchDest" | tee -a $vFileLOG
                     echo "Transfiriendo Archivo al disco J de SRVCCSALC" | tee -a $vFileLOG
                     vRUTAWIN1="$vPrefijoWin\\${pEntAdq}\\T$vpValRet_8\\${vARCHIVOSINC}"
                     vRUTAWIN2="\\$vpValRet_8\\$vArchDest"
                     vCOPIAWIN=`ssh ${SFTP_USER}@${SFTP_IMC_NGTA} cmd.exe /C "C:\\MFESFTP\\transtmve $vRUTAWIN1 $vPrefijoWin $vRUTAWIN2 $USUARIOTMVE $CLAVETMVE"`
                     vSTATT=$?
                     if [ "$vSTATT" != "0" ]
                     then
                        tput setf 8
                        echo "error en la transferencia del archivo $vArchDest del adquiriente $pEntAdq al Disco J de SRVCCSALC, favor revisar" | tee -a $vFileLOG
                        echo $vCOPIAWIN | tee -a $vFileLOG
                        tput setf 7
                        sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO "Error_Transferencia_de_Archivo_$vArchDest_Adquiriente_$pEntAdq"
                     else
                       echo "Archivo ${vARCHIVOSINC} transferido correctamente al Servidor SRVCCSALC (J)"
                     fi
                     echo "rename $vPrefijo/$vEntAdq/T$vpValRet_8/$vARCHIVOSINC  $vPrefijo/$pEntAdq/T$vpValRet_8/RESPALDO/$vARCHIVOSINC" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
#                     ls -l $DIRIN/$vArchDest | tee -a $vFileLOG
                     vCONTADORSEQ=`expr $vCONTADORSEQ + 1`
                  done
                  sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} >> $vFileLOG 2>&1
            fi
            rm $DIRTMP/$dpNom$vFecProc.PAR.SFTP
            DUMMY=0
            while [ "$DUMMY" != "Q" ] && [ "$DUMMY" != "q" ]
            do
               echo "Oprima Q o q <ENTER> para volver al Menu \c"
               read DUMMY
            done
         fi
      fi
   fi # Opcion 6 - Proceso de Reporte Credito MasterCard


   # OPCION DE LOG DE PROCESOS

   if [ "$vOpcion" = "7" ]; then
         vFlgOpcErr="N"
         vOpcion=""
         trap "trap '' 2" 2
         SGCPINCMCADQLOGmenu.sh ${pEntAdq} ${vFecProc}
         trap ""
   fi # Opcion 7 - LOG de Procesos


   # OPCION DE REPROCESO

   if [ "$vOpcion" = "8" ]; then

      vFlgOpcErr="N"
      vOpcion=""

      echo
      if [ "$vOpcRepro" = "N" ]; then
         echo " Desea ACTIVAR la Opcion de Reproceso? (S=Si/N=No/[Enter]=NO) => \c"
      else
         echo " Desea DESACTIVAR la Opcion de Reproceso? (S=Si/N=No/[Enter]=NO) => \c"
      fi
      read vSelOpcRepro

      if [ "$vSelOpcRepro" = "" ]; then
         vSelOpcRepro="N"
      elif [ "$vSelOpcRepro" = "s" ]; then
           vSelOpcRepro="S"
      elif [ "$vSelOpcRepro" = "n" ]; then
           vSelOpcRepro="N"
      fi

      if [ "$vSelOpcRepro" = "S" ]; then
           if [ "$vOpcRepro" = "N" ]; then
              vOpcRepro="S"
           else
              vOpcRepro="N"
           fi
      else
         if [ "$vSelOpcRepro" != "N" ]; then
            echo
            f_fhmsg "Opcion Incorrecta."
            echo
            echo "... presione [ENTER] para continuar."
            read vContinua
         fi
      fi

   fi  # Opcion 8 - Opcion de Reproceso


   if [ "$vFlgOpcErr" = "S" ]; then
      vOpcion=""
      echo
      f_msg "${dpNom} - Opcion Incorrecta."
      echo
      echo "... presione [ENTER] para continuar."
      read vContinua
   fi

done

################################################################################
## FIN | PROCEDIMIENTO PRINCIPAL
################################################################################
