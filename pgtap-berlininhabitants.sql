-- pg_prove -U YOURUSER -d berlindata pgtap-berlininhabitants.sql --verbose
-- psql -U YOURUSER -h YOURHOST -d berlindata -Xf pgtap-berlininhabitants.sql

BEGIN;

SELECT plan(19);

SELECT has_table('inhabitants');

SELECT has_column('inhabitants', 'official_district');
SELECT has_column('inhabitants', 'district');
SELECT has_column('inhabitants', 'gender');
SELECT has_column('inhabitants', 'nationality');
SELECT has_column('inhabitants', 'age_low');
SELECT has_column('inhabitants', 'age_high');
SELECT has_column('inhabitants', 'quantity');


-- list by how many inhabitants all in all
PREPARE by_district AS 
  SELECT 
    district, sum(quantity) 
  FROM 
    inhabitants 
  GROUP BY 
    district 
  ORDER BY 
    sum 
  DESC LIMIT 3;

SELECT results_eq(
    'by_district',
    $$VALUES('Neukölln'::varchar, 158429::bigint), 
            ('Prenzlauer Berg'::varchar, 148878::bigint), 
            ('Kreuzberg'::varchar, 147532::bigint)$$,
    'should return the three districts with most inhabitants'
);

-- list by how many women per district
PREPARE by_women AS
  SELECT 
    district, sum(quantity) 
  FROM 
    inhabitants 
  WHERE 
    gender = 'f' 
  GROUP BY 
    district 
  ORDER BY 
    sum(quantity) 
  DESC LIMIT 3;

SELECT results_eq(
    'by_women',
    $$VALUES('Neukölln'::varchar, 76988::bigint), 
            ('Prenzlauer Berg'::varchar, 74558::bigint), 
            ('Kreuzberg'::varchar, 72357::bigint)$$,
    'should return the three districts with most women'
);

-- list by how many children per district pre-school (0-5)
PREPARE by_preschool_children AS
  SELECT 
    district, sum(quantity) 
  FROM 
    inhabitants 
  WHERE 
    age_high = '5' 
  GROUP BY 
    district 
  ORDER BY 
    sum 
  DESC LIMIT 3;

SELECT results_eq(
    'by_preschool_children',
    $$VALUES('Prenzlauer Berg'::varchar, 9406::bigint), 
            ('Neukölln'::varchar, 9056::bigint), 
            ('Kreuzberg'::varchar, 8053::bigint)$$,
    'should return the three districts with most pre-school children'
);

-- list by how many children per district 0-10 years old
PREPARE by_older_children AS
  SELECT 
    district, sum(quantity) 
  FROM 
    inhabitants 
  WHERE
    age_low = '0' or age_high = '10' 
  GROUP BY
    district 
  ORDER BY
    sum 
  DESC LIMIT 3;

SELECT results_eq(
    'by_older_children',
    $$VALUES('Neukölln'::varchar, 16186::bigint), 
            ('Prenzlauer Berg'::varchar, 15693::bigint), 
            ('Kreuzberg'::varchar, 14788::bigint)$$,
    'should return the three districts with most children between born and 10 yrs old'
);

-- list number of inhabitants without german nationality
PREPARE by_immigrants AS 
  SELECT
    district, sum(quantity) 
  FROM 
    inhabitants 
  WHERE
    nationality = 'A'
  GROUP BY 
    district 
  ORDER BY 
    sum 
  DESC LIMIT 3;

SELECT results_eq(
    'by_immigrants',
    $$VALUES('Neukölln'::varchar, 51055::bigint), 
            ('Kreuzberg'::varchar, 42204::bigint), 
            ('Gesundbrunnen'::varchar, 29088::bigint)$$,
    'should return the three districts with most immigrants'
);

-- due to Ius Sanguinis same goes for children:
PREPARE by_immigrant_children AS
  SELECT 
    district, sum(quantity) 
  FROM 
    inhabitants 
  WHERE 
    nationality = 'A' and age_high = '5' 
  GROUP BY 
    district 
  ORDER BY 
    sum 
  DESC LIMIT 3;

SELECT results_eq(
    'by_immigrant_children',
    $$VALUES('Neukölln'::varchar, 1672::bigint), 
            ('Gesundbrunnen'::varchar, 1056::bigint), 
            ('Wedding'::varchar, 650::bigint)$$,
    'should return the three districts with most immigrant children'
);


-- list in what district live the most old women
PREPARE by_oldest_women AS 
  SELECT 
    district, sum(quantity) 
  FROM 
    inhabitants 
  WHERE 
    age_low = '95' and gender = 'f' 
  GROUP BY 
    district 
  ORDER BY 
    sum 
  DESC LIMIT 3;

SELECT results_eq(
    'by_oldest_women',
    $$VALUES('Charlottenburg'::varchar, 231::bigint), 
            ('Schöneberg'::varchar, 216::bigint), 
            ('Lichterfelde'::varchar, 195::bigint)$$,
    'should return the three districts WHERE the most women over 95 live'
);


-- list female percentages for every district:
PREPARE by_female_percent AS 
  SELECT 
    district, to_char( cast( 
      sum(case when gender = 'f' then quantity end) AS decimal) / sum(quantity)*100, 'FM990D99')
    AS percent, sum(quantity) 
  FROM 
    inhabitants 
  GROUP BY 
    district 
  ORDER BY 
    percent 
  DESC LIMIT 3;

SELECT results_eq(
    'by_female_percent',
    $$VALUES('Schmargendorf'::varchar, '55.3'::text, 20262::bigint), 
            ('Zehlendorf'::varchar, '54.5'::text, 58469::bigint), 
            ('Friedrichshagen'::varchar, '53.84'::text, 17529::bigint)$$,
    'should return the three districts WHERE the highest percent of women over 95 live'
);

-- is indeed Prenzlauer Berg the district with the most children implying AS many parents AS well?
-- absolute numbers say yes - more than in Neukölln - but in
-- percentages?
PREPARE by_children_percent_district AS
  SELECT 
    district, to_char( cast(
        sum(case when age_high = '5' then quantity end) AS decimal)/sum(quantity)*100, 'FM990D99')    AS percent, sum(quantity) 
  FROM 
    inhabitants 
  GROUP BY 
    district 
  ORDER BY 
    percent 
  DESC LIMIT 3;

SELECT results_eq(
    'by_children_percent_district',
    $$VALUES('Rummelsburg'::varchar, '6.58'::text, 20414::bigint), 
            ('Gesundbrunnen'::varchar, '6.38'::text, 84789::bigint), 
            ('Prenzlauer Berg'::varchar, '6.32'::text, 148878::bigint)$$,
    'should return the three districts WHERE the highest percent of pre-school children live'
);

-- is indeed Prenzlauer Berg the district with the most children implying AS many parents AS well?
-- if we go by "official districts", then Pankow wins (Prenzlauer Berg is part of Pankow)
PREPARE by_children_percent_official_district AS
  SELECT 
    official_district, to_char( cast( 
        sum(case when age_high = '5' then quantity end) AS decimal)/sum(quantity)*100, 'FM990D99')    AS percent, sum(quantity) 
  FROM 
    inhabitants 
  GROUP BY 
    official_district 
  ORDER BY 
    percent 
  DESC LIMIT 3;

SELECT results_eq(
    'by_children_percent_official_district',
    $$VALUES('Pankow'::varchar, '5.67'::text, 365021::bigint), 
            ('Friedrichshain-Kreuzberg'::varchar, '5.34'::text, 265361::bigint), 
            ('Mitte'::varchar, '5.21'::text, 333152::bigint)$$,
    'should return the three official districts WHERE the highest percent of pre-school children live'
);

-- list districts by their ratio of men to women
-- secondary sex ratio is 1.01 men/women worldwide
PREPARE by_sex_ratio AS
  SELECT 
    district, to_char(
      cast( sum(case when gender = 'm' then quantity end) AS decimal) / 
      cast( sum(case when gender = 'f' then quantity end) AS decimal), 'FM990D99') 
    AS ratio, sum(quantity)
  FROM 
    inhabitants 
  GROUP BY 
    district 
  ORDER BY 
    ratio 
  DESC LIMIT 3;

SELECT results_eq(
    'by_sex_ratio',
    $$VALUES('Malchow'::varchar, '1.18'::text, 508::bigint), -- even worse than China
            ('Tiergarten'::varchar, '1.14'::text, 12328::bigint), 
            ('Rummelsburg'::varchar, '1.1'::text, 20414::bigint)$$, -- single dad district?
    'should return the three odistricts with the highest male-to-female ratio'
);

SELECT * FROM finish();
ROLLBACK;
