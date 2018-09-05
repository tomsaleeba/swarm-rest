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
  site_location.site_location_name,
  structural_summary.phenology_comment,
  structural_summary.upper_1_dominant,
  structural_summary.upper_2_dominant,
  structural_summary.upper_3_dominant,
  structural_summary.mid_1_dominant,
  structural_summary.mid_2_dominant,
  structural_summary.mid_3_dominant,
  structural_summary.ground_1_dominant,
  structural_summary.ground_2_dominant,
  structural_summary.ground_3_dominant,
  structural_summary.description,
  structural_summary.mass_flowering_event
FROM
  public.site_location,
  public.site_location_visit,
  public.structural_summary
WHERE
  site_location_visit.site_location_id = site_location.site_location_id AND
  structural_summary.site_location_visit_id = site_location_visit.site_location_visit_id;

CREATE OR REPLACE VIEW api.soil_bulk_density AS
SELECT
  site_location.site_location_name,
  soil_bulk_density.sample_id,
  soil_bulk_density.paper_bag_weight,
  soil_bulk_density.oven_dried_weight_in_bag,
  soil_bulk_density.ring_weight,
  soil_bulk_density.gravel_weight,
  soil_bulk_density.ring_volume,
  soil_bulk_density.gravel_volume,
  soil_bulk_density.fine_earth_weight_in_bag,
  soil_bulk_density.fine_earth_weight,
  soil_bulk_density.fine_earth_volume,
  soil_bulk_density.fine_earth_bulk_density,
  soil_bulk_density.gravel_bulk_density
FROM
  public.site_location,
  public.site_location_visit,
  public.soil_bulk_density
WHERE
  site_location_visit.site_location_id = site_location.site_location_id AND
  soil_bulk_density.site_location_visit_id = site_location_visit.site_location_visit_id;

CREATE OR REPLACE VIEW api.soil_characterisation AS
SELECT
  site_location.site_location_name,
  soil_characterisation.upper_depth,
  soil_characterisation.lower_depth,
  soil_characterisation.horizon,
  soil_characterisation.texture_grade,
  soil_characterisation.texture_qualifier,
  soil_characterisation.texture_modifier,
  soil_characterisation.colour_when_moist,
  soil_characterisation.colour_when_dry,
  soil_characterisation.mottles_colour,
  soil_characterisation.mottles_abundance,
  soil_characterisation.mottles_size,
  soil_characterisation.segregations_abundance,
  soil_characterisation.segregations_size,
  soil_characterisation.segregations_nature,
  soil_characterisation.segregations_form,
  soil_characterisation.comments,
  soil_characterisation.collected_by,
  soil_characterisation.smallest_size_1,
  soil_characterisation.smallest_size_2,
  soil_characterisation.effervescence,
  soil_characterisation.ec,
  soil_characterisation.ph,
  soil_characterisation.pedality_grade,
  soil_characterisation.pedality_fabric,
  soil_characterisation.next_size_type_2,
  soil_characterisation.next_size_type_1,
  soil_characterisation.smallest_size_type_2,
  soil_characterisation.smallest_size_type_1,
  soil_characterisation.next_size_2,
  soil_characterisation.next_size_1,
  soil_characterisation.layer_barcode
FROM
  public.site_location,
  public.site_location_visit,
  public.soil_characterisation
WHERE
  site_location_visit.site_location_id = site_location.site_location_id AND
  soil_characterisation.site_location_visit_id = site_location_visit.site_location_visit_id;

CREATE OR REPLACE VIEW api.soil_subsite AS
SELECT
  site_location.site_location_name,
  soil_subsite_observations.subsite_id,
  soil_subsite_observations.zone,
  soil_subsite_observations.easting,
  soil_subsite_observations.northing,
  soil_subsite_observations.ten_to_twenty_barcode,
  soil_subsite_observations.zero_to_ten_barcode,
  soil_subsite_observations.twenty_to_thirty_barcode,
  soil_subsite_observations.comments,
  soil_subsite_observations.metagenomic_barcode
FROM
  public.site_location,
  public.site_location_visit,
  public.soil_subsite_observations
WHERE
  site_location_visit.site_location_id = site_location.site_location_id AND
  soil_subsite_observations.site_location_visit_id = site_location_visit.site_location_visit_id;

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
FROM public.site_location_visit AS slv
INNER JOIN public.site_location AS sl
ON slv.site_location_id = sl.site_location_id
INNER JOIN public.veg_vouchers AS vv
ON vv.site_location_visit_id = slv.site_location_visit_id
LEFT OUTER JOIN public.herbarium_determination AS hd
ON hd.veg_barcode = vv.veg_barcode
LEFT OUTER JOIN public.genetic_vouchers AS gv
ON gv.veg_barcode = vv.veg_barcode;

CREATE OR REPLACE VIEW api.veg_pi AS
SELECT
  site_location.site_location_name,
  point_intercept.site_location_visit_id,
  point_intercept.transect,
  point_intercept.point_number,
  herbarium_determination.veg_barcode,
  herbarium_determination.herbarium_determination,
  point_intercept.substrate,
  point_intercept.in_canopy_sky,
  point_intercept.dead,
  point_intercept.growth_form,
  point_intercept.height
FROM
  public.site_location,
  public.site_location_visit,
  public.point_intercept LEFT OUTER JOIN public.herbarium_determination
  ON public.herbarium_determination.veg_barcode = public.point_intercept.veg_barcode
WHERE
  site_location_visit.site_location_id = site_location.site_location_id AND
  point_intercept.site_location_visit_id = site_location_visit.site_location_visit_id;

CREATE OR REPLACE VIEW api.veg_basal AS
SELECT
  site_location.site_location_name,
  basal_area.site_location_visit_id,
  site_location_visit.site_location_id,
  basal_area.point_id,
  herbarium_determination.herbarium_determination,
  herbarium_determination.veg_barcode,
  basal_area.hits,
  basal_area.basal_area_factor,
  basal_area.basal_area
FROM
  public.site_location,
  public.site_location_visit,
  public.herbarium_determination,
  public.basal_area
WHERE
  site_location_visit.site_location_id = site_location.site_location_id AND
  herbarium_determination.veg_barcode = basal_area.veg_barcode AND
  basal_area.site_location_visit_id = site_location_visit.site_location_visit_id;

GRANT SELECT ON api.site TO web_anon;
GRANT SELECT ON api.structural_summary TO web_anon;
GRANT SELECT ON api.soil_bulk_density TO web_anon;
GRANT SELECT ON api.soil_characterisation TO web_anon;
GRANT SELECT ON api.soil_subsite TO web_anon;
GRANT SELECT ON api.veg_voucher TO web_anon;
GRANT SELECT ON api.veg_pi TO web_anon;
GRANT SELECT ON api.veg_basal TO web_anon;

