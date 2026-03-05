

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

