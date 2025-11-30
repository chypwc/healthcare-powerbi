




create database healthcare

use healthcare

-- Create a  table for storing clinical data
CREATE TABLE ClinicalData (
    HospitalID INT,
    AdmissionDate DATE,
    TotalAdmissions INT,
    Readmissions INT,
    Infections INT,
    TotalDeaths INT,
    AverageLengthOfStay DECIMAL(4,2)
);

DECLARE @hospitalID INT,
        @date DATE,
        @totalAdmissions INT,
        @readmissions INT,
        @infections INT,
        @totalDeaths INT,
        @averageLengthOfStay DECIMAL(4,2),
        @i INT;

-- Loop through 10 hospitals and generate data for each hospital
SET @i = 1;
WHILE @i <= 10
BEGIN
    SET @hospitalID = @i;

    -- Generate data for 2 million records per hospital (20 million total)
    DECLARE @j INT = 1;
    WHILE @j <= 2000000
    BEGIN
        SET @date = DATEADD(DAY, @j, '2024-01-01');  -- Change start date as needed
        SET @totalAdmissions = ABS(CHECKSUM(NEWID())) % 150 + 50; -- Random admissions between 50 and 200
        SET @readmissions = ABS(CHECKSUM(NEWID())) % @totalAdmissions / 10; -- Random readmissions
        SET @infections = ABS(CHECKSUM(NEWID())) % 5; -- Random infections (0-4)
        SET @totalDeaths = ABS(CHECKSUM(NEWID())) % 3; -- Random deaths (0-2)
        SET @averageLengthOfStay = ROUND((ABS(CHECKSUM(NEWID())) % 7 + 1) * 1.0, 2); -- Random length of stay (1-7 days)

        -- Insert data into the temporary table
        INSERT INTO ClinicalData (HospitalID, AdmissionDate, TotalAdmissions, Readmissions, Infections, TotalDeaths, AverageLengthOfStay)
        VALUES (@hospitalID, @date, @totalAdmissions, @readmissions, @infections, @totalDeaths, @averageLengthOfStay);

        SET @j = @j + 1;
    END

    SET @i = @i + 1;
END

-- Query to verify the generated data
SELECT top 10 * FROM ClinicalData;

-- Count total records
SELECT COUNT(*) AS TotalRecords FROM ClinicalData;


