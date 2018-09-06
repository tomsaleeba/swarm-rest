CREATE SCHEMA IF NOT EXISTS api;
SET search_path = "$user", public, api; -- find 'search_path' in https://www.postgresql.org/docs/10/static/ddl-schemas.html for doco
CREATE ROLE web_anon nologin;
GRANT web_anon TO postgres; -- assumes current user is 'postgres'
GRANT USAGE ON SCHEMA api TO web_anon;

CREATE OR REPLACE VIEW api.site AS
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

CREATE OR REPLACE VIEW api.structural_summary AS
SELECT
  sl.site_location_name,
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

CREATE OR REPLACE VIEW api.soil_bulk_density AS
SELECT
  sl.site_location_name,
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

CREATE OR REPLACE VIEW api.soil_characterisation AS
SELECT
  sl.site_location_name,
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

CREATE OR REPLACE VIEW api.soil_subsite AS
SELECT
  sl.site_location_name,
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

CREATE OR REPLACE VIEW api.veg_voucher AS
SELECT
  sl.site_location_name,
  vv.veg_barcode,
  hd.herbarium_determination,
  hd.is_uncertain_determination,
  slv.visit_start_date,
  vv.site_location_visit_id,
  vv.field_name,
  gv.primary_gen_barcode
FROM public.site_location AS sl
INNER JOIN public.site_location_visit AS slv
  ON slv.site_location_id = sl.site_location_id
INNER JOIN public.veg_vouchers AS vv
  ON vv.site_location_visit_id = slv.site_location_visit_id
LEFT OUTER JOIN public.herbarium_determination AS hd
  ON hd.veg_barcode = vv.veg_barcode
LEFT OUTER JOIN public.genetic_vouchers AS gv
  ON gv.veg_barcode = vv.veg_barcode;

CREATE OR REPLACE VIEW api.veg_pi AS
SELECT
  sl.site_location_name,
  pi.site_location_visit_id,
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

CREATE OR REPLACE VIEW api.veg_basal AS
SELECT
  sl.site_location_name,
  ba.site_location_visit_id,
  slv.site_location_id,
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

GRANT SELECT ON api.site TO web_anon;
GRANT SELECT ON api.structural_summary TO web_anon;
GRANT SELECT ON api.soil_bulk_density TO web_anon;
GRANT SELECT ON api.soil_characterisation TO web_anon;
GRANT SELECT ON api.soil_subsite TO web_anon;
GRANT SELECT ON api.veg_voucher TO web_anon;
GRANT SELECT ON api.veg_pi TO web_anon;
GRANT SELECT ON api.veg_basal TO web_anon;

