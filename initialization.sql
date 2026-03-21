-- CREATE DATABASE amphibian_mass;

CREATE TABLE staging_masses(
SurveyID VARCHAR(63),
DateTime VARCHAR(63),
Latitude VARCHAR(63),
Longitude VARCHAR(63),
Accuracy_m VARCHAR(63),
NumberOfEggMasses VARCHAR(63),
SpeciesCode VARCHAR(63),
EggMassSubstrate VARCHAR(63),
Comments VARCHAR(255)
);

CREATE TABLE staging_weather(   
time DATE,
temperature_2m_mean_C FLOAT,
sunshine_duration_s FLOAT,
precipitation_sum_mm FLOAT,
rain_sum_mm FLOAT,
snowfall_sum_cm FLOAT,
wind_speed_10m_max_kmh FLOAT
);

COPY staging_masses(
    SurveyID,DateTime,Latitude,Longitude,Accuracy_m,NumberOfEggMasses,SpeciesCode,EggMassSubstrate,Comments
)
FROM '/var/lib/postgres/engineering/amphibian-egg-mass/data/EggMasses.csv'
DELIMITER ','
CSV HEADER;

COPY staging_weather(
time,
temperature_2m_mean_C,
sunshine_duration_s,
precipitation_sum_mm,
rain_sum_mm,
snowfall_sum_cm,
wind_speed_10m_max_kmh
)
FROM '/var/lib/postgres/engineering/amphibian-egg-mass/data/open-meteo-47.63N122.17W179m.csv'
DELIMITER ','
CSV HEADER;
