--schema.sql--
-- Create the AFM database if it doesn't already exist
DO
$do$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'AFM') THEN
      PERFORM dblink_exec('dbname=postgres', 'CREATE DATABASE AFM');
   END IF;
END
$do$;

-- Switch to the AFM database
\c AFM;
-- -- THIS IS THE CLEANUP plz keep me here
-- DO $$ DECLARE
--     r RECORD;
-- BEGIN
--     FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
--         EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
--     END LOOP;
-- END $$;


-- Table for Water Levels --> created based on the possible attributes that can be found in the second link
DROP TABLE IF EXISTS Water_Levels;

-- Create a simple Water_Levels table for testing
CREATE TABLE Water_Levels (
    id SERIAL PRIMARY KEY,  -- Primary key expected by Django
    location_id INTEGER,
    value_at_time NUMERIC(10, 2),
    unit VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS FloodReport;

-- Create the FloodReport table to store flood report information
CREATE TABLE FloodReport (
    ID SERIAL PRIMARY KEY, -- Unique identifier for each report
    Location TEXT NOT NULL, -- Location of the flood (to be generated by the backend for now)
    AssociatedEmail VARCHAR(255) NOT NULL, -- Email of the person submitting the report (mandatory)
    AssociatedPhoneNumber VARCHAR(15), -- Optional phone number of the submitter
    AssociatedUserID INT, -- Optional user ID for registered users (can be NULL for anonymous reports)
    Description TEXT, -- Optional description of the flood situation
    LinkToPicture TEXT, -- Optional link to an uploaded picture of the flood
    Severity VARCHAR(50) NOT NULL CHECK (Severity IN ('low', 'medium', 'high', 'catastrophical')), -- Severity of the flood (mandatory)
    Verified INTEGER NOT NULL DEFAULT 0 CHECK (Verified IN (0, 1, 2)) -- 0: Unverified, 1: Verified, 2: Rejected
);

CREATE TABLE EmergencyResponse (
    ID SERIAL PRIMARY KEY,
    Status VARCHAR(50) NOT NULL DEFAULT 'Planning', -- Default status is "Planning"
    ReportID INT NOT NULL REFERENCES FloodReport(ID) ON DELETE CASCADE -- Foreign key to link reports
);



-- Table for Locations
-- CREATE TABLE IF NOT EXISTS Locations (
--     location_id SERIAL PRIMARY KEY,
--     dbmsnr INTEGER UNIQUE, -- Internal database number
--     hzbnr INTEGER UNIQUE, -- Measuring point number of the hydrographic service
--     water_body_name VARCHAR(255), -- water body name
--     mp_operator VARCHAR(255), -- Operator of the measuring point
--     lat NUMERIC(2, 6), -- up to 9 digits and up to 6 decimal places --> Y coordinates
--     lon NUMERIC(3, 6), -- X coordinates
--     internet TEXT, -- Direct link to the measuring point on the operator's website
--     country TEXT DEFAULT "Austria", -- Country information for measuring points outside Austria
--     -- Do we even need the "country" attribute??
--     mp_geometry GEOMETRY(Polygon, 4326), -- mp stands for measuring point (MAYBE NEED TO USE: mp_geometry POLYGON)
--     -- Geometry as Polygon, using SRID 4326 for WGS84
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );



-- CREATE TABLE IF NOT EXISTS Water_Level_History (
--     entry_id SERIAL PRIMARY KEY,
--     location_id INTEGER REFERENCES Locations(location_id) ON DELETE CASCADE,  -- Links to location if applicable
--     category_label VARCHAR(255),           -- Category label (e.g., CRS or projection system)
--     category_term TEXT,                    -- Category term (e.g., EPSG code)
--     title TEXT,                            -- Title of the dataset
--     summary TEXT,                          -- Summary of dataset description (german...)
--     last_updated TIMESTAMP,                -- Timestamp of last dataset update
--     geom GEOMETRY(POLYGON, 4326),          -- Polygon coordinates (stored as GEOMETRY type for spatial use)
--     hq30 GEOMETRY(POLYGON, 4326),          -- HQ30 (30-year flood value), as an example value
--     all_time_high NUMERIC(10, 2),          -- All-time high water level
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );


-- Table for Water Levels
CREATE TABLE IF NOT EXISTS Users (
    user_id SERIAL PRIMARY KEY,                     -- Unique identifier for each user
    email VARCHAR(255) UNIQUE NOT NULL,             -- Email address, unique and required
    hashed_passw VARCHAR(255) NOT NULL,             -- Hashed password (255 to accommodate long hashes)
    phone_num VARCHAR(15),                          -- Phone number (optional, allows for country codes)
    user_address TEXT,                              -- User's address (text for flexibility in length, can use VARCHAR(255) if needed)
    perm_level int DEFAULT 1 CHECK (perm_level IN (0,1,2,3,4)),        -- Permission level (right now it can be user or admin)
    -- 0: Guest; 1: User; 2: Moderator; 3: Emergency Service; 4: Admin
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      -- Timestamp of user creation --> may be used for statistics (if not, it can be easily deleted)
    last_rejected_on TIMESTAMP,
    ESRejected BOOLEAN DEFAULT FALSE
);



-- Create PromotionRequests table if it doesn't exist
CREATE TABLE IF NOT EXISTS PromotionRequests (
    request_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES Users(user_id),
    requested_role INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    rejected_on TIMESTAMP,
    type VARCHAR(20) CHECK (type IN ('Moderator', 'Emergency Service'))
);


-- Insert a default admin user
Insert into Users (email, hashed_passw, perm_level) 
values ('admin@example.com', 'pbkdf2:sha256:1000000$p05Dwd3ap9ogMdkI$7f4e1fcba3da1beec50f690cc57047c4ee81afde904dadb0632a534ed555e3d2', 4)

-- Log a message to indicate that the schema.sql file has finished executing
\echo 'Finished executing schema.sql'