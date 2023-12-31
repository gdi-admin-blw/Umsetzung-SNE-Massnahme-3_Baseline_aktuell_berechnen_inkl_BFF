-- Umsetzung SNE Massnahme 3

-- 1. Version
-- Berechnung Baseline mit bestehenden Programmen
-- fse, 29.08.2022

-- 2. Version
--> Korrekturen auf BTS / RAUS (Fehler im Skript)
--> Berücksichtigung aller Kategorien BTS / RAUS,
--> Ergänzung KT, FAT, Zone
--> Aufteilung Biopotential auf Spezialkulturen SK und Andere Kulturen AK, gleiches Vorgehen wie bei BTS / RAUS
-- fse, 31.08.2022

-- Korrekturen/Finalisierung für Besprechung vom 12.10.2022
-- Bio wieder zurücksetzen auf 1 Wert
-- fse 26.09.2022

-- 02.11.2022
-- Berechnung für alle Jahre in einem Skript, Ergänzung mit prozentualer Beteiligung pro Range


-- 3. Version
-- Aufnahme der BFF in die Berechnung
-- fse, 16.03.2023

/*
Zunächst wird für jeden Betrieb festgestellt, an welchen PSB er aufgrund seiner Struktur theoretisch teilnehmen kann (Potenzial). Dann wird festgestellt, wie stark er dieses Potenzial ausschöpft.

•	Beitrag für biologische Landwirtschaft: Alle Betriebe können diesen Beitrag erhalten. Der Betrieb wirtschaftet entweder biologisch oder nicht, entsprechend erhält jeder Betrieb eine Beteiligung von 0% oder 100%.
•	Tierwohlbeiträge: Nur tierhaltende Betriebe können diese Beiträge (RAUS und BTS) erhalten. Die RAUS- und BTS-Beiträge werden pro GVE ausbezahlt. Jede GVE eines Betriebes kann bei RAUS und BTS teilnehmen. Der Einfachheit halber sollen nur Tiere der Rinder-, Schweine-, Schaf-, und Ziegengattung sowie Nutzgeflügel in die Berechnung einbezogen werden. Ausserdem wird nicht berücksichtigt, dass gewisse Tierkategorien bei BTS nicht teilnehmen können (z.B. Kälber, Hengste). Die Beteiligung des Betriebes wird folgendermassen berechnet: GVE mit BTS + GVE mit RAUS geteilt durch 2*GVE des Betriebes.
•	Graslandbasierte Milch- und Fleischproduktion: Nur Betriebe mit raufutterverzehrenden Nutztieren können diesen erhalten. Ein Betrieb erfüllt die Bedingungen oder er erfüllt sie nicht. Die Beteiligung ist entweder 100 % oder 0%.
•	Beitrag für die extensive Produktion: Jeder Betrieb mit Getreide, Sonnenblumen, Eiweisserbsen, Ackerbohnen, Lupinen und Raps kann teilnehmen. Die Beteiligung eines Betriebes umfasst den Anteil dieser Fläche, für die er einen Beitrag für die extensive Produktion erhält.
Schliesslich wird für jeden einzelnen Betrieb eine durchschnittliche Beteiligung über alle PSB berechnet. Jede PSB ist dabei gleichwertig, wird also mit gleicher Gewichtung in den Indikator aufgenommen. Das ergibt eine Beteiligung zwischen 0 und 100%.

*/



-- Fragen an Jonas:
/*

-- Grundmenge
Wir haben gesagt, nur Betriebe mit DZ. Sömmerung ist auch DZ... Was machen?
--> NUR DZ GJB

-- Tierwohl
Wieso Equiden nicht bei Tierwohl? Und Bison und Hirsche, Kaninchen? Macht das Sinn?
--> ALLE Kategorien berücksichtigen

Was ist mit dem Weideauslauf?
--> Weglassen

Schafe können gar nicht bei BTS teilnehmen (nicht nur ein Teil der Tiergattung, sondern die ganze). ist das bewusst?
Müsste pro Gattung mit ja oder nein geschaut werden?? im Moment nur total angeschaut
--> ALLE Kategorien berücksichtigen, jedoch nur BTS und RAUS separat berechnen, nicht detaillierter


-- gmf
welche Tiergattungen?
gem LBV, Merkmalskatalog und Matrix: Raufutter verzehrende Tiere sind Tiere der Rindergattung und der Pferdegattung sowie Schafe, Ziegen, Bisons, Hirsche, Lamas und Alpakas.
--> korrekt

-- ext
-- alle Kulturen, die in der Matrix bei ext eine 1 haben?
--> korrekt

-- wann und wie muss ich runden?
-- berechnung betriebsindikator auf 2 Stellen nach dem Komma gerundet
--> so lassen

*/

-- Abfrage pro Jahr

undefine Jahr;


-- zwischentabellen löschen
DECLARE
CURSOR c1 IS
SELECT TABLE_NAME AS TABNAM FROM user_tables
WHERE TABLE_NAME IN (
'T_BFF_POTENTIAL',
'T_BFF_POTENTIAL_BET',
'T_BASELINE'
);
sqlstmt VARCHAR2(4000);
BEGIN
FOR c1rec IN c1 LOOP
sqlstmt := 'DROP TABLE '||c1rec.TABNAM||' PURGE';
EXECUTE IMMEDIATE sqlstmt;
END LOOP;
END;
/


-------------------------------------------------------------
-- Zwischentabelle (T_BFF_POTENTIAL und BFF_POTENTIAL_BET) für Berechnung	"Indikator_ BDB"
-------------------------------------------------------------

/*
Angestrebter Anteil BFF mit hoher Qualität pro Zone (entspricht Potential)

Talzone	10 %
Hügelzone	12 %
Bergzone I	13 %
Bergzone II	17 %
Bergzone III	30 %
Bergzone IV	45 %
*/


-- für die Berechnung des Potentialsg nehmen wir nur die LN (ohne Bäume)
-- wir berücksichtigen nur die Zonen 31 - 54
--> Entscheid von Jonas


-- create table T_BFF_POTENTIAL
-- drop table T_BFF_POTENTIAL;

create table T_BFF_POTENTIAL AS

(SELECT afl_abj_id_ln abj_id_bff_pot, CD_CODE zone, Sum(AFL_FLNETTO) LN_BETRIEB, 0 BFF_ANTEIL_SOLL, 0 BFF_POTENTIAL
FROM T_flaechen_2014, t_code_kulturen_2002, T_code_kulturen_jahr_2014, T_CODETAB
WHERE AFL_AKR_CODE_LN = AKR_CODE_ID
AND AKR_CODE_ID = AKU_AKR_ID_LN
AND AFL_ERHEBUNGSJAHR  BETWEEN 2014 AND 2021
AND AFL_ERHEBUNGSJAHR = AKU_JAHR
AND AFL_CD_ZONE_LN = CD_CODE_ID
AND akr_code < '0900'
AND cd_code BETWEEN 31 AND 54
GROUP BY afl_abj_id_ln,CD_CODE)

;


-- update bff_anteil_soll
UPDATE T_BFF_POTENTIAL SET BFF_ANTEIL_SOLL = 0.1 WHERE ZONE = 31;
UPDATE T_BFF_POTENTIAL SET BFF_ANTEIL_SOLL = 0.12 WHERE ZONE = 41;
UPDATE T_BFF_POTENTIAL SET BFF_ANTEIL_SOLL = 0.13 WHERE ZONE = 51;
UPDATE T_BFF_POTENTIAL SET BFF_ANTEIL_SOLL = 0.17 WHERE ZONE = 52;
UPDATE T_BFF_POTENTIAL SET BFF_ANTEIL_SOLL = 0.30 WHERE ZONE = 53;
UPDATE T_BFF_POTENTIAL SET BFF_ANTEIL_SOLL = 0.45 WHERE ZONE = 54;


-- update bff_anteil_soll
UPDATE T_BFF_POTENTIAL SET BFF_POTENTIAL = LN_BETRIEB * BFF_ANTEIL_SOLL;


-- drop table T_bff_potential_bet;


CREATE TABLE T_BFF_POTENTIAL_BET AS

SELECT ABJ_ID_BFF_POT, Sum(BFF_POTENTIAL) BFF_POTENTIAL
FROM T_BFF_POTENTIAL
GROUP BY abj_id_BFF_POT
;




------------------------------------------------------------
-- Berechnung Potentiale und effektiv umgesetzte Programme
------------------------------------------------------------


CREATE TABLE T_BASELINE as
SELECT  ABJ_JAHR, ABJ_KANTON, SubStr(ABJ_BDA_ZONE_LN,-2) Betriebszone, SubStr(ABJ_BDA_PFAT_LN,-4) FAT_TYP_4, ABJ_ID, ABJ_BBS_ID, ABJ_BBS_KT_ID_B,
FL_POTENTIAL_BIO, BIO, 0 indikator_bio, 0 divisor_bio,
GVE_BTS_POTENTIAL, GVE_BTS, 0 indikator_BTS, 0 divisor_BTS,
GVE_RAUS_POTENTIAL, GVE_RAUS, 0 indikator_RAUS, 0 divisor_RAUS,
0 indikator_tierwohl, 0 divisor_tierwohl,
RGVE_GMF, GMF_BEITRAG, 0 indikator_gmf, 0 divisor_gmf,
EXTENSO_POTENTIAL, EXTENSOFLAECHE, 0 indikator_extenso, 0 divisor_extenso,
BFF_POTENTIAL, BFF_FLAECHE, 0 indikator_BDB, 0 divisor_BDB

FROM

-- Grundmenge: alle Betriebe mit DZ (ohne Sömmerung)und hat_Strukturen

(SELECT ABJ_JAHR, ABJ_KANTON, ABJ_BDA_ZONE_LN, ABJ_BDA_PFAT_LN, ABJ_ID, ABJ_BBS_ID, ABJ_BBS_KT_ID_B
FROM T_betrieb_jahr
WHERE ABJ_BDA_HAT_DZ = '1'
AND ABJ_BDA_HAT_STRUKTUREN = '1'
AND abj_jahr BETWEEN 2014 AND 2021)


-- bio potential

left JOIN

(SELECT afl_abj_id_ln ABJ_ID_BIO_POT, Sum(AFL_FLNETTO) FL_POTENTIAL_BIO
FROM T_flaechen_2014, T_code_kulturen_2002, t_code_kulturen_jahr_2014
WHERE AFL_AKR_CODE_LN = AKR_CODE_ID
AND AKR_CODE_ID = AKU_AKR_ID_LN
AND AKU_JAHR = AFL_ERHEBUNGSJAHR
AND AFL_ERHEBUNGSJAHR BETWEEN 2014 AND 2021
AND akr_code < '0900'
AND AKU_PS_BIO_BER = 1  -- per def bioberechtigt
GROUP BY afl_abj_id_ln)

ON ABJ_ID = ABJ_ID_BIO_POT

-- bio fläche
left JOIN

(SELECT MBS_ABJ_ID ABJ_ID_BIO,
 Sum(MBS_WERT_STRUKTUR) BIO
FROM adz.MV_BI_DATA_BEI_STRUKTUR
WHERE MBS_JAHR  BETWEEN 2014 AND 2021
and MBS_BIR_S3_NUMM in ('A.12.01') -- = Fläche Bio
GROUP BY MBS_JAHR, MBS_ABJ_ID)

ON ABJ_ID = ABJ_ID_BIO


--> 2020: 43'375 Betriebe

-- Tierwohl GVE des Betriebs

-- Tierwohlbeiträge: Nur tierhaltende Betriebe können diese Beiträge (RAUS und BTS) erhalten.
-- Die RAUS- und BTS-Beiträge werden pro GVE ausbezahlt. Jede GVE eines Betriebes kann bei RAUS und BTS teilnehmen.
-- Die Beteiligung des Betriebes wird folgendermassen berechnet: GVE mit BTS + GVE mit RAUS geteilt durch 2*GVE des Betriebes.

left join

-- GVE BTS Potential

(SELECT VTG_ABJ_ID_LN ABJ_ID_BTS_Potential, Sum(VTG_ANZGVE_ALLE) GVE_BTS_POTENTIAL
FROM V_tiere_gjb_2014, T_code_tiere_2002, T_code_Tiere_jahr_2014
WHERE VTG_ATR_CODE_LN = ATR_CODE_ID
AND ATR_CODE_ID = ATJ_ATR_ID_LN
AND VTG_ERHEBUNGSJAHR = ATJ_JAHR
AND ATJ_BTS_BER = '1'  -- per def für bts berechtigt im entsprechenden jahr
AND VTG_ERHEBUNGSJAHR  BETWEEN 2014 AND 2021
GROUP BY VTG_ABJ_ID_LN)

ON ABJ_ID = ABJ_ID_BTS_Potential


-- GVE BTS bei Betrieben mit Beiträgen
/*
S001 = Nutzgeflügel
S002 = Kaninchen   --> nicht ausgeschlossen, wie Sämi wollte
S003 = Pferdegattung --> nicht ausgeschlossen, wie Sämi wollte
S004 = Rinder
S005 = Rinder Weideauslauf --> AUSSCHLIESSEN!
S006 = Schafe (nur RAUS!)
S007 = Schweine
S008 = Ziegen
S011 = Bisons (nur RAUS!)  --> nicht ausgeschlossen, wie Sämi wollte
S012 = Hirsche (nur RAUS!)  --> nicht ausgeschlossen, wie Sämi wollte
*/

left join

(SELECT MBS_ABJ_ID ABJ_ID_BTS,
 Sum(MBS_WERT_STRUKTUR) GVE_BTS
FROM adz.MV_BI_DATA_BEI_STRUKTUR
WHERE MBS_JAHR  BETWEEN 2014 AND 2021
 and MBS_BIR_S3_NUMM in ('A.12.04') -- 04 = BTS
GROUP BY MBS_JAHR, MBS_ABJ_ID)

ON abj_id = ABJ_ID_BTS



left join

-- GVE RAUS Potential

(SELECT VTG_ABJ_ID_LN ABJ_ID_RAUS_Potential, Sum(VTG_ANZGVE_ALLE) GVE_RAUS_POTENTIAL
FROM V_tiere_gjb_2014, T_code_tiere_2002, T_CODE_TIERE_JAHR_2014
WHERE VTG_ATR_CODE_LN = ATR_CODE_ID
AND ATR_CODE_ID = ATJ_ATR_ID_LN
AND VTG_ERHEBUNGSJAHR = ATJ_JAHR
AND ATJ_RAUS_BER = '1'  -- per def für RAUS berechtigt im entsprechenden jahr
AND VTG_ERHEBUNGSJAHR  BETWEEN 2014 AND 2021
GROUP BY VTG_ABJ_ID_LN)

ON ABJ_ID = ABJ_ID_RAUS_Potential


-- GVE RAUS bei Betrieben mit Beiträgen

left join

(SELECT MBS_ABJ_ID ABJ_ID_RAUS,
 Sum(MBS_WERT_STRUKTUR) GVE_RAUS
FROM adz.MV_BI_DATA_BEI_STRUKTUR
WHERE MBS_JAHR  BETWEEN 2014 AND 2021
and MBS_BIR_S3_NUMM in ('A.12.05') -- 05 = raus
and SubStr(MBS_BIS_S5_NUMM,-4) NOT IN 'S005' -- Ausschluss Weideauslauf!
GROUP BY MBS_JAHR, MBS_ABJ_ID)

ON abj_id = ABJ_ID_RAUS



-- Graslandbasierte Milch- und Fleischproduktion:
-- Nur Betriebe mit raufutterverzehrenden Nutztieren können diesen erhalten.
-- Ein Betrieb erfüllt die Bedingungen oder er erfüllt sie nicht. Die Beteiligung ist entweder 100 % oder 0%.

/*
rinder 11xx
pferde 12xx
schafe 13xx
ziegen 14xx
andere Bisons, 1571, 1572,
Hirsche, Lama, Alpaka 1575, 1578, 1581, 1582, 1585, 1586  -- alle 15xx
*/

left JOIN

-- GVE RGVE
(SELECT VTG_ABJ_ID_LN ABJ_ID_GMF_RGVE, (Sum(VTG_ANZGVE_ALLE)) RGVE_GMF
FROM V_tiere_gjb_2014, T_code_tiere_2002
WHERE VTG_ATR_CODE_LN = ATR_CODE_ID
AND ATR_CODE BETWEEN '1100' AND '1599'
AND VTG_ERHEBUNGSJAHR  BETWEEN 2014 AND 2021
GROUP BY VTG_ABJ_ID_LN, VTG_ERHEBUNGSJAHR)


ON abj_id = ABJ_ID_GMF_RGVE


left JOIN

-- GMF Beitrag
(SELECT MBZ_ABJ_ID ABJ_ID_GMF_BEITRAG,
 Sum(MBZ_BETRAG) GMF_BEITRAG
FROM adz.MV_BI_DATA_BEI_ZAHLUNG
WHERE MBZ_JAHR  BETWEEN 2014 AND 2021
 and MBZ_BIR_S3_NUMM in ('A.12.03') -- 03 = GMF
GROUP BY MBZ_ABJ_ID)

ON abj_id = ABJ_ID_GMF_BEITRAG



-- extenso
-- Beitrag für die extensive Produktion:
-- Jeder Betrieb mit Getreide, Sonnenblumen, Eiweisserbsen, Ackerbohnen, Lupinen und Raps kann teilnehmen.
-- Die Beteiligung eines Betriebes umfasst den Anteil dieser Fläche, für die er einen Beitrag für die
-- extensive Produktion erhält.

--> alle, die in der Matrix bei ext eine 1 haben?

left join

(SELECT afl_abj_id_ln abj_id_ext_pot, Sum(AFL_FLNETTO) Extenso_potential
FROM T_flaechen_2014, t_code_kulturen_2002, T_code_kulturen_jahr_2014
WHERE AFL_AKR_CODE_LN = AKR_CODE_ID
AND AKR_CODE_ID = AKU_AKR_ID_LN
AND AFL_ERHEBUNGSJAHR  BETWEEN 2014 AND 2021
AND AFL_ERHEBUNGSJAHR = AKU_JAHR
AND AKU_PS_EXT_BER = '1'  -- per definiton extenso-berechtigt
GROUP BY afl_abj_id_ln)

ON abj_id = abj_id_ext_pot



-- extensofläche
left join

(SELECT MBS_ABJ_ID ABJ_ID_Extenso,
 Sum(MBS_WERT_STRUKTUR) extensoflaeche
FROM adz.MV_BI_DATA_BEI_STRUKTUR
WHERE MBS_JAHR  BETWEEN 2014 AND 2021
 and MBS_BIR_S3_NUMM in ('A.12.02') -- 02 = Extenso
GROUP BY MBS_JAHR, MBS_ABJ_ID)

ON abj_id = ABJ_ID_Extenso


-- BFF

left JOIN

-- BFF_POTENTIAL
(SELECT ABJ_ID_BFF_POT, BFF_POTENTIAL FROM T_BFF_POTENTIAL_BET)

ON abj_id = ABJ_ID_BFF_POT

left join

-- BFF_FLAECHE
(SELECT ABJ_ID_BFF, Sum(BFF_FLAECHE) BFF_FLAECHE from
-- QII ohne Hecken und Bäume
((SELECT MBS_ABJ_ID ABJ_ID_BFF,
 Sum(MBS_WERT_STRUKTUR) BFF_FLAECHE
FROM adz.MV_BI_DATA_BEI_STRUKTUR
WHERE MBS_JAHR  BETWEEN 2014 AND 2021
and MBS_BIR_S3_NUMM in ('A.10.02') -- Qualitaet II
AND MBS_BIS_EINHEIT_STRUKTUR = 'm2' -- Ausschluss Bäume
AND MBS_BIS_S6_NUMM <> 'A.10.02.011.S020' -- Ausschluss Hecken QII
GROUP BY MBS_JAHR, MBS_ABJ_ID)

UNION

-- QII Hochstammobstbäume und Nussbäume
(SELECT MBS_ABJ_ID ABJ_ID_BFF,
 Sum(MBS_WERT_STRUKTUR* 100) BFF_FLAECHE  -- 1 Baum = 1 Are
FROM adz.MV_BI_DATA_BEI_STRUKTUR
WHERE MBS_JAHR  BETWEEN 2014 AND 2021
AND MBS_BIS_S6_NUMM IN ('A.10.02.030.S021.0030','A.10.02.031.S021.0031') -- Hochstammobstbäume + Nussbäume QII
GROUP BY MBS_JAHR, MBS_ABJ_ID)

UNION

-- ausgewählte Positionen QI

(SELECT MBS_ABJ_ID ABJ_ID_BFF,
 Sum(MBS_WERT_STRUKTUR) BFF_FLAECHE
FROM adz.MV_BI_DATA_BEI_STRUKTUR
WHERE MBS_JAHR  BETWEEN 2014 AND 2021
AND MBS_BIS_S6_NUMM in
(
'A.10.01.007.S010.0007', -- Buntbrache
'A.10.01.008.S010.0008', -- Rotationsbrache
'A.10.01.010.S010.0010', -- Saum auf Ackerfläche
'A.10.01.009.S010.0009', -- Ackerschonstreifen
'A.10.01.011.S010.0011'  -- Hecken mit Qualitätsstufe I
)
GROUP BY MBS_JAHR, MBS_ABJ_ID))
GROUP BY ABJ_ID_BFF)

ON abj_id = ABJ_ID_BFF

;


COMMIT;



-----------------------------------------------------------------------
-- Berechnung Indikatoren und Beteiligung
----------------------------------------------------------------------

----------------
-- psb
----------------

/*
Schliesslich wird für jeden einzelnen Betrieb eine durchschnittliche Beteiligung über alle PSB berechnet.
Jede PSB ist dabei gleichwertig, wird also mit gleicher Gewichtung in den Indikator aufgenommen.
Das ergibt eine Beteiligung zwischen 0 und 100%.
*/


-------------------------------------------
--BIO
-------------------------------------------


-- update indikator_bio (ist per default = 0)
UPDATE t_baseline
SET indikator_bio = BIO/FL_POTENTIAL_BIO * 100 WHERE Nvl(FL_POTENTIAL_BIO,0) > 0 AND Nvl(BIO,0) > 0;

-- Korrektur indikator_bio, wenn > 100 %
UPDATE t_baseline
SET indikator_bio = 100 WHERE indikator_bio > 100;


-- update divisor_bio  --> nur wenn divisor = 1, wird Programm berücksichtigt
UPDATE t_baseline
SET divisor_bio = 1 WHERE Nvl(FL_POTENTIAL_BIO,0) > 0;



-------------------------------------------
-- BTS /RAUS
-------------------------------------------

-- update INDIKATOR_BTS (ist per default = 0)
UPDATE t_baseline
SET indikator_bts = GVE_BTS/GVE_BTS_POTENTIAL * 100 WHERE Nvl(GVE_BTS_POTENTIAL,0) > 0 AND Nvl(GVE_BTS,0) > 0;

-- Korrektur INDIKATOR_BTS, wenn > 100 %
UPDATE t_baseline
SET indikator_bts = 100 WHERE indikator_bts > 100;


-- update DIVISOR_BTS  --> nur wenn divisor = 1, wird Programm berücksichtigt
UPDATE t_baseline
SET DIVISOR_BTS = 1 WHERE Nvl(GVE_BTS_POTENTIAL,0) > 0;


-- update INDIKATOR_RAUS (ist per default = 0)
UPDATE t_baseline
SET indikator_raus =  GVE_RAUS/GVE_RAUS_POTENTIAL * 100 WHERE Nvl(GVE_RAUS_POTENTIAL,0) > 0 AND Nvl(GVE_RAUS,0) > 0;


-- Korrektur INDIKATOR_RAUS, wenn > 100 %
UPDATE t_baseline
SET indikator_raus = 100 WHERE indikator_raus > 100;


-- update DIVISOR_RAUS  --> nur wenn divisor = 1, wird Programm berücksichtigt
UPDATE t_baseline
SET DIVISOR_RAUS = 1 WHERE Nvl(GVE_RAUS_POTENTIAL,0) > 0;


-- update indikator_tierwohl
UPDATE t_baseline
SET indikator_tierwohl = (indikator_bts + indikator_raus) / (DIVISOR_BTS + DIVISOR_RAUS)
WHERE DIVISOR_BTS + DIVISOR_RAUS > 0;


-- korrektur nicht nötig, da schon auf bts und raus korrigiert

-- update DIVISOR_TIERWOHL
UPDATE t_baseline
SET DIVISOR_TIERWOHL = 1
WHERE DIVISOR_BTS + DIVISOR_RAUS > 0  --> dies wurde vorher falsch berechnet! (statt DIVISOR_BTS + DIVISOR_RAUS > 0, indikator_tierwohl > 0, so wird aber ein indikator = 0 fälschlicherweise nicht eingerechnet)
;



-------------------------------------------
-- GMF
-------------------------------------------

-- update indikator_gmf
UPDATE t_baseline
SET indikator_gmf = 100 WHERE Nvl(RGVE_GMF,0) > 0 AND Nvl(GMF_BEITRAG,0) > 0;


-- update DIVISOR_GMF  --> nur wenn divisor = 1, wird Programm berücksichtigt
UPDATE t_baseline
SET DIVISOR_GMF = 1 WHERE Nvl(RGVE_GMF,0) > 0;


------------------------------------------------------
-- extenso
------------------------------------------------------

-- update indikator_extenso
UPDATE t_baseline
SET indikator_extenso = EXTENSOFLAECHE/EXTENSO_POTENTIAL * 100 WHERE Nvl(EXTENSO_POTENTIAL,0) > 0 AND Nvl(EXTENSOFLAECHE,0) > 0;


-- Korrektur indikator_extenso, wenn > 100 %
UPDATE t_baseline
SET indikator_extenso = 100 WHERE indikator_extenso > 100;


-- update DIVISOR_EXTENSO  --> nur wenn divisor = 1, wird Programm berücksichtigt
UPDATE t_baseline
SET DIVISOR_EXTENSO = 1 WHERE Nvl(EXTENSO_POTENTIAL,0) > 0;


------------------------------------------------------
-- Indikator BDB (BFF)
------------------------------------------------------

-- update indikator_bdb
UPDATE t_baseline
SET indikator_bdb = BFF_FLAECHE/BFF_POTENTIAL * 100 WHERE Nvl(BFF_POTENTIAL,0) > 0 AND Nvl(BFF_FLAECHE,0) > 0;


-- Korrektur indikator_bdb, wenn > 100 %
UPDATE t_baseline
SET indikator_bdb = 100 WHERE indikator_bdb > 100;


-- update DIVISOR_BFF  --> nur wenn divisor = 1, wird Programm berücksichtigt
UPDATE t_baseline
SET DIVISOR_Bdb = 1 WHERE Nvl(BFF_POTENTIAL,0) > 0;




----------------------------------------------------------------
-- Betriebsindikator PSB
----------------------------------------------------------------


ALTER TABLE t_baseline
ADD Indikator_PSB NUMBER (5,2);


-- update indikator_PSB

UPDATE t_baseline
SET indikator_PSB = (INDIKATOR_BIO + INDIKATOR_TIERWOHL + indikator_gmf + indikator_extenso) /
(DIVISOR_BIO + DIVISOR_TIERWOHL + DIVISOR_GMF + DIVISOR_EXTENSO)
WHERE DIVISOR_BIO + DIVISOR_TIERWOHL + DIVISOR_GMF + DIVISOR_EXTENSO > 0
;


----------------------------------------------------------------
-- Betriebsindikator BUTP
----------------------------------------------------------------


ALTER TABLE t_baseline
ADD Indikator_BUTP NUMBER (5,2);


-- update Indikator_BUTP

UPDATE t_baseline
SET Indikator_BUTP = ((INDIKATOR_PSB * 3) + INDIKATOR_BDB)/4
WHERE DIVISOR_BDB = 1;


UPDATE t_baseline
SET Indikator_BUTP = INDIKATOR_PSB
WHERE DIVISOR_BDB = 0;

COMMIT;



-- baseline

SELECT jahr_bet, anz_bet, indikator_PSB, Indikator_BUTP,
Round((indikator_PSB/anz_bet),2) baseline_PSB, Round((indikator_BUTP/anz_bet),2) baseline_BUTP
from
-- anz_bet
(SELECT ABJ_JAHR jahr_bet, Count(*) anz_bet FROM t_baseline
GROUP BY abj_jahr)

left join
-- indikatoren
(SELECT abj_jahr jahr_ind,  Sum (indikator_PSB) indikator_PSB,
Sum (Indikator_BUTP) Indikator_BUTP
 FROM t_baseline
GROUP BY abj_jahr)

ON jahr_bet = jahr_ind

;



--> Werte 2020
-- 51.59 -- ursprungswert (mit fehlern bei bts-raus) und ohne gewichtung bio
-- 50.99 -- neu


-- Resultat über die Jahre
/*
2014: 45.64
2015: 46.86
2016: 47.96
2017: 48.77
2018: 49.69
2019: 50.38
2020: 50.99
2021: 51.74
*/


-- Durchschnittliche Indikatoren und beteiligte Betriebe pro Range

SELECT Jahr_alle jahr, Betriebe_alle, Indikator_alle,

Betriebe_0_25,
Round((Betriebe_0_25 / Betriebe_alle),2) Prozentual_0_25 ,
Betriebe_25_50,
Round((Betriebe_25_50 / Betriebe_alle),2) Prozentual_25_50,
Betriebe_50_75,
Round((Betriebe_50_75 / Betriebe_alle),2) Prozentual_50_75 ,
Betriebe_75_100  ,
Round((Betriebe_75_100 / Betriebe_alle),2) Prozentual_75_100

FROM
((SELECT ABJ_JAHR Jahr_alle,  Count(*) Betriebe_alle, Sum (INDIKATOR_BET), round(Sum (INDIKATOR_BET)/  Count(*),2) Indikator_alle FROM t_baseline GROUP BY ABJ_JAHR)
left JOIN
(SELECT ABJ_JAHR Jahr_25, Count(*) Betriebe_0_25 FROM t_baseline WHERE INDIKATOR_BET <= 25  GROUP BY ABJ_JAHR)
ON jahr_alle = jahr_25
left JOIN
(SELECT ABJ_JAHR Jahr_50, Count(*) Betriebe_25_50 FROM t_baseline WHERE INDIKATOR_BET > 25 AND INDIKATOR_BET <= 50  GROUP BY ABJ_JAHR)
ON jahr_alle = jahr_50
left JOIN
(SELECT ABJ_JAHR Jahr_75, Count(*) Betriebe_50_75 FROM t_baseline WHERE  INDIKATOR_BET > 50 AND INDIKATOR_BET <= 75   GROUP BY ABJ_JAHR)
ON jahr_alle = jahr_75
left JOIN
(SELECT ABJ_JAHR Jahr_100, Count(*) Betriebe_75_100 FROM t_baseline WHERE INDIKATOR_BET > 75  GROUP BY ABJ_JAHR)
ON jahr_alle = jahr_100)
ORDER BY jahr


