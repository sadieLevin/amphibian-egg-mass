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
latitude VARCHAR(255),
longitude VARCHAR(255),
elevation VARCHAR(255),
utc_offset_seconds VARCHAR(255),
timezone VARCHAR(255),
timezone_abbreviation VARCHAR(255)
);

COPY staging_masses(
    SurveyID,DateTime,Latitude,Longitude,Accuracy_m,NumberOfEggMasses,SpeciesCode,EggMassSubstrate,Comments
)
FROM '/var/lib/postgres/engineering/amphibian-egg-mass/data/EggMasses.csv'
DELIMITER ','
CSV HEADER;

COPY staging_weather(
latitude,longitude,elevation,utc_offset_seconds,timezone,timezone_abbreviation
)
FROM '/var/lib/postgres/engineering/amphibian-egg-mass/data/open-meteo-47.63N122.17W179m.csv'
DELIMITER ','
CSV HEADER;
