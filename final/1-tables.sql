
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

