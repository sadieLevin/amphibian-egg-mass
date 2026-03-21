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
time VARCHAR(63),
temperature_2m_mean_C VARCHAR(63),
sunshine_duration_s VARCHAR(63),
precipitation_sum_mm VARCHAR(63),
rain_sum_mm VARCHAR(63),
snowfall_sum_cm VARCHAR(63),
wind_speed_10m_max_kmh VARCHAR(63)
);

\copy staging_masses(
    SurveyID,DateTime,Latitude,Longitude,Accuracy_m,NumberOfEggMasses,SpeciesCode,EggMassSubstrate,Comments
)
FROM './data/EggMasses.csv'
DELIMITER ','
CSV HEADER;
