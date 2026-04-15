-- sanity check
SELECT COUNT(*) FROM staging_masses;
SELECT COUNT(*) FROM staging_weather;
SELECT COUNT(*) FROM staging_survey;

-- creating normalized tables
CREATE TABLE species (
  species_id char(4) PRIMARY KEY,
  species_name varchar(80) NOT NULL,
  CONSTRAINT species_name_unique UNIQUE (species_name)
);

CREATE TABLE substrates (
  substrate_id smallserial PRIMARY KEY,
  substrate_name varchar(200) NOT NULL,
  CONSTRAINT substrate_name_unique UNIQUE (substrate_name)
);

CREATE TABLE lakes (
  lake_id smallserial PRIMARY KEY,
  lake_name varchar(200) NOT NULL,
  CONSTRAINT lake_name_unique UNIQUE (lake_name)
);

CREATE TABLE surveys (
  survey_id serial PRIMARY KEY,
  s_lat numeric(9, 6),
  s_lon numeric(9, 6),
  s_accuracy smallint,
  date date NOT NULL,
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
  comments varchar(300),
  lake_id int REFERENCES lakes(lake_id),
  CONSTRAINT check_date
    CHECK (date BETWEEN '2000-01-01' AND '2026-01-01'),
  CONSTRAINT start_end_check
    CHECK (start_time < end_time),
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

CREATE TABLE egg_masses (
  egg_mass_id serial PRIMARY KEY,
  mass_time timestamptz NOT NULL,
  mass_lat numeric(9,6),
  mass_lon numeric(9,6),
  mass_accuracy smallint,
  num_egg_masses smallint NOT NULL,
  species_id char(4) REFERENCES species(species_id),
  substrate_id smallint REFERENCES substrates(substrate_id),
  survey_id int REFERENCES surveys(survey_id),
  CONSTRAINT mass_lat_check
    CHECK (mass_lat BETWEEN 40.0 AND 50.0),
  CONSTRAINT mass_lon_check
    CHECK (mass_lon BETWEEN -125.0 AND -115.0),
  CONSTRAINT positive_masses
    CHECK (num_egg_masses > 0),
  CONSTRAINT positive_accuracy
    CHECK (mass_accuracy > 0)
);

CREATE TABLE survey_results (
  results_id serial PRIMARY KEY,
  total_egg_masses int,
  num_adults int,
  species_id char(4) REFERENCES species(species_id),
  survey_id int REFERENCES surveys(survey_id),
  CONSTRAINT positive_tot_masses
    CHECK (total_egg_masses > 0 OR total_egg_masses IS NULL),
  CONSTRAINT positive_adults
    CHECK (num_adults > 0 OR num_adults IS NULL)
);

CREATE TABLE observers (
  observer_id serial PRIMARY KEY,
  observer_name varchar(80) NOT NULL
);

CREATE TABLE observer_surveys (
  observer_id int REFERENCES observers(observer_id),
  survey_id int REFERENCES surveys(survey_id)
);

CREATE TABLE weather (
  weather_id serial PRIMARY KEY,
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

CREATE TABLE dates (
  date_id int PRIMARY KEY,
  date date NOT NULL,
  weather_id int REFERENCES weather(weather_id),
  survey_id int REFERENCES surveys(survey_id),
  CONSTRAINT weather_survey_unique UNIQUE (weather_id, survey_id)
);

-- backups
CREATE TABLE backup_masses AS 
SELECT * FROM staging_masses;

CREATE TABLE backup_survey AS 
SELECT * FROM staging_survey;

CREATE TABLE backup_weather AS 
SELECT * FROM staging_weather;

-- migration
START TRANSACTION;

INSERT INTO weather(temp_2m_mean, sunshine_duration, 
  precip_sum, rain_sum, snowfall_sum, wind_speed_10m_max)
SELECT temperature_2m_mean_C, sunshine_duration_s, precipitation_sum_mm, 
  rain_sum_mm, snowfall_sum_cm, wind_speed_10m_max_kmh
FROM staging_weather;

INSERT INTO lakes(lake_name)
SELECT DISTINCT Lake
FROM staging_survey;

SELECT * FROM lakes;
SELECT * FROM weather LIMIT 5;

COMMIT;

START TRANSACTION;
--INSERT INTO species(species_id)
--SELECT DISTINCT SpeciesCode
--FROM staging_survey WHERE SpeciesCode != 'NA';

SELECT * FROM species;
