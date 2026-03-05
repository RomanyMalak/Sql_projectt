
USE ExaminationSystemDB;
GO

INSERT INTO Branch (BranchName, Location) VALUES
('Cairo','Nasr City'),
('Alexandria','Smouha'),
('Assiut','ITI Assiut');
GO

INSERT INTO Track (BranchID, TrackName, Description) VALUES
(1,'Software Engineering','Full SDLC'),
(1,'Data Engineering','Data pipelines'),
(2,'Cyber Security','Security track'),
(3,'AI Engineering','AI and ML');
GO

INSERT INTO Intake (IntakeName, StartDate, EndDate) VALUES
('Intake 44','2024-01-01','2024-12-31'),
('Intake 45','2025-01-01','2025-12-31');
GO

INSERT INTO SystemUser (Username,PasswordHash,UserRole) VALUES
('admin1','hash','Admin'),
('manager1','hash','TrainingManager'),
('inst1','hash','Instructor'),
('inst2','hash','Instructor'),
('student1','hash','Student'),
('student2','hash','Student'),
('student3','hash','Student');
GO

INSERT INTO Instructor (UserID,FirstName,LastName,Email,Phone,HireDate) VALUES
(3,'Ahmed','Ali','ahmed@iti.com','0100000001','2020-01-01'),
(4,'Sara','Hassan','sara@iti.com','0100000002','2021-03-10');
GO

INSERT INTO Student (UserID,IntakeID,BranchID,TrackID,FirstName,LastName,Email,Phone,DateOfBirth,NationalID) VALUES
(5,1,1,1,'Mohamed','Tarek','mohamed@iti.com','011000001','2000-05-10','30001010101010'),
(6,1,1,2,'Salma','Adel','salma@iti.com','011000002','2001-07-12','30102020202020'),
(7,2,3,4,'Youssef','Khaled','youssef@iti.com','011000003','1999-09-15','29903030303030');
GO

INSERT INTO Course (CourseName,Description,MaxDegree,MinDegree) VALUES
('Database Systems','SQL Server course',100,50),
('Operating Systems','OS concepts',100,50),
('Machine Learning','ML basics',100,50);
GO

INSERT INTO InstructorCourse (InstructorID,CourseID,IntakeID,BranchID,TrackID,AcademicYear) VALUES
(1,1,1,1,1,2024),
(1,2,1,1,2,2024),
(2,3,2,3,4,2025);
GO

INSERT INTO Question (CourseID,InstructorID,QuestionType,QuestionText,ModelAnswer,DifficultyLevel) VALUES
(1,1,'MCQ','What does SQL stand for?','Structured Query Language','Easy'),
(1,1,'TrueFalse','SQL is used to manage relational databases','True','Easy'),
(3,2,'Text','Define Machine Learning','AI that learns from data','Medium');
GO

INSERT INTO QuestionChoice (QuestionID,ChoiceText,IsCorrect,ChoiceOrder) VALUES
(1,'Structured Query Language',1,1),
(1,'Simple Query Language',0,2),
(1,'System Query Logic',0,3),
(2,'True',1,1),
(2,'False',0,2);
GO

INSERT INTO Exam (CourseID,InstructorID,IntakeID,BranchID,TrackID,AcademicYear,ExamType,ExamTitle,StartTime,EndTime,TotalTimeMin,TotalDegree) VALUES
(1,1,1,1,1,2024,'Exam','Database Midterm','2024-06-01 10:00','2024-06-01 12:00',120,100);
GO

INSERT INTO ExamQuestion (ExamID,QuestionID,Degree,OrderNum) VALUES
(1,1,50,1),
(1,2,50,2);
GO

INSERT INTO StudentExam (StudentID,ExamID,ExamDate,Status) VALUES
(1,1,'2024-06-01','Submitted'),
(2,1,'2024-06-01','Submitted');
GO

INSERT INTO StudentAnswer (StudentExamID,ExamQuestionID,ChoiceID,IsCorrect,AwardedDegree) VALUES
(1,1,1,1,50),
(1,2,4,1,50),
(2,1,2,0,0),
(2,2,4,1,50);
GO
