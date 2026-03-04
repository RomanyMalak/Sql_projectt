-- ============================================================
-- EXAMINATION SYSTEM DATABASE
-- Author : Abdulrahman
-- Version: Refactored
-- ============================================================

-- ============================================================
-- SECTION 0: DATABASE CREATION
-- ============================================================

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'ExaminationSystem')
    CREATE DATABASE ExaminationSystem;
GO

USE ExaminationSystem;
GO

-- ============================================================
-- SECTION 1: TABLES
-- ============================================================

-- 1. Users
CREATE TABLE Users (
    UserID       INT           IDENTITY PRIMARY KEY,
    Username     NVARCHAR(100) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    Role         NVARCHAR(20)  NOT NULL
        CONSTRAINT CK_Users_Role CHECK (Role IN ('Student','Instructor','Manager'))
);
GO

-- 2. Department
CREATE TABLE Department (
    DepartmentID   INT           IDENTITY PRIMARY KEY,
    DepartmentName NVARCHAR(200) NOT NULL
);
GO

-- 3. Branch
CREATE TABLE Branch (
    BranchID   INT           IDENTITY PRIMARY KEY,
    BranchName NVARCHAR(200) NOT NULL
);
GO

-- 4. Track
CREATE TABLE Track (
    TrackID      INT           IDENTITY PRIMARY KEY,
    TrackName    NVARCHAR(200) NOT NULL,
    DepartmentID INT           NOT NULL
        CONSTRAINT FK_Track_Department FOREIGN KEY REFERENCES Department(DepartmentID)
);
GO

-- 5. Intake
CREATE TABLE Intake (
    IntakeID   INT           IDENTITY PRIMARY KEY,
    IntakeName NVARCHAR(100) NOT NULL,
    StartDate  DATE,
    EndDate    DATE
);
GO

-- 6. Instructor
CREATE TABLE Instructor (
    InstructorID INT           IDENTITY PRIMARY KEY,
    UserID       INT           NOT NULL UNIQUE
        CONSTRAINT FK_Instructor_User FOREIGN KEY REFERENCES Users(UserID),
    Name         NVARCHAR(200),
    Email        NVARCHAR(200)
);
GO

-- 7. Student
CREATE TABLE Student (
    StudentID INT           IDENTITY PRIMARY KEY,
    UserID    INT           NOT NULL UNIQUE
        CONSTRAINT FK_Student_User     FOREIGN KEY REFERENCES Users(UserID),
    Name      NVARCHAR(200),
    Email     NVARCHAR(200) UNIQUE,
    BranchID  INT
        CONSTRAINT FK_Student_Branch   FOREIGN KEY REFERENCES Branch(BranchID),
    TrackID   INT
        CONSTRAINT FK_Student_Track    FOREIGN KEY REFERENCES Track(TrackID),
    IntakeID  INT
        CONSTRAINT FK_Student_Intake   FOREIGN KEY REFERENCES Intake(IntakeID)
);
GO

-- 8. Course
CREATE TABLE Course (
    CourseID    INT            IDENTITY PRIMARY KEY,
    CourseName  NVARCHAR(200)  NOT NULL,
    Description NVARCHAR(MAX),
    MaxDegree   INT,
    MinDegree   INT,
    CONSTRAINT CK_Course_Degree CHECK (MaxDegree >= MinDegree)
);
GO

-- 9. InstructorCourse  (one instructor per course per class/year)
CREATE TABLE InstructorCourse (
    InstructorCourseID INT IDENTITY PRIMARY KEY,
    InstructorID       INT NOT NULL
        CONSTRAINT FK_IC_Instructor FOREIGN KEY REFERENCES Instructor(InstructorID),
    CourseID           INT NOT NULL
        CONSTRAINT FK_IC_Course     FOREIGN KEY REFERENCES Course(CourseID),
    Year               INT NOT NULL,
    BranchID           INT
        CONSTRAINT FK_IC_Branch     FOREIGN KEY REFERENCES Branch(BranchID),
    TrackID            INT
        CONSTRAINT FK_IC_Track      FOREIGN KEY REFERENCES Track(TrackID),
    IntakeID           INT
        CONSTRAINT FK_IC_Intake     FOREIGN KEY REFERENCES Intake(IntakeID)
);
GO

-- 10. Question Pool
CREATE TABLE Question (
    QuestionID   INT           IDENTITY PRIMARY KEY,
    CourseID     INT           NOT NULL
        CONSTRAINT FK_Question_Course      FOREIGN KEY REFERENCES Course(CourseID),
    InstructorID INT           NOT NULL
        CONSTRAINT FK_Question_Instructor  FOREIGN KEY REFERENCES Instructor(InstructorID),
    QuestionText NVARCHAR(MAX) NOT NULL,
    QuestionType NVARCHAR(10)  NOT NULL
        CONSTRAINT CK_Question_Type CHECK (QuestionType IN ('MCQ','TF','Text'))
);
GO

-- 11. Choices  (MCQ & TF)
CREATE TABLE Choice (
    ChoiceID   INT           IDENTITY PRIMARY KEY,
    QuestionID INT           NOT NULL
        CONSTRAINT FK_Choice_Question FOREIGN KEY REFERENCES Question(QuestionID),
    ChoiceText NVARCHAR(500) NOT NULL,
    IsCorrect  BIT           NOT NULL DEFAULT 0
);
GO

-- 12. Text Accepted Answers
CREATE TABLE TextAnswer (
    TextAnswerID   INT           IDENTITY PRIMARY KEY,
    QuestionID     INT           NOT NULL
        CONSTRAINT FK_TextAnswer_Question FOREIGN KEY REFERENCES Question(QuestionID),
    AcceptedAnswer NVARCHAR(MAX) NOT NULL
);
GO

-- 13. Exam
CREATE TABLE Exam (
    ExamID           INT           IDENTITY PRIMARY KEY,
    CourseID         INT           NOT NULL
        CONSTRAINT FK_Exam_Course      FOREIGN KEY REFERENCES Course(CourseID),
    InstructorID     INT           NOT NULL
        CONSTRAINT FK_Exam_Instructor  FOREIGN KEY REFERENCES Instructor(InstructorID),
    IntakeID         INT
        CONSTRAINT FK_Exam_Intake      FOREIGN KEY REFERENCES Intake(IntakeID),
    BranchID         INT
        CONSTRAINT FK_Exam_Branch      FOREIGN KEY REFERENCES Branch(BranchID),
    TrackID          INT
        CONSTRAINT FK_Exam_Track       FOREIGN KEY REFERENCES Track(TrackID),
    ExamType         NVARCHAR(20)
        CONSTRAINT CK_Exam_Type CHECK (ExamType IN ('Exam','Corrective')),
    StartTime        DATETIME,
    EndTime          DATETIME,
    TotalTime        INT,
    Year             INT,
    AllowanceOptions NVARCHAR(MAX)
);
GO

-- 14. Exam Questions
CREATE TABLE ExamQuestion (
    ExamID     INT NOT NULL
        CONSTRAINT FK_EQ_Exam     FOREIGN KEY REFERENCES Exam(ExamID),
    QuestionID INT NOT NULL
        CONSTRAINT FK_EQ_Question FOREIGN KEY REFERENCES Question(QuestionID),
    Degree     INT NOT NULL DEFAULT 0,
    CONSTRAINT PK_ExamQuestion PRIMARY KEY (ExamID, QuestionID)
);
GO

-- 15. Student Exam  (enrollment / access control)
CREATE TABLE StudentExam (
    StudentID INT NOT NULL
        CONSTRAINT FK_SE_Student FOREIGN KEY REFERENCES Student(StudentID),
    ExamID    INT NOT NULL
        CONSTRAINT FK_SE_Exam    FOREIGN KEY REFERENCES Exam(ExamID),
    Status    NVARCHAR(50),
    CONSTRAINT PK_StudentExam PRIMARY KEY (StudentID, ExamID)
);
GO

-- 16. Student Answers
CREATE TABLE StudentAnswer (
    StudentID  INT           NOT NULL,
    ExamID     INT           NOT NULL,
    QuestionID INT           NOT NULL,
    ChoiceID   INT           NULL
        CONSTRAINT FK_SA_Choice    FOREIGN KEY REFERENCES Choice(ChoiceID),
    TextAnswer NVARCHAR(MAX) NULL,
    IsCorrect  BIT,
    Mark       INT           DEFAULT 0,
    CONSTRAINT PK_StudentAnswer  PRIMARY KEY (StudentID, ExamID, QuestionID),
    CONSTRAINT FK_SA_StudentExam FOREIGN KEY (StudentID, ExamID)
        REFERENCES StudentExam(StudentID, ExamID)
);
GO

-- 17. Final Result
CREATE TABLE Result (
    StudentID INT NOT NULL
        CONSTRAINT FK_Result_Student FOREIGN KEY REFERENCES Student(StudentID),
    CourseID  INT NOT NULL
        CONSTRAINT FK_Result_Course  FOREIGN KEY REFERENCES Course(CourseID),
    TotalMark INT NOT NULL DEFAULT 0,
    CONSTRAINT PK_Result PRIMARY KEY (StudentID, CourseID)
);
GO


-- ============================================================
-- SECTION 2: INDEXES
-- ============================================================

-- Student
CREATE NONCLUSTERED INDEX IX_Student_BranchID        ON Student         (BranchID);
CREATE NONCLUSTERED INDEX IX_Student_TrackID         ON Student         (TrackID);
CREATE NONCLUSTERED INDEX IX_Student_IntakeID        ON Student         (IntakeID);
CREATE NONCLUSTERED INDEX IX_Student_Name            ON Student         (Name);

-- Course
CREATE NONCLUSTERED INDEX IX_Course_CourseName       ON Course          (CourseName);

-- InstructorCourse
CREATE NONCLUSTERED INDEX IX_IC_InstructorID         ON InstructorCourse (InstructorID);
CREATE NONCLUSTERED INDEX IX_IC_CourseID             ON InstructorCourse (CourseID);
CREATE NONCLUSTERED INDEX IX_IC_Year                 ON InstructorCourse (Year);
CREATE NONCLUSTERED INDEX IX_IC_Composite            ON InstructorCourse (InstructorID, CourseID, Year);

-- Question
CREATE NONCLUSTERED INDEX IX_Question_CourseID       ON Question        (CourseID);
CREATE NONCLUSTERED INDEX IX_Question_InstructorID   ON Question        (InstructorID);
CREATE NONCLUSTERED INDEX IX_Question_Type           ON Question        (QuestionType);
CREATE NONCLUSTERED INDEX IX_Question_Course_Type    ON Question        (CourseID, QuestionType);

-- Choice
CREATE NONCLUSTERED INDEX IX_Choice_QuestionID       ON Choice          (QuestionID);
CREATE NONCLUSTERED INDEX IX_Choice_Correct          ON Choice          (QuestionID, IsCorrect);

-- TextAnswer
CREATE NONCLUSTERED INDEX IX_TextAnswer_QuestionID   ON TextAnswer      (QuestionID);

-- Exam
CREATE NONCLUSTERED INDEX IX_Exam_CourseID           ON Exam            (CourseID);
CREATE NONCLUSTERED INDEX IX_Exam_InstructorID       ON Exam            (InstructorID);

-- StudentAnswer
CREATE NONCLUSTERED INDEX IX_SA_StudentExam          ON StudentAnswer   (StudentID, ExamID);
CREATE NONCLUSTERED INDEX IX_SA_QuestionID           ON StudentAnswer   (QuestionID);
GO


-- ============================================================
-- SECTION 3: VIEWS
-- ============================================================

-- vw_StudentDetails: full student profile
CREATE OR ALTER VIEW vw_StudentDetails AS
SELECT
    s.StudentID,
    s.Name      AS StudentName,
    s.Email,
    b.BranchName,
    t.TrackName,
    i.IntakeName
FROM Student s
LEFT JOIN Branch b ON s.BranchID = b.BranchID
LEFT JOIN Track  t ON s.TrackID  = t.TrackID
LEFT JOIN Intake i ON s.IntakeID = i.IntakeID;
GO

-- vw_CourseInfo: courses with computed degree range
CREATE OR ALTER VIEW vw_CourseInfo AS
SELECT
    CourseID,
    CourseName,
    Description,
    MaxDegree,
    MinDegree,
    (MaxDegree - MinDegree) AS DegreeRange
FROM Course;
GO

-- vw_InstructorCourseDetails: assignments with all context
CREATE OR ALTER VIEW vw_InstructorCourseDetails AS
SELECT
    ic.InstructorCourseID,
    ic.InstructorID,
    ins.Name   AS InstructorName,
    ic.CourseID,
    c.CourseName,
    ic.Year,
    b.BranchName,
    t.TrackName,
    i.IntakeName
FROM InstructorCourse ic
JOIN  Instructor ins ON ic.InstructorID = ins.InstructorID
JOIN  Course      c  ON ic.CourseID     = c.CourseID
LEFT JOIN Branch  b  ON ic.BranchID     = b.BranchID
LEFT JOIN Track   t  ON ic.TrackID      = t.TrackID
LEFT JOIN Intake  i  ON ic.IntakeID     = i.IntakeID;
GO

-- vw_QuestionPool: question pool with readable names
CREATE OR ALTER VIEW vw_QuestionPool AS
SELECT
    q.QuestionID,
    q.QuestionText,
    q.QuestionType,
    c.CourseName,
    ins.Name AS InstructorName
FROM Question q
JOIN Course      c   ON q.CourseID     = c.CourseID
JOIN Instructor  ins ON q.InstructorID = ins.InstructorID;
GO

-- vw_QuestionChoices: MCQ/TF questions with all choices
CREATE OR ALTER VIEW vw_QuestionChoices AS
SELECT
    q.QuestionID,
    q.QuestionText,
    q.QuestionType,
    ch.ChoiceID,
    ch.ChoiceText,
    ch.IsCorrect,
    c.CourseName
FROM Question q
JOIN Choice ch ON q.QuestionID = ch.QuestionID
JOIN Course  c ON q.CourseID   = c.CourseID
WHERE q.QuestionType IN ('MCQ','TF');
GO

-- vw_TextQuestions: text questions with accepted answers
CREATE OR ALTER VIEW vw_TextQuestions AS
SELECT
    q.QuestionID,
    q.QuestionText,
    c.CourseName,
    ins.Name AS InstructorName,
    ta.AcceptedAnswer
FROM Question q
JOIN TextAnswer  ta  ON q.QuestionID  = ta.QuestionID
JOIN Course       c  ON q.CourseID    = c.CourseID
JOIN Instructor  ins ON q.InstructorID = ins.InstructorID
WHERE q.QuestionType = 'Text';
GO

-- vw_QuestionCountByCourseType: question pool stats
CREATE OR ALTER VIEW vw_QuestionCountByCourseType AS
SELECT
    c.CourseID,
    c.CourseName,
    q.QuestionType,
    COUNT(*) AS QuestionCount
FROM Question q
JOIN Course c ON q.CourseID = c.CourseID
GROUP BY c.CourseID, c.CourseName, q.QuestionType;
GO

-- vw_InstructorCourseList: all courses per instructor
CREATE OR ALTER VIEW vw_InstructorCourseList AS
SELECT
    ins.InstructorID,
    ins.Name AS InstructorName,
    c.CourseID,
    c.CourseName,
    ic.Year
FROM InstructorCourse ic
JOIN Instructor ins ON ic.InstructorID = ins.InstructorID
JOIN Course      c  ON ic.CourseID     = c.CourseID;
GO

-- vw_StudentsByTrack: student headcount per track/branch/intake
CREATE OR ALTER VIEW vw_StudentsByTrack AS
SELECT
    t.TrackName,
    b.BranchName,
    i.IntakeName,
    COUNT(s.StudentID) AS StudentCount
FROM Student s
LEFT JOIN Track  t ON s.TrackID  = t.TrackID
LEFT JOIN Branch b ON s.BranchID = b.BranchID
LEFT JOIN Intake i ON s.IntakeID = i.IntakeID
GROUP BY t.TrackName, b.BranchName, i.IntakeName;
GO

-- vw_ExamDetails: full exam info
CREATE OR ALTER VIEW vw_ExamDetails AS
SELECT
    e.ExamID,
    e.ExamType,
    e.Year,
    e.StartTime,
    e.EndTime,
    e.TotalTime,
    e.AllowanceOptions,
    c.CourseName,
    ins.Name  AS InstructorName,
    b.BranchName,
    t.TrackName,
    i.IntakeName
FROM Exam e
JOIN  Course      c   ON e.CourseID     = c.CourseID
JOIN  Instructor  ins ON e.InstructorID = ins.InstructorID
LEFT JOIN Branch  b   ON e.BranchID     = b.BranchID
LEFT JOIN Track   t   ON e.TrackID      = t.TrackID
LEFT JOIN Intake  i   ON e.IntakeID     = i.IntakeID;
GO

-- vw_StudentResults: per-student exam scores
CREATE OR ALTER VIEW vw_StudentResults AS
SELECT
    s.StudentID,
    s.Name     AS StudentName,
    c.CourseName,
    r.TotalMark,
    c.MinDegree,
    c.MaxDegree,
    CASE WHEN r.TotalMark >= c.MinDegree THEN 'Pass' ELSE 'Fail' END AS Status
FROM Result r
JOIN Student s ON r.StudentID = s.StudentID
JOIN Course  c ON r.CourseID  = c.CourseID;
GO


-- ============================================================
-- SECTION 4: SCALAR FUNCTIONS
-- ============================================================

-- fn_GetQuestionCount: count questions for a course (optionally by type)
CREATE OR ALTER FUNCTION fn_GetQuestionCount
(
    @CourseID     INT,
    @QuestionType NVARCHAR(20) = NULL
)
RETURNS INT
AS
BEGIN
    DECLARE @Count INT;
    SELECT @Count = COUNT(*)
    FROM Question
    WHERE CourseID = @CourseID
      AND (@QuestionType IS NULL OR QuestionType = @QuestionType);
    RETURN ISNULL(@Count, 0);
END;
GO

-- fn_GetCorrectChoice: return the correct choice text for MCQ/TF
CREATE OR ALTER FUNCTION fn_GetCorrectChoice (@QuestionID INT)
RETURNS NVARCHAR(500)
AS
BEGIN
    DECLARE @Answer NVARCHAR(500);
    SELECT TOP 1 @Answer = ChoiceText
    FROM Choice
    WHERE QuestionID = @QuestionID AND IsCorrect = 1;
    RETURN @Answer;
END;
GO

-- fn_IsAnswerCorrect: returns 1 if the chosen answer is correct
CREATE OR ALTER FUNCTION fn_IsAnswerCorrect
(
    @QuestionID INT,
    @ChoiceID   INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @Result BIT = 0;
    IF EXISTS (
        SELECT 1 FROM Choice
        WHERE QuestionID = @QuestionID
          AND ChoiceID   = @ChoiceID
          AND IsCorrect  = 1
    )
        SET @Result = 1;
    RETURN @Result;
END;
GO

-- fn_GetCourseName: return course name by ID
CREATE OR ALTER FUNCTION fn_GetCourseName (@CourseID INT)
RETURNS NVARCHAR(200)
AS
BEGIN
    DECLARE @Name NVARCHAR(200);
    SELECT @Name = CourseName FROM Course WHERE CourseID = @CourseID;
    RETURN @Name;
END;
GO

-- fn_CheckTextAnswer: 1 if student answer contains accepted answer (basic match)
CREATE OR ALTER FUNCTION fn_CheckTextAnswer
(
    @QuestionID    INT,
    @StudentAnswer NVARCHAR(MAX)
)
RETURNS BIT
AS
BEGIN
    DECLARE @Accepted NVARCHAR(MAX);
    DECLARE @Result   BIT = 0;
    SELECT TOP 1 @Accepted = AcceptedAnswer
    FROM TextAnswer
    WHERE QuestionID = @QuestionID;
    IF @Accepted IS NOT NULL
       AND CHARINDEX(LOWER(@Accepted), LOWER(@StudentAnswer)) > 0
        SET @Result = 1;
    RETURN @Result;
END;
GO

-- fn_GetCourseInstructor: return instructor name for a course in a year
CREATE OR ALTER FUNCTION fn_GetCourseInstructor
(
    @CourseID INT,
    @Year     INT
)
RETURNS NVARCHAR(200)
AS
BEGIN
    DECLARE @InstructorName NVARCHAR(200);
    SELECT TOP 1 @InstructorName = ins.Name
    FROM InstructorCourse ic
    JOIN Instructor ins ON ic.InstructorID = ins.InstructorID
    WHERE ic.CourseID = @CourseID AND ic.Year = @Year;
    RETURN @InstructorName;
END;
GO


-- ============================================================
-- SECTION 5: TABLE-VALUED FUNCTIONS
-- ============================================================

-- fn_GetCourseQuestions: questions for a course, optional type filter
CREATE OR ALTER FUNCTION fn_GetCourseQuestions
(
    @CourseID     INT,
    @QuestionType NVARCHAR(20) = NULL
)
RETURNS TABLE AS RETURN
(
    SELECT
        q.QuestionID,
        q.QuestionText,
        q.QuestionType,
        ins.Name AS InstructorName
    FROM Question q
    JOIN Instructor ins ON q.InstructorID = ins.InstructorID
    WHERE q.CourseID = @CourseID
      AND (@QuestionType IS NULL OR q.QuestionType = @QuestionType)
);
GO

-- fn_GetRandomQuestions: N random questions by course and type
CREATE OR ALTER FUNCTION fn_GetRandomQuestions
(
    @CourseID     INT,
    @QuestionType NVARCHAR(20),
    @Count        INT
)
RETURNS TABLE AS RETURN
(
    SELECT TOP (@Count)
        QuestionID,
        QuestionText,
        QuestionType
    FROM Question
    WHERE CourseID     = @CourseID
      AND QuestionType = @QuestionType
    ORDER BY NEWID()
);
GO

-- fn_GetQuestionChoices: all choices for a question
CREATE OR ALTER FUNCTION fn_GetQuestionChoices (@QuestionID INT)
RETURNS TABLE AS RETURN
(
    SELECT ChoiceID, ChoiceText, IsCorrect
    FROM   Choice
    WHERE  QuestionID = @QuestionID
);
GO

-- fn_GetStudentsByContext: students filtered by branch/track/intake
CREATE OR ALTER FUNCTION fn_GetStudentsByContext
(
    @BranchID INT = NULL,
    @TrackID  INT = NULL,
    @IntakeID INT = NULL
)
RETURNS TABLE AS RETURN
(
    SELECT
        s.StudentID,
        s.Name,
        s.Email,
        b.BranchName,
        t.TrackName,
        i.IntakeName
    FROM Student s
    LEFT JOIN Branch b ON s.BranchID = b.BranchID
    LEFT JOIN Track  t ON s.TrackID  = t.TrackID
    LEFT JOIN Intake i ON s.IntakeID = i.IntakeID
    WHERE (@BranchID IS NULL OR s.BranchID = @BranchID)
      AND (@TrackID  IS NULL OR s.TrackID  = @TrackID)
      AND (@IntakeID IS NULL OR s.IntakeID = @IntakeID)
);
GO


-- ============================================================
-- SECTION 6: STORED PROCEDURES
-- ============================================================

------------------------------------------------------------------------
-- STUDENT
------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_AddStudent
    @UserID   INT,
    @Name     NVARCHAR(200),
    @Email    NVARCHAR(200),
    @BranchID INT = NULL,
    @TrackID  INT = NULL,
    @IntakeID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM Student WHERE UserID = @UserID)
    BEGIN
        RAISERROR('A student with this UserID already exists.', 16, 1);
        RETURN;
    END
    INSERT INTO Student (UserID, Name, Email, BranchID, TrackID, IntakeID)
    VALUES (@UserID, @Name, @Email, @BranchID, @TrackID, @IntakeID);
    SELECT SCOPE_IDENTITY() AS NewStudentID;
END;
GO

CREATE OR ALTER PROCEDURE sp_UpdateStudent
    @StudentID INT,
    @Name      NVARCHAR(200) = NULL,
    @Email     NVARCHAR(200) = NULL,
    @BranchID  INT           = NULL,
    @TrackID   INT           = NULL,
    @IntakeID  INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Student WHERE StudentID = @StudentID)
    BEGIN
        RAISERROR('Student not found.', 16, 1);
        RETURN;
    END
    UPDATE Student
    SET
        Name     = ISNULL(@Name,     Name),
        Email    = ISNULL(@Email,    Email),
        BranchID = ISNULL(@BranchID, BranchID),
        TrackID  = ISNULL(@TrackID,  TrackID),
        IntakeID = ISNULL(@IntakeID, IntakeID)
    WHERE StudentID = @StudentID;
    PRINT 'Student updated successfully.';
END;
GO

CREATE OR ALTER PROCEDURE sp_DeleteStudent
    @StudentID INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Student WHERE StudentID = @StudentID)
    BEGIN
        RAISERROR('Student not found.', 16, 1);
        RETURN;
    END
    DELETE FROM Student WHERE StudentID = @StudentID;
    PRINT 'Student deleted successfully.';
END;
GO

CREATE OR ALTER PROCEDURE sp_SearchStudents
    @Name     NVARCHAR(200) = NULL,
    @BranchID INT           = NULL,
    @TrackID  INT           = NULL,
    @IntakeID INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        s.StudentID,
        s.Name,
        s.Email,
        b.BranchName,
        t.TrackName,
        i.IntakeName
    FROM Student s
    LEFT JOIN Branch b ON s.BranchID = b.BranchID
    LEFT JOIN Track  t ON s.TrackID  = t.TrackID
    LEFT JOIN Intake i ON s.IntakeID = i.IntakeID
    WHERE (@Name     IS NULL OR s.Name     LIKE '%' + @Name + '%')
      AND (@BranchID IS NULL OR s.BranchID = @BranchID)
      AND (@TrackID  IS NULL OR s.TrackID  = @TrackID)
      AND (@IntakeID IS NULL OR s.IntakeID = @IntakeID);
END;
GO

CREATE OR ALTER PROCEDURE sp_GetStudentByID
    @StudentID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM vw_StudentDetails WHERE StudentID = @StudentID;
END;
GO

------------------------------------------------------------------------
-- COURSE
------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_AddCourse
    @CourseName  NVARCHAR(200),
    @Description NVARCHAR(MAX) = NULL,
    @MaxDegree   INT,
    @MinDegree   INT
AS
BEGIN
    SET NOCOUNT ON;
    IF @MaxDegree < @MinDegree
    BEGIN
        RAISERROR('MaxDegree must be >= MinDegree.', 16, 1);
        RETURN;
    END
    INSERT INTO Course (CourseName, Description, MaxDegree, MinDegree)
    VALUES (@CourseName, @Description, @MaxDegree, @MinDegree);
    SELECT SCOPE_IDENTITY() AS NewCourseID;
END;
GO

CREATE OR ALTER PROCEDURE sp_UpdateCourse
    @CourseID    INT,
    @CourseName  NVARCHAR(200) = NULL,
    @Description NVARCHAR(MAX) = NULL,
    @MaxDegree   INT           = NULL,
    @MinDegree   INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Course WHERE CourseID = @CourseID)
    BEGIN
        RAISERROR('Course not found.', 16, 1);
        RETURN;
    END
    DECLARE @NewMax INT = ISNULL(@MaxDegree, (SELECT MaxDegree FROM Course WHERE CourseID = @CourseID));
    DECLARE @NewMin INT = ISNULL(@MinDegree, (SELECT MinDegree FROM Course WHERE CourseID = @CourseID));
    IF @NewMax < @NewMin
    BEGIN
        RAISERROR('MaxDegree must be >= MinDegree.', 16, 1);
        RETURN;
    END
    UPDATE Course
    SET
        CourseName  = ISNULL(@CourseName,  CourseName),
        Description = ISNULL(@Description, Description),
        MaxDegree   = @NewMax,
        MinDegree   = @NewMin
    WHERE CourseID = @CourseID;
    PRINT 'Course updated successfully.';
END;
GO

CREATE OR ALTER PROCEDURE sp_DeleteCourse
    @CourseID INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Course WHERE CourseID = @CourseID)
    BEGIN
        RAISERROR('Course not found.', 16, 1);
        RETURN;
    END
    -- trg_PreventCourseDeleteWithQuestions will block if questions exist
    DELETE FROM Course WHERE CourseID = @CourseID;
    PRINT 'Course deleted successfully.';
END;
GO

CREATE OR ALTER PROCEDURE sp_SearchCourses
    @CourseName NVARCHAR(200) = NULL,
    @MinDegree  INT           = NULL,
    @MaxDegree  INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *
    FROM Course
    WHERE (@CourseName IS NULL OR CourseName LIKE '%' + @CourseName + '%')
      AND (@MinDegree  IS NULL OR MinDegree  >= @MinDegree)
      AND (@MaxDegree  IS NULL OR MaxDegree  <= @MaxDegree);
END;
GO

------------------------------------------------------------------------
-- INSTRUCTOR-COURSE
------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_AssignInstructorToCourse
    @InstructorID INT,
    @CourseID     INT,
    @Year         INT,
    @BranchID     INT = NULL,
    @TrackID      INT = NULL,
    @IntakeID     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM InstructorCourse
        WHERE CourseID = @CourseID AND Year = @Year
          AND (BranchID = @BranchID OR (BranchID IS NULL AND @BranchID IS NULL))
          AND (TrackID  = @TrackID  OR (TrackID  IS NULL AND @TrackID  IS NULL))
          AND (IntakeID = @IntakeID OR (IntakeID IS NULL AND @IntakeID IS NULL))
    )
    BEGIN
        RAISERROR('This course already has an instructor for this class/year.', 16, 1);
        RETURN;
    END
    INSERT INTO InstructorCourse (InstructorID, CourseID, Year, BranchID, TrackID, IntakeID)
    VALUES (@InstructorID, @CourseID, @Year, @BranchID, @TrackID, @IntakeID);
    SELECT SCOPE_IDENTITY() AS NewInstructorCourseID;
END;
GO

CREATE OR ALTER PROCEDURE sp_UpdateInstructorCourse
    @InstructorCourseID INT,
    @InstructorID       INT = NULL,
    @BranchID           INT = NULL,
    @TrackID            INT = NULL,
    @IntakeID           INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM InstructorCourse WHERE InstructorCourseID = @InstructorCourseID)
    BEGIN
        RAISERROR('InstructorCourse record not found.', 16, 1);
        RETURN;
    END
    UPDATE InstructorCourse
    SET
        InstructorID = ISNULL(@InstructorID, InstructorID),
        BranchID     = ISNULL(@BranchID,     BranchID),
        TrackID      = ISNULL(@TrackID,      TrackID),
        IntakeID     = ISNULL(@IntakeID,     IntakeID)
    WHERE InstructorCourseID = @InstructorCourseID;
    PRINT 'Assignment updated successfully.';
END;
GO

CREATE OR ALTER PROCEDURE sp_RemoveInstructorCourse
    @InstructorCourseID INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM InstructorCourse WHERE InstructorCourseID = @InstructorCourseID)
    BEGIN
        RAISERROR('Assignment record not found.', 16, 1);
        RETURN;
    END
    DELETE FROM InstructorCourse WHERE InstructorCourseID = @InstructorCourseID;
    PRINT 'Assignment removed successfully.';
END;
GO

CREATE OR ALTER PROCEDURE sp_GetInstructorCourses
    @InstructorID INT,
    @Year         INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *
    FROM vw_InstructorCourseDetails
    WHERE InstructorID = @InstructorID
      AND (@Year IS NULL OR Year = @Year);
END;
GO

------------------------------------------------------------------------
-- QUESTION
------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_AddQuestion
    @CourseID     INT,
    @InstructorID INT,
    @QuestionText NVARCHAR(MAX),
    @QuestionType NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (
        SELECT 1 FROM InstructorCourse
        WHERE InstructorID = @InstructorID AND CourseID = @CourseID
    )
    BEGIN
        RAISERROR('Instructor is not assigned to this course.', 16, 1);
        RETURN;
    END
    IF @QuestionType NOT IN ('MCQ','TF','Text')
    BEGIN
        RAISERROR('Invalid question type. Use MCQ, TF, or Text.', 16, 1);
        RETURN;
    END
    INSERT INTO Question (CourseID, InstructorID, QuestionText, QuestionType)
    VALUES (@CourseID, @InstructorID, @QuestionText, @QuestionType);
    SELECT SCOPE_IDENTITY() AS NewQuestionID;
END;
GO

CREATE OR ALTER PROCEDURE sp_UpdateQuestion
    @QuestionID   INT,
    @InstructorID INT,
    @QuestionText NVARCHAR(MAX) = NULL,
    @QuestionType NVARCHAR(10)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (
        SELECT 1 FROM Question
        WHERE QuestionID = @QuestionID AND InstructorID = @InstructorID
    )
    BEGIN
        RAISERROR('Question not found or you do not own it.', 16, 1);
        RETURN;
    END
    IF @QuestionType IS NOT NULL AND @QuestionType NOT IN ('MCQ','TF','Text')
    BEGIN
        RAISERROR('Invalid question type.', 16, 1);
        RETURN;
    END
    UPDATE Question
    SET
        QuestionText = ISNULL(@QuestionText, QuestionText),
        QuestionType = ISNULL(@QuestionType, QuestionType)
    WHERE QuestionID = @QuestionID;
    PRINT 'Question updated successfully.';
END;
GO

CREATE OR ALTER PROCEDURE sp_DeleteQuestion
    @QuestionID   INT,
    @InstructorID INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (
        SELECT 1 FROM Question
        WHERE QuestionID = @QuestionID AND InstructorID = @InstructorID
    )
    BEGIN
        RAISERROR('Question not found or you do not own it.', 16, 1);
        RETURN;
    END
    DELETE FROM Choice     WHERE QuestionID = @QuestionID;
    DELETE FROM TextAnswer WHERE QuestionID = @QuestionID;
    DELETE FROM Question   WHERE QuestionID = @QuestionID;
    PRINT 'Question and all related data deleted.';
END;
GO

CREATE OR ALTER PROCEDURE sp_SearchQuestions
    @CourseID     INT,
    @QuestionType NVARCHAR(10)  = NULL,
    @Keyword      NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        q.QuestionID,
        q.QuestionText,
        q.QuestionType,
        ins.Name AS InstructorName
    FROM Question q
    JOIN Instructor ins ON q.InstructorID = ins.InstructorID
    WHERE q.CourseID = @CourseID
      AND (@QuestionType IS NULL OR q.QuestionType = @QuestionType)
      AND (@Keyword      IS NULL OR q.QuestionText LIKE '%' + @Keyword + '%');
END;
GO

CREATE OR ALTER PROCEDURE sp_GetRandomQuestionsForExam
    @CourseID  INT,
    @MCQCount  INT = 0,
    @TFCount   INT = 0,
    @TextCount INT = 0
AS
BEGIN
    SET NOCOUNT ON;
    IF @MCQCount > 0
    BEGIN
        SELECT TOP (@MCQCount) QuestionID, QuestionText, QuestionType
        FROM Question
        WHERE CourseID = @CourseID AND QuestionType = 'MCQ'
        ORDER BY NEWID();
    END
    IF @TFCount > 0
    BEGIN
        SELECT TOP (@TFCount) QuestionID, QuestionText, QuestionType
        FROM Question
        WHERE CourseID = @CourseID AND QuestionType = 'TF'
        ORDER BY NEWID();
    END
    IF @TextCount > 0
    BEGIN
        SELECT TOP (@TextCount) QuestionID, QuestionText, QuestionType
        FROM Question
        WHERE CourseID = @CourseID AND QuestionType = 'Text'
        ORDER BY NEWID();
    END
END;
GO

------------------------------------------------------------------------
-- CHOICE
------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_AddChoice
    @QuestionID INT,
    @ChoiceText NVARCHAR(500),
    @IsCorrect  BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (
        SELECT 1 FROM Question
        WHERE QuestionID = @QuestionID AND QuestionType IN ('MCQ','TF')
    )
    BEGIN
        RAISERROR('Question not found or is not of type MCQ/TF.', 16, 1);
        RETURN;
    END
    IF (SELECT QuestionType FROM Question WHERE QuestionID = @QuestionID) = 'TF'
       AND (SELECT COUNT(*) FROM Choice WHERE QuestionID = @QuestionID) >= 2
    BEGIN
        RAISERROR('True/False question can only have 2 choices.', 16, 1);
        RETURN;
    END
    IF @IsCorrect = 1
        UPDATE Choice SET IsCorrect = 0 WHERE QuestionID = @QuestionID;
    INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect)
    VALUES (@QuestionID, @ChoiceText, @IsCorrect);
    SELECT SCOPE_IDENTITY() AS NewChoiceID;
END;
GO

CREATE OR ALTER PROCEDURE sp_UpdateChoice
    @ChoiceID   INT,
    @ChoiceText NVARCHAR(500) = NULL,
    @IsCorrect  BIT           = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Choice WHERE ChoiceID = @ChoiceID)
    BEGIN
        RAISERROR('Choice not found.', 16, 1);
        RETURN;
    END
    IF @IsCorrect = 1
    BEGIN
        DECLARE @QID INT;
        SELECT @QID = QuestionID FROM Choice WHERE ChoiceID = @ChoiceID;
        UPDATE Choice SET IsCorrect = 0 WHERE QuestionID = @QID;
    END
    UPDATE Choice
    SET
        ChoiceText = ISNULL(@ChoiceText, ChoiceText),
        IsCorrect  = ISNULL(@IsCorrect,  IsCorrect)
    WHERE ChoiceID = @ChoiceID;
    PRINT 'Choice updated successfully.';
END;
GO

CREATE OR ALTER PROCEDURE sp_DeleteChoice
    @ChoiceID INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Choice WHERE ChoiceID = @ChoiceID)
    BEGIN
        RAISERROR('Choice not found.', 16, 1);
        RETURN;
    END
    DELETE FROM Choice WHERE ChoiceID = @ChoiceID;
    PRINT 'Choice deleted successfully.';
END;
GO

CREATE OR ALTER PROCEDURE sp_GetChoicesByQuestion
    @QuestionID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ChoiceID, ChoiceText, IsCorrect
    FROM   Choice
    WHERE  QuestionID = @QuestionID;
END;
GO

------------------------------------------------------------------------
-- TEXT ANSWER
------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE sp_AddTextAnswer
    @QuestionID     INT,
    @AcceptedAnswer NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (
        SELECT 1 FROM Question
        WHERE QuestionID = @QuestionID AND QuestionType = 'Text'
    )
    BEGIN
        RAISERROR('Question not found or is not of type Text.', 16, 1);
        RETURN;
    END
    INSERT INTO TextAnswer (QuestionID, AcceptedAnswer)
    VALUES (@QuestionID, @AcceptedAnswer);
    SELECT SCOPE_IDENTITY() AS NewTextAnswerID;
END;
GO

CREATE OR ALTER PROCEDURE sp_UpdateTextAnswer
    @TextAnswerID   INT,
    @AcceptedAnswer NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM TextAnswer WHERE TextAnswerID = @TextAnswerID)
    BEGIN
        RAISERROR('TextAnswer record not found.', 16, 1);
        RETURN;
    END
    UPDATE TextAnswer
    SET AcceptedAnswer = @AcceptedAnswer
    WHERE TextAnswerID = @TextAnswerID;
    PRINT 'Accepted answer updated successfully.';
END;
GO

CREATE OR ALTER PROCEDURE sp_DeleteTextAnswer
    @TextAnswerID INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM TextAnswer WHERE TextAnswerID = @TextAnswerID)
    BEGIN
        RAISERROR('TextAnswer record not found.', 16, 1);
        RETURN;
    END
    DELETE FROM TextAnswer WHERE TextAnswerID = @TextAnswerID;
    PRINT 'TextAnswer deleted successfully.';
END;
GO

CREATE OR ALTER PROCEDURE sp_GetTextAnswers
    @QuestionID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TextAnswerID, QuestionID, AcceptedAnswer
    FROM   TextAnswer
    WHERE  QuestionID = @QuestionID;
END;
GO

-- sp_ReviewTextAnswers: instructor review of student text responses
-- Requires StudentAnswer table (Exam module). Uses dynamic SQL
-- so this proc compiles safely even before that table is created.
CREATE OR ALTER PROCEDURE sp_ReviewTextAnswers
    @CourseID INT
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('StudentAnswer','U') IS NULL
    BEGIN
        RAISERROR('StudentAnswer table does not exist yet.', 16, 1);
        RETURN;
    END
    DECLARE @SQL NVARCHAR(MAX) = N'
        SELECT
            q.QuestionID,
            q.QuestionText,
            ta.AcceptedAnswer,
            sa.StudentID,
            sa.TextAnswer AS StudentAnswer,
            CASE
                WHEN CHARINDEX(LOWER(ta.AcceptedAnswer), LOWER(sa.TextAnswer)) > 0
                THEN ''Likely Valid''
                ELSE ''Needs Review''
            END AS MatchStatus
        FROM Question q
        JOIN TextAnswer   ta ON q.QuestionID = ta.QuestionID
        JOIN StudentAnswer sa ON q.QuestionID = sa.QuestionID
        WHERE q.CourseID = @CourseID AND q.QuestionType = ''Text''
        ORDER BY MatchStatus DESC;
    ';
    EXEC sp_executesql @SQL, N'@CourseID INT', @CourseID = @CourseID;
END;
GO


-- ============================================================
-- SECTION 7: TRIGGERS
-- ============================================================

-- Prevent deleting a course that still has questions
CREATE OR ALTER TRIGGER trg_PreventCourseDeleteWithQuestions
ON Course
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM Question q
        JOIN deleted d ON q.CourseID = d.CourseID
    )
    BEGIN
        RAISERROR('Cannot delete course: remove its questions first.', 16, 1);
        ROLLBACK;
        RETURN;
    END
    DELETE FROM Course WHERE CourseID IN (SELECT CourseID FROM deleted);
END;
GO

-- Enforce a single correct choice per question
CREATE OR ALTER TRIGGER trg_EnforceSingleCorrectChoice
ON Choice
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted WHERE IsCorrect = 1)
    BEGIN
        UPDATE Choice
        SET    IsCorrect = 0
        WHERE  QuestionID IN (SELECT QuestionID FROM inserted WHERE IsCorrect = 1)
          AND  ChoiceID  NOT IN (SELECT ChoiceID FROM inserted);
    END
END;
GO

-- Validate QuestionType on insert/update
CREATE OR ALTER TRIGGER trg_ValidateQuestionType
ON Question
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted
        WHERE QuestionType NOT IN ('MCQ','TF','Text')
    )
    BEGIN
        RAISERROR('Invalid QuestionType. Allowed: MCQ, TF, Text.', 16, 1);
        ROLLBACK;
    END
END;
GO

-- Auto-calculate IsCorrect on StudentAnswer after insert
CREATE OR ALTER TRIGGER trg_AutoGradeStudentAnswer
ON StudentAnswer
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    -- Grade MCQ/TF answers automatically
    UPDATE sa
    SET
        sa.IsCorrect = dbo.fn_IsAnswerCorrect(i.QuestionID, i.ChoiceID),
        sa.Mark      = CASE
                           WHEN dbo.fn_IsAnswerCorrect(i.QuestionID, i.ChoiceID) = 1
                           THEN ISNULL(eq.Degree, 0)
                           ELSE 0
                       END
    FROM StudentAnswer sa
    JOIN inserted      i  ON  sa.StudentID  = i.StudentID
                           AND sa.ExamID     = i.ExamID
                           AND sa.QuestionID = i.QuestionID
    JOIN ExamQuestion  eq ON  eq.ExamID     = i.ExamID
                           AND eq.QuestionID = i.QuestionID
    WHERE i.ChoiceID IS NOT NULL;   -- only auto-grade MCQ/TF
END;
GO

-- ============================================================
-- END OF SCRIPT
-- ============================================================