/*Date: 26-Feb -2021
File Name: 20210226_DBu_Attempt_to_retrieve_data_for_ki_result_v0.01
Created by: Divakar Budda (D.Budda)
Based on: None (Using 20210225_DBu_BDB_extraction_v0.14 as input for some sections)
Description: this file serves as single entity to retrieve all the data for the master table ki_result in the Binding Database


====================================================================================================================================================
-- Checking the number of records in ki_result table
====================================================================================================================================================
select count(*) from ki_result;--20,76,907
select count(ki_result_id) from ki_result;--20,76,907
select count(distinct ki_result_id) from ki_result;--20,76,907
select count(reactant_set_id) from ki_result;--20,76,907
select count(distinct reactant_set_id) from ki_result;--20,76,907
select count(distinct entryid) from ki_result;--41,241
-- Composite of entryid, ki_reult_id is used as the primary key for ki_result table: and the ki_result_id is same as that of ERS's reactant_set_id
*/
select count(*) from (select A.ENTRYID, A.KI_RESULT_ID, A.REACTANT_SET_ID, YY.*, A.ASSAYID, B.assay_name, B.description as Assay,A.E_CONC_RANGE, A.S_CONC_RANGE, A.I_CONC_RANGE, A.TEMP, A.TEMP_UNCERT, A.PRESS, A.PRESS_UNCERT, A.PH,
A.PH_UNCERT, A.IC50, A.IC50_UNCERT, A.EC50, A.EC50_UNCERT, A.IC_PERCENT_DEF, A.IC_PERCENT, A.IC_PERCENT_UNCERT, A.KI, A.KI_UNCERT, A.KD, A.KD_UNCERT, A.KOFF, A.KON, A.KM,
A.KM_UNCERT, A.VMAX, A.VMAX_UNCERT, A.K_CAT, A.K_CAT_UNCERT, A.DELTA_G, A.DELTA_G_UNCERT, A.BIOLOGICAL_DATA, A.SOLUTION_ID, 
S.solution_id,S.solution_type, S.solution_pH, S.solution_temp, S.solution_comments, S.solute_name, S.solute_purpose, S.solute_source,
S.solute_purity, S.solute_purity_method, S.solvent_comments, S.solvent_frac_or_conc, A.DATA_FIT_METH_ID, D.data_fit_meth_id, D.data_fit_meth_desc, A.INSTRUMENTID, 
Z.instrumentid, Z.name as Instrument,A.COMMENTS, A.KON_UNCERT, A.KOFF_UNCERT

from
ki_result A

left join 
assay B
on A.assayid = B.assayid

left join (
select s3.entryid as entryid, s3.solution_id as solution_id, s3.type solution_type, s3.ph_prep as solution_pH, s3.temp_prep as solution_temp, 
s3.comments as solution_comments,s1.name as solute_name, s1.purpose as solute_purpose, s1.source as solute_source, s1.purity as solute_purity, 
s1.pur_meth as solute_purity_method,s1.comments as solute_comments, s2.conc as solute_conc, s4.solventid, s4.name as solvent_name, s4.source as solvent_source, 
s4.purity as solvent_purity, s4.pur_meth as solvent_purity_method, s4.comments as solvent_comments,s5.conc_or_fract as solvent_frac_or_conc
from solute s1, solute_conc s2, solution_prep s3, solvent s4, solvent_fract s5
where s2.soluteid = s1.soluteid
AND
s3.solution_id = s2.solution_id
AND
s5.solution_id = s3.solution_id
AND
s5.solventid = s4.solventid
) S
on A.solution_id = S.solution_id


left join 
data_fit_meth D
on A.data_fit_meth_id = D.data_fit_meth_id

left join 
instrument Z
on A.instrumentid = Z.instrumentid

left join
(select er1.entryid, er1.reactant_set_id, er1.enzyme, er1.e_prep, AA.enzyme_poly_name, GG.enzyme_complex_name, er1.substrate, er1.s_prep, 
EE.substrate_mono_name, BB.substrate_poly_name, HH.substrate_complex_name,er1.inhibitor, er1.i_prep, FF.inhibitor_mono_name, CC.inhibitor_poly_name, 
II.inhibitor_complex_name, er1.comments, er1.category, er1.sources, DD.enzyme_mono_name 
from
enzyme_reactant_set er1 
left join
(select E.entryid,e.reactant_set_id, e.enzyme_polymerid, P.polymerid as enzyme_pl_id, P.poly_nm  as enzyme_poly_name from enzyme_reactant_set E,dbu_polymers P where E.enzyme_polymerid = P.polymerid) AA
on er1.reactant_set_id = AA.reactant_set_id
left join
(select E.entryid,e.reactant_set_id, e.substrate_polymerid, P.polymerid as substrate_pl_id, P.poly_nm as substrate_poly_name from enzyme_reactant_set E,dbu_polymers P where E.substrate_polymerid = P.polymerid) BB
on er1.reactant_set_id = BB.reactant_set_id
left join
(select E.entryid,e.reactant_set_id, e.inhibitor_polymerid, P.polymerid as inhibitor_pl_id, P.poly_nm as inhibitor_poly_name from enzyme_reactant_set E,dbu_polymers P where E.inhibitor_polymerid = P.polymerid) CC
on er1.reactant_set_id = CC.reactant_set_id
left join
(select E.entryid,e.reactant_set_id, e.enzyme_monomerid, M.monomerid as enzyme_mn_id, m.mono_nm  as enzyme_mono_name from enzyme_reactant_set E,dbu_monomers M where E.enzyme_monomerid is not null and E.enzyme_monomerid = M.monomerid) DD
on er1.reactant_set_id = DD.reactant_set_id
left join
(select E.entryid,e.reactant_set_id, e.substrate_monomerid, M.monomerid as substrate_mn_id, M.mono_nm as substrate_mono_name from enzyme_reactant_set E,dbu_monomers M where E.substrate_monomerid is not null and E.substrate_monomerid = M.monomerid) EE
on er1.reactant_set_id = EE.reactant_set_id
left join
(select E.entryid,e.reactant_set_id, e.inhibitor_monomerid, M.monomerid as inhibitor_mn_id, M.mono_nm as inhibitor_mono_name from enzyme_reactant_set E,dbu_monomers M where E.inhibitor_monomerid is not null and E.inhibitor_monomerid = M.monomerid) FF
on ER1.reactant_set_id = FF.reactant_set_id
left join
(select E.entryid,e.reactant_set_id, e.enzyme_complexid, C.complexid as enzyme_cm_id,c.name as enzyme_complex_name from enzyme_reactant_set E,complex_name C where E.enzyme_complexid is not null and E.enzyme_complexid = C.complexid) GG
on er1.reactant_set_id = GG.reactant_set_id
left join
(select E.entryid,e.reactant_set_id, e.substrate_complexid, C.complexid as substrate_cm_id, c.name as substrate_complex_name from enzyme_reactant_set E,complex_name C where E.substrate_complexid is not null and E.substrate_complexid = C.complexid) HH
on er1.reactant_set_id = HH.reactant_set_id
left join
(select E.entryid,e.reactant_set_id, e. inhibitor_complexid, C.complexid as inhibitor_cm_id, c.name as inhibitor_complex_name from enzyme_reactant_set E,complex_name C where E.inhibitor_complexid is not null and E.inhibitor_complexid = C.complexid) II
on ER1.reactant_set_id = II.reactant_set_id) YY
on A.reactant_set_id = YY.reactant_set_id
);-- cardinality shows 24,179,722,646 ~ 24 billion rows

--The above query gave me the combined output of all foreign key values for the master table ki_result