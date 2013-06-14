-- createdb berlindata
-- psql berlindata -U postgres < pg-berlindemographics.sql

CREATE TABLE inhabitants (
  id SERIAL NOT NULL,
  official_district VARCHAR(100) NOT NULL,
  district VARCHAR(100) NOT NULL,
  gender VARCHAR(1) NOT NULL,
  nationality VARCHAR(100) NOT NULL,
  age_low SMALLINT NOT NULL,
  age_high SMALLINT NOT NULL,
  quantity INTEGER NOT NULL,
  PRIMARY KEY (id)
);


