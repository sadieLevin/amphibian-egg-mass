SELECT speciescode, COUNT(*) AS num_obv FROM staging_masses GROUP BY speciescode;

SELECT DISTINCT eggmasssubstrate FROM staging_masses LIMIT 20;


