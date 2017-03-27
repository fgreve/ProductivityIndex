********************************************************************************
***DISCLAIMER
*This code generates the oficial TFP measure of the Productivity Comission of Chile (CNP)
*The code was written for Stata 13.

*Author: Fernando Greve fgreve@cnp.gob.cl o fgreve@gmail.com 
********************************************************************************

********************************************************************************
*PACKAGE(s) requerido(s):
*ssc install labellist
*ssc install svret
*ssc install hprescott

*download renvars (not available in ssc)
*findit renvars
********************************************************************************

********************************************************************************
*PATHS
*Path 
global Path = "C:\Users\Fgreve\Dropbox\CNP\PTF_IPROD_2016" 

*CASEN Survey Path
global casen_Path   = "C:\Users\fgreve\Dropbox\CASEN" 
********************************************************************************

********************************************************************************
*SUPUESTOS DE LA ESTIMACION
*Se aproxima el dato del último IPOM como el crecimiento del PIB
*dato IPOM Sept-2016 (1.5%-2.0%): Se considera un crecimiento del PIB de 1.75%
*dato IPOM Dic-2016 (1.5%): Se considera un crecimiento del PIB de 1.5%
scalar Ygr2016 =  1.015

*Se aproxima el dato del último IPOM como el crecimiento del PIB
*dato IPOM Sept-2016 (1.5%-2.0%): Se considera un crecimiento del PIB de 1.75%
*dato IPOM Dic-2016 (1.5%): Se considera un crecimiento del PIB de 1.5%
scalar YCFgr2016 =  1.015

*A partir de los anterior se estima el PIB sin minería
scalar YCFgr2016 =  1.015

*de los supuestos anteriores y suponiendo una cierta proporción se obtienen los 
*siguientes valores de PIB sin mineria
scalar YSMgr2015  = 1.0268 
scalar YSMgr2016  = 1.0256 

*Se supone un crecimiento del capital de aprox. 4.0%
*crecimiento de la inversión agregada de -0.6% en 2016 FBCF (var%) IPOM Dic 2016
scalar K2016 = 301925.543  
scalar Igr2016 = (1-0.006)

*Se suponen los siguientes valores para 2015 y 2016
scalar KM2015 = 54796540 
scalar KM2016 = 57711424 

*para el año 2016 se estima un crecimiento del trabajo equivalente al del 
*promedio hasta el trimestre que se tiene informacion 
*Se que las horas trabajadas promedio del 2016 equivalen a las de 2015
scalar Lgr2016 = (1+0.013) 
scalar Ngr2016 = (1+0.013) 
scalar Hgr2016 = (1+0.0) 

scalar LSMgr2015 = 1.0194
scalar LSMgr2016 = 1.0139

*replace KSM_cnp = 235570.650 if year==2015
*replace KSM_cnp = 244214.119 if year==2016
scalar KSM2015 = 235570.650 
scalar KSM2016 = 244214.119 

*Se suponen los siguientes valores para 2015 y 2016
scalar KM2015 = 54796.540 
scalar KM2016 = 57711.424 
********************************************************************************

********************************************************************************
*YCF_cnp
import excel "${Path}\BC.xls", ///
sheet(YCF) cellrange(A1:G27) firstrow clear
gen year=year(Periodo)
drop Periodo
order year, first
rename ProductoInternoBrutoCF YCF_cnp

*genera 2016
local N = `=_N' +1
set obs `N'
replace year=2016 in `N'
tset year
replace YCF_cnp = L.YCF_cnp * YCFgr2016 if year==2016

keep year YCF_cnp
save "${Path}/YCF_cnp.dta", replace
********************************************************************************

********************************************************************************
*YSM_cnp

*EH-CLIO-LAB para obtener series 1990-1995
import excel "${Path}\BC.xls", ///
sheet(YCF) cellrange(A1:G27) firstrow clear
gen year=year(Periodo)
drop Periodo
order year, first
rename ProductoInternoBrutoCFsinMi YSM_ecl
keep year YSM_ecl
save "${Path}/YSEC_ecl.dta", replace


*series de pib sectoriales del BC
import excel "${Path}\BC.xls", ///
sheet(YSEC) cellrange(A3:N23) firstrow clear
gen year=year(Periodo)
drop Periodo
order year, first

rename Agropecuariosilvcola YAGR
rename Pesca YFISH

rename Minera YMIN
rename IndustriaManufacturera YMAN
rename Electricidadgasyagua YUT
rename Construccin YCON
rename Comerciorestaurantesyhote YCOM
rename Administracinpblica YGOV

rename Transporte YTRA
rename Comunicaciones YCES

rename Serviciosfinancierosyempr YSFE
rename Serviciosdevivienda YSVV
rename Serviciospersonales YSPS

ds year, not
renvars `r(varlist)',  postfix(e)
save "${Path}/YSECe.dta", replace



*YSECpc (base 2008)
import excel "${Path}\BC.xls", ///
sheet(YSECpc) cellrange(A3:N23) firstrow clear
gen year=year(Periodo)
drop Periodo
order year, first

rename Agropecuariosilvcola YAGR
rename Pesca YFISH

rename Minera YMIN
rename IndustriaManufacturera YMAN
rename Electricidadgasyagua YUT
rename Construccin YCON
rename Comerciorestaurantesyhote YCOM

rename Transporte YTRA
rename Comunicaciones YCES

rename Administracinpblica YGOV
rename Serviciosfinancierosyempr YSFE
rename Serviciosdevivienda YSVV
rename Serviciospersonales YSPS

gen YAYP = YAGR + YFISH
gen YSERV = YSFE + YSVV + YSPS + YGOV
gen YTYC = YTRA + YCES

*keep year YAYP YMIN YMAN YUT YCON YCOM YSERV YTYC
ds year, not
renvars `r(varlist)',  postfix(pc2008)
save "${Path}/YSECpc.dta", replace



*finalmente SE ENCADENADA
use "${Path}/YSECe.dta", clear
merge 1:1 year using "${Path}/YSECpc.dta", nogen 
tset year

***genera base movil
local Sector "YAGR YFISH YMIN YMAN YUT YCON YCOM YGOV YTRA YCES YSFE YSVV YSPS"
foreach x of local Sector {
	gen `x'bm = L.`x'pc * `x'e / L.`x'e   	
	}
**GENERA LAS 3 SERIES ENCADENADAS
*Agricultura y Pesca
gen YAYPbm = YAGRbm + YFISHbm

*Servicios
gen YSERVbm = YSFEbm + YSVVbm + YSPSbm + YGOVbm

*Transporte y Comunicaciones
gen YTYCbm = YTRAbm + YCESbm	
	
local Sector "YAYP YTYC YSERV"
foreach x of local Sector {
	gen `x'e =.
	replace `x'e = `x'pc if year==2008 

	forv i = 2009/2015 {
		quiet replace `x'e = L.`x'e * `x'bm / L.`x'pc  if year==`i' 
	}
	forvalues i = 2007(-1)1996 {
		quiet replace `x'e = F.`x'e * `x'pc / F.`x'bm  if year==`i' 
	}	
}

*Ahora se genera la serie de PIB SIN MINERIA encadenada
gen YSMpc = YAYPpc +YMANpc +YUTpc +YCONpc +YCOMpc +YTYCpc +YSERVpc
gen YSMbm = YAYPbm +YMANbm +YUTbm +YCONbm +YCOMbm +YTYCbm +YSERVbm

gen YSMbm_cnp = YSMbm
gen YSMpc_cnp = YSMpc

gen YSMe_cnp =.
replace YSMe_cnp = YSMpc_cnp if year==2008 

forv i = 2009/2015 {
	quiet replace YSMe_cnp = L.YSMe_cnp * YSMbm_cnp / L.YSMpc_cnp  if year==`i' 
	}
forvalues i = 2007(-1)1996 {
	quiet replace YSMe_cnp = F.YSMe_cnp * YSMpc_cnp / F.YSMbm_cnp  if year==`i' 
	}

gen YSM_cnp = YSMe_cnp
merge 1:1 year using "${Path}/YSEC_ecl.dta", nogen
sort year
replace	YSM_cnp = YSM_ecl if year<=1995

*genera 2016 y se imponen los supuestos
local N = `=_N' +1
set obs `N'
replace year=2016 in `N'
tset year
replace YSM_cnp  = L.YSM_cnp * YSMgr2015 if year==2015 
replace YSM_cnp  = L.YSM_cnp * YSMgr2016 if year==2016   

keep year YSM_cnp
save "${Path}/YSM_cnp.dta", replace
********************************************************************************


********************************************************************************
*K_cnp
import excel ///
"${Path}\BC.xls", ///
sheet(K) cellrange(A3:E34) firstrow clear
gen year=year(Periodo)
drop Periodo
order year, first
   
rename Stockdecapitalneto  K_bc    
replace K_bc = K_bc/1000
save "${Path}/K_bc.dta", replace

*a partir de la serie del central se define la serie CNP
use "${Path}/K_bc.dta", replace
sort year
tset year
gen K_cnp = K_bc

*Se construye una serie de la diferencia del capital por periodo
gen Kdelta = D.K_cnp

*genera 2016
local N = `=_N' +1
set obs `N'
replace year=2016 in `N'
sort year

*se utiliza el dato del IPOM crecimiento de inversión de -0.6%
replace Kdelta = L.Kdelta * Igr2016  if year==2016
replace K_cnp = L.K_cnp + Kdelta if year==2016
*replace K_cnp = K2016   if year==2016

keep year K_cnp
save "${Path}/K_cnp.dta", replace
********************************************************************************

********************************************************************************
*KM_cnp
import excel "${Path}\BC.xls", ///
sheet(STOCK CAPITAL) cellrange(A1:C27) firstrow clear
gen year=year(Periodo)
drop Periodo
order year, first
rename StockNetoMineria KM_cnp
tset year

*genera 2016
local N = `=_N' +1
set obs `N'
replace year=2016 in `N'

replace KM_cnp = KM2015 if year==2015
replace KM_cnp = KM2016 if year==2016

keep year KM_cnp
save "${Path}/KM_cnp.dta", replace
********************************************************************************

********************************************************************************
*NM_cnp Nivel de empleo en mineria en miles
*Perez Villalobos
import excel "${Path}\BC.xls", ///
sheet(EMPLEO HORAS) cellrange(A1:I27) firstrow clear
gen year=year(Periodo)
drop Periodo
order year, first
rename EMPLEOMINERIAPEREZVILLALOBO NM_cnp
rename HHsinMineria HSM_cnp
keep year NM_cnp HSM_cnp

save "${Path}/NM_cnp.dta", replace
********************************************************************************

********************************************************************************
*AJLSM_cnp

*UF_bc
import excel ///
"${Path}\BC.xls", ///
sheet(UF) cellrange(A3:B29) firstrow clear
gen year=year(Periodo)
drop Periodo
order year, first
rename  UnidaddefomentoUF UF_bc
save "${Path}/UF_bc.dta", replace

*casen1990
*0 sin educ.formal; 1 basica incom.; 2 basica compl.; 3 m.hum. incompleta; 
*4 m.tec.prof. incompleta; 5 m.hum. completa.; 6 m.tec completa; 
*7 tec. o univ.inc.; 8 tecnica completa; 9 univ. completa; 11 ens.especial; 
*12 sin dato 
use "${casen_Path}\casen1990.dta", clear
keep if rama!=1
gen educ7=.
replace educ7=1 if educ==0
replace educ7=2 if educ==1
replace educ7=3 if educ==2
replace educ7=4 if educ==3 | educ==4
replace educ7=5 if educ==5 | educ==6
replace educ7=6 if educ==7
replace educ7=7 if educ==8 | educ==9
rename ytrabaj salario
rename jh horas 
keep(educ7 salario horas expr)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen1990_nm.dta", replace

*casen1992
*0 sin educacion, formal; 1 basica incompleta; 2 basica completa; 
*3 media humanista incompleta; 4 media tecnica profesional incompleta; 
*5 media humanista completa; 6 media tecnica completa; 
*7 tecnica o universitaria incompleta; 8 tecnica o universitaria completa; 
*99 sin dato 
use "${casen_Path}\casen1992.dta", clear
keep if rama!=2
gen educ7=.
replace educ7=1 if educ==0
replace educ7=2 if educ==1
replace educ7=3 if educ==2
replace educ7=4 if educ==3 | educ==4
replace educ7=5 if educ==5 | educ==6
replace educ7=6 if educ==7
replace educ7=7 if educ==8 | educ==9
rename ytrabaj salario
rename o14 horas 
keep(educ7 salario horas expr)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen1992_nm.dta", replace

*casen1994
*1 preescolar; 2 basica incompleta; 3 basica completa; 4 educacion diferencial; 
*5 media humanistica incompleta; 6 media humanistica completa; 
*7 media tecnica profesional incompleta; 8 media tecnica profesional completa
*9 universitaria incompleta; 10 universitaria completa; 
*11 instituto profesional o cft incompleto; 
*12 instituto profesional o cft completo; 13 universitaria postgrado; 
*14 academia y otros; 15 ninguno (analfabeto); 99 no sabe 
use "${casen_Path}\casen1994.dta", clear
keep if rama!=2
rename e9 educ 
gen educ7=.
replace educ7=1 if educ==15
replace educ7=2 if educ==2
replace educ7=3 if educ==3
replace educ7=4 if educ==5 | educ==7
replace educ7=5 if educ==6 | educ==8
replace educ7=6 if educ==9 | educ==11
replace educ7=7 if educ==10 | educ==12 | educ==13 | educ==14
drop if educ7==.
rename ytrabaj salario
rename o14 horas 
keep(educ7 salario horas expr)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen1994_nm.dta", replace

*casen1996
*0 ninguno; 1 educacion preescolar; 2 preparatoria (sist.ant); 3 basica
*4 b. diferencial; 5 humanidades (sist.ant); 6 media c.hum.
*7 tec./com.ind.(sist. a); 8 media/tec.prof.; 9 c.f.tecnica inc.
*10 c.f.tecnica comp; 11 ins.profesional incomp.; 12 ins.profesional completo
*13 univ.incompleta; 14 univ. completa; 15 iniv. postgrado; 99 no sabe
use "${casen_Path}\casen1996.dta", clear
keep if rama!=2
rename e6 educ 
gen educ7=.
replace educ7=1 if educ==0
replace educ7=2 if educ==1
replace educ7=3 if educ==2 | educ==3 | educ==4
replace educ7=5 if educ==5 | educ==6 | educ==7 | educ==8
replace educ7=6 if educ==9 | educ==11| educ==13
replace educ7=7 if educ==10| educ==12| educ==14
drop if educ7==.
rename ytrabaj salario
rename o19 horas
replace horas = horas/4 
keep(educ7 salario horas expr)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen1996_nm.dta", replace

*casen1998
*0 sin educacion formal; 1 basica incompleta; 2 basica completa
*3 media humanista incompleta; 4 media tecnica profesional incompleta
*5 media humanista completa; 6 media tecnica completa
*7 tecnica o universitaria incompleta; 8 tecnica completa
*9 universitaria completa; 10 sin dato
use "${casen_Path}\casen1998.dta", clear
keep if rama!=2
gen educ7=.
replace educ7=1 if educ==0
replace educ7=2 if educ==1
replace educ7=3 if educ==2
replace educ7=4 if educ==3 | educ==4
replace educ7=5 if educ==5 | educ==6
replace educ7=6 if educ==7
replace educ7=7 if educ==8
replace educ7=7 if educ==9
drop if educ7==.
rename ytrabaj salario
rename o17 horas 
replace horas = horas/4
keep(educ7 salario horas expr)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen1998_nm.dta", replace

*casen2000
*1 sin educcacion formal; 2 basica incompleta; 3 basica completa.
*4 media c/h incompleto; 5 media c/h completo; 6 media t/p incompleto
*7 media t/p completo; 8 c.f.t/i.p incompleta.; 9 c.f.t/i.p completa.
*10 universidad incompleta; 11 universidad completa; 99 sin dato
use "${casen_Path}\casen2000.dta", clear
keep if rama!=2
gen educ7=.
replace educ7=1 if educ==1
replace educ7=2 if educ==2
replace educ7=3 if educ==3
replace educ7=4 if educ==4 | educ==6
replace educ7=5 if educ==5 | educ==7
replace educ7=6 if educ==8 | educ==10
replace educ7=7 if educ==11
drop if educ7==.
rename ytrabaj salario
rename o19h horas 
replace horas = horas/4
keep(educ7 salario horas expr)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen2000_nm.dta", replace

*casen2003
*1 sin educacion formal; 2 basica incompleta; 3 basica completa.
*4 media c/h incompleto; 5 media c/h completo; 6 media t/p incompleto
*7 media t/p completo; 8 c.f.t/i.p incompleta.; 9 c.f.t/i.p completa.
*10 universidad incompleta; 11 universidad completa; 99 sin dato
use "${casen_Path}\casen2003.dta", clear
keep if rama!=2
gen educ7=.
replace educ7=1 if educ==1
replace educ7=2 if educ==2
replace educ7=3 if educ==3
replace educ7=4 if educ==4 | educ==6
replace educ7=5 if educ==5 | educ==7
replace educ7=6 if educ==8 | educ==10
replace educ7=7 if educ==11
drop if educ7==.
rename yopraj salario
rename o19_hrs horas
replace horas = horas/4 
keep(educ7 salario horas expr)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen2003_nm.dta", replace

*casen2006
*0 sin educ. formal; 1 basica incom.; 2 basica compl.; 3 m.hum. incompleta
*4 m.tec.prof. incompleta; 5 m.hum. completa; 6 m.tec completa
*7 tec. o univ. incompleta.; 8 tecnica o univ. completa; 99 sin dato
use "${casen_Path}\casen2006.dta", clear
keep if rama!=2
gen educ7=.
replace educ7=1 if educ==0
replace educ7=2 if educ==1
replace educ7=3 if educ==2
replace educ7=4 if educ==3 | educ==4
replace educ7=5 if educ==5 | educ==6
replace educ7=6 if educ==7
replace educ7=7 if educ==8
drop if educ7==.
rename yopraj salario
rename o15 horas 
keep(educ7 salario horas expr)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen2006_nm.dta", replace

*casen2009
*1 sin educacion formal; 2 basica incompleta; 3 basica completa
*4 media humanista incompleta; 5 media tecnico profesional incompleta
*6 media humanista completa; 7 media tecnico completa
*8 tecnica o universitaria incompleta; 9 tecnica o universitaria completa
use "${casen_Path}\casen2009.dta", clear
keep if rama!=2
gen educ7=.
replace educ7=1 if educ==1
replace educ7=2 if educ==2
replace educ7=3 if educ==3 
replace educ7=4 if educ==4 | educ==5
replace educ7=5 if educ==6 | educ==7
replace educ7=6 if educ==8
replace educ7=7 if educ==9
drop if educ7==.
rename yopraj salario
rename o16 horas 
keep(educ7 salario horas expr)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen2009_nm.dta", replace

*casen2011
*0 sin educ. formal; 1 basica incom.; 2 basica compl.; 3 m. hum. incompleta
*4 m. tec. prof. incompleta; 5 m. hum. completa; 6 m. tec completa
*7 tecnico nivel superior o profesional i
*8 tecnico nivel superior o profesional c
use "${casen_Path}\casen2011.dta", clear
keep if rama1!=3
gen educ7=.
replace educ7=1 if educ==0
replace educ7=2 if educ==1
replace educ7=3 if educ==2 
replace educ7=4 if educ==3 | educ==4
replace educ7=5 if educ==5 | educ==6
replace educ7=6 if educ==7
replace educ7=7 if educ==8
drop if educ7==.
rename yopraj salario
rename o10 horas
rename expr_r2 expr 
keep(educ7 salario horas expr)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen2011_nm.dta", replace

*casen2013
*0 sin educ. formal; 1 basica incom.; 2 basica compl.; 3 m. hum. incompleta
*4 m. tec. prof. incompleta; 5 m. hum. completa; 6 m. tec completa
*7 tecnico nivel superior incompleta; 8 tecnico nivel superior completo
*9 profesional incompleto; 10 postgrado incompleto; 11 profesional completo
*12 postgrado completo; 99 ns/nr
use "${casen_Path}\casen2013.dta", clear
keep if rama1!=3
gen educ7=.
replace educ7=1 if educ==0
replace educ7=2 if educ==1
replace educ7=3 if educ==2 
replace educ7=4 if educ==3 | educ==4
replace educ7=5 if educ==5 | educ==6
replace educ7=6 if educ==7 | educ==9
replace educ7=7 if educ==8 | educ==10 | educ==11 | educ==12
drop if educ7==.
rename ytrabajocor salario
rename o10 horas 
keep(educ7 salario horas expr)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen2013_nm.dta", replace

*casen2015
*0 sin educ. formal; 1 basica incom.; 2 basica compl.; 3 m. hum. incompleta 
*4 m. tec. prof. incompleta; 5 m. hum. completa; 6 m. tec completa 
*7 tecnico nivel superior incompleta; 8 tecnico nivel superior completo 
*9 profesional incompleto; 10 postgrado incompleto; 11 profesional completo 
*12 postgrado completo; 99 ns/nr 
use "${casen_Path}\casen2015.dta", clear
keep if rama1!=3
gen educ7=.
replace educ7=1 if educ==0
replace educ7=2 if educ==1
replace educ7=3 if educ==2 
replace educ7=4 if educ==3 | educ==4
replace educ7=5 if educ==5 | educ==6
replace educ7=6 if educ==7 | educ==9
replace educ7=7 if educ==8 | educ==10 | educ==11 | educ==12
drop if educ7==.
rename ytrabajocor salario
rename o10 horas 
keep(educ7 salario horas expr)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen2015_nm.dta", replace


set more off
local year_casen "1990 1992 1994 1996 1998 2000 2003 2006 2009 2011 2013 2015"
foreach Year of local year_casen {

use "${Path}\casen`Year'_nm.dta",clear

gen educ4=.
replace educ4=1 if educ7==1 | educ7==2
replace educ4=2 if educ7==3 | educ7==4
replace educ4=3 if educ7==5 | educ7==6 
replace educ4=4 if educ7==7 
drop if educ4==.

gen person= 1
gen Nhat = _N

collapse (mean) Nhat salario horas (sum) person  [w=expr], by(educ4)

forvalues e = 1(1)4{
	gen w`e'    =.
	gen Nhat`e' =.
	gen h`e'    =.
	
	quiet replace w`e'    = salario[`e'] in 1 
	quiet replace Nhat`e' = person[`e'] in 1
	quiet replace h`e'    = horas[`e'] in 1
}
gen year =`Year'
order year, first	
save "${Path}\c`Year'_nm.dta", replace
}
*
set more off
local year_casen "1990 1992 1994 1996 1998 2000 2003 2006 2009 2011 2013 2015"
foreach Year of local year_casen {
use "${Path}\c`Year'_nm.dta", clear
keep in 1
drop educ4 salario horas person
save "${Path}\cas`Year'_nm.dta", replace
}
*
set more off
use "${Path}\cas1990_nm.dta",clear
local year_casen "1992 1994 1996 1998 2000 2003 2006 2009 2011 2013 2015"
foreach Year of local year_casen {
append using "${Path}\cas`Year'_nm.dta"
}
order year, first 
save "${Path}\casen_nm.dta", replace

use "${Path}\casen_nm.dta", clear

merge m:m year using "${Path}\UF_bc.dta", nogenerate
drop if Nhat==.
replace w1=w1/UF_bc
replace w2=w2/UF_bc
replace w3=w3/UF_bc
replace w4=w4/UF_bc
save "${Path}\casen_data_nm.dta", replace

use "${Path}\casen_data_nm.dta", clear 

*1990
expand 2 in 1
replace year=1991 in `=_N'
sort year

*1992
expand 2 in 3
replace year=1993 in `=_N'
sort year

*1994
expand 2 in 5
replace year=1995 in `=_N'
sort year

*1996
expand 2 in 7
replace year=1997 in `=_N'
sort year

*1998
expand 2 in 9
replace year=1999 in `=_N'
sort year

*2000
expand 2 in 11
replace year=2001 in `=_N'
sort year

expand 2 in 11
replace year=2002 in `=_N'
sort year

*2003
expand 2 in 14
replace year=2004 in `=_N'
sort year

expand 2 in 14
replace year=2005 in `=_N'
sort year

*2006
expand 2 in 17
replace year=2007 in `=_N'
sort year

expand 2 in 17
replace year=2008 in `=_N'
sort year

*2009
expand 2 in 20
replace year=2010 in `=_N'
sort year

*2011
expand 2 in 22
replace year=2012 in `=_N'
sort year

*2013
expand 2 in 24
replace year=2014 in `=_N'
sort year

gen h = h1+h2+h3+h4

tsset year, yearly

gen Nhat1_share = Nhat1 / Nhat
gen Nhat2_share = Nhat2 / Nhat
gen Nhat3_share = Nhat3 / Nhat
gen Nhat4_share = Nhat4 / Nhat

gen AJL_cnp_sum = Nhat1_share *w1/w1 + Nhat2_share *w2/w1 + Nhat3_share * w3/w1 + Nhat4_share *w4/w1
gen Ln_AJL_cnp=ln(AJL_cnp_sum)
tsset year, yearly

gen year2 = year * year

gen ttrend=(year-1989)
gen ttrend2=ttrend*ttrend
gen ttrend3=ttrend2*ttrend

qreg Ln_AJL_cnp ttrend ttrend2
scalar b1=_b[ttrend]
scalar b2=_b[ttrend2]
scalar b0=_b[_cons]

gen logAJL_cnp_trend = b0 + ttrend * b1 + ttrend2 * b2

gen AJL_cnp_trend = exp(logAJL_cnp_trend)

rename AJL_cnp_trend AJLSM_cnp

*para el año 2016 se asume un crecimiento de calidad del trabajo igual que 2015
local N = `=_N' +1
set obs `N'
replace year=2016 in `N'
sort year

*replace AJLSM_cnp = L.AJLSM_cnp * 1.0028   if year==2015
*replace AJLSM_cnp = L.AJLSM_cnp * 1.0027   if year==2016

replace AJLSM_cnp = L.AJLSM_cnp * L.AJLSM_cnp / L2.AJLSM_cnp   if year==2016

rename w1 w1sm_cnp
rename w2 w2sm_cnp
rename w3 w3sm_cnp
rename w4 w4sm_cnp

rename Nhat1 N1sm_cnp
rename Nhat2 N2sm_cnp
rename Nhat3 N3sm_cnp
rename Nhat4 N4sm_cnp

save "${Path}/AJLSM_cnp.dta", replace
********************************************************************************

********************************************************************************
*L_cnp
import excel "${Path}\BC.xls", ///
sheet(EMPLEO HORAS) cellrange(A1:I27) firstrow clear
gen year=year(Periodo)
drop Periodo
tset year
order year, first

rename EMPALMEEMPLEOEMPALMENENE N_cnp /*EMPALME INE AGREGADO*/
rename HHEMPLEOTOTAL H_cnp /*HORAS TOTALES INE*/
*rename INEEMPLEOSECTORIALEMPALMADOS N_cnp /*EMPALME INE A PARTIR DE SECTORIAL*/
rename HHsinMineria HSM_cnp
rename EMPLEOMINERIAPEREZVILLALOBO NM_cnp

keep if year>=1990 & year<=2015

gen L_cnp = N_cnp * H_cnp

*genera ano 2016
local N = `=_N' +1
set obs `N'
replace year=2016 in `N'
sort year

*para el año 2016 se estima un crecimiento del trabajo
keep year N_cnp H_cnp L_cnp HSM_cnp NM_cnp 

replace L_cnp = L.L_cnp * Lgr2016 if year==2016
replace N_cnp = L.N_cnp * Ngr2016  if year==2016

*suponemos que las horas permanecen constantes.
replace H_cnp = L.H_cnp   if year==2016

keep year N_cnp H_cnp L_cnp
save "${Path}/L_cnp.dta", replace
********************************************************************************

********************************************************************************
*LSM_cnp
import excel "${Path}\BC.xls", ///
sheet(EMPLEO HORAS) cellrange(A1:I27) firstrow clear
gen year=year(Periodo)
drop Periodo
tset year
order year, first

rename EMPALMEEMPLEOEMPALMENENE N_cnp /*EMPALME INE AGREGADO*/
rename HHEMPLEOTOTAL H_cnp /*HORAS TOTALES INE*/
*rename INEEMPLEOSECTORIALEMPALMADOS N_cnp /*EMPALME INE A PARTIR DE SECTORIAL*/
rename HHsinMineria HSM_cnp
rename EMPLEOMINERIAPEREZVILLALOBO NM_cnp

keep if year>=1990 & year<=2015

gen NSM_cnp= N_cnp - NM_cnp
gen LSM_cnp=HSM_cnp*(N_cnp-NM_cnp)
sort year

*genera ano 2016
local N = `=_N' +1
set obs `N'
replace year=2016 in `N'
sort year

*supuestos
replace LSM_cnp = L.LSM_cnp * LSMgr2015 if year==2015
replace LSM_cnp = L.LSM_cnp * LSMgr2016 if year==2016
  
replace NSM_cnp = L.NSM_cnp * LSMgr2015 if year==2015
replace NSM_cnp = L.NSM_cnp * LSMgr2016 if year==2016  
  
*suponemos que las horas permanecen constantes.
replace HSM_cnp = L.HSM_cnp   if year==2015  
replace HSM_cnp = L.HSM_cnp   if year==2016
  
keep year NSM_cnp HSM_cnp LSM_cnp  
save "${Path}/LSM_cnp.dta", replace
********************************************************************************

********************************************************************************
*AJL_cnp

*casen1990
*0 sin educ.formal; 1 basica incom.; 2 basica compl.; 3 m.hum. incompleta 
*4 m.tec.prof. incompleta; 5 m.hum. completa.; 6 m.tec completa
*7 tec. o univ.inc.; 8 tecnica completa; 9 univ. completa; 11 ens.especial 
*12 sin dato 
use "${casen_Path}\casen1990.dta", clear
gen educ7=.
replace educ7=1 if educ==0
replace educ7=2 if educ==1
replace educ7=3 if educ==2
replace educ7=4 if educ==3 | educ==4
replace educ7=5 if educ==5 | educ==6
replace educ7=6 if educ==7
replace educ7=7 if educ==8 | educ==9
rename ytrabaj salario
rename jh horas 
keep(educ7 salario horas  expr)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen1990_.dta", replace

*casen1992
*0 sin educacion, formal; 1 basica incompleta; 2 basica completa
*3 media humanista incompleta; 4 media tecnica profesional incompleta 
*5 media humanista completa; 6 media tecnica completa 
*7 tecnica o universitaria incompleta; 8 tecnica o universitaria completa 
*99 sin dato 
use "${casen_Path}\casen1992.dta", clear
gen educ7=.
replace educ7=1 if educ==0
replace educ7=2 if educ==1
replace educ7=3 if educ==2
replace educ7=4 if educ==3 | educ==4
replace educ7=5 if educ==5 | educ==6
replace educ7=6 if educ==7
replace educ7=7 if educ==8 | educ==9
rename ytrabaj salario
rename o14 horas 
keep(educ7 salario horas expr)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen1992_.dta", replace

*casen1994
*1 preescolar; 2 basica incompleta; 3 basica completa; 4 educacion diferencial 
*5 media humanistica incompleta; 6 media humanistica completa
*7 media tecnica profesional incompleta; 8 media tecnica profesional completa
*9 universitaria incompleta; 10 universitaria completa 
*11 instituto profesional o cft incompleto
*12 instituto profesional o cft completo; 13 universitaria postgrado 
*14 academia y otros 
*15 ninguno (analfabeto)
*99 no sabe 
use "${casen_Path}\casen1994.dta", clear
rename e9 educ 
gen educ7=.
replace educ7=1 if educ==15
replace educ7=2 if educ==2
replace educ7=3 if educ==3
replace educ7=4 if educ==5 | educ==7
replace educ7=5 if educ==6 | educ==8
replace educ7=6 if educ==9 | educ==11
replace educ7=7 if educ==10 | educ==12 | educ==13 | educ==14
drop if educ7==.
rename ytrabaj salario
rename o14 horas 
keep(educ7 salario horas expr)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen1994_.dta", replace

*casen1996
*0 ninguno; 1 educacion preescolar; 2 preparatoria (sist.ant); 3 basica
*4 b. diferencial; 5 humanidades (sist.ant); 6 media c.hum.
*7 tec./com.ind.(sist. a); 8 media/tec.prof.; 9 c.f.tecnica inc.
*10 c.f.tecnica comp; 11 ins.profesional incomp.; 12 ins.profesional completo
*13 univ.incompleta; 14 univ. completa; 15 iniv. postgrado; 99 no sabe
use "${casen_Path}\casen1996.dta", clear
rename e6 educ 
gen educ7=.
replace educ7=1 if educ==0
replace educ7=2 if educ==1
replace educ7=3 if educ==2 | educ==3 | educ==4
*replace educ7=4
replace educ7=5 if educ==5 | educ==6 | educ==7 | educ==8
replace educ7=6 if educ==9 | educ==11| educ==13
replace educ7=7 if educ==10| educ==12| educ==14
drop if educ7==.
rename ytrabaj salario
rename o19 horas
replace horas = horas/4 
keep(educ7 salario horas expr)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen1996_.dta", replace

*casen1998
*0 sin educacion formal; 1 basica incompleta; 2 basica completa
*3 media humanista incompleta; 4 media tecnica profesional incompleta
*5 media humanista completa; 6 media tecnica completa
*7 tecnica o universitaria incompleta; 8 tecnica completa;
*9 universitaria completa; 10 sin dato
use "${casen_Path}\casen1998.dta", clear
gen educ7=.
replace educ7=1 if educ==0
replace educ7=2 if educ==1
replace educ7=3 if educ==2
replace educ7=4 if educ==3 | educ==4
replace educ7=5 if educ==5 | educ==6
replace educ7=6 if educ==7
replace educ7=7 if educ==8
replace educ7=7 if educ==9
drop if educ7==.
rename ytrabaj salario
rename o17 horas 
replace horas = horas/4
keep(educ7 salario horas expr)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen1998_.dta", replace

*casen2000
*1 sin educcacion formal; 2 basica incompleta; 3 basica completa.
*4 media c/h incompleto; 5 media c/h completo; 6 media t/p incompleto
*7 media t/p completo; 8 c.f.t/i.p incompleta.; 9 c.f.t/i.p completa.
*10 universidad incompleta; 11 universidad completa; 99 sin dato
use "${casen_Path}\casen2000.dta", clear
gen educ7=.
replace educ7=1 if educ==1
replace educ7=2 if educ==2
replace educ7=3 if educ==3
replace educ7=4 if educ==4 | educ==6
replace educ7=5 if educ==5 | educ==7
replace educ7=6 if educ==8 | educ==10
replace educ7=7 if educ==11
drop if educ7==.
rename ytrabaj salario
rename o19h horas 
replace horas = horas/4
keep(educ7 salario horas expr)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen2000_.dta", replace

*casen2003
*1 sin educacion formal; 2 basica incompleta; 3 basica completa.
*4 media c/h incompleto; 5 media c/h completo; 6 media t/p incompleto
*7 media t/p completo 8 c.f.t/i.p incompleta.; 9 c.f.t/i.p completa.
*10 universidad incompleta; 11 universidad completa; 99 sin dato
use "${casen_Path}\casen2003.dta", clear
gen educ7=.
replace educ7=1 if educ==1
replace educ7=2 if educ==2
replace educ7=3 if educ==3
replace educ7=4 if educ==4 | educ==6
replace educ7=5 if educ==5 | educ==7
replace educ7=6 if educ==8 | educ==10
replace educ7=7 if educ==11
drop if educ7==.
rename yopraj salario
rename o19_hrs horas
replace horas = horas/4 
keep(educ7 salario horas expr)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen2003_.dta", replace

*casen2006
*0 sin educ. formal; 1 basica incom.; 2 basica compl.; 3 m.hum. incompleta
*4 m.tec.prof. incompleta; 5 m.hum. completa; 6 m.tec completa
*7 tec. o univ. incompleta.; 8 tecnica o univ. completa; 99 sin dato
use "${casen_Path}\casen2006.dta", clear
gen educ7=.
replace educ7=1 if educ==0
replace educ7=2 if educ==1
replace educ7=3 if educ==2
replace educ7=4 if educ==3 | educ==4
replace educ7=5 if educ==5 | educ==6
replace educ7=6 if educ==7
replace educ7=7 if educ==8
drop if educ7==.
rename yopraj salario
rename o15 horas 
keep(educ7 salario horas expr)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen2006_.dta", replace

*casen2009
*1 sin educacion formal; 2 basica incompleta; 3 basica completa
*4 media humanista incompleta; 5 media tecnico profesional incompleta
*6 media humanista completa;7 media tecnico completa
*8 tecnica o universitaria incompleta; 9 tecnica o universitaria completa
use "${casen_Path}\casen2009.dta", clear
gen educ7=.
replace educ7=1 if educ==1
replace educ7=2 if educ==2
replace educ7=3 if educ==3 
replace educ7=4 if educ==4 | educ==5
replace educ7=5 if educ==6 | educ==7
replace educ7=6 if educ==8
replace educ7=7 if educ==9
drop if educ7==.
rename yopraj salario
rename o16 horas 
keep(educ7 salario horas expr)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen2009_.dta", replace

*casen2011
*0 sin educ. formal; 1 basica incom.; 2 basica compl.; 3 m. hum. incompleta
*4 m. tec. prof. incompleta; 5 m. hum. completa; 6 m. tec completa
*7 tecnico nivel superior o profesional i
*8 tecnico nivel superior o profesional c
use "${casen_Path}\casen2011.dta", clear
gen educ7=.
replace educ7=1 if educ==0
replace educ7=2 if educ==1
replace educ7=3 if educ==2 
replace educ7=4 if educ==3 | educ==4
replace educ7=5 if educ==5 | educ==6
replace educ7=6 if educ==7
replace educ7=7 if educ==8
drop if educ7==.
rename yopraj salario
rename o10 horas 
keep(educ7 salario horas expr_r2)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen2011_.dta", replace

*casen2013
*0 sin educ. formal; 1 basica incom.; 2 basica compl.; 3 m. hum. incompleta
*4 m. tec. prof. incompleta; 5 m. hum. completa; 6 m. tec completa
*7 tecnico nivel superior incompleta; 8 tecnico nivel superior completo
*9 profesional incompleto; 10 postgrado incompleto; 11 profesional completo
*12 postgrado completo; 99 ns/nr
use "${casen_Path}\casen2013.dta", clear
gen educ7=.
replace educ7=1 if educ==0
replace educ7=2 if educ==1
replace educ7=3 if educ==2 
replace educ7=4 if educ==3 | educ==4
replace educ7=5 if educ==5 | educ==6
replace educ7=6 if educ==7 | educ==9
replace educ7=7 if educ==8 | educ==10 | educ==11 | educ==12
drop if educ7==.
rename ytrabajocor salario
rename o10 horas 
keep(educ7 salario horas expr)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen2013_.dta", replace

*casen2015
*0 sin educ. formal; 1 basica incom.; 2 basica compl. 
*3 m. hum. incompleta; 4 m. tec. prof. incompleta; 5 m. hum. completa 
*6 m. tec completa; 7 tecnico nivel superior incompleta 
*8 tecnico nivel superior completo; 9 profesional incompleto 
*10 postgrado incompleto; 11 profesional completo; 12 postgrado completo 
*99 ns/nr 
use "${casen_Path}\casen2015.dta", clear
gen educ7=.
replace educ7=1 if educ==0
replace educ7=2 if educ==1
replace educ7=3 if educ==2 
replace educ7=4 if educ==3 | educ==4
replace educ7=5 if educ==5 | educ==6
replace educ7=6 if educ==7 | educ==9
replace educ7=7 if educ==8 | educ==10 | educ==11 | educ==12
drop if educ7==.
rename ytrabajocor salario
rename o10 horas 
keep(educ7 salario horas expr)
drop if educ7==. | salario==. | salario==999 | horas==. | horas==999
save "${Path}\casen2015_.dta", replace


set more off
local year_casen "1990 1992 1994 1996 1998 2000 2003 2006 2009 2011 2013 2015"
foreach Year of local year_casen {

use "${Path}\casen`Year'_.dta",clear

gen educ4=.
replace educ4=1 if educ7==1 | educ7==2
replace educ4=2 if educ7==3 | educ7==4
replace educ4=3 if educ7==5 | educ7==6 
replace educ4=4 if educ7==7 
drop if educ4==.

gen person= 1
gen Nhat = _N

collapse (mean) Nhat salario horas (sum) person  [w=expr], by(educ4)

forvalues e = 1(1)4{
	gen w`e'    =.
	gen Nhat`e' =.
	gen h`e'    =.
	
	quiet replace w`e'    = salario[`e'] in 1 
	quiet replace Nhat`e' = person[`e'] in 1
	quiet replace h`e'    = horas[`e'] in 1
}
gen year =`Year'
order year, first	
save "${Path}\c`Year'.dta", replace
}
*
set more off
local year_casen "1990 1992 1994 1996 1998 2000 2003 2006 2009 2011 2013 2015"
foreach Year of local year_casen {
use "${Path}\c`Year'.dta", clear
keep in 1
drop educ4 salario horas person
save "${Path}\cas`Year'.dta", replace
}
*
set more off
use "${Path}\cas1990.dta",clear
local year_casen "1992 1994 1996 1998 2000 2003 2006 2009 2011 2013 2015"
foreach Year of local year_casen {
append using "${Path}\cas`Year'.dta"
}
order year, first 
save "${Path}\casen.dta", replace

use "${Path}\casen.dta", clear

merge m:m year using "${Path}\UF_bc.dta", nogenerate
drop if Nhat==.
replace w1=w1/UF_bc
replace w2=w2/UF_bc
replace w3=w3/UF_bc
replace w4=w4/UF_bc

*1990
expand 2 in 1
replace year=1991 in `=_N'
sort year

*1992
expand 2 in 3
replace year=1993 in `=_N'
sort year

*1994
expand 2 in 5
replace year=1995 in `=_N'
sort year

*1996
expand 2 in 7
replace year=1997 in `=_N'
sort year

*1998
expand 2 in 9
replace year=1999 in `=_N'
sort year

*2000
expand 2 in 11
replace year=2001 in `=_N'
sort year

expand 2 in 11
replace year=2002 in `=_N'
sort year

*2003
expand 2 in 14
replace year=2004 in `=_N'
sort year

expand 2 in 14
replace year=2005 in `=_N'
sort year

*2006
expand 2 in 17
replace year=2007 in `=_N'
sort year

expand 2 in 17
replace year=2008 in `=_N'
sort year

*2009
expand 2 in 20
replace year=2010 in `=_N'
sort year

*2011
expand 2 in 22
replace year=2012 in `=_N'
sort year

*2013
expand 2 in 24
replace year=2014 in `=_N'
sort year

gen h = h1+h2+h3+h4

tsset year, yearly

gen Nhat1_share = Nhat1 / Nhat
gen Nhat2_share = Nhat2 / Nhat
gen Nhat3_share = Nhat3 / Nhat
gen Nhat4_share = Nhat4 / Nhat

gen AJL_cnp_sum = Nhat1_share *w1/w1 + Nhat2_share *w2/w1 + Nhat3_share * w3/w1 + Nhat4_share *w4/w1
gen Ln_AJL_cnp=ln(AJL_cnp_sum)
tsset year, yearly

gen year2 = year * year

gen ttrend=(year-1989)
gen ttrend2=ttrend*ttrend
gen ttrend3=ttrend2*ttrend

qreg Ln_AJL_cnp ttrend ttrend2
scalar b1=_b[ttrend]
scalar b2=_b[ttrend2]
scalar b0=_b[_cons]

gen logAJL_cnp_trend = b0 + ttrend * b1 + ttrend2 * b2

gen AJL_cnp_trend = exp(logAJL_cnp_trend)

rename AJL_cnp_trend AJL_cnp

*para el año 2016 se asume un ajuste de calidad del trabajo que para el año 2015
local N = `=_N' +1
set obs `N'
replace year=2016 in `N'
sort year

replace AJL_cnp = L.AJL_cnp * L.AJL_cnp / L2.AJL_cnp   if year==2016

rename w1 w1_cnp
rename w2 w2_cnp
rename w3 w3_cnp
rename w4 w4_cnp

rename Nhat1 N1_cnp
rename Nhat2 N2_cnp
rename Nhat3 N3_cnp
rename Nhat4 N4_cnp

save "${Path}/AJL_cnp.dta", replace
********************************************************************************

********************************************************************************
*LAJ_cnp
use "${Path}/L_cnp.dta", clear
merge m:m year using "${Path}/AJL_cnp.dta", nogenerate
gen LAJ_cnp = L_cnp * AJL_cnp
save "${Path}/LAJ_cnp.dta", replace
********************************************************************************

********************************************************************************
*LAJSM_cnp
use "${Path}/LSM_cnp.dta", clear
merge m:m year using "${Path}/AJLSM_cnp.dta", nogenerate
gen LAJSM_cnp = LSM_cnp * AJLSM_cnp 
save "${Path}/LAJSM_cnp.dta", replace
********************************************************************************

********************************************************************************
*Categoria de ocupados
*1986-2010
import excel "${Path}\INE.xls", ///
sheet(CATEGORIA AMBOS SEXOS) cellrange(B7:I298) firstrow clear
rename Cuenta Cuenta_propia
rename Personal Personal_servicio
rename Familiar Familiar_no_remunerado
rename Asalariados Asalariado
destring *, replace force
drop in 1/2
drop Periodo B
gen year =.
order year, first
local year = 1986
forvalues x = 12(12)`=_N'{
	local x_1 = `x'-11
	replace year = `year' in `x_1'/`x'
	local year = `year' + 1
}
replace year=2010 in `=_N'
rename Total Ocupados
ds year, not
collapse (mean) `r(varlist)' , by(year)
save "${Path}/OCUPene_ine.dta", replace

*2010-2016
import excel "${Path}\INE.xls", ///
sheet(Categoria) cellrange(A8:H87) firstrow clear
rename C Total
rename Empleadores Empleador
rename Cuenta Cuenta_propia
rename PersonaldeServicio Personal_servicio
rename Familiarnoremunerado Familiar_no_remunerado
drop Periodo B
gen year =.
order year, first
local year = 2010
forvalues x = 12(12)`=_N'{
	local x_1 = `x'-11
	replace year = `year' in `x_1'/`x'
	local year = `year' + 1
}
replace year=2016 in 73/`=_N'
rename Total Ocupados
ds year, not
collapse (mean) `r(varlist)' , by(year)
save "${Path}/OCUPnene_ine.dta", replace
********************************************************************************

********************************************************************************
*Fuerza_trabajo
*1986-2010
import excel "${Path}\INE.xls", ///
sheet(SFDT AMBOS SEXOS) cellrange(B7:E298) firstrow clear
rename Fuerzade FT
destring *, replace force
drop in 1/2
keep FT
gen year =.
order year, first
local year = 1986
forvalues x = 12(12)`=_N'{
	local x_1 = `x'-11
	replace year = `year' in `x_1'/`x'
	local year = `year' + 1
}
replace year=2010 in `=_N'
ds year, not
collapse (mean) `r(varlist)' , by(year)
label variable FT "Fuerza de Trabajo"
save "${Path}/FTene_ine.dta", replace

*2010-2016
import excel "${Path}\INE.xls", ///
sheet(SFDT) cellrange(A8:D90) firstrow clear
rename Fuerzade FT
destring *, replace force
drop in 1/2
keep FT
gen year =.
order year, first
local year = 2010
forvalues x = 12(12)`=_N'{
	local x_1 = `x'-11
	replace year = `year' in `x_1'/`x'
	local year = `year' + 1
}
replace year=2016 in 73/`=_N'
ds year, not
collapse (mean) `r(varlist)' , by(year)
save "${Path}/FTnene_ine.dta", replace
********************************************************************************

********************************************************************************
*AJK_cnp 
*ENE
use "${Path}/FTene_ine.dta", replace
merge m:m year using "${Path}/OCUPene_ine.dta", nogenerate
sort year
tset year
gen Asal_FT = Asalariado / FT

reg Asal_FT year 
predict Asal_FT_tend, xb
gen IUasalariado_ene = Asal_FT / Asal_FT_tend
save "${Path}/Asal_FT_ene.dta", replace

*NENE
use "${Path}/FTnene_ine.dta", replace
merge m:m year using "${Path}/OCUPnene_ine.dta", nogenerate
sort year
tset year
gen Asal_FT = Asalariado / FT

reg Asal_FT year 
predict Asal_FT_tend, xb
gen IUasalariado_nene = Asal_FT / Asal_FT_tend
save "${Path}/Asal_FT_nene.dta", replace

*EMPALME
use "${Path}/Asal_FT_ene.dta", clear
merge m:m year using "${Path}/Asal_FT_nene.dta", nogenerate
sort year

browse year IUasalariado_ene IUasalariado_nene
gen coef = IUasalariado_nene[25] / IUasalariado_ene[25] 
gen IUasalariado_ene_empalme = IUasalariado_ene * coef

gen IUasalariado_empalme = IUasalariado_nene
replace IUasalariado_empalme = IUasalariado_ene if year<2010
drop if year<1990

egen IUasalariado_empalme_mean = mean(IUasalariado_empalme)

gen IUasalariado = IUasalariado_empalme / IUasalariado_empalme_mean
replace IUasalariado = round(IUasalariado, 0.0001)

browse year IUasalariado

save "${Path}/IUasalariado.dta", replace

*se utilizan series de DIPRES
import excel "${Path}\BC.xls", ///
sheet(DIPRES) cellrange(A1:D61) firstrow clear
save "${Path}/dipres.dta", replace


use "${Path}/dipres.dta", clear
keep year U_dipres UN_dipres IU_dipres
merge m:m year using "${Path}/Asal_FT_nene.dta", nogen
merge m:m year using "${Path}/IUasalariado.dta", nogen

sort year
*se genera desempleo natural para el ano 2016
replace UN_dipres = L.UN_dipres if year==2016

*ajuste por utilizacion a la DIPRES hasta 2016
gen Utotal = 1 - Ocupados/FT
gen IUtotal = (1-Utotal)/(1-UN_dipres)

order IUtotal, first
replace IUtotal=round(IUtotal, 0.001)
replace IUtotal = IU_dipres if year<=2015

save "${Path}/IUtotal.dta", replace


use "${Path}/IUtotal.dta", clear
merge m:m year using "${Path}/IUasalariado.dta", nogen

gen AJKA_cnp = IUasalariado
gen AJKD_cnp = IUtotal

save "${Path}/AJK_cnp.dta", replace
********************************************************************************

********************************************************************************
*KAJ_cnp
use "${Path}/K_cnp.dta", clear
merge m:m year using "${Path}/AJK_cnp.dta", nogenerate
sort year

gen KAJA_cnp = K_cnp * AJKA_cnp
gen KAJD_cnp = K_cnp * AJKD_cnp

save "${Path}/KAJ_cnp.dta", replace
********************************************************************************


********************************************************************************
*KSM_cnp
use "${Path}/KM_cnp.dta", clear
merge m:m year using "${Path}/K_cnp.dta", nogenerate
sort year

gen KSM_cnp = (K_cnp-KM_cnp/1000)

replace KSM_cnp = KSM2015 if year==2015
replace KSM_cnp = KSM2016 if year==2016

save "${Path}/KSM_cnp.dta", replace
********************************************************************************

********************************************************************************
*AJKSM_cnp
use "${Path}/KSM_cnp.dta", clear
merge m:m year using "${Path}/KAJ_cnp.dta", nogenerate
sort year

*se calcula un capital ciclico, definido como la variacion ciclica del capital
gen K_ciclo   = K_cnp * (AJKA_cnp - 1)
gen K_ciclo_D = K_cnp * (AJKD_cnp - 1)

gen AJKASM_cnp = AJKA_cnp 
gen AJKDSM_cnp = AJKD_cnp

sort year
save "${Path}/AJKSM_cnp.dta", replace
********************************************************************************

********************************************************************************
*KAJSM_cnp
use "${Path}/KSM_cnp.dta", clear
merge m:m year using "${Path}/AJKSM_cnp.dta", nogenerate

*siguiendo a UAI/CORFO se asume que mineria no presenta un comportamiento
*ciclico, luego todo el "capital ciclico" afecta solo al sector no-minero 
gen KAJASM_cnp = KSM_cnp + K_ciclo
gen KAJDSM_cnp = KSM_cnp + K_ciclo_D

sort year
save "${Path}/KAJSM_cnp.dta", replace
********************************************************************************

********************************************************************************
*PTF_CNP
drop _all
set obs 70
gen year=.
quiet forv x = 1(1)70{
quiet replace year=2016-`x'+1 in `x'
}
gen alpha_cnp=0.4849
gen alpha_sm_cnp=0.445
drop if year<1990 
sort year
*merge m:m year using "${Path}/Y_cnp.dta", nogenerate
merge m:m year using "${Path}/YCF_cnp.dta", nogenerate
merge m:m year using "${Path}/YSM_cnp.dta", nogenerate
merge m:m year using "${Path}/K_cnp.dta", nogenerate
merge m:m year using "${Path}/KAJ_cnp.dta", nogenerate
merge m:m year using "${Path}/KSM_cnp.dta", nogenerate
merge m:m year using "${Path}/KAJSM_cnp.dta", nogenerate
merge m:m year using "${Path}/AJK_cnp.dta", nogenerate
merge m:m year using "${Path}/AJKSM_cnp.dta", nogenerate
merge m:m year using "${Path}/AJLSM_cnp.dta", nogenerate
merge m:m year using "${Path}/LAJ_cnp.dta", nogenerate
merge m:m year using "${Path}/LAJSM_cnp.dta", nogenerate

tsset year
drop if year<1990

local total_1="YCF_cnp N_cnp H_cnp L_cnp AJL_cnp LAJ_cnp K_cnp KAJA_cnp KAJD_cnp alpha_cnp"
local total_2="w1_cnp w2_cnp w3_cnp w4_cnp N1_cnp N2_cnp N3_cnp N4_cnp"

local sm_1="YSM_cnp	NSM_cnp	HSM_cnp	LSM_cnp	AJLSM_cnp LAJSM_cnp	KSM_cnp	KAJASM_cnp KAJDSM_cnp alpha_sm_cnp"
local sm_2="w1sm_cnp w2sm_cnp w3sm_cnp w4sm_cnp N1sm_cnp N2sm_cnp N3sm_cnp N4sm_cnp"

local vars="`total_1' `total_2' `sm_1' `sm_2'"

keep year `vars' 

*le saca la terminacion _cnp a las variables
renvars `vars' , postdrop(4)

rename YCF PIB
rename YSM PIBSM

order year PIB K KAJA KAJD alpha N H L w1 w2 w3 w4 N1 N2 N3 N4 AJL LAJ ///
PIBSM KSM KAJASM KAJDSM	alpha_sm NSM HSM LSM w1sm w2sm w3sm w4sm ///
N1sm N2sm N3sm N4sm AJLSM LAJSM, first

save "${Path}/PTF_cnp.dta", replace
********************************************************************************

********************************************************************************
*exportar series a archivo excel PTF (hoja "data")
use "${Path}/PTF_cnp.dta", clear
export excel "${Path}\DATA.xls", ///
sheet("data") sheetreplace firstrow(variables) 
********************************************************************************
