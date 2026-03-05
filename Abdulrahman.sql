use [ExaminationSystemDB];
-- Add Student (creates SystemUser + Student in one transaction)
CREATE OR ALTER PROCEDURE usp_AddStudent
    @Username    NVARCHAR(50),
    @PasswordHash NVARCHAR(256),
    @IntakeID    INT,
    @BranchID    INT,
    @TrackID     INT,
    @FirstName   NVARCHAR(50),
    @LastName    NVARCHAR(50),
    @Email       NVARCHAR(100),
    @Phone       NVARCHAR(20) = NULL,
    @DateOfBirth DATE         = NULL,
    @NationalID  NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO ExaminationSystemDB.dbo.SystemUser (Username, PasswordHash, UserRole)
        VALUES (@Username, @PasswordHash, 'Student');
        DECLARE @NewUserID INT = SCOPE_IDENTITY();

        INSERT INTO Student (UserID, IntakeID, BranchID, TrackID,
                             FirstName, LastName, Email, Phone, DateOfBirth, NationalID)
        VALUES (@NewUserID, @IntakeID, @BranchID, @TrackID,
                @FirstName, @LastName, @Email, @Phone, @DateOfBirth, @NationalID);

        SELECT SCOPE_IDENTITY() AS NewStudentID;
        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO
drop procedure usp_AddStudent;
select * from ExaminationSystemDB.dbo.Intake;
insert into ExaminationSystemDB.dbo.Intake (IntakeName, StartDate, EndDate) values ('Intake 1', '2024-01-01', '2024-12-31');
insert into ExaminationSystemDB.dbo.Branch ( BranchName) values ( 'Computer Science');
insert into ExaminationSystemDB.dbo.Track ( TrackName,BranchID) values ( 'Software Engineering', 1);

Exec usp_AddStudent
    @Username = 'john.doe',
    @PasswordHash = 'hashedpassword123',
    @IntakeID = 1,
    @BranchID = 1,
    @TrackID = 1,
    @FirstName = 'John',
    @LastName = 'Doe',
    @Email = 'john@gmail.com',
    @Phone = '1234567890',
    @DateOfBirth = '1990-01-01',
    @NationalID = 'A123456789';
GO

select * from [dbo].[Student];

-- Assign Instructor to Course
CREATE OR ALTER PROCEDURE sp_AssignInstructorToCourse
    @InstructorID INT,
    @CourseID     INT,
    @IntakeID     INT,
    @BranchID     INT,
    @TrackID      INT,
    @AcademicYear INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM InstructorCourse
        WHERE InstructorID = @InstructorID AND CourseID     = @CourseID
          AND IntakeID     = @IntakeID     AND BranchID     = @BranchID
          AND TrackID      = @TrackID      AND AcademicYear = @AcademicYear
    )
        THROW 50010, 'This assignment already exists.', 1;

    INSERT INTO InstructorCourse (InstructorID, CourseID, IntakeID, BranchID, TrackID, AcademicYear)
    VALUES (@InstructorID, @CourseID, @IntakeID, @BranchID, @TrackID, @AcademicYear);
    SELECT SCOPE_IDENTITY() AS NewAssignmentID;
END;
GO

-- Test Data
INSERT INTO Course (CourseName, Description, MaxDegree, MinDegree)
VALUES ('Database Systems', 'Learn about databases', 100, 50);

INSERT INTO SystemUser (Username, PasswordHash, UserRole)
VALUES ('instructor2', 'pass', 'Instructor');

INSERT INTO Instructor (UserID, FirstName, LastName, Email)
VALUES (3, 'Dr', 'Smith', 'drsmith@test.com');

-- Test Procedure
EXEC sp_AssignInstructorToCourse
    @InstructorID = 5,
    @CourseID = 1,
    @IntakeID = 1,
    @BranchID = 1,
    @TrackID = 1,
    @AcademicYear = 2024;

SELECT * FROM InstructorCourse;



-- Search Students
CREATE OR ALTER PROCEDURE sp_SearchStudents
    @IntakeID   INT           = NULL,
    @BranchID   INT           = NULL,
    @TrackID    INT           = NULL,
    @SearchName NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *
    FROM vw_StudentFullInfo
    WHERE (@IntakeID   IS NULL OR IntakeName  = (SELECT IntakeName FROM Intake WHERE IntakeID = @IntakeID))
      AND (@BranchID   IS NULL OR BranchName  = (SELECT BranchName FROM Branch WHERE BranchID = @BranchID))
      AND (@TrackID    IS NULL OR TrackName   = (SELECT TrackName  FROM Track  WHERE TrackID  = @TrackID))
      AND (@SearchName IS NULL OR StudentName LIKE '%' + @SearchName + '%');
END;
GO
-- Test Procedure
EXEC sp_SearchStudents
    @IntakeID = 1,
    @BranchID = 1,
    @TrackID = 1,
    @SearchName = 'John';

-- View results
SELECT * FROM vw_StudentFullInfo;

------------------------------------------------------------------------
-- INSTRUCTOR – QUESTION MANAGEMENT
------------------------------------------------------------------------

-- Add Question
CREATE OR ALTER PROCEDURE sp_AddQuestion
    @CourseID        INT,
    @InstructorID    INT,
    @QuestionType    NVARCHAR(20),
    @QuestionText    NVARCHAR(MAX),
    @ModelAnswer     NVARCHAR(MAX) = NULL,
    @DifficultyLevel NVARCHAR(10)  = 'Medium'
AS
BEGIN
    SET NOCOUNT ON;
    -- Ownership enforced by trg_Question_InstructorCourse
    INSERT INTO Question (CourseID, InstructorID, QuestionType, QuestionText, ModelAnswer, DifficultyLevel)
    VALUES (@CourseID, @InstructorID, @QuestionType, @QuestionText, @ModelAnswer, @DifficultyLevel);
    SELECT SCOPE_IDENTITY() AS NewQuestionID;
END;
GO

select * from [dbo].[Instructor];
-- Test Procedure
EXEC sp_AddQuestion
    @CourseID = 1,
    @InstructorID = 5,
    @QuestionType = 'MCQ',
    @QuestionText = 'What is SQL?',
    @ModelAnswer = 'Structured Query Language',
    @DifficultyLevel = 'Easy';

SELECT * FROM Question;



-- Add Question Choice
CREATE OR ALTER PROCEDURE sp_AddQuestionChoice
    @QuestionID  INT,
    @ChoiceText  NVARCHAR(500),
    @IsCorrect   BIT,
    @ChoiceOrder TINYINT = 1
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Question WHERE QuestionID = @QuestionID
                                            AND QuestionType IN ('MCQ','TrueFalse'))
        THROW 50025, 'Question not found or is not of type MCQ/TrueFalse.', 1;

    -- TrueFalse: enforce max 2 choices
    IF (SELECT QuestionType FROM Question WHERE QuestionID = @QuestionID) = 'TrueFalse'
        AND (SELECT COUNT(*) FROM QuestionChoice WHERE QuestionID = @QuestionID) >= 2
        THROW 50026, 'TrueFalse questions can only have 2 choices.', 1;

    INSERT INTO QuestionChoice (QuestionID, ChoiceText, IsCorrect, ChoiceOrder)
    VALUES (@QuestionID, @ChoiceText, @IsCorrect, @ChoiceOrder);
    SELECT SCOPE_IDENTITY() AS NewChoiceID;
END;
GO

-- Test Procedure
EXEC sp_AddQuestionChoice
    @QuestionID = 3,
    @ChoiceText = 'Structured Query Language',
    @IsCorrect = 1,
    @ChoiceOrder = 1;

EXEC sp_AddQuestionChoice
    @QuestionID = 3,
    @ChoiceText = 'Simple Query Language',
    @IsCorrect = 0,
    @ChoiceOrder = 2;

EXEC sp_AddQuestionChoice
    @QuestionID = 3,
    @ChoiceText = 'System Query Language',
    @IsCorrect = 0,
    @ChoiceOrder = 3;

SELECT * FROM QuestionChoice;



-- Update Question
CREATE OR ALTER PROCEDURE sp_UpdateQuestion
    @QuestionID      INT,
    @InstructorID    INT,
    @QuestionText    NVARCHAR(MAX) = NULL,
    @ModelAnswer     NVARCHAR(MAX) = NULL,
    @DifficultyLevel NVARCHAR(10)  = NULL,
    @IsActive        BIT           = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Question
                   WHERE QuestionID = @QuestionID AND InstructorID = @InstructorID)
        THROW 50020, 'Question not found or you do not own it.', 1;

    UPDATE Question
    SET
        QuestionText    = ISNULL(@QuestionText,    QuestionText),
        ModelAnswer     = ISNULL(@ModelAnswer,     ModelAnswer),
        DifficultyLevel = ISNULL(@DifficultyLevel, DifficultyLevel),
        IsActive        = ISNULL(@IsActive,        IsActive)
    WHERE QuestionID = @QuestionID;
END;
GO

-- Test Procedure
EXEC sp_UpdateQuestion
    @QuestionID = 3,
    @InstructorID = 5,
    @QuestionText = 'What does SQL stand for?',
    @DifficultyLevel = 'Medium',
    @IsActive = 1;

SELECT * FROM Question;




-- Delete Question (soft-delete if used in exam, hard-delete otherwise)
CREATE OR ALTER PROCEDURE sp_DeleteQuestion
    @QuestionID   INT,
    @InstructorID INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Question
                   WHERE QuestionID = @QuestionID AND InstructorID = @InstructorID)
        THROW 50021, 'Question not found or you do not own it.', 1;

    IF EXISTS (SELECT 1 FROM ExamQuestion WHERE QuestionID = @QuestionID)
        THROW 50022, 'Cannot delete a question used in an exam. Deactivate it instead.', 1;

    DELETE FROM Question WHERE QuestionID = @QuestionID;
    PRINT 'Question deleted successfully.';
END;
GO

-- Test Procedure
EXEC sp_DeleteQuestion
    @QuestionID = 1,
    @InstructorID = 1;

SELECT * FROM Question;

-- Search Questions
CREATE OR ALTER PROCEDURE sp_SearchQuestions
    @CourseID     INT          = NULL,
    @QuestionType NVARCHAR(20) = NULL,
    @Difficulty   NVARCHAR(10) = NULL,
    @SearchText   NVARCHAR(200)= NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *
    FROM vw_QuestionPool
    WHERE (@CourseID     IS NULL OR CourseID      = @CourseID)
      AND (@QuestionType IS NULL OR QuestionType  = @QuestionType)
      AND (@Difficulty   IS NULL OR DifficultyLevel = @Difficulty)
      AND (@SearchText   IS NULL OR QuestionText  LIKE '%' + @SearchText + '%')
      AND IsActive = 1;
END;
GO


-- Test Procedure
EXEC sp_SearchQuestions
    @CourseID = 1,
    @QuestionType = 'MCQ',
    @Difficulty = 'Medium',
    @SearchText = 'SQL';

SELECT * FROM vw_QuestionPool;