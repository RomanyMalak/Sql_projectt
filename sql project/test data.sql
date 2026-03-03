

-- اختبار view
SELECT TOP 50 * FROM dbo.v_TrackWithDepartment;
SELECT TOP 50 * FROM dbo.v_InstructorProfile;


--- trigger
BEGIN TRY
  INSERT INTO dbo.Intake(IntakeName, StartDate, EndDate)
  VALUES (N'Bad', '2026-09-01', '2026-03-01');
END TRY
BEGIN CATCH
  SELECT ERROR_MESSAGE() AS TriggerWorked;
END CATCH;

------

-- instractor 
DECLARE @AnyStudentUser INT =
(
  SELECT TOP 1 UserID FROM dbo.Users WHERE Role=N'Student' ORDER BY NEWID()
);

BEGIN TRY
  INSERT INTO dbo.Instructor(UserID, Name, Email)
  VALUES (@AnyStudentUser, N'X', N'x@mail.com');
END TRY
BEGIN CATCH
  SELECT ERROR_MESSAGE() AS TriggerWorked;
END CATCH;

-----------------
EXECUTE AS USER = 'student_u';
BEGIN TRY
  SELECT TOP 5 * FROM dbo.Department;     -- المفروض يفشل لو DENY على tables
END TRY
BEGIN CATCH
  SELECT ERROR_MESSAGE() AS ExpectedDeny;
END CATCH;



BEGIN TRY
  SELECT TOP 5 * FROM dbo.v_TrackWithDepartment; -- المفروض ينجح
END TRY
BEGIN CATCH
  SELECT ERROR_MESSAGE() AS Unexpected;
END CATCH;
REVERT;



SELECT name, type_desc
FROM sys.objects
WHERE name = 'usp_User_Create';




EXEC dbo.usp_User_Create
    @Username     = N'stu_ahmed',
    @PasswordHash = N'hash_123',
    @Role         = N'Student';



    EXEC dbo.usp_User_Search @Username = N'stu_ahmed';



    SELECT TOP 10 UserID, Username, Role
FROM dbo.Users
ORDER BY UserID DESC;


EXEC dbo.usp_Department_Create @DepartmentName = N'AI Department';
EXEC dbo.usp_Department_Search @Name = N'AI';


EXEC dbo.usp_Branch_Create @BranchName = N'Cairo';
EXEC dbo.usp_Branch_Search @Name = N'Ca';



EXEC dbo.usp_Intake_Create
    @IntakeName = N'Intake 45',
    @StartDate  = '2026-03-01',
    @EndDate    = '2026-09-01';

EXEC dbo.usp_Intake_Search @Name = N'45';


EXEC dbo.usp_Department_Search @Name = N'AI Department';



EXEC dbo.usp_User_Create
    @Username     = N'romany',
    @PasswordHash = N'hash_999',
    @Role         = N'Instructor';

    EXEC dbo.usp_User_Search @Username =N'romany';

    EXEC dbo.usp_Instructor_Create
    @UserID = 502,
    @Name   = N'Romany Malak',
    @Email  = N'romany@mail.com';


    SELECT * FROM dbo.v_InstructorProfile;

EXEC dbo.usp_Instructor_Search @Name = N'Romany';




EXEC dbo.usp_User_Create
    @Username     = N'hager',
    @PasswordHash = N'hash',
    @Role         = N'Student';

EXEC dbo.usp_User_Search @Username = N'hager';  -- هات UserID (مثلاً 13)

EXEC dbo.usp_Instructor_Create
    @UserID = 503,
    @Name = N'Mo',
    @Email = N'mo@mail.com';
--لعError: Cannot insert/update Instructor unless Users.Role = Instructor.

EXECUTE AS USER = 'student_u';

-- المفروض ينجح (view):
SELECT TOP 5 * FROM dbo.v_TrackWithDepartment;

-- المفروض يفشل (table direct):
SELECT TOP 5 * FROM dbo.Department;

REVERT;



SELECT name, type_desc
FROM sys.database_principals
WHERE name IN ('db_exam_admin','db_training_manager','db_instructor','db_student');




SELECT 
  dp.name AS Principal,
  o.name  AS ObjectName,
  p.permission_name,
  p.state_desc
FROM sys.database_permissions p
JOIN sys.database_principals dp ON dp.principal_id = p.grantee_principal_id
JOIN sys.objects o ON o.object_id = p.major_id
WHERE dp.name IN ('db_exam_admin','db_training_manager','db_instructor','db_student')
ORDER BY dp.name, o.name, p.permission_name;





EXECUTE AS USER = 'student_u';

PRINT 'Student: table direct access (should FAIL)';
BEGIN TRY
    SELECT TOP 1 * FROM dbo.Department;
    SELECT 'FAIL: student can read Department table' AS Result;
END TRY
BEGIN CATCH
    SELECT 'PASS: student denied on Department table' AS Result, ERROR_MESSAGE() AS Msg;
END CATCH;



PRINT 'Student: view access (should PASS)';
BEGIN TRY
    SELECT TOP 5 * FROM dbo.v_TrackWithDepartment;
    SELECT 'PASS: student can read v_TrackWithDepartment' AS Result;
END TRY
BEGIN CATCH
    SELECT 'FAIL: student cannot read view' AS Result, ERROR_MESSAGE() AS Msg;
END CATCH;

REVERT;
GO