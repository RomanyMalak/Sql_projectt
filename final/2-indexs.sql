
-- ============================================================
-- SECTION 3: INDEXES
-- ============================================================

use [ExaminationSystemDB];
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
