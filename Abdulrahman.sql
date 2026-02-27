-- =========================================
-- Create Database
-- =========================================
CREATE DATABASE ExaminationSystem;
GO

USE ExaminationSystem;
GO


-- =========================================
-- 1. Users (RBAC: Student, Instructor, Manager)
-- =========================================
CREATE TABLE Users (
    UserID INT IDENTITY PRIMARY KEY,
    Username NVARCHAR(100) UNIQUE NOT NULL,
    PasswordHash NVARCHAR(255) NOT NULL,
    Role NVARCHAR(50) CHECK (Role IN ('Student','Instructor','Manager')) NOT NULL
);


-- =========================================
-- 2. Department
-- =========================================
CREATE TABLE Department (
    DepartmentID INT IDENTITY PRIMARY KEY,
    DepartmentName NVARCHAR(200) NOT NULL
);


-- =========================================
-- 3. Branch
-- =========================================
CREATE TABLE Branch (
    BranchID INT IDENTITY PRIMARY KEY,
    BranchName NVARCHAR(200) NOT NULL
);


-- =========================================
-- 4. Track
-- =========================================
CREATE TABLE Track (
    TrackID INT IDENTITY PRIMARY KEY,
    TrackName NVARCHAR(200) NOT NULL,
    DepartmentID INT NOT NULL,
    FOREIGN KEY (DepartmentID) REFERENCES Department(DepartmentID)
);


-- =========================================
-- 5. Intake
-- =========================================
CREATE TABLE Intake (
    IntakeID INT IDENTITY PRIMARY KEY,
    IntakeName NVARCHAR(100),
    StartDate DATE,
    EndDate DATE
);


-- =========================================
-- 6. Instructor
-- =========================================
CREATE TABLE Instructor (
    InstructorID INT IDENTITY PRIMARY KEY,
    UserID INT UNIQUE NOT NULL,
    Name NVARCHAR(200),
    Email NVARCHAR(200),
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);


-- =========================================
-- 7. Student
-- =========================================
CREATE TABLE Student (
    StudentID INT IDENTITY PRIMARY KEY,
    UserID INT UNIQUE NOT NULL,
    Name NVARCHAR(200),
    Email NVARCHAR(200),
    BranchID INT,
    TrackID INT,
    IntakeID INT,
    FOREIGN KEY (UserID) REFERENCES Users(UserID),
    FOREIGN KEY (BranchID) REFERENCES Branch(BranchID),
    FOREIGN KEY (TrackID) REFERENCES Track(TrackID),
    FOREIGN KEY (IntakeID) REFERENCES Intake(IntakeID)
);


-- =========================================
-- 8. Course
-- =========================================
CREATE TABLE Course (
    CourseID INT IDENTITY PRIMARY KEY,
    CourseName NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX),
    MaxDegree INT,
    MinDegree INT,
    CHECK (MaxDegree >= MinDegree)
);


-- =========================================
-- 9. InstructorCourse (Teaching per class/year)
-- =========================================
CREATE TABLE InstructorCourse (
    InstructorCourseID INT IDENTITY PRIMARY KEY,
    InstructorID INT NOT NULL,
    CourseID INT NOT NULL,
    Year INT NOT NULL,
    BranchID INT,
    TrackID INT,
    IntakeID INT,
    FOREIGN KEY (InstructorID) REFERENCES Instructor(InstructorID),
    FOREIGN KEY (CourseID) REFERENCES Course(CourseID),
    FOREIGN KEY (BranchID) REFERENCES Branch(BranchID),
    FOREIGN KEY (TrackID) REFERENCES Track(TrackID),
    FOREIGN KEY (IntakeID) REFERENCES Intake(IntakeID)
);


-- =========================================
-- 10. Question Pool
-- =========================================
CREATE TABLE Question (
    QuestionID INT IDENTITY PRIMARY KEY,
    CourseID INT NOT NULL,
    InstructorID INT NOT NULL,
    QuestionText NVARCHAR(MAX),
    QuestionType NVARCHAR(20) CHECK (QuestionType IN ('MCQ','TF','Text')),
    FOREIGN KEY (CourseID) REFERENCES Course(CourseID),
    FOREIGN KEY (InstructorID) REFERENCES Instructor(InstructorID)
);


-- =========================================
-- 11. Choices (for MCQ & TF)
-- =========================================
CREATE TABLE Choice (
    ChoiceID INT IDENTITY PRIMARY KEY,
    QuestionID INT NOT NULL,
    ChoiceText NVARCHAR(500),
    IsCorrect BIT,
    FOREIGN KEY (QuestionID) REFERENCES Question(QuestionID)
);


-- =========================================
-- 12. Text Accepted Answers
-- =========================================
CREATE TABLE TextAnswer (
    TextAnswerID INT IDENTITY PRIMARY KEY,
    QuestionID INT NOT NULL,
    AcceptedAnswer NVARCHAR(MAX),
    FOREIGN KEY (QuestionID) REFERENCES Question(QuestionID)
);


-- =========================================
-- 13. Exam
-- =========================================
CREATE TABLE Exam (
    ExamID INT IDENTITY PRIMARY KEY,
    CourseID INT NOT NULL,
    InstructorID INT NOT NULL,
    IntakeID INT,
    BranchID INT,
    TrackID INT,
    ExamType NVARCHAR(50) CHECK (ExamType IN ('Exam','Corrective')),
    StartTime DATETIME,
    EndTime DATETIME,
    TotalTime INT,
    Year INT,
    FOREIGN KEY (CourseID) REFERENCES Course(CourseID),
    FOREIGN KEY (InstructorID) REFERENCES Instructor(InstructorID),
    FOREIGN KEY (IntakeID) REFERENCES Intake(IntakeID),
    FOREIGN KEY (BranchID) REFERENCES Branch(BranchID),
    FOREIGN KEY (TrackID) REFERENCES Track(TrackID)
);


-- =========================================
-- 14. Exam Questions
-- =========================================
CREATE TABLE ExamQuestion (
    ExamID INT,
    QuestionID INT,
    Degree INT,
    PRIMARY KEY (ExamID, QuestionID),
    FOREIGN KEY (ExamID) REFERENCES Exam(ExamID),
    FOREIGN KEY (QuestionID) REFERENCES Question(QuestionID)
);


-- =========================================
-- 15. Student Exam
-- =========================================
CREATE TABLE StudentExam (
    StudentID INT,
    ExamID INT,
    Status NVARCHAR(50),
    PRIMARY KEY (StudentID, ExamID),
    FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
    FOREIGN KEY (ExamID) REFERENCES Exam(ExamID)
);


-- =========================================
-- 16. Student Answers
-- =========================================
CREATE TABLE StudentAnswer (
    StudentID INT,
    ExamID INT,
    QuestionID INT,
    ChoiceID INT NULL,
    TextAnswer NVARCHAR(MAX) NULL,
    IsCorrect BIT,
    Mark INT,
    PRIMARY KEY (StudentID, ExamID, QuestionID),
    FOREIGN KEY (StudentID, ExamID) REFERENCES StudentExam(StudentID, ExamID),
    FOREIGN KEY (ChoiceID) REFERENCES Choice(ChoiceID)
);


-- =========================================
-- 17. Final Result per Course
-- =========================================
CREATE TABLE Result (
    StudentID INT,
    CourseID INT,
    TotalMark INT,
    PRIMARY KEY (StudentID, CourseID),
    FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
    FOREIGN KEY (CourseID) REFERENCES Course(CourseID)
);