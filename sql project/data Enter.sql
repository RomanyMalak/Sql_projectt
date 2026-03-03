USE ExaminationSystem_new_version;
GO

/* Departments: 20 */
;WITH n AS (
  SELECT TOP (20) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
  FROM sys.objects
)
INSERT INTO dbo.Department(DepartmentName)
SELECT CONCAT(N'Department ', i) FROM n;

/* Branches: 10 */
;WITH n AS (
  SELECT TOP (10) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
  FROM sys.objects
)
INSERT INTO dbo.Branch(BranchName)
SELECT CONCAT(N'Branch ', i) FROM n;

/* Intakes: 12 */
;WITH n AS (
  SELECT TOP (12) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
  FROM sys.objects
)
INSERT INTO dbo.Intake(IntakeName, StartDate, EndDate)
SELECT CONCAT(N'Intake ', i),
       DATEADD(MONTH, (i-1)*6, CAST('2024-01-01' AS DATE)),
       DATEADD(MONTH, (i-1)*6 + 5, CAST('2024-01-01' AS DATE))
FROM n;

/* Tracks: 200 (random DepartmentID) */
;WITH n AS (
  SELECT TOP (200) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
  FROM sys.objects a CROSS JOIN sys.objects b
)
INSERT INTO dbo.Track(TrackName, DepartmentID)
SELECT CONCAT(N'Track ', i),
       (SELECT TOP 1 DepartmentID FROM dbo.Department ORDER BY NEWID())
FROM n;

/* Users: 500 (mix roles) */
;WITH n AS (
  SELECT TOP (500) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
  FROM sys.objects a CROSS JOIN sys.objects b
)
INSERT INTO dbo.Users(Username, PasswordHash, Role)
SELECT CONCAT(N'user_', i),
       CONCAT(N'hash_', i),
       CASE WHEN i % 3 = 0 THEN N'Student'
            WHEN i % 3 = 1 THEN N'Instructor'
            ELSE N'Manager' END
FROM n;

/* Instructors: create 120 instructors from Users where Role=Instructor */
INSERT INTO dbo.Instructor(UserID, Name, Email)
SELECT TOP (120)
       u.UserID,
       CONCAT(N'Instructor ', u.UserID),
       CONCAT(N'instructor', u.UserID, N'@mail.com')
FROM dbo.Users u
WHERE u.Role = N'Instructor'
  AND NOT EXISTS (SELECT 1 FROM dbo.Instructor i WHERE i.UserID = u.UserID)
ORDER BY u.UserID;
GO