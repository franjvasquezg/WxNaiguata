#!/bin/ksh

arch=$1
#test_send_diskR10.tx
USUARIOTMVE=$2 
CLAVETMVE=$3

COD_AMBIENTEm="ccal"
vPrefijo="/TDD/Entrada"
vPrefijo_Res="/TDD/Entrada/Respaldo"
COD_AMBIENTE2="Calidad"

#vPrefijoWin=`echo $vPrefijo_Res | sed -e 's/\//\//'`   ## quita la primera "/"
vPrefijoWin="\\TDD\\Entrada\\Respaldo"
echo "vPrefijoWin  $vPrefijoWin"
#echo "Inicio de Transferencia de archivo"
vRUTAWIN1="\\TDD\\Entrada\\Respaldo\\${arch}"  #"$vPrefijoWin\\${arch}"
echo                                                       ## $COD_AMBIENTE2   NUEVA VARIABLE DE AMBIENTE IPR1302
echo "vRUTAWIN1 "$vRUTAWIN1
echo
vRUTAWIN2="\\Procesos\\Compensacion Naiguata-MC\\${COD_AMBIENTE2}\\T461NA\\${arch}" ## $vpValRet_910\\$vArchDestB"
echo "vRUTAWIN2 "$vRUTAWIN2
echo
echo "SFTP_USER}" ${SFTP_USER}
echo "SFTP_IMC_NGTA" ${SFTP_IMC_NGTA}
#vCOPIAWIN=`ssh ${SFTP_USER}@${SFTP_IMC_NGTA} cmd.exe /C "C:\\MFESFTP\\transtmve $vRUTAWIN1 $vPrefijoWin $vRUTAWIN2 $USUARIOTMVE $CLAVETMVE"`
vCOPIAWIN=`ssh ${SFTP_USER}@${SFTP_IMC_NGTA} cmd.exe /R "R:\\dskclu02dt1\\GerenciaTsT-1 $vRUTAWIN1 $vPrefijoWin $vRUTAWIN2 $USUARIOTMVE $CLAVETMVE"`
vSTATT=$?
if [ "$vSTATT" != "0" ]
then
    echo 
    echo "error en la transferencia del archivo ${arch} del adquiriente  al Disco R de SRVCCSALC, favor revisar"
    echo "|-----------------------------------------------------------------------|" 
    echo   $vCOPIAWIN | tee -a $vFileLOG
    echo "|-----------------------------------------------------------------------|" 
else
    echo "Archivo ${arch} transferido correctamente al Servidor SRVCCSALC (R)"
fi

