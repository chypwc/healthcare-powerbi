-- Patient level simulation
CREATE TABLE PatientAdmissions (
    PatientID INT IDENTITY(1,1) PRIMARY KEY,
    HospitalID INT,
    AdmissionDate DATE,
    LengthOfStay DECIMAL(4,2),
    IsReadmission BIT,
    HasInfection BIT,
    DiedInHospital BIT
);


DECLARE @hospitalID INT,
        @date DATE,
        @LengthOfStay DECIMAL(4,2),
        @IsReadmission BIT,
        @HasInfection BIT,
        @DiedInHospital BIT,
        @patientsPerDay INT;

SET @hospitalID = 1;
WHILE @hospitalID <= 10
BEGIN
    SET @date = '2010-01-01';

    WHILE @date <= '2024-12-31'
    BEGIN
        -- Admissions per day ~ Normal(mean=120, sd≈25)
        SET @patientsPerDay = ROUND(
            ( (ABS(CHECKSUM(NEWID())) % 50) +
              (ABS(CHECKSUM(NEWID())) % 50) +
              (ABS(CHECKSUM(NEWID())) % 50) ) / 3.0 + 100, 0
        );

        DECLARE @p INT = 1;
        WHILE @p <= @patientsPerDay
        BEGIN
            -- Length of stay ~ Normal(mean=4.5, sd≈1.5)
            SET @LengthOfStay = ROUND(
                ( (ABS(CHECKSUM(NEWID())) % 3) +
                  (ABS(CHECKSUM(NEWID())) % 3) +
                  (ABS(CHECKSUM(NEWID())) % 3) ) / 3.0 + 3.5, 2
            );

            -- Readmission flag (~10% chance)
            SET @IsReadmission = CASE WHEN ABS(CHECKSUM(NEWID())) % 10 = 0 THEN 1 ELSE 0 END;

            -- Infection flag (~5% chance)
            SET @HasInfection = CASE WHEN ABS(CHECKSUM(NEWID())) % 20 = 0 THEN 1 ELSE 0 END;

            -- Death flag (~2% chance)
            SET @DiedInHospital = CASE WHEN ABS(CHECKSUM(NEWID())) % 50 = 0 THEN 1 ELSE 0 END;

            -- Insert patient record
            INSERT INTO PatientAdmissions
            (HospitalID, AdmissionDate, LengthOfStay, IsReadmission, HasInfection, DiedInHospital)
            VALUES (@hospitalID, @date, @LengthOfStay, @IsReadmission, @HasInfection, @DiedInHospital);

            SET @p = @p + 1;
        END

        SET @date = DATEADD(DAY, 1, @date);
    END

    SET @hospitalID = @hospitalID + 1;
END


---------------------------------------------

drop table if exists dbo.ClinicalData;

-- Create a table for storing clinical data
create table ClinicalData (
    HospitalID int,
    AdmissionDate date,
    TotalAdmissions int,
    Readmissions int,
    Infections int,
    TotalDeaths int,
    AverageLengthOfStay decimal(4,2)
);


INSERT INTO ClinicalData (HospitalID, AdmissionDate, TotalAdmissions, Readmissions, Infections, TotalDeaths, AverageLengthOfStay)
SELECT 
    HospitalID,
    AdmissionDate,
    COUNT(*) AS TotalAdmissions,
    SUM(CASE WHEN IsReadmission = 1 THEN 1 ELSE 0 END) AS Readmissions,
    SUM(CASE WHEN HasInfection = 1 THEN 1 ELSE 0 END) AS Infections,
    SUM(CASE WHEN DiedInHospital = 1 THEN 1 ELSE 0 END) AS TotalDeaths,
    AVG(LengthOfStay) AS AverageLengthOfStay
FROM PatientAdmissions
GROUP BY HospitalID, AdmissionDate
ORDER BY HospitalID, AdmissionDate;
