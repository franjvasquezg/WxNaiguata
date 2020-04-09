#!/bin/ksh

################################################################################
##
##  Nombre del Programa : SGCPINCMCADQLOGmenu.sh
##                Autor : JMG
##       Codigo Inicial : 23/05/2008
##          Descripcion : Menu de Log de Procesos
##
##  ======================== Registro de Modificaciones ========================
##
##  Fecha      Autor Version Descripcion de la Modificacion
##  ---------- ----- ------- ---------------------------------------------------
##  26/05/2008 JMG   2.00    Codigo Inicial
##  06/03/2013 DCB   2.00    Modificado para Incoming Automatico
##
################################################################################

################################################################################
## DECLARACION DE DATOS, PARAMETROS DE EJECUCION Y VARIABLES DEL PROGRAMA
################################################################################


## Datos del Programa
################################################################################

dpNom="SGCPINCMCADQLOGmenu"   # Nombre del Programa
dpDesc=""                     # Descripcion del Programa
dpVer=2.00                    # Ultima Version del Programa
dpFec="20080526"              # Fecha de Ultima Actualizacion [Formato:AAAAMMDD]

## Variables del Programa
################################################################################

vpValRet=""                   # Valor de Retorno (funciones)
vpFH=`date '+%Y%m%d%H%M%S'`   # Fecha y Hora [Formato:AAAAMMDDHHMMSS]
vpFileLOG=""                  # Nombre del Archivo LOG del Programa


## Parametros
################################################################################

pEntAdq="$1"                  # Entidad Adquirente [BM/BP]
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



# f_menuOPC () | menu de opciones
################################################################################
f_menuOPC ()
{
   f_getCTAMC BINESD
   vpValRet_1=${vpValRet}
   f_getCTAMC TC
   vpValRet_2=${vpValRet}
   f_getCTAMC INCOMING
   vpValRet_3=${vpValRet}
   f_getCTAMC INCRET
   vpValRet_4=${vpValRet}
   f_getCTAMC INCMATCH
   vpValRet_5=${vpValRet}
   f_getCTAMC INCMAESTRO
   vpValRet_6=${vpValRet}
   f_getCTAMC BINESE
   vpValRet_7=${vpValRet}
   f_getCTAMC REPCREDMC
   vpValRet_8=${vpValRet}
   f_getCTAMC REPDEBMAESTRO
   vpValRet_9=${vpValRet}

   echo "-------------------------------------------------------------------------------"
   echo
   echo "CONSULTAS"
   echo "-----------------------------------"
   echo "[ 1] LOG de Incoming Maestro (${vpValRet_6})"
   echo "[ 2] LOG de Proceso de Incoming y Retornos (${vpValRet_3}-${vpValRet_4})"
   echo "[ 3] LOG de Carga de Bines (${vpValRet_1})"
   echo "[ 4] LOG de Carga de Tipo de Cambio (${vpValRet_2})"
   echo "[ 5] LOG de Reporte Debito Maestro (${vpValRet_9})"
   echo "[ 6] LOG de Reporte de Credito Master Card (${vpValRet_8})"
   echo
   echo "-------------------------------------------------------------------------------"
   echo " Ver $dpVer | Telefonica Servicios Transaccionales                     [Q] Salir"
   echo "-------------------------------------------------------------------------------"

}

# f_getCTAMC () | codigo de tipo de archivo
################################################################################
f_getCTAMC ()
{

pTipo="$1"

if [ "${pTipo}" = "TC" ]; then
   vpValRet=`echo $COD_TIPOARCHMC | awk '{print substr($0,1,3)}'`
elif [ "${pTipo}" = "BINESD" ]; then
     vpValRet=`echo $COD_TIPOARCHMC | awk '{print substr($0,4,3)}'`
elif [ "${pTipo}" = "BINESE" ]; then
     vpValRet=`echo $COD_TIPOARCHMC | awk '{print substr($0,7,3)}'`
elif [ "${pTipo}" = "INCOMING" ]; then
     vpValRet=`echo $COD_TIPOARCHMC | awk '{print substr($0,10,3)}'`
elif [ "${pTipo}" = "INCRET" ]; then
     vpValRet=`echo $COD_TIPOARCHMC | awk '{print substr($0,13,3)}'`
elif [ "${pTipo}" = "INCMATCH" ]; then
     vpValRet=`echo $COD_TIPOARCHMC | awk '{print substr($0,16,3)}'`
elif [ "${pTipo}" = "INCMAESTRO" ]; then
     vpValRet=`echo $COD_TIPOARCHMC | awk '{print substr($0,19,3)}'`
elif [ "${pTipo}" = "REPCREDMC" ]; then
     vpValRet=`echo $COD_TIPOARCHMC | awk '{print substr($0,22,3)}'`
elif [ "${pTipo}" = "REPDEBMAESTRO" ]; then
     vpValRet=`echo $COD_TIPOARCHMC | awk '{print substr($0,25,3)}'`
fi

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
     f_msg "Codigo de Entidad Incorrecto [BM/BP]"
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

   vFileBINESD="SGCPINCMC${pEntAdq}.BINESD.${vFecProc}"
   vFileBINESE="SGCPINCMC${pEntAdq}.BINESE.${vFecProc}"
   vFileTC="SGCPINCMC${pEntAdq}.TC.${vFecProc}"
   vFileINCOMING="SGCPINCMC${pEntAdq}.INCOMINGMC.${vFecProc}"
   vFileINCRET="SGCPINCMC${pEntAdq}.INCRET.${vFecProc}"
   vFileINCMATCH="SGCPINCMC${pEntAdq}.INCMATCH.${vFecProc}"
   vFileINCMAESTRO="SGCPINCMC${pEntAdq}.INCMAESTRO.${vFecProc}"

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


   # LOG DE INCOMING MAESTRO

   if [ "$vOpcion" = "1" ]; then

      vFlgOpcErr="N"
      vOpcion=""
         if [ "$pEntAdq" = "TODOS" ]
         then
            for vEntAdq in BM BP
            do
              vFileINCMAESTRO="SGCPINCMC${vEntAdq}.INCMAESTRO.${vFecProc}"
              vFileLOG="${DIRLOG}/${vFileINCMAESTRO}"
              vFileCTL="${DIRDAT}/${vFileINCMAESTRO}.CTL"
              if [ -f "${vFileCTL}" ]; then
                vEstProc=`awk '{print substr($0,13,1)}' $vFileCTL`
                case $vEstProc in
                  P) echo
                    f_fhmsg "El Proceso de Incoming Maestro aun no ha sido ejecutado."
                    echo
                    echo "... presione [ENTER] para continuar."
                    read vContinua;;
                  X) echo
                    f_fhmsg "Proceso de Incoming Maestro en Ejecucion... [CTRL+C para salir del LOG]"
                    echo
                    trap "trap '' 2" 2
                    tail -f $vFileLOG
                    trap "";;
                  *) echo
                    vFileLOG=`ls -tr ${vFileLOG}*.LOG | tail -1`
                    f_msg "Archivo LOG: $vFileLOG"
                    echo
                    cat $vFileLOG
                    echo "... presione [ENTER] para continuar."
                    read vContinua;;
                esac
              else
                echo
                f_fhmsg "El Proceso de Incoming Maestro aun no ha sido ejecutado."
                echo
                echo "... presione [ENTER] para regresar."
                read vContinua;
              fi
            done
         else
            vFileINCMAESTRO="SGCPINCMC${pEntAdq}.INCMAESTRO.${vFecProc}"
            vFileLOG="${DIRLOG}/${vFileINCMAESTRO}"
            vFileCTL="${DIRDAT}/${vFileINCMAESTRO}.CTL"
            if [ -f "${vFileCTL}" ]; then
              vEstProc=`awk '{print substr($0,13,1)}' $vFileCTL`
              case $vEstProc in
                P) echo
                  f_fhmsg "El Proceso de Incoming Maestro aun no ha sido ejecutado."
                  echo
                  echo "... presione [ENTER] para continuar."
                  read vContinua;;
                X) echo
                  f_fhmsg "Proceso de Incoming Maestro en Ejecucion... [CTRL+C para salir del LOG]"
                  echo
                  vFileLOG=`ls -tr ${vFileLOG}*.LOG | tail -1`
                  trap "trap '' 2" 2
                  tail -f $vFileLOG
                  trap "";;
                *) echo
                  vFileLOG=`ls -tr ${vFileLOG}*.LOG | tail -1`
                  f_msg "Archivo LOG: $vFileLOG"
                  echo
                  cat $vFileLOG
                  echo "... presione [ENTER] para continuar."
                  read vContinua;;
              esac
            else
              echo
              f_fhmsg "El Proceso de Incoming Maestro aun no ha sido ejecutado."
              echo
              echo "... presione [ENTER] para regresar."
              read vContinua;
            fi
         fi
   fi # Opcion 1 - LOG de Incoming Maestro

   # LOG DE INCOMING Y RETORNOS

   if [ "$vOpcion" = "2" ]; then

      vFlgOpcErr="N"
      vOpcion=""
         if [ "$pEntAdq" = "TODOS" ]
         then
            for vEntAdq in BM BP
            do
              vFileINCOMING="SGCPINCMC${vEntAdq}.INCOMINGMC.${vFecProc}"
              vFileINCRET="SGCPINCMC${vEntAdq}.INCRET.${vFecProc}"
              vFileLOG="${DIRLOG}/${vFileINCOMING}"
              vFileCTL="${DIRDAT}/${vFileINCOMING}.CTL"
              if [ -f "${vFileCTL}" ]; then
                vEstProc=`awk '{print substr($0,13,1)}' $vFileCTL`
                case $vEstProc in
                  P) echo
                    f_fhmsg "El Proceso de Incoming MasterCard aun no ha sido ejecutado."
                    echo
                    echo "... presione [ENTER] para continuar."
                    read vContinua;;
                  X) echo
                    f_fhmsg "Proceso de Incoming MasterCard en Ejecucion... [CTRL+C para salir del LOG]"
                    echo
                    vFileLOG=`ls -tr ${vFileLOG}*.LOG | tail -1`
                    trap "trap '' 2" 2
                    tail -f $vFileLOG
                    trap "";;
                  *) echo
                    vFileLOG=`ls -tr ${vFileLOG}*.LOG | tail -1`
                    f_msg "Archivo LOG: $vFileLOG"
                    echo
                    cat $vFileLOG
                    echo "... presione [ENTER] para continuar."
                    read vContinua;;
                esac
              else
                echo
                f_fhmsg "El Proceso de Incoming MasterCard aun no ha sido ejecutado."
                echo
                echo "... presione [ENTER] para regresar."
                read vContinua;
              fi
              vFileLOG="${DIRLOG}/${vFileINCRET}"
              vFileCTL="${DIRDAT}/${vFileINCRET}.CTL"
              if [ -f "${vFileCTL}" ]; then
                vEstProc=`awk '{print substr($0,13,1)}' $vFileCTL`
                case $vEstProc in
                  P) echo
                    f_fhmsg "El Proceso de Incoming de Retornos aun no ha sido ejecutado."
                    echo
                    echo "... presione [ENTER] para continuar."
                    read vContinua;;
                  X) echo
                    f_fhmsg "Proceso de Incoming de Retornos en Ejecucion... [CTRL+C para salir del LOG]"
                    echo
                    vFileLOG=`ls -tr ${vFileLOG}*.LOG | tail -1`
                    trap "trap '' 2" 2
                    tail -f $vFileLOG
                    trap "";;
                  *) echo
                    vFileLOG=`ls -tr ${vFileLOG}*.LOG | tail -1`
                    f_msg "Archivo LOG: $vFileLOG"
                    echo
                    cat $vFileLOG
                    echo "... presione [ENTER] para continuar."
                    read vContinua;;
                esac
              else
                echo
                f_fhmsg "El Proceso de Incoming de Retornos aun no ha sido ejecutado."
                echo
                echo "... presione [ENTER] para regresar."
                read vContinua;
              fi
            done
         else
            vFileINCOMING="SGCPINCMC${pEntAdq}.INCOMINGMC.${vFecProc}"
            vFileINCRET="SGCPINCMC${pEntAdq}.INCRET.${vFecProc}"
            vFileLOG="${DIRLOG}/${vFileINCOMING}"
            vFileCTL="${DIRDAT}/${vFileINCOMING}.CTL"
            if [ -f "${vFileCTL}" ]; then
              vEstProc=`awk '{print substr($0,13,1)}' $vFileCTL`
              case $vEstProc in
                P) echo
                  f_fhmsg "El Proceso de Incoming MasterCard aun no ha sido ejecutado."
                  echo
                  echo "... presione [ENTER] para continuar."
                  read vContinua;;
                X) echo
                  f_fhmsg "Proceso de Incoming MasterCard en Ejecucion... [CTRL+C para salir del LOG]"
                  echo
                  trap "trap '' 2" 2
                  vFileLOG=`ls -tr ${vFileLOG}*.LOG | tail -1`
                  tail -f $vFileLOG
                  trap "";;
                *) echo
                  vFileLOG=`ls -tr ${vFileLOG}*.LOG | tail -1`
                  f_msg "Archivo LOG: $vFileLOG"
                  echo
                  cat $vFileLOG
                  echo "... presione [ENTER] para continuar."
                  read vContinua;;
              esac
            else
              echo
              f_fhmsg "El Proceso de Incoming MasterCard aun no ha sido ejecutado."
              echo
              echo "... presione [ENTER] para regresar."
              read vContinua;
            fi
            vFileLOG="${DIRLOG}/${vFileINCRET}"
            vFileCTL="${DIRDAT}/${vFileINCRET}.CTL"
            if [ -f "${vFileCTL}" ]; then
              vEstProc=`awk '{print substr($0,13,1)}' $vFileCTL`
              case $vEstProc in
                P) echo
                  f_fhmsg "El Proceso de Incoming de Retornos aun no ha sido ejecutado."
                  echo
                  echo "... presione [ENTER] para continuar."
                  read vContinua;;
                X) echo
                  f_fhmsg "Proceso de Incoming de Retornos en Ejecucion... [CTRL+C para salir del LOG]"
                  echo
                  vFileLOG=`ls -tr ${vFileLOG}*.LOG | tail -1`
                  trap "trap '' 2" 2
                  tail -f $vFileLOG
                  trap "";;
                *) echo
                  vFileLOG=`ls -tr ${vFileLOG}*.LOG | tail -1`
                  f_msg "Archivo LOG: $vFileLOG"
                  echo
                  cat $vFileLOG
                  echo "... presione [ENTER] para continuar."
                  read vContinua;;
              esac
            else
              echo
              f_fhmsg "El Proceso de Incoming de Retornos aun no ha sido ejecutado."
              echo
              echo "... presione [ENTER] para regresar."
              read vContinua;
            fi
         fi
   fi # Opcion 2 - LOG de Incoming y Retornos

   # LOG DE BINES

   if [ "$vOpcion" = "3" ]; then

      vFlgOpcErr="N"
      vOpcion=""
      vEntAdq="BM"
      vFileBINESD="SGCPINCMC${vEntAdq}.BINESD.${vFecProc}"
      vFileBINESE="SGCPINCMC${vEntAdq}.BINESE.${vFecProc}"
      vFileLOG="${DIRLOG}/${vFileBINESD}"
      vFileCTL="${DIRDAT}/${vFileBINESD}.CTL"
      if [ -f "${vFileCTL}" ]; then
        vEstProc=`awk '{print substr($0,13,1)}' $vFileCTL`
        case $vEstProc in
          P) echo
            f_fhmsg "El Proceso de Carga de Bines aun no ha sido ejecutado."
            echo
            echo "... presione [ENTER] para continuar."
            read vContinua;;
          X) echo
            f_fhmsg "Proceso de Carga de Bines en Ejecucion... [CTRL+C para salir del LOG]"
            echo
            vFileLOG=`ls -tr ${vFileLOG}*.LOG | tail -1`
            trap "trap '' 2" 2
            tail -f $vFileLOG
            trap "";;
          *) echo
            vFileLOG=`ls -tr ${vFileLOG}*.LOG | tail -1`
            f_msg "Archivo LOG: $vFileLOG"
            echo
            cat $vFileLOG
            echo "... presione [ENTER] para continuar."
            read vContinua;;
        esac
      else
        echo
        f_fhmsg "El Proceso de Carga de Bines no ha sido ejecutado, Se revisara la Carga de Bines Eventuales"
        echo
        echo "... presione [ENTER] para regresar."
        read vContinua;
        vFileLOG="${DIRLOG}/${vFileBINESE}"
        vFileCTL="${DIRDAT}/${vFileBINESE}.CTL"
        if [ -f "${vFileCTL}" ]; then
          vEstProc=`awk '{print substr($0,13,1)}' $vFileCTL`
          case $vEstProc in
            P) echo
              f_fhmsg "El Proceso de Carga de Bines Eventuales aun no ha sido ejecutado."
              echo
              echo "... presione [ENTER] para continuar."
              read vContinua;;
            X) echo
              f_fhmsg "Proceso de Carga de Bines Eventuales en Ejecucion... [CTRL+C para salir del LOG]"
              echo
              vFileLOG=`ls -tr ${vFileLOG}*.LOG | tail -1`
              trap "trap '' 2" 2
              tail -f $vFileLOG
              trap "";;
            *) echo
              vFileLOG=`ls -tr ${vFileLOG}*.LOG | tail -1`
              f_msg "Archivo LOG: $vFileLOG"
              echo
              cat $vFileLOG
              echo "... presione [ENTER] para continuar."
              read vContinua;;
          esac
        else
          echo
          f_fhmsg "El Proceso de Carga de Bines Eventuales no ha sido ejecutado."
          echo
          echo "... presione [ENTER] para regresar."
          read vContinua;
        fi
      fi
   fi # Opcion 3 - LOG de Bines

   # LOG DE TIPOS DE CAMBIO

   if [ "$vOpcion" = "4" ]; then

      vFlgOpcErr="N"
      vOpcion=""
      vEntAdq="BM"
      vFileTC="SGCPINCMC${vEntAdq}.TC.${vFecProc}"
      vFileLOG="${DIRLOG}/${vFileTC}"
      vFileCTL="${DIRDAT}/${vFileTC}.CTL"
      if [ -f "${vFileCTL}" ]; then
        vEstProc=`awk '{print substr($0,13,1)}' $vFileCTL`
        case $vEstProc in
          P) echo
            f_fhmsg "El Proceso de Tipos de Cambio aun no ha sido ejecutado."
            echo
            echo "... presione [ENTER] para continuar."
            read vContinua;;
          X) echo
            f_fhmsg "Proceso de Tipos de Cambio en Ejecucion... [CTRL+C para salir del LOG]"
            echo
            vFileLOG=`ls -tr ${vFileLOG}*.LOG | tail -1`
            trap "trap '' 2" 2
            tail -f $vFileLOG
            trap "";;
          *) echo
            vFileLOG=`ls -tr ${vFileLOG}*.LOG | tail -1`
            f_msg "Archivo LOG: $vFileLOG"
            echo
            cat $vFileLOG
            echo "... presione [ENTER] para continuar."
            read vContinua;;
        esac
      else
        echo
        f_fhmsg "El Proceso de Tipos de Cambio no ha sido ejecutado"
      fi
   fi # Opcion 4 - LOG Tipos de Cambio

   # LOG DE REPORTE DE DEBITO MAESTRO

   if [ "$vOpcion" = "5" ]; then

      vFlgOpcErr="N"
      vOpcion=""
         if [ "$pEntAdq" = "TODOS" ]
         then
            for vEntAdq in BM BP
            do
              vFileINCREPDEBMAESTRO="SGCPINCMC${vEntAdq}.REPDEBMAESTRO.${vFecProc}"
              vFileLOG="${DIRLOG}/${vFileINCREPDEBMAESTRO}"
              vFileLOG=`ls -tr ${vFileLOG}*.LOG 2>/dev/null | tail -1`
              if [ -z "$vFileLOG" ]
              then
                 echo "Proceso de Copia de Archivo de Reporte de Debito Maestro no ejecutado"
              else
                 f_msg "Archivo LOG: $vFileLOG"
                 echo
                 cat $vFileLOG
                 echo
              fi
              echo "... presione [ENTER] para continuar."
              read vContinua
            done
         else
            vFileINCREPDEBMAESTRO="SGCPINCMC${pEntAdq}.REPDEBMAESTRO.${vFecProc}"
            vFileLOG="${DIRLOG}/${vFileINCREPDEBMAESTRO}"
            vFileLOG=`ls -tr ${vFileLOG}*.LOG 2>/dev/null | tail -1`
            if [ -z "$vFileLOG" ]
            then
               echo "Proceso de Copia de Archivo de Reporte de Debito Maestro no ejecutado"
            else
               f_msg "Archivo LOG: $vFileLOG"
               echo
               cat $vFileLOG
               echo
            fi
            echo "... presione [ENTER] para continuar."
            read vContinua
         fi
   fi # Opcion 5 - LOG de Reporte Debito Maestro

   # LOG DE REPORTE DE CREDITO MASTERCARD

   if [ "$vOpcion" = "6" ]; then

      vFlgOpcErr="N"
      vOpcion=""
         if [ "$pEntAdq" = "TODOS" ]
         then
            for vEntAdq in BM BP
            do
              vFileINCREPCREDMC="SGCPINCMC${vEntAdq}.REPCREDMC.${vFecProc}"
              vFileLOG="${DIRLOG}/${vFileINCREPCREDMC}"
              vFileLOG=`ls -tr ${vFileLOG}*.LOG 2>/dev/null | tail -1`
              if [ -z "$vFileLOG" ]
              then
                 echo "Proceso de Copia de Archivo de Reporte de Credito MasterCard no ejecutado"
              else
                 f_msg "Archivo LOG: $vFileLOG"
                 echo
                 cat $vFileLOG
                 echo
              fi
              echo "... presione [ENTER] para continuar."
              read vContinua
            done
         else
            vFileINCREPCREDMC="SGCPINCMC${pEntAdq}.REPCREDMC.${vFecProc}"
            vFileLOG="${DIRLOG}/${vFileINCREPCREDMC}"
            vFileLOG=`ls -tr ${vFileLOG}*.LOG 2>/dev/null | tail -1`
            if [ -z "$vFileLOG" ]
            then
               echo "Proceso de Copia de Archivo de Reporte de Credito MasterCard no ejecutado"
            else
               f_msg "Archivo LOG: $vFileLOG"
               echo
               cat $vFileLOG
               echo
            fi
            echo "... presione [ENTER] para continuar."
            read vContinua
         fi
   fi # Opcion 6 - LOG de Reporte Credito MasterCard

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
