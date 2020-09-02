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


-- public_hostname() function is created by set-hostname-for-jsonld.sh


DROP FUNCTION IF EXISTS escape_spaces;
CREATE FUNCTION escape_spaces(val text) RETURNS text AS $$ BEGIN
  RETURN replace(val, ' ', '%20');
END $$ LANGUAGE PLPGSQL IMMUTABLE;


DROP FUNCTION IF EXISTS build_url;
CREATE FUNCTION build_url(val text) RETURNS text AS $$ BEGIN
  RETURN public_url_prefix() || escape_spaces(val);
END $$ LANGUAGE PLPGSQL IMMUTABLE;


DROP FUNCTION IF EXISTS context_url;
CREATE FUNCTION context_url() RETURNS text AS $$ BEGIN
  RETURN build_url('/om_context');
END $$ LANGUAGE PLPGSQL IMMUTABLE;


DROP FUNCTION IF EXISTS site_id;
CREATE FUNCTION site_id(id_fragment integer) RETURNS text AS $$ BEGIN
  RETURN build_url('/om_site?_id=eq.' || id_fragment);
END $$ LANGUAGE PLPGSQL IMMUTABLE;


DROP FUNCTION IF EXISTS site_visit_id;
CREATE FUNCTION site_visit_id(id_fragment integer) RETURNS text AS $$ BEGIN
  RETURN build_url('/om_site_visit?_id=eq.' || id_fragment);
END $$ LANGUAGE PLPGSQL IMMUTABLE;


DROP FUNCTION IF EXISTS site_point_id;
CREATE FUNCTION site_point_id(id_fragment integer) RETURNS text AS $$ BEGIN
  RETURN build_url('/om_site_point?_id=eq.' || id_fragment);
END $$ LANGUAGE PLPGSQL IMMUTABLE;


DROP FUNCTION IF EXISTS procedure_id;
CREATE FUNCTION procedure_id(id_fragment text) RETURNS text AS $$ BEGIN
  RETURN build_url('/om_procedure?%22rdfs:label%22=eq.' || id_fragment);
END $$ LANGUAGE PLPGSQL IMMUTABLE;


DROP FUNCTION IF EXISTS create_local_id;
CREATE FUNCTION create_local_id(VARIADIC id_fragment text[]) RETURNS text AS $$ BEGIN
  RETURN array_to_string(id_fragment, '/', '');
END $$ LANGUAGE PLPGSQL IMMUTABLE;


DROP FUNCTION IF EXISTS observation_id;
CREATE FUNCTION observation_id(VARIADIC id_fragment text[]) RETURNS text AS $$ BEGIN
  RETURN build_url('/om_observation?_id=eq.' || create_local_id(VARIADIC id_fragment));
END $$ LANGUAGE PLPGSQL IMMUTABLE;


DROP FUNCTION IF EXISTS observation_collection_id;
CREATE FUNCTION observation_collection_id(VARIADIC id_fragment text[]) RETURNS text AS $$ BEGIN
  RETURN build_url('/om_observation_collection?_id=eq.' || create_local_id(VARIADIC id_fragment));
END $$ LANGUAGE PLPGSQL IMMUTABLE;


-- sites have lots of points and we need to choose just one. Let's make sure we
-- always choose the same one.
DROP VIEW IF EXISTS api.singular_site_location_point;
CREATE VIEW api.singular_site_location_point AS
SELECT *
FROM public.site_location_point
WHERE point = 'SW'; -- need to pick a single point to get coordinates


-- WFO = http://www.worldfloraonline.org/
DROP VIEW IF EXISTS api.wfo_determination_pretty;
CREATE VIEW api.wfo_determination_pretty AS
SELECT
  wfod.veg_barcode,
  NULLIF(
    trim(
      regexp_replace(
          coalesce(wfod.tax_genus, '') || ' ' ||
          coalesce(wfod.tax_specific_epithet, '') || ' ' ||
          coalesce(wfod.tax_infraspecific_rank, '') || ' ' ||
          coalesce(wfod.tax_infraspecific_epithet, ''),
        E'\\s+',
        ' ',
        'g'
      )
    ), ''
  ) AS standardised_name,
  NULLIF(wfod.tax_family, '') AS family,
  NULLIF(wfod.tax_genus, '') AS genus,
  NULLIF(wfod.tax_specific_epithet, '') AS specific_epithet,
  NULLIF(wfod.tax_infraspecific_rank, '') AS infraspecific_rank,
  NULLIF(wfod.tax_infraspecific_epithet, '') AS infraspecific_epithet,
  NULLIF(wfod.tax_status, '') AS taxa_status,
  NULLIF(trim(wfod.tax_genus || ' '
      || wfod.tax_specific_epithet), '') AS genus_species
FROM public.wfo_determination AS wfod;


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
INNER JOIN api.singular_site_location_point AS slp
  ON slp.site_location_id = sl.site_location_id;

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
  hd.herbarium_determination,
  hd.is_uncertain_determination,
  wfod_pretty.*,
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
  ON gv.veg_barcode = vv.veg_barcode
LEFT OUTER JOIN wfo_determination_pretty AS wfod_pretty
  ON wfod_pretty.veg_barcode = vv.veg_barcode;

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
  hd.herbarium_determination,
  pi.substrate,
  pi.in_canopy_sky,
  pi.dead,
  pi.growth_form,
  pi.height,
  wfod_pretty.*
FROM public.site_location AS sl
INNER JOIN public.site_location_visit AS slv
  ON slv.site_location_id = sl.site_location_id
INNER JOIN public.point_intercept AS pi
  ON pi.site_location_visit_id = slv.site_location_visit_id
LEFT OUTER JOIN public.herbarium_determination AS hd
  ON hd.veg_barcode = pi.veg_barcode
LEFT OUTER JOIN wfo_determination_pretty AS wfod_pretty
  ON wfod_pretty.veg_barcode = hd.veg_barcode;

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
  wfod_pretty.*,
  ba.hits,
  ba.basal_area_factor,
  ba.basal_area
FROM public.site_location AS sl
INNER JOIN public.site_location_visit AS slv
  ON slv.site_location_id = sl.site_location_id
INNER JOIN public.basal_area AS ba
  ON ba.site_location_visit_id = slv.site_location_visit_id
INNER JOIN public.herbarium_determination AS hd
  ON hd.veg_barcode = ba.veg_barcode
LEFT OUTER JOIN wfo_determination_pretty AS wfod_pretty
  ON wfod_pretty.veg_barcode = hd.veg_barcode;

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
  hd.herbarium_determination,
  wfod_pretty.*
FROM public.site_location AS sl
INNER JOIN public.site_location_visit AS slv
  ON slv.site_location_id = sl.site_location_id
INNER JOIN api.singular_site_location_point AS slp
  ON slp.site_location_id = sl.site_location_id
LEFT OUTER JOIN public.veg_vouchers AS vv
  ON vv.site_location_visit_id = slv.site_location_visit_id
LEFT OUTER JOIN public.herbarium_determination AS hd
  ON hd.veg_barcode = vv.veg_barcode
LEFT OUTER JOIN wfo_determination_pretty AS wfod_pretty
  ON wfod_pretty.veg_barcode = hd.veg_barcode;

DROP VIEW IF EXISTS api.search;
CREATE VIEW api.search AS
SELECT *
FROM api.search_inc_unpub
WHERE site_location_visit_id NOT IN (SELECT * FROM unpublished_site_location_visit_ids);



DROP VIEW IF EXISTS api.metadata_dictionary;
CREATE VIEW api.metadata_dictionary AS
SELECT
  'basal_point' AS variable, -- FIXME is this really "basal", and do we need it?
  point_id AS code,
  point_name AS label,
  'Distance from SW corner: ' || distance_from_sw_corner AS description
FROM public.lut_basal_point
UNION ALL
SELECT
  'bioregion_name' AS variable,
  abbreviation AS code,
  name AS label,
  NULL AS description
FROM public.lut_bioregions
UNION ALL
SELECT -- FIXME do we need this?
  'coarse_frag_abund' AS variable,
  id AS code,
  "type" AS label,
  NULL AS description
FROM public.lut_coarse_frag_abund
UNION ALL
SELECT -- FIXME do we need this?
  'coarse_frag_shape' AS variable,
  id AS code,
  "type" AS label,
  NULL AS description
FROM public.lut_coarse_frag_shape
UNION ALL
SELECT -- FIXME do we need this?
  'coarse_frag_size' AS variable,
  id AS code,
  "size" AS label,
  NULL AS description
FROM public.lut_coarse_frag_size
UNION ALL
SELECT
  'pit_marker_datum' AS variable,
  datum AS code,
  description AS label,
  description_geoscience_australia AS description
FROM public.lut_datum
UNION ALL
SELECT
  'disturbance' AS variable,
  id AS code,
  disturbance AS label,
  NULL AS description
FROM public.lut_disturbance
UNION ALL
SELECT
  'drainage_type' AS variable,
  id::VARCHAR AS code,
  drainage AS label,
  description
FROM public.lut_drainage
UNION ALL
SELECT
  'effervescence' AS variable,
  id AS code,
  effervescence AS label,
  NULL AS description
FROM public.lut_effervescence
UNION ALL
SELECT
  'erosion_abundance' AS variable,
  id AS code,
  abundance AS label,
  NULL AS description
FROM public.lut_erosion_abund
UNION ALL
SELECT
  'erosion_state' AS variable,
  id AS code,
  state AS label,
  NULL AS description
FROM public.lut_erosion_state
UNION ALL
SELECT
  'erosion_type' AS variable,
  id AS code,
  erosion_type AS label,
  NULL AS description
FROM public.lut_erosion_type
UNION ALL
SELECT
  'growth_form' AS variable,
  id AS code,
  growth_form AS label,
  definition AS description
FROM public.lut_growth_form
UNION ALL
SELECT -- FIXME do we need this?
  'ibra' AS variable,
  bioregion_name AS code,
  bioregion_description AS label,
  NULL AS description
FROM public.lut_ibra
UNION ALL
SELECT
  'landform_element' AS variable,
  code,
  landform_element AS label,
  description
FROM public.lut_landform_element
UNION ALL
SELECT
  'landform_pattern' AS variable,
  id AS code,
  landform_pattern AS label,
  description
FROM public.lut_landform_pattern
UNION ALL
SELECT
  'outcrop_lithology' AS variable,
  code,
  outcrop_lithology AS label,
  'Rock type: ' || rock_type AS description
FROM public.lut_lithology
-- FIXME also add other_outcrop_lithology?
UNION ALL
SELECT
  'pit_marker_location_method' AS variable,
  location_tech_type AS code,
  description AS label,
  NULL AS description
FROM public.lut_location_method
UNION ALL
SELECT
  'pit_marker_mga_zones' AS variable,
  mga_zone::VARCHAR AS code,
  'Zone ' || mga_zone AS label,
  'Datum: ' || datum
    || ', Projection: ' || projection
    || ', Boundary: ' || eastern_boundary || ' to ' || western_boundary
    AS description
FROM public.lut_mga_zone
UNION ALL
SELECT
  'microrelief' AS variable,
  id AS code,
  "type" AS label,
  description
FROM public.lut_microrelief
UNION ALL
SELECT
  'mottles_abundance' AS variable,
  id AS code,
  abundance AS label,
  NULL AS description
FROM public.lut_mottle_abund
UNION ALL
SELECT
  'mottles_colour' AS variable,
  id AS code,
  colour AS label,
  NULL AS description
FROM public.lut_mottle_colour
UNION ALL
SELECT
  'mottles_size' AS variable,
  id AS code,
  size AS label,
  NULL AS description
FROM public.lut_mottle_size
UNION ALL
SELECT
  'observer_veg' AS variable,
  id::VARCHAR AS code,
  full_name AS label,
  'Affiliation: ' || affiliation AS description
FROM public.lut_observer
-- FIXME also need observer_soil?
-- FIXME also need described_by?
UNION ALL
SELECT
  'pedality_fabric' AS variable,
  id::VARCHAR AS code,
  pedality_fabric AS label,
  description
FROM public.lut_pedality_fabric
UNION ALL
SELECT
  'pedality_grade' AS variable,
  id::VARCHAR AS code,
  grade AS label,
  'Pedality: ' || pedality || '. ' || description AS description
FROM public.lut_pedality_grade
UNION ALL
SELECT
  'pedality_type' AS variable,
  id::VARCHAR AS code,
  pedality_type AS label,
  description
FROM public.lut_pedality_type
UNION ALL
SELECT
  'segregations_abundance' AS variable,
  id AS code,
  abundance AS label,
  NULL AS description
FROM public.lut_seg_abundance
UNION ALL
SELECT
  'segregations_form' AS variable,
  id AS code,
  form AS label,
  NULL AS description
FROM public.lut_seg_form
UNION ALL
SELECT
  'segregations_nature' AS variable,
  id AS code,
  nature AS label,
  NULL AS description
FROM public.lut_seg_nature
UNION ALL
SELECT
  'segregations_size' AS variable,
  id AS code,
  "size" AS label,
  NULL AS description
FROM public.lut_seg_size
UNION ALL
SELECT
  'soil_observation_type' AS variable,
  id AS code,
  "type" AS label,
  description
FROM public.lut_soil_obs_type
UNION ALL
SELECT
  'texture_grade' AS variable,
  code,
  name AS label,
  bolus_description || '. Clay content: ' || clay_content AS description
FROM public.lut_soil_tex_grade
UNION ALL
SELECT
  'texture_modifier' AS variable,
  id AS code,
  modifier AS label,
  NULL AS description
FROM public.lut_soil_tex_mod
UNION ALL
SELECT
  'texture_qualifier' AS variable,
  id AS code,
  qualification AS label,
  NULL AS description
FROM public.lut_soil_tex_qual
UNION ALL
SELECT
  'state' AS variable,
  state AS code,
  description AS label,
  NULL AS description
FROM public.lut_state
UNION ALL
SELECT
  'smallest_size_1' AS variable,
  id AS code,
  "size" AS label,
  NULL AS description
FROM public.lut_structure_size
-- FIXME do we need smallest_size_2 too?
UNION ALL
SELECT
  'substrate' AS variable,
  substrate AS code,
  substrate AS label,
  description
FROM public.lut_substrate
UNION ALL
SELECT -- FIXME do we need this?
  'surface_soil_condition' AS variable,
  id AS code,
  condition AS label,
  NULL AS description
FROM public.lut_surface_soil_cond
UNION ALL
SELECT -- FIXME do we need this?
  'surface_strew_size' AS variable,
  id::VARCHAR AS code,
  "size" AS label,
  NULL AS description
FROM public.lut_surface_strew_size
;


-- O&M (observations and measurements) views

DROP VIEW IF EXISTS api.om_site;
CREATE VIEW api.om_site AS -- TODO make inc_unpub version
SELECT
  context_url() AS "@context",
  sl.site_location_id AS "_id",
  site_id(sl.site_location_id) AS "@id",
  'plot:Site' AS "rdf:type",
  sl.site_location_name AS "rdfs:label",
  sl.established_date AS "prov:generatedAtTime",
  json_agg(site_point_id(slp.id)) AS "locn:location" -- TODO could nest full objects
  -- TODO should we create a link to members, ssn-ext:hasMember?
FROM site_location AS sl
INNER JOIN site_location_point AS slp
  ON sl.site_location_id = slp.site_location_id
GROUP BY 1,2,3,4,5,6;


DROP VIEW IF EXISTS api.om_site_visit;
CREATE VIEW api.om_site_visit AS -- TODO make inc_unpub version
SELECT
  context_url() AS "@context",
  slv.site_location_visit_id AS "_id",
  site_visit_id(slv.site_location_visit_id) AS "@id",
  'plot:SiteVisit' AS "rdf:type",
  site_id(slv.site_location_id) AS "sosa:hasFeatureOfInterest",
  slv.visit_start_date AS "prov:startedAtTime", -- is it undecided between this and sosa:phenomenonTime, or do we need both?
  slv.visit_end_date AS "prov:endedAtTime",
  slv.visit_notes AS "rdfs:comment"
  -- TODO should we create a link to members, ssn-ext:hasMember?
FROM site_location_visit AS slv;


DROP VIEW IF EXISTS api.om_site_point;
CREATE VIEW api.om_site_point AS -- TODO make inc_unpub version
SELECT
  context_url() AS "@context",
  slp.id AS "_id",
  site_point_id(slp.id) AS "@id",
  'plot:Location' AS "rdf:type",
  site_id(slp.site_location_id) AS "plot:isLocationOf",
  slp.point AS "dct:description",
  slp.latitude AS "geo:lat", -- or locn:geometry?
  slp.longitude AS "geo:long", -- or locn:geometry?
  slp.threedcq AS "geo:alt" -- or locn:geometry?
FROM site_location_point AS slp;


DROP VIEW IF EXISTS api.om_procedure;
CREATE VIEW api.om_procedure AS
SELECT
  context_url() AS "@context",
  'sosa:Procedure' AS "rdf:type",
  procedure_id(code) AS "@id",
  code AS "rdfs:label",
  comm AS "rdfs:comment"
FROM (
  SELECT
    'APSOIL01' AS code,
    'TODO add text about procedure' AS comm -- TODO
  UNION ALL
  SELECT
    'APSOIL02',
    'TODO add text about procedure' -- TODO
) AS s;


DROP VIEW IF EXISTS api._soil_characterisation_obs;
CREATE VIEW api._soil_characterisation_obs AS
SELECT
  create_local_id('soil_characterisation'::text, sc.site_location_visit_id::text, sc.layer_barcode, the_obs.op) AS "_id",
  slv.visit_start_date AS "sosa:resultTime",
  observation_collection_id('soil_characterisation'::text, sc.site_location_visit_id::text, sc.layer_barcode) as "sosa:hasFeatureOfInterest",
  the_obs.op AS "sosa:observedProperty",
  the_obs.r AS "sosa:hasResult"
FROM soil_characterisation AS sc
INNER JOIN site_location_visit AS slv
  ON sc.site_location_visit_id = slv.site_location_visit_id
INNER JOIN (
  -- first one sets up the column names
  SELECT id, 'collected_by' AS op, collected_by::text AS r FROM soil_characterisation
  UNION ALL
  SELECT id, 'colour_when_dry', colour_when_dry::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'colour_when_moist', colour_when_moist::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'ec', ec::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'effervescence', effervescence::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'horizon', horizon::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'layer_barcode', layer_barcode::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'lower_depth', lower_depth::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'mottles_abundance', mottles_abundance::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'mottles_colour', mottles_colour::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'mottles_size', mottles_size::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'next_size_1', next_size_1::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'next_size_2', next_size_2::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'next_size_type_1', next_size_type_1::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'next_size_type_2', next_size_type_2::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'pedality_fabric', pedality_fabric::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'pedality_grade', pedality_grade::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'ph', ph::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'segregations_abundance', segregations_abundance::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'segregations_form', segregations_form::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'segregations_nature', segregations_nature::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'segregations_size', segregations_size::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'smallest_size_1', smallest_size_1::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'smallest_size_2', smallest_size_2::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'smallest_size_type_1', smallest_size_type_1::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'smallest_size_type_2', smallest_size_type_2::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'texture_grade', texture_grade::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'texture_modifier', texture_modifier::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'texture_qualifier', texture_qualifier::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'upper_depth', upper_depth::text FROM soil_characterisation
) AS the_obs
ON sc.id = the_obs.id;


DROP VIEW IF EXISTS api._soil_bulk_density_obs;
CREATE VIEW api._soil_bulk_density_obs AS
SELECT
  create_local_id('soil_bulk_density'::text, sbd.site_location_visit_id::text, sbd.sample_id, the_obs.op) AS "_id",
  slv.visit_start_date AS "sosa:resultTime",
  observation_collection_id('soil_bulk_density'::text, sbd.site_location_visit_id::text, sbd.sample_id) as "sosa:hasFeatureOfInterest",
  the_obs.op AS "sosa:observedProperty",
  the_obs.r AS "sosa:hasResult"
FROM soil_bulk_density AS sbd
INNER JOIN site_location_visit AS slv
  ON sbd.site_location_visit_id = slv.site_location_visit_id
INNER JOIN (
  -- first one sets up the column names
  SELECT id, 'fine_earth_bulk_density' AS op, fine_earth_bulk_density::text AS r FROM soil_bulk_density
  UNION ALL
  SELECT id, 'fine_earth_volume', fine_earth_volume::text FROM soil_bulk_density
  UNION ALL
  SELECT id, 'fine_earth_weight', fine_earth_weight::text FROM soil_bulk_density
  UNION ALL
  SELECT id, 'fine_earth_weight_in_bag', fine_earth_weight_in_bag::text FROM soil_bulk_density
  UNION ALL
  SELECT id, 'gravel_bulk_density', gravel_bulk_density::text FROM soil_bulk_density
  UNION ALL
  SELECT id, 'gravel_volume', gravel_volume::text FROM soil_bulk_density
  UNION ALL
  SELECT id, 'gravel_weight', gravel_weight::text FROM soil_bulk_density
  UNION ALL
  SELECT id, 'oven_dried_weight_in_bag', oven_dried_weight_in_bag::text FROM soil_bulk_density
  UNION ALL
  SELECT id, 'paper_bag_weight', paper_bag_weight::text FROM soil_bulk_density
  UNION ALL
  SELECT id, 'ring_volume', ring_volume::text FROM soil_bulk_density
  UNION ALL
  SELECT id, 'ring_weight', ring_weight::text FROM soil_bulk_density
  UNION ALL
  SELECT id, 'sample_id', sample_id::text FROM soil_bulk_density
  UNION ALL
  SELECT id, 'wet_weight_in_bag', wet_weight_in_bag::text FROM soil_bulk_density
) AS the_obs
ON sbd.id = the_obs.id;


DROP VIEW IF EXISTS api.om_observation;
CREATE VIEW api.om_observation AS
SELECT
  context_url() AS "@context",
  observation_id(partial."_id") AS "@id",
  'sosa:Observation' AS "rdf:type",
  'unknown' AS "sosa:phenomenonTime",
  partial.*
FROM (
  SELECT * FROM api._soil_characterisation_obs
  UNION ALL
  SELECT * FROM api._soil_bulk_density_obs
) AS partial;


DROP VIEW IF EXISTS api._soil_characterisation_oc;
CREATE VIEW api._soil_characterisation_oc AS
SELECT
  create_local_id('soil_characterisation'::text, sc.site_location_visit_id::text, sc.layer_barcode) AS "_id",
  'ogroup:SoilC14n' AS "dct:type", -- FIXME not in vocab
  sc.comments AS "rdfs:comment",
  sc.layer_barcode AS "rdfs:label",
  procedure_id('APSOIL01') AS "sosa:usedProcedure", -- TODO same procedure for all?
  site_visit_id(sc.site_location_visit_id) as "sosa:hasFeatureOfInterest"
FROM soil_characterisation AS sc;


DROP VIEW IF EXISTS api._soil_bulk_density_oc;
CREATE VIEW api._soil_bulk_density_oc AS
SELECT
  create_local_id('soil_bulk_density'::text, sbd.site_location_visit_id::text, sbd.sample_id) AS "_id",
  'ogroup:SoilBulk' AS "dct:type", -- FIXME not in vocab
  null AS "rdfs:comment",
  'Visit ID: ' || sbd.site_location_visit_id || ', sample ID: ' || sbd.sample_id AS "rdfs:label",
  procedure_id('APSOIL02') AS "sosa:usedProcedure", -- TODO same procedure for all?
  site_visit_id(sbd.site_location_visit_id) as "sosa:hasFeatureOfInterest"
FROM soil_bulk_density AS sbd;


DROP VIEW IF EXISTS api.om_observation_collection;
CREATE VIEW api.om_observation_collection AS
SELECT
  oc.*,
  json_agg(obs.json_object) AS "ssn-ext:hasMember"
FROM (
  SELECT
    context_url() AS "@context",
    'ssn-ext:ObservationCollection' AS "rdf:type",
    partial.*,
    observation_collection_id(partial."_id") AS "@id"
  FROM (
    SELECT * FROM api._soil_characterisation_oc
    UNION ALL
    SELECT * FROM api._soil_bulk_density_oc
  ) AS partial
) AS oc
INNER JOIN (
  SELECT
    "sosa:hasFeatureOfInterest",
    row_to_json(api.om_observation.*) AS json_object
  FROM api.om_observation
) AS obs
  ON obs."sosa:hasFeatureOfInterest" = oc."@id"
GROUP BY 1,2,3,4,5,6,7,8,9;

DROP VIEW IF EXISTS api.om_context;
CREATE VIEW api.om_context AS
SELECT
  'http://www.tern.org.au/ns/data/' AS data,
  'http://purl.org/dc/terms/' AS dct,
  'http://rs.tdwg.org/dwc/terms/' AS dwcterms,
  'http://www.opengis.net/ont/geosparql#' AS geosparql,
  'http://www.w3.org/ns/locn#' AS locn,
  'http://www.w3.org/ns/odrl/2/' AS odrl,
  'http://registry.it.csiro.au/sandbox/tern/plot/ogroup/' AS ogroup, -- TODO update if 'sandbox' is removed
  'http://www.tern.org.au/cv/op/' AS op,
  'http://www.w3.org/2002/07/owl#' AS owl,
  'http://www.tern.org.au/ns/plot/' AS plot,
  'http://www.tern.org.au/ns/plot/x/' AS "plot-x",
  'http://www.w3.org/ns/prov#' AS prov,
  'http://www.w3.org/1999/02/22-rdf-syntax-ns#' AS rdf,
  'http://www.w3.org/2000/01/rdf-schema#' AS rdfs,
  'http://www.w3.org/2004/02/skos/core#' AS skos,
  'http://www.w3.org/ns/sosa/' AS sosa,
  'http://www.w3.org/ns/ssn/' AS ssn,
  'http://www.w3.org/ns/ssn/ext/' AS "ssn-ext",
  'http://www.w3.org/2006/time#' AS time,
  'http://www.w3.org/2003/01/geo/wgs84_pos#' AS w3cgeo,
  'http://www.w3.org/2001/XMLSchema#' AS xsd
;



-- custom format for <ross dot searle at csiro dot au>
DROP VIEW IF EXISTS api.ross;
CREATE VIEW api.ross AS
SELECT
  sl.site_location_name,
  slv.site_location_visit_id,
  slp.latitude,
  slp.longitude,
  slv.visit_start_date AS "visit_date",
  sc.upper_depth,
  sc.lower_depth,
  the_obs.op AS "observed_property",
  the_obs.r AS "value"
FROM public.site_location AS sl
INNER JOIN public.site_location_visit AS slv
  ON slv.site_location_id = sl.site_location_id
  AND slv.site_location_visit_id NOT IN (
    SELECT * FROM unpublished_site_location_visit_ids
  )
INNER JOIN api.singular_site_location_point AS slp
  ON slp.site_location_id = sl.site_location_id
INNER JOIN soil_characterisation AS sc
  ON sc.site_location_visit_id = slv.site_location_visit_id
INNER JOIN (
  -- first one sets up the column names
  SELECT id, 'collected_by' AS op, collected_by::text AS r FROM soil_characterisation
  UNION ALL
  SELECT id, 'colour_when_dry', colour_when_dry::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'colour_when_moist', colour_when_moist::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'ec', ec::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'effervescence', effervescence::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'horizon', horizon::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'layer_barcode', layer_barcode::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'mottles_abundance', mottles_abundance::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'mottles_colour', mottles_colour::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'mottles_size', mottles_size::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'next_size_1', next_size_1::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'next_size_2', next_size_2::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'next_size_type_1', next_size_type_1::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'next_size_type_2', next_size_type_2::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'pedality_fabric', pedality_fabric::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'pedality_grade', pedality_grade::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'ph', ph::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'segregations_abundance', segregations_abundance::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'segregations_form', segregations_form::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'segregations_nature', segregations_nature::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'segregations_size', segregations_size::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'smallest_size_1', smallest_size_1::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'smallest_size_2', smallest_size_2::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'smallest_size_type_1', smallest_size_type_1::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'smallest_size_type_2', smallest_size_type_2::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'texture_grade', texture_grade::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'texture_modifier', texture_modifier::text FROM soil_characterisation
  UNION ALL
  SELECT id, 'texture_qualifier', texture_qualifier::text FROM soil_characterisation
) AS the_obs
ON sc.id = the_obs.id;



-- Soils2Satellites views
DROP VIEW IF EXISTS api.s2s_study_location;
CREATE VIEW api.s2s_study_location AS
SELECT
  sl.site_location_id AS "studyLocationId",
  sl.site_location_name AS "studyLocationName",
  slp.easting AS "easting",
  slp.northing AS "northing",
  slp.zone AS "mgaZone",
  slp.latitude,
  slp.longitude,
  first_visits."firstVisit",
  last_visits."lastVisit",
  observers.json_observers AS "observers"
FROM public.site_location AS sl
INNER JOIN api.singular_site_location_point AS slp
  ON slp.site_location_id = sl.site_location_id
INNER JOIN (
  SELECT
    site_location_id,
    json_agg(json_build_object(
      'affiliation', lo.affiliation,
      'observerName', lo.full_name
    )) AS json_observers
  FROM (
    SELECT
      site_location_id,
      observer_soil AS observer_id
    FROM public.site_location_visit
    UNION
    SELECT
      site_location_id,
      observer_veg
    FROM public.site_location_visit
  ) AS observer_ids
  INNER JOIN public.lut_observer AS lo
    ON lo.id = observer_ids.observer_id
  GROUP BY 1
) AS observers
  ON observers.site_location_id = sl.site_location_id
INNER JOIN (
  SELECT
    site_location_id,
    min(date(visit_start_date)) AS "firstVisit"
  FROM public.site_location_visit
  GROUP BY 1
) AS first_visits
  ON first_visits.site_location_id = sl.site_location_id
INNER JOIN (
  SELECT
    site_location_id,
    max(date(visit_start_date)) AS "lastVisit"
  FROM public.site_location_visit
  GROUP BY 1
) AS last_visits
  ON last_visits.site_location_id = sl.site_location_id;


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
GRANT SELECT ON api.metadata_dictionary TO web_anon;

GRANT SELECT ON api.om_context TO web_anon;
GRANT SELECT ON api.om_site TO web_anon;
GRANT SELECT ON api.om_site_visit TO web_anon;
GRANT SELECT ON api.om_site_point TO web_anon;
GRANT SELECT ON api.om_procedure TO web_anon;
GRANT SELECT ON api.om_observation TO web_anon;
GRANT SELECT ON api.om_observation_collection TO web_anon;

GRANT SELECT ON api.ross TO web_anon;

GRANT SELECT ON api.s2s_study_location TO web_anon;

SELECT 'success' AS outcome;
