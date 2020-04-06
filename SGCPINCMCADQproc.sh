#!/bin/ksh

################################################################################
##
##  Nombre del Programa : SGCPINCMCADQproc.sh
##                Autor : SSM
##       Codigo Inicial : 14/01/2008
##          Descripcion : Proceso de Carga Inicial de Incoming de MasterCard
##
##  ======================== Registro de Modificaciones ========================
##
##  Fecha      Autor Version Descripcion de la Modificacion
##  ---------- ----- ------- ---------------------------------------------------
##  14/01/2008 SSM   1.00    Codigo Inicial
##  26/05/2008 JMG   2.00    Proceso Incoming Maestro Agregado
##  03/02/2020 FJV   3.00    Proceso Incoming Maestro Naiguata
##
################################################################################

################################################################################
## DECLARACION DE DATOS, PARAMETROS DE EJECUCION Y VARIABLES DEL PROGRAMA
################################################################################


## Datos del Programa
################################################################################

dpNom="SGCPINCMCADQproc"      # Nombre del Programa
dpDesc=""                     # Descripcion del Programa
dpVer=3.00                    # Ultima Version del Programa
dpFec="20200203"              # Fecha de Ultima Actualizacion [Formato:AAAAMMDD]


## Variables del Programa
################################################################################

vpValRet=""                   # Valor de Retorno (funciones)
vpFH=`date '+%Y%m%d%H%M%S'`   # Fecha y Hora [Formato:AAAAMMDDHHMMSS]
vpFileLOG=""                  # Nombre del Archivo LOG del Programa


## Parametros de Ejecucion
################################################################################

pEntAdq="$1"                  # Entidad Adquirente [BM/BP]
pFecProc="$2"                 # Fecha de Proceso
pCodProc="$3"                 # Codigo de Proceso

if [ "${pCodProc}" = "BINESD" ] || [ "${pCodProc}" = "BINESE" ] || [ "${pCodProc}" = "TC" ]; then
   pNumSec="$4"               # Numero de Secuencia (solo para BINESD,BINESE y TC)
   pOpcRepro="$5"             # Opcion de Reproceso
   pFlgBG="$6"                # Flag de Ejecucion en Background
else
   pOpcRepro="$4"             # Opcion de Reproceso
   pFlgBG="$5"                # Flag de Ejecucion en Background
fi


## Variables de Trabajo
################################################################################

vFileCTL=""                   # Archivo de Control
vEstProc=""                   # Estado del Proceso (P=Pendiente/X=En Ejecucion/
                              #                     E=Fin ERROR/F=Fin OK)
vSubProc=""                   # Codigo de SubProceso

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
if [ "${dpDesc}" = "" ]; then
   vMsg="${dpNom}"
else
   vMsg="${dpDesc}"
fi
if [ "${pTipo}" = "I" ]; then
   vMsg="INICIO | ${vMsg}"
elif [ "${pTipo}" = "R" ]; then
     vMsg="REPROCESO | ${vMsg}"
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
f_msg "${vMsg}" S

if [ "${pTipo}" = "E" ]; then
   if [ "$pFlgBG" = "S" ]; then
      echo " --> PRESIONE [CTRL+C] PARA REGRESAR"
      echo
   fi
   exit 1;
elif [ "${pTipo}" = "F" ]; then
   if [ "$pFlgBG" = "S" ]; then
      echo " --> PRESIONE [CTRL+C] PARA REGRESAR"
      echo
   fi
   exit 0;
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

Parametro 1 (obligatorio) : Entidad Adquirente [BM/BP]
Parametro 2 (obligatorio) : Codigo de Proceso

Si el Codigo de Proceso es ...

--------------------------------------------------------------------------------
Programa: ${dpNom} | Version: ${dpVer} | Modificacion: ${vpValRet}
" | more
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
exit 1
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
  # [01-02] Codigo de Entidad Adquirente
  # [04-11] Fecha de Proceso
  # [13-13] Estado del Proceso (P=Pendiente/X=En Ejecucion/E=Fin ERROR/F=Fin OK)
  # [15-16] Codigo del Sub-Proceso
  # [20-33] Fecha y Hora de Actualizacion de los Estados [AAAAMMDDHHMMSS]

  pOpcion="$1"

  if [ "$pOpcion" = "R" ]; then
     if ! [ -f "$vFileCTL" ]; then
        # Crea el Archivo CTL
        vEstProc="P"
        vSubProc="00"
        echo "${pEntAdq}|${pFecProc}|${vEstProc}|${vSubProc}|`date '+%Y%m%d%H%M%S'`" > $vFileCTL
     else
        vEstProc=`awk '{print substr($0,13,1)}' $vFileCTL`
     fi
  else
     echo "${pEntAdq}|${pFecProc}|${vEstProc}|${vSubProc}|`date '+%Y%m%d%H%M%S'`" > $vFileCTL
  fi

}


################################################################################
## INICIO | PROCEDIMIENTO PRINCIPAL
################################################################################

echo

## Validacion de Parametros
################################################################################

# Menu de parametros
if [ $# -eq 0 ]; then
   f_parametros;
   exit 0;
fi

## Entidad Adquirente
################################################################################

if [ "${pEntAdq}" = "BM" ]; then
   vEntAdq="Banco Mercantil"
elif [ "${pEntAdq}" = "BP" ]; then
     vEntAdq="Banco Provincial"
else
     f_msg "Codigo de Entidad Adquirente Incorrecto."
     f_parametros;
     exit 1;
fi


## Fecha de Proceso
################################################################################

if [ "${pFecProc}" = "" ]; then
   f_msg "Fecha de Proceso No Especificada."
   f_parametros;
   exit 1;
fi

## Codigo de Proceso
################################################################################

if [ "${pCodProc}" = "BINESD" ]; then
   vCodProc="Carga de Bines (DIARIO)"
elif [ "${pCodProc}" = "BINESE" ]; then
     vCodProc="Carga de Bines (EVENTUAL)"
elif [ "${pCodProc}" = "TC" ]; then
     vCodProc="Carga de Tipo de Cambio"
elif [ "${pCodProc}" = "INCOMINGMC" ]; then
     vCodProc="Carga de Incoming"
elif [ "${pCodProc}" = "INCRET" ]; then
     vCodProc="Carga de Incoming de Retornos"
elif [ "${pCodProc}" = "INCMATCH" ]; then
     vCodProc="Carga de Incoming MATCH"
elif [ "${pCodProc}" = "INCMAESTRO" ]; then
     vCodProc="Carga de Incoming MAESTRO"
elif [ "${pCodProc}" = "INCMAESTRONGTA" ]; then
     vCodProc="Carga de Incoming Naiguata MAESTRO"
else
     f_msg "Codigo de Proceso Incorrecto."
     f_parametros;
     exit 1;
fi


## Numero de Secuencia
if [ "${pNumSec}" = "" ]; then
   pNumSec="01"
else
   pNumSec=`printf "%02d" ${pNumSec}`
fi


## Opcion de Reproceso
################################################################################

if [ "${pOpcRepro}" = "" ]; then
   pOpcRepro="N"
fi

## Descripcion del Programa
################################################################################
if [ "${pCodProc}" = "INCMAESTRONGTA" ]; then
   dpDesc="Carga de Incoming de Naiguata MasterCard (${vEntAdq}:${pCodProc})"
else
   dpDesc="Carga de Incoming de MasterCard (${vEntAdq}:${pCodProc})"
fi


## Archivo LOG
################################################################################
vpFileLOG="${DIRLOG}/SGCPINCMC${pEntAdq}.${pCodProc}.${pFecProc}.LOG"
echo > $vpFileLOG


## Archivo CTL
################################################################################
vFileCTL="${DIRDAT}/SGCPINCMC${pEntAdq}.${pCodProc}.${pFecProc}.CTL"
f_admCTL R


################################################################################
## INICIO | PROCEDIMIENTO PRINCIPAL
################################################################################


# Verifica el Estado en el Archivo de Control

if [ "${pOpcRepro}" = "S" ]; then
   f_msgtit R
else
   if [ "${vEstProc}" = "X" ]; then
      f_fhmsg "ERROR: El proceso se encuentra aun en ejecucion (Estado=${vEstProc})."
      echo
      if [ "$pFlgBG" = "S" ]; then
         echo " --> PRESIONE [CTRL+C] PARA REGRESAR"
         echo
      fi
      exit 1;
   elif [ "${vEstProc}" = "F" ]; then
        f_fhmsg "ERROR: El proceso ya ha sido ejecutado (Estado=${vEstProc})."
        echo
        if [ "$pFlgBG" = "S" ]; then
           echo " --> PRESIONE [CTRL+C] PARA REGRESAR"
           echo
        fi
        exit 1;
   elif [ "${vEstProc}" = "E" ]; then
        f_fhmsg "ADVERTENCIA: El proceso anterior termino con error (Estado=${vEstProc})"
        f_fhmsg "             REPROCESO AUTOMATICO ACTIVADO." N S
        pOpcRepro="S"
        f_msgtit R
   elif [ "${vEstProc}" = "P" ]; then
        f_msgtit I
   fi
fi


# CARGA DE BINES (DIARIO)

vEstProc="X"
f_admCTL W

if [ "${pCodProc}" = "BINESD" ]; then

   # CARGABINES
   vSubProc="01"
   f_admCTL W
   SGCPINCMCADQ.sh CARGABINES D ${pEntAdq} ${pFecProc} ${pNumSec} ${pOpcRepro}
   vRet="$?"
   if [ "${vRet}" != "0" ]; then
      vEstProc="E"
      f_admCTL W
      f_finerr
   fi

   # FILTRABINES
   vSubProc="02"
   f_admCTL W
   SGCPINCMCADQ.sh FILTRABINES D ${pEntAdq} ${pFecProc} ${pNumSec} ${pOpcRepro}
   vRet="$?"
   if [ "${vRet}" != "0" ]; then
      vEstProc="E"
      f_admCTL W
      f_finerr
   fi

   # FTPIP0040T1
   vSubProc="03"
   f_admCTL W
   SGCPINCMCADQ.sh FTPIP0040T1 IP0040T1.DAT
   vRet="$?"
   if [ "${vRet}" != "0" ]; then
      vEstProc="E"
      f_admCTL W
      f_finerr
   fi

   # CONVMFOCUS
   vSubProc="04"
   f_admCTL W
   SGCPINCMCADQ.sh CONVMFOCUS D ${pEntAdq} ${pFecProc} ${pNumSec}
   vRet="$?"
   if [ "${vRet}" != "0" ]; then
      vEstProc="E"
      f_admCTL W
      f_finerr
   fi

   # FTPT067
   vSubProc="05"
   f_admCTL W
   SGCPINCMCADQ.sh FTPT067 D ${pEntAdq} ${pFecProc} ${pNumSec}
   vRet="$?"
   if [ "${vRet}" != "0" ]; then
      vEstProc="E"
      f_admCTL W
      f_finerr
   fi

fi # BINES (DIARIO)


# CARGA DE BINES (EVENTUAL)

vEstProc="X"
f_admCTL W

if [ "${pCodProc}" = "BINESE" ]; then

   # CARGABINES
   vSubProc="01"
   f_admCTL W
   SGCPINCMCADQ.sh CARGABINES E ${pEntAdq} ${pFecProc} ${pNumSec} ${pOpcRepro}
   vRet="$?"
   if [ "${vRet}" != "0" ]; then
      vEstProc="E"
      f_admCTL W
      f_finerr
   fi

   # FILTRABINES
   vSubProc="02"
   f_admCTL W
   SGCPINCMCADQ.sh FILTRABINES E ${pEntAdq} ${pFecProc} ${pNumSec} ${pOpcRepro}
   vRet="$?"
   if [ "${vRet}" != "0" ]; then
      vEstProc="E"
      f_admCTL W
      f_finerr
   fi

   # FTPIP0040T1
   vSubProc="03"
   f_admCTL W
   SGCPINCMCADQ.sh FTPIP0040T1 IP0040T1.DAT
   vRet="$?"
   if [ "${vRet}" != "0" ]; then
      vEstProc="E"
      f_admCTL W
      f_finerr
   fi

   # CONVMFOCUS
   vSubProc="04"
   f_admCTL W
   SGCPINCMCADQ.sh CONVMFOCUS E ${pEntAdq} ${pFecProc} ${pNumSec}
   vRet="$?"
   if [ "${vRet}" != "0" ]; then
      vEstProc="E"
      f_admCTL W
      f_finerr
   fi

   # FTPT067
   vSubProc="05"
   f_admCTL W
   SGCPINCMCADQ.sh FTPT067 E ${pEntAdq} ${pFecProc} ${pNumSec}
   vRet="$?"
   if [ "${vRet}" != "0" ]; then
      vEstProc="E"
      f_admCTL W
      f_finerr
   fi

fi # BINES (EVENTUAL)


# CARGA DE TIPO DE CAMBIO

if [ "${pCodProc}" = "TC" ]; then

   # CARTIPCAMB
   vSubProc="01"
   f_admCTL W
   SGCPINCMCADQ.sh CARTIPCAMB ${pEntAdq} ${pFecProc} ${pNumSec} ${pOpcRepro}
   vRet="$?"
   if [ "${vRet}" != "0" ]; then
      vEstProc="E"
      f_admCTL W
      f_finerr
   fi


fi # CARGA DE TIPO DE CAMBIO


# CARGA DE INCOMING

if [ "${pCodProc}" = "INCOMINGMC" ]; then

   # INCOMING
   vSubProc="01"
   f_admCTL W
   SGCPINCMCADQ.sh INCOMINGMC ${pEntAdq} ${pFecProc}
   vRet="$?"
   if [ "${vRet}" != "0" ]; then
      vEstProc="E"
      f_admCTL W
      f_finerr
   fi

fi # CARGA DE INCOMING


# CARGA DE INCOMING DE RETORNOS

if [ "${pCodProc}" = "INCRET" ]; then

   # UNEARCHMC
   vSubProc="01"
   f_admCTL W
   SGCPINCMCADQ.sh INCRETMC ${pEntAdq} ${pFecProc}
   vRet="$?"
   if [ "${vRet}" != "0" ]; then
      vEstProc="E"
      f_admCTL W
      f_finerr
   fi

fi # CARGA DE INCOMING DE RETORNOS


# CARGA DE INCOMING MATCH

if [ "${pCodProc}" = "INCMATCH" ]; then

   # INCMATCH
   vSubProc="01"
   f_admCTL W
   SGCPINCMCADQ.sh INCMATCH ${pEntAdq} ${pFecProc}
   vRet="$?"
   if [ "${vRet}" != "0" ]; then
      vEstProc="E"
      f_admCTL W
      f_finerr
   fi


fi # CARGA DE INCOMING MATCH


# CARGA DE INCOMING MAESTRO

if [ "${pCodProc}" = "INCMAESTRO" ]; then

   # INCMAESTRO
   vSubProc="01"
   f_admCTL W

   SGCPCCLMA.sh ${pEntAdq} ${pFecProc}

   vRet="$?"
   if [ "${vRet}" != "0" ]; then
      vEstProc="E"
      f_admCTL W
      f_finerr
   fi

   SGCPCPSMA.sh ${pEntAdq} ${pFecProc}

   vRet="$?"
   if [ "${vRet}" != "0" ]; then
      vEstProc="E"
      f_admCTL W
      f_finerr
   fi

fi # CARGA DE INCOMING MAESTRO

# CARGA DE INCOMING MAESTRO NAIGUATA

if [ "${pCodProc}" = "INCMAESTRONGTA" ]; then

   # INCMAESTRO NAIGUATA
   vSubProc="01"
   f_admCTL W

   SGCPCCLMA_ngta.sh ${pEntAdq} ${pFecProc}

   vRet="$?"
   if [ "${vRet}" != "0" ]; then
      vEstProc="E"
      f_admCTL W
      f_finerr
   fi

   SGCPCPSMA_ngta.sh ${pEntAdq} ${pFecProc}

   vRet="$?"
   if [ "${vRet}" != "0" ]; then
      vEstProc="E"
      f_admCTL W
      f_finerr
   fi

fi # CARGA DE INCOMING MAESTRO NAIGUATA

vEstProc="F"
f_admCTL W

f_msgtit F

################################################################################
## FIN | PROCEDIMIENTO PRINCIPAL
################################################################################
