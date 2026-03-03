
-- منع ادخال instrucor to user non instructor
CREATE OR ALTER TRIGGER dbo.TR_Instructor_EnforceRole
ON dbo.Instructor
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN dbo.Users u ON u.UserID = i.UserID
        WHERE u.Role <> 'Instructor'
    )
    BEGIN
        RAISERROR('Cannot insert/update Instructor unless Users.Role = Instructor.', 16, 1);
        ROLLBACK;
        RETURN;
    END
END
GO

----منع تغيير Role ليوزر مرتبطInstructor بـ 

CREATE OR ALTER TRIGGER dbo.TR_Users_PreventRoleChange_IfInstructor
ON dbo.Users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(Role)
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM inserted i
            JOIN deleted d ON d.UserID = i.UserID
            JOIN dbo.Instructor ins ON ins.UserID = i.UserID
            WHERE i.Role <> d.Role
        )
        BEGIN
            RAISERROR('Cannot change role for a user linked to Instructor table.', 16, 1);
            ROLLBACK;
            RETURN;
        END
    END
END
GO

--لمنع توايخ غلط 

CREATE OR ALTER TRIGGER dbo.TR_Intake_ValidateDates
ON dbo.Intake
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM inserted
        WHERE StartDate IS NOT NULL AND EndDate IS NOT NULL
          AND EndDate < StartDate
    )
    BEGIN
        RAISERROR('Intake EndDate cannot be earlier than StartDate.', 16, 1);
        ROLLBACK;
        RETURN;
    END
END
GO






--Stored Procedures (CRUD + Search)

CREATE OR ALTER PROC dbo.usp_User_Create
    @Username NVARCHAR(100),
    @PasswordHash NVARCHAR(255),
    @Role NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Users(Username, PasswordHash, Role)
    VALUES (@Username, @PasswordHash, @Role);
END
GO

CREATE OR ALTER PROC dbo.usp_User_Search
    @Username NVARCHAR(100) = NULL,
    @Role NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT UserID, Username, Role
    FROM dbo.Users
    WHERE (@Username IS NULL OR Username LIKE N'%' + @Username + N'%')
      AND (@Role IS NULL OR Role = @Role)
    ORDER BY UserID DESC;
END
GO

--


----Department / Branch / Track / Intake / Instructor (CRUD + Search)
/* Department */
CREATE OR ALTER PROC dbo.usp_Department_Create
    @DepartmentName NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Department(DepartmentName) VALUES(@DepartmentName);
END
GO

CREATE OR ALTER PROC dbo.usp_Department_Search
    @Name NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT DepartmentID, DepartmentName
    FROM dbo.Department
    WHERE (@Name IS NULL OR DepartmentName LIKE N'%' + @Name + N'%')
    ORDER BY DepartmentName;
END
GO

/* Branch */
CREATE OR ALTER PROC dbo.usp_Branch_Create
    @BranchName NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Branch(BranchName) VALUES(@BranchName);
END
GO

CREATE OR ALTER PROC dbo.usp_Branch_Search
    @Name NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT BranchID, BranchName
    FROM dbo.Branch
    WHERE (@Name IS NULL OR BranchName LIKE N'%' + @Name + N'%')
    ORDER BY BranchName;
END
GO

/* Track */
CREATE OR ALTER PROC dbo.usp_Track_Create
    @TrackName NVARCHAR(200),
    @DepartmentID INT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Track(TrackName, DepartmentID) VALUES(@TrackName, @DepartmentID);
END
GO

CREATE OR ALTER PROC dbo.usp_Track_Search
    @TrackName NVARCHAR(200) = NULL,
    @DepartmentID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT t.TrackID, t.TrackName, t.DepartmentID, d.DepartmentName
    FROM dbo.Track t
    JOIN dbo.Department d ON d.DepartmentID = t.DepartmentID
    WHERE (@TrackName IS NULL OR t.TrackName LIKE N'%' + @TrackName + N'%')
      AND (@DepartmentID IS NULL OR t.DepartmentID = @DepartmentID)
    ORDER BY t.TrackName;
END
GO

/* Intake */
CREATE OR ALTER PROC dbo.usp_Intake_Create
    @IntakeName NVARCHAR(100) = NULL,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Intake(IntakeName, StartDate, EndDate)
    VALUES(@IntakeName, @StartDate, @EndDate);
END
GO

CREATE OR ALTER PROC dbo.usp_Intake_Search
    @Name NVARCHAR(100) = NULL,
    @From DATE = NULL,
    @To DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT IntakeID, IntakeName, StartDate, EndDate
    FROM dbo.Intake
    WHERE (@Name IS NULL OR IntakeName LIKE N'%' + @Name + N'%')
      AND (@From IS NULL OR StartDate >= @From)
      AND (@To IS NULL OR EndDate <= @To)
    ORDER BY StartDate DESC;
END
GO

/* Instructor */
CREATE OR ALTER PROC dbo.usp_Instructor_Create
    @UserID INT,
    @Name NVARCHAR(200) = NULL,
    @Email NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Instructor(UserID, Name, Email)
    VALUES(@UserID, @Name, @Email);
END
GO

CREATE OR ALTER PROC dbo.usp_Instructor_Search
    @Name NVARCHAR(200) = NULL,
    @Email NVARCHAR(200) = NULL,
    @Username NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT ins.InstructorID,
           ins.Name,
           ins.Email,
           u.UserID,
           u.Username
    FROM dbo.Instructor ins
    JOIN dbo.Users u ON u.UserID = ins.UserID
    WHERE (@Name IS NULL OR ins.Name LIKE N'%' + @Name + N'%')
      AND (@Email IS NULL OR ins.Email LIKE N'%' + @Email + N'%')
      AND (@Username IS NULL OR u.Username LIKE N'%' + @Username + N'%')
    ORDER BY ins.InstructorID DESC;
END
GO

--


-------- view to show
CREATE OR ALTER VIEW dbo.v_TrackWithDepartment
AS
SELECT t.TrackID, t.TrackName,
       d.DepartmentID, d.DepartmentName
FROM dbo.Track t
JOIN dbo.Department d ON d.DepartmentID = t.DepartmentID;
GO

CREATE OR ALTER VIEW dbo.v_InstructorProfile
AS
SELECT ins.InstructorID, ins.Name, ins.Email,
       u.UserID, u.Username, u.Role
FROM dbo.Instructor ins
JOIN dbo.Users u ON u.UserID = ins.UserID;
GO