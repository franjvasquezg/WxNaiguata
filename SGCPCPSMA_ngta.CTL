LOAD DATA
APPEND
INTO TABLE TMP_MAESTRO_COMP_NGTA
WHEN MsgType = 'STRL' AND ind_carga = 'A'
(Nbr               RECNUM
,MsgType           POSITION(001:004)
,cod_moneda        POSITION(012:014)
,ind_carga         POSITION(016:016)
,impana_s87_accc   POSITION(027:040)
,numana_s75_accc   POSITION(041:048)
,impcar_s88_accc   POSITION(049:062)
,numcar_s76_accc   POSITION(063:070)
,ichaab_s105_accc  POSITION(071:084)
,nchaab_s107_accc  POSITION(085:092)
,ichaca_s106_accc  POSITION(093:106)
,nchaca_s108_accc  POSITION(107:114)
,cuocar_s110_accc  POSITION(123:134)
,cuoabo_s109_accc  POSITION(135:146)
,imp_neto          POSITION(164:177)
,tipo_saldo        POSITION(178:178)
)