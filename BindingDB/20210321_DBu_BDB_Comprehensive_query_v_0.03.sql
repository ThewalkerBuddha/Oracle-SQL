/*Date: 21-Mar-2021
File Name: 20210321_DBu_DB_Comprehensive_query_v0.03
Created by: Divakar Budda (D.Budda)
Based on: 20210321_DBu_BDB_extraction_v0.19, 20210302_DBu_Binding_Database_Comprehensive_query_v0.02, 20210226_DBu_Attempt_to_retrieve_data_for_ki_result_v0.01, 20210226_DBu_BDB_extraction_v0.14, 20210301_DBu_ITC_tables_BDB_export_trial_v0.01
Description: This file contains the codes developed so far for the Binding Database data extraction from:
Ki_result_table (Main table), ITC_result_a_b_ab (isothermal titration calorimetry) table which provides Binding data


Key Notes: This script contains the code in BDB comprehensive code v0.02, with the updated code for KI_RESULT, ITC_RESULT_A_B_AB tables
i.e. non-duplicative results with modified script for solution, enzyme_reactant_set included entryid in the scripts

=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
KI_RESULTS
=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+

        ----------------------------------------------------------------------------------------------------------------------------------------------
        -- ki_results master table data depends on the foreign key values of different child tables
        ----------------------------------------------------------------------------------------------------------------------------------------------
        Ki_result table containg different foreign keys such as assayid, solution_id, data_fit_meth_id, instrumentid, reactant_set_id
        inorder to have the complete database data, we need to have the child tables data as well: 
        the advantage with this comprehensive code is we don't need to work extensively in the future, if we have input like an identifier we should be able to get all the data requried


        -------------------------------------------------
        -- Foreign key tables for ki_results master table
        -------------------------------------------------

        ASSAYS          : Assays table is pretty straight forward, hence we can directly write the query, no need to develop extensive code, in which we have to select the columns needed
        DATA_FIT_METH   : Data_fit_meth table is pretty straight forward, hence we can directly write the query, no need to develop extensive code, in which we have to select the columns needed
        INSTRUMENT      : Instrumemt table is pretty straight forward, hence we can directly write the query, no need to develop extensive code, in which we have to select the columns needed
        SOLUTION_ID {
            SOLUTION_PREP   :
            SOLUTE          :
            SOLUTE_CONC     :
            SOLVENT         :
            SOLVENT_FRAC    :
            }           : It depends on the above mentioned tables, we need to a join query to fetch all the details for a solution_id, like solute, solute_conc, solvent_solvent_conc etc

                        -- The below query provides data of different solutions used in the enzyme inhibition studies, with the solute, solvent, ph, temperature conditions along with the references for their individual entries i.e. Solution_entry_id, Solute_entry_id, solvent_entry_id etc
                        -- this output is to be combined with the enzyme inhibition studies data i.e. enzyme reactant set data to be combined with Ki_results data

                        >>>:
                        select s3.entryid as sp_entry_id, s3.solution_id as sp_soltn_id, s3.type, s3.ph_prep, s3.temp_prep, s3.comments as sp_comments,
                        s1.soluteid,s1.name as solute_name,s1.purpose as solute_purpose,s1.source as solute_source, s1.purity as solute_purity, s1.pur_meth as solute_pure_method,s1.comments as slt_comments,
                        s2.entryid as solute_conc_entry_id, s2.conc,
                        s4.solventid, s4.name as solvent_name, s4.source as solvent_source, s4.purity as solvent_purity, s4.pur_meth as solvent_purity_method,s4.comments as slvnt_comments,
                        s5.entryid as solvent_frac_entry_id,s5.conc_or_fract
                        from solute s1, solute_conc s2, solution_prep s3, solvent s4, solvent_fract s5
                        where s2.soluteid = s1.soluteid
                        AND
                        s3.solution_id = s2.solution_id
                        AND
                        s5.solution_id = s3.solution_id
                        AND
                        s5.solventid = s4.solventid;

        ENZYME_REACTANT_SET: This table contains foreign keys belonging to multiple other tables such as POLY_NAME, MONO_NAME, COMPLEX, COMPLEX_COMPONENT
                --We have to develope a code that pulls the data from all these tables; it took lot of time and during which stranger things were also observed: 
                details can be found in DBu_BDB_extraction files v0.05 and above: important points to be remembered are

                --------
                --------
                1. Duplicate record for the reactant_set_id: 246
                /*--Just checking the distinct reactant_set_ids, idea is to combine all different tables based on 
                --reactant_set_id to cope with the dissimilar strcuture of the columns from poly_name, mono_name, complex etc

                select count(*) from enzyme_reactant_set; --2076957--
                select count(distinct reactant_set_id) from enzyme_reactant_set;--2076956--
                select reactant_set_id from enzyme_reactant_set group by reactant_set_id having (count(*)>1);
                --it appears that reactant_set_id 246 has more than 1 row, reported the same to the Binding Database team through email

                --------
                --------
                2. Same polymerid's have different polymer names:
                for a single polymerid for example: polymerid 50007692 has 596 synonyms: the problem with this will be, when we use join or union queries, for every match the queries provides a row
                i.e. for one record of the above polymer in the ki_result table, we will get the combined result of 1*596 i.e. 596 which is costly and with 2.08 million records it leads to huge duplications
                    i. inorder to solve it i thought of creating a table with synonyms of each polymer in one column, polymerid in another: has done that with the help of 
                    --------------------------------------------------------------------------------------------------------------------------------
                    /*-- i got the output of all combined but the issue is, for the same polymerid i have different names, 
                    --now i am trying to create a table where i can have the columns, polymerid, polymer_name, synonyms (all the synonyms)

                    --trial 1: 
                    select polymerid, LISTAGG (name, ', ') within group (order by polymerid) as poly_id from poly_name group by polymerid;
                    -- it worked fine for the poly_name table, but figure that
                    -- this statement has limitation i.e. LISTAGG function won't be able to concatenate strings greater than 4000 bytes; hence new function has to be used instead

                    --trial 2:
                    select rtrim(xmlagg(xmlelement(polymerid,name, ', ').extract('//text()') order by polymerid).getclobval(),',') from poly_name group by polymerid;
                    --output of the statement shows that the script is escaping certain character such as & --> &amp, '--> apos etc

                    --trial 3:
                    --inorder to avoid that issue there was another script proposed by someone on stackoverflow: https://stackoverflow.com/a/23092500/11966129
                    --dbms_xmlgen.convert(xmlagg(xmlelement(E, name||',')).extract('//text()').getclobval(),1)
                >>>:
                    select polymerid,dbms_xmlgen.convert(xmlagg(xmlelement(polymerid, name||'| ')).extract('//text()').getclobval(),1)as poly_syno from poly_name group by polymerid;
                    --It worked fine.

                --------
                --------
                3. Same monomerid's have different monomer names:
                /*-- the above statement gave me output in format of polymerid, synonyms; now i have to do the same for the remaining two tables as well i.e. mono_name and complex tables
                select monomerid,dbms_xmlgen.convert(xmlagg(xmlelement(monomerid, name||'| ')).extract('//text()').getclobval(),5)as mono_syno from mono_name group by monomerid;
                -- the above statement throwed the error "ORA-64451: Conversion of special character to escaped character failed.". basically it means the special characters in the column values were unable to be converted
                -- 3 aspects here listagg, can't combine bytes over 4000, then rtrim approach as in trial 2 can't escape (convert) special characters with errors described at trial 2 output
                -- now i had to use the trial 3 approach to coombine the bytes > 4000 and also convert them, but here it says it cant convert some characters
                -- Solution is to inspect the string where the problem is, and its impossible with > 9.3 lac lines

                --------
                --------
                4. Special characters, duplicate primary keys for some monomers:
                /* it throwed the error of conversion of special character failed
                --idea is identifying those special characters
                --SELECT * FROM test WHERE REGEXP_LIKE(sampletext,  '[^]^A-Z^a-z^0-9^[^.^{^}^ ]' );(this query identifies all special character containing rows/records in the table: ref: https://stackoverflow.com/a/25140828/11966129
                --select * from mono_name where NOT regexp_like(name, '[ A-Za-z0-9.{}[]|]');ref: https://stackoverflow.com/a/25117706/11966129
                --the above query gave output with 12 records with identifiers :282972,289784,299743,300359,300360,300361,300362,300363,300364,300365,300366,300367
                -- i did try to update them couldn't do it
                -- upon inspecting those with the below query i saw
                select * from mono_name where name = ')';
                select * from mono_name where monomerid in (282972,289784,299743,300359,300360,300361,300362,300363,300364,300365,300366,300367);
                --which led to the conclusion that above monomer ids (primary key) have duplicate entries, which is messing with update data so
                --seems like the only possible way is to delete the records where the data is equal to ")"
                delete from mono_name M where name = ')';

                ---------
                ---------
                5. Created table dbu_poly_name to host the data like polymerid, poly_syno (synonyms of polymer)
                /* Lets create table without duplicate names for polymerid for now
                --tables created by me apart from those by BDB shoould have specific initial to differentiate from those in the BDB oracle dump file
                --tables starting with the initials DBu are created by me


                >>>:
                create table DBu_poly_name as 
                (select polymerid,dbms_xmlgen.convert(xmlagg(xmlelement(polymerid, name||'| ')).extract('//text()').getclobval(),1)as poly_syno from poly_name group by polymerid);
                --table created now it doesn't have duplicate rows for the same polymer name which saves the number of rows

                ----------
                ----------
                6. Simple query to fetch all the foregin key values for the master table enzyme_reactant_set

                ---------------------------------------------------------------------------------------------------------------------------------
                --Simple straight forward way fetching all FK data with the master table; rest will be figured out later
                ---------------------------------------------------------------------------------------------------------------------------------

                >>>:
                select er1.reactant_set_id,er1.enzyme,er1.e_prep,er1.enzyme_polymerid,comb1.polymerid,er1.enzyme_complexid, 
                comb3.complexid, comb3.cm_nm, er1.substrate,er1.s_prep,er1.substrate_monomerid,comb2.monomerid, comb2.mn_nm,
                er1.substrate_polymerid, comb1.polymerid, er1.substrate_complexid, comb3.complexid, comb3.cm_nm, er1.inhibitor,
                er1.i_prep,er1.inhibitor_monomerid,comb2.monomerid,comb2.mn_nm, er1.inhibitor_polymerid, comb1.polymerid, 
                er1.inhibitor_complexid,comb3.complexid,comb3.cm_nm,er1.comments,er1.category,er1.sources,er1.enzyme_monomerid,comb2.monomerid,
                comb2.mn_nm

                from enzyme_reactant_set ER1 
                left join
                (select E.entryid,e.reactant_set_id, P.polymerid from enzyme_reactant_set E,dbu_poly_name P where E.enzyme_polymerid is not null and E.enzyme_polymerid = P.polymerid
                union
                select E.entryid,e.reactant_set_id, P.polymerid from enzyme_reactant_set E,dbu_poly_name P where E.substrate_polymerid is not null and E.substrate_polymerid = P.polymerid
                union
                select E.entryid,e.reactant_set_id, P.polymerid from enzyme_reactant_set E,dbu_poly_name P where E.inhibitor_polymerid is not null and E.inhibitor_polymerid = P.polymerid)comb1
                on ER1.reactant_set_id = comb1.reactant_set_id
                left join
                (select E.entryid,e.reactant_set_id, M.monomerid, m.name as mn_nm from enzyme_reactant_set E,mono_name M where E.enzyme_monomerid is not null and E.enzyme_monomerid = M.monomerid
                union
                select E.entryid,e.reactant_set_id, M.monomerid, M.name as mn_nm from enzyme_reactant_set E,mono_name M where E.substrate_monomerid is not null and E.substrate_monomerid = M.monomerid
                union
                select E.entryid,e.reactant_set_id, M.monomerid, M.name as mn_nm from enzyme_reactant_set E,mono_name M where E.inhibitor_monomerid is not null and E.inhibitor_monomerid = M.monomerid) comb2
                on ER1.reactant_set_id = comb2.reactant_set_id
                left join
                (select E.entryid,e.reactant_set_id, C.complexid,c.name as cm_nm from enzyme_reactant_set E,complex_name C where E.enzyme_complexid is not null and E.enzyme_complexid = C.complexid
                union
                select E.entryid,e.reactant_set_id, C.complexid, c.name as cm_nm from enzyme_reactant_set E,complex_name C where E.substrate_complexid is not null and E.substrate_complexid = C.complexid
                union
                select E.entryid,e.reactant_set_id, C.complexid, c.name as cm_nm from enzyme_reactant_set E,complex_name C where E.inhibitor_complexid is not null and E.inhibitor_complexid = C.complexid) comb3
                on ER1.reactant_set_id = comb3.reactant_set_id;--21,86,082
                --above script gave me a combined output of all foreign keys related to the master table of enzyme_reactant_set; still there seems to be lot of duplicate records
                -- checked the above script if it is giving me all reactant_set_id details with (select count(distinct reactant_set_id) from (the above statement))# it gave me 20,76,956
                --which is equal to the distinct reactant_set_id from the enzyme_reactant_set##Meaning we have not missed any reactant_set_id
                select count(*) from enzyme_reactant_set;--20,76,957
                select count(distinct reactant_set_id) from enzyme_reactant_set;--2076956

                select * from enzyme_reactant_set where reactant_set_id = 246;-- for this reactant_set_id we have two entries entrid: 2524,6159


                ----------
                ----------
                7. synonyms of monomers again led to huge dupications resulting in enormous number of records for the query for master table enzyme_reactant_set
                    i. as we observed earlier, listagg or xmlconvert methods didn't work with the error of cant convert special character to escape character
                    ii. Tried to convert the strings into characters and then use the xml convert like below
                            
                            >>>:
                            select monomerid, dbms_xmlgen.convert(xmlagg(xmlelement(monomerid, name||'| ')).extract('//text()').getclobval(),1)as mono_syno from (
                            select monomerid,to_char(to_char(name)) as name from mono_name) group by monomerid;

                            -- conclusion: there is no solution to the error "ORA-64451: Conversion of special character to escaped character failed.". no use even with using 9 lac rows
                            --or converting it into string characters before performing the concatenation also didn't wor
                            -- i think the best solution would be to export the tables with monomerids and then try to have the concatenated monomer names with python/ R script
                    iii. Now the idea is to prepare the comprehensive list of monomerids with matched records in enzyme, substrate, inhibitor then try to prepare the synonyms
                            -------------------------------------------------------------------------------------------------------------------------------------------------
                            /* Below script gives a table containing the uninon of monomerids for enzyme, substrate, inhibitor matched with those of monomerid from mono_name
                            --Also removes names that are starting with BDBM, CID, CHEMB
                            -------------------------------------------------------------------------------------------------------------------------------------------------
                            
                            >>>:
                            select count(distinct enzyme_monomerid) from (select * from (select distinct ers.enzyme_monomerid, d1.name as monomer_name from enzyme_reactant_set ers, mono_name d1 where enzyme_monomerid = d1.monomerid
                            UNION
                            select ers.substrate_monomerid, d1.name as monomer_name from enzyme_reactant_set ers, mono_name d1 where ers.substrate_monomerid = d1.monomerid
                            UNION
                            select ers.inhibitor_monomerid, d1.name as monomer_name from enzyme_reactant_set ers, mono_name d1 where ers.inhibitor_monomerid = d1.monomerid)
                            where monomer_name not like 'BDBM%' AND monomer_name not like 'cid%' AND monomer_name not like 'CHEMB%');--6,67,490 records
                    iv. This time we are making use of the function "FIRST_VALUE". it basically fetches the value for th first match for records with more than one match

                            >>>:
                            select monomerid, first_value(name) over(partition by monomerid) from mono_name order by name;
                            --basically the above statement gives first_value (i.e. first record match value) from the identifier matches
                            --if we combine the above monomerid matches with this first_value function maybe we can identify non duplicate monomer names for those

                            -------------------------------------------------------------------------------------------------------------------------------------------------
                            --Having all the monomerid values into one single table which can be later combined with query to fetch their names
                            -------------------------------------------------------------------------------------------------------------------------------------------------
                            
                            >>>:
                            select distinct (v1.monomerid) as monom, first_value(v2.name) over(partition by v2.monomerid) as monomer_name from (select distinct monomerid from (select ers.enzyme_monomerid as monomerid, d1.name as monomer_name from enzyme_reactant_set ers, mono_name d1 where enzyme_monomerid = d1.monomerid
                            UNION
                            select ers.substrate_monomerid as monomerid, d1.name as monomer_name from enzyme_reactant_set ers, mono_name d1 where ers.substrate_monomerid = d1.monomerid
                            UNION
                            select ers.inhibitor_monomerid as monomerid, d1.name as monomer_name from enzyme_reactant_set ers, mono_name d1 where ers.inhibitor_monomerid = d1.monomerid)
                            where monomer_name not like 'BDBM%' AND monomer_name not like 'cid%' AND monomer_name not like 'CHEMB%') v1
                            left join
                            mono_name v2
                            on v1.monomerid = v2.monomerid;--count is 6,67,490

                            -- the above query gave me output as required but  i am still missing monomer names for some probably because i had filtered them off with cid, chemb, bdbm
                            -- i might have to change it to normal or remove some exception then it shoul be fine

                    v. we observed that the above query seems to do its job. we checked if we are missing any monomerids during the fetch/ method with the below codes

                            /*
                            -------------------------------------------------------------------------------------------------------------------------------------------------
                            -- Lets try another way to do this now. basically all i need is first name for all of distinct monomderids, then checking if all monomerids
                            -- then checking if all the monomerds were represented from the mono_name table by count check
                            -------------------------------------------------------------------------------------------------------------------------------------------------
                            
                            >>>:
                            select monomerid, first_value(name) over(partition by monomerid) from mono_name order by monomerid;--17,61,770
                            select count(*) from (select distinct monomerid, first_value(name) over(partition by monomerid) from mono_name order by monomerid);--9,31,570
                            select count(distinct monomerid) from mono_name;--9,31,570
                            */


                            /*
                            -------------------------------------------------------------------------------------------------------------------------------------------------
                            --Now a simple check if the combined monomer details from enzyme, substrate, inhibitor are equal to the first_names we got from the first_value query
                            -------------------------------------------------------------------------------------------------------------------------------------------------
                            
                            >>>:
                            select count(*) from (select distinct (v1.monomerid) as monom from (select distinct monomerid from (select ers.enzyme_monomerid as monomerid, d1.name as monomer_name from enzyme_reactant_set ers, mono_name d1 where enzyme_monomerid = d1.monomerid
                            UNION
                            select ers.substrate_monomerid as monomerid, d1.name as monomer_name from enzyme_reactant_set ers, mono_name d1 where ers.substrate_monomerid = d1.monomerid
                            UNION
                            select ers.inhibitor_monomerid as monomerid, d1.name as monomer_name from enzyme_reactant_set ers, mono_name d1 where ers.inhibitor_monomerid = d1.monomerid)) v1
                            left join
                            mono_name v2
                            on v1.monomerid = v2.monomerid);--9,14,814; 
                            --hence its equal so as to say we are not missing any values
                            

                ------------
                ------------
                8. After discovering the FIRST_VALUE function, we created specific tables that holds monomer, polymer names and their first_value as mono_nm

                    >>>:
                    create table dbu_mono_name as
                    select distinct monomerid, first_value(name) over (partition by monomerid) as mono_nm from mono_name order by monomerid;
                    select count(*) from dbu_mono_name;--9,31,570
                    select count(distinct monomerid) from mono_name;--9,31,570

                9. When trying to combine the dbu_poly_name, dbu_mono_name with enzyme_reactant_set we got the data type CLOB error with polymers
                        i. Inorder to handle the issue we developed two new tables using the FIRST_VALUE function for both monomers, polymers

                            -------------------------------------------------------------------------------------------------------------------------------------
                            -- Now creating tables for simple monomer names, polymer names to combine with master query rather than longitudinal big names
                            -------------------------------------------------------------------------------------------------------------------------------------
                            create table dbu_monomers as
                            select distinct monomerid, first_value(name) over (partition by monomerid) as mono_nm from 
                            (select monomerid, name from mono_name order by monomerid, length(name)asc);

                            create table dbu_polymers as
                            select distinct polymerid, first_value(name) over (partition by polymerid) as poly_nm from 
                            (select polymerid, name from poly_name order by polymerid, length(name)asc);
                10. Query combining monomers, polymers, enzyme_reactant_set table in one

                        >>>:
                        ------------------------------------------------------------------------------------------------------------------------------------------------
                        --Now the target is to get the full master table of enzyme_reactant_set
                        ------------------------------------------------------------------------------------------------------------------------------------------------
                        select er1.entryid, er1.reactant_set_id, er1.enzyme, er1.e_prep, A.enzyme_polymerid, A.enzyme_pl_id, A.enzyme_poly_name, G.enzyme_complexid, 
                        G.enzyme_cm_id, G.enzyme_complex_name, er1.substrate, er1.s_prep, E.substrate_monomerid, E.substrate_mn_id,E.substrate_mono_name, 
                        B.substrate_polymerid, B.substrate_pl_id,B.substrate_poly_name, H.substrate_complexid, H.substrate_cm_id, H.substrate_complex_name,er1.inhibitor,
                        er1.i_prep, F.inhibitor_monomerid, F.inhibitor_mn_id, F.inhibitor_mono_name,C.inhibitor_polymerid, C.inhibitor_pl_id, C.inhibitor_poly_name, 
                        I.inhibitor_complexid, I.inhibitor_cm_id, I.inhibitor_complex_name, er1.comments, er1.category, er1.sources, D.enzyme_monomerid,D.enzyme_mn_id,
                        D.enzyme_mono_name  
                        
                        from

                        enzyme_reactant_set er1 
                        left join
                        (select E.entryid,e.reactant_set_id, e.enzyme_polymerid, P.polymerid as enzyme_pl_id, P.poly_nm  as enzyme_poly_name from enzyme_reactant_set E,dbu_polymers P where E.enzyme_polymerid = P.polymerid) A
                        on er1.reactant_set_id = A.reactant_set_id
                        left join
                        (select E.entryid,e.reactant_set_id, e.substrate_polymerid, P.polymerid as substrate_pl_id, P.poly_nm as substrate_poly_name from enzyme_reactant_set E,dbu_polymers P where E.substrate_polymerid = P.polymerid) B
                        on er1.reactant_set_id = B.reactant_set_id
                        left join
                        (select E.entryid,e.reactant_set_id, e.inhibitor_polymerid, P.polymerid as inhibitor_pl_id, P.poly_nm as inhibitor_poly_name from enzyme_reactant_set E,dbu_polymers P where E.inhibitor_polymerid = P.polymerid) C
                        on er1.reactant_set_id = C.reactant_set_id
                        left join
                        (select E.entryid,e.reactant_set_id, e.enzyme_monomerid, M.monomerid as enzyme_mn_id, m.mono_nm  as enzyme_mono_name from enzyme_reactant_set E,dbu_monomers M where E.enzyme_monomerid is not null and E.enzyme_monomerid = M.monomerid) D
                        on er1.reactant_set_id = D.reactant_set_id
                        left join
                        (select E.entryid,e.reactant_set_id, e.substrate_monomerid, M.monomerid as substrate_mn_id, M.mono_nm as substrate_mono_name from enzyme_reactant_set E,dbu_monomers M where E.substrate_monomerid is not null and E.substrate_monomerid = M.monomerid) E
                        on er1.reactant_set_id = E.reactant_set_id
                        left join
                        (select E.entryid,e.reactant_set_id, e.inhibitor_monomerid, M.monomerid as inhibitor_mn_id, M.mono_nm as inhibitor_mono_name from enzyme_reactant_set E,dbu_monomers M where E.inhibitor_monomerid is not null and E.inhibitor_monomerid = M.monomerid) F
                        on ER1.reactant_set_id = F.reactant_set_id
                        left join
                        (select E.entryid,e.reactant_set_id, e.enzyme_complexid, C.complexid as enzyme_cm_id,c.name as enzyme_complex_name from enzyme_reactant_set E,complex_name C where E.enzyme_complexid is not null and E.enzyme_complexid = C.complexid) G
                        on er1.reactant_set_id = G.reactant_set_id
                        left join
                        (select E.entryid,e.reactant_set_id, e.substrate_complexid, C.complexid as substrate_cm_id, c.name as substrate_complex_name from enzyme_reactant_set E,complex_name C where E.substrate_complexid is not null and E.substrate_complexid = C.complexid) H
                        on er1.reactant_set_id = H.reactant_set_id
                        left join
                        (select E.entryid,e.reactant_set_id, e. inhibitor_complexid, C.complexid as inhibitor_cm_id, c.name as inhibitor_complex_name from enzyme_reactant_set E,complex_name C where E.inhibitor_complexid is not null and E.inhibitor_complexid = C.complexid) I
                        on ER1.reactant_set_id = I.reactant_set_id;--21,75,150 (compared to 20,76,957 rows in the enzyme_reactant_set table)
                        --distinct reactant_set ids from the above query (20,76,956) (compared to 20,76,956 distinct reactant_set_id from enzyme_reactant_set table)
                        -- the above query gave all foregin key values to the master table; now lets try to remove the ids such as polymerid, monomerid, complexid to make it look clean
                
                11. Final enzyme_reactant_set table without any identier columns for clean overview

                        >>>:
                        -------------------------------------------------------------------------------------------------------------------------------------------------
                        -- The below query has the same information as above, but we are selecting only specific columns to see clean view of the relevant columns
                        -------------------------------------------------------------------------------------------------------------------------------------------------
                        
                        >>>:
                        select count(distinct reactant_set_id) from (
                        select er1.entryid, er1.reactant_set_id, er1.enzyme, er1.e_prep, A.enzyme_poly_name, G.enzyme_complex_name, er1.substrate, er1.s_prep, 
                        E.substrate_mono_name, B.substrate_poly_name, H.substrate_complex_name,er1.inhibitor, er1.i_prep, F.inhibitor_mono_name, C.inhibitor_poly_name, 
                        I.inhibitor_complex_name, er1.comments, er1.category, er1.sources, D.enzyme_mono_name 

                        from

                        enzyme_reactant_set er1 
                        left join
                        (select E.entryid,e.reactant_set_id, e.enzyme_polymerid, P.polymerid as enzyme_pl_id, P.poly_nm  as enzyme_poly_name from enzyme_reactant_set E,dbu_polymers P where E.enzyme_polymerid = P.polymerid) A
                        on er1.reactant_set_id = A.reactant_set_id
                        left join
                        (select E.entryid,e.reactant_set_id, e.substrate_polymerid, P.polymerid as substrate_pl_id, P.poly_nm as substrate_poly_name from enzyme_reactant_set E,dbu_polymers P where E.substrate_polymerid = P.polymerid) B
                        on er1.reactant_set_id = B.reactant_set_id
                        left join
                        (select E.entryid,e.reactant_set_id, e.inhibitor_polymerid, P.polymerid as inhibitor_pl_id, P.poly_nm as inhibitor_poly_name from enzyme_reactant_set E,dbu_polymers P where E.inhibitor_polymerid = P.polymerid) C
                        on er1.reactant_set_id = C.reactant_set_id
                        left join
                        (select E.entryid,e.reactant_set_id, e.enzyme_monomerid, M.monomerid as enzyme_mn_id, m.mono_nm  as enzyme_mono_name from enzyme_reactant_set E,dbu_monomers M where E.enzyme_monomerid is not null and E.enzyme_monomerid = M.monomerid) D
                        on er1.reactant_set_id = D.reactant_set_id
                        left join
                        (select E.entryid,e.reactant_set_id, e.substrate_monomerid, M.monomerid as substrate_mn_id, M.mono_nm as substrate_mono_name from enzyme_reactant_set E,dbu_monomers M where E.substrate_monomerid is not null and E.substrate_monomerid = M.monomerid) E
                        on er1.reactant_set_id = E.reactant_set_id
                        left join
                        (select E.entryid,e.reactant_set_id, e.inhibitor_monomerid, M.monomerid as inhibitor_mn_id, M.mono_nm as inhibitor_mono_name from enzyme_reactant_set E,dbu_monomers M where E.inhibitor_monomerid is not null and E.inhibitor_monomerid = M.monomerid) F
                        on ER1.reactant_set_id = F.reactant_set_id
                        left join
                        (select E.entryid,e.reactant_set_id, e.enzyme_complexid, C.complexid as enzyme_cm_id,c.name as enzyme_complex_name from enzyme_reactant_set E,complex_name C where E.enzyme_complexid is not null and E.enzyme_complexid = C.complexid) G
                        on er1.reactant_set_id = G.reactant_set_id
                        left join
                        (select E.entryid,e.reactant_set_id, e.substrate_complexid, C.complexid as substrate_cm_id, c.name as substrate_complex_name from enzyme_reactant_set E,complex_name C where E.substrate_complexid is not null and E.substrate_complexid = C.complexid) H
                        on er1.reactant_set_id = H.reactant_set_id
                        left join
                        (select E.entryid,e.reactant_set_id, e. inhibitor_complexid, C.complexid as inhibitor_cm_id, c.name as inhibitor_complex_name from enzyme_reactant_set E,complex_name C where E.inhibitor_complexid is not null and E.inhibitor_complexid = C.complexid) I
                        on ER1.reactant_set_id = I.reactant_set_id
                        )
                        ;-- gave 21,75,150 rows as it did in the above query as well, with 20,76,956 distinct reactant_set_id values as above; meaning we missed no data

        =====================================================================================================================================================================================
        --Below query combines the foreign key value queries of data_fit_meth, enzyme_reactant_set, mono_name, poly_name, complex, solution_prep, solute, solute_conc, solvent, solvent_fract
        =====================================================================================================================================================================================
            -- Below is the query updated to remove redundant, erroraneous duplicate matches and give the correct rows as opposed to the previous comprehensive query
            ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            -- Checking the number of records in ki_result table
            ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
            select count(*) from ki_result;--20,76,907
            select count(ki_result_id) from ki_result;--20,76,907
            select count(distinct ki_result_id) from ki_result;--20,76,907
            select count(reactant_set_id) from ki_result;--20,76,907
            select count(distinct reactant_set_id) from ki_result;--20,76,907
            select count(distinct entryid) from ki_result;--41,241
            -- Composite of entryid, ki_reult_id is used as the primary key for ki_result table: and the ki_result_id is same as that of ERS's reactant_set_id

            >>>:

            select A.ENTRYID, A.KI_RESULT_ID, A.REACTANT_SET_ID, YY.*, A.ASSAYID, B.assay_name, B.description as Assay,A.E_CONC_RANGE, A.S_CONC_RANGE, A.I_CONC_RANGE, A.TEMP, A.TEMP_UNCERT, A.PRESS, A.PRESS_UNCERT, A.PH,
            A.PH_UNCERT, A.IC50, A.IC50_UNCERT, A.EC50, A.EC50_UNCERT, A.IC_PERCENT_DEF, A.IC_PERCENT, A.IC_PERCENT_UNCERT, A.KI, A.KI_UNCERT, A.KD, A.KD_UNCERT, A.KOFF, A.KON, A.KM,
            A.KM_UNCERT, A.VMAX, A.VMAX_UNCERT, A.K_CAT, A.K_CAT_UNCERT, A.DELTA_G, A.DELTA_G_UNCERT, A.BIOLOGICAL_DATA, A.SOLUTION_ID, 
            S.solution_id,S.solution_type, S.solution_pH, S.solution_temp, S.solution_comments, S.solute_name, S.solute_purpose, S.solute_source,
            S.solute_purity, S.solute_purity_method, S.solvent_comments, S.solvent_frac_or_conc, A.DATA_FIT_METH_ID, D.data_fit_meth_id, D.data_fit_meth_desc, A.INSTRUMENTID, 
            Z.instrumentid, Z.name as Instrument,A.COMMENTS, A.KON_UNCERT, A.KOFF_UNCERT

            from
            ki_result A

            left join 
            assay B
            on A.assayid = B.assayid AND A.entryid = B.entryid
            -- it's observed that solution mapping lead to so many duplicate records, now we are changing the query to give non-duplicate results
            left join (
            select s3.entryid as entryid, s3.solution_id as solution_id, s3.type solution_type, s3.ph_prep as solution_pH, s3.temp_prep as solution_temp, 
            s3.comments as solution_comments,s1.name as solute_name, s1.purpose as solute_purpose, s1.source as solute_source, s1.purity as solute_purity, 
            s1.pur_meth as solute_purity_method,s1.comments as solute_comments, s2.conc as solute_conc, s4.solventid, s4.name as solvent_name, s4.source as solvent_source, 
            s4.purity as solvent_purity, s4.pur_meth as solvent_purity_method, s4.comments as solvent_comments,s5.conc_or_fract as solvent_frac_or_conc
            from solute s1
            left join solute_conc s2
            on s2.soluteid = s1.soluteid
            left join solution_prep s3
            on s3.solution_id = s2.solution_id
            left join solvent_fract s5
            on s5.solution_id = s3.solution_id
            left join solvent s4
            on s5.solventid = s4.solventid
            where s2.entryid = s3.entryid AND s3.entryid= s5.entryid--6306 rows
            ) S
            on A.solution_id = S.solution_id AND A.entryid = S.entryid


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
            on er1.reactant_set_id = II.reactant_set_id) YY
            on A.reactant_set_id = YY.reactant_set_id AND A.entryid = YY.entryid
            ;-- 24,01,038  Rows
            
            -- above query gave the required output; it working perfectly
            --let's try to implement the same for the itc_results_a_b_ab table as well

=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
ITC_RESULT_A_B_AB
=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
        ----------------------------------------------------------------------------------------------------------------------------------------------
        -- ITC_RESULT_A_B_AB master table data depends on the foreign key values of different child tables
        ----------------------------------------------------------------------------------------------------------------------------------------------
        Ki_result table containg different foreign keys such as solution_id, data_fit_meth_id, instrumentid, monomerid, polymerid, complexid
        inorder to have the complete database data, we need to have the child tables data as well: 
        the advantage with this comprehensive code is we don't need to work extensively in the future, if we have input like an identifier we should be able to get all the data requried


        --------------------------------------------------------
        -- Foreign key tables for ITC_RESULT_A_B_AB master table
        --------------------------------------------------------
        DATA_FIT_METH   : Data_fit_meth table is pretty straight forward, hence we can directly write the query, no need to develop extensive code, in which we have to select the columns needed
        INSTRUMENT      : Instrumemt table is pretty straight forward, hence we can directly write the query, no need to develop extensive code, in which we have to select the columns needed
        SOLUTION_ID {
            SOLUTION_PREP   :
            SOLUTE          :
            SOLUTE_CONC     :
            SOLVENT         :
            SOLVENT_FRAC    :
            }           : It depends on the above mentioned tables, we need to a join query to fetch all the details for a solution_id, like solute, solute_conc, solvent_solvent_conc etc

                        -- The below query provides data of different solutions used in the enzyme inhibition studies, with the solute, solvent, ph, temperature conditions along with the references for their individual entries i.e. Solution_entry_id, Solute_entry_id, solvent_entry_id etc
                        -- this output is to be combined with the enzyme inhibition studies data i.e. enzyme reactant set data to be combined with Ki_results data

                        >>>:
                        select s3.entryid as sp_entry_id, s3.solution_id as sp_soltn_id, s3.type, s3.ph_prep, s3.temp_prep, s3.comments as sp_comments,
                        s1.soluteid,s1.name as solute_name,s1.purpose as solute_purpose,s1.source as solute_source, s1.purity as solute_purity, s1.pur_meth as solute_pure_method,s1.comments as slt_comments,
                        s2.entryid as solute_conc_entry_id, s2.conc,
                        s4.solventid, s4.name as solvent_name, s4.source as solvent_source, s4.purity as solvent_purity, s4.pur_meth as solvent_purity_method,s4.comments as slvnt_comments,
                        s5.entryid as solvent_frac_entry_id,s5.conc_or_fract
                        from solute s1, solute_conc s2, solution_prep s3, solvent s4, solvent_fract s5
                        where s2.soluteid = s1.soluteid
                        AND
                        s3.solution_id = s2.solution_id
                        AND
                        s5.solution_id = s3.solution_id
                        AND
        MONOMERID       : This is primary key from the table mono_name, which is pretty straight forward, hence we can directly write the query, no need to develop extensive code, in which we have to select the columns needed
        POLYMERID       : This is primary key from the table poly_name, which is pretty straight forward, hence we can directly write the query, no need to develop extensive code, in which we have to select the columns needed
        COMPLEXID       : This is primary key from the table complex, which is pretty straight forward, hence we can directly write the query, no need to develop extensive code, in which we have to select the columns needed
       
        =====================================================================================================================================================================================
        --Below query combines the foreign key value queries of data_fit_meth, mono_name, poly_name, complex, solution_prep, solute, solute_conc, solvent, solvent_fract
        =====================================================================================================================================================================================

            ----------------------------------------------------------------------------------------------------------------------------------------------------
            --Below code is an attempt to, fetch all foregin key values to the table itc_result_a_b_ab
            ----------------------------------------------------------------------------------------------------------------------------------------------------

            select i.ENTRYID, i.ITC_RESULT_A_B_AB_ID, i.CELL_REACT, i.CELL_MONOMERID, i.CELL_POLYMERID, i.CELL_COMPLEXID, i.CELL_REACT_SOURCE, i.CELL_REACT_PURITY, 
            i.CELL_REACT_PREP_METH, i.SYR_REACT, i.SYR_MONOMERID, i.SYR_POLYMERID, i.SYR_COMPLEXID, i.SYR_REACT_SOURCE, i.SYR_REACT_PURITY, i.SYR_REACT_PREP_METH,
            i.ITC_SOLUTION_ID, i.PH, i.PH_UNCERT, i.TEMP, i.TEMP_UNCERT, i.PRESS, i.PRESS_UNCERT, i.ION_STR, ION_STR_UNCERT, i.STOICH_FREE_PARAM, i.STOICH_PARAM, 
            i.FIT_SD,i.HEAT_DIL_CORR, i.HEAT_ION_CORR, i.NUM_PROTON, i.DELTA_H_OBS, i.DELTA_H_OBS_UNCERT, i.K, i.K_UNCERT, i.DELTA_G0, i.DELTA_G0_UNCERT, i.DELTA_H0, 
            i.DELTA_H0_UNCERT,i.DELTA_CP, i.DELTA_CP_UNCERT, i.DELTA_S0, i.DELTA_S0_UNCERT, i.DATA_FIT_METH_ID, i.INSTRUMENTID, i.COMMENTS 

            from 
            itc_result_a_b_ab i;

            m.monomerid, m.mono_nm from dbu_monomers m
            p.polymerid, p.poly_nm from dbu_polymers p
            c.complexid, c.name as complex_nm from complex_name c



            ------------------------------------------------------------------------------------------------------------------------------------------------
            -- Attempt 1 to combine the above queries
            ------------------------------------------------------------------------------------------------------------------------------------------------
            
            >>>:
            select i.ENTRYID, i.ITC_RESULT_A_B_AB_ID, i.CELL_REACT, i.CELL_MONOMERID, CM.cell_mn_id, CM.cell_mono_nm, i.CELL_POLYMERID, CP.cell_pl_id, 
            CP.cell_poly_nm, i.CELL_COMPLEXID, CC.cell_cm_id, CC.Cell_complex_nm, i.CELL_REACT_SOURCE, i.CELL_REACT_PURITY, i.CELL_REACT_PREP_METH, 
            i.SYR_REACT, i.SYR_MONOMERID, SM.syr_mn_id, SM.syr_mono_nm, i.SYR_POLYMERID, SP.syr_pl_id, SP.syr_poly_nm, i.SYR_COMPLEXID, SC.syr_cm_id, 
            SC.syr_complex_nm, i.SYR_REACT_SOURCE, i.SYR_REACT_PURITY, i.SYR_REACT_PREP_METH, i.ITC_SOLUTION_ID, S.solution_id, S.solution_type, 
            S.solution_pH, S.solution_temp, S.solution_comments, S.solute_name, S.solute_purpose, S.solute_source, S.solute_purity, S.solute_purity_method, 
            S.solvent_comments, S.solvent_frac_or_conc, i.PH, i.PH_UNCERT, i.TEMP, i.TEMP_UNCERT, i.PRESS, i.PRESS_UNCERT, i.ION_STR, ION_STR_UNCERT, 
            i.STOICH_FREE_PARAM, i.STOICH_PARAM, i.FIT_SD,i.HEAT_DIL_CORR, i.HEAT_ION_CORR, i.NUM_PROTON, i.DELTA_H_OBS, i.DELTA_H_OBS_UNCERT, i.K, i.K_UNCERT, 
            i.DELTA_G0, i.DELTA_G0_UNCERT, i.DELTA_H0, i.DELTA_H0_UNCERT,i.DELTA_CP, i.DELTA_CP_UNCERT, i.DELTA_S0, i.DELTA_S0_UNCERT, i.DATA_FIT_METH_ID, 
            D.data_fit_meth_id, D.data_fit_meth_desc, i.INSTRUMENTID, Z.instrumentid, Z.name as Instrument, i.COMMENTS

            from
            itc_result_a_b_ab i

            left join
            (select A.entryid,A.itc_result_a_b_ab_id, A.cell_react,A.cell_monomerid,B.monomerid as cell_mn_id, B.mono_nm as cell_mono_nm from itc_result_a_b_ab A, dbu_monomers B where A.cell_monomerid = B.monomerid) CM
            on i.entryid = CM.entryid AND i.itc_result_a_b_ab_id = CM.itc_result_a_b_ab_id
            left join
            (select A.entryid,A.itc_result_a_b_ab_id, A.syr_react,A.syr_monomerid,B.monomerid as syr_mn_id, B.mono_nm as syr_mono_nm from itc_result_a_b_ab A, dbu_monomers B where A.syr_monomerid = B.monomerid) SM
            on i.entryid = SM.entryid AND i.itc_result_a_b_ab_id = SM.itc_result_a_b_ab_id
            left join
            (select A.entryid,A.itc_result_a_b_ab_id, A.cell_react,A.cell_polymerid,P.polymerid as cell_pl_id, P.poly_nm as cell_poly_nm from itc_result_a_b_ab A, dbu_polymers P where A.cell_polymerid = P.polymerid) CP
            on i.entryid = CP.entryid AND i.itc_result_a_b_ab_id = CP.itc_result_a_b_ab_id
            left join
            (select A.entryid,A.itc_result_a_b_ab_id, A.cell_react,A.syr_polymerid,P.polymerid as syr_pl_id, P.poly_nm as syr_poly_nm from itc_result_a_b_ab A, dbu_polymers P where A.syr_polymerid = P.polymerid) SP
            on i.entryid = SP.entryid AND i.itc_result_a_b_ab_id = SP.itc_result_a_b_ab_id
            left join
            (select A.entryid,A.itc_result_a_b_ab_id, A.cell_react,A.cell_complexid,C.complexid as cell_cm_id, C.name as cell_complex_nm from itc_result_a_b_ab A, complex_name C where A.cell_complexid = C.complexid) CC
            on i.entryid = CC.entryid AND i.itc_result_a_b_ab_id = CC.itc_result_a_b_ab_id
            left join
            (select A.entryid,A.itc_result_a_b_ab_id, A.cell_react,A.syr_complexid,C.complexid as syr_cm_id, C.name as syr_complex_nm from itc_result_a_b_ab A, complex_name C where A.syr_complexid = C.complexid) SC
            on i.entryid = SC.entryid AND i.itc_result_a_b_ab_id = SC.itc_result_a_b_ab_id

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
            on i.itc_solution_id = S.solution_id


            left join 
            data_fit_meth D
            on i.data_fit_meth_id = D.data_fit_meth_id

            left join 
            instrument Z
            on i.instrumentid = Z.instrumentid;-- cardinality was 26,254,350,040,747 ~ 26 trillion rows
            -- I was able to get all the foreign key values for the master table itc_result, but we will not be needing all rows we have to 
            --filter these out with the required receptors data
            -- it was successful--*/



            -------------------------------------------------------------------------------------------------------------------------------------------------
            -- Below query is same as above except it removes the identifiers removes redundant erroraneous rows
            -------------------------------------------------------------------------------------------------------------------------------------------------
            
            >>>:

            select i.ENTRYID, i.ITC_RESULT_A_B_AB_ID, i.CELL_REACT, i.CELL_MONOMERID, CM.cell_mn_id, CM.cell_mono_nm, i.CELL_POLYMERID, CP.cell_pl_id, 
            CP.cell_poly_nm, i.CELL_COMPLEXID, CC.cell_cm_id, CC.Cell_complex_nm, i.CELL_REACT_SOURCE, i.CELL_REACT_PURITY, i.CELL_REACT_PREP_METH, 
            i2.ENTRYID, i2.ITC_RESULT_A_B_AB_ID, i2.ITC_RUN_A_B_AB_ID, i2.CELL_REACT_CONC, i2.CELL_REACT_CONC_UNIT, i2.CELL_REACT_VOL,
            i.SYR_REACT, i.SYR_MONOMERID, SM.syr_mn_id, SM.syr_mono_nm, i.SYR_POLYMERID, SP.syr_pl_id, SP.syr_poly_nm, i.SYR_COMPLEXID, SC.syr_cm_id, 
            SC.syr_complex_nm, i.SYR_REACT_SOURCE, i.SYR_REACT_PURITY, i.SYR_REACT_PREP_METH, i.ITC_SOLUTION_ID, 
            i2.SYR_REACT_CONC, i2.SYR_REACT_CONC_UNIT, i2.SYR_INJ_VOL, i2.COMMENTS, i2.RAW_DATA_FILE, S.solution_id, S.solution_type, 
            S.solution_pH, S.solution_temp, S.solution_comments, S.solute_name, S.solute_purpose, S.solute_source, S.solute_purity, S.solute_purity_method, 
            S.solvent_comments, S.solvent_frac_or_conc, i.PH, i.PH_UNCERT, i.TEMP, i.TEMP_UNCERT, i.PRESS, i.PRESS_UNCERT, i.ION_STR, ION_STR_UNCERT, 
            i.STOICH_FREE_PARAM, i.STOICH_PARAM, i.FIT_SD,i.HEAT_DIL_CORR, i.HEAT_ION_CORR, i.NUM_PROTON, i.DELTA_H_OBS, i.DELTA_H_OBS_UNCERT, i.K, i.K_UNCERT, 
            i.DELTA_G0, i.DELTA_G0_UNCERT, i.DELTA_H0, i.DELTA_H0_UNCERT,i.DELTA_CP, i.DELTA_CP_UNCERT, i.DELTA_S0, i.DELTA_S0_UNCERT, i.DATA_FIT_METH_ID, 
            D.data_fit_meth_id, D.data_fit_meth_desc, i.INSTRUMENTID, Z.instrumentid, Z.name as Instrument, i.COMMENTS

            from
            itc_result_a_b_ab i

            left join
            (select A.entryid,A.itc_result_a_b_ab_id, A.cell_react,A.cell_monomerid,B.monomerid as cell_mn_id, B.mono_nm as cell_mono_nm from itc_result_a_b_ab A, dbu_monomers B where A.cell_monomerid = B.monomerid) CM
            on i.entryid = CM.entryid AND i.itc_result_a_b_ab_id = CM.itc_result_a_b_ab_id
            left join
            (select A.entryid,A.itc_result_a_b_ab_id, A.syr_react,A.syr_monomerid,B.monomerid as syr_mn_id, B.mono_nm as syr_mono_nm from itc_result_a_b_ab A, dbu_monomers B where A.syr_monomerid = B.monomerid) SM
            on i.entryid = SM.entryid AND i.itc_result_a_b_ab_id = SM.itc_result_a_b_ab_id
            left join
            (select A.entryid,A.itc_result_a_b_ab_id, A.cell_react,A.cell_polymerid,P.polymerid as cell_pl_id, P.poly_nm as cell_poly_nm from itc_result_a_b_ab A, dbu_polymers P where A.cell_polymerid = P.polymerid) CP
            on i.entryid = CP.entryid AND i.itc_result_a_b_ab_id = CP.itc_result_a_b_ab_id
            left join
            (select A.entryid,A.itc_result_a_b_ab_id, A.cell_react,A.syr_polymerid,P.polymerid as syr_pl_id, P.poly_nm as syr_poly_nm from itc_result_a_b_ab A, dbu_polymers P where A.syr_polymerid = P.polymerid) SP
            on i.entryid = SP.entryid AND i.itc_result_a_b_ab_id = SP.itc_result_a_b_ab_id
            left join
            (select A.entryid,A.itc_result_a_b_ab_id, A.cell_react,A.cell_complexid,C.complexid as cell_cm_id, C.name as cell_complex_nm from itc_result_a_b_ab A, complex_name C where A.cell_complexid = C.complexid) CC
            on i.entryid = CC.entryid AND i.itc_result_a_b_ab_id = CC.itc_result_a_b_ab_id
            left join
            (select A.entryid,A.itc_result_a_b_ab_id, A.cell_react,A.syr_complexid,C.complexid as syr_cm_id, C.name as syr_complex_nm from itc_result_a_b_ab A, complex_name C where A.syr_complexid = C.complexid) SC
            on i.entryid = SC.entryid AND i.itc_result_a_b_ab_id = SC.itc_result_a_b_ab_id

            left join (
            select s3.entryid as entryid, s3.solution_id as solution_id, s3.type solution_type, s3.ph_prep as solution_pH, s3.temp_prep as solution_temp, 
            s3.comments as solution_comments,s1.name as solute_name, s1.purpose as solute_purpose, s1.source as solute_source, s1.purity as solute_purity, 
            s1.pur_meth as solute_purity_method,s1.comments as solute_comments, s2.conc as solute_conc, s4.solventid, s4.name as solvent_name, s4.source as solvent_source, 
            s4.purity as solvent_purity, s4.pur_meth as solvent_purity_method, s4.comments as solvent_comments,s5.conc_or_fract as solvent_frac_or_conc
            from solute s1
            left join solute_conc s2
            on s2.soluteid = s1.soluteid
            left join solution_prep s3
            on s3.solution_id = s2.solution_id
            left join solvent_fract s5
            on s5.solution_id = s3.solution_id
            left join solvent s4
            on s5.solventid = s4.solventid
            where s2.entryid = s3.entryid AND s3.entryid= s5.entryid
            ) S
            on i.itc_solution_id = S.solution_id AND i.entryid = S.entryid


            left join 
            data_fit_meth D
            on i.data_fit_meth_id = D.data_fit_meth_id

            left join 
            instrument Z
            on i.instrumentid = Z.instrumentid-- 2426 rows
            
            left join itc_run_a_b_ab i2
            
            on i.entryid = i2.entryid AND i.itc_result_a_b_ab_id = i2.itc_result_a_b_ab_id;--2426 rows