-- QUERIES
SELECT s.date, l.lake_name, sr.total_egg_masses, sp.species_name, sp.species_id
FROM surveys AS s
JOIN survey_results AS sr ON s.survey_id = sr.survey_id
JOIN lakes AS l ON s.lake_id = l.lake_id
JOIN species AS sp ON sr.species_id = sp.species_id
WHERE sr.total_egg_masses IS NOT NULL
ORDER BY total_egg_masses DESC
LIMIT 10;

SELECT s.date, l.lake_name, sr.total_egg_masses, o.observer_name
FROM surveys AS s
JOIN survey_results AS sr ON s.survey_id = sr.survey_id
JOIN lakes AS l ON s.lake_id = l.lake_id
JOIN observer_surveys AS os ON s.survey_id = os.survey_id
JOIN observers AS o ON os.observer_id = o.observer_id
WHERE sr.total_egg_masses IS NOT NULL
ORDER BY total_egg_masses DESC
LIMIT 10;

SELECT sum(sr.total_egg_masses) AS sum_masses, observer_name
FROM survey_results AS sr
JOIN surveys AS s ON s.survey_id = sr.survey_id
JOIN observer_surveys AS os ON s.survey_id = os.survey_id
JOIN observers AS o ON os.observer_id = o.observer_id
GROUP BY observer_name
ORDER BY sum_masses DESC;

SELECT sum(sr.total_egg_masses) AS sum_masses, count(s.date) AS num_surveys, sum(sr.total_egg_masses)/count(s.survey_id) AS masses_per_survey, observer_name
FROM survey_results AS sr
JOIN surveys AS s ON s.survey_id = sr.survey_id
JOIN observer_surveys AS os ON s.survey_id = os.survey_id
JOIN observers AS o ON os.observer_id = o.observer_id
GROUP BY observer_name
ORDER BY masses_per_survey DESC;

WITH survey_totals AS (
  SELECT s.survey_id, o.observer_name, sum(sr.total_egg_masses)
  FROM surveys AS s
  JOIN observer_surveys AS os ON s.survey_id = os.survey_id
  JOIN observers AS o ON os.observer_id = o.observer_id
  JOIN survey_results AS sr ON s.survey_id = sr.survey_id
  GROUP BY s.survey_id, o.observer_name