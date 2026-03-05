-- ============================================================
--  EXAMINATION SYSTEM DATABASE
--  Author  : Full Project
--  Version : Refactored
--  Sections:
--    1.  Database & Filegroups
--    2.  Tables
--    3.  Indexes
--    4.  Triggers
--    5.  Views
--    6.  Functions
--    7.  Stored Procedures
--    8.  Test Data
--    9.  SQL Server Logins & Permissions
--    10. Automated Daily Backup Job
--    11. Quick Test Queries
-- ============================================================


-- ============================================================
-- SECTION 1: DATABASE & FILEGROUPS
-- ============================================================

USE master;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'ExaminationSystemDB')
    BEGIN
        ALTER DATABASE ExaminationSystemDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
        DROP DATABASE ExaminationSystemDB;
    END
GO

CREATE  DATABASE ExaminationSystemDB
    ON PRIMARY
    (
        NAME     = 'ExamSys_Primary',
        FILENAME = 'C:\SQLData\ExamSys_Primary.mdf',
        SIZE     = 50MB,  MAXSIZE = 500MB,  FILEGROWTH = 10MB
        ),
    FILEGROUP FG_Users
        (
            NAME     = 'ExamSys_Users',
            FILENAME = 'C:\SQLData\ExamSys_Users.ndf',
            SIZE     = 20MB,  MAXSIZE = 200MB,  FILEGROWTH = 5MB
            ),
    FILEGROUP FG_Questions
        (
            NAME     = 'ExamSys_Questions',
            FILENAME = 'C:\SQLData\ExamSys_Questions.ndf',
            SIZE     = 50MB,  MAXSIZE = 1GB,    FILEGROWTH = 20MB
            ),
    FILEGROUP FG_Exams
        (
            NAME     = 'ExamSys_Exams',
            FILENAME = 'C:\SQLData\ExamSys_Exams.ndf',
            SIZE     = 50MB,  MAXSIZE = 1GB,    FILEGROWTH = 20MB
            ),
    FILEGROUP FG_Results
        (
            NAME     = 'ExamSys_Results',
            FILENAME = 'C:\SQLData\ExamSys_Results.ndf',
            SIZE     = 100MB, MAXSIZE = 2GB,    FILEGROWTH = 50MB
            )
    LOG ON
    (
        NAME     = 'ExamSys_Log',
        FILENAME = 'C:\SQLData\ExamSys_Log.ldf',
        SIZE     = 20MB,  MAXSIZE = 500MB,  FILEGROWTH = 10MB
        );
GO

USE ExaminationSystemDB;
GO


-- ============================================================
-- SECTION 2: TABLES
-- (created in FK-dependency order)
-- ============================================================

-- ---- Branch ------------------------------------------------
CREATE TABLE Branch (
                        BranchID   INT           IDENTITY(1,1) NOT NULL,
                        BranchName NVARCHAR(100) NOT NULL,
                        Location   NVARCHAR(200) NULL,
                        IsActive   BIT           NOT NULL CONSTRAINT DF_Branch_IsActive DEFAULT 1,
                        CONSTRAINT PK_Branch PRIMARY KEY CLUSTERED (BranchID),
                        CONSTRAINT UQ_Branch_Name UNIQUE (BranchName)
) ON FG_Users;
GO

-- ---- Track -------------------------------------------------
CREATE TABLE Track (
                       TrackID     INT           IDENTITY(1,1) NOT NULL,
                       BranchID    INT           NOT NULL,
                       TrackName   NVARCHAR(100) NOT NULL,
                       Description NVARCHAR(500) NULL,
                       IsActive    BIT           NOT NULL CONSTRAINT DF_Track_IsActive DEFAULT 1,
                       CONSTRAINT PK_Track        PRIMARY KEY CLUSTERED (TrackID),
                       CONSTRAINT FK_Track_Branch FOREIGN KEY (BranchID) REFERENCES Branch(BranchID)
) ON FG_Users;
GO

-- ---- Intake ------------------------------------------------
CREATE TABLE Intake (
                        IntakeID   INT          IDENTITY(1,1) NOT NULL,
                        IntakeName NVARCHAR(50) NOT NULL,
                        StartDate  DATE         NULL,
                        EndDate    DATE         NULL,
                        IsActive   BIT          NOT NULL CONSTRAINT DF_Intake_IsActive DEFAULT 1,
                        CONSTRAINT PK_Intake      PRIMARY KEY CLUSTERED (IntakeID),
                        CONSTRAINT UQ_Intake_Name UNIQUE (IntakeName)
) ON FG_Users;
GO

-- ---- SystemUser --------------------------------------------
CREATE TABLE SystemUser (
                            UserID       INT           IDENTITY(1,1) NOT NULL,
                            Username     NVARCHAR(50)  NOT NULL,
                            PasswordHash NVARCHAR(256) NOT NULL,
                            UserRole     NVARCHAR(20)  NOT NULL,
                            IsActive     BIT           NOT NULL CONSTRAINT DF_SystemUser_IsActive  DEFAULT 1,
                            CreatedAt    DATETIME      NOT NULL CONSTRAINT DF_SystemUser_CreatedAt DEFAULT GETDATE(),
                            CONSTRAINT PK_SystemUser      PRIMARY KEY CLUSTERED (UserID),
                            CONSTRAINT UQ_SystemUser_Name UNIQUE (Username),
                            CONSTRAINT CK_SystemUser_Role CHECK (UserRole IN ('Admin','TrainingManager','Instructor','Student'))
) ON FG_Users;
GO

-- ---- Instructor --------------------------------------------
CREATE TABLE Instructor (
                            InstructorID      INT           IDENTITY(1,1) NOT NULL,
                            UserID            INT           NOT NULL,
                            FirstName         NVARCHAR(50)  NOT NULL,
                            LastName          NVARCHAR(50)  NOT NULL,
                            Email             NVARCHAR(100) NOT NULL,
                            Phone             NVARCHAR(20)  NULL,
                            IsTrainingManager BIT           NOT NULL CONSTRAINT DF_Instructor_IsTM DEFAULT 0,
                            HireDate          DATE          NULL,
                            CONSTRAINT PK_Instructor        PRIMARY KEY CLUSTERED (InstructorID),
                            CONSTRAINT FK_Instructor_User   FOREIGN KEY (UserID) REFERENCES SystemUser(UserID),
                            CONSTRAINT UQ_Instructor_UserID UNIQUE (UserID),
                            CONSTRAINT UQ_Instructor_Email  UNIQUE (Email)
) ON FG_Users;
GO

-- ---- Student -----------------------------------------------
CREATE TABLE Student (
                         StudentID   INT           IDENTITY(1,1) NOT NULL,
                         UserID      INT           NOT NULL,
                         IntakeID    INT           NOT NULL,
                         BranchID    INT           NOT NULL,
                         TrackID     INT           NOT NULL,
                         FirstName   NVARCHAR(50)  NOT NULL,
                         LastName    NVARCHAR(50)  NOT NULL,
                         Email       NVARCHAR(100) NOT NULL,
                         Phone       NVARCHAR(20)  NULL,
                         DateOfBirth DATE          NULL,
                         NationalID  NVARCHAR(20)  NULL,
                         IsActive    BIT           NOT NULL CONSTRAINT DF_Student_IsActive DEFAULT 1,
                         CONSTRAINT PK_Student        PRIMARY KEY CLUSTERED (StudentID),
                         CONSTRAINT FK_Student_User   FOREIGN KEY (UserID)   REFERENCES SystemUser(UserID),
                         CONSTRAINT FK_Student_Intake FOREIGN KEY (IntakeID) REFERENCES Intake(IntakeID),
                         CONSTRAINT FK_Student_Branch FOREIGN KEY (BranchID) REFERENCES Branch(BranchID),
                         CONSTRAINT FK_Student_Track  FOREIGN KEY (TrackID)  REFERENCES Track(TrackID),
                         CONSTRAINT UQ_Student_UserID UNIQUE (UserID),
                         CONSTRAINT UQ_Student_Email  UNIQUE (Email)
) ON FG_Users;
GO

-- ---- Course ------------------------------------------------
CREATE TABLE Course (
                        CourseID    INT           IDENTITY(1,1) NOT NULL,
                        CourseName  NVARCHAR(100) NOT NULL,
                        Description NVARCHAR(500) NULL,
                        MaxDegree   DECIMAL(6,2)  NOT NULL,
                        MinDegree   DECIMAL(6,2)  NOT NULL,
                        IsActive    BIT           NOT NULL CONSTRAINT DF_Course_IsActive DEFAULT 1,
                        CONSTRAINT PK_Course         PRIMARY KEY CLUSTERED (CourseID),
                        CONSTRAINT CK_Course_Degrees CHECK (MinDegree >= 0 AND MaxDegree > MinDegree)
) ON FG_Questions;
GO

-- ---- InstructorCourse (one instructor per course-class-year)
CREATE TABLE InstructorCourse (
                                  AssignmentID INT IDENTITY(1,1) NOT NULL,
                                  InstructorID INT NOT NULL,
                                  CourseID     INT NOT NULL,
                                  IntakeID     INT NOT NULL,
                                  BranchID     INT NOT NULL,
                                  TrackID      INT NOT NULL,
                                  AcademicYear INT NOT NULL,
                                  CONSTRAINT PK_InstructorCourse PRIMARY KEY CLUSTERED (AssignmentID),
                                  CONSTRAINT FK_IC_Instructor    FOREIGN KEY (InstructorID) REFERENCES Instructor(InstructorID),
                                  CONSTRAINT FK_IC_Course        FOREIGN KEY (CourseID)     REFERENCES Course(CourseID),
                                  CONSTRAINT FK_IC_Intake        FOREIGN KEY (IntakeID)     REFERENCES Intake(IntakeID),
                                  CONSTRAINT FK_IC_Branch        FOREIGN KEY (BranchID)     REFERENCES Branch(BranchID),
                                  CONSTRAINT FK_IC_Track         FOREIGN KEY (TrackID)      REFERENCES Track(TrackID),
                                  CONSTRAINT UQ_IC_Unique        UNIQUE (InstructorID, CourseID, IntakeID, BranchID, TrackID, AcademicYear)
) ON FG_Users;
GO

-- ---- Question ----------------------------------------------
CREATE TABLE Question (
                          QuestionID      INT            IDENTITY(1,1) NOT NULL,
                          CourseID        INT            NOT NULL,
                          InstructorID    INT            NOT NULL,
                          QuestionType    NVARCHAR(20)   NOT NULL,
                          QuestionText    NVARCHAR(MAX)  NOT NULL,
                          ModelAnswer     NVARCHAR(MAX)  NULL,
                          DifficultyLevel NVARCHAR(10)   NOT NULL CONSTRAINT DF_Question_Difficulty DEFAULT 'Medium',
                          IsActive        BIT            NOT NULL CONSTRAINT DF_Question_IsActive   DEFAULT 1,
                          CreatedAt       DATETIME       NOT NULL CONSTRAINT DF_Question_CreatedAt  DEFAULT GETDATE(),
                          CONSTRAINT PK_Question        PRIMARY KEY CLUSTERED (QuestionID),
                          CONSTRAINT FK_Question_Course FOREIGN KEY (CourseID)     REFERENCES Course(CourseID),
                          CONSTRAINT FK_Question_Inst   FOREIGN KEY (InstructorID) REFERENCES Instructor(InstructorID),
                          CONSTRAINT CK_Question_Type   CHECK (QuestionType    IN ('MCQ','TrueFalse','Text')),
                          CONSTRAINT CK_Question_Diff   CHECK (DifficultyLevel IN ('Easy','Medium','Hard'))
) ON FG_Questions;
GO

-- ---- QuestionChoice (MCQ & TrueFalse) ----------------------
CREATE TABLE QuestionChoice (
                                ChoiceID    INT           IDENTITY(1,1) NOT NULL,
                                QuestionID  INT           NOT NULL,
                                ChoiceText  NVARCHAR(500) NOT NULL,
                                IsCorrect   BIT           NOT NULL CONSTRAINT DF_Choice_IsCorrect  DEFAULT 0,
                                ChoiceOrder TINYINT       NOT NULL CONSTRAINT DF_Choice_Order       DEFAULT 1,
                                CONSTRAINT PK_QuestionChoice  PRIMARY KEY CLUSTERED (ChoiceID),
                                CONSTRAINT FK_Choice_Question FOREIGN KEY (QuestionID)
                                    REFERENCES Question(QuestionID) ON DELETE CASCADE
) ON FG_Questions;
GO

-- ---- Exam --------------------------------------------------
CREATE TABLE Exam (
                      ExamID           INT           IDENTITY(1,1) NOT NULL,
                      CourseID         INT           NOT NULL,
                      InstructorID     INT           NOT NULL,
                      IntakeID         INT           NOT NULL,
                      BranchID         INT           NOT NULL,
                      TrackID          INT           NOT NULL,
                      AcademicYear     INT           NOT NULL,
                      ExamType         NVARCHAR(20)  NOT NULL CONSTRAINT DF_Exam_Type      DEFAULT 'Exam',
                      ExamTitle        NVARCHAR(200) NOT NULL,
                      StartTime        DATETIME      NOT NULL,
                      EndTime          DATETIME      NOT NULL,
                      TotalTimeMin     INT           NOT NULL,
                      TotalDegree      DECIMAL(6,2)  NOT NULL CONSTRAINT DF_Exam_Degree    DEFAULT 0,
                      AllowanceOptions NVARCHAR(200) NULL,
                      IsPublished      BIT           NOT NULL CONSTRAINT DF_Exam_Published DEFAULT 0,
                      CreatedAt        DATETIME      NOT NULL CONSTRAINT DF_Exam_CreatedAt DEFAULT GETDATE(),
                      CONSTRAINT PK_Exam            PRIMARY KEY CLUSTERED (ExamID),
                      CONSTRAINT FK_Exam_Course     FOREIGN KEY (CourseID)     REFERENCES Course(CourseID),
                      CONSTRAINT FK_Exam_Instructor FOREIGN KEY (InstructorID) REFERENCES Instructor(InstructorID),
                      CONSTRAINT FK_Exam_Intake     FOREIGN KEY (IntakeID)     REFERENCES Intake(IntakeID),
                      CONSTRAINT FK_Exam_Branch     FOREIGN KEY (BranchID)     REFERENCES Branch(BranchID),
                      CONSTRAINT FK_Exam_Track      FOREIGN KEY (TrackID)      REFERENCES Track(TrackID),
                      CONSTRAINT CK_Exam_Type       CHECK (ExamType IN ('Exam','Corrective')),
                      CONSTRAINT CK_Exam_Times      CHECK (EndTime > StartTime),
                      CONSTRAINT CK_Exam_Degree     CHECK (TotalDegree >= 0)
) ON FG_Exams;
GO

-- ---- ExamQuestion ------------------------------------------
CREATE TABLE ExamQuestion (
                              ExamQuestionID INT          IDENTITY(1,1) NOT NULL,
                              ExamID         INT          NOT NULL,
                              QuestionID     INT          NOT NULL,
                              Degree         DECIMAL(5,2) NOT NULL,
                              OrderNum       INT          NOT NULL CONSTRAINT DF_EQ_Order DEFAULT 1,
                              CONSTRAINT PK_ExamQuestion    PRIMARY KEY CLUSTERED (ExamQuestionID),
                              CONSTRAINT FK_EQ_Exam         FOREIGN KEY (ExamID)     REFERENCES Exam(ExamID)     ON DELETE CASCADE,
                              CONSTRAINT FK_EQ_Question     FOREIGN KEY (QuestionID) REFERENCES Question(QuestionID),
                              CONSTRAINT UQ_EQ_ExamQuestion UNIQUE (ExamID, QuestionID),
                              CONSTRAINT CK_EQ_Degree       CHECK (Degree > 0)
) ON FG_Exams;
GO

-- ---- StudentExam -------------------------------------------
CREATE TABLE StudentExam (
                             StudentExamID INT          IDENTITY(1,1) NOT NULL,
                             StudentID     INT          NOT NULL,
                             ExamID        INT          NOT NULL,
                             ExamDate      DATE         NULL,
                             ActualStart   DATETIME     NULL,
                             ActualEnd     DATETIME     NULL,
                             TotalScore    DECIMAL(6,2) NULL,
                             IsPassed      BIT          NULL,
                             Status        NVARCHAR(20) NOT NULL CONSTRAINT DF_SE_Status DEFAULT 'Scheduled',
                             CONSTRAINT PK_StudentExam    PRIMARY KEY CLUSTERED (StudentExamID),
                             CONSTRAINT FK_SE_Student     FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
                             CONSTRAINT FK_SE_Exam        FOREIGN KEY (ExamID)    REFERENCES Exam(ExamID),
                             CONSTRAINT UQ_SE_StudentExam UNIQUE (StudentID, ExamID),
                             CONSTRAINT CK_SE_Status      CHECK (Status IN ('Scheduled','InProgress','Submitted','Graded'))
) ON FG_Results;
GO

-- ---- StudentAnswer -----------------------------------------
CREATE TABLE StudentAnswer (
                               AnswerID         INT           IDENTITY(1,1) NOT NULL,
                               StudentExamID    INT           NOT NULL,
                               ExamQuestionID   INT           NOT NULL,
                               ChoiceID         INT           NULL,
                               TextAnswer       NVARCHAR(MAX) NULL,
                               IsCorrect        BIT           NULL,
                               AwardedDegree    DECIMAL(5,2)  NOT NULL CONSTRAINT DF_SA_AwardedDegree DEFAULT 0,
                               InstructorReview NVARCHAR(MAX) NULL,
                               ReviewedBy       INT           NULL,
                               ReviewedAt       DATETIME      NULL,
                               CONSTRAINT PK_StudentAnswer    PRIMARY KEY CLUSTERED (AnswerID),
                               CONSTRAINT FK_SA_StudentExam   FOREIGN KEY (StudentExamID)  REFERENCES StudentExam(StudentExamID) ON DELETE CASCADE,
                               CONSTRAINT FK_SA_ExamQuestion  FOREIGN KEY (ExamQuestionID) REFERENCES ExamQuestion(ExamQuestionID),
                               CONSTRAINT FK_SA_Choice        FOREIGN KEY (ChoiceID)       REFERENCES QuestionChoice(ChoiceID),
                               CONSTRAINT FK_SA_Reviewer      FOREIGN KEY (ReviewedBy)     REFERENCES Instructor(InstructorID),
                               CONSTRAINT UQ_SA_Unique        UNIQUE (StudentExamID, ExamQuestionID)
) ON FG_Results;
GO


-- ============================================================
-- SECTION 3: INDEXES
-- ============================================================

-- Question
CREATE NONCLUSTERED INDEX IX_Question_CourseID     ON Question(CourseID);
CREATE NONCLUSTERED INDEX IX_Question_InstructorID ON Question(InstructorID);
CREATE NONCLUSTERED INDEX IX_Question_Type         ON Question(QuestionType);
CREATE NONCLUSTERED INDEX IX_Question_Active       ON Question(IsActive);

-- Exam
CREATE NONCLUSTERED INDEX IX_Exam_CourseID          ON Exam(CourseID);
CREATE NONCLUSTERED INDEX IX_Exam_InstructorID      ON Exam(InstructorID);
CREATE NONCLUSTERED INDEX IX_Exam_IntakeBranchTrack ON Exam(IntakeID, BranchID, TrackID);
CREATE NONCLUSTERED INDEX IX_Exam_Published         ON Exam(IsPublished);

-- StudentExam
CREATE NONCLUSTERED INDEX IX_SE_StudentID ON StudentExam(StudentID);
CREATE NONCLUSTERED INDEX IX_SE_ExamID    ON StudentExam(ExamID);
CREATE NONCLUSTERED INDEX IX_SE_Status    ON StudentExam(Status);

-- StudentAnswer
CREATE NONCLUSTERED INDEX IX_SA_StudentExamID  ON StudentAnswer(StudentExamID);
CREATE NONCLUSTERED INDEX IX_SA_ExamQuestionID ON StudentAnswer(ExamQuestionID);

-- Student
CREATE NONCLUSTERED INDEX IX_Student_IntakeBT ON Student(IntakeID, BranchID, TrackID);
CREATE NONCLUSTERED INDEX IX_Student_Name     ON Student(LastName, FirstName);

-- InstructorCourse
CREATE NONCLUSTERED INDEX IX_IC_CourseYear ON InstructorCourse(CourseID, AcademicYear);
GO


-- ============================================================
-- SECTION 4: TRIGGERS
-- ============================================================

-- Trigger: Prevent ExamQuestion total degree from exceeding Course MaxDegree
CREATE OR ALTER TRIGGER trg_CheckExamTotalDegree
    ON ExamQuestion
    AFTER INSERT, UPDATE
    AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM (
                 SELECT eq.ExamID,
                        SUM(eq.Degree) AS TotalDeg,
                        c.MaxDegree
                 FROM ExamQuestion eq
                          JOIN Exam   e ON eq.ExamID   = e.ExamID
                          JOIN Course c ON e.CourseID  = c.CourseID
                 WHERE eq.ExamID IN (SELECT DISTINCT ExamID FROM inserted)
                 GROUP BY eq.ExamID, c.MaxDegree
             ) x
        WHERE TotalDeg > MaxDegree
    )
        BEGIN
            RAISERROR('Total exam degree exceeds the course MaxDegree.', 16, 1);
            ROLLBACK TRANSACTION;
        END
END;
GO

-- Trigger: Instructor can only add questions to courses they are assigned to
CREATE OR ALTER TRIGGER trg_Question_InstructorCourse
    ON Question
    AFTER INSERT, UPDATE
    AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1 FROM InstructorCourse ic
            WHERE ic.InstructorID = i.InstructorID
              AND ic.CourseID     = i.CourseID
        )
    )
        BEGIN
            RAISERROR('Instructor can only add questions to courses they are assigned to teach.', 16, 1);
            ROLLBACK TRANSACTION;
        END
END;
GO

-- Trigger: Auto-grade MCQ/TrueFalse answers immediately on insert
CREATE OR ALTER TRIGGER trg_AutoGradeAnswer
    ON StudentAnswer
    AFTER INSERT
    AS
BEGIN
    SET NOCOUNT ON;
    UPDATE sa
    SET
        sa.IsCorrect     = CASE WHEN qc.IsCorrect = 1 THEN 1 ELSE 0 END,
        sa.AwardedDegree = CASE WHEN qc.IsCorrect = 1 THEN eq.Degree ELSE 0 END
    FROM StudentAnswer  sa
             JOIN inserted       i  ON sa.AnswerID       = i.AnswerID
             JOIN ExamQuestion   eq ON sa.ExamQuestionID = eq.ExamQuestionID
             JOIN Question       q  ON eq.QuestionID     = q.QuestionID
             LEFT JOIN QuestionChoice qc ON sa.ChoiceID  = qc.ChoiceID
    WHERE q.QuestionType IN ('MCQ','TrueFalse')
      AND sa.ChoiceID IS NOT NULL;
END;
GO

-- Trigger: Recalculate StudentExam total score after any answer is updated
CREATE OR ALTER TRIGGER trg_UpdateStudentExamScore
    ON StudentAnswer
    AFTER UPDATE
    AS
BEGIN
    SET NOCOUNT ON;
    UPDATE se
    SET
        se.TotalScore = (
            SELECT ISNULL(SUM(sa2.AwardedDegree), 0)
            FROM StudentAnswer sa2
            WHERE sa2.StudentExamID = se.StudentExamID
        ),
        se.IsPassed = CASE
                          WHEN (
                                   SELECT ISNULL(SUM(sa2.AwardedDegree), 0)
                                   FROM StudentAnswer sa2
                                   WHERE sa2.StudentExamID = se.StudentExamID
                               ) >= (
                                   SELECT c.MinDegree
                                   FROM Exam e
                                            JOIN Course c ON e.CourseID = c.CourseID
                                   WHERE e.ExamID = se.ExamID
                               )
                              THEN 1 ELSE 0
            END,
        se.Status = 'Graded'
    FROM StudentExam se
    WHERE se.StudentExamID IN (SELECT DISTINCT StudentExamID FROM inserted);
END;
GO


-- ============================================================
-- SECTION 5: VIEWS
-- ============================================================

-- Full student profile
CREATE OR ALTER VIEW vw_StudentFullInfo AS
SELECT
    s.StudentID,
    s.FirstName + ' ' + s.LastName AS StudentName,
    s.Email,
    s.Phone,
    s.DateOfBirth,
    s.NationalID,
    i.IntakeName,
    b.BranchName,
    t.TrackName,
    u.Username,
    s.IsActive
FROM Student    s
         JOIN Intake     i ON s.IntakeID = i.IntakeID
         JOIN Branch     b ON s.BranchID = b.BranchID
         JOIN Track      t ON s.TrackID  = t.TrackID
         JOIN SystemUser u ON s.UserID   = u.UserID;
GO

-- Course-to-instructor assignments
CREATE OR ALTER VIEW vw_CourseInstructors AS
SELECT
    ic.AssignmentID,
    c.CourseName,
    ins.FirstName + ' ' + ins.LastName AS InstructorName,
    ins.IsTrainingManager,
    i.IntakeName,
    b.BranchName,
    t.TrackName,
    ic.AcademicYear
FROM InstructorCourse ic
         JOIN Course      c   ON ic.CourseID     = c.CourseID
         JOIN Instructor  ins ON ic.InstructorID = ins.InstructorID
         JOIN Intake      i   ON ic.IntakeID     = i.IntakeID
         JOIN Branch      b   ON ic.BranchID     = b.BranchID
         JOIN Track       t   ON ic.TrackID      = t.TrackID;
GO

-- Exam overview with question and student counts
CREATE OR ALTER VIEW vw_ExamOverview AS
SELECT
    e.ExamID,
    e.ExamTitle,
    e.ExamType,
    c.CourseName,
    ins.FirstName + ' ' + ins.LastName AS InstructorName,
    i.IntakeName,
    b.BranchName,
    t.TrackName,
    e.AcademicYear,
    e.StartTime,
    e.EndTime,
    e.TotalTimeMin,
    e.TotalDegree,
    e.IsPublished,
    (SELECT COUNT(*) FROM ExamQuestion eq WHERE eq.ExamID = e.ExamID) AS QuestionCount,
    (SELECT COUNT(*) FROM StudentExam  se WHERE se.ExamID = e.ExamID) AS EnrolledStudents
FROM Exam        e
         JOIN Course      c   ON e.CourseID     = c.CourseID
         JOIN Instructor  ins ON e.InstructorID = ins.InstructorID
         JOIN Intake      i   ON e.IntakeID     = i.IntakeID
         JOIN Branch      b   ON e.BranchID     = b.BranchID
         JOIN Track       t   ON e.TrackID      = t.TrackID;
GO

-- Student exam results
CREATE OR ALTER VIEW vw_StudentResults AS
SELECT
    se.StudentExamID,
    s.FirstName + ' ' + s.LastName AS StudentName,
    s.Email,
    e.ExamTitle,
    c.CourseName,
    i.IntakeName,
    b.BranchName,
    t.TrackName,
    se.ExamDate,
    se.TotalScore,
    e.TotalDegree,
    c.MinDegree,
    se.IsPassed,
    se.Status
FROM StudentExam se
         JOIN Student  s  ON se.StudentID = s.StudentID
         JOIN Exam     e  ON se.ExamID    = e.ExamID
         JOIN Course   c  ON e.CourseID   = c.CourseID
         JOIN Intake   i  ON s.IntakeID   = i.IntakeID
         JOIN Branch   b  ON s.BranchID   = b.BranchID
         JOIN Track    t  ON s.TrackID    = t.TrackID;
GO

-- Question pool per course
CREATE OR ALTER VIEW vw_QuestionPool AS
SELECT
    q.QuestionID,
    q.CourseID,
    c.CourseName,
    q.QuestionType,
    q.QuestionText,
    q.ModelAnswer,
    q.DifficultyLevel,
    ins.FirstName + ' ' + ins.LastName AS CreatedBy,
    q.IsActive,
    q.CreatedAt,
    (SELECT COUNT(*) FROM QuestionChoice qc WHERE qc.QuestionID = q.QuestionID) AS ChoiceCount
FROM Question    q
         JOIN Course      c   ON q.CourseID     = c.CourseID
         JOIN Instructor  ins ON q.InstructorID = ins.InstructorID;
GO

-- Text answers pending instructor review
CREATE OR ALTER VIEW vw_PendingTextReview AS
SELECT
    sa.AnswerID,
    s.FirstName + ' ' + s.LastName AS StudentName,
    e.ExamTitle,
    c.CourseName,
    q.QuestionText,
    q.ModelAnswer,
    sa.TextAnswer,
    sa.AwardedDegree,
    eq.Degree AS MaxDegree,
    sa.InstructorReview
FROM StudentAnswer sa
         JOIN StudentExam  se ON sa.StudentExamID   = se.StudentExamID
         JOIN Student      s  ON se.StudentID       = s.StudentID
         JOIN ExamQuestion eq ON sa.ExamQuestionID  = eq.ExamQuestionID
         JOIN Exam         e  ON eq.ExamID          = e.ExamID
         JOIN Course       c  ON e.CourseID         = c.CourseID
         JOIN Question     q  ON eq.QuestionID      = q.QuestionID
WHERE q.QuestionType     = 'Text'
  AND sa.InstructorReview IS NULL;
GO


-- ============================================================
-- SECTION 6: FUNCTIONS
-- ============================================================

-- Scalar: Get a student's latest graded score for a course
CREATE OR ALTER FUNCTION dbo.fn_GetStudentCourseScore
(
    @StudentID INT,
    @CourseID  INT
)
    RETURNS DECIMAL(6,2)
AS
BEGIN
    DECLARE @Score DECIMAL(6,2);
    SELECT TOP 1 @Score = se.TotalScore
    FROM StudentExam se
             JOIN Exam e ON se.ExamID = e.ExamID
    WHERE se.StudentID = @StudentID
      AND e.CourseID   = @CourseID
      AND se.Status    = 'Graded'
    ORDER BY se.StudentExamID DESC;
    RETURN ISNULL(@Score, 0);
END;
GO

-- Scalar: Basic keyword match between student answer and model answer
-- Returns 1 if the first 20 chars of the model answer appear in the student answer
CREATE OR ALTER FUNCTION dbo.fn_CheckTextAnswer
(
    @StudentAnswer NVARCHAR(MAX),
    @ModelAnswer   NVARCHAR(MAX)
)
    RETURNS BIT
AS
BEGIN
    IF LEN(LTRIM(RTRIM(@StudentAnswer))) = 0
        RETURN 0;
    IF CHARINDEX(LOWER(LEFT(@ModelAnswer, 20)), LOWER(@StudentAnswer)) > 0
        RETURN 1;
    RETURN 0;
END;
GO

-- Scalar: Count questions of a given type in an exam
CREATE OR ALTER FUNCTION dbo.fn_ExamQuestionCountByType
(
    @ExamID       INT,
    @QuestionType NVARCHAR(20)
)
    RETURNS INT
AS
BEGIN
    DECLARE @Count INT;
    SELECT @Count = COUNT(*)
    FROM ExamQuestion eq
             JOIN Question q ON eq.QuestionID = q.QuestionID
    WHERE eq.ExamID      = @ExamID
      AND q.QuestionType = @QuestionType;
    RETURN ISNULL(@Count, 0);
END;
GO

-- TVF: Get all questions for a course with optional type/difficulty filters
CREATE OR ALTER FUNCTION dbo.fn_GetCourseQuestions
(
    @CourseID       INT,
    @QuestionType   NVARCHAR(20) = NULL,
    @Difficulty     NVARCHAR(10) = NULL
)
    RETURNS TABLE AS RETURN
        (
        SELECT
            q.QuestionID,
            q.QuestionType,
            q.QuestionText,
            q.ModelAnswer,
            q.DifficultyLevel,
            ins.FirstName + ' ' + ins.LastName AS InstructorName,
            (SELECT COUNT(*) FROM QuestionChoice qc WHERE qc.QuestionID = q.QuestionID) AS ChoiceCount
        FROM Question   q
                 JOIN Instructor ins ON q.InstructorID = ins.InstructorID
        WHERE q.CourseID  = @CourseID
          AND q.IsActive  = 1
          AND (@QuestionType IS NULL OR q.QuestionType   = @QuestionType)
          AND (@Difficulty   IS NULL OR q.DifficultyLevel = @Difficulty)
        );
GO


-- ============================================================
-- SECTION 7: STORED PROCEDURES
-- ============================================================

------------------------------------------------------------------------
-- ADMIN / TRAINING MANAGER
------------------------------------------------------------------------

-- Add Branch
CREATE OR ALTER PROCEDURE sp_AddBranch
    @BranchName NVARCHAR(100),
    @Location   NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM Branch WHERE BranchName = @BranchName)
        THROW 50001, 'Branch name already exists.', 1;
    INSERT INTO Branch (BranchName, Location) VALUES (@BranchName, @Location);
    SELECT SCOPE_IDENTITY() AS NewBranchID;
END;
GO

-- Add Track
CREATE OR ALTER PROCEDURE sp_AddTrack
    @BranchID    INT,
    @TrackName   NVARCHAR(100),
    @Description NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Branch WHERE BranchID = @BranchID AND IsActive = 1)
        THROW 50002, 'Branch not found or is inactive.', 1;
    INSERT INTO Track (BranchID, TrackName, Description) VALUES (@BranchID, @TrackName, @Description);
    SELECT SCOPE_IDENTITY() AS NewTrackID;
END;
GO

-- Add Intake
CREATE OR ALTER PROCEDURE usp_AddIntake
    @IntakeName NVARCHAR(50),
    @StartDate  DATE = NULL,
    @EndDate    DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Intake (IntakeName, StartDate, EndDate) VALUES (@IntakeName, @StartDate, @EndDate);
    SELECT SCOPE_IDENTITY() AS NewIntakeID;
END;
GO

-- Add Instructor
-- Add Intake
CREATE OR ALTER PROCEDURE usp_AddIntake
    @IntakeName NVARCHAR(50),
    @StartDate  DATE = NULL,
    @EndDate    DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Intake (IntakeName, StartDate, EndDate) VALUES (@IntakeName, @StartDate, @EndDate);
    SELECT SCOPE_IDENTITY() AS NewIntakeID;
END;
GO

-- (creates SystemUser + Instructor in one transaction)
CREATE OR ALTER PROCEDURE sp_AddInstructor
    @Username          NVARCHAR(50),
    @PasswordHash      NVARCHAR(256),
    @FirstName         NVARCHAR(50),
    @LastName          NVARCHAR(50),
    @Email             NVARCHAR(100),
    @Phone             NVARCHAR(20) = NULL,
    @IsTrainingManager BIT          = 0
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO SystemUser (Username, PasswordHash, UserRole)
        VALUES (
                   @Username,
                   @PasswordHash,
                   CASE WHEN @IsTrainingManager = 1 THEN 'TrainingManager' ELSE 'Instructor' END
               );
        DECLARE @NewUserID INT = SCOPE_IDENTITY();

        INSERT INTO Instructor (UserID, FirstName, LastName, Email, Phone, IsTrainingManager)
        VALUES (@NewUserID, @FirstName, @LastName, @Email, @Phone, @IsTrainingManager);

        SELECT SCOPE_IDENTITY() AS NewInstructorID;
        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO

------------------------------------------------------------------------
-- INSTRUCTOR – EXAM MANAGEMENT
------------------------------------------------------------------------

-- Create Exam
CREATE OR ALTER PROCEDURE sp_CreateExam
    @CourseID         INT,
    @InstructorID     INT,
    @IntakeID         INT,
    @BranchID         INT,
    @TrackID          INT,
    @AcademicYear     INT,
    @ExamType         NVARCHAR(20),
    @ExamTitle        NVARCHAR(200),
    @StartTime        DATETIME,
    @EndTime          DATETIME,
    @TotalTimeMin     INT,
    @AllowanceOptions NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (
        SELECT 1 FROM InstructorCourse
        WHERE InstructorID = @InstructorID AND CourseID     = @CourseID
          AND IntakeID     = @IntakeID     AND BranchID     = @BranchID
          AND TrackID      = @TrackID      AND AcademicYear = @AcademicYear
    )
        THROW 50030, 'Instructor is not assigned to this course/class.', 1;

    INSERT INTO Exam (CourseID, InstructorID, IntakeID, BranchID, TrackID, AcademicYear,
                      ExamType, ExamTitle, StartTime, EndTime, TotalTimeMin, AllowanceOptions)
    VALUES (@CourseID, @InstructorID, @IntakeID, @BranchID, @TrackID, @AcademicYear,
            @ExamType, @ExamTitle, @StartTime, @EndTime, @TotalTimeMin, @AllowanceOptions);
    SELECT SCOPE_IDENTITY() AS NewExamID;
END;
GO

-- Add Question to Exam (manual selection)
CREATE OR ALTER PROCEDURE sp_AddQuestionToExam
    @ExamID     INT,
    @QuestionID INT,
    @Degree     DECIMAL(5,2),
    @OrderNum   INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentTotal DECIMAL(6,2);
    DECLARE @MaxDegree    DECIMAL(6,2);

    SELECT @CurrentTotal = ISNULL(SUM(eq.Degree), 0)
    FROM ExamQuestion eq
    WHERE eq.ExamID = @ExamID;

    SELECT @MaxDegree = c.MaxDegree
    FROM Exam e
             JOIN Course c ON e.CourseID = c.CourseID
    WHERE e.ExamID = @ExamID;

    IF @CurrentTotal + @Degree > @MaxDegree
        THROW 50031, 'Adding this question would exceed the course MaxDegree.', 1;

    INSERT INTO ExamQuestion (ExamID, QuestionID, Degree, OrderNum)
    VALUES (@ExamID, @QuestionID, @Degree, @OrderNum);

    -- Keep TotalDegree in sync
    UPDATE Exam
    SET TotalDegree = @CurrentTotal + @Degree
    WHERE ExamID = @ExamID;

    SELECT SCOPE_IDENTITY() AS NewExamQuestionID;
END;
GO

-- Auto-select random questions for an exam
CREATE OR ALTER PROCEDURE sp_AutoSelectExamQuestions
    @ExamID        INT,
    @InstructorID  INT,
    @MCQCount      INT          = 0,
    @TFCount       INT          = 0,
    @TextCount     INT          = 0,
    @DegreePerMCQ  DECIMAL(5,2) = 1,
    @DegreePerTF   DECIMAL(5,2) = 1,
    @DegreePerText DECIMAL(5,2) = 5
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Exam WHERE ExamID = @ExamID AND InstructorID = @InstructorID)
        THROW 50040, 'You do not own this exam.', 1;

    DECLARE @CourseID INT;
    SELECT @CourseID = CourseID FROM Exam WHERE ExamID = @ExamID;

    -- Clear previous auto-selection
    DELETE FROM ExamQuestion WHERE ExamID = @ExamID;
    UPDATE Exam SET TotalDegree = 0 WHERE ExamID = @ExamID;

    -- Insert MCQ questions
    IF @MCQCount > 0
        INSERT INTO ExamQuestion (ExamID, QuestionID, Degree, OrderNum)
        SELECT TOP (@MCQCount)
            @ExamID, QuestionID, @DegreePerMCQ,
            ROW_NUMBER() OVER (ORDER BY NEWID())
        FROM Question
        WHERE CourseID    = @CourseID
          AND QuestionType = 'MCQ'
          AND IsActive    = 1
        ORDER BY NEWID();

    -- Insert TrueFalse questions
    IF @TFCount > 0
        INSERT INTO ExamQuestion (ExamID, QuestionID, Degree, OrderNum)
        SELECT TOP (@TFCount)
            @ExamID, QuestionID, @DegreePerTF,
            @MCQCount + ROW_NUMBER() OVER (ORDER BY NEWID())
        FROM Question
        WHERE CourseID    = @CourseID
          AND QuestionType = 'TrueFalse'
          AND IsActive    = 1
          AND QuestionID NOT IN (SELECT QuestionID FROM ExamQuestion WHERE ExamID = @ExamID)
        ORDER BY NEWID();

    -- Insert Text questions
    IF @TextCount > 0
        INSERT INTO ExamQuestion (ExamID, QuestionID, Degree, OrderNum)
        SELECT TOP (@TextCount)
            @ExamID, QuestionID, @DegreePerText,
            @MCQCount + @TFCount + ROW_NUMBER() OVER (ORDER BY NEWID())
        FROM Question
        WHERE CourseID    = @CourseID
          AND QuestionType = 'Text'
          AND IsActive    = 1
          AND QuestionID NOT IN (SELECT QuestionID FROM ExamQuestion WHERE ExamID = @ExamID)
        ORDER BY NEWID();

    -- Sync TotalDegree
    UPDATE Exam
    SET TotalDegree = (SELECT ISNULL(SUM(Degree), 0) FROM ExamQuestion WHERE ExamID = @ExamID)
    WHERE ExamID = @ExamID;

    SELECT COUNT(*) AS QuestionsAdded FROM ExamQuestion WHERE ExamID = @ExamID;
END;
GO

-- Enroll student in exam
CREATE OR ALTER PROCEDURE sp_EnrollStudentInExam
    @StudentID INT,
    @ExamID    INT,
    @ExamDate  DATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM StudentExam WHERE StudentID = @StudentID AND ExamID = @ExamID)
        THROW 50050, 'Student is already enrolled in this exam.', 1;

    INSERT INTO StudentExam (StudentID, ExamID, ExamDate, Status)
    VALUES (@StudentID, @ExamID, @ExamDate, 'Scheduled');
    SELECT SCOPE_IDENTITY() AS NewStudentExamID;
END;
GO

------------------------------------------------------------------------
-- STUDENT – EXAM SUBMISSION
------------------------------------------------------------------------

-- Submit a single answer (upsert)
CREATE OR ALTER PROCEDURE sp_SubmitStudentAnswer
    @StudentExamID  INT,
    @ExamQuestionID INT,
    @ChoiceID       INT           = NULL,
    @TextAnswer     NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (
        SELECT 1 FROM StudentExam
        WHERE StudentExamID = @StudentExamID
          AND Status IN ('Scheduled','InProgress')
    )
        THROW 50060, 'Exam is not available for submission.', 1;

    IF EXISTS (
        SELECT 1 FROM StudentAnswer
        WHERE StudentExamID = @StudentExamID AND ExamQuestionID = @ExamQuestionID
    )
        UPDATE StudentAnswer
        SET ChoiceID = @ChoiceID, TextAnswer = @TextAnswer, IsCorrect = NULL, AwardedDegree = 0
        WHERE StudentExamID = @StudentExamID AND ExamQuestionID = @ExamQuestionID;
    ELSE
        INSERT INTO StudentAnswer (StudentExamID, ExamQuestionID, ChoiceID, TextAnswer)
        VALUES (@StudentExamID, @ExamQuestionID, @ChoiceID, @TextAnswer);

    -- Mark exam as in-progress on first answer
    UPDATE StudentExam
    SET Status = 'InProgress', ActualStart = ISNULL(ActualStart, GETDATE())
    WHERE StudentExamID = @StudentExamID AND Status = 'Scheduled';
END;
GO

-- Finalize / submit exam
CREATE OR ALTER PROCEDURE sp_FinalizeStudentExam
@StudentExamID INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE StudentExam
    SET Status = 'Submitted', ActualEnd = GETDATE()
    WHERE StudentExamID = @StudentExamID
      AND Status IN ('Scheduled','InProgress');
END;
GO

------------------------------------------------------------------------
-- INSTRUCTOR – GRADING
------------------------------------------------------------------------

-- Manually review a text answer
CREATE OR ALTER PROCEDURE sp_ReviewTextAnswer
    @AnswerID      INT,
    @InstructorID  INT,
    @AwardedDegree DECIMAL(5,2),
    @Review        NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Verify the instructor owns the exam this answer belongs to
    IF NOT EXISTS (
        SELECT 1
        FROM StudentAnswer sa
                 JOIN ExamQuestion eq ON sa.ExamQuestionID = eq.ExamQuestionID
                 JOIN Exam         e  ON eq.ExamID         = e.ExamID
        WHERE sa.AnswerID      = @AnswerID
          AND e.InstructorID   = @InstructorID
    )
        THROW 50070, 'You are not authorised to review this answer.', 1;

    -- Degree cannot exceed the question's allocated degree
    DECLARE @MaxDegree DECIMAL(5,2);
    SELECT @MaxDegree = eq.Degree
    FROM StudentAnswer sa
             JOIN ExamQuestion eq ON sa.ExamQuestionID = eq.ExamQuestionID
    WHERE sa.AnswerID = @AnswerID;

    IF @AwardedDegree > @MaxDegree
        THROW 50071, 'Awarded degree cannot exceed the question maximum degree.', 1;

    UPDATE StudentAnswer
    SET
        AwardedDegree    = @AwardedDegree,
        IsCorrect        = CASE WHEN @AwardedDegree > 0 THEN 1 ELSE 0 END,
        InstructorReview = @Review,
        ReviewedBy       = @InstructorID,
        ReviewedAt       = GETDATE()
    WHERE AnswerID = @AnswerID;

    -- Recalculate the student's total score
    DECLARE @StudentExamID INT;
    SELECT @StudentExamID = StudentExamID FROM StudentAnswer WHERE AnswerID = @AnswerID;
    EXEC sp_RecalcStudentScore @StudentExamID;
END;
GO

-- Recalculate and persist student's total score
CREATE OR ALTER PROCEDURE sp_RecalcStudentScore
@StudentExamID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Total     DECIMAL(6,2);
    DECLARE @MinDegree DECIMAL(6,2);

    SELECT @Total = ISNULL(SUM(AwardedDegree), 0)
    FROM StudentAnswer
    WHERE StudentExamID = @StudentExamID;

    SELECT @MinDegree = c.MinDegree
    FROM StudentExam se
             JOIN Exam   e ON se.ExamID   = e.ExamID
             JOIN Course c ON e.CourseID  = c.CourseID
    WHERE se.StudentExamID = @StudentExamID;

    UPDATE StudentExam
    SET
        TotalScore = @Total,
        IsPassed   = CASE WHEN @Total >= @MinDegree THEN 1 ELSE 0 END,
        Status     = 'Graded'
    WHERE StudentExamID = @StudentExamID;
END;
GO

-- Get student exam result with per-question breakdown
CREATE OR ALTER PROCEDURE sp_GetStudentExamResult
@StudentExamID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Summary header
    SELECT * FROM vw_StudentResults WHERE StudentExamID = @StudentExamID;

    -- Per-question detail
    SELECT
        eq.OrderNum,
        q.QuestionType,
        q.QuestionText,
        q.ModelAnswer,
        sa.TextAnswer,
        qc.ChoiceText  AS SelectedChoice,
        sa.IsCorrect,
        sa.AwardedDegree,
        eq.Degree      AS MaxDegree,
        sa.InstructorReview
    FROM ExamQuestion    eq
             JOIN Question        q  ON eq.QuestionID     = q.QuestionID
             LEFT JOIN StudentAnswer sa ON sa.ExamQuestionID = eq.ExamQuestionID
        AND sa.StudentExamID  = @StudentExamID
             LEFT JOIN QuestionChoice qc ON sa.ChoiceID      = qc.ChoiceID
    WHERE eq.ExamID = (SELECT ExamID FROM StudentExam WHERE StudentExamID = @StudentExamID)
    ORDER BY eq.OrderNum;
END;
GO


-- ============================================================
-- SECTION 8: TEST DATA
-- ============================================================

-- Branches
EXEC sp_AddBranch 'Cairo Branch',      'Cairo, Egypt';
EXEC sp_AddBranch 'Alexandria Branch', 'Alexandria, Egypt';
EXEC sp_AddBranch 'Giza Branch',       'Giza, Egypt';

-- Tracks
EXEC sp_AddTrack 1, 'Software Development', 'Full-stack web development';
EXEC sp_AddTrack 1, 'Data Science',         'Machine learning and analytics';
EXEC sp_AddTrack 2, 'Cybersecurity',        'Network and application security';
EXEC sp_AddTrack 3, 'Mobile Development',   'iOS and Android development';

-- Intakes
EXEC sp_AddIntake 'Intake 44', '2023-09-01', '2024-06-30';
EXEC sp_AddIntake 'Intake 45', '2024-03-01', '2024-12-31';
EXEC sp_AddIntake 'Intake 46', '2024-09-01', '2025-06-30';

-- Courses (direct INSERT — no procedure wraps Course)
INSERT INTO Course (CourseName, Description, MaxDegree, MinDegree) VALUES
                                                                       ('SQL Server',      'Database design and T-SQL programming', 100, 50),
                                                                       ('C# Programming',  'Object-oriented programming with C#',   100, 50),
                                                                       ('HTML & CSS',      'Web frontend fundamentals',             100, 50),
                                                                       ('Python Basics',   'Introduction to Python programming',    100, 50),
                                                                       ('Data Analysis',   'Data analysis with Python and pandas',  100, 50);

-- Instructors (InstructorID 1 = Training Manager)
EXEC sp_AddInstructor 'tm.ahmed',   'hashed_pass_1', 'Ahmed',  'Salah',   'ahmed.salah@iti.gov.eg',   '01001112233', 1;
EXEC sp_AddInstructor 'ins.sara',   'hashed_pass_2', 'Sara',   'Mohamed', 'sara.mohamed@iti.gov.eg',  '01112223344', 0;
EXEC sp_AddInstructor 'ins.khaled', 'hashed_pass_3', 'Khaled', 'Hassan',  'khaled.hassan@iti.gov.eg', '01223334455', 0;
EXEC sp_AddInstructor 'ins.mona',   'hashed_pass_4', 'Mona',   'Ali',     'mona.ali@iti.gov.eg',      '01334445566', 0;

-- Assign instructors to courses
-- (InstructorID, CourseID, IntakeID, BranchID, TrackID, AcademicYear)
EXEC sp_AssignInstructorToCourse 1, 1, 1, 1, 1, 2024;  -- Ahmed  -> SQL Server
EXEC sp_AssignInstructorToCourse 2, 2, 1, 1, 1, 2024;  -- Sara   -> C#
EXEC sp_AssignInstructorToCourse 3, 3, 1, 1, 1, 2024;  -- Khaled -> HTML & CSS
EXEC sp_AssignInstructorToCourse 1, 4, 2, 1, 2, 2024;  -- Ahmed  -> Python, Intake45, DS track
EXEC sp_AssignInstructorToCourse 4, 5, 2, 2, 3, 2024;  -- Mona   -> Data Analysis, Alex, Cyber

-- Students
EXEC sp_AddStudent 'std.ali',    'hashed_s1', 1,1,1, 'Ali',    'Ibrahim', 'ali.ibrahim@student.com',    '01500001111', '2001-05-10', '28501012345678';
EXEC sp_AddStudent 'std.nour',   'hashed_s2', 1,1,1, 'Nour',   'Mahmoud', 'nour.mahmoud@student.com',   '01500002222', '2002-03-20', '28703022345679';
EXEC sp_AddStudent 'std.omar',   'hashed_s3', 1,1,1, 'Omar',   'Youssef', 'omar.youssef@student.com',   '01500003333', '2001-11-05', '28611032345680';
EXEC sp_AddStudent 'std.rania',  'hashed_s4', 1,1,1, 'Rania',  'Tarek',   'rania.tarek@student.com',    '01500004444', '2003-07-15', '28907042345681';
EXEC sp_AddStudent 'std.hassan', 'hashed_s5', 2,1,2, 'Hassan', 'Farouk',  'hassan.farouk@student.com',  '01500005555', '2000-12-01', '28012052345682';
EXEC sp_AddStudent 'std.aya',    'hashed_s6', 2,2,3, 'Aya',    'Saber',   'aya.saber@student.com',      '01500006666', '2002-08-25', '28208062345683';

-- Questions for SQL Server (CourseID=1, InstructorID=1)
DECLARE @Q1 INT, @Q2 INT, @Q3 INT, @Q4 INT, @Q5 INT, @Q6 INT, @Q7 INT, @Q8 INT;

EXEC sp_AddQuestion 1, 1, 'MCQ', 'Which SQL statement retrieves data from a database?', NULL, 'Easy';
SET @Q1 = IDENT_CURRENT('Question');
EXEC sp_AddQuestionChoice @Q1, 'SELECT', 1, 1;
EXEC sp_AddQuestionChoice @Q1, 'INSERT', 0, 2;
EXEC sp_AddQuestionChoice @Q1, 'UPDATE', 0, 3;
EXEC sp_AddQuestionChoice @Q1, 'DELETE', 0, 4;

EXEC sp_AddQuestion 1, 1, 'MCQ', 'What does the PRIMARY KEY constraint do?', NULL, 'Easy';
SET @Q2 = IDENT_CURRENT('Question');
EXEC sp_AddQuestionChoice @Q2, 'Allows NULL values',          0, 1;
EXEC sp_AddQuestionChoice @Q2, 'Uniquely identifies each row', 1, 2;
EXEC sp_AddQuestionChoice @Q2, 'Links two tables',             0, 3;
EXEC sp_AddQuestionChoice @Q2, 'Creates an index only',        0, 4;

EXEC sp_AddQuestion 1, 1, 'TrueFalse', 'A FOREIGN KEY can reference a non-primary key column.', NULL, 'Medium';
SET @Q3 = IDENT_CURRENT('Question');
EXEC sp_AddQuestionChoice @Q3, 'True',  1, 1;
EXEC sp_AddQuestionChoice @Q3, 'False', 0, 2;

EXEC sp_AddQuestion 1, 1, 'TrueFalse', 'A table can have multiple PRIMARY KEY constraints.', NULL, 'Easy';
SET @Q4 = IDENT_CURRENT('Question');
EXEC sp_AddQuestionChoice @Q4, 'True',  0, 1;
EXEC sp_AddQuestionChoice @Q4, 'False', 1, 2;

EXEC sp_AddQuestion 1, 1, 'Text',
     'Explain the difference between WHERE and HAVING in SQL.',
     'WHERE filters rows before grouping; HAVING filters groups after GROUP BY.',
     'Medium';
SET @Q5 = IDENT_CURRENT('Question');

EXEC sp_AddQuestion 1, 1, 'Text',
     'What is normalization? Explain 1NF, 2NF, and 3NF.',
     'Normalization organises data to reduce redundancy. 1NF: atomic values; 2NF: full functional dependency; 3NF: no transitive dependency.',
     'Hard';
SET @Q6 = IDENT_CURRENT('Question');

EXEC sp_AddQuestion 1, 1, 'MCQ', 'Which JOIN returns all rows from both tables?', NULL, 'Medium';
SET @Q7 = IDENT_CURRENT('Question');
EXEC sp_AddQuestionChoice @Q7, 'INNER JOIN',      0, 1;
EXEC sp_AddQuestionChoice @Q7, 'LEFT JOIN',       0, 2;
EXEC sp_AddQuestionChoice @Q7, 'FULL OUTER JOIN', 1, 3;
EXEC sp_AddQuestionChoice @Q7, 'CROSS JOIN',      0, 4;

EXEC sp_AddQuestion 1, 1, 'MCQ', 'What is the default sort order of ORDER BY?', NULL, 'Easy';
SET @Q8 = IDENT_CURRENT('Question');
EXEC sp_AddQuestionChoice @Q8, 'DESC', 0, 1;
EXEC sp_AddQuestionChoice @Q8, 'ASC',  1, 2;
EXEC sp_AddQuestionChoice @Q8, 'RAND', 0, 3;
EXEC sp_AddQuestionChoice @Q8, 'NONE', 0, 4;

-- Create exam (CourseID=1, InstructorID=1, IntakeID=1, BranchID=1, TrackID=1, Year=2024)
DECLARE @ExamID INT;
EXEC sp_CreateExam 1, 1, 1, 1, 1, 2024, 'Exam', 'SQL Server Midterm Exam',
     '2024-11-15 09:00', '2024-11-15 11:00', 120, NULL;
SET @ExamID = IDENT_CURRENT('Exam');

-- Add questions to exam with degrees
EXEC sp_AddQuestionToExam @ExamID, @Q1, 10, 1;
EXEC sp_AddQuestionToExam @ExamID, @Q2, 10, 2;
EXEC sp_AddQuestionToExam @ExamID, @Q3, 10, 3;
EXEC sp_AddQuestionToExam @ExamID, @Q4, 10, 4;
EXEC sp_AddQuestionToExam @ExamID, @Q5, 30, 5;
EXEC sp_AddQuestionToExam @ExamID, @Q7, 10, 6;
EXEC sp_AddQuestionToExam @ExamID, @Q8, 10, 7;

-- Publish exam
UPDATE Exam SET IsPublished = 1 WHERE ExamID = @ExamID;

-- Enroll students
DECLARE @SE1 INT, @SE2 INT, @SE3 INT;
EXEC sp_EnrollStudentInExam 1, @ExamID, '2024-11-15'; SET @SE1 = IDENT_CURRENT('StudentExam');
EXEC sp_EnrollStudentInExam 2, @ExamID, '2024-11-15'; SET @SE2 = IDENT_CURRENT('StudentExam');
EXEC sp_EnrollStudentInExam 3, @ExamID, '2024-11-15'; SET @SE3 = IDENT_CURRENT('StudentExam');

-- Resolve ExamQuestionIDs for answer submission
DECLARE @EQ1 INT, @EQ2 INT, @EQ3 INT, @EQ4 INT, @EQ5 INT, @EQ6 INT, @EQ7 INT;
SELECT @EQ1 = ExamQuestionID FROM ExamQuestion WHERE ExamID = @ExamID AND QuestionID = @Q1;
SELECT @EQ2 = ExamQuestionID FROM ExamQuestion WHERE ExamID = @ExamID AND QuestionID = @Q2;
SELECT @EQ3 = ExamQuestionID FROM ExamQuestion WHERE ExamID = @ExamID AND QuestionID = @Q3;
SELECT @EQ4 = ExamQuestionID FROM ExamQuestion WHERE ExamID = @ExamID AND QuestionID = @Q4;
SELECT @EQ5 = ExamQuestionID FROM ExamQuestion WHERE ExamID = @ExamID AND QuestionID = @Q5;
SELECT @EQ6 = ExamQuestionID FROM ExamQuestion WHERE ExamID = @ExamID AND QuestionID = @Q7;
SELECT @EQ7 = ExamQuestionID FROM ExamQuestion WHERE ExamID = @ExamID AND QuestionID = @Q8;

-- Student 1: all correct
EXEC sp_SubmitStudentAnswer @SE1, @EQ1, 1,  NULL;
EXEC sp_SubmitStudentAnswer @SE1, @EQ2, 6,  NULL;
EXEC sp_SubmitStudentAnswer @SE1, @EQ3, 9,  NULL;
EXEC sp_SubmitStudentAnswer @SE1, @EQ4, 12, NULL;
EXEC sp_SubmitStudentAnswer @SE1, @EQ5, NULL, 'WHERE filters rows before grouping; HAVING filters after GROUP BY on aggregated results.';
EXEC sp_SubmitStudentAnswer @SE1, @EQ6, 15, NULL;
EXEC sp_SubmitStudentAnswer @SE1, @EQ7, 18, NULL;
EXEC sp_FinalizeStudentExam @SE1;

-- Instructor reviews Student 1 text answer
DECLARE @TextAnswerID INT;
SELECT @TextAnswerID = AnswerID
FROM StudentAnswer
WHERE StudentExamID = @SE1 AND ExamQuestionID = @EQ5;
EXEC sp_ReviewTextAnswer @TextAnswerID, 1, 28, 'Good answer — demonstrates understanding of both clauses.';

EXEC sp_RecalcStudentScore @SE1;

-- Student 2: some wrong
EXEC sp_SubmitStudentAnswer @SE2, @EQ1, 2,  NULL;   -- wrong
EXEC sp_SubmitStudentAnswer @SE2, @EQ2, 6,  NULL;   -- correct
EXEC sp_SubmitStudentAnswer @SE2, @EQ3, 9,  NULL;   -- correct
EXEC sp_SubmitStudentAnswer @SE2, @EQ4, 11, NULL;   -- wrong
EXEC sp_SubmitStudentAnswer @SE2, @EQ5, NULL, 'WHERE is used to filter, HAVING is also for filtering.';
EXEC sp_SubmitStudentAnswer @SE2, @EQ6, 14, NULL;   -- wrong
EXEC sp_SubmitStudentAnswer @SE2, @EQ7, 18, NULL;   -- correct
EXEC sp_FinalizeStudentExam @SE2;
EXEC sp_RecalcStudentScore @SE2;
GO


-- ============================================================
-- SECTION 9: SQL SERVER LOGINS & PERMISSIONS
-- ============================================================

USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'AdminLogin')
CREATE LOGIN AdminLogin          WITH PASSWORD = 'Admin@SecureP@ss1!';
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'TrainingManagerLogin')
CREATE LOGIN TrainingManagerLogin WITH PASSWORD = 'TM@SecureP@ss2!';
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'InstructorLogin')
CREATE LOGIN InstructorLogin      WITH PASSWORD = 'Inst@SecureP@ss3!';
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'StudentLogin')
CREATE LOGIN StudentLogin         WITH PASSWORD = 'Stud@SecureP@ss4!';
GO

USE ExaminationSystemDB;
GO

-- Guard against re-running
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'AdminUser')
CREATE USER AdminUser       FOR LOGIN AdminLogin;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'TrainingMgrUser')
CREATE USER TrainingMgrUser FOR LOGIN TrainingManagerLogin;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'InstructorUser')
CREATE USER InstructorUser  FOR LOGIN InstructorLogin;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'StudentUser')
CREATE USER StudentUser     FOR LOGIN StudentLogin;
GO

-- Admin: full database owner
ALTER ROLE db_owner ADD MEMBER AdminUser;

-- Training Manager: organisation + reporting
GRANT EXECUTE ON sp_AddBranch                TO TrainingMgrUser;
GRANT EXECUTE ON sp_AddTrack                 TO TrainingMgrUser;
GRANT EXECUTE ON sp_AddIntake                TO TrainingMgrUser;
GRANT EXECUTE ON sp_AddInstructor            TO TrainingMgrUser;
GRANT EXECUTE ON sp_AddStudent               TO TrainingMgrUser;
GRANT EXECUTE ON sp_AssignInstructorToCourse TO TrainingMgrUser;
GRANT EXECUTE ON sp_SearchStudents           TO TrainingMgrUser;
GRANT SELECT  ON vw_StudentFullInfo          TO TrainingMgrUser;
GRANT SELECT  ON vw_CourseInstructors        TO TrainingMgrUser;
GRANT SELECT  ON vw_ExamOverview             TO TrainingMgrUser;
GRANT SELECT  ON vw_StudentResults           TO TrainingMgrUser;

-- Instructor: question and exam management
GRANT EXECUTE ON sp_AddQuestion              TO InstructorUser;
GRANT EXECUTE ON sp_AddQuestionChoice        TO InstructorUser;
GRANT EXECUTE ON sp_UpdateQuestion           TO InstructorUser;
GRANT EXECUTE ON sp_DeleteQuestion           TO InstructorUser;
GRANT EXECUTE ON sp_SearchQuestions          TO InstructorUser;
GRANT EXECUTE ON sp_CreateExam               TO InstructorUser;
GRANT EXECUTE ON sp_AddQuestionToExam        TO InstructorUser;
GRANT EXECUTE ON sp_AutoSelectExamQuestions  TO InstructorUser;
GRANT EXECUTE ON sp_EnrollStudentInExam      TO InstructorUser;
GRANT EXECUTE ON sp_ReviewTextAnswer         TO InstructorUser;
GRANT EXECUTE ON sp_RecalcStudentScore       TO InstructorUser;
GRANT EXECUTE ON sp_GetStudentExamResult     TO InstructorUser;
GRANT SELECT  ON vw_QuestionPool             TO InstructorUser;
GRANT SELECT  ON vw_ExamOverview             TO InstructorUser;
GRANT SELECT  ON vw_StudentResults           TO InstructorUser;
GRANT SELECT  ON vw_PendingTextReview        TO InstructorUser;

-- Student: submit answers and view own results only
GRANT EXECUTE ON sp_SubmitStudentAnswer      TO StudentUser;
GRANT EXECUTE ON sp_FinalizeStudentExam      TO StudentUser;
GRANT EXECUTE ON sp_GetStudentExamResult     TO StudentUser;
GO


-- ============================================================
-- SECTION 10: AUTOMATED DAILY BACKUP JOB
-- ============================================================

USE msdb;
GO

-- Remove existing job if re-running
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'ExaminationSystemDB_DailyBackup')
    EXEC sp_delete_job @job_name = N'ExaminationSystemDB_DailyBackup';
GO

DECLARE @JobID UNIQUEIDENTIFIER;

EXEC sp_add_job
     @job_name   = N'ExaminationSystemDB_DailyBackup',
     @enabled    = 1,
     @description= N'Daily full backup of ExaminationSystemDB',
     @job_id     = @JobID OUTPUT;

EXEC sp_add_jobstep
     @job_name      = N'ExaminationSystemDB_DailyBackup',
     @step_name     = N'Full Backup Step',
     @subsystem     = N'TSQL',
     @database_name = N'master',
     @command       = N'
DECLARE @Path NVARCHAR(500) =
    ''/gvar/opt/mssql/data/'' + CONVERT(NVARCHAR(8), GETDATE(), 112) + ''.bak'';
BACKUP DATABASE ExaminationSystemDB
TO DISK = @Path
WITH COMPRESSION, CHECKSUM, STATS = 10;';

EXEC sp_add_schedule
     @schedule_name      = N'DailyAt2AM',
     @freq_type          = 4,       -- Daily
     @freq_interval      = 1,
     @active_start_time  = 20000;   -- 02:00 AM

EXEC sp_attach_schedule
     @job_name      = N'ExaminationSystemDB_DailyBackup',
     @schedule_name = N'DailyAt2AM';

EXEC sp_add_jobserver
     @job_name = N'ExaminationSystemDB_DailyBackup';
GO


-- ============================================================
-- SECTION 11: QUICK TEST QUERIES
-- ============================================================

USE ExaminationSystemDB;
GO

-- All students with full context
SELECT * FROM vw_StudentFullInfo;

-- All exams with student/question counts
SELECT * FROM vw_ExamOverview;

-- Question pool for SQL Server course
SELECT * FROM vw_QuestionPool WHERE CourseName = 'SQL Server';

-- All student results
SELECT * FROM vw_StudentResults ORDER BY CourseName, TotalScore DESC;

-- Text answers awaiting instructor review
SELECT * FROM vw_PendingTextReview;

-- Search students in Cairo / Software Development track
EXEC sp_SearchStudents @BranchID = 1, @TrackID = 1;

-- Full result breakdown for StudentExam 1
EXEC sp_GetStudentExamResult 1;

-- Student 1 score in course 1
SELECT dbo.fn_GetStudentCourseScore(1, 1) AS StudentScore;

-- Exam question count by type
SELECT
    dbo.fn_ExamQuestionCountByType(1, 'MCQ')       AS MCQ_Count,
    dbo.fn_ExamQuestionCountByType(1, 'TrueFalse') AS TF_Count,
    dbo.fn_ExamQuestionCountByType(1, 'Text')      AS Text_Count;

PRINT '
==========================================
 ExaminationSystemDB ready.
------------------------------------------
 Accounts
   Admin            : AdminLogin           / Admin@SecureP@ss1!
   Training Manager : TrainingManagerLogin / TM@SecureP@ss2!
   Instructor       : InstructorLogin      / Inst@SecureP@ss3!
   Student          : StudentLogin         / Stud@SecureP@ss4!
==========================================
';
GO

-- ============================================================
-- END OF SCRIPT
-- ============================================================