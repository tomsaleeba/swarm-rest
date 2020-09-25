-- A series of queries to give an idea of how well the WFO matching has gone
\pset border 2

-- TODO consider change to HTML format and piping to a file that we can serve.
-- \pset format html

\pset title 'How many records do we have?'
SELECT 'WFO records' AS "Record type", count(*)
FROM wfo_determination
UNION
SELECT 'Herbarium determination records', count(*)
FROM herbarium_determination;


\pset title 'Breakdown of record (veg vouchers) count for different values of the rank from WFO. Blanks are values that we sent to WFO but did NOT get a match.'
SELECT
  taxon_rank AS "rank",
  count(*) AS "Count of veg vouchers"
FROM wfo_determination
GROUP BY 1
ORDER BY 1;


\pset title 'Breakdown of record (veg vouchers) count for different values of the taxa_group from WFO. Blanks are values that we sent to WFO but did NOT get a match.'
SELECT
  tax_group AS taxa_group,
  count(*) AS "Count of veg vouchers"
FROM wfo_determination
GROUP BY 1;


\pset title 'All the species that WFO could not match. They have a "match record" but no taxon_rank value (not NULL, but a zero length string). These are the "blanks" from the two tables above.'
SELECT
  original_herbarium_determination AS "Herbarium determination",
  count(*) AS "Count of veg vouchers"
FROM wfo_determination
WHERE taxon_rank = ''
GROUP BY 1
ORDER BY 2 DESC;


\pset title 'A sample of the most occurring herbarium determination records that have no WFO match record. This is either because we made the decision not to send it or something else went wrong (the call to match failed?). You should NOT see things that look like real species names in this table.'
SELECT herbarium_determination, count(*)
FROM herbarium_determination
WHERE veg_barcode NOT IN (
  SELECT veg_barcode
  FROM wfo_determination
)
GROUP BY 1
ORDER BY 2 DESC
LIMIT 25;


\pset title 'A sample of the most occurring "never tried (because we think they are not real species)" or "never had a WFO match record (not has a record but it is blank) written" species. Similar to the table above, except here we only use species name, not the veg_barcode. You should NOT see things that look like real species names in this table.'
SELECT herbarium_determination, count(*)
FROM herbarium_determination
WHERE trim(herbarium_determination) NOT IN (
  SELECT trim(original_herbarium_determination)
  FROM wfo_determination
)
GROUP BY 1
ORDER BY 2 DESC
LIMIT 25;


\pset title 'Count of "has no WFO match record" species (the species in the table above)'
SELECT count(DISTINCT herbarium_determination) AS distinct_species, count(*) AS total
FROM herbarium_determination
WHERE trim(herbarium_determination) NOT IN (
  SELECT trim(original_herbarium_determination)
  FROM wfo_determination
);


\pset title 'Count of species name that sometimes match and sometimes do not. Zero is good!'
SELECT count(*)
FROM herbarium_determination
WHERE veg_barcode NOT IN (
  SELECT veg_barcode
  FROM wfo_determination
)
AND trim(herbarium_determination) IN (
  SELECT trim(original_herbarium_determination)
  FROM wfo_determination
)
LIMIT 25;
 

\pset title 'A sample of the most occurring "sometimes matches" (same as table above) species names, count=times it did NOT match'
SELECT herbarium_determination, count(*)
FROM herbarium_determination
WHERE veg_barcode NOT IN (
  SELECT veg_barcode
  FROM wfo_determination
)
AND trim(herbarium_determination) IN (
  SELECT trim(original_herbarium_determination)
  FROM wfo_determination
)
GROUP BY 1
ORDER BY 2 DESC
LIMIT 25;


\pset title 'Records that have their barcode present in the WFO match table but the herbarium_determination value does not appear in the list of original determinations. Basically an indicator that old data was matched against WFO. This table should be empty.'
select hd.veg_barcode, hd.herbarium_determination, wf.original_herbarium_determination
FROM herbarium_determination AS hd
INNER JOIN wfo_determination AS wf
ON hd.veg_barcode = wf.veg_barcode
WHERE trim(hd.herbarium_determination) NOT IN (
  SELECT trim(original_herbarium_determination)
  FROM wfo_determination
)
AND hd.veg_barcode IN (
  SELECT veg_barcode
  FROM wfo_determination
)
LIMIT 25;


\pset title 'Sample of matches to use for checking WFO accuracy by hand. Will be different every time the report runs. Sample size will change slightly but is roughly 50.'
SELECT
  original_herbarium_determination AS "Name sent to WFO",
  scientific_name AS "Standardised name match we got back"
FROM wfo_determination
WHERE (random() * 700)::int = 1;
