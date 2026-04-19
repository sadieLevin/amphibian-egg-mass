-- CREATE DATABASE amphibian_mass;
DROP TABLE staging_masses;
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

DROP TABLE staging_survey;
CREATE TABLE staging_survey(
  SurveyID VARCHAR(35),
  Latitude VARCHAR(63),
  Longitude VARCHAR(63),
  Accuracy_m VARCHAR(63),
  Date DATE,
  StartTime VARCHAR(63),
  EndTime VARCHAR(63), 
  SurveyLength VARCHAR(63),
  SurveyLengthCalc VARCHAR(63), 
  latest_observation_time VARCHAR(63),
  Lake VARCHAR(63),
  Observer VARCHAR(63),
  Sky VARCHAR(63),
  Precip VARCHAR(63),
  Wind VARCHAR(63),
  AirThermometer VARCHAR(63),
  AirTemperature_F VARCHAR(63),
  WaterThermometer VARCHAR(63),
  WaterTemperature_F VARCHAR(63),
  WaterColor VARCHAR(63),
  SurveyType VARCHAR(63),
  Comments VARCHAR(255),
  SpeciesCode VARCHAR(5),
  NumberOfEggMasses VARCHAR(63),
  NumberOfAdults VARCHAR(63),
  Weather VARCHAR(63)
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
FROM '/tmp/EggMasses.csv'
DELIMITER ','
CSV HEADER
NULL 'NA';

COPY staging_weather(
time,
temperature_2m_mean_C,
sunshine_duration_s,
precipitation_sum_mm,
rain_sum_mm,
snowfall_sum_cm,
wind_speed_10m_max_kmh
)
FROM '/tmp/open-meteo-47.63N122.17W179m.csv'
DELIMITER ','
CSV HEADER;

COPY staging_survey(
  SurveyID,
  Latitude,
  Longitude,
  Accuracy_m,
  Date,
  StartTime,
  EndTime, 
  SurveyLength,
  SurveyLengthCalc, 
  latest_observation_time,
  Lake,
  Observer,
  Sky,
  Precip,
  Wind,
  AirThermometer,
  AirTemperature_F,
  WaterThermometer,
  WaterTemperature_F,
  WaterColor,
  SurveyType,
  Comments,
  SpeciesCode,
  NumberOfEggMasses,
  NumberOfAdults,
  Weather) 
FROM '/tmp/SurveyResults.csv'
DELIMITER ','
CSV HEADER
NULL 'NA';

SELECT COUNT(*) FROM staging_masses;
SELECT COUNT(*) FROM staging_weather;
SELECT COUNT(*) FROM staging_survey;


