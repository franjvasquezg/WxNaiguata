#!/bin/ksh

################################################################################
##
##  Nombre del Programa : SGCPCPSMA_ngta.sh
##                Autor : JMG
##       Codigo Inicial : 18/02/2008
##          Descripcion : Proceso Compensacion de Maestro Naiguata
##
##  ======================== Registro de Modificaciones ========================
##
##  Fecha      Autor Version Descripcion de la Modificacion
##  ---------- ----- ------- ---------------------------------------------------
##  18/02/2008 JMG   1.00    Codigo Inicial
##  28/02/2008 JMG   1.10    Proceso de compensacion con detalle de Arch.Datos
##  11/03/2008 JMG   1.11    Proceso de compensacion Correccion Trailer de Datos
##  23/03/2008 JMG   1.12    Fecha del archivo es fecha del dia
##  06/05/2008 JMG   1.13    Prefijo Automatico en Archivos en DESA,CCAL y PROD
##  19/05/2008 JMG   1.14    Ejecucion de AddCrLf2File.java fuera del DIRBIN
##  26/05/2008 JMG   1.15    Cambio de nombres de archivos LOG
##  15/09/2008 JMG   2.00    Actualizacion de proceso
##  10/11/2011 CPU   2.10    Carga con CTL, informacion en dolares (IPR 1017).
##  29/06/2012 JMG   2.50    Se quita el uso de la aplicacion AddCrLf2File.sh
##  03/02/2020 FJV   3.00    SC para la compensacion maestro naiguata
##
################################################################################

################################################################################
## DECLARACION DE DATOS, PARAMETROS DE EJECUCION Y VARIABLES DEL PROGRAMA
################################################################################

## Datos del Programa
################################################################################

dpNom="SGCPCPSMA_ngta"              # Nombre del Programa
dpDesc=""                      # Descripcion del Programa
dpVer=3.00                     # Ultima Version del Programa
dpFec="20200203"               # Fecha de Ultima Actualizacion [Formato:AAAAMMDD]

## Variables del Programa
################################################################################

vpValRet=""                    # Valor de Retorno (funciones)
vpFH=`date '+%Y%m%d%H%M%S'`    # Fecha y Hora [Formato:AAAAMMDDHHMMSS]
vpFileLOG=""                   # Nombre del Archivo LOG del Programa

## Parametros de Ejecucion
################################################################################

pEntAdq="$1"                   # Entidad Adquirente [BM=Banco Mercantil/BP=Banco Provincial]
pFecProc="$2"                  # Fecha de Proceso [Formato: AAAAMMDD, default=SYSDATE]

## Variables de Trabajo
################################################################################

vNomFile_IdAdq=""              # Nombre del Archivo de Datos - Adquiriente
vNomFile_FeJul=""              # Nombre del Archivo de Datos - Fecha Juliana
vNomFile_Prefi=""              # Nombre del Archivo de Datos - Prefijo
vNomFile_SecA=""               # Secuencia del años en curso ultimo digito Ex: 2020 Seria 0 Ex2: 2021 Seria 1 IPR 1302

vEntidad=""                    # Nombre de la Entidad
vEntidadIdB=""                 # Identificador Banco #IPR1302 NAIGUATA
vCodAmbi=""                    # Codigo de Ambiente
vNomFile=""                    # Nombre del Archivo de Datos
vFileDIR=""                    # Nombre del Archivo con Lista "vFileDAT" Existentes
vFileDAT=""                    # Archivo de Datos a Cargar
vFileTMP=""                    # Archivo Temporal para agregar saltos de linea
vFileCTL=""                    # Archivo de Control de la Carga
vFileCAR=""                    # Archivo LOG de la Carga
vFileBAD=""                    # Archivo de Errores de la Carga
vFileDSC=""                    # Archivo de Registros Descartados


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
f_msg "${vMsg}" S
if [ "${pTipo}" = "E" ]; then
   exit 1;
elif [ "${pTipo}" = "F" ]; then
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

pEntAdq  (obligatorio): Entidad Adquirente
                        [BM=Banco Mercantil/BP=Banco Provincial]
pFecProc (opcional)   : Fecha de Proceso [Formato: AAAAMMDD, default=SYSDATE]
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


################################################################################
## INICIO | PROCEDIMIENTO PRINCIPAL
################################################################################

dpDesc="Proceso Compensacion de Naiguata Maestro"


## Verificacion de Parametros
################################################################################


# Entidad Adquirente
if [ "${pEntAdq}" = "BM" ]; then
   vEntidad="Banco Mercantil"
   vEntidadIdB="0502"            #IPR1302 NAIGUATA
elif [ "${pEntAdq}" = "BP" ]; then
   vEntidad="Banco Provincial"
   vEntidadIdB="0502"            #IPR1302 NAIGUATA
else
   echo
   f_fhmsg "ERROR | Entidad Adquiriente Incorrecta."
   f_parametros
   exit 1;
fi

dpDesc="${dpDesc} (${pEntAdq})"

# Fecha de Proceso
if [ "${pFecProc}" = "" ]; then
    pFecProc=`getdate`
fi


## Archivos de Trabajo
## -------------------
## File PROD: 464EEEEE_JJJ_SS_conv
## File CCAL: 470EEEEE_JJJ_SS_conv
## File DESA: 470EEEEE_JJJ_SS_conv
##
## EEEEE    : Endpoint , 01857 BM , 01858 BP
## JJJ      : Fecha Juliana
## SS       : Secuencia
################################################################################

f_msgtit I
f_fhmsg "Buscando archivo de datos con secuencia maxima"

## Ibteniendo Prefijo de Archivo segun Ambiente
vCodAmbi=`echo ${COD_AMBIENTE}`
if [ "${vCodAmbi}" = "PROD" ]; then
   vNomFile_Prefi="T464NA"
elif [ "${vCodAmbi}" = "CCAL" ]; then
   vNomFile_Prefi="T464NA"
elif [ "${vCodAmbi}" = "DESA" ]; then
   vNomFile_Prefi="T464NA"
fi

## Ibteniendo ID de Adquiriente
if [ "${pEntAdq}" = "BM" ]; then
   vNomFile_IdAdq="0275"
elif [ "${pEntAdq}" = "BP" ]; then
   vNomFile_IdAdq="0313"
fi

## Ibteniendo Fecha Juliana
vNomFile_FeJul=`dayofyear ${pFecProc}`
vNomFile_FeJul=`expr ${vNomFile_FeJul} - 1`
vNomFile_FeJul=`printf "%03d" $vNomFile_FeJul`

## corresponde al último dígito del año al que corresponde el bulk, 
## es decir, el cero corresponde al año 2020 para el año venidero el valor deberá ser 1.
vNomFile_SecA=`echo ${pFecProc} | awk '{print substr($0,4,1)}'`

## Buscando Archivo de Datos con secuencia maxima
##vNomFile=${vNomFile_Prefi}${vNomFile_IdAdq}_${vNomFile_FeJul}_*_"conv"
##vNomFile=${vNomFile_Prefi}_${vNomFile_IdAdq}_${vEntidadIdB}_"0"_"062"_"conv33"   ##PRUEBA IPR1302
vNomFile=${vNomFile_Prefi}_${vNomFile_IdAdq}_${vEntidadIdB}_${vNomFile_SecA}_${vNomFile_FeJul}_"conv"   ##PRUEBA IPR1302
vFileDIR=${DIRTMP}/${dpNom}${vpFH}.TMP

##ls -a ${DIRIN}/${vNomFile_Prefi}${vNomFile_IdAdq}_${vNomFile_FeJul}_[0-9][0-9]_conv 2>/dev/null 1>${vFileDIR}
##ls -a ${DIRIN}/${vNomFile_Prefi}_${vNomFile_IdAdq}_${vEntidadIdB}_"0"_"062"_"conv33" 2>/dev/null 1>${vFileDIR}
ls -a ${DIRIN}/${vNomFile_Prefi}_${vNomFile_IdAdq}_${vEntidadIdB}_${vNomFile_SecA}_${vNomFile_FeJul}_"conv" 2>/dev/null 1>${vFileDIR}


vCant_line=`cat ${vFileDIR} | wc -l | sed 's/ //g'`

if [ ${vCant_line} = "0" ]; then
   rm ${vFileDIR}
   oraexec "exec PQPMAESTRO.p_NoExisteArchivo('${pEntAdq}',TO_DATE('${pFecProc}','YYYYMMDD'),'${vNomFile}','PCPSMA_NGTA');" $DB
   f_finerr "ERROR: Archivo <${vNomFile}> no encontrado."
else
   vNomFile=`tail -1 ${vFileDIR}`
   vNomFile=`basename ${vNomFile}`
   rm ${vFileDIR}
fi

## Nombrando Archivos
vFileID=${dpNom}.${pFecProc}.${vpFH}
vFileDAT=${DIRIN}/${vNomFile}
vFileTMP=${DIRTMP}/${vNomFile}.TMP
vFileCAR=${DIRTMP}/${vFileID}.CAR
vFileBAD=${DIRTMP}/${vFileID}.BAD
vFileDSC=${DIRTMP}/${vFileID}.DSC
vFileCTL=${DIRDAT}/${dpNom}.CTL

## Crea Archivo LOG del Programa
################################################################################

vpFileLOG="${DIRLOG}/${vFileID}.LOG"

echo > ${vpFileLOG}


## Informe de Archivos a utilizar
################################################################################

f_msg
f_fechora ${pFecProc}
f_msg "           Fecha de Proceso : ${vpValRet}"
f_msg "         Entidad Adquirente : ${vEntidad} (${pEntAdq})"
f_msg "           Archivo de Datos : `basename ${vFileDAT}`"
f_msg "                 Directorio : `dirname ${vFileDAT}`"
f_msg "         Archivo de Control : `basename ${vFileCTL}`"
f_msg "                 Directorio : `dirname ${vFileCTL}`"
f_msg "    Archivo LOG del Proceso : `basename ${vpFileLOG}`"
f_msg "                 Directorio : `dirname ${vpFileLOG}`"
f_msg "       Archivo LOG de Carga : `basename ${vFileCAR}`"
f_msg "                 Directorio : `dirname ${vFileCAR}`"
f_msg "         Archivo de Errores : `basename ${vFileBAD}`"
f_msg "                 Directorio : `dirname ${vFileBAD}`"
f_msg "       Archivo de Descartes : `basename ${vFileDSC}`"
f_msg "                 Directorio : `dirname ${vFileDSC}`"
f_msg

# Verifica la Existencia del Archivo de Datos y Archivo de Control
################################################################################

f_fhmsg "Verificando Existencia de Archivos"
if ! [ -f "${vFileDAT}" ]; then
   vNomFile=`basename ${vFileDAT}`
   oraexec "exec PQPMAESTRO.p_NoExisteArchivo('${pEntAdq}',TO_DATE('${pFecProc}','YYYYMMDD'),'${vNomFile}','PCPSMA_NGTA');" $DB
   f_finerr "ERROR: Archivo de datos <${vNomFile}> no encontrado."
fi
if ! [ -f "${vFileCTL}" ]; then
   vNomFile=`basename ${vFileCTL}`
   oraexec "exec PQPMAESTRO.p_NoExisteArchivo('${pEntAdq}',TO_DATE('${pFecProc}','YYYYMMDD'),'${vNomFile}','PCPSMA_NGTA');" $DB
   f_finerr "ERROR: Archivo de control <${vNomFile}> no encontrado."
fi

# Archivo Temporal
################################################################################

cp -p ${vFileDAT} ${vFileTMP}

# Contamos Numero de Lineas del Archivo de Datos TMP
################################################################################

vNLineTMP=`cat ${vFileTMP} | wc -l | sed 's/ //g'`

if [ ${vNLineTMP} = "0" ]; then
  f_finerr "ERROR: El archivo <${vNomFile}> no tiene registros."
fi

# Inicio de la Carga del Archivo
################################################################################

f_fhmsg "Cargando archivo a base de datos"
sqlload $DB data=${vFileTMP} control=${vFileCTL} log=${vFileCAR} bad=${vFileBAD} discard=${vFileDSC} >> $vpFileLOG
vRet="$?"
echo >> $vpFileLOG
if [ "$vRet" != "0" ] && [ "$vRet" != "2" ]; then
   f_finerr "Error al ejecutar SQLLOAD (vRet=${vRet}). Revisar Archivos LOG y BAD."
fi

## Procesos ORACLE NGTA IPR-1302
################################################################################

# Ejecuta Proceso Oracle de Compensacion
f_fhmsg "Procesando compensacion en base de datos"
vNomFile=`basename ${vFileTMP}`
vRet=`ORAExec.sh "exec :rC:=PQPMAESTRO.pf_Load_compensacion_ngta('${pEntAdq}',TO_DATE('$pFecProc','YYYYMMDD'),'${vNomFile}');" $DB`
f_vrfvalret "$?" "Error al Ejecutar PQPMAESTRO.pf_Load_compensacion_ngta. Avisar a Soporte."
vEst=`echo $vRet | awk '{print substr($0,1,1)}'`
if [ "$vEst" != "0" ]; then
   vRet=`echo "$vRet" | awk '{print substr($0,2)}'`
   f_finerr "$vRet"
fi

# Eliminando Temporales
################################################################################

f_fhmsg "Eliminando archivos temporales"
rm -f ${vFileTMP}

f_msgtit F
exit 0;

################################################################################
## FIN | PROCEDIMIENTO PRINCIPAL
################################################################################
