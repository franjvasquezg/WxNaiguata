#!/bin/ksh

################################################################################
##
##  Nombre del Programa : conver_NGTA_T464.sh
##                Autor : Luis Nieto / Francisco Vasquez
##       Codigo Inicial : 09/03/2020
##          Descripcion : Conversro para archivos T464 para Compensacion de Maestro Naiguata
##
##  ======================== Registro de Modificaciones ========================
##
##  Fecha      Autor Version Descripcion de la Modificacion
##  ---------- ----- ------- ---------------------------------------------------
##  09/03/2020 LN/FV   1.50    Codigo Inicial
#
################################################################################

################################################################################
## DECLARACION DE DATOS, PARAMETROS DE EJECUCION Y VARIABLES DEL PROGRAMA
################################################################################

## Datos del Programa
################################################################################
fileT464="$1"

## Variables de Trabajo
################################################################################

header_t464="headert464.txt"
body1_t464="body1t464.txt"
body2_t464="body2t464.txt"
footer1a_t464="footer1at464.txt"
footer1b_t464="footer1bt464.txt"
footer2_t464="footer2t464.txt"
arch1_t464="arch1t464.txt"
arch_final_t464=${fileT464}_"conv"


################################################################################
## INICIO | PROCEDIMIENTO PRINCIPAL
################################################################################


awk -F  '/FHDR/' ${DIRIN}/${fileT464} | cut -c 1-500 | grep -v "REC" > ${DIRTMP}/headert464.txt
awk -F  '/REC/' ${DIRIN}/${fileT464} | cut -c 1-500 | grep -v "FHDR" > ${DIRTMP}/body1t464.txt
awk -F  '/REC/' ${DIRIN}/${fileT464} | cut -c 501-1000 | grep -v "STRL" > ${DIRTMP}/body2t464.txt


awk -F  '/STRL/' ${DIRIN}/${fileT464} | cut -c 1-250 | grep -v 'REC'| grep -v 'FTRL' | grep -i '9282A' >> ${DIRTMP}/footer1at464.txt
awk -F  '/STRL/' ${DIRIN}/${fileT464} | cut -c 251-500 | grep -v 'REC'| grep -v 'FTRL' | grep -i '9282A' >> ${DIRTMP}/footer1at464.txt 
awk -F  '/STRL/' ${DIRIN}/${fileT464} | cut -c 501-750 | grep -v 'REC'| grep -v 'FTRL' | grep -i '9282A' >> ${DIRTMP}/footer1at464.txt
awk -F  '/STRL/' ${DIRIN}/${fileT464} | cut -c 751-1000 | grep -v 'REC'| grep -v 'FTRL' | grep -i '9282A' >> ${DIRTMP}/footer1at464.txt


awk -F  '/STRL/' ${DIRIN}/${fileT464} | cut -c 1-250 | grep -v 'REC'| grep -v 'FTRL' | grep -i '9282N' >> ${DIRTMP}/footer1bt464.txt
awk -F  '/STRL/' ${DIRIN}/${fileT464} | cut -c 251-500 | grep -v 'REC'| grep -v 'FTRL' | grep -i '9282N' >> ${DIRTMP}/footer1bt464.txt
awk -F  '/STRL/' ${DIRIN}/${fileT464} | cut -c 501-750 | grep -v 'REC'| grep -v 'FTRL' | grep -i '9282N' >> ${DIRTMP}/footer1bt464.txt
awk -F  '/STRL/' ${DIRIN}/${fileT464} | cut -c 751-1000 | grep -v 'REC'| grep -v 'FTRL' | grep -i '9282N' >> ${DIRTMP}/footer1bt464.txt


awk -F  '/FTRL/' ${DIRIN}/${fileT464} | awk '{print substr($0,1,250)}' | grep -i 'FTRL' | grep -v 'STRL' >> ${DIRTMP}/footer2t464.txt
awk -F  '/FTRL/' ${DIRIN}/${fileT464} | awk '{print substr($0,251,250)}' | grep -i 'FTRL' | grep -v 'STRL' >> ${DIRTMP}/footer2t464.txt
awk -F  '/FTRL/' ${DIRIN}/${fileT464} | awk '{print substr($0,501,250)}' | grep -i 'FTRL' | grep -v 'STRL' >> ${DIRTMP}/footer2t464.txt
awk -F  '/FTRL/' ${DIRIN}/${fileT464} | awk '{print substr($0,751,250)}' | grep -i 'FTRL' | grep -v 'STRL' >> ${DIRTMP}/footer2t464.txt


cat ${DIRTMP}/headert464.txt > ${DIRTMP}/arch1t464.txt
cat ${DIRTMP}/body1t464.txt >> ${DIRTMP}/arch1t464.txt
cat ${DIRTMP}/body2t464.txt >> ${DIRTMP}/arch1t464.txt


awk -F  '/FHDR/' ${DIRTMP}/${arch1_t464} | cut -c 1-250 | grep -v "REC"> ${DIRTMP}/${arch_final_t464}
awk -F  '/SHDR/' ${DIRTMP}/${arch1_t464} | cut -c 251-500 | grep -v "REC" >> ${DIRTMP}/${arch_final_t464}
awk -F  '/REC/' ${DIRTMP}/${arch1_t464} | cut -c 1-250 | grep -v "STRL" >> ${DIRTMP}/${arch_final_t464}
awk -F  '/REC/' ${DIRTMP}/${arch1_t464} | cut -c 251-500 | grep -v "STRL" >> ${DIRTMP}/${arch_final_t464}

cat ${DIRTMP}/${footer1a_t464} >> ${DIRTMP}/${arch_final_t464} 
cat ${DIRTMP}/${footer1b_t464} >> ${DIRTMP}/${arch_final_t464}
cat ${DIRTMP}/${footer2_t464} >> ${DIRTMP}/${arch_final_t464}


cp ${DIRTMP}/${arch_final_t464}  ${DIRIN}

rm -rf ${DIRTMP}/*t464.txt
