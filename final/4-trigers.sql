
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

