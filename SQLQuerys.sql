-- Creamos base de datos
DROP DATABASE IF EXISTS LA_climate;
CREATE DATABASE LA_climate;

USE LA_climate;

-- Creamos las tablas correspondientes a los csv que tenemos

DROP TABLE IF EXISTS LA_daily_climate;
CREATE TABLE LA_daily_climate(
	Country VARCHAR(60) NOT NULL,
	City VARCHAR(60),
	Measure_date DATE NOT NULL,
	Latitude FLOAT,
	Longitude FLOAT,
	Temperature_2m_max FLOAT,
	Temperature_2m_min FLOAT,
	Temperature_2m_mean FLOAT,
	Apparent_temperature_max FLOAT,
	Apparent_temperature_min FLOAT,
	Apparent_temperature_mean FLOAT,
	Precipitation_sum DECIMAL(5,1),
	wind_speed_10m_max FLOAT,
	et0_fao_evapotranspiration FLOAT
);

DROP TABLE IF EXISTS LA_daily_air_quality;
CREATE TABLE LA_daily_air_quality(
	Measure_date DATE,
	Latitude FLOAT,
	Longitude FLOAT,
	Pm10 DECIMAL(10,1),
	Pm2_5 DECIMAL(10,1),
	Carbon_monoxide DECIMAL(10,1),
	Nitrogen_dioxide DECIMAL(10,1),
	Sulphur_dioxide DECIMAL(10,1),
	Ozone DECIMAL(10,1)
);

-- Poblamos las tablas con los csv

BULK INSERT LA_daily_air_quality
FROM 'C:\Users\the_n\Desktop\Javier\Coderhouse\Proyecto\LA_daily_air_quality.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',  --CSV field delimiter
    ROWTERMINATOR = '\n',   --Use to shift the control to next row
    TABLOCK
)

BULK INSERT LA_daily_climate
FROM 'C:\Users\the_n\Desktop\Javier\Coderhouse\Proyecto\LA_daily_climate.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',  --CSV field delimiter
    ROWTERMINATOR = '\n',   --Use to shift the control to next row
    TABLOCK
)

-- Se borran los registros que tienen los datos relevantes nulos

DELETE FROM LA_daily_air_quality
WHERE Pm10 IS NULL AND Pm2_5 IS NULL AND Carbon_monoxide IS NULL AND
	Nitrogen_dioxide IS NULL AND Sulphur_dioxide IS NULL AND Ozone IS NULL;

-- Le agregamos una columna que va a ser la primary key de la tabla

ALTER TABLE [dbo].[LA_daily_air_quality]
ADD Id_measure INT IDENTITY(1,1) NOT NULL;

ALTER TABLE [dbo].[LA_daily_climate]
ADD Id_measure INT IDENTITY(1,1) NOT NULL;


-- Creaamos las tablas con las que vamos a normalizar la base de datos

DROP TABLE IF EXISTS City;
CREATE TABLE City(
Id_city INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
City VARCHAR(60) NOT NULL,
Country VARCHAR(60) NOT NULL,
Latitude FLOAT,
Longitude FLOAT
);

DROP TABLE IF EXISTS Country;
CREATE TABLE Country(
Id_country INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
Country VARCHAR(60)
);

-- Insertamos en las tablas los valores correspondientes

INSERT INTO City (City, Country, Latitude, Longitude)
SELECT DISTINCT City, Country, Latitude, Longitude FROM LA_daily_climate;

INSERT INTO Country (Country)
SELECT DISTINCT Country FROM City;

--Agregamos la nueva columna que va a tener la correspondencia de cada país con su ID de la tabla Country y la llenamos con un join

ALTER TABLE City
ADD Id_country INT;

UPDATE City 
SET City.Id_country = co.Id_country
FROM City ci
JOIN Country co ON co.Country=ci.Country;

-- Establecemos la FK y borramos la columna Country

ALTER TABLE City
ADD CONSTRAINT City_countryFK FOREIGN KEY (Id_country) REFERENCES Country (Id_country);

ALTER TABLE City
DROP COLUMN Country;

-- Realizamos lo mismo con las tablas principales, primero daily climate

ALTER TABLE LA_daily_climate
ADD Id_city INT;

UPDATE LA_daily_climate
SET LA_daily_climate.Id_city = c.Id_city
FROM LA_daily_climate lc
JOIN City c ON c.City=lc.City;

ALTER TABLE LA_daily_climate
ADD CONSTRAINT climate_cityFK FOREIGN KEY (Id_city) REFERENCES City (Id_city);

ALTER TABLE LA_daily_climate
DROP COLUMN Country, City, Latitude, Longitude;

-- Ahora daily air quality

ALTER TABLE LA_daily_air_quality
ADD Id_city INT;

UPDATE LA_daily_air_quality
SET LA_daily_air_quality.Id_city = c.Id_city
FROM LA_daily_air_quality la
JOIN City c ON c.Latitude=la.Latitude;

ALTER TABLE LA_daily_air_quality
ADD CONSTRAINT air_cityFK FOREIGN KEY (Id_city) REFERENCES City (Id_city);

ALTER TABLE LA_daily_air_quality
DROP COLUMN Latitude, Longitude;

-- Establecemos las primary key en las tablas de hechos

ALTER TABLE LA_daily_climate
ADD PRIMARY KEY (Id_measure);

ALTER TABLE LA_daily_air_quality
ADD PRIMARY KEY (Id_measure);