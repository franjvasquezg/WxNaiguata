#!/bin/ksh 

################################################################################
##
##  Nombre del Programa : SGCPINCMCADQmenu.sh
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
##
################################################################################

################################################################################
## DECLARACION DE DATOS, PARAMETROS DE EJECUCION Y VARIABLES DEL PROGRAMA
################################################################################


## Datos del Programa
################################################################################

dpNom="SGCPINCMCADQmenu_ngta"      # Nombre del Programa
dpDesc=""                     # Descripcion del Programa
dpVer=3.00                    # Ultima Version del Programa
dpFec="20200203"              # Fecha de Ultima Actualizacion [Formato:AAAAMMDD]

## Variables del Programa
################################################################################

vpValRet=""                   # Valor de Retorno (funciones)
vpFH=`date '+%Y%m%d%H%M%S'`   # Fecha y Hora [Formato:AAAAMMDDHHMMSS]
vpFileLOG=""                  # Nombre del Archivo LOG del Programa


## Parametros
################################################################################

pEntAdq="$1"                  # Entidad Adquirente [BM/BP/TODOS]
pFecProc="$2"                 # Fecha de Proceso [Formato:AAAAMMDD]


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
      echo "*                  Incoming de MasterCard (Banco Mercantil)                   *"
   elif [ "$pEntAdq" = "BP" ]; then
        echo "*                  Incoming de MasterCard (Banco Provincial)                  *"
   elif [ "$pEntAdq" = "TODOS" ]; then
        echo "*                  Incoming de MasterCard (GENERAL)                           *"
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
   echo " Fecha de Proceso: ${vFecProcF}                                     Reproceso: $vRepro"

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

   echo "-------------------------------------------------------------------------------"
   echo
   echo "CARGA DE ENTRANTES                                    REPORTES"
   echo "-----------------------------------------             -------------------------"

   echo "[ 1] Carga de INC NGTA Debito Maestro (${vpValRet_6})           [ 5] Debito Maestro (${vpValRet_9})"
   echo "[ 2] Carga de INC y Retornos NGTA Credito (${vpValRet_3}-${vpValRet_4})   [ 6] Credito MC (${vpValRet_8})"
   ## La Carga de Bines y Tipos de Cambio Es omitido para NAIGUATA
   echo "                                                      CONSULTAS"
   echo "                                                      -------------------------"
   echo "                                                      [ 7] Log de Procesos"
   echo ""
   echo "                                                      REPROCESO"
   echo "                                                      -------------------------"
   echo "                                                      [ 8] Reproceso"
   echo
   echo "-------------------------------------------------------------------------------"
   echo " Ver $dpVer | Telefonica Servicios Transaccionales                     [Q] Salir"
   echo "-------------------------------------------------------------------------------"

}

find_footer ()
{
for sec in 1 251 501 751;
do
    pie=`awk -F '/FTRL/' ${DIRIN}/another/${fT464} | awk '{print substr($0,'${sec}',250)}' | grep -i 'FTRL' | grep -v 'STRL' | awk '{print substr($0,0,4)}'`
    vFOOTER=${pie}
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


   # CARGA DE INCOMING DEBITO MAESTRO NAIGUATA 
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
      f_msg " Proceso: CARGA DE INCOMING DEBITO MAESTRO" N S
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
              vPrefijo="/TDD/Entrada"
              vPrefijo_Res="/TDD/Entrada/RESPALDO"
              ;;
            CCAL)
              vPrefijo="/TDD/Entrada"
              vPrefijo_Res="/TDD/Entrada/RESPALDO"
              ;;
            PROD)
              vPrefijo="/TDD/Entrada"
              vPrefijo_Res="/TDD/Entrada/RESPALDO"   #IPR 1302 RUTA PRODUCCION
              ;;    
         esac
         ## Se carga las variable para todos las opciones TODOS ó BP & BM Independiente 
         ## Ibteniendo Fecha Juliana MENOS 1 
         vFecJul=`dayofyear ${vFecProc}`    
         vFecJul=`expr ${vFecJul} - 1`      #Ajuste T464NA Este archivo es del dia de AYER ipr1302 
         vFecJul=`printf "%03d" $vFecJul`   #Ajuste T464NA Este archivo es del dia de AYER ipr1302 

         ## Corresponde al último dígito del año al que corresponde el bulk, 
         ## Es decir, el cero corresponde al año 2020 para el año venidero el valor deberá ser 1.
         vNomFile_SecA=`echo ${pFecProc} | awk '{print substr($0,4,1)}'`

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
                   vEndPoint=0275;;
                 BP)
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
                 echo "No existe el Archivo de Incoming Debito Naiguata Maestro para el Adquiriente $vEntAdq - ${vEndPoint}"| tee -a $vFileLOG
                 tput setf 7
                 sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Archivo_de_Debito_NAiguata_Maestro_Adquiriente_$vEntAdq_No_Existe"
              fi
              if [ "${vARCHINC[$vADQIDX]}" -gt "1" ]
              then
                 tput setf 8
                 echo "Existe mas de Un Archivo de Incoming Debito Maestro Naiguata para el Adquiriente $vEntAdq - ${vEndPoint}, favor revisar" | tee -a $vFileLOG
                 tput setf 7
                 sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Numero_Incorrecto_de_Archivos_de_Debito_Naiguata_Maestro_Adquiriente_$vEntAdq_No_Existe"
              fi
              if [ "${vARCHINC[$vADQIDX]}" -eq "1" ]
              then
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
                    echo "error en la transferencia del archivo Ngta ${vARCHINC[$vADQIDX]} del adquiriente $vEntAdq - ${vEndPoint}, favor revisar" | tee -a $vFileLOG
                    tput setf 7
                    sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Error_Transferencia_de_Archivo_${vARCHINC[$vADQIDX]}_Adquiriente_$vEntAdq - ${vEndPoint}"
                 else
                    echo "Archivo ${vARCHINC[$vADQIDX]} Transferido Correctamente"
                    vENCABEZADO=`head -1 $DIRIN/$vArchDest | awk '{print substr($0,0,4)}'`
                    # Buscar el footer y lo almacena en la variable --> vFOOTER
                    find_footer $DIRIN/$vArchDest           

                    if [ "$vENCABEZADO" = "FHDR" ] && [ "$vFOOTER" = "FTRL" ]
                    then
                       echo "Verificacion de Encabezado y Fin de Archivo Completada Correctamente" | tee -a $vFileLOG
                       vCONSIST=1
                    else
                       tput setf 8
                       echo "Verificacion de Encabezado y Fin de Archivo Fallida" | tee -a $vFileLOG
                       tput setf 7
                       sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Error_Consistencia_de_Archivo_${vARCHINC[$vADQIDX]}_Adquiriente_$vEntAdq - ${vEndPoint}"
                       vCONSIST=0
                    fi
                 fi
              
               #  PREOCESAMIENTO Y CARGA EN BD DE ARCHIVOS T464NA  NAIGUATA
				 
                 if [ "$vCONSIST" = "0" ]
                 then
                       tput setf 8
                       echo "No se Procesara el Archivo ${vARCHINC[$vADQIDX]}" | tee -a $vFileLOG
                       tput setf 7
                       sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Archivo_${vARCHINC[$vADQIDX]}_Adquiriente_${vEndPoint}_$vEntAdq_No_Procesado"
                 else
                     f_msg "-----------Convirtiendo archivos T464Na_vEndPoint_0502_0_conv-------------------" N S #IPR1302 18032020
                     trap "trap '' 2" 2
                     ${DIRBIN}/conver_NGTA_T464NA.sh $DIRIN/$vArchDest
                     trap ""               #En caso que falle IPR1302 fjvg 25082020
                     if [ -f "$DIRIN/$vArchDest_conv" ]; then
                        echo " "
                        echo "Archivo ${vARCHINC[$vADQIDX]} Movido al Directorio Procesado(E)" | tee -a $vFileLOG
                        echo "rm $vPrefijo/$vEntAdq/T$vpValRet_6/RESPALDO/${vARCHINC[$vADQIDX]}" > $DIRTMP/$dpNom$vFecProc.PARRM.SFTP
                        echo "rename $vPrefijo/$vEntAdq/T$vpValRet_6/${vARCHINC[$vADQIDX]} $vPrefijo/$vEntAdq/T$vpValRet_6/RESPALDO/${vARCHINC[$vADQIDX]}" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                        sftp -b $DIRTMP/$dpNom$vFecProc.PARRM.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} >> $vFileLOG 2>&1
                        sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} >> $vFileLOG 2>&1
                        f_msg "--------------------------------------------------------------------------------" N S
                        f_msg
                        echo
                        echo "         Archivo de Control : `basename ${vFileCTL}`"
                        echo "                 Directorio : `dirname ${vFileCTL}`"
                        echo "   Archivo LOG de Ejecucion : `basename ${vFileLOG}`"
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
                           #vArchDestB="${vpValRet_6}${vEndPoint}_${vFecJul}_01_conv"
                           #Se envía transferencia al XCOM del archivo convertido - Retomado en el IPR 1156 Fase IV
                           #scp -Bq $DIRIN/$vArchDest $SSSH_USER@$FTP_HOSTXCOM:${vEntAdq}pu_fileout/$vArchDestB
                           scp -Bq $DIRIN/$vArchDest* $SSSH_USER@$FTP_HOSTXCOM:/file_transfer/${COD_AMBIENTE}/${vEntAdq}/file_out
                           vSTATT=$?
                           if [ "$vSTATT" != "0" ]
                              then
                                 tput setf 8
                                 echo "error en la transferencia del archivo $vArchDest del adquiriente $vEntAdq al area de acceso de los Bancos, favor revisar" | tee -a $vFileLOG
                                 tput setf 7
                                 sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO "Error_Transferencia_de_Archivo_$vArchDest_Adquiriente_$vEntAdq"
                           else
                              echo "Archivo Transferido correctamente al area de acceso de los Bancos"
                              echo
                              echo "Respaldando archivos T464NA procesados - ${vPrefijo_Res} en Servidor MQFTE" >> $vFileLOG 2>&1
                              echo "Respaldando archivos T464NA procesados - ${vPrefijo_Res} en Servidor MQFTE" 
                              scp -Bq $DIRIN/$vArchDest* ${SFTP_USER}@${SFTP_IMC_NGTA}:/${vPrefijo_Res}

                           fi  ####Fin de la modificación GlobalR IPR1156
                           mv $DIRIN/$vArchDest $DIRIN/${vArchDest}_bkp
                           mv $DIRIN/$vArchDest_conv $DIRIN/${vArchDest_conv}_bkp
                        fi
                     else
                        echo "Generacion de archivo T464NA-CONV Fallida" | tee -a $vFileLOG
                       tput setf 7
                       sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Error_ARCHIVOS T464NA-CONV_${vARCHINC[$vADQIDX]}_Adquiriente_$vEntAdq - ${vEndPoint}"
                       
                     fi  
                 fi
              fi
              vADQIDX=`expr $vADQIDX + 1`
            done
            rm $DIRTMP/$dpNom$vFecProc.PAR.SFTP 2>/dev/null
            rm $DIRTMP/$dpNom$vFecProc.PARRM.SFTP 2>/dev/null
            rm $DIRIN/$vArchDest 2>/dev/null
            rm $DIRIN/$vArchDest_conv 2>/dev/null
            DUMMY=0
            while [ "$DUMMY" != "Q" ] && [ "$DUMMY" != "q" ]
            do
               echo "Oprima Q o q <ENTER> para volver al Menu \c"
               read DUMMY
            done
            stty intr 
         else         ## INICIO OPCION POR ADQUIRIENTES 
            stty intr 
            case $pEntAdq in
               BM)
                 vEndPoint=0275;;
               BP)
                 vEndPoint=0313;;
              esac
            f_fechora $vFecProc
            vFecJul=`dayofyear ${vFecProc}`
            vFecJul=`printf "%03d" $vFecJul`
            vFecArch="$vAno-$vMes-$vDia"
            vFileINCMAESTRO="SGCPINCMC${pEntAdq}.INCMAESTRONGTA.${vFecProc}"
            vFileCTL="${DIRDAT}/${vFileINCMAESTRO}.CTL"
            vFileLOG="${DIRLOG}/${vFileINCMAESTRO}.`date '+%Y%m%d%H%M%S'`.LOG"
            vFileLOG1="${DIRLOG}/${vFileINCMAESTRO}.`date '+%Y%m%d%H%M%S'`.LOG.tmp"
            vEstProc=`awk '{print substr($0,13,1)}' $vFileCTL 2>/dev/null`
            if [ "$vEstProc" = "F" ] && [ "$vOpcRepro" != "S" ]
            then
               tput setf 8
               echo "el Incoming de Debito Maestro Naiguata para este dia ya ha sido procesado"
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
               echo "cd $vPrefijo/$pEntAdq/T$vpValRet_6" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
               echo "ls T${vpValRet_6}"NA"_${vEndPoint}_"0502"_${vNomFile_SecA}_${vFecJul}*" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
               vARCHINC=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\> | wc -l`
               if [ "$vARCHINC" -lt "1" ]
               then
                  tput setf 8
                  echo "No existe el Archivo de Incoming Debito Maestro para el Adquiriente $pEntAdq - ${vEndPoint}" | tee -a $vFileLOG
                  tput setf 7
                  sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Archivo_de_Debito_Maestro_Adquiriente_$pEntAdq_No_Existe"
               fi
               if [ "$vARCHINC" -gt "1" ]
               then
                  tput setf 8
                  echo "Existe mas de Un Archivo de Incoming Debito Maestro Naiguata para el Adquiriente $pEntAdq, favor revisar" | tee -a $vFileLOG
                  tput setf 7
                  sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Numero_Incorrecto_de_Archivos_de_Debito_Naiguata_Maestro_Adquiriente_$pEntAdq_No_Existe"
               fi
               if [ "$vARCHINC" -eq "1" ]
               then
                  vARCHINC=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\>`
                  #vNumSec=`echo $vARCHINC | cut -d. -f3`
                  #vNumSec=`printf "%02d" $vNumSec`
                  #vArchDest="${vpValRet_6}${vEndPoint}_${vFecJul}_${vNumSec}_conv"
                  #echo "cd $vPrefijo/$pEntAdq/T$vpValRet_6" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                  #echo "get $vARCHINC $DIRIN/$vArchDest" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
		            #  echo "get $vARCHINC $DIRIN/$vARCHINC" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP   #Eliminado GlobalR IPR1156 para traer archivo con formato TT${vpValRet_6}T0 Fase IV
                  #sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} | grep -v Fetching >> $vFileLOG 2>&1
                  
                  vArchDest="T${vpValRet_6}"NA"_${vEndPoint}_"0502"_${vNomFile_SecA}_${vFecJul}"
                  vArchDest_conv="T${vpValRet_6}"NA"_${vEndPoint}_"0502"_${vNomFile_SecA}_${vFecJul}_conv"
                  echo "cd $vPrefijo/" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                  echo "get $vARCHINC $DIRIN/$vArchDest" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                  sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} | grep -v Fetching >> $vFileLOG 2>&1
                  vSTATT=$?
                  if [ "$vSTATT" != "0" ]
                  then
                     tput setf 8
                     echo "error en la transferencia del archivo Ngta $vARCHINC del adquiriente $pEntAdq - ${vEndPoint}, favor revisar" | tee -a $vFileLOG
                     tput setf 7
                     sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Error_Transferencia_de_Archivo_${vARCHINC}_Adquiriente_$pEntAdq - ${vEndPoint}"
                  else
                    echo "Archivo $vARCHINC Transferido Correctamente"
                    vENCABEZADO=`head -1 $DIRIN/$vArchDest | awk '{print substr($0,0,4)}'`
                    #vFOOTER=`tail -2 $DIRIN/$vArchDest | head -1 | awk '{print substr($0,0,4)}'`
                    find_footer $DIRIN/$vArchDest

                    if [ "$vENCABEZADO" = "FHDR" ] && [ "$vFOOTER" = "FTRL" ]
                    then
                       echo "Verificacion de Encabezado y Fin de Archivo Completada Correctamente" | tee -a $vFileLOG
                       vCONSIST=1
                    else
                       tput setf 8
                       echo "Verificacion de Encabezado y Fin de Archivo Fallida" | tee -a $vFileLOG
                       tput setf 7
                       sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Error_Consistencia_de_Archivo_${vARCHINC}_Adquiriente_$pEntAdq - ${vEndPoint}"
                       vCONSIST=0
                    fi
                  fi
            
               #  PRECESAMIENTO Y CARGA EN BD DE ARCHIVOS T464NA  NAIGUATA POR ADQUIRIENTE

               if [ "$vCONSIST" = "0" ]
               then
                     tput setf 8
                     echo "No se Procesara el Archivo ${vARCHINC}" | tee -a $vFileLOG
                     tput setf 7
                     sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Archivo_${vARCHINC}_Adquiriente_${vEndPoint}_$pEntAdq_No_Procesado"
               else
                  f_msg "-----------Convirtiendo archivos T464Na_vEndPoint_0502_0_conv-------------------" N S #IPR1302 18032020
                  trap "trap '' 2" 2
                  ${DIRBIN}/conver_NGTA_T464NA.sh $DIRIN/$vArchDest
                  trap ""                                                        #En caso que falle IPR1302 fjvg 25082020
		            if [ -f "$DIRIN/$vArchDest_conv" ]; then
                     echo " "
                     echo "Archivo $vARCHINC Movido al Directorio Procesado(E)" | tee -a $vFileLOG
                     echo "rm $vPrefijo/$vEntAdq/T$vpValRet_6/RESPALDO/$vARCHINC" > $DIRTMP/$dpNom$vFecProc.PARRM.SFTP
                     echo "rename $vPrefijo/$vEntAdq/T$vpValRet_6/$vARCHINC $vPrefijo/$vEntAdq/T$vpValRet_6/RESPALDO/$vARCHINC" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                     sftp -b $DIRTMP/$dpNom$vFecProc.PARRM.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} >> $vFileLOG 2>&1
                     sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} >> $vFileLOG 2>&1
                     f_msg "--------------------------------------------------------------------------------" N S
                     f_msg
                     echo
                     echo "         Archivo de Control : `basename ${vFileCTL}`"
                     echo "                 Directorio : `dirname ${vFileCTL}`"
                     echo "   Archivo LOG de Ejecucion : `basename ${vFileLOG}`"
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
                         scp -Bq $DIRIN/$vArchDest* $SSSH_USER@$FTP_HOSTXCOM:/file_transfer/${COD_AMBIENTE}/${vEntAdq}/file_out
                         vSTATT=$?
                         if [ "$vSTATT" != "0" ]
                         then
                           tput setf 8
                           echo "error en la transferencia del archivo $vArchDest del adquiriente $pEntAdq al area de acceso de los Bancos, favor revisar" | tee -a $vFileLOG
                           tput setf 7
                           sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Error_Transferencia_de_Archivo_$vArchDest_Adquiriente_$pEntAdq"
                         else
                           echo "Archivo Transferido correctamente al area de acceso de los Bancos"
                           echo
                           echo "Respaldando archivos T464NA procesados - ${vPrefijo_Res} en Servidor MQFTE" >> $vFileLOG 2>&1
                           echo "Respaldando archivos T464NA procesados - ${vPrefijo_Res} en Servidor MQFTE" 
                           scp -Bq $DIRIN/$vArchDest* ${SFTP_USER}@${SFTP_IMC_NGTA}:/${vPrefijo_Res}
                         fi # Fin de la eliminación de transferencia de archivo convertido al area de los bancos IPR1156
                          mv $DIRIN/$vArchDest $DIRIN/${vArchDest}_bkp
                          mv $DIRIN/$vArchDest_conv $DIRIN/${vArchDest_conv}_bkp
                     fi
                  else
                        echo "Generacion de archivo T464NA-CONV Fallida" | tee -a $vFileLOG
                        tput setf 7
                        sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO-NGTA "Error_ARCHIVOS T464NA_${vARCHINC[$vADQIDX]}_Adquiriente_$vEntAdq - ${vEndPoint}"
                  fi
               fi
            fi
            rm $DIRTMP/$dpNom$vFecProc.PAR.SFTP
            rm $DIRTMP/$dpNom$vFecProc.PARRM.SFTP
            rm $DIRIN/$vArchDest 2>/dev/null
            rm $DIRIN/$vArchDest_conv 2>/dev/null
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
         DiaSemana=`sqlplus -s $DB << !
set head off
set pagesize 0000
select to_char(to_date('$vFecProc','YYYYMMDD'),'D') from dual;
!`
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
			  #Eliminación GlobalR Modificación 08-10-2015 IPR1156 - Envío especial de los archivos de Incoming
#              if [ "$vTRANS112" -eq "1" ] && [ "$vERRORTRANS112" -eq "0" ] && [ "$DiaSemana" -ne "1" ]
#              then
#			    echo "Comienza transferencia al XCOM IPR1156" | tee -a $vFileLOG
#                vTRANS112_XCOM=1
#				 for vARCHMC in `ls -t ${DIRIN}/TT${vpValRet_3}T0.${vFecArch}*`
#                 do
#					echo "Tranfiriendo al XCOM ${vARCHMC}" | tee -a $vFileLOG
#					vLongitud=${#DIRIN}
#					let vLongitud=$vLongitud+2
#					vArchBanco=`echo $vARCHMC ${vLongitud} | awk '{print substr($0,$2,31)}'`
#
#					scp -B -q $vARCHMC ${SSSH_USER}@${FTP_HOSTXCOM}:${vEntAdq}pu_fileout/$vArchBanco.FTP 2>&1 | tee -a $vFileLOG
#					vSTATT=$?
#						ssh  -o "BatchMode=yes" ${SSSH_USER}@${FTP_HOSTXCOM} "chmod 644 ${vEntAdq}pu_fileout/$vArchBanco.FTP" 2> $vFileParSSH
#						ssh  -o "BatchMode=yes" ${SSSH_USER}@${FTP_HOSTXCOM} "mv ${vEntAdq}pu_fileout/$vArchBanco.FTP ${vEntAdq}pu_fileout/$vArchBanco" 2>> $vFileParSSH
#						vSSHStat=$?
#						if [ "$vSSHStat" != "0" ]
#						then
#							vSSHERROR=1
#							cat $vFileParSSH >> $vFileLOG
#						fi
#						if [ "$vSSHStat" -ne "0" ]
#						then
#							 echo "error en el renombrado de los archivos ${vARCHINC[$vADQIDX]} del adquiriente $vEntAdq al XCOM, favor revisar" | tee -a $vFileLOG
#						fi								 
#                 done
#                 if [ "$vSTATT" -ne "0" ]
#                 then
#                    vERRORTRANS112_XCOM=1
#                    tput setf 8
#                    echo "error en la transferencia de los archivos ${vARCHINC[$vADQIDX]} del adquiriente $vEntAdq al XCOM, favor revisar" | tee -a $vFileLOG
#                    tput setf 7
#                    sqlplus -s $DB @$DIRBIN/alertacie INC MASTERCARD "Error_Transferencia_de_Archivos_${vARCHINC[$vADQIDX]}_Adquiriente_$vEntAdq"
#                 else 
#                    echo "Archivo ${vARCHINC[$vADQIDX]} Transferido Correctamente al XCOM ${vDIRTGT}"
#                    vERRORTRANS112_XCOM=0
#                 fi			  
#			  fi	  
			  #Fin de la modificación IPR1156
			  #Si la transferencia se hizo sin errores le cambia el nombre a los archivos
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
			  
			  #Eliminación Fase IV GlobalR Modificación 08-10-2015 IPR1156 - Envío especial de los archivos de Incoming
#              if [ "$vTRANS113" -eq "1" ] && [ "$vERRORTRANS113" -eq "0" ]
#              then
#			    echo "Comienza transferencia al XCOM IPR1156" | tee -a $vFileLOG
#                vTRANS112_XCOM=1
#				 for vARCHMC in `ls -t ${DIRIN}/TT${vpValRet_4}T0.${vFecArch}*`
#                 do
#					echo "Tranfiriendo al XCOM ${vARCHMC}" | tee -a $vFileLOG
#					vLongitud=${#DIRIN}
#					let vLongitud=$vLongitud+2
#					vArchBanco=`echo $vARCHMC ${vLongitud} | awk '{print substr($0,$2,31)}'`
#					
#					scp -B -q $vARCHMC ${SSSH_USER}@${FTP_HOSTXCOM}:${vEntAdq}pu_fileout/$vArchBanco.FTP 2>&1 | tee -a $vFileLOG
#					vSTATT=$?
#						ssh  -o "BatchMode=yes" ${SSSH_USER}@${FTP_HOSTXCOM} "chmod 644 ${vEntAdq}pu_fileout/$vArchBanco.FTP" 2> $vFileParSSH
#						ssh  -o "BatchMode=yes" ${SSSH_USER}@${FTP_HOSTXCOM} "mv ${vEntAdq}pu_fileout/$vArchBanco.FTP ${vEntAdq}pu_fileout/$vArchBanco" 2>> $vFileParSSH
#						vSSHStat=$?
#						if [ "$vSSHStat" != "0" ]
#						then
#							vSSHERROR=1
#							cat $vFileParSSH >> $vFileLOG
#						fi
#						if [ "$vSSHStat" -ne "0" ]
#						then
#							 echo "error en el renombrado de los archivos ${vARCHINC[$vADQIDX]} del adquiriente $vEntAdq al XCOM, favor revisar" | tee -a $vFileLOG
#						fi								 
#                 done
#	                 if [ "$vSTATT" -ne "0" ]
 #                then
#                    vERRORTRANS113_XCOM=1
#                    tput setf 8
#                    echo "error en la transferencia de los archivos ${vARCHINC[$vADQIDX]} del adquiriente $vEntAdq al XCOM, favor revisar" | tee -a $vFileLOG
#                    tput setf 7
#                    sqlplus -s $DB @$DIRBIN/alertacie INC MASTERCARD "Error_Transferencia_de_Archivos_${vARCHINC[$vADQIDX]}_Adquiriente_$vEntAdq"
#                 else 				 
#                    echo "Archivo ${vARCHINC[$vADQIDX]} Transferido Correctamente al XCOM ${vDIRTGT}"
#                    vERRORTRANS113_XCOM=0
#                 fi			  
#			  fi	  
			  #Fin de la modificación IPR1156

			  
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

			  #Eliminación GlobalR Modificación 08-10-2015 IPR1156 - Envío especial de los archivos de Incoming
#              if [ "$vTRANS112" -eq "1" ] && [ "$vERRORTRANS112" -eq "0" ] && [ "$DiaSemana" -ne "1" ]
#              then
#                vTRANS112_XCOM=1
#				 for vARCHMC in `ls -t ${DIRIN}/TT${vpValRet_3}T0.${vFecArch}*`
#                 do
#					echo "Tranfiriendo al XCOM ${vARCHMC}" | tee -a $vFileLOG
#					vLongitud=${#DIRIN}
#					let vLongitud=$vLongitud+2
#					vArchBanco=`echo $vARCHMC ${vLongitud} | awk '{print substr($0,$2,31)}'`
#
#					scp -B -q $vARCHMC ${SSSH_USER}@${FTP_HOSTXCOM}:${pEntAdq}pu_fileout/$vArchBanco.FTP 2>&1 | tee -a $vFileLOG
#					vSTATT=$?
#						ssh  -o "BatchMode=yes" ${SSSH_USER}@${FTP_HOSTXCOM} "chmod 644 ${pEntAdq}pu_fileout/$vArchBanco.FTP" 2> $vFileParSSH
#						ssh  -o "BatchMode=yes" ${SSSH_USER}@${FTP_HOSTXCOM} "mv ${pEntAdq}pu_fileout/$vArchBanco.FTP ${pEntAdq}pu_fileout/$vArchBanco" 2>> $vFileParSSH
#						vSSHStat=$?
#						if [ "$vSSHStat" != "0" ]
#						then
#							vSSHERROR=1
#							cat $vFileParSSH >> $vFileLOG
#						fi
#						if [ "$vSSHStat" -ne "0" ]
#						then
#							 echo "error en el renombrado de los archivos ${vARCHINC[$vADQIDX]} del adquiriente $vEntAdq al XCOM, favor revisar" | tee -a $vFileLOG
#						fi								 
 #                done
#                 if [ "$vSTATT" -ne "0" ]
#                 then
#                    vERRORTRANS112_XCOM=1
#                    tput setf 8
#                    echo "error en la transferencia de los archivos ${vARCHINC[$vADQIDX]} del adquiriente $vEntAdq al XCOM, favor revisar" | tee -a $vFileLOG
#                    tput setf 7
#                    sqlplus -s $DB @$DIRBIN/alertacie INC MASTERCARD "Error_Transferencia_de_Archivos_${vARCHINC[$vADQIDX]}_Adquiriente_$vEntAdq"
#                 else 
#                    echo "Archivo ${vARCHINC[$vADQIDX]} Transferido Correctamente al XCOM ${vDIRTGT}"
#                    vERRORTRANS112_XCOM=0
#                 fi			  
#			  fi	  
			  #Fin de la modificación IPR1156
			   
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
			  #Eliminación GlobalR Modificación 08-10-2015 IPR1156 - Envío especial de los archivos de Incoming
#              if [ "$vTRANS113" -eq "1" ] && [ "$vERRORTRANS113" -eq "0" ]
#              then
#                vTRANS112_XCOM=1
#				 for vARCHMC in `ls -t ${DIRIN}/TT${vpValRet_4}T0.${vFecArch}*`
#                 do
#					echo "Tranfiriendo al XCOM ${vARCHMC}" | tee -a $vFileLOG
#					vLongitud=${#DIRIN}
#					let vLongitud=$vLongitud+2
#					vArchBanco=`echo $vARCHMC ${vLongitud} | awk '{print substr($0,$2,31)}'`
#
#					scp -B -q $vARCHMC ${SSSH_USER}@${FTP_HOSTXCOM}:${pEntAdq}pu_fileout/$vArchBanco.FTP 2>&1 | tee -a $vFileLOG
#					vSTATT=$?
#						ssh  -o "BatchMode=yes" ${SSSH_USER}@${FTP_HOSTXCOM} "chmod 644 ${pEntAdq}pu_fileout/$vArchBanco.FTP" 2> $vFileParSSH
#						ssh  -o "BatchMode=yes" ${SSSH_USER}@${FTP_HOSTXCOM} "mv ${pEntAdq}pu_fileout/$vArchBanco.FTP ${pEntAdq}pu_fileout/$vArchBanco" 2>> $vFileParSSH
#						vSSHStat=$?
#						if [ "$vSSHStat" != "0" ]
#						then
#							vSSHERROR=1
#							cat $vFileParSSH >> $vFileLOG
#						fi
#						if [ "$vSSHStat" -ne "0" ]
#						then
#							 echo "error en el renombrado de los archivos ${vARCHINC[$vADQIDX]} del adquiriente $vEntAdq al XCOM, favor revisar" | tee -a $vFileLOG
#						fi								 
#                 done              
#                 if [ "$vSTATT" -ne "0" ]
#                 then
#                    vERRORTRANS113_XCOM=1
#                    tput setf 8
#                    echo "error en la transferencia de los archivos ${vARCHINC[$vADQIDX]} del adquiriente $vEntAdq al XCOM, favor revisar" | tee -a $vFileLOG
#                    tput setf 7
#                    sqlplus -s $DB @$DIRBIN/alertacie INC MASTERCARD "Error_Transferencia_de_Archivos_${vARCHINC[$vADQIDX]}_Adquiriente_$vEntAdq"
#                 else 				 
#                    echo "Archivo ${vARCHINC[$vADQIDX]} Transferido Correctamente al XCOM ${vDIRTGT}"
#                    vERRORTRANS113_XCOM=0
#                 fi			  
#			  fi	  
			  #Fin de la modificación IPR1156
			   
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


   # PROCESO DE REPORTE DEBITO MAESTRO

   if [ "$vOpcion" = "5" ]; then

      vFlgOpcErr="N"
      vOpcion=""

      f_msg
      f_msg " Proceso: REPORTE DEBITO MAESTRO" N S
      f_msg
      f_msg
      f_fechora $vFecProc
      f_msg "    Fecha de Proceso: $vpValRet" N S
      f_msg
      echo " Desea Continuar? (S=Si/N=No/<Enter>=No) => \c"
      read ValConf
      f_msg
      echo "Ingresar Usuario Windows para Transferencia Disco J: \c"
      read USUARIOTMVE
      echo "Ingresar Clave Windows para Transferencia Disco J: \c"
      stty -echo
      read CLAVETMVE
      stty echo
#      echo $CLAVETMVE
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
              vFileREPDEBMAESTRO="SGCPINCMC${vEntAdq}.REPDEBMAESTRO.${vFecProc}"
              vFileLOG="${DIRLOG}/${vFileREPDEBMAESTRO}.`date '+%Y%m%d%H%M%S'`.LOG"
              echo "cd $vPrefijo/$vEntAdq/T$vpValRet_9" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
              echo "ls TT${vpValRet_9}T0.${vFecArch}*" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
              vARCHINC[$vADQIDX]=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\> | wc -l`
              if [ "${vARCHINC[$vADQIDX]}" -lt "1" ]
              then
                 echo "No existe el Archivo de Reporte Debito Maestro para el Adquiriente $vEntAdq" | tee -a $vFileLOG
                 sqlplus -s $DB @$DIRBIN/alertacie INC REPMAESTRO "Reporte_de_Debito_Maestro_Adquiriente_$vEntAdq_No_Existe"
              fi
              if [ "${vARCHINC[$vADQIDX]}" -gt "1" ]
              then
                 echo "Existe mas de Un Archivo de Reporte Debito Maestro para el Adquiriente $vEntAdq, favor revisar" | tee -a $vFileLOG
                 sqlplus -s $DB @$DIRBIN/alertacie INC REPMAESTRO "Numero_Incorrecto_de_Archivos_de_Reporte_Debito_Maestro_Adquiriente_$vEntAdq_No_Existe"
              fi
              if [ "${vARCHINC[$vADQIDX]}" -eq "1" ]
              then
                 vARCHINC[$vADQIDX]=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\>`
                 vArchDest=`echo ${vARCHINC[$vADQIDX]} | cut -d. -f1`
                 vArchDest=${vArchDest}_${vEndPoint}.001
                 echo "cd $vPrefijo/$vEntAdq/T$vpValRet_9" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                 echo "get ${vARCHINC[$vADQIDX]} $DIRIN/$vArchDest" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                 sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} | grep -v Fetching >> $vFileLOG 2>&1
                 vSTATT=$?
                 if [ "$vSTATT" != "0" ]
                 then
                    tput setf 8
                    echo "error en la transferencia del archivo ${vARCHINC[$vADQIDX]} del adquiriente $vEntAdq, favor revisar" | tee -a $vFileLOG
                    tput setf 7
                    sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO "Error_Transferencia_de_Archivo_${vARCHINC[$vADQIDX]}_Adquiriente_$vEntAdq"
                 else
                    vArchDestB="${vpValRet_9}${vEndPoint}_${vFecJul}_01_conv"
                    scp -Bq $DIRIN/$vArchDest $SSSH_USER@$FTP_HOSTXCOM:${vEntAdq}pu_fileout/$vArchDestB
                    vSTATT=$?
                    if [ "$vSTATT" != "0" ]
                    then
                      tput setf 8
                      echo "error en la transferencia del archivo $vArchDest del adquiriente $vEntAdq al area de acceso de los Bancos, favor revisar" | tee -a $vFileLOG
                      tput setf 7
                      sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO "Error_Transferencia_de_Archivo_$vArchDest_Adquiriente_$vEntAdq"
                    else
                      echo "Archivo Transferido correctamente al area de acceso de los Bancos"
                      echo "Transfiriendo Archivo al disco J de SRVCCSALC"
                      vRUTAWIN1="$vPrefijoWin\\${vEntAdq}\\T$vpValRet_9\\${vARCHINC[$vADQIDX]}"
                      vRUTAWIN2="\\$vpValRet_9\\$vArchDestB"
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
                         echo "Archivo ${vARCHINC[$vADQIDX]} transferido correctamente al Servidor SRVCCSALC (J)"
                     fi
                    fi
                    echo " "
                    echo "Archivo ${vARCHINC[$vADQIDX]} Movido al Directorio Procesado(E)" | tee -a $vFileLOG
                    echo "rename $vPrefijo/$vEntAdq/T$vpValRet_9/${vARCHINC[$vADQIDX]} $vPrefijo/$vEntAdq/T$vpValRet_9/RESPALDO/${vARCHINC[$vADQIDX]}" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                    sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} >> $vFileLOG 2>&1
#                    pg $DIRIN/$vArchDest
                 fi
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
            case $pEntAdq in
               BM)
                 vEndPoint=01857;;
               BP)
                 vEndPoint=01858;;
            esac
            f_fechora $vFecProc
            vFecJul=`dayofyear ${vFecProc}`
            vFecJul=`printf "%03d" $vFecJul`
            vFecArch="$vAno-$vMes-$vDia"
            vFileREPDEBMAESTRO="SGCPINCMC${pEntAdq}.REPDEBMAESTRO.${vFecProc}"
            vFileLOG="${DIRLOG}/${vFileREPDEBMAESTRO}.`date '+%Y%m%d%H%M%S'`.LOG"
            echo "cd $vPrefijo/$pEntAdq/T$vpValRet_9" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
            echo "ls TT${vpValRet_9}T0.${vFecArch}*" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
            vARCHINC=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\> | wc -l`
            if [ "$vARCHINC" -lt "1" ]
            then
               echo "No existe el Archivo de Reporte Debito Maestro para el Adquiriente $pEntAdq" | tee -a $vFileLOG
               sqlplus -s $DB @$DIRBIN/alertacie INC REPMAESTRO "Reporte_de_Debito_Maestro_Adquiriente_$vEntAdq_No_Existe"
            fi
            if [ "$vARCHINC" -gt "1" ]
            then
               echo "Existe mas de Un Archivo de Reporte Debito Maestro para el Adquiriente $pEntAdq, favor revisar" | tee -a $vFileLOG
               sqlplus -s $DB @$DIRBIN/alertacie INC REPMAESTRO "Numero_Incorrecto_de_Archivos_de_Reporte_Debito_Maestro_Adquiriente_$vEntAdq_No_Existe"
            fi
            if [ "$vARCHINC" -eq "1" ]
            then
               vARCHINC=`sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} 2>/dev/null | grep -v sftp\>`
               vArchDest=`echo ${vARCHINC} | cut -d. -f1`
               vArchDest=${vArchDest}_${vEndPoint}.001
               echo "cd $vPrefijo/$pEntAdq/T$vpValRet_9" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
               echo "get $vARCHINC $DIRIN/$vArchDest" >> $DIRTMP/$dpNom$vFecProc.PAR.SFTP
               sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} | grep -v Fetching >> $vFileLOG 2>&1
               vSTATT=$?
               if [ "$vSTATT" != "0" ]
               then
                  tput setf 8
                  echo "error en la transferencia del archivo $vARCHINC del adquiriente $pEntAdq, favor revisar" | tee -a $vFileLOG
                  tput setf 7
                  sqlplus -s $DB @$DIRBIN/alertacie INC REPMAESTRO "Error_Transferencia_de_Archivo_${vARCHINC[$vADQIDX]}_Adquiriente_$pEntAdq"
               else
                  vArchDestB="${vpValRet_9}${vEndPoint}_${vFecJul}_01_conv"
                  scp -Bq $DIRIN/$vArchDest $SSSH_USER@$FTP_HOSTXCOM:${pEntAdq}pu_fileout/$vArchDestB
                  vSTATT=$?
                  if [ "$vSTATT" != "0" ]
                  then
                    tput setf 8
                    echo "error en la transferencia del archivo $vArchDest del adquiriente $pEntAdq al area de acceso de los Bancos, favor revisar" | tee -a $vFileLOG
                    tput setf 7
                    sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO "Error_Transferencia_de_Archivo_$vArchDest_Adquiriente_$pEntAdq"
                  else
                    echo "Archivo Transferido correctamente al area de acceso de los Bancos"
                    echo "Transfiriendo Archivo al disco J de SRVCCSALC"
                    vRUTAWIN1="$vPrefijoWin\\${pEntAdq}\\T$vpValRet_9\\${vARCHINC}"
                    vRUTAWIN2="\\$vpValRet_9\\$vArchDestB"
                    vCOPIAWIN=`ssh ${SFTP_USER}@${SFTP_IMC_NGTA} cmd.exe /C "C:\\MFESFTP\\transtmve $vRUTAWIN1 $vPrefijoWin $vRUTAWIN2 $USUARIOTMVE $CLAVETMVE"`
                    vSTATT=$?
                    if [ "$vSTATT" != "0" ]
                    then
                       tput setf 8
                       echo "error en la transferencia del archivo $vArchDest del adquiriente $pEntAdq al Disco J de SRVCCSALC, favor revisar" | tee -a $vFileLOG
                       echo $vCOPIAWIN | tee -a $vFileLOG
                       tput setf 7
                       sqlplus -s $DB @$DIRBIN/alertacie INC MAESTRO "Error_Transferencia_de_Archivo_$vArchDest_Adquiriente_$vEntAdq"
                     else
                       echo "Archivo ${vARCHINC[$vADQIDX]} transferido correctamente al Servidor SRVCCSALC (J)"
                    fi
                  fi
                  echo " "
                  echo "Archivo $vARCHINC Movido al Directorio Procesado(E)" | tee -a $vFileLOG
                  vNumSec=`echo $vARCHINC | cut -d. -f3`
                  echo "rename $vPrefijo/$pEntAdq/T$vpValRet_9/$vARCHINC $vPrefijo/$pEntAdq/T$vpValRet_9/RESPALDO/$vARCHINC" > $DIRTMP/$dpNom$vFecProc.PAR.SFTP
                   sftp -b $DIRTMP/$dpNom$vFecProc.PAR.SFTP ${SFTP_USER}@${SFTP_IMC_NGTA} > /dev/null 2>&1
                   DUMMY=0
                   while [ "$DUMMY" != "Q" ] && [ "$DUMMY" != "q" ]
                   do
                      echo "Oprima Q o q <ENTER> para volver al Menu \c"
                      read DUMMY
                   done
              fi
            fi
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
         DiaSemana=`sqlplus -s $DB << !
set head off
set pagesize 0000
select to_char(to_date('$vFecProc','YYYYMMDD'),'D') from dual;
! #######################################################`

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
