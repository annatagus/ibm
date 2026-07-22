/*=============================================================================
 PROJETO AIDAPT-04
 IBM HR Analytics Employee Attrition & Performance
 SQL SERVER — VERSÃO SIMPLIFICADA

 ÂMBITO DESTE FICHEIRO
 - Usa apenas o dataset IBM original.
 - Usa apenas a primeira pesquisa de satisfação incluída no dataset.
 - Não inclui a segunda survey realizada após a mesa de ping-pong.
 - Não tenta criar evolução temporal, porque existe apenas um snapshot.

 ORDEM DO TRABALHO
 1. Carregamento dos dados para o SQL Server
 2. Validação dos dados carregados
 3. Normalização até à 3.ª Forma Normal
 4. Criação de views
 5. Estudo da informação e resposta às perguntas da entrevista
=============================================================================*/


/*=============================================================================
 0. CRIAÇÃO DA BASE DE DADOS
=============================================================================*/

IF DB_ID(N'IBM_HR_Analytics') IS NULL
BEGIN
    CREATE DATABASE IBM_HR_Analytics;
END;
GO

USE IBM_HR_Analytics;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'stg')
    EXEC('CREATE SCHEMA stg');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'hr')
    EXEC('CREATE SCHEMA hr');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'bi')
    EXEC('CREATE SCHEMA bi');
GO


/*=============================================================================
 1. CARREGAMENTO DOS DADOS PARA O SQL SERVER
=============================================================================*/

/*
 A tabela staging mantém o dataset exatamente como foi recebido.

 As colunas constantes:
 - EmployeeCount
 - Over18
 - StandardHours

 são carregadas para permitir a validação, mas não serão levadas para o
 modelo normalizado porque não acrescentam informação analítica.
*/

IF OBJECT_ID(N'stg.EmployeeRaw', N'U') IS NULL
BEGIN
    CREATE TABLE stg.EmployeeRaw
    (
        Age                         TINYINT,
        Attrition                   VARCHAR(3),
        BusinessTravel              VARCHAR(30),
        DailyRate                   INT,
        Department                  VARCHAR(50),
        DistanceFromHome            TINYINT,
        Education                   TINYINT,
        EducationField              VARCHAR(50),
        EmployeeCount               TINYINT,
        EmployeeNumber              INT,
        EnvironmentSatisfaction     TINYINT,
        Gender                      VARCHAR(10),
        HourlyRate                  INT,
        JobInvolvement              TINYINT,
        JobLevel                    TINYINT,
        JobRole                     VARCHAR(60),
        JobSatisfaction             TINYINT,
        MaritalStatus               VARCHAR(20),
        MonthlyIncome               INT,
        MonthlyRate                 INT,
        NumCompaniesWorked          TINYINT,
        Over18                      CHAR(1),
        OverTime                    VARCHAR(3),
        PercentSalaryHike           TINYINT,
        PerformanceRating           TINYINT,
        RelationshipSatisfaction    TINYINT,
        StandardHours               TINYINT,
        StockOptionLevel            TINYINT,
        TotalWorkingYears           TINYINT,
        TrainingTimesLastYear       TINYINT,
        WorkLifeBalance             TINYINT,
        YearsAtCompany              TINYINT,
        YearsInCurrentRole          TINYINT,
        YearsSinceLastPromotion     TINYINT,
        YearsWithCurrManager        TINYINT
    );
END;
GO


/*-----------------------------------------------------------------------------
 IMPORTAÇÃO RECOMENDADA

 No SQL Server Management Studio:

 1. Clicar com o botão direito na base IBM_HR_Analytics.
 2. Tasks.
 3. Import Flat File.
 4. Selecionar o ficheiro:
    WA_Fn-UseC_-HR-Employee-Attrition.csv
 5. Escolher stg.EmployeeRaw como tabela de destino.
 6. Confirmar que a primeira linha é o cabeçalho.
 7. Confirmar os tipos de dados.
 8. Concluir a importação.

 Depois da importação, executar a validação abaixo.
-------------------------------------------------------------------------------*/


/*=============================================================================
 2. VALIDAÇÃO DOS DADOS CARREGADOS
=============================================================================*/

-- 2.1 Total de linhas e colaboradores diferentes
SELECT
    COUNT(*) AS TotalLinhas,
    COUNT(DISTINCT EmployeeNumber) AS ColaboradoresDiferentes
FROM stg.EmployeeRaw;
GO


-- 2.2 Verificar identificadores duplicados
SELECT
    EmployeeNumber,
    COUNT(*) AS Quantidade
FROM stg.EmployeeRaw
GROUP BY EmployeeNumber
HAVING COUNT(*) > 1;
GO


-- 2.3 Verificar EmployeeNumber nulo
SELECT *
FROM stg.EmployeeRaw
WHERE EmployeeNumber IS NULL;
GO


-- 2.4 Verificar valores nulos nas colunas principais
SELECT
    SUM(CASE WHEN Age IS NULL THEN 1 ELSE 0 END) AS IdadeNula,
    SUM(CASE WHEN Gender IS NULL THEN 1 ELSE 0 END) AS GeneroNulo,
    SUM(CASE WHEN Department IS NULL THEN 1 ELSE 0 END) AS DepartamentoNulo,
    SUM(CASE WHEN JobRole IS NULL THEN 1 ELSE 0 END) AS CargoNulo,
    SUM(CASE WHEN MonthlyIncome IS NULL THEN 1 ELSE 0 END) AS SalarioNulo,
    SUM(CASE WHEN Attrition IS NULL THEN 1 ELSE 0 END) AS AttritionNulo
FROM stg.EmployeeRaw;
GO


-- 2.5 Validar categorias principais
SELECT DISTINCT Gender FROM stg.EmployeeRaw;
SELECT DISTINCT MaritalStatus FROM stg.EmployeeRaw;
SELECT DISTINCT Department FROM stg.EmployeeRaw;
SELECT DISTINCT BusinessTravel FROM stg.EmployeeRaw;
SELECT DISTINCT Attrition FROM stg.EmployeeRaw;
SELECT DISTINCT OverTime FROM stg.EmployeeRaw;
GO


-- 2.6 Validar escalas de 1 a 4
SELECT *
FROM stg.EmployeeRaw
WHERE EnvironmentSatisfaction NOT BETWEEN 1 AND 4
   OR JobInvolvement NOT BETWEEN 1 AND 4
   OR JobSatisfaction NOT BETWEEN 1 AND 4
   OR RelationshipSatisfaction NOT BETWEEN 1 AND 4
   OR WorkLifeBalance NOT BETWEEN 1 AND 4;
GO


-- 2.7 Validar idade, nível do cargo e educação
SELECT *
FROM stg.EmployeeRaw
WHERE Age NOT BETWEEN 18 AND 100
   OR JobLevel NOT BETWEEN 1 AND 5
   OR Education NOT BETWEEN 1 AND 5;
GO


-- 2.8 Confirmar que as colunas são constantes
SELECT
    MIN(EmployeeCount) AS EmployeeCountMin,
    MAX(EmployeeCount) AS EmployeeCountMax,
    MIN(Over18) AS Over18Min,
    MAX(Over18) AS Over18Max,
    MIN(StandardHours) AS StandardHoursMin,
    MAX(StandardHours) AS StandardHoursMax
FROM stg.EmployeeRaw;
GO


/*=============================================================================
 3. NORMALIZAÇÃO ATÉ À 3.ª FORMA NORMAL
=============================================================================*/

/*
 O dataset original contém tudo numa única tabela.

 A normalização separa:
 - valores de referência;
 - dados pessoais;
 - situação profissional;
 - remuneração;
 - carreira;
 - primeira pesquisa de satisfação.

 EmployeeNumber é a ligação entre as tabelas do colaborador.
*/


/*-----------------------------------------------------------------------------
 3.1 Tabelas de referência
-------------------------------------------------------------------------------*/

IF OBJECT_ID(N'hr.Gender', N'U') IS NULL
BEGIN
    CREATE TABLE hr.Gender
    (
        GenderID      TINYINT IDENTITY(1,1) PRIMARY KEY,
        GenderName    VARCHAR(10) NOT NULL UNIQUE
    );
END;
GO


IF OBJECT_ID(N'hr.MaritalStatus', N'U') IS NULL
BEGIN
    CREATE TABLE hr.MaritalStatus
    (
        MaritalStatusID      TINYINT IDENTITY(1,1) PRIMARY KEY,
        MaritalStatusName    VARCHAR(20) NOT NULL UNIQUE
    );
END;
GO


IF OBJECT_ID(N'hr.Department', N'U') IS NULL
BEGIN
    CREATE TABLE hr.Department
    (
        DepartmentID      TINYINT IDENTITY(1,1) PRIMARY KEY,
        DepartmentName    VARCHAR(50) NOT NULL UNIQUE
    );
END;
GO


IF OBJECT_ID(N'hr.JobRole', N'U') IS NULL
BEGIN
    CREATE TABLE hr.JobRole
    (
        JobRoleID      SMALLINT IDENTITY(1,1) PRIMARY KEY,
        JobRoleName    VARCHAR(60) NOT NULL UNIQUE
    );
END;
GO


IF OBJECT_ID(N'hr.BusinessTravel', N'U') IS NULL
BEGIN
    CREATE TABLE hr.BusinessTravel
    (
        BusinessTravelID      TINYINT IDENTITY(1,1) PRIMARY KEY,
        BusinessTravelName    VARCHAR(30) NOT NULL UNIQUE
    );
END;
GO


IF OBJECT_ID(N'hr.EducationField', N'U') IS NULL
BEGIN
    CREATE TABLE hr.EducationField
    (
        EducationFieldID      SMALLINT IDENTITY(1,1) PRIMARY KEY,
        EducationFieldName    VARCHAR(50) NOT NULL UNIQUE
    );
END;
GO


IF OBJECT_ID(N'hr.EducationLevel', N'U') IS NULL
BEGIN
    CREATE TABLE hr.EducationLevel
    (
        EducationLevelID       TINYINT PRIMARY KEY,
        EducationLevelName     VARCHAR(30) NOT NULL UNIQUE,

        CONSTRAINT CK_EducationLevel
            CHECK (EducationLevelID BETWEEN 1 AND 5)
    );
END;
GO


/*-----------------------------------------------------------------------------
 3.2 Tabelas principais normalizadas
-------------------------------------------------------------------------------*/

IF OBJECT_ID(N'hr.Employee', N'U') IS NULL
BEGIN
    CREATE TABLE hr.Employee
    (
        EmployeeNumber       INT PRIMARY KEY,
        Age                  TINYINT NOT NULL,
        GenderID             TINYINT NOT NULL,
        MaritalStatusID      TINYINT NOT NULL,
        DistanceFromHome     TINYINT NOT NULL,
        EducationLevelID     TINYINT NOT NULL,
        EducationFieldID     SMALLINT NOT NULL,

        CONSTRAINT FK_Employee_Gender
            FOREIGN KEY (GenderID) REFERENCES hr.Gender(GenderID),

        CONSTRAINT FK_Employee_MaritalStatus
            FOREIGN KEY (MaritalStatusID)
            REFERENCES hr.MaritalStatus(MaritalStatusID),

        CONSTRAINT FK_Employee_EducationLevel
            FOREIGN KEY (EducationLevelID)
            REFERENCES hr.EducationLevel(EducationLevelID),

        CONSTRAINT FK_Employee_EducationField
            FOREIGN KEY (EducationFieldID)
            REFERENCES hr.EducationField(EducationFieldID),

        CONSTRAINT CK_Employee_Age
            CHECK (Age BETWEEN 18 AND 100)
    );
END;
GO


IF OBJECT_ID(N'hr.Employment', N'U') IS NULL
BEGIN
    CREATE TABLE hr.Employment
    (
        EmployeeNumber       INT PRIMARY KEY,
        DepartmentID         TINYINT NOT NULL,
        JobRoleID            SMALLINT NOT NULL,
        JobLevel             TINYINT NOT NULL,
        BusinessTravelID     TINYINT NOT NULL,
        OverTimeFlag         BIT NOT NULL,
        AttritionFlag        BIT NOT NULL,

        CONSTRAINT FK_Employment_Employee
            FOREIGN KEY (EmployeeNumber)
            REFERENCES hr.Employee(EmployeeNumber),

        CONSTRAINT FK_Employment_Department
            FOREIGN KEY (DepartmentID)
            REFERENCES hr.Department(DepartmentID),

        CONSTRAINT FK_Employment_JobRole
            FOREIGN KEY (JobRoleID)
            REFERENCES hr.JobRole(JobRoleID),

        CONSTRAINT FK_Employment_BusinessTravel
            FOREIGN KEY (BusinessTravelID)
            REFERENCES hr.BusinessTravel(BusinessTravelID),

        CONSTRAINT CK_Employment_JobLevel
            CHECK (JobLevel BETWEEN 1 AND 5)
    );
END;
GO


IF OBJECT_ID(N'hr.Compensation', N'U') IS NULL
BEGIN
    CREATE TABLE hr.Compensation
    (
        EmployeeNumber       INT PRIMARY KEY,
        DailyRate            INT NOT NULL,
        HourlyRate           INT NOT NULL,
        MonthlyIncome        INT NOT NULL,
        MonthlyRate          INT NOT NULL,
        PercentSalaryHike    TINYINT NOT NULL,
        PerformanceRating    TINYINT NOT NULL,
        StockOptionLevel     TINYINT NOT NULL,

        CONSTRAINT FK_Compensation_Employee
            FOREIGN KEY (EmployeeNumber)
            REFERENCES hr.Employee(EmployeeNumber)
    );
END;
GO


IF OBJECT_ID(N'hr.Career', N'U') IS NULL
BEGIN
    CREATE TABLE hr.Career
    (
        EmployeeNumber              INT PRIMARY KEY,
        NumCompaniesWorked          TINYINT NOT NULL,
        TotalWorkingYears           TINYINT NOT NULL,
        TrainingTimesLastYear       TINYINT NOT NULL,
        YearsAtCompany              TINYINT NOT NULL,
        YearsInCurrentRole          TINYINT NOT NULL,
        YearsSinceLastPromotion     TINYINT NOT NULL,
        YearsWithCurrManager        TINYINT NOT NULL,

        CONSTRAINT FK_Career_Employee
            FOREIGN KEY (EmployeeNumber)
            REFERENCES hr.Employee(EmployeeNumber)
    );
END;
GO


IF OBJECT_ID(N'hr.SatisfactionSurvey', N'U') IS NULL
BEGIN
    CREATE TABLE hr.SatisfactionSurvey
    (
        EmployeeNumber               INT PRIMARY KEY,
        EnvironmentSatisfaction      TINYINT NOT NULL,
        JobInvolvement               TINYINT NOT NULL,
        JobSatisfaction              TINYINT NOT NULL,
        RelationshipSatisfaction     TINYINT NOT NULL,
        WorkLifeBalance              TINYINT NOT NULL,

        CONSTRAINT FK_Satisfaction_Employee
            FOREIGN KEY (EmployeeNumber)
            REFERENCES hr.Employee(EmployeeNumber),

        CONSTRAINT CK_Satisfaction_Environment
            CHECK (EnvironmentSatisfaction BETWEEN 1 AND 4),

        CONSTRAINT CK_Satisfaction_Involvement
            CHECK (JobInvolvement BETWEEN 1 AND 4),

        CONSTRAINT CK_Satisfaction_Job
            CHECK (JobSatisfaction BETWEEN 1 AND 4),

        CONSTRAINT CK_Satisfaction_Relationship
            CHECK (RelationshipSatisfaction BETWEEN 1 AND 4),

        CONSTRAINT CK_Satisfaction_WorkLife
            CHECK (WorkLifeBalance BETWEEN 1 AND 4)
    );
END;
GO


/*-----------------------------------------------------------------------------
 3.3 Carregamento das tabelas de referência
-------------------------------------------------------------------------------*/

INSERT INTO hr.Gender (GenderName)
SELECT DISTINCT Gender
FROM stg.EmployeeRaw s
WHERE Gender IS NOT NULL
  AND NOT EXISTS
      (
          SELECT 1
          FROM hr.Gender g
          WHERE g.GenderName = s.Gender
      );
GO


INSERT INTO hr.MaritalStatus (MaritalStatusName)
SELECT DISTINCT MaritalStatus
FROM stg.EmployeeRaw s
WHERE MaritalStatus IS NOT NULL
  AND NOT EXISTS
      (
          SELECT 1
          FROM hr.MaritalStatus m
          WHERE m.MaritalStatusName = s.MaritalStatus
      );
GO


INSERT INTO hr.Department (DepartmentName)
SELECT DISTINCT Department
FROM stg.EmployeeRaw s
WHERE Department IS NOT NULL
  AND NOT EXISTS
      (
          SELECT 1
          FROM hr.Department d
          WHERE d.DepartmentName = s.Department
      );
GO


INSERT INTO hr.JobRole (JobRoleName)
SELECT DISTINCT JobRole
FROM stg.EmployeeRaw s
WHERE JobRole IS NOT NULL
  AND NOT EXISTS
      (
          SELECT 1
          FROM hr.JobRole j
          WHERE j.JobRoleName = s.JobRole
      );
GO


INSERT INTO hr.BusinessTravel (BusinessTravelName)
SELECT DISTINCT BusinessTravel
FROM stg.EmployeeRaw s
WHERE BusinessTravel IS NOT NULL
  AND NOT EXISTS
      (
          SELECT 1
          FROM hr.BusinessTravel b
          WHERE b.BusinessTravelName = s.BusinessTravel
      );
GO


INSERT INTO hr.EducationField (EducationFieldName)
SELECT DISTINCT EducationField
FROM stg.EmployeeRaw s
WHERE EducationField IS NOT NULL
  AND NOT EXISTS
      (
          SELECT 1
          FROM hr.EducationField e
          WHERE e.EducationFieldName = s.EducationField
      );
GO


IF NOT EXISTS (SELECT 1 FROM hr.EducationLevel)
BEGIN
    INSERT INTO hr.EducationLevel
        (EducationLevelID, EducationLevelName)
    VALUES
        (1, 'Below College'),
        (2, 'College'),
        (3, 'Bachelor'),
        (4, 'Master'),
        (5, 'Doctor');
END;
GO


/*-----------------------------------------------------------------------------
 3.4 Carregamento das tabelas principais
-------------------------------------------------------------------------------*/

INSERT INTO hr.Employee
(
    EmployeeNumber,
    Age,
    GenderID,
    MaritalStatusID,
    DistanceFromHome,
    EducationLevelID,
    EducationFieldID
)
SELECT
    s.EmployeeNumber,
    s.Age,
    g.GenderID,
    m.MaritalStatusID,
    s.DistanceFromHome,
    s.Education,
    ef.EducationFieldID
FROM stg.EmployeeRaw s
JOIN hr.Gender g
    ON g.GenderName = s.Gender
JOIN hr.MaritalStatus m
    ON m.MaritalStatusName = s.MaritalStatus
JOIN hr.EducationField ef
    ON ef.EducationFieldName = s.EducationField
WHERE NOT EXISTS
(
    SELECT 1
    FROM hr.Employee e
    WHERE e.EmployeeNumber = s.EmployeeNumber
);
GO


INSERT INTO hr.Employment
(
    EmployeeNumber,
    DepartmentID,
    JobRoleID,
    JobLevel,
    BusinessTravelID,
    OverTimeFlag,
    AttritionFlag
)
SELECT
    s.EmployeeNumber,
    d.DepartmentID,
    j.JobRoleID,
    s.JobLevel,
    bt.BusinessTravelID,
    CASE WHEN s.OverTime = 'Yes' THEN 1 ELSE 0 END,
    CASE WHEN s.Attrition = 'Yes' THEN 1 ELSE 0 END
FROM stg.EmployeeRaw s
JOIN hr.Department d
    ON d.DepartmentName = s.Department
JOIN hr.JobRole j
    ON j.JobRoleName = s.JobRole
JOIN hr.BusinessTravel bt
    ON bt.BusinessTravelName = s.BusinessTravel
WHERE NOT EXISTS
(
    SELECT 1
    FROM hr.Employment e
    WHERE e.EmployeeNumber = s.EmployeeNumber
);
GO


INSERT INTO hr.Compensation
(
    EmployeeNumber,
    DailyRate,
    HourlyRate,
    MonthlyIncome,
    MonthlyRate,
    PercentSalaryHike,
    PerformanceRating,
    StockOptionLevel
)
SELECT
    EmployeeNumber,
    DailyRate,
    HourlyRate,
    MonthlyIncome,
    MonthlyRate,
    PercentSalaryHike,
    PerformanceRating,
    StockOptionLevel
FROM stg.EmployeeRaw s
WHERE NOT EXISTS
(
    SELECT 1
    FROM hr.Compensation c
    WHERE c.EmployeeNumber = s.EmployeeNumber
);
GO


INSERT INTO hr.Career
(
    EmployeeNumber,
    NumCompaniesWorked,
    TotalWorkingYears,
    TrainingTimesLastYear,
    YearsAtCompany,
    YearsInCurrentRole,
    YearsSinceLastPromotion,
    YearsWithCurrManager
)
SELECT
    EmployeeNumber,
    NumCompaniesWorked,
    TotalWorkingYears,
    TrainingTimesLastYear,
    YearsAtCompany,
    YearsInCurrentRole,
    YearsSinceLastPromotion,
    YearsWithCurrManager
FROM stg.EmployeeRaw s
WHERE NOT EXISTS
(
    SELECT 1
    FROM hr.Career c
    WHERE c.EmployeeNumber = s.EmployeeNumber
);
GO


INSERT INTO hr.SatisfactionSurvey
(
    EmployeeNumber,
    EnvironmentSatisfaction,
    JobInvolvement,
    JobSatisfaction,
    RelationshipSatisfaction,
    WorkLifeBalance
)
SELECT
    EmployeeNumber,
    EnvironmentSatisfaction,
    JobInvolvement,
    JobSatisfaction,
    RelationshipSatisfaction,
    WorkLifeBalance
FROM stg.EmployeeRaw s
WHERE NOT EXISTS
(
    SELECT 1
    FROM hr.SatisfactionSurvey ss
    WHERE ss.EmployeeNumber = s.EmployeeNumber
);
GO


/*=============================================================================
 4. CRIAÇÃO DE VIEWS
=============================================================================*/

/*
 As views voltam a juntar os dados normalizados para facilitar:
 - consultas SQL;
 - ligação ao Power BI;
 - criação de KPIs e gráficos.
*/


/*-----------------------------------------------------------------------------
 4.1 Perfil demográfico e profissional
-------------------------------------------------------------------------------*/

CREATE OR ALTER VIEW bi.vw_EmployeeProfile
AS
SELECT
    e.EmployeeNumber,
    e.Age,

    CASE
        WHEN e.Age BETWEEN 18 AND 25 THEN '18-25'
        WHEN e.Age BETWEEN 26 AND 35 THEN '26-35'
        WHEN e.Age BETWEEN 36 AND 45 THEN '36-45'
        WHEN e.Age BETWEEN 46 AND 55 THEN '46-55'
        WHEN e.Age BETWEEN 56 AND 59 THEN '56-59'
        ELSE '60+'
    END AS AgeBand,

    g.GenderName AS Gender,
    ms.MaritalStatusName AS MaritalStatus,
    e.DistanceFromHome,

    CASE
        WHEN e.DistanceFromHome <= 5 THEN '0-5'
        WHEN e.DistanceFromHome <= 10 THEN '6-10'
        WHEN e.DistanceFromHome <= 20 THEN '11-20'
        ELSE '21+'
    END AS DistanceBand,

    el.EducationLevelName AS EducationLevel,
    ef.EducationFieldName AS EducationField,
    d.DepartmentName AS Department,
    jr.JobRoleName AS JobRole,
    emp.JobLevel,
    bt.BusinessTravelName AS BusinessTravel,

    CASE WHEN emp.OverTimeFlag = 1 THEN 'Yes' ELSE 'No' END AS OverTime,
    CASE WHEN emp.AttritionFlag = 1 THEN 'Yes' ELSE 'No' END AS Attrition,

    CASE WHEN e.Age >= 60 THEN 1 ELSE 0 END AS RetirementIn5YearsFlag

FROM hr.Employee e
JOIN hr.Gender g
    ON g.GenderID = e.GenderID
JOIN hr.MaritalStatus ms
    ON ms.MaritalStatusID = e.MaritalStatusID
JOIN hr.EducationLevel el
    ON el.EducationLevelID = e.EducationLevelID
JOIN hr.EducationField ef
    ON ef.EducationFieldID = e.EducationFieldID
JOIN hr.Employment emp
    ON emp.EmployeeNumber = e.EmployeeNumber
JOIN hr.Department d
    ON d.DepartmentID = emp.DepartmentID
JOIN hr.JobRole jr
    ON jr.JobRoleID = emp.JobRoleID
JOIN hr.BusinessTravel bt
    ON bt.BusinessTravelID = emp.BusinessTravelID;
GO


/*-----------------------------------------------------------------------------
 4.2 Felicidade e bem-estar
-------------------------------------------------------------------------------*/

CREATE OR ALTER VIEW bi.vw_EmployeeHappiness
AS
SELECT
    ss.EmployeeNumber,
    ss.EnvironmentSatisfaction,
    ss.JobInvolvement,
    ss.JobSatisfaction,
    ss.RelationshipSatisfaction,
    ss.WorkLifeBalance,

    CAST
    (
        (
            ss.EnvironmentSatisfaction
            + ss.JobSatisfaction
            + ss.RelationshipSatisfaction
            + ss.WorkLifeBalance
        ) / 4.0
        AS DECIMAL(4,2)
    ) AS HappinessIndex,

    CASE
        WHEN
        (
            ss.EnvironmentSatisfaction
            + ss.JobSatisfaction
            + ss.RelationshipSatisfaction
            + ss.WorkLifeBalance
        ) / 4.0 < 2 THEN 'Low'

        WHEN
        (
            ss.EnvironmentSatisfaction
            + ss.JobSatisfaction
            + ss.RelationshipSatisfaction
            + ss.WorkLifeBalance
        ) / 4.0 < 3 THEN 'Medium'

        WHEN
        (
            ss.EnvironmentSatisfaction
            + ss.JobSatisfaction
            + ss.RelationshipSatisfaction
            + ss.WorkLifeBalance
        ) / 4.0 < 3.5 THEN 'High'

        ELSE 'Very High'
    END AS HappinessLevel

FROM hr.SatisfactionSurvey ss;
GO


/*-----------------------------------------------------------------------------
 4.3 View completa para estudo e Power BI
-------------------------------------------------------------------------------*/

CREATE OR ALTER VIEW bi.vw_HRAnalysis
AS
SELECT
    p.EmployeeNumber,
    p.Age,
    p.AgeBand,
    p.Gender,
    p.MaritalStatus,
    p.DistanceFromHome,
    p.DistanceBand,
    p.EducationLevel,
    p.EducationField,
    p.Department,
    p.JobRole,
    p.JobLevel,
    p.BusinessTravel,
    p.OverTime,
    p.Attrition,
    p.RetirementIn5YearsFlag,

    c.DailyRate,
    c.HourlyRate,
    c.MonthlyIncome,
    c.MonthlyRate,
    c.PercentSalaryHike,
    c.PerformanceRating,
    c.StockOptionLevel,

    cr.NumCompaniesWorked,
    cr.TotalWorkingYears,
    cr.TrainingTimesLastYear,
    cr.YearsAtCompany,

    CASE
        WHEN cr.YearsAtCompany <= 5 THEN '0-5'
        WHEN cr.YearsAtCompany <= 15 THEN '6-15'
        WHEN cr.YearsAtCompany <= 25 THEN '16-25'
        ELSE '26+'
    END AS YearsAtCompanyBand,

    cr.YearsInCurrentRole,
    cr.YearsSinceLastPromotion,
    cr.YearsWithCurrManager,

    h.EnvironmentSatisfaction,
    h.JobInvolvement,
    h.JobSatisfaction,
    h.RelationshipSatisfaction,
    h.WorkLifeBalance,
    h.HappinessIndex,
    h.HappinessLevel

FROM bi.vw_EmployeeProfile p
JOIN hr.Compensation c
    ON c.EmployeeNumber = p.EmployeeNumber
JOIN hr.Career cr
    ON cr.EmployeeNumber = p.EmployeeNumber
JOIN bi.vw_EmployeeHappiness h
    ON h.EmployeeNumber = p.EmployeeNumber;
GO


/*=============================================================================
 5. ESTUDO DA INFORMAÇÃO
=============================================================================*/

/*
 ENTREVISTA COM O DIRETOR DE RH

 Objetivos principais:
 - conhecer o perfil da empresa;
 - analisar equilíbrio entre homens e mulheres;
 - perceber se a empresa é jovem ou envelhecida;
 - identificar colaboradores próximos da reforma;
 - analisar felicidade e equilíbrio vida/trabalho;
 - estudar attrition;
 - apoiar decisões de recrutamento e políticas de atratividade.
*/


/*-----------------------------------------------------------------------------
 5.1 VALIDAÇÃO APÓS A NORMALIZAÇÃO
-------------------------------------------------------------------------------*/

-- As tabelas devem ter o mesmo número de colaboradores.
SELECT 'Employee' AS Tabela, COUNT(*) AS Total FROM hr.Employee
UNION ALL
SELECT 'Employment', COUNT(*) FROM hr.Employment
UNION ALL
SELECT 'Compensation', COUNT(*) FROM hr.Compensation
UNION ALL
SELECT 'Career', COUNT(*) FROM hr.Career
UNION ALL
SELECT 'SatisfactionSurvey', COUNT(*) FROM hr.SatisfactionSurvey;
GO


-- Verificar colaboradores sem registos nas tabelas relacionadas.
SELECT e.EmployeeNumber
FROM hr.Employee e
LEFT JOIN hr.Employment emp
    ON emp.EmployeeNumber = e.EmployeeNumber
LEFT JOIN hr.Compensation c
    ON c.EmployeeNumber = e.EmployeeNumber
LEFT JOIN hr.Career cr
    ON cr.EmployeeNumber = e.EmployeeNumber
LEFT JOIN hr.SatisfactionSurvey ss
    ON ss.EmployeeNumber = e.EmployeeNumber
WHERE emp.EmployeeNumber IS NULL
   OR c.EmployeeNumber IS NULL
   OR cr.EmployeeNumber IS NULL
   OR ss.EmployeeNumber IS NULL;
GO


/*-----------------------------------------------------------------------------
 5.2 QUEM SOMOS — PERFIL GERAL DA EMPRESA
-------------------------------------------------------------------------------*/

SELECT
    COUNT(*) AS TotalEmployees,
    CAST(AVG(CAST(Age AS DECIMAL(5,2))) AS DECIMAL(5,2)) AS AverageAge,
    MIN(Age) AS MinimumAge,
    MAX(Age) AS MaximumAge,
    CAST(AVG(CAST(YearsAtCompany AS DECIMAL(5,2))) AS DECIMAL(5,2))
        AS AverageYearsAtCompany
FROM bi.vw_HRAnalysis;
GO


-- Distribuição por departamento.
SELECT
    Department,
    COUNT(*) AS Employees,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,2))
        AS Percentage
FROM bi.vw_HRAnalysis
GROUP BY Department
ORDER BY Employees DESC;
GO


/*-----------------------------------------------------------------------------
 5.3 META DE 50% HOMENS / 50% MULHERES
-------------------------------------------------------------------------------*/

SELECT
    Gender,
    COUNT(*) AS Employees,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,2))
        AS GenderPercentage,
    CAST
    (
        ABS
        (
            50.0
            - 100.0 * COUNT(*) / SUM(COUNT(*)) OVER ()
        )
        AS DECIMAL(5,2)
    ) AS DifferenceFrom50Percent
FROM bi.vw_HRAnalysis
GROUP BY Gender;
GO


-- Equilíbrio de género por departamento.
SELECT
    Department,
    Gender,
    COUNT(*) AS Employees,
    CAST
    (
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (PARTITION BY Department)
        AS DECIMAL(5,2)
    ) AS PercentageWithinDepartment
FROM bi.vw_HRAnalysis
GROUP BY Department, Gender
ORDER BY Department, Gender;
GO


/*-----------------------------------------------------------------------------
 5.4 A EMPRESA É JOVEM OU ENVELHECIDA?
-------------------------------------------------------------------------------*/

SELECT
    AgeBand,
    COUNT(*) AS Employees,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,2))
        AS Percentage
FROM bi.vw_HRAnalysis
GROUP BY AgeBand
ORDER BY MIN(Age);
GO


/*
 Não é correto atribuir gerações como Gen Z, Millennials ou Gen X sem:
 - data de nascimento;
 - data exata do snapshot.

 Para o projeto usamos classes etárias, que são objetivas.
*/


/*-----------------------------------------------------------------------------
 5.5 RISCO DE REFORMA NOS PRÓXIMOS CINCO ANOS
-------------------------------------------------------------------------------*/

/*
 Pressuposto:
 - idade aproximada de reforma = 65 anos;
 - colaboradores com 60 ou mais anos podem reformar-se nos próximos cinco anos.
*/

SELECT
    COUNT(*) AS EmployeesNearRetirement,
    CAST
    (
        100.0 * COUNT(*)
        / (SELECT COUNT(*) FROM bi.vw_HRAnalysis)
        AS DECIMAL(5,2)
    ) AS PercentageNearRetirement
FROM bi.vw_HRAnalysis
WHERE RetirementIn5YearsFlag = 1;
GO


-- Departamentos com maior necessidade potencial de substituição.
SELECT
    Department,
    COUNT(*) AS EmployeesNearRetirement
FROM bi.vw_HRAnalysis
WHERE RetirementIn5YearsFlag = 1
GROUP BY Department
ORDER BY EmployeesNearRetirement DESC;
GO


-- Cargos com maior necessidade potencial de substituição.
SELECT
    Department,
    JobRole,
    COUNT(*) AS EmployeesNearRetirement
FROM bi.vw_HRAnalysis
WHERE RetirementIn5YearsFlag = 1
GROUP BY Department, JobRole
ORDER BY EmployeesNearRetirement DESC;
GO


-- Necessidade potencial de recrutamento num horizonte de cinco anos.
SELECT
    Department,
    JobRole,
    JobLevel,
    COUNT(*) AS PotentialReplacementsIn5Years
FROM bi.vw_HRAnalysis
WHERE RetirementIn5YearsFlag = 1
GROUP BY Department, JobRole, JobLevel
ORDER BY PotentialReplacementsIn5Years DESC;
GO


/*-----------------------------------------------------------------------------
 5.6 ÍNDICE DE FELICIDADE
-------------------------------------------------------------------------------*/

/*
 HappinessIndex:
 média de:
 - satisfação com o ambiente;
 - satisfação com o trabalho;
 - satisfação com relações;
 - equilíbrio vida pessoal/profissional.

 JobInvolvement é analisado separadamente porque mede envolvimento,
 não felicidade diretamente.
*/

SELECT
    CAST(AVG(HappinessIndex) AS DECIMAL(4,2)) AS CompanyHappinessIndex,
    CAST(AVG(CAST(WorkLifeBalance AS DECIMAL(5,2))) AS DECIMAL(4,2))
        AS AverageWorkLifeBalance,
    CAST(AVG(CAST(JobInvolvement AS DECIMAL(5,2))) AS DECIMAL(4,2))
        AS AverageJobInvolvement
FROM bi.vw_HRAnalysis;
GO


-- Índice de felicidade por departamento.
SELECT
    Department,
    COUNT(*) AS Employees,
    CAST(AVG(HappinessIndex) AS DECIMAL(4,2)) AS HappinessIndex,
    CAST(AVG(CAST(WorkLifeBalance AS DECIMAL(5,2))) AS DECIMAL(4,2))
        AS AverageWorkLifeBalance
FROM bi.vw_HRAnalysis
GROUP BY Department
ORDER BY HappinessIndex;
GO


-- Distribuição dos níveis de felicidade.
SELECT
    HappinessLevel,
    COUNT(*) AS Employees,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,2))
        AS Percentage
FROM bi.vw_HRAnalysis
GROUP BY HappinessLevel
ORDER BY MIN(HappinessIndex);
GO


/*-----------------------------------------------------------------------------
 5.7 ATTRITION E RETENÇÃO
-------------------------------------------------------------------------------*/

-- Taxa geral de attrition.
SELECT
    COUNT(*) AS TotalEmployees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Attritions,
    CAST
    (
        100.0 * SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(5,2)
    ) AS AttritionRate
FROM bi.vw_HRAnalysis;
GO


-- Attrition por departamento.
SELECT
    Department,
    COUNT(*) AS Employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Attritions,
    CAST
    (
        100.0 * SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(5,2)
    ) AS AttritionRate
FROM bi.vw_HRAnalysis
GROUP BY Department
ORDER BY AttritionRate DESC;
GO


-- Attrition por classe etária.
SELECT
    AgeBand,
    COUNT(*) AS Employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Attritions,
    CAST
    (
        100.0 * SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(5,2)
    ) AS AttritionRate
FROM bi.vw_HRAnalysis
GROUP BY AgeBand
ORDER BY MIN(Age);
GO


-- Attrition por cargo e nível.
SELECT
    Department,
    JobRole,
    JobLevel,
    COUNT(*) AS Employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Attritions,
    CAST
    (
        100.0 * SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(5,2)
    ) AS AttritionRate
FROM bi.vw_HRAnalysis
GROUP BY Department, JobRole, JobLevel
HAVING COUNT(*) >= 5
ORDER BY AttritionRate DESC;
GO


/*-----------------------------------------------------------------------------
 5.8 FELICIDADE VERSUS ATTRITION
-------------------------------------------------------------------------------*/

SELECT
    Attrition,
    COUNT(*) AS Employees,
    CAST(AVG(HappinessIndex) AS DECIMAL(4,2)) AS HappinessIndex,
    CAST(AVG(CAST(EnvironmentSatisfaction AS DECIMAL(5,2))) AS DECIMAL(4,2))
        AS EnvironmentSatisfaction,
    CAST(AVG(CAST(JobSatisfaction AS DECIMAL(5,2))) AS DECIMAL(4,2))
        AS JobSatisfaction,
    CAST(AVG(CAST(RelationshipSatisfaction AS DECIMAL(5,2))) AS DECIMAL(4,2))
        AS RelationshipSatisfaction,
    CAST(AVG(CAST(WorkLifeBalance AS DECIMAL(5,2))) AS DECIMAL(4,2))
        AS WorkLifeBalance
FROM bi.vw_HRAnalysis
GROUP BY Attrition;
GO


/*-----------------------------------------------------------------------------
 5.9 SALÁRIO E PROGRESSÃO
-------------------------------------------------------------------------------*/

-- Salário médio de quem saiu e de quem permaneceu.
SELECT
    Attrition,
    COUNT(*) AS Employees,
    CAST(AVG(CAST(MonthlyIncome AS DECIMAL(12,2))) AS DECIMAL(12,2))
        AS AverageMonthlyIncome,
    CAST(AVG(CAST(PercentSalaryHike AS DECIMAL(5,2))) AS DECIMAL(5,2))
        AS AverageSalaryHike
FROM bi.vw_HRAnalysis
GROUP BY Attrition;
GO


-- Progressão salarial por nível do cargo.
SELECT
    JobLevel,
    COUNT(*) AS Employees,
    CAST(AVG(CAST(MonthlyIncome AS DECIMAL(12,2))) AS DECIMAL(12,2))
        AS AverageMonthlyIncome,
    CAST(AVG(CAST(PercentSalaryHike AS DECIMAL(5,2))) AS DECIMAL(5,2))
        AS AverageSalaryHike
FROM bi.vw_HRAnalysis
GROUP BY JobLevel
ORDER BY JobLevel;
GO


-- Salário por antiguidade na empresa.
SELECT
    YearsAtCompanyBand,
    COUNT(*) AS Employees,
    CAST(AVG(CAST(MonthlyIncome AS DECIMAL(12,2))) AS DECIMAL(12,2))
        AS AverageMonthlyIncome,
    CAST(AVG(CAST(PercentSalaryHike AS DECIMAL(5,2))) AS DECIMAL(5,2))
        AS AverageSalaryHike
FROM bi.vw_HRAnalysis
GROUP BY YearsAtCompanyBand
ORDER BY MIN(YearsAtCompany);
GO


/*-----------------------------------------------------------------------------
 5.10 POLÍTICAS DE ATRATIVIDADE — INDICADORES
-------------------------------------------------------------------------------*/

-- Horas extra e attrition.
SELECT
    OverTime,
    COUNT(*) AS Employees,
    CAST
    (
        100.0 * SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(5,2)
    ) AS AttritionRate
FROM bi.vw_HRAnalysis
GROUP BY OverTime;
GO


-- Viagens profissionais e attrition.
SELECT
    BusinessTravel,
    COUNT(*) AS Employees,
    CAST
    (
        100.0 * SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(5,2)
    ) AS AttritionRate
FROM bi.vw_HRAnalysis
GROUP BY BusinessTravel
ORDER BY AttritionRate DESC;
GO


-- Distância de casa e attrition.
SELECT
    DistanceBand,
    COUNT(*) AS Employees,
    CAST
    (
        100.0 * SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(5,2)
    ) AS AttritionRate
FROM bi.vw_HRAnalysis
GROUP BY DistanceBand
ORDER BY MIN(DistanceFromHome);
GO


-- Treinamentos e attrition.
SELECT
    TrainingTimesLastYear,
    COUNT(*) AS Employees,
    CAST
    (
        100.0 * SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(5,2)
    ) AS AttritionRate
FROM bi.vw_HRAnalysis
GROUP BY TrainingTimesLastYear
ORDER BY TrainingTimesLastYear;
GO


-- Antiguidade e attrition.
SELECT
    YearsAtCompanyBand,
    COUNT(*) AS Employees,
    CAST
    (
        100.0 * SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(5,2)
    ) AS AttritionRate
FROM bi.vw_HRAnalysis
GROUP BY YearsAtCompanyBand
ORDER BY MIN(YearsAtCompany);
GO


/*-----------------------------------------------------------------------------
 5.11 ESTADO CIVIL E VIAGENS
-------------------------------------------------------------------------------*/

SELECT
    MaritalStatus,
    BusinessTravel,
    COUNT(*) AS Employees,
    CAST
    (
        100.0 * SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(5,2)
    ) AS AttritionRate
FROM bi.vw_HRAnalysis
GROUP BY MaritalStatus, BusinessTravel
HAVING COUNT(*) >= 5
ORDER BY AttritionRate DESC;
GO


/*=============================================================================
 6. O QUE NÃO É POSSÍVEL RESPONDER COM ESTE DATASET
=============================================================================*/

/*
 1. Acompanhamento evolutivo
    Só existe um snapshot e uma pesquisa.
    Não é possível demonstrar evolução ao longo do tempo.

 2. Impacto da mesa de ping-pong
    A segunda survey não faz parte deste modelo SQL.
    A primeira pesquisa apenas fornece o estado inicial.

 3. Trabalho no escritório ou remoto
    O dataset não possui uma coluna sobre modalidade de trabalho.

 4. Utilização do refeitório
    O dataset não possui presenças ou utilização do refeitório.

 5. Reforma efetiva
    O dataset não contém data de nascimento nem data prevista de reforma.
    A análise de reforma usa apenas o pressuposto de idade >= 60 anos.

 6. Gerações
    Sem data de nascimento e data exata do snapshot, é preferível usar
    classes etárias em vez de rótulos como Gen Z ou Millennials.

 7. Causalidade
    As consultas mostram associações.
    Não provam que salário, horas extra, viagens ou felicidade causaram
    diretamente a saída dos colaboradores.
*/


/*=============================================================================
 7. POSSÍVEIS RECOMENDAÇÕES DE RH A PARTIR DOS RESULTADOS
=============================================================================*/

/*
 As recomendações devem ser propostas apenas depois de observar os resultados.

 Exemplos:

 - Plano de sucessão e recrutamento para departamentos/cargos com mais pessoas
   de 60 ou mais anos.

 - Programas de integração e desenvolvimento para colaboradores mais jovens
   ou com poucos anos de empresa, caso apresentem maior attrition.

 - Revisão da carga de horas extra nos grupos com maior attrition.

 - Políticas de flexibilidade ou mobilidade para quem mora mais longe.

 - Planos de carreira e progressão salarial por nível e antiguidade.

 - Formação direcionada aos grupos com menor participação em treinamentos.

 - Intervenções de bem-estar nos departamentos com menor índice de felicidade
   ou menor WorkLifeBalance.

 - Ações para aproximar a distribuição de género da meta de 50% / 50%,
   especialmente nos departamentos mais desequilibrados.
*/


/*=============================================================================
 FIM DO FICHEIRO
=============================================================================*/
