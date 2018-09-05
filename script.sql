CREATE SCHEMA IF NOT EXISTS api;
SET search_path = "$user", public, api; -- find 'search_path' in https://www.postgresql.org/docs/10/static/ddl-schemas.html for doco
CREATE ROLE web_anon nologin;
GRANT web_anon TO postgres; -- assumes current user is 'postgres'
GRANT USAGE ON SCHEMA api TO web_anon;

CREATE OR REPLACE VIEW api.site AS
SELECT 
  site_location.site_location_name, 
  site_location.established_date, 
  site_location.description, 
  site_location.bioregion_name, 
  site_location.landform_pattern, 
  site_location.landform_element, 
  site_location.site_slope, 
  site_location.site_aspect, 
  site_location.comments, 
  site_location.outcrop_lithology, 
  site_location.other_outcrop_lithology, 
  site_location.plot_dimensions, 
  site_location_visit.visit_start_date, 
  site_location_visit.visit_end_date, 
  site_location_visit.visit_notes, 
  site_location_visit.location_description, 
  site_location_visit.erosion_type, 
  site_location_visit.erosion_abundance, 
  site_location_visit.erosion_state, 
  site_location_visit.microrelief, 
  site_location_visit.drainage_type, 
  site_location_visit.disturbance, 
  site_location_visit.climatic_condition, 
  site_location_visit.vegetation_condition, 
  site_location_visit.observer_veg, 
  site_location_visit.observer_soil, 
  site_location_visit.described_by, 
  site_location_visit.pit_marker_easting, 
  site_location_visit.pit_marker_northing, 
  site_location_visit.pit_marker_mga_zones, 
  site_location_visit.pit_marker_datum, 
  site_location_visit.pit_marker_location_method, 
  site_location_visit.soil_observation_type, 
  site_location_visit.a_s_c, 
  site_location.plot_is_100m_by_100m, 
  site_location.plot_is_aligned_to_grid, 
  site_location.plot_is_permanently_marked,
  site_location_point.latitude, 
  site_location_point.longitude, 
  site_location_point.point 
FROM 
  public.site_location, 
  public.site_location_visit,
  public.site_location_point
WHERE 
  site_location_point.point = 'SW' AND -- FIXME is this OK that we only pick a single point
  site_location_point.site_location_id = site_location.site_location_id AND
  site_location_visit.site_location_id = site_location.site_location_id;

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
  soil_characterisation.next_size_1
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
SELECT public.site_location.site_location_name,
  public.veg_vouchers.veg_barcode,  
  public.herbarium_determination.herbarium_determination,
  public.herbarium_determination.is_uncertain_determination,
  public.site_location_visit.visit_start_date, 
  public.veg_vouchers.site_location_visit_id,
  public.veg_vouchers.field_name          
FROM public.site_location_visit
INNER JOIN public.site_location
ON public.site_location_visit.site_location_id = public.site_location.site_location_id
INNER JOIN public.veg_vouchers
ON public.veg_vouchers.site_location_visit_id = public.site_location_visit.site_location_visit_id
LEFT OUTER JOIN public.herbarium_determination
ON public.herbarium_determination.veg_barcode = public.veg_vouchers.veg_barcode;

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

