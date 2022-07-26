select distinct sp.specimenlabel
from gxd_specimen sp
inner join gxd_genotype ge on sp._genotype_key = ge._genotype_key
	inner join prb_strain st on ge._strain_key = st._strain_key
-- 		inner join mgi_user us on st._createdby_key = us._user_key
where agemin in (select min(agemin) from gxd_specimen) or agemin in (select max(agemin) from gxd_specimen) 
	and agemax in (select min(agemax) from gxd_specimen) or agemax in (select max(agemax) from gxd_specimen)														   
	and ge.isconditional = 0
	and st.standard = 1 and st.private = 0
-- 	and us.creation_date >= '2010-05-03'::date and us.creation_date <= '2020-05-03'::date
order by specimenlabel;

-- select sum(sp.sequencenum) / count(sp.sequencenum)
-- from gxd_specimen sp
-- inner join gxd_genotype ge on sp._genotype_key = ge._genotype_key
-- 	inner join prb_strain st on ge._strain_key = st._strain_key
-- 		inner join mgi_user us on st._createdby_key = us._user_key
-- where agemin in (select min(agemin) from gxd_specimen) or agemax in (select max(agemin) from gxd_specimen) 
-- 	and agemax in (select min(agemax) from gxd_specimen) or agemax in (select max(agemax) from gxd_specimen)														   
-- 	and ge.isconditional = 0
-- 	and st.standard = 1 and st.private = 0
-- 	and us.creation_date >= '2010-05-03'::date and us.creation_date <= '2020-05-03'::date
-- ;

-- select count(distinct insertsize) from prb_probe;

-- select max(insertsize) from prb_probe;

-- select sum(distinct startcoordinate) / count(distinct startcoordinate) from map_coord_feature;

-- select count(*) from map_coord_feature;