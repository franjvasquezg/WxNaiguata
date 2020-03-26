#!/bin/ksh

################################################################################
##
##  Nombre del Programa : SGCPCLR.sh
##                Autor : SSM
##       Codigo Inicial : 01/05/2007
##          Descripcion : Ejecucion de Procesos de Clearing
##
##  ======================== Registro de Modificaciones ========================
##
##  Fecha      Autor Version Descripcion de la Modificacion
##  ---------- ----- ------- ---------------------------------------------------
##  01/05/2007 SSM   1.00    Codigo Inicial
##  11/01/2008 SSM   1.01    Modificacion de PQOUTGOINGVISA
##  18/01/2008 SSM   1.02    PQOUTGOINGMC.P_OUTGOINGMC -> PQOUTGOINGMC.F_MAIN
##  17/06/2008 SSM   1.10    Cambios en PQPCLRRPT.F_CLR_GENDATRPT
##  03/07/2008 JMG   1.20    Actualizacion de script para PQPCLRRPT.F_CLR_GENDATRPT
##  17/05/2011 JMG   1.50    Manejo de Outgoing independiente MC, VISA y PRICE
##  23/05/2011 JMG   2.00    IPR 943: Cambio de Horario de Cierre
##  20/03/2012 DCB   2.00    IPR 1039: Cambio de Orden de Outgoing OUTALL
##  23/05/2012 CRF   2.01    Incidencia TDP-1027020. Mejora Ctrl Estados.
##  25/05/2012 CRF   2.02    Incidencia TDP-1052816. Interrumpe Ejecucion para
##                           descuadre en el clearing y envio de alerta SGCMON.
##  06/06/2012 JMG   2.50    Modificacion de script para enviar alertas del
##                           Outgoing Mastercard y Price en el SGCMON.
##                           Nuevo FileConverter.sh que reemplaza a BitMapConv.
##  06/02/2020 FJV   3.20    IRP 1302 cambion en proceso automatico.
##
################################################################################

################################################################################
## DECLARACION DE DATOS, PARAMETROS DE EJECUCION Y VARIABLES DEL PROGRAMA
################################################################################


## Datos del Programa
################################################################################

dpNom="SGCPCLR"               # Nombre del Programa
dpDesc=""                     # Descripcion del Programa
dpVer=3.20                    # Ultima Version del Programa
dpFec="20200206"              # Fecha de Ultima Actualizacion [Formato:AAAAMMDD]


## Variables del Programa
################################################################################

vpValRet=""                   # Valor de Retorno (funciones)
vpFH=`date '+%Y%m%d%H%M%S'`   # Fecha y Hora [Formato:AAAAMMDDHHMMSS]
vpFileLOG=""                  # Nombre del Archivo LOG del Programa


## Parametros de Ejecucion
################################################################################

pFecSes="$1"                  # Fecha de Sesion
pCodHCierre="$2"              # Codigo de Hora de Cierre
pOpcProc="$3"                 # Opcion de Proceso
pOpcRepro="$4"                # Opcion de Reproceso (S=Si/N=No)
pFlgBG="$5"                   # Ejecucion en Background (S=Si/N=No)


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
typeset -i vContReg           # Contador de Registros
typeset -i vIDAlerta          # ID de Alerta
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


# f_msgtit | muestra mensaje de titulo
# Parametros
#   pTipo : tipo de mensaje de titulo [I=Inicio/F=Fin OK/E=Fin Error]
################################################################################
f_msgtit ()
{
pTipo="$1"
if [ "${dpDesc}" = "" ]; then
   vMsg="${dpNom}"
else
   vMsg="${dpNom} - ${dpDesc}"
fi
if [ "${pTipo}" = "I" ]; then
   vMsg="INICIO | ${vMsg}"
elif [ "${pTipo}" = "F" ]; then
     vMsg="FIN OK | ${vMsg}"
else
   vMsg="FIN ERROR | ${vMsg}"
fi
vMsg="\n\
********************************************************** [`date '+%d.%m.%Y'` `date '+%H:%M:%S'`]
 ${vMsg}\n\
********************************************************************************
\n\
"
f_admCTL
f_msg "${vMsg}" S
if [ "${pTipo}" = "E" ]; then
   f_CtrlC
   exit 1;
elif [ "${pTipo}" = "F" ]; then
   f_CtrlC
   exit 0;
fi
}


# f_finerr | error en el programa, elimina archivos de trabajo
# Parametros
#   pMsg : mensaje a mostrar
################################################################################
f_finerr ()
{
# <Inicio RollBack>
# <Fin RollBack>
pMsg="$1"
if [ "${pMsg}" != "" ]; then
   f_fhmsg "${pMsg}"
fi
f_msgtit E
}


# f_vrfvalret | verifica valor de retorno, fin error si el valor es 1
# Parametros
#   pValRet : valor de retorno
#   pMsgErr : mensaje de error
################################################################################
f_vrfvalret ()
{
pValRet="$1"
pMsgErr="$2"
if [ "${pValRet}" != "0" ]; then
   f_finerr "${pMsgErr}"
fi
}


# f_parametros | muestra los parametros de ejecucion
################################################################################
f_parametros ()
{
f_fechora ${dpFec}
echo "
--------------------------------------------------------------------------------
${dpNom} - Parametros de Ejecucion

Parametro 1 (obligatorio) : Fecha de Sesion [Formato=YYYYMMDD1]
Parametro 2 (obligatorio) : Codigo de Hora de Cierre [1=${vHCierre1}/2=${vHCierre1}]
Parametro 3 (obligatorio) : Opcion de Proceso [CLR/PLIQ/OUTMC/OUTVISA/OUTPRICE/OUTALL/REP]
Parametro 4 (opcional)    : Opcion de Reproceso [S=Si/N=No(default)]
Parametro 5 (opcional)    : Flag de Proceso en Background [S=Si/N=No(default)]

--------------------------------------------------------------------------------
Programa: ${dpNom} | Version: ${dpVer} | Modificacion: ${vpValRet}
" | more
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
  # [22-22] Estado del Proceso de Outgoing VISA NGTA
  # [24-24] Estado del Proceso de Outgoing Master Card NGTA
  # [26-37] Fecha y Hora de Actualizacion de los Estados [AAAAMMDDHHMMSS]

  pOpcion="$1"

  if [ "$pOpcion" = "R" ]; then
     test ! -f $vFileCTL
     if [ "$?" = "0" ]; then
        # Crea el Archivo CTL
        # echo "SGCPCLR ENTRO CREAR EL ARCHIVO CTL en SGCPCLR" #prueba IPR 1302 
        vEstCLR="0"
        vEstPLIQ="0"
        vEstOUTVISA="0"
        vEstOUTMC="0"
        vEstOUTPRICE="0"
        vEstOUTVISA_NGTA="0"           # Estado del Proceso de Outgoing VISA NGTA
        vEstOUTMC_NGTA="0"             # Estado del Proceso de Outgoing Master Card NGTA
        echo "${pFecSes}|${pCodHCierre}|${vEstCLR}|${vEstPLIQ}|${vEstOUTVISA}|${vEstOUTMC}|${vEstOUTPRICE}|${vEstOUTVISA_NGTA}|${vEstOUTMC_NGTA}|`date '+%Y%m%d%H%M%S'`" > $vFileCTL
     else
        ##echo "SGCPCLR ENTRO BUSCA DATOS EN CTL en SGCPCLR" #prueba IPR 1302 
        vEstCLR=`awk '{print substr($0,12,1)}' $vFileCTL`
        vEstPLIQ=`awk '{print substr($0,14,1)}' $vFileCTL`
        vEstOUTVISA=`awk '{print substr($0,16,1)}' $vFileCTL`
        vEstOUTMC=`awk '{print substr($0,18,1)}' $vFileCTL`
        vEstOUTPRICE=`awk '{print substr($0,20,1)}' $vFileCTL`
        vEstOUTVISA_NGTA=`awk '{print substr($0,22,1)}' $vFileCTL`           
        vEstOUTMC_NGTA=`awk '{print substr($0,24,1)}' $vFileCTL`             
     fi
  else
     ##echo "vEstCLR: $vEstCLR vEstPLIQ: $vEstPLIQ en el SC SGCPCLR" #prueba IPR 1302 
     ##echo "Actualizo archivo de control con los vEstCLR, vEstPLIQ Actualizados "
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
          vNomEst="PENDIENTE";;
       P)
          vNomEst="EN PROCESO";;
       F)
          vNomEst="FINALIZADO";;
       E)
          vNomEst="FIN ERROR";;
       *)
          vNomEst="DESCONOCIDO";;
  esac

}

# f_CtrlC () | espera un CTRL+C para continuar
################################################################################
f_CtrlC ()
{
  if [ "$pFlgBG" = "S" ]; then
     echo " --> PRESIONE [CTRL+C] PARA REGRESAR"
     echo
  fi
}

# f_ftp () | transferencia FTP
################################################################################
f_ftp ()
{

pDirOri="$1"
pDirDest="$2"
pFile="$3"
pTipoTransf="$7"

vFileParFTP="${DIRTMP}/${dpNom}_${vFHsys}.PAR.FTP"

if [ "$pTipoTransf" = "" ]; then
   pTipoTransf="ascii"
else
   if [ "$pTipoTransf" = "B" ]; then
      pTipoTransf="bin"
   else
      pTipoTransf="ascii"
   fi
fi

cd $pDirOri

touch ${pFile}.FLG

vCmdFTP="\
        verbose                      \n\
        open ${FTP_HOSTXCOM}          \n\
        user ${FTP_USERXCOM}          \n\
        prompt                       \n\
        ${pTipoTransf}               \n\
        cd ${pDirDest}               \n\
        put ${pFile} ${pFile}.ftp    \n\
        rename ${pFile}.ftp ${pFile} \n\
        put ${pFile}.FLG ${pFile}.FLG.ftp    \n\
        rename ${pFile}.FLG.ftp ${pFile}.FLG \n\
        bye                          \n\
       "

# echo "$vCmdFTP"
f_fhmsg "Transfiriendo ${pFile} al Servidor XCOM..."
echo "$vCmdFTP" | ftp -n > $vFileParFTP

# Verificacion del FTP
grep "226 Transfer complete." $vFileParFTP >/dev/null
vpValRet="$?"

if [ "$vpValRet" != "0" ]; then
   echo
   cat $vFileParFTP
   echo
   echo >> $vpFileLOG
   cat $vFileParFTP >> $vpFileLOG
   echo >> $vpFileLOG
   vpValRet="1"
   echo
   echo >> $vpFileLOG
   rm -f ${pFile}.FLG
   f_fhmsg "Archivo ${pFile} NO Transferido. Revisar e Informar."
else
   rm -f $vFileParFTP
   f_fhmsg "Archivo ${pFile} Transferido."
fi

}


################################################################################
## INICIO | PROCEDIMIENTO PRINCIPAL
################################################################################

echo

## Hora de Cierre Descripcion
################################################################################

vHCierre1=`ORAExec.sh "exec :rC:=PQPLIQ.gHRA_CIERRE1;" $DB`
vHCierre2=`ORAExec.sh "exec :rC:=PQPLIQ.gHRA_CIERRE2;" $DB`

vHCierre1=`echo $vHCierre1 | awk '{print substr($0,1,5)}'`
vHCierre2=`echo $vHCierre2 | awk '{print substr($0,1,5)}'`

## Archivo de Control
################################################################################

vFileCTL="$DIRDAT/SGCPCLR${pFecSes}.${pCodHCierre}.CTL"

# Lee Archivo de Control
f_admCTL R

## Codigo de Hora de Cierre

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

## Opcion de Reproceso

if [ "$pOpcRepro" = "S" ]; then
   vReproceso="SI"
else
   vReproceso="NO"
fi

## Ejecucion de Procesos
################################################################################

# Proceso de Clearing

if [ "$pOpcProc" = "CLR" ]; then

   if [ "$pOpcRepro" = "N" ]; then
      if [ "$vEstCLR" = "P" ]; then
         f_fhmsg "ERROR | Proceso en Ejecucion [Estado=$vEstCLR]." S N
         echo
         f_CtrlC
         exit 1;
      elif [ "$vEstCLR" = "F" ]; then
           f_fhmsg "ERROR | El Proceso de Clearing ya ha sido ejecutado [Estado=$vEstCLR]." S N
           echo
           f_CtrlC
           exit 1;
      elif [ "$vEstCLR" = "E" ]; then
           pOpcRepro="S"
      elif [ "$vEstCLR" != "0" ]; then
           f_fhmsg "ERROR | Estado de Proceso Desconocido [Estado=$vEstCLR]." S N
           echo
           f_CtrlC
           exit 1;
      fi

      if [ "$vEstPLIQ" = "P" ]; then
         f_fhmsg "ERROR | Proceso en Ejecucion [Estado=$vEstPLIQ]." S N
         echo
         f_CtrlC
         exit 1;
      elif [ "$vEstPLIQ" = "F" ]; then
           f_fhmsg "ERROR | La Interfaz PLIQ ya ha sido ejecutada [Estado=$vEstPLIQ]." S N
           echo
           f_CtrlC
           exit 1;
      elif [ "$vEstPLIQ" = "E" ]; then
           pOpcRepro="S"
           vReproceso="SI"
      elif [ "$vEstPLIQ" != "0" ]; then
           f_fhmsg "ERROR | Estado de Proceso Desconocido [Estado=$vEstCLR]." S N
           echo
           f_CtrlC
           exit 1;
      fi
   fi

   # Reproceso

   # Ejecucion del Proceso de Clearing

   dpDesc="Proceso Principal de Clearing"

   vpFileLOG="$DIRLOG/SGCPCLR${pFecSes}.${pCodHCierre}.LOG"

   vEstCLR="P"

   f_msgtit I

   vEstCLR="E"

   f_fhmsg "Procesando Informacion (Banco Provincial)..."
   oraexec "exec PQPCLR.pp_clearing_interfaz (TO_DATE('$pFecSes','YYYYMMDD'),'$pCodHCierre','BP');" $DB
   f_vrfvalret "$?" "Error al ejecutar PQPCLR.pp_clearing_interfaz. Avisar a Soporte."

   f_fhmsg "Procesando Informacion (Banco Mercantil)..."
   oraexec "exec PQPCLR.pp_clearing_interfaz (TO_DATE('$pFecSes','YYYYMMDD'),'$pCodHCierre','BM');" $DB
   f_vrfvalret "$?" "Error al ejecutar PQPCLR.pp_clearing_interfaz. Avisar a Soporte."

   f_fhmsg "Generando Informacion para Reportes (Banco Provincial)..."
   vRet=`ORAExec.sh "exec :rC:=PQPCLRRPT.F_CLR_GENDATRPT ('BP','$pCodHCierre',TO_DATE('$pFecSes','YYYYMMDD'));" $DB`
   f_vrfvalret "$?" "Error al Ejecutar PQPCLRRPT.F_CLR_GENDATRPT (ErrSQL=$?)"
   vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
   if [ "$vEst" = "E" ]; then
      vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
      f_finerr "$vRet"
   elif [ "$vEst" = "W" ]; then
        vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
        f_fhmsg "$vRet"
   fi

   f_fhmsg "Generando Informacion para Reportes (Banco Mercantil)..."
   vRet=`ORAExec.sh "exec :rC:=PQPCLRRPT.F_CLR_GENDATRPT ('BM','$pCodHCierre',TO_DATE('$pFecSes','YYYYMMDD'));" $DB`
   f_vrfvalret "$?" "Error al Ejecutar PQPCLRRPT.F_CLR_GENDATRPT (ErrSQL=$?)"
   vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
   if [ "$vEst" = "E" ]; then
      vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
      f_finerr "$vRet"
   elif [ "$vEst" = "W" ]; then
        vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
        f_fhmsg "$vRet"
   fi

   f_fhmsg "Generando Reporte de Cuadre (Banco Provincial)..."
   vRet=`ORAExec.sh "exec :rC:=PQPCLRRPT.F_CLR_RPTCUADRE ('BP','$pCodHCierre',TO_DATE('$pFecSes','YYYYMMDD'));" $DB`
   f_vrfvalret "$?" "Error al Ejecutar PQPCLRRPT.F_CLR_RPTCUADRE"
   vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
   if [ "$vEst" = "0" ]; then
      f_fhmsg "Resultado del Reporte: FINALIZADO CORRECTAMENTE"
   else
      if [ "$vEst" = "1" ]; then
         f_fhmsg "Resultado del Reporte: DESCUADRE EN CLEARING DEL BANCO PROVINCIAL"
         if [ -f "$DIROUT/CLRBP${pFecSes}${pCodHCierre}.RPT" ]; then
            cat $DIROUT/CLRBP${pFecSes}${pCodHCierre}.RPT
         else
            echo "Archivo de Reporte <CLRBP${pFecSes}${pCodHCierre}.RPT> NO ENCONTRADO."
         fi
         vRet=`echo "$vRet" | awk '{print substr($0,3)}'`
         vIDAlerta=`ORAExec.sh "exec :rN:=PQMONPROC.InsAlerta('Resultado del Reporte: DESCUADRE EN CLEARING DEL BANCO PROVINCIAL');" $DB`
         f_fhmsg "Alerta Registrada en el Sistema de Monitoreo (ID=${vIDAlerta})" N S
         f_finerr "$vRet"
      else
         vRet=`echo "$vRet" | awk '{print substr($0,3)}'`
         f_finerr "$vRet"
      fi
   fi

   f_fhmsg "Generando Reporte de Cuadre (Banco Mercantil)..."
   vRet=`ORAExec.sh "exec :rC:=PQPCLRRPT.F_CLR_RPTCUADRE ('BM','$pCodHCierre',TO_DATE('$pFecSes','YYYYMMDD'));" $DB`
   f_vrfvalret "$?" "Error al Ejecutar PQPCLRRPT.F_CLR_RPTCUADRE"
   vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
   if [ "$vEst" = "0" ]; then
      f_fhmsg "Resultado del Reporte: FINALIZADO CORRECTAMENTE"
   else
      if [ "$vEst" = "1" ]; then
         f_fhmsg "Resultado del Reporte: DESCUADRE EN CLEARING DEL BANCO MERCANTIL"
         if [ -f "$DIROUT/CLRBM${pFecSes}${pCodHCierre}.RPT" ]; then
            cat $DIROUT/CLRBM${pFecSes}${pCodHCierre}.RPT
         else
            echo "Archivo de Reporte <CLRBM${pFecSes}${pCodHCierre}.RPT> NO ENCONTRADO."
         fi
         vRet=`echo "$vRet" | awk '{print substr($0,3)}'`
         vIDAlerta=`ORAExec.sh "exec :rN:=PQMONPROC.InsAlerta('Resultado del Reporte: DESCUADRE EN CLEARING DEL BANCO MERCANTIL');" $DB`
         f_fhmsg "Alerta Registrada en el Sistema de Monitoreo (ID=${vIDAlerta})" N S
         f_finerr "$vRet"
      else
         vRet=`echo "$vRet" | awk '{print substr($0,3)}'`
         f_finerr "$vRet"
      fi
   fi

   f_fhmsg "Generando Archivos de Reportes (Banco Provincial)..."
   vRet=`ORAExec.sh "exec :rC:=PQPCLRRPT.F_COMP_GENFILERPT0204 ('BP','${pCodHCierre}',TO_DATE('${pFecSes}','YYYYMMDD'),'02');" $DB`
   f_vrfvalret "$?" "Error al Ejecutar PQPCLRRPT.F_COMP_GENFILERPT0204"
   vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
   if [ "$vEst" = "E" ]; then
      vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
      f_finerr "$vRet"
   elif [ "$vEst" = "W" ]; then
        vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
   fi
   #vRet=`ORAExec.sh "exec :rC:=PQPCLRRPT.F_COMP_GENFILERPT0204 ('BP','${pCodHCierre}',TO_DATE('${pFecSes}','YYYYMMDD'),'04');" $DB`
   #f_vrfvalret "$?" "Error al Ejecutar PQPCLRRPT.F_COMP_GENFILERPT0204"
   #vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
   #if [ "$vEst" = "E" ]; then
   #   vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
   #   f_finerr "$vRet"
   #elif [ "$vEst" = "W" ]; then
   #     vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
   #fi

   f_fhmsg "Generando Archivos de Reportes (Banco Mercantil)..."
   vRet=`ORAExec.sh "exec :rC:=PQPCLRRPT.F_COMP_GENFILERPT0204 ('BM','${pCodHCierre}',TO_DATE('${pFecSes}','YYYYMMDD'),'02');" $DB`
   f_vrfvalret "$?" "Error al Ejecutar PQPCLRRPT.F_COMP_GENFILERPT0204"
   vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
   if [ "$vEst" = "E" ]; then
      vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
      f_finerr "$vRet"
   elif [ "$vEst" = "W" ]; then
        vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
   fi
   #vRet=`ORAExec.sh "exec :rC:=PQPCLRRPT.F_COMP_GENFILERPT0204 ('BM','${pCodHCierre}',TO_DATE('${pFecSes}','YYYYMMDD'),'04');" $DB`
   #f_vrfvalret "$?" "Error al Ejecutar PQPCLRRPT.F_COMP_GENFILERPT0204"
   #vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
   #if [ "$vEst" = "E" ]; then
   #   vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
   #   f_finerr "$vRet"
   #elif [ "$vEst" = "W" ]; then
   #     vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
   #fi
   vEstCLR="F"
   ##echo "Cambio de estatus vEstCLR A FINALIZADO" #PRUEBAS IPR1302
   vEstPLIQ="P"
   ##echo "Cambio de estatus vEstPLIQ A PENDIENTE" #PRUEBAS IPR1302
   f_fhmsg "Generando Reporte de Cuadre de Interfaz PLIQ (Banco Provincial)..."
   vRet=`ORAExec.sh "exec :rC:=PQPCLRRPT.F_CLR_GENDATRPT_PCLM ('BP',TO_DATE('$pFecSes','YYYYMMDD'),'$pCodHCierre');" $DB`
   f_vrfvalret "$?" "Error al Ejecutar PQPCLRRPT.F_CLR_GENDATRPT_PCLM"
   vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
   if [ "$vEst" = "0" ]; then
      f_fhmsg "Resultado del Reporte: FINALIZADO CORRECTAMENTE"
   else
      if [ "$vEst" = "1" ]; then
         f_fhmsg "Resultado del Reporte: DESCUADRE EN LA INTERFAZ PLIQ DEL BANCO PROVINCIAL"
         #if [ -f "$DIROUT/PCLMBP${pFecSes}${pCodHCierre}.RPT" ]; then
         #   cat $DIROUT/PCLMBP${pFecSes}${pCodHCierre}.RPT
         #else
         #   echo "Archivo de Reporte <PCLMBP${pFecSes}${pCodHCierre}.RPT> NO ENCONTRADO."
         #fi
      else
         vRet=`echo "$vRet" | awk '{print substr($0,3)}'`
         # f_finerr "$vRet"
      fi
   fi

   f_fhmsg "Generando Reporte de Cuadre de Interfaz PLIQ (Banco Mercantil)..."
   vRet=`ORAExec.sh "exec :rC:=PQPCLRRPT.F_CLR_GENDATRPT_PCLM ('BM',TO_DATE('$pFecSes','YYYYMMDD'),'$pCodHCierre');" $DB`
   f_vrfvalret "$?" "Error al Ejecutar PQPCLRRPT.F_CLR_GENDATRPT_PCLM"
   vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
   if [ "$vEst" = "0" ]; then
      f_fhmsg "Resultado del Reporte: FINALIZADO CORRECTAMENTE"
   else
      if [ "$vEst" = "1" ]; then
         f_fhmsg "Resultado del Reporte: DESCUADRE EN LA INTERFAZ PLIQ DEL BANCO MERCANTIL"
         #if [ -f "$DIROUT/PCLMBM${pFecSes}${pCodHCierre}.RPT" ]; then
         #   cat $DIROUT/PCLMBM${pFecSes}${pCodHCierre}.RPT
         #else
         #   echo "Archivo de Reporte <PCLMBM${pFecSes}${pCodHCierre}.RPT> NO ENCONTRADO."
         #fi
      else
         vRet=`echo "$vRet" | awk '{print substr($0,3)}'`
         # f_finerr "$vRet"
      fi
   fi

   vEstPLIQ="F"
   ##echo "Cambio de estatus vEstPLIQ A FINALIZADO" #PRUEBAS IPR1302
   f_msgtit F

fi

# Interfaz PLIQ

if [ "$pOpcProc" = "PLIQ" ]; then

   if [ "$vEstCLR" != "F" ]; then
      f_fhmsg "ERROR | El Proceso de Clearing aun no ha finalizado [Estado=$vEstCLR]." S N
      echo
      f_CtrlC
      exit 1;
   fi

   if [ "$pOpcRepro" = "N" ]; then
      if [ "$vEstPLIQ" = "P" ]; then
         f_fhmsg "ERROR | Proceso en Ejecucion [Estado=$vEstPLIQ]." S N
         echo
         f_CtrlC
         exit 1;
      elif [ "$vEstPLIQ" = "F" ]; then
           f_fhmsg "ERROR | La Interfaz PLIQ ya ha sido ejecutada [Estado=$vEstPLIQ]." S N
           echo
           f_CtrlC
           exit 1;
      elif [ "$vEstPLIQ" = "E" ]; then
           pOpcRepro="S"
      elif [ "$vEstPLIQ" != "0" ]; then
           f_fhmsg "ERROR | Estado de Proceso Desconocido [Estado=$vEstCLR]." S N
           echo
           f_CtrlC
           exit 1;
      fi
   fi

   # Reproceso

   # Ejecucion de la Interfaz PLIQ

   dpDesc="Interfaz PLIQ"

   vpFileLOG="$DIRLOG/SGCPCLR${pOpcProc}${pFecSes}.${pCodHCierre}.LOG"

   vEstPLIQ="P"
   f_msgtit I

   vEstPLIQ="E"

   f_fhmsg "Procesando Informacion..."
   vRet=`ORAExec.sh "exec :rC:=PQPCLR.F_INTERFAZ_PLIQ(TO_DATE('$pFecSes','YYYYMMDD'),'$pCodHCierre','$pOpcRepro');" $DB`
   f_vrfvalret "$?" "Error al Ejecutar PQPCLR.F_INTERFAZ_PLIQ"
   vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
   if [ "$vEst" != "0" ]; then
      vRet=`echo "$vRet" | awk '{print substr($0,3)}'`
      f_finerr "$vRet"
   fi

   f_fhmsg "Generando Reporte de Cuadre de Interfaz PLIQ (Banco Provincial)..."
   vRet=`ORAExec.sh "exec :rC:=PQPCLRRPT.F_CLR_GENDATRPT_PCLM ('BP',TO_DATE('$pFecSes','YYYYMMDD'),'$pCodHCierre');" $DB`
   f_vrfvalret "$?" "Error al Ejecutar PQPCLRRPT.F_CLR_GENDATRPT_PCLM"
   vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
   if [ "$vEst" = "0" ]; then
      f_fhmsg "Resultado del Reporte: FINALIZADO CORRECTAMENTE"
   else
      if [ "$vEst" = "1" ]; then
         f_fhmsg "Resultado del Reporte: DESCUADRE EN LA INTERFAZ PLIQ DEL BANCO PROVINCIAL"
         if [ -f "$DIROUT/PCLMBP${pFecSes}${pCodHCierre}.RPT" ]; then
            cat $DIROUT/PCLMBP${pFecSes}${pCodHCierre}.RPT
         else
            echo "Archivo de Reporte <PCLMBP${pFecSes}${pCodHCierre}.RPT> NO ENCONTRADO."
         fi
      else
         vRet=`echo "$vRet" | awk '{print substr($0,3)}'`
         # f_finerr "$vRet"
      fi
   fi

   f_fhmsg "Generando Reporte de Cuadre de Interfaz PLIQ (Banco Mercantil)..."
   vRet=`ORAExec.sh "exec :rC:=PQPCLRRPT.F_CLR_GENDATRPT_PCLM ('BM',TO_DATE('$pFecSes','YYYYMMDD'),'$pCodHCierre');" $DB`
   f_vrfvalret "$?" "Error al Ejecutar PQPCLRRPT.F_CLR_GENDATRPT_PCLM"
   vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
   if [ "$vEst" = "0" ]; then
      f_fhmsg "Resultado del Reporte: FINALIZADO CORRECTAMENTE"
   else
      if [ "$vEst" = "1" ]; then
         f_fhmsg "Resultado del Reporte: DESCUADRE EN LA INTERFAZ PLIQ DEL BANCO MERCANTIL"
         if [ -f "$DIROUT/PCLMBM${pFecSes}${pCodHCierre}.RPT" ]; then
            cat $DIROUT/PCLMBM${pFecSes}${pCodHCierre}.RPT
         else
            echo "Archivo de Reporte <PCLMBM${pFecSes}${pCodHCierre}.RPT> NO ENCONTRADO."
         fi
      else
         vRet=`echo "$vRet" | awk '{print substr($0,3)}'`
         # f_finerr "$vRet"
      fi
   fi

   vEstPLIQ="F"
   f_msgtit F

fi

#
# f_Outgoing_mc () | funcion de proceso de Mastercard
################################################################################
f_Outgoing_mc ()
{
   # Ejecucion de Procesos
   vEstOUTMC="P"
   f_admCTL
   vEstOUTMC="E"

   f_fhmsg "Procesando Informacion de Outgoing..."
   vRet=`ORAExec.sh "exec :rC:=PQOUTGOINGMC.F_MAIN ('$pFecSes','${pCodHCierre}','${pOpcRepro}');" $DB`
   f_vrfvalret "$?" "Error al ejecutar PQOUTGOINGMC.F_MAIN. Avisar a Soporte."
   vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
   if [ "$vEst" = "0" ]; then
      vFileOUTMC=`echo "$vRet" | awk '{print substr($0,2,23)}'`
      f_fhmsg "Archivo Generado: ${vFileOUTMC}"
      SGCOUTMCconv.sh ${vFileOUTMC}
      vFileOUTMC=`echo "$vRet" | awk '{print substr($0,25,23)}'`
      if [ "${vFileOUTMC}" != "" ]; then
         f_fhmsg "Archivo Generado: ${vFileOUTMC}"
         SGCOUTMCconv.sh ${vFileOUTMC}
      fi
   elif [ "$vEst" = "W" ]; then
        vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
        f_fhmsg "$vRet"
   else
      vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
      f_finerr "$vRet"
   fi

   if [ $pCodHCierre = "1" ]; then
      f_fhmsg "Procesando Informacion de Retornos..."
      vRet=`ORAExec.sh "exec :rC:=PQOUTRETORNOMC.F_MAIN ('$pFecSes','${pCodHCierre}','${pOpcRepro}');" $DB`
      f_vrfvalret "$?" "Error al ejecutar PQOUTRETORNOMC.F_MAIN. Avisar a Soporte."
      vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
      if [ "$vEst" = "0" ]; then
         vFileOUTMC=`echo "$vRet" | awk '{print substr($0,2,23)}'`
         f_fhmsg "Archivo Generado: ${vFileOUTMC}"
         SGCOUTMCconv.sh ${vFileOUTMC}
         vFileOUTMC=`echo "$vRet" | awk '{print substr($0,25,23)}'`
         if [ "${vFileOUTMC}" != "" ]; then
            f_fhmsg "Archivo Generado: ${vFileOUTMC}"
            SGCOUTMCconv.sh ${vFileOUTMC}
         fi
      elif [ "$vEst" = "W" ]; then
           vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
           f_fhmsg "$vRet"
      else
         vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
         f_finerr "$vRet"
      fi
   fi

   vEstOUTMC="F"
   f_admCTL
   #####################################################################################
   ## f_Outgoing_mcng () | funcion de proceso de Mastercard NAIGUATA para evitar Omisi�n 
   ## Ejecucion de Procesos para salientes MC NAIGUATA  ---  IPR 1302 Fjvg 06/02/2020
   #####################################################################################
   ## f_Outgoing_mc
}
###################################################################################
## f_Outgoing_mcng () | funcion de proceso de Mastercard NAIGUATA
## Ejecucion de Procesos para salientes MC NAIGUATA  ---  IPR 1302 Fjvg 06/02/2020
###################################################################################
f_Outgoing_mcng ()
{
   vEstOUTMC_NGTA="P"
   f_admCTL
   vEstOUTMC_NGTA="E"

   f_fhmsg "Procesando Informacion de Outgoing NAIGUATA..."
   vRet=`ORAExec.sh "exec :rC:=PQOUTGOINGMC_NGTA.F_MAIN ('$pFecSes','${pCodHCierre}','${pOpcRepro}');" $DB`
   f_vrfvalret "$?" "Error al ejecutar PQOUTGOINGMC_NGTA.F_MAIN. Avisar a Soporte."
   vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
   if [ "$vEst" = "0" ]; then
      vFileOUTMC=`echo "$vRet" | awk '{print substr($0,2,28)}'`
      f_fhmsg "Archivo Generado: ${vFileOUTMC}"
      SGCOUTMCconv_ngta.sh ${vFileOUTMC}
      vFileOUTMC=`echo "$vRet" | awk '{print substr($0,25,28)}'`
      if [ "${vFileOUTMC}" != "" ]; then
         f_fhmsg "Archivo Generado: ${vFileOUTMC}"
         SGCOUTMCconv_ngta.sh ${vFileOUTMC}
      fi
   elif [ "$vEst" = "W" ]; then
        vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
        f_fhmsg "$vRet"
   else
      vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
      f_finerr "$vRet"
   fi

   if [ $pCodHCierre = "1" ]; then
      f_fhmsg "Procesando Informacion de Retornos..."
      vRet=`ORAExec.sh "exec :rC:=PQOUTRETORNOMC_NGTA.F_MAIN ('$pFecSes','${pCodHCierre}','${pOpcRepro}');" $DB`
      f_vrfvalret "$?" "Error al ejecutar PQOUTRETORNOMC.F_MAIN. Avisar a Soporte."
      vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
      if [ "$vEst" = "0" ]; then
         vFileOUTMC=`echo "$vRet" | awk '{print substr($0,2,28)}'`
         f_fhmsg "Archivo Generado: ${vFileOUTMC}"
         SGCOUTMCconv.sh ${vFileOUTMC}
         vFileOUTMC=`echo "$vRet" | awk '{print substr($0,25,28)}'`
         if [ "${vFileOUTMC}" != "" ]; then
            f_fhmsg "Archivo Generado: ${vFileOUTMC}"
            SGCOUTMCconv.sh ${vFileOUTMC}
         fi
      elif [ "$vEst" = "W" ]; then
           vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
           f_fhmsg "$vRet"
      else
         vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
         f_finerr "$vRet"
      fi
   fi

   vEstOUTMC_NGTA="F"
   f_admCTL
}

#
# f_Outgoing_visa () | funcion de proceso de Visa
################################################################################
f_Outgoing_visa ()
{
   # Ejecucion de Procesos
   vEstOUTVISA="P"
   f_admCTL
   vEstOUTVISA="E"

   f_fhmsg "Procesando Informacion de Outgoing (Banco Mercantil)..."
   oraexec "exec PQOUTGOINGVISA.P_OUTGOINGVISA ('$pFecSes','0105');" $DB
   f_vrfvalret "$?" "Error al ejecutar PQOUTGOINGVISA.P_OUTGOINGVISA. Avisar a Soporte."

   f_fhmsg "Procesando Informacion de Outgoing (Banco Provincial)..."
   oraexec "exec PQOUTGOINGVISA.P_OUTGOINGVISA ('$pFecSes','0108');" $DB
   f_vrfvalret "$?" "Error al ejecutar PQOUTGOINGVISA.P_OUTGOINGVISA. Avisar a Soporte."

   vEstOUTVISA="F"
   f_admCTL
   #####################################################################################
   ## f_Outgoing_visang () | funcion de proceso de VISA NAIGUATA para evitar Omisi�n 
   ## Ejecucion de Procesos para salientes VISA NAIGUATA  ---  IPR 1302 Fjvg 14/02/2020
   #####################################################################################
   ## f_Outgoing_visang
}
################################################################################
## f_Outgoing_visang () | funcion de proceso de Visa NAIGUATA
## Ejecucion de procesos NAIGUATA ---  IPR 1302 Fjvg 09/01/20202
################################################################################
f_Outgoing_visang ()
{
   
   vEstOUTVISA_NGTA="P"
   f_admCTL
   vEstOUTVISA_NGTA="E"

   f_fhmsg "Procesando Informacion de Outgoing Naiguata (Banco Mercantil)..."
   oraexec "exec PQOUTGOINGVISA.P_OUTGOINGVISA_NGTA ('$pFecSes','0105');" $DB
   f_vrfvalret "$?" "Error al ejecutar PQOUTGOINGVISA.P_OUTGOINGVISA_NGTA. Avisar a Soporte."

   f_fhmsg "Procesando Informacion de Outgoing Naiguata (Banco Provincial)..."
   oraexec "exec PQOUTGOINGVISA.P_OUTGOINGVISA_NGTA ('$pFecSes','0108');" $DB
   f_vrfvalret "$?" "Error al ejecutar PQOUTGOINGVISA.P_OUTGOINGVISA_NGTA. Avisar a Soporte."

   vEstOUTVISA_NGTA="F"
   f_admCTL
}

#
# f_Outgoing_price () | funcion de proceso de Price
################################################################################
f_Outgoing_price ()
{
   # Ejecucion de Procesos
   vEstOUTPRICE="P"
   f_admCTL
   vEstOUTPRICE="E"

   f_fhmsg "Procesando Informacion de Outgoing..."
   oraexec "exec PQOUTGOINGPRICE.P_OUTGOING_PRICE ('$pFecSes');" $DB
   f_vrfvalret "$?" "Error al ejecutar PQOUTGOINGPRICE.P_OUTGOING_PRICE. Avisar a Soporte."

   # Convertidor Price | BANCO MERCANTIL
   vFileOUTLE_TXT="LE0105${pFecSes}.TXT"
   vFileOUTLE_DAT="LE0105${pFecSes}.DAT"
   if [ -f "${DIROUT}/${vFileOUTLE_TXT}" ]; then
      f_fhmsg "Procesando Archivo PRICE (Banco Mercantil)..."
      #BitMapConv -b ${DIROUT}/${vFileOUTLE_TXT} ${DIROUT}/${vFileOUTLE_DAT}
      ${DIRBIN}/FileConverter.sh -u -p ${DIROUT}/${vFileOUTLE_TXT} ${DIROUT}/${vFileOUTLE_DAT} ${DIRDAT}/price-read.xml ${DIRDAT}/price-write.xml
      vRet="$?"
      if [ "$vRet" = "0" ]; then
         # Transferencia de Archivos Lote Emisor
         f_ftp ${DIROUT} bm_filein ${vFileOUTLE_TXT}
         f_ftp ${DIROUT} bm_filein ${vFileOUTLE_DAT} B
         # Generacion OK
         vRet=`wc -l ${DIROUT}/${vFileOUTLE_TXT}`
         vContReg=`echo "$vRet" | awk '{pos=index($0,"/");if ( pos == 0 ) pos=length($0);print substr($0,1,pos-2);}'`
         f_fhmsg "Archivo Generado: ${vFileOUTLE_DAT} | Registros: ${vContReg}"
      else
         vIDAlerta=`ORAExec.sh "exec :rN:=PQMONPROC.InsAlerta('Error en el Outgoing Price. No se pudo convertir el archivo ${vFileOUTLE_TXT}.');" $DB`
         f_fhmsg "Alerta Registrada en el Sistema de Monitoreo (ID=${vIDAlerta})" N S
         f_finerr "ERROR: No se pudo convertir el archivo ${vFileOUTLE_TXT}. Informar a Soporte."
      fi
   else
      vIDAlerta=`ORAExec.sh "exec :rN:=PQMONPROC.InsAlerta('Error en el Outgoing Price. No se ha generado el archivo ${vFileOUTLE_TXT}.');" $DB`
      f_fhmsg "Alerta Registrada en el Sistema de Monitoreo (ID=${vIDAlerta})" N S
      f_finerr "ERROR: No se ha generado el archivo ${vFileOUTLE_TXT}. Informar a Soporte."
   fi

   # Convertidor Price | BANCO PROVINCIAL
   vFileOUTLE_TXT="LE0108${pFecSes}.TXT"
   vFileOUTLE_DAT="LE0108${pFecSes}.DAT"
   if [ -f "${DIROUT}/${vFileOUTLE_TXT}" ]; then
      f_fhmsg "Procesando Archivo PRICE (Banco Provincial)..."
      #BitMapConv -b ${DIROUT}/${vFileOUTLE_TXT} ${DIROUT}/${vFileOUTLE_DAT}
      ${DIRBIN}/FileConverter.sh -u -p ${DIROUT}/${vFileOUTLE_TXT} ${DIROUT}/${vFileOUTLE_DAT} ${DIRDAT}/price-read.xml ${DIRDAT}/price-write.xml
      vRet="$?"
      if [ "$vRet" = "0" ]; then
         # Transferencia de Archivos Lote Emisor
         f_ftp ${DIROUT} bp_filein ${vFileOUTLE_TXT}
         f_ftp ${DIROUT} bp_filein ${vFileOUTLE_DAT} B
         # Generacion OK
         vRet=`wc -l ${DIROUT}/${vFileOUTLE_TXT}`
         vContReg=`echo "$vRet" | awk '{pos=index($0,"/");if ( pos == 0 ) pos=length($0);print substr($0,1,pos-2);}'`
         f_fhmsg "Archivo Generado: ${vFileOUTLE_DAT} | Registros: ${vContReg}"
      else
         vIDAlerta=`ORAExec.sh "exec :rN:=PQMONPROC.InsAlerta('Error en el Outgoing Price. No se pudo convertir el archivo ${vFileOUTLE_TXT}.');" $DB`
         f_fhmsg "Alerta Registrada en el Sistema de Monitoreo (ID=${vIDAlerta})" N S
         f_finerr "ERROR: No se pudo convertir el archivo ${vFileOUTLE_TXT}. Informar a Soporte."
      fi
   else
      vIDAlerta=`ORAExec.sh "exec :rN:=PQMONPROC.InsAlerta('Error en el Outgoing Price. No se ha generado el archivo ${vFileOUTLE_TXT}.');" $DB`
      f_fhmsg "Alerta Registrada en el Sistema de Monitoreo (ID=${vIDAlerta})" N S
      f_finerr "ERROR: No se ha generado el archivo ${vFileOUTLE_TXT}. Informar a Soporte."
   fi

   vEstOUTPRICE="F"
   f_admCTL
}

# Proceso de Outgoing de MasterCard

if [ "$pOpcProc" = "OUTMC" ]; then

   if [ "$vEstCLR" != "F" ]; then
      f_fhmsg "ERROR | El Proceso de Clearing aun no ha finalizado [Estado=$vEstCLR]." S N
      echo
      f_CtrlC
      exit 1;
   fi

   if [ "$pOpcRepro" = "N" ]; then
      if [ "$vEstOUTMC" = "P" ]; then
         f_fhmsg "ERROR | Proceso en Ejecucion [Estado=$vEstOUTMC]." S N
         echo
         f_CtrlC
         exit 1;
      elif [ "$vEstOUTMC" = "F" ]; then
           f_fhmsg "ERROR | El Proceso de Outgoing MC ya ha sido ejecutado [Estado=$vEstOUTMC]." S N
           echo
           f_CtrlC
           exit 1;
      elif [ "$vEstOUTMC" = "E" ]; then
           pOpcRepro="S"
           vReproceso="SI"
      elif [ "$vEstOUTMC" != "0" ]; then
           f_fhmsg "ERROR | Estado de Proceso Desconocido [Estado=$vEstOUTMC]." S N
           echo
           f_CtrlC
           exit 1;
      fi
   fi

   # Parametros

   dpDesc="Proceso de Outgoing de MasterCard"

   vpFileLOG="$DIRLOG/SGCPCLR${pOpcProc}${pFecSes}.${pCodHCierre}.LOG"

   vEstOUTMC="P"

   # Informe de Archivos a utilizar

   f_msgtit I
   f_msg "                 Reproceso : ${vReproceso}"
   f_fechora ${pFecSes}
   f_msg "           Fecha de Sesion : ${vpValRet}"
   f_msg "            Hora de Cierre : ${vHCierre} hrs."
   f_msg
   f_msg "        Archivo de Control : `basename ${vFileCTL}`"
   f_msg "                Directorio : `dirname ${vFileCTL}`"
   f_msg "   Archivo LOG del Proceso : `basename ${vpFileLOG}`"
   f_msg "                Directorio : `dirname ${vpFileLOG}`"
   f_msg

   # Ejecucion del Proceso
   f_Outgoing_mc

   # Fin de Proceso
   f_msgtit F
fi
###########################################################
## Proceso de Outgoing de MasterCard NAIGUATA IPR 1302 FJVG
###########################################################
if [ "$pOpcProc" = "OUTMCNG" ]; then

   if [ "$vEstCLR" != "F" ]; then
      f_fhmsg "ERROR | El Proceso de Clearing aun no ha finalizado [Estado=$vEstCLR]." S N
      echo
      f_CtrlC
      exit 1;
   fi

   if [ "$pOpcRepro" = "N" ]; then
      if [ "$vEstOUTMC_NGTA" = "P" ]; then
         f_fhmsg "ERROR | Proceso en Ejecucion [Estado=$vEstOUTMC_NGTA]." S N
         echo
         f_CtrlC
         exit 1;
      elif [ "$vEstOUTMC_NGTA" = "F" ]; then
           f_fhmsg "ERROR | El Proceso de Outgoing MC Naiguata ya ha sido ejecutado [Estado=$vEstOUTMC_NGTA]." S N
           echo
           f_CtrlC
           exit 1;
      elif [ "$vEstOUTMC_NGTA" = "E" ]; then
           pOpcRepro="S"
           vReproceso="SI"
      elif [ "$vEstOUTMC_NGTA" != "0" ]; then
           f_fhmsg "ERROR | Estado de Proceso Desconocido [Estado=$vEstOUTMC_NGTA]." S N
           echo
           f_CtrlC
           exit 1;
      fi
   fi

   # Parametros

   dpDesc="Proceso de Outgoing de MasterCard Naiguata"

   vpFileLOG="$DIRLOG/SGCPCLR${pOpcProc}${pFecSes}.${pCodHCierre}.LOG"

   vEstOUTMC_NGTA="P"

   # Informe de Archivos a utilizar

   f_msgtit I
   f_msg "                 Reproceso : ${vReproceso}"
   f_fechora ${pFecSes}
   f_msg "           Fecha de Sesion : ${vpValRet}"
   f_msg "            Hora de Cierre : ${vHCierre} hrs."
   f_msg
   f_msg "        Archivo de Control : `basename ${vFileCTL}`"
   f_msg "                Directorio : `dirname ${vFileCTL}`"
   f_msg "   Archivo LOG del Proceso : `basename ${vpFileLOG}`"
   f_msg "                Directorio : `dirname ${vpFileLOG}`"
   f_msg

   # Ejecucion del Proceso
   f_Outgoing_mcng

   # Fin de Proceso
   f_msgtit F
fi

# Proceso de Outgoing de VISA

if [ "$pOpcProc" = "OUTVISA" ]; then

   if [ $pCodHCierre = "1" ]; then
      f_fhmsg "ERROR | El Proceso de Outgoing de Visa, se ejecuta solo en el cierre 2. AQUI ESTOY INGRESANDO CON EL CAMBIO" S N
      echo
      f_CtrlC
      exit 1;
   fi

   if [ "$vEstCLR" != "F" ]; then
      f_fhmsg "ERROR | El Proceso de Clearing aun no ha finalizado [Estado=$vEstCLR]." S N
      echo
      f_CtrlC
      exit 1;
   fi

   if [ "$pOpcRepro" = "N" ]; then
      if [ "$vEstOUTVISA" = "P" ]; then
         f_fhmsg "ERROR | Proceso en Ejecucion [Estado=$vEstOUTVISA]." S N
         echo
         f_CtrlC
         exit 1;
      elif [ "$vEstOUTVISA" = "F" ]; then
           f_fhmsg "ERROR | El Proceso de Outgoing de Visa ya ha sido ejecutado [Estado=$vEstOUTVISA]." S N
           echo
           f_CtrlC
           exit 1;
      elif [ "$vEstOUTVISA" = "E" ]; then
           pOpcRepro="S"
           vReproceso="SI"
      elif [ "$vEstOUTVISA" != "0" ]; then
           f_fhmsg "ERROR | Estado de Proceso Desconocido [Estado=$vEstOUTVISA]." S N
           echo
           f_CtrlC
           exit 1;
      fi
   fi

   # Parametros

   dpDesc="Proceso de Outgoing de Visa"

   vpFileLOG="$DIRLOG/SGCPCLR${pOpcProc}${pFecSes}.${pCodHCierre}.LOG"

   vEstOUTVISA="P"

   # Informe de Archivos a utilizar

   f_msgtit I
   f_msg "                 Reproceso : ${vReproceso}"
   f_fechora ${pFecSes}
   f_msg "           Fecha de Sesion : ${vpValRet}"
   f_msg "            Hora de Cierre : ${vHCierre} hrs."
   f_msg
   f_msg "        Archivo de Control : `basename ${vFileCTL}`"
   f_msg "                Directorio : `dirname ${vFileCTL}`"
   f_msg "   Archivo LOG del Proceso : `basename ${vpFileLOG}`"
   f_msg "                Directorio : `dirname ${vpFileLOG}`"
   f_msg

   # Ejecucion del Proceso
   f_Outgoing_visa

   # Fin de Proceso
   f_msgtit F
fi

###########################################################
## Proceso de Outgoing de VISA NAIGUATA IPR 1302 FJVG
###########################################################
if [ "$pOpcProc" = "OUTVISANG" ]; then

   if [ $pCodHCierre = "1" ]; then
      f_fhmsg "ERROR | El Proceso de Outgoing de Visa NAIGUATA, se ejecuta solo en el cierre 2. AQUI ESTOY INGRESANDO CON EL CAMBIO" S N
      echo
      f_CtrlC
      exit 1;
   fi

   if [ "$vEstCLR" != "F" ]; then
      f_fhmsg "ERROR | El Proceso de Clearing aun no ha finalizado [Estado=$vEstCLR]." S N
      echo
      f_CtrlC
      exit 1;
   fi

   if [ "$pOpcRepro" = "N" ]; then
      if [ "$vEstOUTVISA_NGTA" = "P" ]; then
         f_fhmsg "ERROR | Proceso en Ejecucion [Estado=$vEstOUTVISA]." S N
         echo
         f_CtrlC
         exit 1;
      elif [ "$vEstOUTVISA_NGTA" = "F" ]; then
           f_fhmsg "ERROR | El Proceso de Outgoing de Visa NAIGUATA ya ha sido ejecutado [Estado=$vEstOUTVISA]." S N
           echo
           f_CtrlC
           exit 1;
      elif [ "$vEstOUTVISA_NGTA" = "E" ]; then
           pOpcRepro="S"
           vReproceso="SI"
      elif [ "$vEstOUTVISA_NGTA" != "0" ]; then
           f_fhmsg "ERROR | Estado de Proceso Desconocido [Estado=$vEstOUTVISA_NGTA]." S N
           echo
           f_CtrlC
           exit 1;
      fi
   fi

   # Parametros

   dpDesc="Proceso de Outgoing de Visa NAIGUATA"

   vpFileLOG="$DIRLOG/SGCPCLR${pOpcProc}${pFecSes}.${pCodHCierre}.LOG"

   vEstOUTVISA_NGTA="P"

   # Informe de Archivos a utilizar

   f_msgtit I
   f_msg "                 Reproceso : ${vReproceso}"
   f_fechora ${pFecSes}
   f_msg "           Fecha de Sesion : ${vpValRet}"
   f_msg "            Hora de Cierre : ${vHCierre} hrs."
   f_msg
   f_msg "        Archivo de Control : `basename ${vFileCTL}`"
   f_msg "                Directorio : `dirname ${vFileCTL}`"
   f_msg "   Archivo LOG del Proceso : `basename ${vpFileLOG}`"
   f_msg "                Directorio : `dirname ${vpFileLOG}`"
   f_msg

   # Ejecucion del Proceso
   f_Outgoing_visang

   # Fin de Proceso
   f_msgtit F
fi
# Proceso de Outgoing de PRICE

if [ "$pOpcProc" = "OUTPRICE" ]; then

   if [ $pCodHCierre = "1" ]; then
      f_fhmsg "ERROR | El Proceso de Outgoing de Price, se ejecuta solo en el cierre 2." S N
      echo
      f_CtrlC
      exit 1;
   fi

   if [ "$vEstCLR" != "F" ]; then
      f_fhmsg "ERROR | El Proceso de Clearing aun no ha finalizado [Estado=$vEstCLR]." S N
      echo
      f_CtrlC
      exit 1;
   fi

   if [ "$pOpcRepro" = "N" ]; then
      if [ "$vEstOUTPRICE" = "P" ]; then
         f_fhmsg "ERROR | Proceso en Ejecucion [Estado=$vEstOUTPRICE]." S N
         echo
         f_CtrlC
         exit 1;
      elif [ "$vEstOUTPRICE" = "F" ]; then
           f_fhmsg "ERROR | El Proceso de Outgoing de Price ya ha sido ejecutado [Estado=$vEstOUTPRICE]." S N
           echo
           f_CtrlC
           exit 1;
      elif [ "$vEstOUTPRICE" = "E" ]; then
           pOpcRepro="S"
           vReproceso="SI"
      elif [ "$vEstOUTPRICE" != "0" ]; then
           f_fhmsg "ERROR | Estado de Proceso Desconocido [Estado=$vEstOUTPRICE]." S N
           echo
           f_CtrlC
           exit 1;
      fi
   fi

   # Parametros

   dpDesc="Proceso de Outgoing de Price"

   vpFileLOG="$DIRLOG/SGCPCLR${pOpcProc}${pFecSes}.${pCodHCierre}.LOG"

   vEstOUTPRICE="P"

   ## Informe de Archivos a utilizar

   f_msgtit I
   f_msg "                 Reproceso : ${vReproceso}"
   f_fechora ${pFecSes}
   f_msg "           Fecha de Sesion : ${vpValRet}"
   f_msg "            Hora de Cierre : ${vHCierre} hrs."
   f_msg
   f_msg "        Archivo de Control : `basename ${vFileCTL}`"
   f_msg "                Directorio : `dirname ${vFileCTL}`"
   f_msg "   Archivo LOG del Proceso : `basename ${vpFileLOG}`"
   f_msg "                Directorio : `dirname ${vpFileLOG}`"
   f_msg

   # Ejecucion del Proceso
   f_Outgoing_price

   # Fin de Proceso
   f_msgtit F
fi


# Proceso de Outgoing de Todos

if [ "$pOpcProc" = "OUTALL" ]; then

   if [ "$vEstCLR" != "F" ]; then
      f_fhmsg "ERROR | El Proceso de Clearing aun no ha finalizado [Estado=$vEstCLR]." S N
      echo
      f_CtrlC
      exit 1;
   fi

   if [ "$pOpcRepro" = "N" ]; then
      if [ "$vEstOUTVISA" = "P" ] || [ "$vEstOUTMC" = "P" ] || [ "$vEstOUTPRICE" = "P" ]; then
         f_fhmsg "ERROR | Proceso en Ejecucion [Visa=$vEstOUTVISA,Mastercard=$vEstOUTMC,Price=$vEstOUTPRICE]." S N
         echo
         f_CtrlC
         exit 1;
      elif [ "$vEstOUTVISA" = "F" ] || [ "$vEstOUTMC" = "F" ] || [ "$vEstOUTPRICE" = "F" ]; then
           f_fhmsg "ERROR | El Proceso de Outgoing ya ha sido ejecutado [Visa=$vEstOUTVISA,Mastercard=$vEstOUTMC,Price=$vEstOUTPRICE]." S N
           echo
           f_CtrlC
           exit 1;
      elif [ "$vEstOUTVISA" = "E" ] || [ "$vEstOUTMC" = "E" ] || [ "$vEstOUTPRICE" = "E" ]; then
           pOpcRepro="S"
           vReproceso="SI"
      elif [ "$vEstOUTVISA" != "0" ] || [ "$vEstOUTMC" != "0" ] || [ "$vEstOUTPRICE" != "0" ]; then
           f_fhmsg "ERROR | Estado de Proceso Desconocido [Visa=$vEstOUTVISA,Mastercard=$vEstOUTMC,Price=$vEstOUTPRICE]." S N
           echo
           f_CtrlC
           exit 1;
      fi
   fi

   # Parametros

   dpDesc="Proceso de Outgoing"

   vpFileLOG="$DIRLOG/SGCPCLR${pOpcProc}${pFecSes}.${pCodHCierre}.LOG"

   ## Informe de Archivos a utilizar

   f_msgtit I
   f_msg "                 Reproceso : ${vReproceso}"
   f_fechora ${pFecSes}
   f_msg "           Fecha de Sesion : ${vpValRet}"
   f_msg "            Hora de Cierre : ${vHCierre} hrs."
   f_msg
   f_msg "        Archivo de Control : `basename ${vFileCTL}`"
   f_msg "                Directorio : `dirname ${vFileCTL}`"
   f_msg "   Archivo LOG del Proceso : `basename ${vpFileLOG}`"
   f_msg "                Directorio : `dirname ${vpFileLOG}`"
   f_msg

   # Ejecucion del Proceso
   f_fhmsg "Procesando Outgoing VISA"
   echo
   f_Outgoing_visa
   echo

   f_fhmsg "Procesando Outgoing PRICE"
   echo
   f_Outgoing_price
   echo

   f_fhmsg "Procesando Outgoing MASTERCARD"
   echo
   f_Outgoing_mc
   echo

   # Fin de Proceso
   f_msgtit F
fi


# Cuadre del Proceso de Clearing

# if [ "$pOpcProc" = "REP" ]; then
#
#    if [ "$vEstCLR" != "F" ]; then
#       f_fhmsg "ERROR | El Proceso de Clearing aun no ha finalizado [Estado=$vEstCLR]." S N
#       echo
#       f_CtrlC
#       exit 1;
#    fi
#
#    # Ejecucion del Reporte de Cuadre del Clearing
#
#    dpDesc="Clearing | Reporte de Cuadre de Clearing"
#
#    vpFileLOG="$DIRLOG/SGCPCLR${pOpcProc}${pFecSes}.${pCodHCierre}.LOG"
#
#    f_msgtit I
#
#    f_fhmsg "Procesando Informacion (Banco Provincial)..."
#    oraexec "exec SP_CLR_RPTCUADRE ('BP','$pCodHCierre',TO_DATE('$pFecSes','YYYYMMDD'));" $DB
#    f_vrfvalret "$?" "Error al ejecutar SP_CLR_RPTCUADRE. Avisar a Soporte."
#    f_fhmsg "Procesando Informacion (Banco Mercantil)..."
#    oraexec "exec SP_CLR_RPTCUADRE ('BM','$pCodHCierre',TO_DATE('$pFecSes','YYYYMMDD'));" $DB
#    f_vrfvalret "$?" "Error al ejecutar SP_CLR_RPTCUADRE. Avisar a Soporte."
#
#    f_msgtit F
#
# fi
