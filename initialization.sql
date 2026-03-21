-- CREATE DATABASE amphibian_mass;

CREATE TABLE staging_masses
SurveyID VARCHAR(63),
DateTime VARCHAR(63),
Latitude VARCHAR(63),
Longitude VARCHAR(63),
Accuracy_m VARCHAR(63),
NumberOfEggMasses VARCHAR(63),
SpeciesCode VARCHAR(63),
EggMassSubstrate VARCHAR(63),
Comments VARCHAR(63)

CREATE TABLE staging_weather
time VARCHAR(63),
temperature_2m_mean_(°C) VARCHAR(63),
sunshine_duration_(s) VARCHAR(63),
precipitation_sum_(mm) VARCHAR(63),
rain_sum_(mm) VARCHAR(63),
snowfall_sum_(cm) VARCHAR(63),
wind_speed_10m_max_(km/h) VARCHAR(63)


