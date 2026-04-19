-- sanity check
SELECT COUNT(*) FROM staging_masses;
SELECT COUNT(*) FROM staging_weather;
SELECT COUNT(*) FROM staging_survey;

-- creating normalized tables
DROP TABLE IF EXISTS species CASCADE;
CREATE TABLE species (
  species_id char(4) PRIMARY KEY,
  species_name varchar(80) NOT NULL,
  CONSTRAINT species_name_unique UNIQUE (species_name)
);

DROP TABLE IF EXISTS substrates CASCADE;
CREATE TABLE substrates (
  substrate_id smallserial PRIMARY KEY,
  substrate_name varchar(200) NOT NULL,
  CONSTRAINT substrate_name_unique UNIQUE (substrate_name)
);

DROP TABLE IF EXISTS lakes CASCADE;
CREATE TABLE lakes (
  lake_id smallserial PRIMARY KEY,
  lake_name varchar(200) NOT NULL,
  CONSTRAINT lake_name_unique UNIQUE (lake_name)
);

DROP TABLE IF EXISTS weather CASCADE;
CREATE TABLE weather (
  date date PRIMARY KEY,
  temp_2m_mean numeric(3, 1) NOT NULL,
  sunshine_duration numeric(7, 2) NOT NULL,
  precip_sum numeric(4, 2) NOT NULL,
  rain_sum numeric(4, 2) NOT NULL,
  snowfall_sum numeric(4, 2) NOT NULL,
  wind_speed_10m_max numeric(3, 1) NOT NULL,
  CONSTRAINT sun_pos
    CHECK (sunshine_duration >= 0),
  CONSTRAINT precip_pos
    CHECK (precip_sum >= 0),
  CONSTRAINT rain_pos
    CHECK (rain_sum >= 0),
  CONSTRAINT snow_pos
    CHECK (snowfall_sum >= 0),
  CONSTRAINT wind_pos
    CHECK (wind_speed_10m_max >= 0)
);

DROP TABLE IF EXISTS surveys CASCADE;
CREATE TABLE surveys (
  survey_id serial PRIMARY KEY,
  og_id varchar(200),
  s_lat numeric(9, 6),
  s_lon numeric(9, 6),
  s_accuracy smallint,
  start_time timestamptz,
  end_time timestamptz,
  last_obs_time timestamptz,
  weather_comments varchar(300),
  s_sunshine varchar(80),
  s_precip varchar(80),
  s_wind varchar (80),
  s_air_thermometer boolean,
  s_air_temp numeric(4,1),
  s_water_thermometer boolean,
  s_water_temp numeric(4,1),
  water_color varchar(80),
  survey_type varchar(80),
  date date REFERENCES weather(date),
  lake_id int REFERENCES lakes(lake_id),
  CONSTRAINT check_date
    CHECK (date BETWEEN '2000-01-01' AND '2026-01-01'),
  CONSTRAINT start_date_match
    CHECK (date::timestamptz = date_trunc('day', start_time)),
  CONSTRAINT air_temp_check
    CHECK (s_air_temp BETWEEN -80.0 AND 150.0),
  CONSTRAINT water_temp_check
    CHECK (s_water_temp BETWEEN -90.0 AND 140.0),
  CONSTRAINT s_lat_check
    CHECK (s_lat BETWEEN 40.0 AND 50.0),
  CONSTRAINT s_lon_check
    CHECK (s_lon BETWEEN -125.0 AND -115.0),
  CONSTRAINT positive_accuracy
    CHECK (s_accuracy > 0)
);

DROP TABLE IF EXISTS egg_masses;
CREATE TABLE egg_masses (
  egg_mass_id serial PRIMARY KEY,
  og_id varchar(100) NOT NULL,
  mass_time timestamptz NOT NULL,
  mass_lat numeric(9,6),
  mass_lon numeric(9,6),
  mass_accuracy smallint,
  num_egg_masses smallint NOT NULL,
  mass_comments varchar(300), 
  species_id char(4) REFERENCES species(species_id),
  substrate_id smallint REFERENCES substrates(substrate_id),
  survey_id int REFERENCES surveys(survey_id),
  CONSTRAINT mass_lat_check
    CHECK (mass_lat BETWEEN 40.0 AND 50.0),
  CONSTRAINT mass_lon_check
    CHECK (mass_lon BETWEEN -125.0 AND -115.0),
  CONSTRAINT positive_masses
    CHECK (num_egg_masses >= 0),
  CONSTRAINT positive_accuracy
    CHECK (mass_accuracy >= 0)
);

DROP TABLE IF EXISTS survey_results;
CREATE TABLE survey_results (
  results_id serial PRIMARY KEY,
  total_egg_masses int,
  num_adults int,
  comments varchar(300),
  species_id char(4) REFERENCES species(species_id),
  survey_id int REFERENCES surveys(survey_id),
  CONSTRAINT positive_tot_masses
    CHECK (total_egg_masses >= 0 OR total_egg_masses IS NULL),
  CONSTRAINT positive_adults
    CHECK (num_adults >= 0 OR num_adults IS NULL)
);

DROP TABLE IF EXISTS observers CASCADE;
CREATE TABLE observers (
  observer_id serial PRIMARY KEY,
  observer_name varchar(80) NOT NULL
);

DROP TABLE IF EXISTS observer_surveys;
CREATE TABLE observer_surveys (
  observer_id int REFERENCES observers(observer_id),
  survey_id int REFERENCES surveys(survey_id)
);

-- backups
--DROP TABLE IF EXISTS backup_masses;
CREATE TABLE backup_masses AS 
SELECT * FROM staging_masses;
SELECT count(*) FROM backup_masses;

--DROP TABLE IF EXISTS backup_survey;
CREATE TABLE backup_survey AS 
SELECT * FROM staging_survey;
SELECT count(*) FROM backup_survey;

--DROP TABLE IF EXISTS backup_weather;
CREATE TABLE backup_weather AS 
SELECT * FROM staging_weather;
SELECT count(*) FROM backup_weather;

-- migration
START TRANSACTION;

INSERT INTO weather(date, temp_2m_mean, sunshine_duration, 
  precip_sum, rain_sum, snowfall_sum, wind_speed_10m_max)
SELECT time, temperature_2m_mean_C, sunshine_duration_s, precipitation_sum_mm, 
  rain_sum_mm, snowfall_sum_cm, wind_speed_10m_max_kmh
FROM staging_weather;

INSERT INTO lakes(lake_name)
SELECT DISTINCT Lake
FROM staging_survey;

SELECT count(*) AS lakes_count FROM lakes;
SELECT count(*) AS weather_count FROM weather;

COMMIT;

DROP TABLE IF EXISTS staging_names;
CREATE TABLE staging_names (
  code varchar(4) PRIMARY KEY,
  species_name varchar(80) NOT NULL
);

INSERT INTO staging_names
VALUES ('AMGR', 'Ambystoma gracile'), 
  ('AMMA', 'Ambystoma macrodactylum'), 
  ('PSRE', 'Pseudacris regilla'),
  ('RAAU', 'Rana aurora'),
  ('TAGR', 'Taricha granulosa');

START TRANSACTION;

INSERT INTO species(species_id, species_name)
SELECT DISTINCT s.SpeciesCode, n.species_name
FROM staging_survey AS s
JOIN staging_names AS n ON s.SpeciesCode = n.code
WHERE SpeciesCode IS NOT NULL;

SELECT count(*) AS species_count FROM species;
SELECT * FROM species;

INSERT INTO substrates(substrate_name)
SELECT DISTINCT EggMassSubstrate
FROM staging_masses WHERE EggMassSubstrate IS NOT NULL;

SELECT count(*) AS substrate_count FROM substrates;
SELECT * FROM substrates;

COMMIT;

START TRANSACTION;

INSERT INTO surveys(og_id, date, s_lat, s_lon, s_accuracy, start_time, end_time, 
  last_obs_time, s_sunshine, s_precip, s_wind, 
  s_air_thermometer, s_air_temp, s_water_thermometer, s_water_temp, 
  water_color, survey_type, lake_id)
SELECT DISTINCT s.SurveyID, s.Date, s.Latitude::numeric, s.Longitude::numeric, s.Accuracy_m::numeric, 
  CAST(s.Date as date) + CAST(s.StartTime as time),
  CAST(s.Date as date) + CAST(s.EndTime as time),
  CAST(s.Date as date) + CAST(s.latest_observation_time as time),
  s.Sky, s.Precip, Wind, 
  CASE WHEN s.AirThermometer = 'Yes' THEN TRUE 
  WHEN s.airthermometer = 'No' THEN FALSE 
  ELSE NULL END, s.airtemperature_f::numeric,
  CASE WHEN s.waterthermometer = 'Yes' THEN TRUE 
  WHEN s.waterthermometer = 'No' THEN FALSE 
  ELSE NULL END, s.watertemperature_f::numeric, s.watercolor, s.surveytype, 
  l.lake_id
FROM staging_survey AS s
JOIN lakes AS l ON s.lake = l.lake_name;

SELECT count(*) AS survey_count FROM surveys;
SELECT og_id, date FROM surveys
ORDER BY date, og_id;

COMMIT;

START TRANSACTION;

INSERT INTO observers(observer_name)
SELECT DISTINCT regexp_split_to_table(Observer, ', ')
FROM staging_survey;

SELECT count(*) as observers_count FROM observers;

COMMIT;

DROP TABLE observer_staging;
CREATE TABLE observer_staging (
  obs_id serial PRIMARY KEY,
  og_id varchar(200), 
  survey_id int references surveys(survey_id), 
  date date references weather(date),
  observer varchar(200)
);

START TRANSACTION; 

INSERT INTO observer_staging(og_id, observer, date, survey_id)
SELECT DISTINCT s.surveyid, regexp_split_to_table(s.Observer, ', '), s.date, su.survey_id
FROM staging_survey AS s
JOIN surveys AS su ON s.surveyid = su.og_id;

SELECT count(*) AS staging_count FROM observer_staging;
SELECT * FROM observer_staging LIMIT 6;

INSERT INTO observer_surveys(observer_id, survey_id)
SELECT o.observer_id, s.survey_id
FROM observers AS o
JOIN observer_staging AS os ON o.observer_name=os.observer
JOIN surveys AS s ON os.og_id = s.og_id;

SELECT count(*) AS observer_surveys_count FROM observer_surveys;
SELECT * FROM observer_surveys LIMIT 6;

COMMIT;

START TRANSACTION;

INSERT INTO survey_results(total_egg_masses, num_adults, species_id, survey_id, comments)
SELECT st.numberofeggmasses::numeric, st.numberofadults::numeric, st.speciescode, su.survey_id, st.comments
FROM staging_survey AS st
JOIN surveys AS su ON st.surveyid = su.og_id;

SELECT count(*) AS results_count FROM survey_results;

INSERT INTO egg_masses(og_id, mass_time, mass_lat, mass_lon, mass_accuracy, num_egg_masses, 
  mass_comments, species_id, substrate_id, survey_id)
SELECT m.surveyid, m.datetime::timestamptz, m.latitude::numeric, m.longitude::numeric, m.accuracy_m::numeric, m.numberofeggmasses::numeric, 
  m.comments, m.speciescode, su.substrate_id, s.survey_id
FROM staging_masses AS m
JOIN surveys AS s ON m.surveyid = s.og_id
JOIN substrates AS su ON m.eggmasssubstrate = su.substrate_name;

SELECT count(*) AS masses_count FROM egg_masses;

COMMIT;
