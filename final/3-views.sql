
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