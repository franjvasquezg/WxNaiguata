#!/bin/ksh

################################################################################
##
##  Nombre del Programa : SGCOUTMCconv_ngta.sh
##                Autor : SSM
##       Codigo Inicial : 06/11/2007
##          Descripcion : Outgoing MC | Conversion de Archivo de Outgoing
##
##  ======================== Registro de Modificaciones ========================
##
##  Fecha      Autor Version Descripcion de la Modificacion
##  ---------- ----- ------- ---------------------------------------------------
##  06/11/2007 SSM   1.00    Codigo Inicial
##  07/04/2010 JMG   1.20    Nuevo BitMapConv2 para generar archivo Host
##  06/06/2012 JMG   1.50    Modificacion para enviar alertas en el SGCMON.
##                           Nuevo FileConverter.sh que reemplaza a BitMapConv2.
##  23/03/2020 JMG   2.00    Nuevo SC Adactado A los Salientes Naiguata Master.
##
################################################################################

################################################################################
## DECLARACION DE DATOS, PARAMETROS DE EJECUCION Y VARIABLES DEL PROGRAMA
################################################################################


## Datos del Programa
################################################################################

dpNom="SGCOUTMCconv_ngta"          # Nombre del Programa
dpDesc=""                     # Descripcion del Programa
dpVer=2.00                    # Ultima Version del Programa
dpFec="20200323"              # Fecha de Ultima Actualizacion [Formato:AAAAMMDD]


## Variables del Programa
################################################################################

vpValRet=""                   # Valor de Retorno (funciones)
vpFH=`date '+%Y%m%d%H%M%S'`   # Fecha y Hora [Formato:AAAAMMDDHHMMSS]
vpFileLOG=""                  # Nombre del Archivo LOG del Programa


## Parametros de Ejecucion
################################################################################

pFileOUTMC="$1"               # Archivo Outgoing MC (OUTMCEEEEAAAAMMDDNN.DAT)


## Variables de Trabajo
################################################################################

vEntidad=""                   # Entidad
vFecSes=""                    # Fecha de Sesion
vSecuencia=""                 # Secuencia
vTipoBulk=""                  # Tipo de Archivo
vEndPoint=""                  # End Point
vFileHOST=""                  # Archivo en Formato HOST
vFileIPM=""                   # Archivo en Formato IPM
typeset -i vIDAlerta          # ID de Alerta

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

Parametro 1 (obligatorio) : Archivo Outgoing MC [OUTMCEEEEAAAAMMDDNN.DAT], donde:
                              EEEE = Entidad
                              AAAAMMDD = Fecha de Sesion
                              NN = Secuencia

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


# f_ftp () | transferencia FTP
################################################################################
f_ftp ()
{

pDirOri="$1"
pDirDest="$2"
pFile="$3"
pTipoTransf="$4"

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
verbose                              \n\
open ${FTP_HOSTXCOMMC}                 \n\
user ${FTP_USERXCOMMC}                 \n\
prompt                               \n\
${pTipoTransf}                       \n\
cd ${pDirDest}                       \n\
put ${pFile} ${pFile}.ftp            \n\
rename ${pFile}.ftp ${pFile}         \n\
put ${pFile}.FLG ${pFile}.FLG.ftp    \n\
rename ${pFile}.FLG.ftp ${pFile}.FLG \n\
bye                                  \n\
"

# echo "$vCmdFTP"
f_fhmsg "Transfiriendo ${pFile} al Servidor ${pHOST}..."
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
   f_fhmsg "ERROR: Archivo ${pFile} NO Transferido. Revisar e Informar."
else
   rm -f $vFileParFTP
   f_fhmsg "Archivo ${pFile} Transferido."
fi

}


################################################################################
## INICIO | PROCEDIMIENTO PRINCIPAL
################################################################################

## Validacion de Parametros
################################################################################

# Verifica Parametro de Entrada
if [ $# -eq 0 ]; then
   f_parametros;
   exit 1;
fi

# Archivo Outgoing MC
pFileOUTMC="`basename ${pFileOUTMC}`"

if [ "`echo $pFileOUTMC | awk '{print substr($0,1,10)}'`" != "OUTMC_NGTA" ]; then
   echo
   f_fhmsg "ERROR: Archivo de Outgoing Naiguata Incorrecto." S N
   f_parametros;
   exit 1;
fi

if [ "`echo ${pFileOUTMC} | awk '{print length($0)}'`" != "28" ]; then
   echo
   f_fhmsg "ERROR: Archivo de Outgoing Naiguata Incorrecto." S N
   f_parametros;
   exit 1;
fi

if [ "`echo $pFileOUTMC | awk '{print substr($0,25,4)}'`" != ".DAT" ]; then
   echo
   f_fhmsg "ERROR: Archivo de Outgoing Naiguata Incorrecto." S N
   f_parametros;
   exit 1;
fi


# Datos Principales para el Proceso

vEntidad="`echo $pFileOUTMC | awk '{print substr($0,11,4)}'`"
vFecSes="`echo $pFileOUTMC | awk '{print substr($0,15,8)}'`"
vSecuencia="`echo $pFileOUTMC | awk '{print substr($0,23,2)}'`"
vNomFile="`echo $pFileOUTMC | awk '{print substr($0,1,23)}'`"

# Tipo de Archivo
if [ "${COD_AMBIENTE}" = "DESA" ]; then
   # Ambiente: Desarrollo
   vTipoBulk="119"
elif [ "${COD_AMBIENTE}" = "CCAL" ]; then
     # Ambiente: Control de Calidad
     vTipoBulk="119"
elif [ "${COD_AMBIENTE}" = "PROD" ]; then
     # Ambiente: Produccion
     vTipoBulk="111"
else
   echo
   f_fhmsg "ERROR: Codigo de Ambiente Incorrecto (COD_AMBIENTE=${COD_AMBIENTE})" S N
   exit 1;
fi

# End Point

if [ "${vEntidad}" = "0105" ]; then
   vEndPoint="01857"
elif [ "${vEntidad}" = "0108" ]; then
   vEndPoint="01858"
else
   echo
   f_fhmsg "ERROR: Codigo de Entidad Incorrecto (Entidad=${vEntidad})" S N
   exit 1;
fi

# Archivo IPM

vFecJul="`dayofyear ${vFecSes}`"
vFecJul=`printf "%03d" $vFecJul`
vFileHOST="R${vTipoBulk}${vEndPoint}${vFecJul}${vSecuencia}"
vFileIPM="${vFileHOST}.IPM"

## Descripcion del Programa
################################################################################
dpDesc="Conversion de Archivos de Outgoing de Naiguata MasterCard"


## Archivo LOG
################################################################################

vpFileLOG="${DIRLOG}/SGCOUTMCconv_ngta${vEntidad}${vFecSes}.${vpFH}.LOG"
echo > $vpFileLOG


################################################################################
## INICIO | PROCEDIMIENTO PRINCIPAL
################################################################################

f_msgtit I

f_msg "        Archivo de Entrada : ${pFileOUTMC}"
f_msg "                Directorio : ${DIROUT}"
f_msg "    Archivo de Salida HOST : ${vFileHOST}"
f_msg "                Directorio : ${DIROUT}"
f_msg "     Archivo de Salida IPM : ${vFileIPM}"
f_msg "                Directorio : ${DIROUT}"
f_msg "            Archivo de LOG : `basename ${vpFileLOG}`"
f_msg "                Directorio : `dirname ${vpFileLOG}`"
f_msg

# Verifica la Existencia del Archivo
if ! [ -f "${DIROUT}/${pFileOUTMC}" ]; then
   f_finerr "ERROR: Archivo de Entrada NO Encontrado."
fi

f_fhmsg "Procesando Archivo de Salida HOST..."
#${DIRBIN}/ConvertUtil -f uh -b hb -o ${DIROUT}/${vFileHOST} ${DIROUT}/${pFileOUTMC}
#${DIRBIN}/BitMapConv2 -bh ${DIROUT}/${pFileOUTMC} ${DIROUT}/${vFileHOST}
${DIRBIN}/FileConverter.sh -u -h ${DIROUT}/${pFileOUTMC} ${DIROUT}/${vFileHOST} ${DIRDAT}/mc-read.xml ${DIRDAT}/mc-write.xml

vRet="$?"
if [ "$vRet" = "0" ]; then
   f_fhmsg "Archivo de Salida HOST Generado <${vFileHOST}>..."
else
   vIDAlerta=`ORAExec.sh "exec :rN:=PQMONPROC.InsAlerta('Error en el Outgoing Naiguata MC. No se pudo convertir el archivo ${pFileOUTMC} a formato HOST.');" $DB`
   f_fhmsg "Alerta Registrada en el Sistema de Monitoreo (ID=${vIDAlerta})" N S
   f_finerr "ERROR: Archivo de Salida HOST NO Generado <${vFileHOST}>."
fi

f_fhmsg "Procesando Archivo de Salida Naiguata IPM..."
#${DIRBIN}/BitMapConv2 -b ${DIROUT}/${pFileOUTMC} ${DIROUT}/${vFileIPM}
${DIRBIN}/FileConverter.sh -u -v ${DIROUT}/${pFileOUTMC} ${DIROUT}/${vFileIPM} ${DIRDAT}/mc-read.xml ${DIRDAT}/mc-write.xml

vRet="$?"
if [ "$vRet" = "0" ]; then
   f_fhmsg "Archivo de Salida IPM Naiguata Generado <${vFileIPM}>..."
else
   vIDAlerta=`ORAExec.sh "exec :rN:=PQMONPROC.InsAlerta('Error en el Outgoing MC. No se pudo convertir el archivo ${pFileOUTMC} a formato IPM.');" $DB`
   f_fhmsg "Alerta Registrada en el Sistema de Monitoreo (ID=${vIDAlerta})" N S
   f_finerr "ERROR: Archivo de Salida IPM Naiguata NO Generado <${vFileIPM}>."
fi

f_ftp ${DIROUT} "mc_ngta_filein" ${vFileHOST} B
if [ "$vpValRet" != "0" ]; then
   f_finerr
fi

f_ftp ${DIROUT} "mc_ngta_filein" ${vFileIPM} B
if [ "$vpValRet" != "0" ]; then
   f_finerr
fi

f_msgtit F


################################################################################
## FIN | PROCEDIMIENTO PRINCIPAL
################################################################################
