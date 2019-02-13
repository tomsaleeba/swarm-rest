DROP SCHEMA IF EXISTS api CASCADE;
DROP ROLE IF EXISTS web_anon;
DROP ROLE IF EXISTS staff;

CREATE SCHEMA api;
SET search_path = "$user", public, api; -- find 'search_path' in https://www.postgresql.org/docs/10/static/ddl-schemas.html for doco

CREATE ROLE web_anon NOLOGIN;
GRANT web_anon TO CURRENT_USER;
GRANT USAGE ON SCHEMA api TO web_anon;

CREATE ROLE staff NOLOGIN IN GROUP web_anon INHERIT;
GRANT staff TO CURRENT_USER;
GRANT USAGE ON SCHEMA api TO staff;


DROP VIEW IF EXISTS public.unpublished_site_location_visit_ids;
CREATE VIEW public.unpublished_site_location_visit_ids AS
SELECT site_location_visit_id
FROM public.site_location_visit
WHERE ok_to_publish = false;



DROP VIEW IF EXISTS api.site_inc_unpub;
CREATE VIEW api.site_inc_unpub AS
SELECT
  sl.site_location_name,
  sl.established_date,
  sl.description,
  sl.bioregion_name,
  sl.landform_pattern,
  sl.landform_element,
  sl.site_slope,
  sl.site_aspect,
  sl.comments,
  sl.outcrop_lithology,
  sl.other_outcrop_lithology,
  sl.plot_dimensions,
  slv.site_location_visit_id,
  slv.visit_start_date,
  slv.visit_end_date,
  slv.visit_notes,
  slv.location_description,
  slv.erosion_type,
  slv.erosion_abundance,
  slv.erosion_state,
  slv.microrelief,
  slv.drainage_type,
  slv.disturbance,
  slv.climatic_condition,
  slv.vegetation_condition,
  slv.observer_veg,
  slv.observer_soil,
  slv.described_by,
  slv.pit_marker_easting,
  slv.pit_marker_northing,
  slv.pit_marker_mga_zones,
  slv.pit_marker_datum,
  slv.pit_marker_location_method,
  slv.soil_observation_type,
  slv.a_s_c,
  sl.plot_is_100m_by_100m,
  sl.plot_is_aligned_to_grid,
  sl.plot_is_permanently_marked,
  slp.latitude,
  slp.longitude,
  slp.point
FROM public.site_location AS sl
INNER JOIN public.site_location_visit AS slv
  ON slv.site_location_id = sl.site_location_id
INNER JOIN public.site_location_point AS slp
  ON slp.point = 'SW' -- need to pick a single point to get coordinates
  AND slp.site_location_id = sl.site_location_id;

DROP VIEW IF EXISTS api.site;
CREATE VIEW api.site AS
SELECT *
FROM api.site_inc_unpub
WHERE site_location_visit_id NOT IN (SELECT * FROM unpublished_site_location_visit_ids);



DROP VIEW IF EXISTS api.structural_summary_inc_unpub;
CREATE VIEW api.structural_summary_inc_unpub AS
SELECT
  sl.site_location_name,
  slv.site_location_visit_id,
  ss.phenology_comment,
  ss.upper_1_dominant,
  ss.upper_2_dominant,
  ss.upper_3_dominant,
  ss.mid_1_dominant,
  ss.mid_2_dominant,
  ss.mid_3_dominant,
  ss.ground_1_dominant,
  ss.ground_2_dominant,
  ss.ground_3_dominant,
  ss.description,
  ss.mass_flowering_event
FROM public.site_location AS sl
INNER JOIN public.site_location_visit AS slv
  ON slv.site_location_id = sl.site_location_id
INNER JOIN public.structural_summary AS ss
  ON ss.site_location_visit_id = slv.site_location_visit_id;

DROP VIEW IF EXISTS api.structural_summary;
CREATE VIEW api.structural_summary AS
SELECT *
FROM api.structural_summary_inc_unpub
WHERE site_location_visit_id NOT IN (SELECT * FROM unpublished_site_location_visit_ids);



DROP VIEW IF EXISTS api.soil_bulk_density_inc_unpub;
CREATE VIEW api.soil_bulk_density_inc_unpub AS
SELECT
  sl.site_location_name,
  slv.site_location_visit_id,
  sbd.sample_id,
  sbd.paper_bag_weight,
  sbd.oven_dried_weight_in_bag,
  sbd.ring_weight,
  sbd.gravel_weight,
  sbd.ring_volume,
  sbd.gravel_volume,
  sbd.fine_earth_weight_in_bag,
  sbd.fine_earth_weight,
  sbd.fine_earth_volume,
  sbd.fine_earth_bulk_density,
  sbd.gravel_bulk_density
FROM public.site_location AS sl
INNER JOIN public.site_location_visit AS slv
  ON slv.site_location_id = sl.site_location_id
INNER JOIN public.soil_bulk_density as sbd
  ON sbd.site_location_visit_id = slv.site_location_visit_id;

DROP VIEW IF EXISTS api.soil_bulk_density;
CREATE VIEW api.soil_bulk_density AS
SELECT *
FROM api.soil_bulk_density_inc_unpub
WHERE site_location_visit_id NOT IN (SELECT * FROM unpublished_site_location_visit_ids);



DROP VIEW IF EXISTS api.soil_characterisation_inc_unpub;
CREATE VIEW api.soil_characterisation_inc_unpub AS
SELECT
  sl.site_location_name,
  slv.site_location_visit_id,
  sc.upper_depth,
  sc.lower_depth,
  sc.horizon,
  sc.texture_grade,
  sc.texture_qualifier,
  sc.texture_modifier,
  sc.colour_when_moist,
  sc.colour_when_dry,
  sc.mottles_colour,
  sc.mottles_abundance,
  sc.mottles_size,
  sc.segregations_abundance,
  sc.segregations_size,
  sc.segregations_nature,
  sc.segregations_form,
  sc.comments,
  sc.collected_by,
  sc.smallest_size_1,
  sc.smallest_size_2,
  sc.effervescence,
  sc.ec,
  sc.ph,
  sc.pedality_grade,
  sc.pedality_fabric,
  sc.next_size_type_2,
  sc.next_size_type_1,
  sc.smallest_size_type_2,
  sc.smallest_size_type_1,
  sc.next_size_2,
  sc.next_size_1,
  sc.layer_barcode
FROM public.site_location AS sl
INNER JOIN public.site_location_visit AS slv
  ON slv.site_location_id = sl.site_location_id
INNER JOIN public.soil_characterisation AS sc
  ON sc.site_location_visit_id = slv.site_location_visit_id;

DROP VIEW IF EXISTS api.soil_characterisation;
CREATE VIEW api.soil_characterisation AS
SELECT *
FROM api.soil_characterisation_inc_unpub
WHERE site_location_visit_id NOT IN (SELECT * FROM unpublished_site_location_visit_ids);



DROP VIEW IF EXISTS api.soil_subsite_inc_unpub;
CREATE VIEW api.soil_subsite_inc_unpub AS
SELECT
  sl.site_location_name,
  slv.site_location_visit_id,
  sso.subsite_id,
  sso.zone,
  sso.easting,
  sso.northing,
  sso.ten_to_twenty_barcode,
  sso.zero_to_ten_barcode,
  sso.twenty_to_thirty_barcode,
  sso.comments,
  sso.metagenomic_barcode
FROM public.site_location AS sl
INNER JOIN public.site_location_visit AS slv
  ON slv.site_location_id = sl.site_location_id
INNER JOIN public.soil_subsite_observations AS sso
  ON sso.site_location_visit_id = slv.site_location_visit_id;

DROP VIEW IF EXISTS api.soil_subsite;
CREATE VIEW api.soil_subsite AS
SELECT *
FROM api.soil_subsite_inc_unpub
WHERE site_location_visit_id NOT IN (SELECT * FROM unpublished_site_location_visit_ids);



DROP VIEW IF EXISTS api.veg_voucher_inc_unpub;
CREATE VIEW api.veg_voucher_inc_unpub AS
SELECT
  sl.site_location_name,
  vv.veg_barcode,
  hd.herbarium_determination,
  hd.is_uncertain_determination,
  slv.visit_start_date,
  slv.site_location_visit_id,
  gv.primary_gen_barcode,
  gv.secondary_gen_barcode_1,
  gv.secondary_gen_barcode_2,
  gv.secondary_gen_barcode_3,
  gv.secondary_gen_barcode_4
FROM public.site_location AS sl
INNER JOIN public.site_location_visit AS slv
  ON slv.site_location_id = sl.site_location_id
INNER JOIN public.veg_vouchers AS vv
  ON vv.site_location_visit_id = slv.site_location_visit_id
LEFT OUTER JOIN public.herbarium_determination AS hd
  ON hd.veg_barcode = vv.veg_barcode
LEFT OUTER JOIN public.genetic_vouchers AS gv
  ON gv.veg_barcode = vv.veg_barcode;

DROP VIEW IF EXISTS api.veg_voucher;
CREATE VIEW api.veg_voucher AS
SELECT *
FROM api.veg_voucher_inc_unpub
WHERE site_location_visit_id NOT IN (SELECT * FROM unpublished_site_location_visit_ids);



DROP VIEW IF EXISTS api.veg_pi_inc_unpub;
CREATE VIEW api.veg_pi_inc_unpub AS
SELECT
  sl.site_location_name,
  slv.site_location_visit_id,
  pi.transect,
  pi.point_number,
  hd.veg_barcode,
  hd.herbarium_determination,
  pi.substrate,
  pi.in_canopy_sky,
  pi.dead,
  pi.growth_form,
  pi.height
FROM public.site_location AS sl
INNER JOIN public.site_location_visit AS slv
  ON slv.site_location_id = sl.site_location_id
INNER JOIN public.point_intercept AS pi
  ON pi.site_location_visit_id = slv.site_location_visit_id
LEFT OUTER JOIN public.herbarium_determination AS hd
  ON hd.veg_barcode = pi.veg_barcode;

DROP VIEW IF EXISTS api.veg_pi;
CREATE VIEW api.veg_pi AS
SELECT *
FROM api.veg_pi_inc_unpub
WHERE site_location_visit_id NOT IN (SELECT * FROM unpublished_site_location_visit_ids);



DROP VIEW IF EXISTS api.veg_basal_inc_unpub;
CREATE VIEW api.veg_basal_inc_unpub AS
SELECT
  sl.site_location_name,
  slv.site_location_visit_id,
  sl.site_location_id,
  ba.point_id,
  hd.herbarium_determination,
  hd.veg_barcode,
  ba.hits,
  ba.basal_area_factor,
  ba.basal_area
FROM public.site_location AS sl
INNER JOIN public.site_location_visit AS slv
  ON slv.site_location_id = sl.site_location_id
INNER JOIN public.basal_area AS ba
  ON ba.site_location_visit_id = slv.site_location_visit_id
INNER JOIN public.herbarium_determination AS hd
  ON hd.veg_barcode = ba.veg_barcode;

DROP VIEW IF EXISTS api.veg_basal;
CREATE VIEW api.veg_basal AS
SELECT *
FROM api.veg_basal_inc_unpub
WHERE site_location_visit_id NOT IN (SELECT * FROM unpublished_site_location_visit_ids);



DROP VIEW IF EXISTS api.search_inc_unpub;
CREATE VIEW api.search_inc_unpub AS
SELECT
  sl.site_location_name,
  slv.site_location_visit_id,
  slp.latitude,
  slp.longitude,
  hd.herbarium_determination
FROM public.site_location AS sl
INNER JOIN public.site_location_visit AS slv
  ON slv.site_location_id = sl.site_location_id
INNER JOIN public.site_location_point AS slp
  ON slp.point = 'SW' -- need to pick a single point to get coordinates
  AND slp.site_location_id = sl.site_location_id
LEFT OUTER JOIN public.veg_vouchers AS vv
  ON vv.site_location_visit_id = slv.site_location_visit_id
LEFT OUTER JOIN public.herbarium_determination AS hd
  ON hd.veg_barcode = vv.veg_barcode;

DROP VIEW IF EXISTS api.search;
CREATE VIEW api.search AS
SELECT *
FROM api.search_inc_unpub
WHERE site_location_visit_id NOT IN (SELECT * FROM unpublished_site_location_visit_ids);


GRANT SELECT ON api.site_inc_unpub TO staff;
GRANT SELECT ON api.structural_summary_inc_unpub TO staff;
GRANT SELECT ON api.soil_bulk_density_inc_unpub TO staff;
GRANT SELECT ON api.soil_characterisation_inc_unpub TO staff;
GRANT SELECT ON api.soil_subsite_inc_unpub TO staff;
GRANT SELECT ON api.veg_voucher_inc_unpub TO staff;
GRANT SELECT ON api.veg_pi_inc_unpub TO staff;
GRANT SELECT ON api.veg_basal_inc_unpub TO staff;
GRANT SELECT ON api.search_inc_unpub TO staff;

GRANT SELECT ON api.site TO web_anon;
GRANT SELECT ON api.structural_summary TO web_anon;
GRANT SELECT ON api.soil_bulk_density TO web_anon;
GRANT SELECT ON api.soil_characterisation TO web_anon;
GRANT SELECT ON api.soil_subsite TO web_anon;
GRANT SELECT ON api.veg_voucher TO web_anon;
GRANT SELECT ON api.veg_pi TO web_anon;
GRANT SELECT ON api.veg_basal TO web_anon;
GRANT SELECT ON api.search TO web_anon;

SELECT 'success' AS outcome;
