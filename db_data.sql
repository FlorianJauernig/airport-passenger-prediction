---------- DATA ----------

-- DROP ALL TABLES
DROP TABLE IF EXISTS airports_annex CASCADE;
DROP TABLE IF EXISTS runways CASCADE;
DROP TABLE IF EXISTS airports CASCADE;
DROP TABLE IF EXISTS regions CASCADE;
DROP TABLE IF EXISTS countries CASCADE;
DROP TABLE IF EXISTS continents CASCADE;


-- CONTINENTS
CREATE TABLE continents (
code varchar CHECK (length(code) = 2) UNIQUE NOT NULL,
name varchar UNIQUE NOT NULL CHECK (length(name) > 0 AND length(name) <= 25),
PRIMARY KEY (code));

INSERT INTO continents(code, name) VALUES
('AF', 'Africa'),
('AN', 'Antarctica'),
('AS', 'Asia'),
('EU', 'Europe'),
('NA', 'North America'),
('OC', 'Oceania'),
('SA', 'South America');

-- COUNTRIES
CREATE TABLE countries (
id integer,
code varchar UNIQUE NOT NULL CHECK (length(code) = 2),
name varchar CHECK (length(name) > 0 AND length(name) <= 200),
continent varchar CHECK (length(continent) = 2),
wiki_link varchar CHECK (length(wiki_link) > 0 AND length(wiki_link) <= 200),
keywords varchar CHECK (length(keywords) > 0 AND length(keywords) <= 1000),
PRIMARY KEY (id));

\copy countries(id, code, name, continent, wiki_link, keywords) FROM 'data/countries.csv' DELIMITER ',' CSV HEADER ENCODING 'utf8';

-- REGIONS
CREATE TABLE regions (
id integer,
code varchar UNIQUE NOT NULL CHECK (length(code) > 0 AND length(code) <= 25),
local_code varchar CHECK (length(local_code) > 0 AND length(local_code) <= 25),
name varchar CHECK (length(name) > 0 AND length(name) <= 200),
continent varchar CHECK (length(continent) = 2),
country varchar CHECK (length(country) = 2),
wiki_link varchar CHECK (length(wiki_link) > 0 AND length(wiki_link) <= 200),
keywords varchar CHECK (length(keywords) > 0 AND length(keywords) <= 1000),
PRIMARY KEY (id));

\copy regions(id, code, local_code, name, continent, country, wiki_link, keywords) FROM 'data/regions.csv' DELIMITER ',' CSV HEADER ENCODING 'utf8';

-- AIRPORTS
CREATE TABLE airports (
id integer,
ident varchar UNIQUE NOT NULL CHECK (length(ident) > 0 AND length(ident) <= 25),
type varchar CHECK (length(type) > 0 AND length(type) <= 25),
name varchar CHECK (length(name) > 0 AND length(name) <= 200),
latitude_deg double precision,
longitude_deg double precision,
elevation_ft integer,
continent_code varchar CHECK (length(continent_code) = 2),
country_code varchar CHECK (length(country_code) = 2),
region_code varchar CHECK (length(region_code) > 0 AND length(region_code) <= 25),
municipality varchar CHECK (length(municipality) > 0 AND length(municipality) <= 200),
scheduled_service varchar,
gps_code varchar CHECK (length(gps_code) > 0 AND length(gps_code) <= 25),
code varchar,
local_code varchar CHECK (length(local_code) > 0 AND length(local_code) <= 25),
home_link varchar CHECK (length(home_link) > 0 AND length(home_link) <= 200),
wiki_link varchar CHECK (length(wiki_link) > 0 AND length(wiki_link) <= 200),
keywords varchar CHECK (length(keywords) > 0 AND length(keywords) <= 1000),
PRIMARY KEY (id),
FOREIGN KEY (continent_code) REFERENCES continents (code),
FOREIGN KEY (country_code) REFERENCES countries (code),
FOREIGN KEY (region_code) REFERENCES regions (code));

\copy airports(id, ident, type, name, latitude_deg, longitude_deg, elevation_ft, continent_code, country_code, region_code, municipality, scheduled_service, gps_code, code, local_code, home_link, wiki_link, keywords)  FROM 'data/airports.csv' DELIMITER ',' CSV HEADER ENCODING 'utf8';

CREATE INDEX airports_ident_index
ON airports
(ident);

CREATE INDEX airports_code_index
ON airports
(code);

-- RUNWAYS
CREATE TABLE runways (
id integer,
airport_id integer NOT NULL,
airport_ident varchar NOT NULL CHECK (length(airport_ident) > 0 AND length(airport_ident) <= 25),
length_ft integer,
width_ft integer,
surface varchar CHECK (length(surface) > 0 AND length(surface) <= 100),
lighted integer,
closed integer,
le_ident varchar CHECK (length(le_ident) > 0 AND length(le_ident) <= 25),
le_latitude_deg double precision,
le_longitude_deg double precision,
le_elevation_ft integer,
le_heading_degT double precision,
le_displaced_threshold_ft integer,
he_ident varchar CHECK (length(he_ident) > 0 AND length(he_ident) <= 25),
he_latitude_deg double precision,
he_longitude_deg double precision,
he_elevation_ft integer,
he_heading_degT double precision,
he_displaced_threshold_ft integer,
PRIMARY KEY (id),
FOREIGN KEY (airport_id) REFERENCES airports (id),
FOREIGN KEY (airport_ident) REFERENCES airports (ident));

\copy runways(id, airport_id, airport_ident, length_ft, width_ft, surface, lighted, closed, le_ident, le_latitude_deg, le_longitude_deg, le_elevation_ft, le_heading_degT, le_displaced_threshold_ft, he_ident, he_latitude_deg, he_longitude_deg, he_elevation_ft, he_heading_degT, he_displaced_threshold_ft) FROM 'data/runways.csv' DELIMITER ',' CSV HEADER ENCODING 'utf8';

CREATE INDEX runways_airport_id_index
ON runways
(airport_id);

CREATE INDEX runways_airport_ident_index
ON runways
(airport_ident);

-- DELETE SOME AIRPORTS AND RUNWAYS
DELETE FROM runways WHERE closed = '1';
DELETE FROM runways WHERE length_ft IS NULL OR length_ft < 2500;

DELETE FROM runways R
USING airports A
WHERE R.airport_ident = A.ident
AND A.code IS NULL;

DELETE FROM airports WHERE code IS NULL;

DELETE FROM runways R
USING airports A
WHERE R.airport_ident = A.ident
AND A.code = '0';

DELETE FROM airports WHERE code = '0';

DELETE FROM runways R
USING airports A
WHERE R.airport_ident = A.ident
AND (A.type = 'closed' OR A.type = 'heliport' OR A.type = 'seaplane_base');

DELETE FROM airports WHERE type = 'closed' OR type='heliport' OR type='seaplane_base';

DELETE FROM runways R
USING airports A
WHERE R.airport_ident = A.ident
AND length(A.ident) != 4 AND length(A.gps_code) !=4;

DELETE FROM airports WHERE length(ident) != 4 AND length(gps_code) !=4;

DELETE FROM runways WHERE Surface ILIKE '%gras%' OR Surface ILIKE '%turf%' OR Surface ILIKE '%san%' OR Surface ILIKE '%water%' OR Surface ILIKE '%dirt%' OR Surface ILIKE '%soil%' OR Surface ILIKE '%grav%' OR Surface ILIKE '%grvl%' OR Surface ILIKE '%clay%' OR Surface ILIKE '%grs%' OR Surface ILIKE '%coral%' OR Surface ILIKE '%murram%' OR Surface ILIKE '%unpaved%';

DELETE FROM airports
WHERE ident NOT IN (SELECT airport_ident from runways)
AND id NOT IN (SELECT airport_id from runways);

DELETE FROM runways
WHERE airport_id IN (
SELECT A1.id from airports A1
JOIN airports A2 ON A1.code = A2.code
WHERE (A1.id < A2.id));

DELETE FROM airports
WHERE id IN (
SELECT A1.id from airports A1
JOIN airports A2 ON A1.code = A2.code
WHERE (A1.id < A2.id));

DELETE FROM runways R
USING airports A
WHERE R.airport_ident = A.ident
AND A.scheduled_service = 'no'
AND (A.name ILIKE '%AFB%' OR A.name ILIKE '%air%base%' OR A.name ILIKE '%air%force%' OR A.name ILIKE '%army%' OR A.name ILIKE '%marine%' OR A.name ILIKE '%military%' OR A.name ILIKE '%naval%' OR A.name ILIKE '%RAF%' OR A.wiki_link ILIKE '%AFB%' OR A.wiki_link ILIKE '%air%base%' OR A.wiki_link ILIKE '%air%force%' OR A.wiki_link ILIKE '%army%' OR A.wiki_link ILIKE '%marine%' OR A.wiki_link ILIKE '%military%' OR A.wiki_link ILIKE '%naval%' OR A.wiki_link ILIKE '%RAF%' OR A.keywords ILIKE '%AFB%' OR A.keywords ILIKE '%air%base%' OR A.keywords ILIKE '%air%force%' OR A.keywords ILIKE '%army%' OR A.keywords ILIKE '%marine%' OR A.keywords ILIKE '%military%' OR A.keywords ILIKE '%naval%' OR A.keywords ILIKE '%RAF%' OR A.home_link ILIKE '%.mil%');

DELETE FROM airports
WHERE scheduled_service = 'no'
AND (name ILIKE '%AFB%' OR name ILIKE '%air%base%' OR name ILIKE '%air%force%' OR name ILIKE '%army%' OR name ILIKE '%marine%' OR name ILIKE '%military%' OR name ILIKE '%naval%' OR name ILIKE '%RAF%' OR wiki_link ILIKE '%AFB%' OR wiki_link ILIKE '%air%base%' OR wiki_link ILIKE '%air%force%' OR wiki_link ILIKE '%army%' OR wiki_link ILIKE '%marine%' OR wiki_link ILIKE '%military%' OR wiki_link ILIKE '%naval%' OR wiki_link ILIKE '%RAF%' OR keywords ILIKE '%AFB%' OR keywords ILIKE '%air%base%' OR keywords ILIKE '%air%force%' OR keywords ILIKE '%army%' OR keywords ILIKE '%marine%' OR keywords ILIKE '%military%' OR keywords ILIKE '%naval%' OR keywords ILIKE '%RAF%' OR home_link ILIKE '%.mil%');

CREATE UNIQUE INDEX CONCURRENTLY aiports_code
ON airports (code);

ALTER TABLE airports
ADD CONSTRAINT unique_code
UNIQUE USING INDEX aiports_code;

ALTER TABLE airports
ADD CONSTRAINT check_code
CHECK (length(code) = 3);

UPDATE airports SET type = 'Small' WHERE type = 'small_airport';
UPDATE airports SET type = 'Medium' WHERE type = 'medium_airport';
UPDATE airports SET type = 'Large' WHERE type = 'large_airport';

ALTER TABLE airports
ALTER COLUMN scheduled_service TYPE boolean
USING scheduled_service::boolean;

-- AIRPORTS ANNEX
CREATE TABLE airports_annex (
code varchar CHECK (length(code) = 3),
pax_2018_or_older integer,
PRIMARY KEY (code));

\copy airports_annex (code, pax_2018_or_older) FROM 'data/airports_pax.csv' DELIMITER ';' CSV HEADER ENCODING 'utf8';

DELETE FROM airports_annex where pax_2018_or_older IS NULL or pax_2018_or_older = 0;
DELETE FROM airports_annex where code NOT IN (SELECT DISTINCT(code) from airports);
ALTER TABLE airports_annex ADD CONSTRAINT fkey_code FOREIGN KEY (code) REFERENCES airports (code);
