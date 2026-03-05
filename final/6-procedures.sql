
-- ============================================================
-- 7. STORED PROCEDURES
-- ============================================================

-- ---- Admin & Training Manager Procedures ------------------

-- Add Branch
CREATE OR ALTER PROCEDURE sp_AddBranch
    @BranchName NVARCHAR(100),
    @Location   NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM Branch WHERE BranchName = @BranchName)
        THROW 50001, 'Branch name already exists.', 1;
    INSERT INTO Branch(BranchName, Location) VALUES(@BranchName, @Location);
    SELECT SCOPE_IDENTITY() AS NewBranchID;
END;
GO

-- Add Track
CREATE OR ALTER PROCEDURE sp_AddTrack
    @BranchID   INT,
    @TrackName  NVARCHAR(100),
    @Description NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Branch WHERE BranchID = @BranchID AND IsActive = 1)
        THROW 50002, 'Branch not found or inactive.', 1;
    INSERT INTO Track(BranchID, TrackName, Description) VALUES(@BranchID, @TrackName, @Description);
    SELECT SCOPE_IDENTITY() AS NewTrackID;
END;
GO

-- Add Intake
CREATE OR ALTER PROCEDURE sp_AddIntake
    @IntakeName NVARCHAR(50),
    @StartDate  DATE = NULL,
    @EndDate    DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Intake(IntakeName, StartDate, EndDate) VALUES(@IntakeName, @StartDate, @EndDate);
    SELECT SCOPE_IDENTITY() AS NewIntakeID;
END;
GO

-- Add Instructor (creates SystemUser + Instructor record)
CREATE OR ALTER PROCEDURE sp_AddInstructor
    @Username         NVARCHAR(50),
    @PasswordHash     NVARCHAR(256),
    @FirstName        NVARCHAR(50),
    @LastName         NVARCHAR(50),
    @Email            NVARCHAR(100),
    @Phone            NVARCHAR(20)  = NULL,
    @IsTrainingManager BIT          = 0
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO SystemUser(Username, PasswordHash, UserRole)
        VALUES(@Username, @PasswordHash, CASE WHEN @IsTrainingManager=1 THEN 'TrainingManager' ELSE 'Instructor' END);
        DECLARE @UID INT = SCOPE_IDENTITY();
        INSERT INTO Instructor(UserID, FirstName, LastName, Email, Phone, IsTrainingManager)
        VALUES(@UID, @FirstName, @LastName, @Email, @Phone, @IsTrainingManager);
        SELECT SCOPE_IDENTITY() AS NewInstructorID;
        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- Add Student
CREATE OR ALTER PROCEDURE sp_AddStudent
    @Username   NVARCHAR(50),
    @PasswordHash NVARCHAR(256),
    @IntakeID   INT,
    @BranchID   INT,
    @TrackID    INT,
    @FirstName  NVARCHAR(50),
    @LastName   NVARCHAR(50),
    @Email      NVARCHAR(100),
    @Phone      NVARCHAR(20) = NULL,
    @DateOfBirth DATE        = NULL,
    @NationalID NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO SystemUser(Username, PasswordHash, UserRole)
        VALUES(@Username, @PasswordHash, 'Student');
        DECLARE @UID INT = SCOPE_IDENTITY();
        INSERT INTO Student(UserID, IntakeID, BranchID, TrackID, FirstName, LastName, Email, Phone, DateOfBirth, NationalID)
        VALUES(@UID, @IntakeID, @BranchID, @TrackID, @FirstName, @LastName, @Email, @Phone, @DateOfBirth, @NationalID);
        SELECT SCOPE_IDENTITY() AS NewStudentID;
        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- Assign Instructor to Course
CREATE OR ALTER PROCEDURE sp_AssignInstructorToCourse
    @InstructorID INT,
    @CourseID     INT,
    @IntakeID     INT,
    @BranchID     INT,
    @TrackID      INT,
    @AcademicYear INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM InstructorCourse
               WHERE InstructorID=@InstructorID AND CourseID=@CourseID
                 AND IntakeID=@IntakeID AND BranchID=@BranchID
                 AND TrackID=@TrackID AND AcademicYear=@AcademicYear)
        THROW 50010, 'Assignment already exists.', 1;
    INSERT INTO InstructorCourse(InstructorID, CourseID, IntakeID, BranchID, TrackID, AcademicYear)
    VALUES(@InstructorID, @CourseID, @IntakeID, @BranchID, @TrackID, @AcademicYear);
    SELECT SCOPE_IDENTITY() AS NewAssignmentID;
END;
GO

-- ---- Instructor Procedures --------------------------------

-- Add Question
CREATE OR ALTER PROCEDURE sp_AddQuestion
    @CourseID      INT,
    @InstructorID  INT,
    @QuestionType  NVARCHAR(20),
    @QuestionText  NVARCHAR(MAX),
    @ModelAnswer   NVARCHAR(MAX) = NULL,
    @DifficultyLevel NVARCHAR(10) = 'Medium'
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Question(CourseID, InstructorID, QuestionType, QuestionText, ModelAnswer, DifficultyLevel)
    VALUES(@CourseID, @InstructorID, @QuestionType, @QuestionText, @ModelAnswer, @DifficultyLevel);
    SELECT SCOPE_IDENTITY() AS NewQuestionID;
END;
GO

-- Add Question Choice
CREATE OR ALTER PROCEDURE sp_AddQuestionChoice
    @QuestionID  INT,
    @ChoiceText  NVARCHAR(500),
    @IsCorrect   BIT,
    @ChoiceOrder TINYINT = 1
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO QuestionChoice(QuestionID, ChoiceText, IsCorrect, ChoiceOrder)
    VALUES(@QuestionID, @ChoiceText, @IsCorrect, @ChoiceOrder);
    SELECT SCOPE_IDENTITY() AS NewChoiceID;
END;
GO

-- Update Question
CREATE OR ALTER PROCEDURE sp_UpdateQuestion
    @QuestionID    INT,
    @InstructorID  INT,
    @QuestionText  NVARCHAR(MAX) = NULL,
    @ModelAnswer   NVARCHAR(MAX) = NULL,
    @DifficultyLevel NVARCHAR(10) = NULL,
    @IsActive      BIT           = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Question WHERE QuestionID=@QuestionID AND InstructorID=@InstructorID)
        THROW 50020, 'Question not found or you do not own this question.', 1;
    UPDATE Question SET
        QuestionText   = ISNULL(@QuestionText, QuestionText),
        ModelAnswer    = ISNULL(@ModelAnswer, ModelAnswer),
        DifficultyLevel= ISNULL(@DifficultyLevel, DifficultyLevel),
        IsActive       = ISNULL(@IsActive, IsActive)
    WHERE QuestionID = @QuestionID;
END;
GO

-- Delete Question
CREATE OR ALTER PROCEDURE sp_DeleteQuestion
    @QuestionID   INT,
    @InstructorID INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM Question WHERE QuestionID=@QuestionID AND InstructorID=@InstructorID)
        THROW 50021, 'Question not found or you do not own this question.', 1;
    IF EXISTS (SELECT 1 FROM ExamQuestion WHERE QuestionID=@QuestionID)
        THROW 50022, 'Cannot delete question used in an exam. Deactivate it instead.', 1;
    DELETE FROM Question WHERE QuestionID = @QuestionID;
END;
GO

-- Create Exam
CREATE OR ALTER PROCEDURE sp_CreateExam
    @CourseID       INT,
    @InstructorID   INT,
    @IntakeID       INT,
    @BranchID       INT,
    @TrackID        INT,
    @AcademicYear   INT,
    @ExamType       NVARCHAR(20),
    @ExamTitle      NVARCHAR(200),
    @StartTime      DATETIME,
    @EndTime        DATETIME,
    @TotalTimeMin   INT,
    @AllowanceOptions NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    -- Verify instructor teaches this course
    IF NOT EXISTS (SELECT 1 FROM InstructorCourse
                   WHERE InstructorID=@InstructorID AND CourseID=@CourseID
                     AND IntakeID=@IntakeID AND BranchID=@BranchID
                     AND TrackID=@TrackID AND AcademicYear=@AcademicYear)
        THROW 50030, 'Instructor is not assigned to this course/class.', 1;
    INSERT INTO Exam(CourseID, InstructorID, IntakeID, BranchID, TrackID, AcademicYear,
                     ExamType, ExamTitle, StartTime, EndTime, TotalTimeMin, TotalDegree, AllowanceOptions)
    VALUES(@CourseID, @InstructorID, @IntakeID, @BranchID, @TrackID, @AcademicYear,
           @ExamType, @ExamTitle, @StartTime, @EndTime, @TotalTimeMin, 0, @AllowanceOptions);
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
    -- Check degree won't exceed course max
    DECLARE @CurrentTotal DECIMAL(6,2), @MaxDeg DECIMAL(6,2);
    SELECT @CurrentTotal = ISNULL(SUM(eq.Degree),0)
    FROM ExamQuestion eq WHERE eq.ExamID = @ExamID;
    SELECT @MaxDeg = c.MaxDegree
    FROM Exam e INNER JOIN Course c ON e.CourseID = c.CourseID
    WHERE e.ExamID = @ExamID;
    IF @CurrentTotal + @Degree > @MaxDeg
        THROW 50031, 'Adding this question would exceed the course MaxDegree.', 1;
    INSERT INTO ExamQuestion(ExamID, QuestionID, Degree, OrderNum)
    VALUES(@ExamID, @QuestionID, @Degree, @OrderNum);
    -- Update exam total
    UPDATE Exam SET TotalDegree = @CurrentTotal + @Degree WHERE ExamID = @ExamID;
    SELECT SCOPE_IDENTITY() AS NewExamQuestionID;
END;
GO

-- Auto-select random questions for exam
CREATE OR ALTER PROCEDURE sp_AutoSelectExamQuestions
    @ExamID       INT,
    @InstructorID INT,
    @MCQCount     INT          = 0,
    @TFCount      INT          = 0,
    @TextCount    INT          = 0,
    @DegreePerMCQ DECIMAL(5,2) = 1,
    @DegreePerTF  DECIMAL(5,2) = 1,
    @DegreePerText DECIMAL(5,2)= 5
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CourseID INT;
    SELECT @CourseID = CourseID FROM Exam WHERE ExamID = @ExamID;

    -- Validate instructor
    IF NOT EXISTS (SELECT 1 FROM Exam WHERE ExamID=@ExamID AND InstructorID=@InstructorID)
        THROW 50040, 'You do not own this exam.', 1;

    -- Clear existing questions
    DELETE FROM ExamQuestion WHERE ExamID = @ExamID;
    UPDATE Exam SET TotalDegree = 0 WHERE ExamID = @ExamID;

    -- MCQ
    IF @MCQCount > 0
        INSERT INTO ExamQuestion(ExamID, QuestionID, Degree, OrderNum)
        SELECT TOP (@MCQCount) @ExamID, QuestionID, @DegreePerMCQ,
               ROW_NUMBER() OVER (ORDER BY NEWID())
        FROM Question
        WHERE CourseID=@CourseID AND QuestionType='MCQ' AND IsActive=1
          AND QuestionID NOT IN (SELECT QuestionID FROM ExamQuestion WHERE ExamID=@ExamID)
        ORDER BY NEWID();

    -- True/False
    IF @TFCount > 0
        INSERT INTO ExamQuestion(ExamID, QuestionID, Degree, OrderNum)
        SELECT TOP (@TFCount) @ExamID, QuestionID, @DegreePerTF,
               @MCQCount + ROW_NUMBER() OVER (ORDER BY NEWID())
        FROM Question
        WHERE CourseID=@CourseID AND QuestionType='TrueFalse' AND IsActive=1
          AND QuestionID NOT IN (SELECT QuestionID FROM ExamQuestion WHERE ExamID=@ExamID)
        ORDER BY NEWID();

    -- Text
    IF @TextCount > 0
        INSERT INTO ExamQuestion(ExamID, QuestionID, Degree, OrderNum)
        SELECT TOP (@TextCount) @ExamID, QuestionID, @DegreePerText,
               @MCQCount + @TFCount + ROW_NUMBER() OVER (ORDER BY NEWID())
        FROM Question
        WHERE CourseID=@CourseID AND QuestionType='Text' AND IsActive=1
          AND QuestionID NOT IN (SELECT QuestionID FROM ExamQuestion WHERE ExamID=@ExamID)
        ORDER BY NEWID();

    -- Update total degree
    UPDATE Exam SET TotalDegree = (
        SELECT ISNULL(SUM(Degree),0) FROM ExamQuestion WHERE ExamID=@ExamID
    ) WHERE ExamID = @ExamID;

    SELECT COUNT(*) AS QuestionsAdded FROM ExamQuestion WHERE ExamID = @ExamID;
END;
GO

-- Enroll student to exam
CREATE OR ALTER PROCEDURE sp_EnrollStudentInExam
    @StudentID INT,
    @ExamID    INT,
    @ExamDate  DATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM StudentExam WHERE StudentID=@StudentID AND ExamID=@ExamID)
        THROW 50050, 'Student already enrolled in this exam.', 1;
    INSERT INTO StudentExam(StudentID, ExamID, ExamDate, Status)
    VALUES(@StudentID, @ExamID, @ExamDate, 'Scheduled');
    SELECT SCOPE_IDENTITY() AS NewStudentExamID;
END;
GO

-- Submit student exam (submit all answers)
CREATE OR ALTER PROCEDURE sp_SubmitStudentAnswer
    @StudentExamID  INT,
    @ExamQuestionID INT,
    @ChoiceID       INT          = NULL,
    @TextAnswer     NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    -- Check exam is in progress / student can still submit
    IF NOT EXISTS (SELECT 1 FROM StudentExam WHERE StudentExamID=@StudentExamID
                   AND Status IN ('Scheduled','InProgress'))
        THROW 50060, 'Exam is not available for submission.', 1;

    -- Upsert answer
    IF EXISTS (SELECT 1 FROM StudentAnswer WHERE StudentExamID=@StudentExamID AND ExamQuestionID=@ExamQuestionID)
        UPDATE StudentAnswer SET ChoiceID=@ChoiceID, TextAnswer=@TextAnswer, IsCorrect=NULL, AwardedDegree=0
        WHERE StudentExamID=@StudentExamID AND ExamQuestionID=@ExamQuestionID;
    ELSE
        INSERT INTO StudentAnswer(StudentExamID, ExamQuestionID, ChoiceID, TextAnswer)
        VALUES(@StudentExamID, @ExamQuestionID, @ChoiceID, @TextAnswer);

    -- Mark exam as in progress
    UPDATE StudentExam SET Status='InProgress', ActualStart=ISNULL(ActualStart, GETDATE())
    WHERE StudentExamID=@StudentExamID AND Status='Scheduled';
END;
GO

-- Finalize/submit exam
CREATE OR ALTER PROCEDURE sp_FinalizeStudentExam
    @StudentExamID INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE StudentExam
    SET Status='Submitted', ActualEnd=GETDATE()
    WHERE StudentExamID=@StudentExamID AND Status IN ('Scheduled','InProgress');
END;
GO

-- Instructor manual review of text answer
CREATE OR ALTER PROCEDURE sp_ReviewTextAnswer
    @AnswerID       INT,
    @InstructorID   INT,
    @AwardedDegree  DECIMAL(5,2),
    @Review         NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    -- Verify instructor owns the exam
    IF NOT EXISTS (
        SELECT 1 FROM StudentAnswer sa
        INNER JOIN ExamQuestion eq ON sa.ExamQuestionID = eq.ExamQuestionID
        INNER JOIN Exam e          ON eq.ExamID = e.ExamID
        WHERE sa.AnswerID = @AnswerID AND e.InstructorID = @InstructorID
    )
        THROW 50070, 'You are not authorized to review this answer.', 1;

    UPDATE StudentAnswer
    SET AwardedDegree  = @AwardedDegree,
        IsCorrect      = CASE WHEN @AwardedDegree > 0 THEN 1 ELSE 0 END,
        InstructorReview = @Review,
        ReviewedBy     = @InstructorID,
        ReviewedAt     = GETDATE()
    WHERE AnswerID = @AnswerID;

    -- Recalculate total score
    DECLARE @SEID INT;
    SELECT @SEID = StudentExamID FROM StudentAnswer WHERE AnswerID = @AnswerID;
    EXEC sp_RecalcStudentScore @SEID;
END;
GO

-- Recalculate student score
CREATE OR ALTER PROCEDURE sp_RecalcStudentScore
    @StudentExamID INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE SE
    SET TotalScore = (SELECT ISNULL(SUM(sa.AwardedDegree),0)
                      FROM StudentAnswer sa WHERE sa.StudentExamID = @StudentExamID),
        IsPassed   = CASE WHEN
            (SELECT ISNULL(SUM(sa.AwardedDegree),0) FROM StudentAnswer sa WHERE sa.StudentExamID=@StudentExamID)
            >= (SELECT c.MinDegree FROM StudentExam se2
                INNER JOIN Exam e ON se2.ExamID=e.ExamID
                INNER JOIN Course c ON e.CourseID=c.CourseID
                WHERE se2.StudentExamID=@StudentExamID)
            THEN 1 ELSE 0 END,
        Status     = 'Graded'
    FROM StudentExam SE WHERE SE.StudentExamID = @StudentExamID;
END;
GO

-- Search students
CREATE OR ALTER PROCEDURE sp_SearchStudents
    @IntakeID   INT          = NULL,
    @BranchID   INT          = NULL,
    @TrackID    INT          = NULL,
    @SearchName NVARCHAR(100)= NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM vw_StudentFullInfo
    WHERE (@IntakeID   IS NULL OR IntakeName = (SELECT IntakeName FROM Intake WHERE IntakeID=@IntakeID))
      AND (@BranchID   IS NULL OR BranchName = (SELECT BranchName FROM Branch WHERE BranchID=@BranchID))
      AND (@TrackID    IS NULL OR TrackName  = (SELECT TrackName  FROM Track  WHERE TrackID =@TrackID))
      AND (@SearchName IS NULL OR StudentName LIKE '%' + @SearchName + '%');
END;
GO

-- Search questions
CREATE OR ALTER PROCEDURE sp_SearchQuestions
    @CourseID     INT          = NULL,
    @QuestionType NVARCHAR(20) = NULL,
    @Difficulty   NVARCHAR(10) = NULL,
    @SearchText   NVARCHAR(200)= NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM vw_QuestionPool
    WHERE (@CourseID     IS NULL OR CourseID=(SELECT CourseID FROM Course WHERE CourseID=@CourseID))
      AND (@QuestionType IS NULL OR QuestionType = @QuestionType)
      AND (@Difficulty   IS NULL OR DifficultyLevel = @Difficulty)
      AND (@SearchText   IS NULL OR QuestionText LIKE '%' + @SearchText + '%')
      AND IsActive = 1;
END;
GO

-- Get student exam result details
CREATE OR ALTER PROCEDURE sp_GetStudentExamResult
    @StudentExamID INT
AS
BEGIN
    SET NOCOUNT ON;
    -- Header
    SELECT * FROM vw_StudentResults WHERE StudentExamID = @StudentExamID;
    -- Details per question
    SELECT eq.OrderNum, q.QuestionType, q.QuestionText, q.ModelAnswer,
           sa.TextAnswer, qc.ChoiceText AS SelectedChoice,
           sa.IsCorrect, sa.AwardedDegree, eq.Degree AS MaxDegree,
           sa.InstructorReview
    FROM ExamQuestion eq
    INNER JOIN Question q          ON eq.QuestionID      = q.QuestionID
    LEFT  JOIN StudentAnswer sa    ON sa.ExamQuestionID  = eq.ExamQuestionID
                                   AND sa.StudentExamID  = @StudentExamID
    LEFT  JOIN QuestionChoice qc   ON sa.ChoiceID        = qc.ChoiceID
    WHERE eq.ExamID = (SELECT ExamID FROM StudentExam WHERE StudentExamID=@StudentExamID)
    ORDER BY eq.OrderNum;
END;
GO
