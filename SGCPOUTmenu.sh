#!/bin/ksh

################################################################################
##
##  Nombre del Programa : SGCPOUTmenu.sh
##                Autor : JMG
##       Codigo Inicial : 17/05/2011
##          Descripcion : Menu Principal de Outgoing
##
##  ======================== Registro de Modificaciones ========================
##
##  Fecha      Autor Version Descripcion de la Modificacion
##  ---------- ----- ------- ---------------------------------------------------
##  17/05/2011 JMG   1.00    Codigo Inicial
##  25/01/2012 EEVN  1.00    IPR 1039 : Actualizacion en Menu Operador
##  17/02/2012 DCB   1.01    IPR 1039 : Actualizacion Validaciones en Menu Operador
##  02/06/2015 GLR   1.02    IPR 1148 : Inclusion de envio de archivos al XCOM
##  16/01/2020 FJV   2.00    IPR 1302 : SAlientes Naiguata
####################################################################################

################################################################################
## DECLARACION DE DATOS, PARAMETROS DE EJECUCION Y VARIABLES DEL PROGRAMA
################################################################################


## Datos del Programa
################################################################################

dpNom="SGCPOUTmenu"           # Nombre del Programa
dpDesc=""                     # Descripcion del Programa
dpVer=2.00                    # Ultima Version del Programa
dpFec="20120217"              # Fecha de Ultima Actualizacion [Formato:AAAAMMDD]

## Variables del Programa
################################################################################

vpValRet=""                   # Valor de Retorno (funciones)
vpFH=`date '+%Y%m%d%H%M%S'`   # Fecha y Hora [Formato:AAAAMMDDHHMMSS]
vpFileLOG=""                  # Nombre del Archivo LOG del Programa


## Parametros
################################################################################

pFecSes="$1"                  # Fecha de Sesion
pCodHCierre="$2"              # Codigo de Hora de Cierre
pOpcRepro="$3"                # Opcion de Reproceso (S=Si/N=No)
pFlgBG="$4"                   # Ejecucion en Background (S=Si/N=No)
vFecAbo="$5"                  # Fecha de abono Modificado por GLOBALR 12-03-2015 IPR 1148

## Variables de Trabajo
################################################################################

vHCierre=""                   # Hora de Cierre
vReproceso=""                 # Descripcion de Opcion de Reproceso
vFileCTL=""                   # Archivo de Control
vEstCLR=""                    # Estado del Proceso de Clearing
vEstPLIQ=""                   # Estado de la Interfaz PLIQ
vEstOUTMC=""                  # Estado del Proceso de Outgoing Mastercard
vEstOUTVISA=""                # Estado del Proceso de Outgoing VISA
vEstOUTPRICE=""               # Estado del Proceso de Outgoing PRICE
vEstOUTVISA_NGTA=""           # Estado del Proceso de Outgoing VISA NGTA
vEstOUTMC_NGTA=""             # Estado del Proceso de Outgoing Master Card NGTA
vNomEst=""                    # Nombre del Estado del Proceso

vHCierre1=""                  # Hora de Cierre Nro 1
vHCierre2=""                  # Hora de Cierre Nro 2

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

# f_admCTL () | administra el Archivo de Control (lee/escribe)
# Parametros
#   pOpcion   : R=lee/W=escribe
################################################################################
f_admCTL ()
{

  # Estructura del Archivo de Control
  # [01-08] Fecha de Sesion
  # [10-10] Codigo de Hora de Cierre
  # [12-12] Estado del Proceso de Clearing
  # [14-14] Estado de la Interfaz PLIQ
  # [16-16] Estado del Proceso de Outgoing VISA
  # [18-18] Estado del Proceso de Outgoing MC
  # [20-20] Estado del Proceso de Outgoing PRICE
  # [22-35] Fecha y Hora de Actualizacion de los Estados [AAAAMMDDHHMMSS]

  pOpcion="$1"

  if [ "$pOpcion" = "R" ]; then
     if ! [ -f "$vFileCTL" ]; then
        # Crea el Archivo CTL
        vEstCLR="0"
        vEstPLIQ="0"
        vEstOUTVISA="0"
        vEstOUTMC="0"
        vEstOUTPRICE="0"
        vEstOUTVISA_NGTA="0"
        vEstOUTMC_NGTA="0"
        echo "${pFecSes}|${pCodHCierre}|${vEstCLR}|${vEstPLIQ}|${vEstOUTVISA}|${vEstOUTMC}|${vEstOUTPRICE}|${vEstOUTVISA_NGTA}|${vEstOUTMC_NGTA}|`date '+%Y%m%d%H%M%S'`" > $vFileCTL
     else
        vEstCLR=`awk '{print substr($0,12,1)}' $vFileCTL`
        vEstPLIQ=`awk '{print substr($0,14,1)}' $vFileCTL`
        vEstOUTVISA=`awk '{print substr($0,16,1)}' $vFileCTL`
        vEstOUTMC=`awk '{print substr($0,18,1)}' $vFileCTL`
        vEstOUTPRICE=`awk '{print substr($0,20,1)}' $vFileCTL`
        vEstOUTVISA_NGTA=`awk '{print substr($0,22,1)}' $vFileCTL`
        vEstOUTMC_NGTA=`awk '{print substr($0,24,1)}' $vFileCTL`
     fi
  else
     echo "${pFecSes}|${pCodHCierre}|${vEstCLR}|${vEstPLIQ}|${vEstOUTVISA}|${vEstOUTMC}|${vEstOUTPRICE}|${vEstOUTVISA_NGTA}|${vEstOUTMC_NGTA}|`date '+%Y%m%d%H%M%S'`" > $vFileCTL
  fi

}

# f_getNomEst () | nombre del estado de proceso
# Parametros
#   pEstado   : estado del proceso
################################################################################
f_getNomEst ()
{

  pEstado="$1"

  case $pEstado in

       0)
          vNomEst="PENDte"
          vNomEstNG="PENDte"
          ;; ## PENDIENTE
       P)
          vNomEst="EN_PRO"
          vNomEstNG="EN_PRO"
          ;; ## EN PROCESO
       F)
          vNomEst="FINzdo"
          vNomEstNG="FINzdo"
          ;; ## FINALIZADO
       E)
          vNomEst="FINerr"
          vNomEstNG="FINerr"
          ;; ## FIN ERROR
       *)
          vNomEst="DEScon!"
          vNomEstNG="DEScon!"
          ;; ## DESCONOCIDO
  esac

}

# f_menuCAB () | administra el Archivo de Control (lee/escribe)
################################################################################
f_menuCAB ()
{

   clear
   echo "*******************************************************************************"
   echo "*                       SISTEMA DE GESTION DE COMERCIOS                  ${COD_AMBIENTE} *"
   echo "*                              Menu de Outgoing                               *"
   echo "*******************************************************************************"

}


# f_menuDAT () | datos del menu
################################################################################
f_menuDAT ()
{

   if [ "$pOpcRepro" = "S" ]; then
      vReproceso="SI"
   else
      vReproceso="NO"
   fi

   f_fechora $vFecSes

   if [ "$pCodHCierre" = "1" ]; then
      f_getNomEst $vEstOUTMC
      echo " Fecha de Sesion: $vpValRet  Estatus MC: $vNomEst  Estatus Ngta MC: $vNomEstNG"
      echo "  Hora de Cierre: $vHCierre hrs.                             "
      echo "       Reproceso: $vReproceso   "

   elif [ "$pCodHCierre" = "2" ]; then
        f_getNomEst $vEstOUTVISA
        f_getNomEst $vEstOUTVISA_NGTA
        echo " Fecha de Sesion: $vpValRet  Estatus Visa : $vNomEst  Est. Ngta Visa : $vNomEstNG"
        f_getNomEst $vEstOUTMC
        f_getNomEst $vEstOUTMC_NGTA
        echo "  Hora de Cierre: $vHCierre hrs.      Estatus MC   : $vNomEst  Est. Ngta MC   : $vNomEstNG"
        f_getNomEst $vEstOUTPRICE
        echo "       Reproceso: $vReproceso          Estatus Price: $vNomEst"

   fi

}

# f_menuOPC () | menu de opciones
################################################################################
f_menuOPC ()
{

if [ "$pCodHCierre" = "1" ]; then

   echo "-------------------------------------------------------------------------------"
   echo
   echo "  PROCESOS                                 CONSULTAS"
   echo "  -----------------------------------      ----------------------------------"

## IPR 1039: Modificacion visual de orden de ejecucion
## 09/12/2011 EEVN 
################################################################################
#  echo "  [ 2] Proceso Outgoing de Mastercard      [ 6] LOG de Outgoing de Mastercard"
################################################################################

   echo "  [30] Proceso Outgoing de MC Ngta         [70] LOG de Outgoing de MC Ngta"
   echo "  [ 3] Proceso Outgoing de Mastercard      [ 7] LOG de Outgoing de Mastercard"
   echo
   echo "-------------------------------------------------------------------------------"
   echo " Ver $dpVer | Telefonica Servicios Transaccionales                     [Q] Salir"
   echo "-------------------------------------------------------------------------------"

elif [ "$pCodHCierre" = "2" ]; then

   echo "-------------------------------------------------------------------------------"
   echo
   echo "  PROCESOS                                 CONSULTAS"
   echo "  -----------------------------------      ----------------------------------"
   echo "  [10] Proceso Outgoing de Visa Ngta       [50] LOG de Outgoing de Visa Ngta"
   echo "  [30] Proceso Outgoing de MC Ngta         [70] LOG de Outgoing de MC Ngta"
   echo "  [ 1] Proceso Outgoing de Visa            [ 5] LOG de Outgoing de Visa"
   echo "  [ 2] Proceso Outgoing de Price           [ 6] LOG de Outgoing de Price"
   echo "  [ 3] Proceso Outgoing de Mastercard      [ 7] LOG de Outgoing de Mastercard"
################################################################################
#   echo "  [ 2] Proceso Outgoing de Mastercard      [ 6] LOG de Outgoing de Mastercard"
#   echo "  [ 3] Proceso Outgoing de Price           [ 7] LOG de Outgoing de Price"
## FIN IPR 1039: Modificacion visual de orden de ejecucion
## 09/12/2011 EEVN 
################################################################################

   echo
   echo "  [ 4] Todos                               [ 8] LOG de Todos"
   echo
   echo "-------------------------------------------------------------------------------"
   echo " Ver $dpVer | Telefonica Servicios Transaccionales                     [Q] Salir"
   echo "-------------------------------------------------------------------------------"
fi

}

transmc ()
{
  #vEstOUTMC=`awk '{print substr($0,15,1)}' $vFileCTL 2>/dev/null`
  vEstOUTMC=`awk '{print substr($0,18,1)}' $vFileCTL 2>/dev/null`  #Modificado GLOBALR 12-03-2015
  if [ "$vEstOUTMC" = "F" ]
  then
    vFileLOG="${DIRLOG}/SGCPCLROUTMC${vFecSes}.${vCodHCierre}.LOG"
    echo "***************************************************************************" | tee -a $vFileLOG
    echo "el Proceso de OutGoing de MASTERCARD (Cierre 1) Finalizo EXITOSAMENTE" | tee -a $vFileLOG
    echo "Revisar el Log $vFileLOG" | tee -a $vFileLOG
    echo "***************************************************************************" | tee -a $vFileLOG
    echo "------------------------------------------------------------------------------" | tee -a $vFileLOG
    echo "Copiando Archivos IPM de MasterCard al Servidor de PRE-EDIT" | tee -a $vFileLOG
    echo "------------------------------------------------------------------------------" | tee -a $vFileLOG
    vSSHERROR=0
    vSSHELOGSZ=0
    vSSHStat=0
    case $COD_AMBIENTE in
       DESA)
         vTipoBulk="R119";;
       CCAL)
         vTipoBulk="R119";;
       PROD)
         vTipoBulk="R111";;
    esac
    if [ "$vCodHCierre" = "1" ]
    then 
      vFecJul="`dayofyear ${vFecSes}`"
    else
      vFecJul="`dayofyear ${vFecAbo}`"
    fi
    vFecJul=`printf "%03d" $vFecJul`
    vFHsys=`date '+%Y%m%d%H%M%S'`
    vFileParSFTP="${DIRTMP}/${dpNom}_${vFHsys}.PAR.SFTP"
    vFileBatSFTP="${DIRTMP}/${dpNom}_${vFHsys}.BAT.SFTP"
    vFileLOG="${DIRLOG}/SGCPCLROUTMC${vFecSes}.${vCodHCierre}.LOG"
    for vEndPoint in 01857 01858
    do
       case $vEndPoint in
          01858)
             vRUTAWIN="$PSFTP_MC/0070193_BP";;
          01857)
             vRUTAWIN="$PSFTP_MC/0071049_BM";;
       esac
       vARCHMC=`ls ${DIROUT}/${vTipoBulk}${vEndPoint}${vFecJul}[0-2][0-9].IPM 2>/dev/null | wc -l`
       vARCHMC=`printf "%d" "$vARCHMC"`
       if [ "$vARCHMC" = "0" ]
       then
          vFileLOG="${DIRLOG}/SGCPCLROUTMC${vFecSes}.${vCodHCierre}.LOG"
          tput setf 8
          echo "***************************************************************************" | tee -a $vFileLOG
          echo `date` | tee -a $vFileLOG
          echo "El Archivo de Outgoing de Master Card del Adquiriente $vEndPoint" | tee -a $vFileLOG
          echo "Archivo cuyo nombre empieza con: $DIROUT/$vTipoBulk$vEndPoint$vFecJul" | tee -a $vFileLOG
          echo "Archivo $vARCHMC" | tee -a $vFileLOG
          echo "No Existe o esta Vacio" | tee -a $vFileLOG
          echo "Esto Indica una falla no detectada en el Proceso de Outgoing de Master Card" | tee -a $vFileLOG
          echo "Revisar el log $vFileLOG" | tee -a $vFileLOG
          echo "***************************************************************************" | tee -a $vFileLOG
          tput setf 7
          sqlplus -s $DB @$DIRBIN/alertacie MC OUTMC "Outgoing_MasterCard_Archivo_$vTipoBulk$vEndPoint$vFecJul_No_Existe_o_Vacio"
          vSSHERROR=1
          vEstOUTMC="E"
          continue
       fi
       if [ "$vEstOUTMC" = "F" ] && [ "$vARCHMC" -gt "0" ]
       then
          for vARCHMC in `ls -t ${DIROUT}/${vTipoBulk}${vEndPoint}${vFecJul}[0-2][0-9].IPM`
          do
             if [ "$vARCHMC" -nt "$vSTARTMC" ]
             then
                vARCHMCD=$vARCHMC.CONV
                 unix2dos -ascii -437 $vARCHMC $vARCHMCD
                 mv $vARCHMCD $vARCHMC
                echo "put $vARCHMC ${vRUTAWIN}"  >> $vFileBatSFTP
             fi
          done
          sftp -b $vFileBatSFTP ${SFTP_USER}@${SFTP_MC} > $vFileParSFTP 2>&1
          vSSHStat=$?
          vSSHELOGSZ=`/usr/xpg4/bin/grep -v -e mkdir -e put -e Uploading -e sftp -e Connecting $vFileParSFTP | wc -l`
          if [ "$vSSHStat" != "0" ] || [ "$vSSHELOGSZ" -gt "0" ]
          then
             vSSHERROR=1
             cat $vFileParSFTP | tee -a $vFileLOG
          fi
       else
          vSSHERROR=1
       fi
    done
    if [ "$vSSHERROR" = "0" ]
    then
       echo "***************************************************************************" | tee -a $vFileLOG
       echo "Copia de Archivos de Mastercard" | tee -a $vFileLOG
       echo "Finalizada CORRECTAMENTE" | tee -a $vFileLOG
       echo "Ejecutar Proceso de Validacion en PRE-EDIT" | tee -a $vFileLOG
       echo "***************************************************************************" | tee -a $vFileLOG

				  #GLOBALR 27/01/2015 IPR 1148 - Transferencia de Archivos del Outgoing a los bancos
				  SGCFTPOutgoingAdq.sh ${vFecSes} BM MC ${vFecAbo} ${vCodHCierre} ${vFecAbo}
				  SGCFTPOutgoingAdq.sh ${vFecSes} BP MC ${vFecAbo} ${vCodHCierre} ${vFecAbo}
				  
       rm $vFileBatSFTP
       rm $vFileParSFTP
    else
       tput setf 8
       echo "***************************************************************************" | tee -a $vFileLOG
       echo "Copia de Archivos de Mastercard" | tee -a $vFileLOG
       echo "Finalizada EN ERROR" | tee -a $vFileLOG
       echo "***************************************************************************" | tee -a $vFileLOG
       tput setf 7
       sqlplus -s $DB @$DIRBIN/alertacie MC TOUTMC "Transferencia_Outgoing_MasterCard_Fallida"
    fi
  elif [ "$vEstOUTMC" = "E" ]
  then
    vFileLOG="${DIRLOG}/SGCPCLROUTMC${vFecSes}.${vCodHCierre}.LOG"
    tput setf 8
    echo "***************************************************************************" | tee -a $vFileLOG
    echo "Error, el Proceso de OutGoing de MASTERCARD (Cierre 1) Finalizo CON ERRORES" | tee -a $vFileLOG
    echo "Revisar el Log $vFileLOG" | tee -a $vFileLOG
    echo "***************************************************************************" | tee -a $vFileLOG
    tput setf 7
  fi
}
transmcNG ()  ## IPR 1302 NAIGUATA FJVG 06022020
{
  vEstOUTMC_NGTA=`awk '{print substr($0,24,1)}' $vFileCTL 2>/dev/null`  #Modificado GLOBALR 12-03-2015
  if [ "$vEstOUTMC_NGTA" = "F" ]
  then
    vFileLOG="${DIRLOG}/SGCPCLROUTMC_NGTA${vFecSes}.${vCodHCierre}.LOG"
    echo "***************************************************************************" | tee -a $vFileLOG
    echo "el Proceso de OutGoing de Naiguata MASTERCARD (Cierre 1) Finalizo EXITOSAMENTE" | tee -a $vFileLOG
    echo "Revisar el Log $vFileLOG" | tee -a $vFileLOG
    echo "***************************************************************************" | tee -a $vFileLOG
    echo "------------------------------------------------------------------------------" | tee -a $vFileLOG
    echo "Copiando Archivos IPM de MasterCard al Servidor de PRE-EDIT" | tee -a $vFileLOG
    echo "------------------------------------------------------------------------------" | tee -a $vFileLOG
    vSSHERROR=0
    vSSHELOGSZ=0
    vSSHStat=0
    case $COD_AMBIENTE in
       DESA)
         vTipoBulk="R119";;
       CCAL)
         vTipoBulk="R119";;
       PROD)
         vTipoBulk="R111";;
    esac
    if [ "$vCodHCierre" = "1" ]
    then 
      vFecJul="`dayofyear ${vFecSes}`"
    else
      vFecJul="`dayofyear ${vFecAbo}`"
    fi
    vFecJul=`printf "%03d" $vFecJul`
    vFHsys=`date '+%Y%m%d%H%M%S'`
    vFileParSFTP="${DIRTMP}/${dpNom}_${vFHsys}.PAR.SFTP"
    vFileBatSFTP="${DIRTMP}/${dpNom}_${vFHsys}.BAT.SFTP"
    vFileLOG="${DIRLOG}/SGCPCLROUTMC_NGTA${vFecSes}.${vCodHCierre}.LOG"
    for vEndPoint in 01857 01858
    do
       case $vEndPoint in
          01858)
             vRUTAWIN="$PSFTP_MC/0070193_BP";;
          01857)
             vRUTAWIN="$PSFTP_MC/0071049_BM";;
       esac
       vARCHMC=`ls ${DIROUT}/${vTipoBulk}${vEndPoint}${vFecJul}[0-2][0-9].IPM 2>/dev/null | wc -l`
       vARCHMC=`printf "%d" "$vARCHMC"`
       if [ "$vARCHMC" = "0" ]
       then
          vFileLOG="${DIRLOG}/SGCPCLROUTMC_NGTA${vFecSes}.${vCodHCierre}.LOG"
          tput setf 8
          echo "***************************************************************************" | tee -a $vFileLOG
          echo `date` | tee -a $vFileLOG
          echo "El Archivo de Outgoing de naiguata  Master Card del Adquiriente $vEndPoint" | tee -a $vFileLOG
          echo "Archivo cuyo nombre empieza con: $DIROUT/$vTipoBulk$vEndPoint$vFecJul" | tee -a $vFileLOG
          echo "Archivo $vARCHMC" | tee -a $vFileLOG
          echo "No Existe o esta Vacio" | tee -a $vFileLOG
          echo "Esto Indica una falla no detectada en el Proceso de Outgoing de Master Card" | tee -a $vFileLOG
          echo "Revisar el log $vFileLOG" | tee -a $vFileLOG
          echo "***************************************************************************" | tee -a $vFileLOG
          tput setf 7
          sqlplus -s $DB @$DIRBIN/alertacie MC OUTMCNGTA "Outgoing_nAIGUATA_MasterCard_Archivo_$vTipoBulk$vEndPoint$vFecJul_No_Existe_o_Vacio"
          vSSHERROR=1
          vEstOUTMC_NGTA="E"
          continue
       fi
       if [ "$vEstOUTMC_NGTA" = "F" ] && [ "$vARCHMC" -gt "0" ]
       then
          for vARCHMC in `ls -t ${DIROUT}/${vTipoBulk}${vEndPoint}${vFecJul}[0-2][0-9].IPM`
          do
             if [ "$vARCHMC" -nt "$vSTARTMC" ]
             then
                vARCHMCD=$vARCHMC.CONV
                 unix2dos -ascii -437 $vARCHMC $vARCHMCD
                 mv $vARCHMCD $vARCHMC
                echo "put $vARCHMC ${vRUTAWIN}"  >> $vFileBatSFTP
             fi
          done
          sftp -b $vFileBatSFTP ${SFTP_USER}@${SFTP_MC} > $vFileParSFTP 2>&1
          vSSHStat=$?
          vSSHELOGSZ=`/usr/xpg4/bin/grep -v -e mkdir -e put -e Uploading -e sftp -e Connecting $vFileParSFTP | wc -l`
          if [ "$vSSHStat" != "0" ] || [ "$vSSHELOGSZ" -gt "0" ]
          then
             vSSHERROR=1
             cat $vFileParSFTP | tee -a $vFileLOG
          fi
       else
          vSSHERROR=1
       fi
    done
    if [ "$vSSHERROR" = "0" ]
    then
       echo "***************************************************************************" | tee -a $vFileLOG
       echo "Copia de Archivos de naiguata Mastercard" | tee -a $vFileLOG
       echo "Finalizada CORRECTAMENTE" | tee -a $vFileLOG
       echo "Ejecutar Proceso de Validacion en PRE-EDIT" | tee -a $vFileLOG
       echo "***************************************************************************" | tee -a $vFileLOG

				  #GLOBALR 27/01/2015 IPR 1148 - Transferencia de Archivos del Outgoing a los bancos
				  SGCFTPOutgoingAdq.sh ${vFecSes} BM MC ${vFecAbo} ${vCodHCierre} ${vFecAbo}
				  SGCFTPOutgoingAdq.sh ${vFecSes} BP MC ${vFecAbo} ${vCodHCierre} ${vFecAbo}
				  
       rm $vFileBatSFTP
       rm $vFileParSFTP
    else
       tput setf 8
       echo "***************************************************************************" | tee -a $vFileLOG
       echo "Copia de Archivos de Mastercard" | tee -a $vFileLOG
       echo "Finalizada EN ERROR" | tee -a $vFileLOG
       echo "***************************************************************************" | tee -a $vFileLOG
       tput setf 7
       sqlplus -s $DB @$DIRBIN/alertacie MC TOUTMC "Transferencia_Outgoing_MasterCard_Fallida"
    fi
  elif [ "$vEstOUTMC_NGTA" = "E" ]
  then
    vFileLOG="${DIRLOG}/SGCPCLROUTMC_NGTA${vFecSes}.${vCodHCierre}.LOG"
    tput setf 8
    echo "***************************************************************************" | tee -a $vFileLOG
    echo "Error, el Proceso de OutGoing de MASTERCARD (Cierre 1) Finalizo CON ERRORES" | tee -a $vFileLOG
    echo "Revisar el Log $vFileLOG" | tee -a $vFileLOG
    echo "***************************************************************************" | tee -a $vFileLOG
    tput setf 7
  fi
}
transvisa ()
{
  if [ "$vEstOUTVISA" = "F" ]
  then
    vFileLOG="${DIRLOG}/SGCPCLROUTVISA${vFecSes}.${vCodHCierre}.LOG"
    echo "***************************************************************************" | tee -a $vFileLOG
    echo "el Proceso de OutGoing de VISA Finalizo EXITOSAMENTE" | tee -a $vFileLOG
    echo "Revisar el Log $vFileLOG" | tee -a $vFileLOG
    echo "***************************************************************************" | tee -a $vFileLOG
    echo "------------------------------------------------------------------------------" | tee -a $vFileLOG
    echo "Copiando Archivos de VISA al Servidor de EDITPACK" | tee -a $vFileLOG
    echo "------------------------------------------------------------------------------" | tee -a $vFileLOG
    vSSHERROR=0
    vSSHStat=0
    vSSELOGSZ=0
    vFHsys=`date '+%Y%m%d%H%M%S'`
    vFileParSFTP="${DIRTMP}/${dpNom}_${vFHsys}.PAR.SFTP"
    vFileBatSFTP="${DIRTMP}/${dpNom}_${vFHsys}.BAT.SFTP"
    vFecSesCorta=`echo $vFecSes | awk '{ print substr($0,3) }'`
    for vEndPoint in 0105 0108
    do
       vARCHVI=`ls -t ${DIROUT}/OUTVI${vEndPoint}${vFecSes}.DAT 2>/dev/null | wc -l`
       vARCHVI=`printf "%d" "$vARCHVI"`
       if [ "$vARCHVI" = "0" ]
       then
          vFileLOG="${DIRLOG}/SGCPCLROUTVISA${vFecSes}.${vCodHCierre}.LOG"
          tput setf 8
          echo "***************************************************************************" | tee -a $vFileLOG
          echo "El Archivo de Outgoing de VISA del Adquiriente $vEndPoint" | tee -a $vFileLOG
          echo "Archivo: $DIROUT/OUTVI$vEndPoint$vFecSes.DAT" | tee -a $vFileLOG
          echo "No Existe o esta Vacio" | tee -a $vFileLOG
          echo "Esto Indica una falla no detectada en el Proceso de Outgoing de VISA" | tee -a $vFileLOG
          echo "Revisar el log $vFileLOG" | tee -a $vFileLOG
          echo "***************************************************************************" | tee -a $vFileLOG
          tput setf 7
          sqlplus -s $DB @$DIRBIN/alertacie VISA OUTVI "Outgoing_VISA_Archivo_OUTVI$vEndPoint$vFecSes.DAT_No_Existe_o_Vacio"
          vSSHERROR=1
          vEstOUTVISA="E"
       fi
       vRUTAWIN=/OUTGOING
#		vRUTAWIN=/C411032/OUTGOING      #GLOBALR - SOLO PARA EL AMBIENTE DE CALIDAD.	   
		
       if [ "$vEstOUTVISA" = "F" ]
       then
          case $vEndPoint in
            0105)
                vEndPointADQ=BM
                ;;
            0108)
                vEndPointADQ=BP
                ;;
          esac
#          echo "mkdir ${vRUTAWIN}/OU${vFecSesCorta}" >> $vFileBatSFTP
          for vARCHVI in `ls -t ${DIROUT}/OUTVI${vEndPoint}${vFecSes}.DAT`
          do
             vARCHVIDEST="OUTVIS${vEndPointADQ}${vFecSesCorta}.CTF"
             unix2dos -ascii -437 $vARCHVI $DIROUT/$vARCHVIDEST
#             echo "put $DIROUT/$vARCHVIDEST ${vRUTAWIN}/OU${vFecSesCorta}/${vARCHVIDEST}"  >> $vFileBatSFTP
             echo "put $DIROUT/$vARCHVIDEST ${vRUTAWIN}/${vARCHVIDEST}"  >> $vFileBatSFTP
          done
          sftp -b $vFileBatSFTP ${SFTP_USER}@${SFTP_VISA} > $vFileParSFTP 2>&1
          vSSHStat=$?
          vSSHELOGSZ=`/usr/xpg4/bin/grep -v -e mkdir -e put -e Uploading -e sftp -e Connecting $vFileParSFTP | wc -l`
          if [ "$vSSHStat" != "0" ] || [ "$vSSHELOGSZ" -gt "0" ]
          then
             vSSHERROR=1
             cat $vFileParSFTP | tee -a $vFileLOG
          fi
          rm $vFileBatSFTP
          rm $vFileParSFTP
       fi
    done
    if [ "$vSSHERROR" = "0" ]
    then
       echo "***************************************************************************" | tee -a $vFileLOG
       echo "Copia de Archivos de VISA" | tee -a $vFileLOG
       echo "Finalizada CORRECTAMENTE" | tee -a $vFileLOG
       echo "Ejecutar Proceso de Validacion en EDITPACK" | tee -a $vFileLOG
       echo "***************************************************************************" | tee -a $vFileLOG
	   
				  #GLOBALR 27/01/2015 IPR 1148 - Transferencia de Archivos del Outgoing a los bancos
				  SGCFTPOutgoingAdq.sh ${vFecSes} BM VI ${vFecAbo} ${vCodHCierre} ${vFecAbo}
				  SGCFTPOutgoingAdq.sh ${vFecSes} BP VI ${vFecAbo} ${vCodHCierre} ${vFecAbo}
    fi
  elif [ "$vEstOUTVISA" = "E" ]
  then
    vFileLOG="${DIRLOG}/SGCPCLROUTVISA${vFecSes}.${vCodHCierre}.LOG"
    tput setf 8
    echo "***************************************************************************" | tee -a $vFileLOG
    echo "Error, el Proceso de OutGoing de VISA Finalizo CON ERRORES" | tee -a $vFileLOG
    echo "Revisar el Log $vFileLOG" | tee -a $vFileLOG
    echo "***************************************************************************" | tee -a $vFileLOG
    tput setf 7
  fi
}
transvisaNG ()   ## IPR 1302 NAIGUATA FJVG 06022020
{
  vEstOUTVISA_NGTA=`awk '{print substr($0,22,1)}' $vFileCTL 2>/dev/null`  #Modificado GLOBALR FJVG 21-02-2020
  if [ "$vEstOUTVISA_NGTA" = "F" ]
  then
    vFileLOG="${DIRLOG}/SGCPCLROUTVISA_NGTA${vFecSes}.${vCodHCierre}.LOG"
    echo "***************************************************************************" | tee -a $vFileLOG
    echo "el Proceso de OutGoing de NAIGUATA VISA Finalizo EXITOSAMENTE" | tee -a $vFileLOG
    echo "Revisar el Log $vFileLOG" | tee -a $vFileLOG
    echo "***************************************************************************" | tee -a $vFileLOG
    echo "------------------------------------------------------------------------------" | tee -a $vFileLOG
    echo "Copiando Archivos de NAIGUATA VISA al Servidor de EDITPACK" | tee -a $vFileLOG
    echo "------------------------------------------------------------------------------" | tee -a $vFileLOG
    vSSHERROR=0
    vSSHStat=0
    vSSELOGSZ=0
    vFHsys=`date '+%Y%m%d%H%M%S'`
    vFileParSFTP="${DIRTMP}/${dpNom}_${vFHsys}.PAR.SFTP"
    vFileBatSFTP="${DIRTMP}/${dpNom}_${vFHsys}.BAT.SFTP"
    vFecSesCorta=`echo $vFecSes | awk '{ print substr($0,3) }'`
    for vEndPoint in 0105 0108
    do
       vARCHVI=`ls -t ${DIROUT}/OUTVI${vEndPoint}${vFecSes}.DAT 2>/dev/null | wc -l`
       vARCHVI=`printf "%d" "$vARCHVI"`
       if [ "$vARCHVI" = "0" ]
       then
          vFileLOG="${DIRLOG}/SGCPCLROUTVISA_NGTA${vFecSes}.${vCodHCierre}.LOG"
          tput setf 8
          echo "***************************************************************************" | tee -a $vFileLOG
          echo "El Archivo de Outgoing de NAIGUATA VISA del Adquiriente $vEndPoint" | tee -a $vFileLOG
          echo "Archivo: $DIROUT/OUTVI-NGTA$vEndPoint$vFecSes.DAT" | tee -a $vFileLOG
          echo "No Existe o esta Vacio" | tee -a $vFileLOG
          echo "Esto Indica una falla no detectada en el Proceso de Outgoing de NAIGUATA VISA" | tee -a $vFileLOG
          echo "Revisar el log $vFileLOG" | tee -a $vFileLOG
          echo "***************************************************************************" | tee -a $vFileLOG
          tput setf 7
          sqlplus -s $DB @$DIRBIN/alertacie VISA OUTVINGTA "Outgoing_VISA_Archivo_OUTVI-NGTA$vEndPoint$vFecSes.DAT_No_Existe_o_Vacio"
          vSSHERROR=1
          vEstOUTVISA_NGTA="E"
       fi
       vRUTAWIN=/OUTGOING
#		vRUTAWIN=/C411032/OUTGOING      #GLOBALR - SOLO PARA EL AMBIENTE DE CALIDAD.	   
		
       if [ "$vEstOUTVISA_NGTA" = "F" ]
       then
          case $vEndPoint in
            0105)
                vEndPointADQ=BM
                ;;
            0108)
                vEndPointADQ=BP
                ;;
          esac
#          echo "mkdir ${vRUTAWIN}/OU${vFecSesCorta}" >> $vFileBatSFTP
          for vARCHVI in `ls -t ${DIROUT}/OUTVI-NGTA${vEndPoint}${vFecSes}.DAT`
          do
             vARCHVIDEST="OUTVIS-NGTA${vEndPointADQ}${vFecSesCorta}.CTF"
             unix2dos -ascii -437 $vARCHVI $DIROUT/$vARCHVIDEST
#             echo "put $DIROUT/$vARCHVIDEST ${vRUTAWIN}/OU${vFecSesCorta}/${vARCHVIDEST}"  >> $vFileBatSFTP
             echo "put $DIROUT/$vARCHVIDEST ${vRUTAWIN}/${vARCHVIDEST}"  >> $vFileBatSFTP
          done
          sftp -b $vFileBatSFTP ${SFTP_USER}@${SFTP_VISA} > $vFileParSFTP 2>&1
          vSSHStat=$?
          vSSHELOGSZ=`/usr/xpg4/bin/grep -v -e mkdir -e put -e Uploading -e sftp -e Connecting $vFileParSFTP | wc -l`
          if [ "$vSSHStat" != "0" ] || [ "$vSSHELOGSZ" -gt "0" ]
          then
             vSSHERROR=1
             cat $vFileParSFTP | tee -a $vFileLOG
          fi
          rm $vFileBatSFTP
          rm $vFileParSFTP
       fi
    done
    if [ "$vSSHERROR" = "0" ]
    then
       echo "***************************************************************************" | tee -a $vFileLOG
       echo "Copia de Archivos de NAIGUATA VISA" | tee -a $vFileLOG
       echo "Finalizada CORRECTAMENTE" | tee -a $vFileLOG
       echo "Ejecutar Proceso de Validacion en EDITPACK" | tee -a $vFileLOG
       echo "***************************************************************************" | tee -a $vFileLOG
	   
				  #GLOBALR 27/01/2015 IPR 1148 - Transferencia de Archivos del Outgoing a los bancos
				  SGCFTPOutgoingAdq.sh ${vFecSes} BM VI ${vFecAbo} ${vCodHCierre} ${vFecAbo}
				  SGCFTPOutgoingAdq.sh ${vFecSes} BP VI ${vFecAbo} ${vCodHCierre} ${vFecAbo}
    fi
  elif [ "$vEstOUTVISA_NGTA" = "E" ]
  then
    vFileLOG="${DIRLOG}/SGCPCLROUTVISA_NGTA${vFecSes}.${vCodHCierre}.LOG"
    tput setf 8
    echo "***************************************************************************" | tee -a $vFileLOG
    echo "Error, el Proceso de OutGoing de NAIGUATA VISA Finalizo CON ERRORES" | tee -a $vFileLOG
    echo "Revisar el Log $vFileLOG" | tee -a $vFileLOG
    echo "***************************************************************************" | tee -a $vFileLOG
    tput setf 7
  fi
}
################################################################################
## INICIO | PROCEDIMIENTO PRINCIPAL
################################################################################

echo


## Fecha de Sesion
################################################################################

if [ "${pFecSes}" = "" ]; then
   vFecSes=`getdate`
else
   ValFecha.sh ${pFecSes}
   vRet="$?"
   if [ "$vRet" != "0" ]; then
      f_msg "Fecha de Sesion Incorrecta (FecSes=${pFecSes})"
      f_msg
      exit 1;
   fi
   vFecSes=${pFecSes}
fi

## Hora de Cierre Descripcion
################################################################################

vHCierre1=`ORAExec.sh "exec :rC:=PQPLIQ.gHRA_CIERRE1;" $DB`
vHCierre2=`ORAExec.sh "exec :rC:=PQPLIQ.gHRA_CIERRE2;" $DB`

vHCierre1=`echo $vHCierre1 | awk '{print substr($0,1,5)}'`
vHCierre2=`echo $vHCierre2 | awk '{print substr($0,1,5)}'`

## Codigo de Hora de Cierre
################################################################################

if [ "$pCodHCierre" = "" ]; then
   f_msg "ERROR | El Codigo de Hora de Cierre es Obligatorio" S N
   exit 1;
fi

if [ "$pCodHCierre" = "1" ]; then
   vHCierre="${vHCierre1}"
elif [ "$pCodHCierre" = "2" ]; then
     vHCierre="${vHCierre2}"
else
   f_msg "ERROR | Codigo de Hora de Cierre Incorrecto" S N
   exit 1;
fi

## Archivo de Control
################################################################################

vFileCTL="$DIRDAT/SGCPCLR${pFecSes}.${pCodHCierre}.CTL"

## Menu Principal
################################################################################

while ( test -z "$vOpcion" || true ) do

   f_admCTL R

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

   # ARCHIVOS

   vFileCTL="${DIRDAT}/SGCPCLR${vFecSes}.${pCodHCierre}.CTL"
   vFileLOGOUTVISA="${DIRLOG}/SGCPCLROUTVISA${vFecSes}.${pCodHCierre}.LOG"
   vFileLOGOUTMC="${DIRLOG}/SGCPCLROUTMC${vFecSes}.${pCodHCierre}.LOG"
   vFileLOGOUTPRICE="${DIRLOG}/SGCPCLROUTPRICE${vFecSes}.${pCodHCierre}.LOG"
   vFileLOGOUTALL="${DIRLOG}/SGCPCLROUTALL${vFecSes}.${pCodHCierre}.LOG"
   # LOG PARA NAIGUATA 
   vFileLOGOUTVISA_NGTA="${DIRLOG}/SGCPCLROUTVISA_NGTA${vFecSes}.${pCodHCierre}.LOG"
   vFileLOGOUTMC_NGTA="${DIRLOG}/SGCPCLROUTMC_NGTA${vFecSes}.${pCodHCierre}.LOG"

   # OUTGOING DE VISA

########################################################################################
## IPR 1039: Solo Permitir el Outgoing de VISA cuando se este en condicion de Cierre 2
## 17/02/2012 DCB 
########################################################################################
   if [ "$vOpcion" = "1" ] && [ "$pCodHCierre" = "2" ]; then
##########################################################################################
## FIN IPR 1039: Solo Permitir el Outgoing de VISA cuando se este en condicion de Cierre 2
## 17/02/2012 DCB 
##########################################################################################

      vFlgOpcErr="N"
      vOpcion=""

      # Confirmacion de Ejecucion
      if [ "$pOpcRepro" = "S" ]; then
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
      f_msg " Proceso: OUTGOING DE VISA" N S
      f_fechora $vFecSes
      f_msg " Fecha de Sesion: $vpValRet" N S
      f_msg
      echo " Desea Continuar? (S=Si/N=No/<Enter>=No) => \c"
      read ValConf
      f_msg

      if [ "$ValConf" = "s" ] || [ "$ValConf" = "S" ]; then
         f_msg "--------------------------------------------------------------------------------" N S
         f_msg
         vFileLOG="${DIRLOG}/SGCPCLROUTVISA${vFecSes}.${pCodHCierre}.`date '+%Y%m%d%H%M%S'`.LOG"
         if [ -f "$vFileLOG" ]; then
            rm -f $vFileLOG
         fi
         touch $vFileLOG
         echo
         echo "         Archivo de Control : `basename ${vFileCTL}`"
         echo "                 Directorio : `dirname ${vFileCTL}`"
         echo "   Archivo LOG de Ejecucion : `basename ${vFileLOG}`"
         echo "                 Directorio : `dirname ${vFileLOG}`"
         echo "    Archivo LOG del Proceso : `basename ${vFileLOGOUTVISA}`"
         echo "                 Directorio : `dirname ${vFileLOGOUTVISA}`"
         echo
         nohup ${DIRBIN}/SGCPCLR.sh ${vFecSes} ${pCodHCierre} OUTVISA ${pOpcRepro} S 1>${vFileLOG} 2>&1 &
         PROCVI=$!
         trap "" 2
         cat $vFileLOG
         transvisa		
#         trap "trap '' 2" 2  #comentado cambios IPR 1148
#         tail -f $vFileLOG
#         trap ""
      fi

   fi # Opcion 1

#############################################################################################
## OUTGOING DE VISA NAIGUATA IPR 1302  cuando se este en condicion de Cierre 2 16/1/2020 FJVG
#############################################################################################
   if [ "$vOpcion" = "10" ] && [ "$pCodHCierre" = "2" ]; then
##########################################################################################

      vFlgOpcErr="N"
      vOpcion=""

      # Confirmacion de Ejecucion
      if [ "$pOpcRepro" = "S" ]; then
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
      f_msg " Proceso: OUTGOING DE VISA" N S
      f_fechora $vFecSes
      f_msg " Fecha de Sesion: $vpValRet" N S
      f_msg
      echo " Desea Continuar? (S=Si/N=No/<Enter>=No) => \c"
      read ValConf
      f_msg

      if [ "$ValConf" = "s" ] || [ "$ValConf" = "S" ]; then
         f_msg "--------------------------------------------------------------------------------" N S
         f_msg
         vFileLOG="${DIRLOG}/SGCPCLROUTVISA_NGTA${vFecSes}.${pCodHCierre}.`date '+%Y%m%d%H%M%S'`.LOG"
         if [ -f "$vFileLOG" ]; then
            rm -f $vFileLOG
         fi
         touch $vFileLOG
         echo
         echo "         Archivo de Control : `basename ${vFileCTL}`"
         echo "                 Directorio : `dirname ${vFileCTL}`"
         echo "   Archivo LOG de Ejecucion : `basename ${vFileLOG}`"
         echo "                 Directorio : `dirname ${vFileLOG}`"
         echo "    Archivo LOG del Proceso : `basename ${vFileLOGOUTVISA_NGTA}`"
         echo "                 Directorio : `dirname ${vFileLOGOUTVISA_NGTA}`"
         echo
         nohup ${DIRBIN}/SGCPCLR.sh ${vFecSes} ${pCodHCierre} OUTVISANG ${pOpcRepro} S 1>${vFileLOG} 2>&1 &
         PROCVI=$!
         trap "" 2
         cat $vFileLOG
         ##transvisaNG  ## comentado para verificar cual es la ruta para trasmitir el archivo naiguata visa IPR1302 
      fi

   fi # Opcion 11 Naiguata

################################################################################

################################################################################
## IPR 1039: Modificacion orden de ejecucion
## vOpcion = 2 MASTERCARD ===> vOpcion = 2 PRICE
## vOpcion = 3 PRICE ===> vOpcion = 3 MASTERCARD
## 09/12/2011 EEVN 
################################################################################
## IPR 1039: Solo Permitir el Outgoing de PRICE cuando se este en condicion de Cierre 2
## 17/02/2012 DCB 
########################################################################################
      # OUTGOING DE PRICE

   if [ "$vOpcion" = "2" ] && [ "$pCodHCierre" = "2" ]; then

      vFlgOpcErr="N"
      vOpcion=""

      # Confirmacion de Ejecucion
      if [ "$pOpcRepro" = "S" ]; then
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
      f_msg " Proceso: OUTGOING DE PRICE" N S
      f_fechora $vFecSes
      f_msg " Fecha de Sesion: $vpValRet" N S
      f_msg
      echo " Desea Continuar? (S=Si/N=No/<Enter>=No) => \c"
      read ValConf
      f_msg

      if [ "$ValConf" = "s" ] || [ "$ValConf" = "S" ]; then
         f_msg "--------------------------------------------------------------------------------" N S
         f_msg
         vFileLOG="${DIRLOG}/SGCPCLROUTPRICE${vFecSes}.${pCodHCierre}.`date '+%Y%m%d%H%M%S'`.LOG"
         if [ -f "$vFileLOG" ]; then
            rm -f $vFileLOG
         fi
         touch $vFileLOG
         echo
         echo "         Archivo de Control : `basename ${vFileCTL}`"
         echo "                 Directorio : `dirname ${vFileCTL}`"
         echo "   Archivo LOG de Ejecucion : `basename ${vFileLOG}`"
         echo "                 Directorio : `dirname ${vFileLOG}`"
         echo "    Archivo LOG del Proceso : `basename ${vFileLOGOUTPRICE}`"
         echo "                 Directorio : `dirname ${vFileLOGOUTPRICE}`"
         echo
         nohup ${DIRBIN}/SGCPCLR.sh ${vFecSes} ${pCodHCierre} OUTPRICE ${pOpcRepro} S 1>${vFileLOG} 2>&1 &
         trap "trap '' 2" 2
         tail -f $vFileLOG
         trap ""
      fi

   fi # Opcion 2

   # OUTGOING DE MASTERCARD

   if [ "$vOpcion" = "3" ]; then

      vFlgOpcErr="N"
      vOpcion=""

      # Confirmacion de Ejecucion
      if [ "$pOpcRepro" = "S" ]; then
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
      f_msg " Proceso: OUTGOING DE MASTERCARD" N S
      f_fechora $vFecSes
      f_msg " Fecha de Sesion: $vpValRet" N S
      f_msg
      echo " Desea Continuar? (S=Si/N=No/<Enter>=No) => \c"
      read ValConf
      f_msg

      if [ "$ValConf" = "s" ] || [ "$ValConf" = "S" ]; then
         f_msg "--------------------------------------------------------------------------------" N S
         f_msg
         vFileLOG="${DIRLOG}/SGCPCLROUTMC${vFecSes}.${pCodHCierre}.`date '+%Y%m%d%H%M%S'`.LOG"
         if [ -f "$vFileLOG" ]; then
            rm -f $vFileLOG
         fi
         touch $vFileLOG
         echo
         echo "         Archivo de Control : `basename ${vFileCTL}`"
         echo "                 Directorio : `dirname ${vFileCTL}`"
         echo "   Archivo LOG de Ejecucion : `basename ${vFileLOG}`"
         echo "                 Directorio : `dirname ${vFileLOG}`"
         echo "    Archivo LOG del Proceso : `basename ${vFileLOGOUTMC}`"
         echo "                 Directorio : `dirname ${vFileLOGOUTMC}`"
         echo
         nohup ${DIRBIN}/SGCPCLR.sh ${vFecSes} ${pCodHCierre} OUTMC ${pOpcRepro} S 1>${vFileLOG} 2>&1 &
         PROCMC=$!
         trap "" 2
         cat $vFileLOG
         transmc
#         trap "trap '' 2" 2  #Modificacion IPR 1148
#         tail -f $vFileLOG
#         trap ""
      fi

   fi # Opcion 3

################################################################################
## FIN IPR 1039: Modificacion orden de ejecucion
## vOpcion = 2 MASTERCARD ===> vOpcion = 2 PRICE
## vOpcion = 3 PRICE ===> vOpcion = 3 MASTERCARD
## 09/12/2011 EEVN 
################################################################################
################################################################################
## OUTGOING DE MASTERCARD NAIGUATA  IPR 1039  FJVG  06082020
## Proceso Outgoing de MC Ngta 
################################################################################
   if [ "$vOpcion" = "30" ]; then

      vFlgOpcErr="N"
      vOpcion=""

      # Confirmacion de Ejecucion
      if [ "$pOpcRepro" = "S" ]; then
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
      f_msg " Proceso: OUTGOING DE NAIGUATA MASTERCARD" N S
      f_fechora $vFecSes
      f_msg " Fecha de Sesion: $vpValRet" N S
      f_msg
      echo " Desea Continuar? (S=Si/N=No/<Enter>=No) => \c"
      read ValConf
      f_msg

      if [ "$ValConf" = "s" ] || [ "$ValConf" = "S" ]; then
         f_msg "--------------------------------------------------------------------------------" N S
         f_msg
         vFileLOG="${DIRLOG}/SGCPCLROUTMC_NGTA${vFecSes}.${pCodHCierre}.`date '+%Y%m%d%H%M%S'`.LOG"
         if [ -f "$vFileLOG" ]; then
            rm -f $vFileLOG
         fi
         touch $vFileLOG
         echo
         echo "         Archivo de Control : `basename ${vFileCTL}`"
         echo "                 Directorio : `dirname ${vFileCTL}`"
         echo "   Archivo LOG de Ejecucion : `basename ${vFileLOG}`"
         echo "                 Directorio : `dirname ${vFileLOG}`"
         echo "    Archivo LOG del Proceso : `basename ${vFileLOGOUTMC_NGTA}`"
         echo "                 Directorio : `dirname ${vFileLOGOUTMC_NGTA}`"
         echo
         nohup ${DIRBIN}/SGCPCLR.sh ${vFecSes} ${pCodHCierre} OUTMCNG ${pOpcRepro} S 1>${vFileLOG} 2>&1 &
         PROCMC=$!
         trap "" 2
         cat $vFileLOG
         #transmcNG  # Se comenta para verificar cambio en la ruta para naiguata IPR1302 fjvg	
      fi

   fi # Opcion 30

   # TODOS LOS OUTGOING

##########################################################################################
## IPR 1039: Solo Permitir el Outgoing Total cuando se este en condicion de Cierre 2
## 17/02/2012 DCB 
##########################################################################################
   if [ "$vOpcion" = "4" ] && [ "$pCodHCierre" = "2" ]; then
##########################################################################################
## FIN IPR 1039: Solo Permitir el Outgoing Total cuando se este en condicion de Cierre 2
## 17/02/2012 DCB 
##########################################################################################

      vFlgOpcErr="N"
      vOpcion=""

      # Confirmacion de Ejecucion
      if [ "$pOpcRepro" = "S" ]; then
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
      f_msg " Proceso: TODOS LOS OUTGOING" N S
      f_fechora $vFecSes
      f_msg " Fecha de Sesion: $vpValRet" N S
      f_msg
      echo " Desea Continuar? (S=Si/N=No/<Enter>=No) => \c"
      read ValConf
      f_msg

      if [ "$ValConf" = "s" ] || [ "$ValConf" = "S" ]; then
         f_msg "--------------------------------------------------------------------------------" N S
         f_msg
         vFileLOG="${DIRLOG}/SGCPCLROUTALL${vFecSes}.${pCodHCierre}.`date '+%Y%m%d%H%M%S'`.LOG"
         if [ -f "$vFileLOG" ]; then
            rm -f $vFileLOG
         fi
         touch $vFileLOG
         echo
         echo "            Archivo de Control : `basename ${vFileCTL}`"
         echo "                    Directorio : `dirname ${vFileCTL}`"
         echo "      Archivo LOG de Ejecucion : `basename ${vFileLOG}`"
         echo "                    Directorio : `dirname ${vFileLOG}`"
         echo "       Archivo LOG del Proceso : `basename ${vFileLOGOUTALL}`"
         echo "                    Directorio : `dirname ${vFileLOGOUTALL}`"
         echo
         nohup ${DIRBIN}/SGCPCLR.sh ${vFecSes} ${pCodHCierre} OUTALL ${pOpcRepro} S 1>${vFileLOG} 2>&1 &
         trap "trap '' 2" 2
		 cat $vFileLOG
		 transmc
		 transvisa	
         trap ""
 #        tail -f $vFileLOG  #Modificado IPR 1148
 #        trap ""
      fi

   fi # Opcion 4


   # LOG DE OUTGOING DE VISA

   if [ "$vOpcion" = "5" ]; then

      vFlgOpcErr="N"
      vOpcion=""

      if [ -f "${vFileCTL}" ]; then
         f_admCTL R
         case $vEstOUTVISA in
              0) echo
                 f_msg "   >> El Proceso de Outgoing de Visa aun no ha sido ejecutado."
                 echo
                 echo "... presione [ENTER] para regresar."
                 read vContinua;;
              P) echo
                 f_msg "   >> Proceso de Outgoing de Visa en Ejecucion... [CTRL+C para salir del LOG]"
                 echo
                 trap "trap '' 2" 2
                 tail -f ${vFileLOGOUTVISA}
                 trap "";;
              *) echo
                 f_msg "   >> Archivo LOG: `basename ${vFileLOGOUTVISA}`"
                 echo
                 if [ -f "${vFileLOGOUTVISA}" ]; then
                    cat ${vFileLOGOUTVISA}
                 else
                    f_msg "   >> No se ha encuentrado el archivo Log."
                 fi
                 echo
                 echo "... presione [ENTER] para regresar."
                 read vContinua;;
         esac
      else
         echo
         f_fhmsg "El Proceso de Outgoing de Visa aun no ha sido ejecutado."
         echo
         echo "... presione [ENTER] para regresar."
         read vContinua;
      fi

   fi # Opcion 5
   
################################################################################
## IPR 1302:  LOG DE OUTGOING DE VISA NAIGUATA
################################################################################
  

   if [ "$vOpcion" = "50" ]; then

      vFlgOpcErr="N"
      vOpcion=""

      if [ -f "${vFileCTL}" ]; then
         f_admCTL R
         case $vEstOUTVISA_NGTA in
              0) echo
                 f_msg "   >> El Proceso de Outgoing de Visa Naiguata aun no ha sido ejecutado."
                 echo
                 echo "... presione [ENTER] para regresar."
                 read vContinua;;
              P) echo
                 f_msg "   >> Proceso de Outgoing de Visa Naiguata en Ejecucion... [CTRL+C para salir del LOG]"
                 echo
                 trap "trap '' 2" 2
                 tail -f ${vFileLOGOUTVISA_NGTA}
                 trap "";;
              *) echo
                 f_msg "   >> Archivo LOG: `basename ${vFileLOGOUTVISA_NGTA}`"
                 echo
                 if [ -f "${vFileLOGOUTVISA_NGTA}" ]; then
                    cat ${vFileLOGOUTVISA_NGTA}
                 else
                    f_msg "   >> No se ha encuentrado el archivo Log."
                 fi
                 echo
                 echo "... presione [ENTER] para regresar."
                 read vContinua;;
         esac
      else
         echo
         f_fhmsg "El Proceso de Outgoing de Visa Naiguata aun no ha sido ejecutado."
         echo
         echo "... presione [ENTER] para regresar."
         read vContinua;
      fi

   fi # Opcion 50
   
################################################################################
## IPR 1039: Modificacion orden de ejecucion
## vOpcion = 6 MASTERCARD ===> vOpcion = 6 PRICE
## vOpcion = 7 PRICE ===> vOpcion = 7 MASTERCARD
## 09/12/2011 EEVN 
################################################################################
   # LOG DE OUTGOING DE PRICE

   if [ "$vOpcion" = "6" ]; then

      vFlgOpcErr="N"
      vOpcion=""

      if [ -f "${vFileCTL}" ]; then
         f_admCTL R
         case $vEstOUTPRICE in
              0) echo
                 f_msg "   >> El Proceso de Outgoing de Price aun no ha sido ejecutado."
                 echo
                 echo "... presione [ENTER] para regresar."
                 read vContinua;;
              P) echo
                 f_msg "   >> Proceso de Outgoing de Price en Ejecucion... [CTRL+C para salir del LOG]"
                 echo
                 trap "trap '' 2" 2
                 tail -f ${vFileLOGOUTPRICE}
                 trap "";;
              *) echo
                 f_msg "   >> Archivo LOG: `basename ${vFileLOGOUTPRICE}`"
                 echo
                 if [ -f "${vFileLOGOUTPRICE}" ]; then
                    cat ${vFileLOGOUTPRICE}
                 else
                    f_msg "   >> No se ha encuentrado el archivo Log."
                 fi
                 echo
                 echo "... presione [ENTER] para regresar."
                 read vContinua;;
         esac
      else
         echo
         f_fhmsg "El Proceso de Outgoing de Price aun no ha sido ejecutado."
         echo
         echo "... presione [ENTER] para regresar."
         read vContinua;
      fi

   fi # Opcion 6


   # LOG DE OUTGOING DE MASTERCARD

   if [ "$vOpcion" = "7" ]; then

      vFlgOpcErr="N"
      vOpcion=""

      if [ -f "${vFileCTL}" ]; then
         f_admCTL R
         case $vEstOUTMC in
              0) echo
                 f_msg "   >> El Proceso de Outgoing de Mastercard aun no ha sido ejecutado."
                 echo
                 echo "... presione [ENTER] para regresar."
                 read vContinua;;
              P) echo
                 f_msg "   >> Proceso de Outgoing de Mastercard en Ejecucion... [CTRL+C para salir del LOG]"
                 echo
                 trap "trap '' 2" 2
                 tail -f ${vFileLOGOUTMC}
                 trap "";;
              *) echo
                 f_msg "   >> Archivo LOG: `basename ${vFileLOGOUTMC}`"
                 echo
                 if [ -f "${vFileLOGOUTMC}" ]; then
                    cat ${vFileLOGOUTMC}
                 else
                    f_msg "   >> No se ha encuentrado el archivo Log."
                 fi
                 echo
                 echo "... presione [ENTER] para regresar."
                 read vContinua;;
         esac
      else
         echo
         f_fhmsg "El Proceso de Outgoing de Mastercard aun no ha sido ejecutado."
         echo
         echo "... presione [ENTER] para regresar."
         read vContinua;
      fi

   fi # Opcion 7
################################################################################
## FIN IPR 1302:  # LOG DE OUTGOING DE MASTERCARD 16/01/2020 
################################################################################

   if [ "$vOpcion" = "70" ]; then

      vFlgOpcErr="N"
      vOpcion=""

      if [ -f "${vFileCTL}" ]; then
         f_admCTL R
         case $vEstOUTMC_NGTA in
              0) echo
                 f_msg "   >> El Proceso de Outgoing de Mastercard Naiguata aun no ha sido ejecutado."
                 echo
                 echo "... presione [ENTER] para regresar."
                 read vContinua;;
              P) echo
                 f_msg "   >> Proceso de Outgoing de Mastercard Naiguata en Ejecucion... [CTRL+C para salir del LOG]"
                 echo
                 trap "trap '' 2" 2
                 tail -f ${vFileLOGOUTMC_NGTA}
                 trap "";;
              *) echo
                 f_msg "   >> Archivo LOG: `basename ${vFileLOGOUTMC_NGTA}`"
                 echo
                 if [ -f "${vFileLOGOUTMC_NGTA}" ]; then
                    cat ${vFileLOGOUTMC_NGTA}
                 else
                    f_msg "   >> No se ha encuentrado el archivo Log."
                 fi
                 echo
                 echo "... presione [ENTER] para regresar."
                 read vContinua;;
         esac
      else
         echo
         f_fhmsg "El Proceso de Outgoing de Mastercard Naiguata aun no ha sido ejecutado."
         echo
         echo "... presione [ENTER] para regresar."
         read vContinua;
      fi

   fi # Opcion 70
################################################################################

   # LOG DE OUTGOING TODOS

   if [ "$vOpcion" = "8" ]; then

      vFlgOpcErr="N"
      vOpcion=""

      if [ -f "${vFileCTL}" ]; then
         f_admCTL R
         if [ "$vEstOUTVISA" = "0" ] && [ "$vEstOUTMC" = "0" ] && [ "$vEstOUTPRICE" = "0" ]; then
            echo
            f_msg "   >> El Proceso de Outgoing aun no ha sido ejecutado."
            echo
            echo "... presione [ENTER] para regresar."
            read vContinua;
         elif [ "$vEstOUTVISA" = "P" ] || [ "$vEstOUTMC" = "P" ] || [ "$vEstOUTPRICE" = "P" ]; then
              echo
              f_msg "   >> Proceso de Outgoing de Price en Ejecucion... [CTRL+C para salir del LOG]"
              echo
              trap "trap '' 2" 2
              tail -f ${vFileLOGOUTALL}
              trap "";
         else
            echo
            f_msg "   >> Archivo LOG: `basename ${vFileLOGOUTALL}`"
            echo
            if [ -f "${vFileLOGOUTALL}" ]; then
               cat ${vFileLOGOUTALL}
            else
               f_msg "   >> No se ha encuentrado el archivo Log."
            fi
            echo
            echo "... presione [ENTER] para regresar."
            read vContinua;
         fi
      else
         echo
         f_msg "   >> El Proceso de Outgoing aun no ha sido ejecutado."
         echo
         echo "... presione [ENTER] para regresar."
         read vContinua;
      fi

   fi # Opcion 8


   # OPCION INCORRECTA

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
