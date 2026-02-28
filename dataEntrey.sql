USE ExaminationSystem;
GO

/* 1) Department */
INSERT INTO Department (DepartmentName)
VALUES (N'Computer Science'), (N'Information Systems');

/* 2) Branch */
INSERT INTO Branch (BranchName)
VALUES (N'Cairo'), (N'Alex');

/* 3) Track (depends on Department) */
INSERT INTO Track (TrackName, DepartmentID)
SELECT N'.NET', DepartmentID FROM Department WHERE DepartmentName = N'Computer Science'
UNION ALL
SELECT N'Data Science', DepartmentID FROM Department WHERE DepartmentName = N'Information Systems';

/* 4) Intake */
INSERT INTO Intake (IntakeName, StartDate, EndDate)
VALUES (N'Intake 45', '2026-01-01', '2026-06-30');

/* 5) Users */
-- NOTE: PasswordHash هنا مجرد نص تجريبي (المفروض يبقى Hash من التطبيق)
INSERT INTO Users (Username, PasswordHash, Role)
VALUES
(N'admin1',    N'HASH_admin',    N'Manager'),
(N'manager1',  N'HASH_manager',  N'Manager'),
(N'instr1',    N'HASH_instr1',   N'Instructor'),
(N'stud1',     N'HASH_stud1',    N'Student'),
(N'stud2',     N'HASH_stud2',    N'Student');

/* 6) Instructor (depends on Users) */
INSERT INTO Instructor (UserID, Name, Email)
SELECT u.UserID, N'Dr. Ahmed', N'ahmed@iti.com'
FROM Users u WHERE u.Username = N'instr1';

/* 7) Student (depends on Users + Branch + Track + Intake) */
DECLARE @CairoBranchId INT = (SELECT TOP 1 BranchID FROM Branch WHERE BranchName=N'Cairo');
DECLARE @DotNetTrackId INT = (SELECT TOP 1 TrackID FROM Track WHERE TrackName=N'.NET');
DECLARE @IntakeId INT = (SELECT TOP 1 IntakeID FROM Intake WHERE IntakeName=N'Intake 45');

INSERT INTO Student (UserID, Name, Email, BranchID, TrackID, IntakeID)
SELECT u.UserID, N'Ali Hassan', N'ali@student.com', @CairoBranchId, @DotNetTrackId, @IntakeId
FROM Users u WHERE u.Username = N'stud1';

INSERT INTO Student (UserID, Name, Email, BranchID, TrackID, IntakeID)
SELECT u.UserID, N'Sara Mohamed', N'sara@student.com', @CairoBranchId, @DotNetTrackId, @IntakeId
FROM Users u WHERE u.Username = N'stud2';

/* 8) Course */
INSERT INTO Course (CourseName, Description, MaxDegree, MinDegree)
VALUES (N'SQL Server', N'Database fundamentals and T-SQL', 100, 50);

/* 9) InstructorCourse (depends on Instructor + Course + class context) */
DECLARE @InstructorId INT = (SELECT TOP 1 InstructorID FROM Instructor WHERE Name=N'Dr. Ahmed');
DECLARE @CourseId INT = (SELECT TOP 1 CourseID FROM Course WHERE CourseName=N'SQL Server');

INSERT INTO InstructorCourse (InstructorID, CourseID, Year, BranchID, TrackID, IntakeID)
VALUES (@InstructorId, @CourseId, 2026, @CairoBranchId, @DotNetTrackId, @IntakeId);

/* 10) Question */
INSERT INTO Question (CourseID, InstructorID, QuestionText, QuestionType)
VALUES
(@CourseId, @InstructorId, N'What does SQL stand for?', N'Text'),
(@CourseId, @InstructorId, N'SELECT is used to retrieve data.', N'TF'),
(@CourseId, @InstructorId, N'Which keyword is used to filter rows?', N'MCQ');

/* 11) Choice + TextAnswer */
DECLARE @Q_Text INT = (SELECT TOP 1 QuestionID FROM Question WHERE QuestionType='Text' ORDER BY QuestionID);
DECLARE @Q_TF   INT = (SELECT TOP 1 QuestionID FROM Question WHERE QuestionType='TF' ORDER BY QuestionID);
DECLARE @Q_MCQ  INT = (SELECT TOP 1 QuestionID FROM Question WHERE QuestionType='MCQ' ORDER BY QuestionID);

-- Text accepted answer
INSERT INTO TextAnswer (QuestionID, AcceptedAnswer)
VALUES (@Q_Text, N'Structured Query Language');

-- TF choices (max 2)
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect)
VALUES
(@Q_TF,  N'True',  1),
(@Q_TF,  N'False', 0);

-- MCQ choices (one correct)
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect)
VALUES
(@Q_MCQ, N'WHERE', 1),
(@Q_MCQ, N'GROUP', 0),
(@Q_MCQ, N'ORDER', 0),
(@Q_MCQ, N'JOIN',  0);

/* 12) Exam */
INSERT INTO Exam
(CourseID, InstructorID, IntakeID, BranchID, TrackID, ExamType, StartTime, EndTime, TotalTime, Year)
VALUES
(@CourseId, @InstructorId, @IntakeId, @CairoBranchId, @DotNetTrackId,
 N'Exam', '2026-02-28T10:00:00', '2026-02-28T11:00:00', 60, 2026);

DECLARE @ExamId INT = (SELECT TOP 1 ExamID FROM Exam ORDER BY ExamID DESC);

/* 13) ExamQuestion */
INSERT INTO ExamQuestion (ExamID, QuestionID, Degree)
VALUES
(@ExamId, @Q_Text, 40),
(@ExamId, @Q_TF,   20),
(@ExamId, @Q_MCQ,  40);

/* 14) StudentExam */
DECLARE @Stud1 INT = (SELECT TOP 1 StudentID FROM Student WHERE Name=N'Ali Hassan');
DECLARE @Stud2 INT = (SELECT TOP 1 StudentID FROM Student WHERE Name=N'Sara Mohamed');

INSERT INTO StudentExam (StudentID, ExamID, Status)
VALUES
(@Stud1, @ExamId, N'Assigned'),
(@Stud2, @ExamId, N'Assigned');

/* 15) StudentAnswer */
-- Ali answers:
-- Text answer (mark NULL غالبًا لحد مراجعة المدرس)
INSERT INTO StudentAnswer (StudentID, ExamID, QuestionID, ChoiceID, TextAnswer, IsCorrect, Mark)
VALUES (@Stud1, @ExamId, @Q_Text, NULL, N'Structured Query Language', 1, NULL);

-- TF answer (pick the correct choice)
DECLARE @TF_TrueChoice INT = (SELECT TOP 1 ChoiceID FROM Choice WHERE QuestionID=@Q_TF AND ChoiceText=N'True');
INSERT INTO StudentAnswer (StudentID, ExamID, QuestionID, ChoiceID, TextAnswer, IsCorrect, Mark)
VALUES (@Stud1, @ExamId, @Q_TF, @TF_TrueChoice, NULL, 1, 20);

-- MCQ answer (WHERE correct)
DECLARE @MCQ_WhereChoice INT = (SELECT TOP 1 ChoiceID FROM Choice WHERE QuestionID=@Q_MCQ AND ChoiceText=N'WHERE');
INSERT INTO StudentAnswer (StudentID, ExamID, QuestionID, ChoiceID, TextAnswer, IsCorrect, Mark)
VALUES (@Stud1, @ExamId, @Q_MCQ, @MCQ_WhereChoice, NULL, 1, 40);

-- Sara answers wrong TF + wrong MCQ
DECLARE @TF_FalseChoice INT = (SELECT TOP 1 ChoiceID FROM Choice WHERE QuestionID=@Q_TF AND ChoiceText=N'False');
DECLARE @MCQ_JoinChoice INT = (SELECT TOP 1 ChoiceID FROM Choice WHERE QuestionID=@Q_MCQ AND ChoiceText=N'JOIN');

INSERT INTO StudentAnswer (StudentID, ExamID, QuestionID, ChoiceID, TextAnswer, IsCorrect, Mark)
VALUES
(@Stud2, @ExamId, @Q_TF,  @TF_FalseChoice, NULL, 0, 0),
(@Stud2, @ExamId, @Q_MCQ, @MCQ_JoinChoice,  NULL, 0, 0),
(@Stud2, @ExamId, @Q_Text, NULL, N'SQL', 0, NULL);

/* 16) Result (manual demo) */
-- عادة الأفضل تحسبها من StudentAnswer وتدخلها، بس ده مثال مباشر:
INSERT INTO Result (StudentID, CourseID, TotalMark)
VALUES
(@Stud1, @CourseId, 60),  -- text still NULL mark, so this is just demo
(@Stud2, @CourseId, 0);
GO