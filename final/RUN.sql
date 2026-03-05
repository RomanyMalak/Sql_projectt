
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

-- PRINT '
-- ==========================================
--  ExaminationSystemDB ready.
-- ------------------------------------------
--  Accounts
--    Admin            : AdminLogin           / Admin@SecureP@ss1!
--    Training Manager : TrainingManagerLogin / TM@SecureP@ss2!
--    Instructor       : InstructorLogin      / Inst@SecureP@ss3!
--    Student          : StudentLogin         / Stud@SecureP@ss4!
-- ==========================================
-- ';
-- GO

