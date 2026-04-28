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
  SELECT s.survey_id AS id, o.observer_name, 
    sum(sr.total_egg_masses) AS survey_total_masses
  FROM surveys AS s
  JOIN observer_surveys AS os ON s.survey_id = os.survey_id
  JOIN observers AS o ON os.observer_id = o.observer_id
  JOIN survey_results AS sr ON s.survey_id = sr.survey_id
  GROUP BY s.survey_id, o.observer_name
)
SELECT sum(survey_total_masses) AS sum_masses, 
  count(id) AS num_surveys, 
  round(sum(survey_total_masses) / count(id), 1) AS masses_per_survey, 
  observer_name
FROM survey_totals
GROUP BY observer_name
ORDER BY masses_per_survey DESC;

-- PRECIPITATION
-- precip quartiles (all of Seattle weather)
SELECT count(*),
  max(precip_sum) AS max_precip,
  PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY precip_sum) AS third_precip,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY precip_sum) AS med_precip,
  PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY precip_sum) AS first_precip,
  min(precip_sum) AS min_precip
FROM weather;

-- weather during surveys for comparison
WITH survey_weather AS (
  SELECT w.precip_sum, s.survey_id, s.date
  FROM surveys AS s
  JOIN weather AS w ON s.date = w.date
)
SELECT 
  max(precip_sum) AS max_precip,
  PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY precip_sum) AS third_precip,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY precip_sum) AS med_precip,
  PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY precip_sum) AS first_precip,
  min(precip_sum) AS min_precip
FROM survey_weather;

-- precip quartiles view
CREATE OR REPLACE VIEW precip_quartiles AS 
SELECT max(precip_sum) AS max_precip,
PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY precip_sum) AS third_precip,
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY precip_sum) AS med_precip,
PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY precip_sum)::numeric AS first_precip,
min(precip_sum) AS min_precip
FROM weather;

-- avg, median, & sum masses by precip amount (across all observers)
WITH survey_totals AS (
  SELECT s.survey_id AS id,
  sum(sr.total_egg_masses) AS survey_total_masses,
  s.date,
  w.precip_sum
  FROM surveys AS s
  JOIN survey_results AS sr ON s.survey_id = sr.survey_id
  JOIN weather AS w ON s.date=w.date
  GROUP BY s.survey_id, w.precip_sum
)
SELECT 
  CASE WHEN precip_sum >= 0.5 THEN 'precip'
  ELSE 'dry'
  END AS precip_amt,
  round(avg(survey_total_masses), 4) AS avg_masses,
  percentile_cont(0.5) WITHIN GROUP (ORDER BY survey_total_masses) AS med_masses,
  sum(survey_total_masses) AS sum_masses
FROM survey_totals
GROUP BY precip_amt;

WITH survey_totals AS (
  SELECT s.survey_id AS id, o.observer_name, 
    sum(sr.total_egg_masses) AS survey_total_masses,
    CASE WHEN w.precip_sum >= 4.9 THEN 'high'
    ELSE 'med_low'
    END AS precip_amt
  FROM surveys AS s
  JOIN observer_surveys AS os ON s.survey_id = os.survey_id
  JOIN observers AS o ON os.observer_id = o.observer_id
  JOIN survey_results AS sr ON s.survey_id = sr.survey_id
  JOIN weather AS w ON s.date = w.date
  GROUP BY s.survey_id, o.observer_name, precip_amt
)
SELECT sum(survey_total_masses) AS sum_masses, 
  count(id) AS num_surveys, 
  round(sum(survey_total_masses) / count(id), 1) AS masses_per_survey, 
  observer_name,
  precip_amt
FROM survey_totals
GROUP BY observer_name, precip_amt
ORDER BY masses_per_survey DESC;

-- masses per survey by observer and precip amount
WITH survey_totals AS (
  SELECT s.survey_id AS id, o.observer_name, 
    sum(sr.total_egg_masses) AS survey_total_masses,
    CASE WHEN w.precip_sum >= 0.5 THEN 'precip'
    ELSE 'dry'
    END AS precip_amt
  FROM surveys AS s
  JOIN observer_surveys AS os ON s.survey_id = os.survey_id
  JOIN observers AS o ON os.observer_id = o.observer_id
  JOIN survey_results AS sr ON s.survey_id = sr.survey_id
  JOIN weather AS w ON s.date = w.date
  GROUP BY s.survey_id, o.observer_name, precip_amt
)
SELECT sum(survey_total_masses) AS sum_masses, 
  count(id) AS num_surveys, 
  round(sum(survey_total_masses) / count(id), 1) AS masses_per_survey, 
  observer_name,
  precip_amt
FROM survey_totals
GROUP BY precip_amt, observer_name
ORDER BY masses_per_survey DESC;

-- by species
WITH survey_totals AS (
  SELECT s.survey_id AS id, sp.species_name, 
    sum(sr.total_egg_masses) AS survey_total_masses,
    CASE WHEN w.precip_sum >= 0.5 THEN 'precip'
    ELSE 'dry'
    END AS precip_amt
  FROM surveys AS s
  JOIN survey_results AS sr ON s.survey_id = sr.survey_id
  JOIN species AS sp ON sr.species_id = sp.species_id
  JOIN weather AS w ON s.date = w.date
  GROUP BY s.survey_id, sp.species_name, precip_amt
)
SELECT sum(survey_total_masses) AS sum_masses, 
  count(id) AS num_surveys, 
  round(sum(survey_total_masses) / count(id), 1) AS masses_per_survey, 
  species_name,
  precip_amt
FROM survey_totals
GROUP BY precip_amt, species_name
ORDER BY sum_masses DESC;

-- SUNSHINE DURATION
-- total sun quartiles
SELECT max(sunshine_duration) AS max_sun,
  PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY sunshine_duration) AS third_sun,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sunshine_duration) AS med_sun,
  PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY sunshine_duration)::numeric AS first_sun,
  min(sunshine_duration) AS min_sun
FROM weather;

-- survey sun quartiles
WITH survey_weather AS (
  SELECT w.sunshine_duration, s.survey_id, s.date
  FROM surveys AS s
  JOIN weather AS w ON s.date = w.date
)
SELECT --count(*), 
  max(sunshine_duration) AS max_sun,
  PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY sunshine_duration) AS third_sun,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sunshine_duration) AS med_sun,
  PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY sunshine_duration)::numeric AS first_sun,
  min(sunshine_duration) AS min_sun
FROM survey_weather;

-- sunshine egg masses
WITH survey_totals AS (
  SELECT s.survey_id AS id,
  sum(sr.total_egg_masses) AS survey_total_masses,
  s.date,
  w.sunshine_duration
  FROM surveys AS s
  JOIN survey_results AS sr ON s.survey_id = sr.survey_id
  JOIN weather AS w ON s.date=w.date
  GROUP BY s.survey_id, w.sunshine_duration
)
SELECT 
  CASE WHEN sunshine_duration <= 33684.69 THEN 'cloudy'
  ELSE 'sunny'
  END AS sun_amt,
  round(avg(survey_total_masses), 4) AS avg_masses,
  percentile_cont(0.5) WITHIN GROUP (ORDER BY survey_total_masses) AS med_masses,
  sum(survey_total_masses) AS sum_masses
FROM survey_totals
GROUP BY sun_amt;

-- masses per survey by sun and observer
WITH survey_totals AS (
  SELECT s.survey_id AS id, o.observer_name, 
    sum(sr.total_egg_masses) AS survey_total_masses,
    CASE WHEN w.sunshine_duration <= 33684.69 THEN 'cloudy'
    ELSE 'sunny'
    END AS sun_amt
  FROM surveys AS s
  JOIN observer_surveys AS os ON s.survey_id = os.survey_id
  JOIN observers AS o ON os.observer_id = o.observer_id
  JOIN survey_results AS sr ON s.survey_id = sr.survey_id
  JOIN weather AS w ON s.date = w.date
  GROUP BY s.survey_id, o.observer_name, sun_amt
)
SELECT sum(survey_total_masses) AS sum_masses, 
  count(id) AS num_surveys, 
  round(sum(survey_total_masses) / count(id), 1) AS masses_per_survey, 
  observer_name,
  sun_amt
FROM survey_totals
GROUP BY sun_amt, observer_name
ORDER BY masses_per_survey DESC;

-- CORRELATIONS
-- does rain predict egg masses found?
WITH survey_totals AS (
  SELECT s.survey_id AS id,
  sum(sr.total_egg_masses) AS survey_total_masses,
  s.date,
  w.precip_sum
  FROM surveys AS s
  JOIN survey_results AS sr ON s.survey_id = sr.survey_id
  JOIN weather AS w ON s.date=w.date
  GROUP BY s.survey_id, w.precip_sum
)
SELECT round(corr(survey_total_masses, precip_sum)::numeric, 3) AS precip_masses_r
FROM survey_totals;

-- does sun predict egg masses found? 
WITH survey_totals AS (
  SELECT s.survey_id AS id,
  sum(sr.total_egg_masses) AS survey_total_masses,
  s.date,
  w.sunshine_duration
  FROM surveys AS s
  JOIN survey_results AS sr ON s.survey_id = sr.survey_id
  JOIN weather AS w ON s.date=w.date
  GROUP BY s.survey_id, w.sunshine_duration
)
SELECT round(corr(survey_total_masses, sunshine_duration)::numeric, 3) AS sun_masses_r
FROM survey_totals;

-- does week predict egg masses found?
WITH survey_totals AS (
  SELECT s.survey_id AS id,
  sum(sr.total_egg_masses) AS survey_total_masses,
  s.date,
  date_part('week', s.date) AS week
  FROM surveys AS s
  JOIN survey_results AS sr ON s.survey_id = sr.survey_id
  GROUP BY s.survey_id, week
)
SELECT round(corr(survey_total_masses, week)::numeric, 3) AS week_masses_r
FROM survey_totals;

-- DATE/TIME OF YEAR
WITH survey_totals AS (
  SELECT s.survey_id AS id,
  sum(sr.total_egg_masses) AS survey_total_masses,
  s.date,
  w.precip_sum
  FROM surveys AS s
  JOIN survey_results AS sr ON s.survey_id = sr.survey_id
  JOIN weather AS w ON s.date = w.date
  GROUP BY s.survey_id, w.precip_sum
)
SELECT 
  round(avg(precip_sum), 2) AS avg_precip,
  date_part('week', date) AS week,
  --avg(date_part('month', date)) AS month,
  count(id) AS num_surveys,
  round(avg(survey_total_masses), 4) AS avg_masses,
  percentile_cont(0.5) WITHIN GROUP (ORDER BY survey_total_masses) AS med_masses,
  sum(survey_total_masses) AS sum_masses
FROM survey_totals
GROUP BY week
ORDER BY week;

-- more people better? teamwork
WITH survey_totals AS (
  SELECT s.survey_id AS id, o.observer_name, 
    --count(s.survey_id),
    sum(sr.total_egg_masses) AS survey_total_masses,
    s.date
  FROM surveys AS s
  JOIN observer_surveys AS os ON s.survey_id = os.survey_id
  JOIN observers AS o ON os.observer_id = o.observer_id
  JOIN survey_results AS sr ON s.survey_id = sr.survey_id
  GROUP BY s.survey_id, o.observer_name, s.date
  ORDER BY s.date
), observer_counts AS (
  SELECT id, date, 
    (sum(survey_total_masses)/count(id))::int AS survey_total_masses, 
    count(id) AS num_observers
  FROM survey_totals
  GROUP BY id, date
  ORDER BY date
)
SELECT round(avg(survey_total_masses), 2) AS avg_masses, 
  num_observers,
  count(id) AS num_surveys,
  sum(survey_total_masses)/count(id) AS masses_per_survey
FROM observer_counts
GROUP BY num_observers
ORDER BY avg_masses DESC;

-- corr
WITH survey_totals AS (
  SELECT s.survey_id AS id, o.observer_name, 
    --count(s.survey_id),
    sum(sr.total_egg_masses) AS survey_total_masses,
    s.date
  FROM surveys AS s
  JOIN observer_surveys AS os ON s.survey_id = os.survey_id
  JOIN observers AS o ON os.observer_id = o.observer_id
  JOIN survey_results AS sr ON s.survey_id = sr.survey_id
  GROUP BY s.survey_id, o.observer_name, s.date
  ORDER BY s.date
), observer_counts AS (
  SELECT id, date, 
    (sum(survey_total_masses)/count(id))::int AS survey_total_masses, 
    count(id) AS num_observers
  FROM survey_totals
  GROUP BY id, date
  ORDER BY date
)
SELECT round(corr(survey_total_masses, num_observers)::numeric, 3) AS num_obs_masses_r
FROM observer_counts;

-- corr if we ignore the three surveys with three people
WITH survey_totals AS (
  SELECT s.survey_id AS id, o.observer_name, 
    --count(s.survey_id),
    sum(sr.total_egg_masses) AS survey_total_masses,
    s.date
  FROM surveys AS s
  JOIN observer_surveys AS os ON s.survey_id = os.survey_id
  JOIN observers AS o ON os.observer_id = o.observer_id
  JOIN survey_results AS sr ON s.survey_id = sr.survey_id
  GROUP BY s.survey_id, o.observer_name, s.date
  ORDER BY s.date
), observer_counts AS (
  SELECT id, date, 
    (sum(survey_total_masses)/count(id))::int AS survey_total_masses, 
    count(id) AS num_observers
  FROM survey_totals
  GROUP BY id, date
  ORDER BY date
)
SELECT 
  round(corr(survey_total_masses, num_observers)::numeric, 3) AS num_obs_under_3_masses_r
FROM observer_counts
WHERE num_observers < 3;

WITH survey_totals AS (
  SELECT s.survey_id AS id, o.observer_name, 
    --count(s.survey_id),
    sum(sr.total_egg_masses) AS survey_total_masses,
    s.date
  FROM surveys AS s
  JOIN observer_surveys AS os ON s.survey_id = os.survey_id
  JOIN observers AS o ON os.observer_id = o.observer_id
  JOIN survey_results AS sr ON s.survey_id = sr.survey_id
  GROUP BY s.survey_id, o.observer_name, s.date
  ORDER BY s.date, o.observer_name
), observer_groups AS (
  SELECT id, date, 
    string_agg(observer_name, ', ') AS observer_list,
    (sum(survey_total_masses)/count(id))::int AS survey_total_masses, 
    count(id) AS num_observers
  FROM survey_totals
  GROUP BY id, date
  ORDER BY date
)
SELECT sum(survey_total_masses) AS sum_masses, 
  count(id) AS num_surveys,
  round(sum(survey_total_masses) / count(id), 1) AS masses_per_survey,
  observer_list
FROM observer_groups
GROUP BY observer_list
ORDER BY masses_per_survey DESC;

WITH survey_totals AS (
  SELECT s.survey_id AS id, o.observer_name, 
    --count(s.survey_id),
    sum(sr.total_egg_masses) AS survey_total_masses,
    s.date
  FROM surveys AS s
  JOIN observer_surveys AS os ON s.survey_id = os.survey_id
  JOIN observers AS o ON os.observer_id = o.observer_id
  JOIN survey_results AS sr ON s.survey_id = sr.survey_id
  GROUP BY s.survey_id, o.observer_name, s.date
  ORDER BY s.date, o.observer_name
)
SELECT id, date, 
  string_agg(observer_name, ', ') AS observer_list,
  (sum(survey_total_masses)/count(id))::int AS survey_total_masses, 
  count(id) AS num_observers
FROM survey_totals
--WHERE observer_name = 'Barnett' OR observer_name = 'Richards'
GROUP BY id, date
ORDER BY observer_list, date;