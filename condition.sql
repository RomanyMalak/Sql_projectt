USE ExaminationSystem;
GO
/* Users: قيود وIndexes لتقوية صحة البيانات وتسريع البحث */

-- CHECK: طول اليوزرنيم
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_Users_UsernameLen')
    ALTER TABLE dbo.Users
    ADD CONSTRAINT CK_Users_UsernameLen CHECK (LEN(Username) BETWEEN 3 AND 100);
GO

-- Index: تسريع فلترة المستخدمين حسب الدور
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Users_Role' AND object_id=OBJECT_ID('dbo.Users'))
    CREATE INDEX IX_Users_Role ON dbo.Users(Role);
GO

-------------------------------

USE ExaminationSystem;
GO
/* Department: منع التكرار */

IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name='UX_Department_DepartmentName')
    ALTER TABLE dbo.Department
    ADD CONSTRAINT UX_Department_DepartmentName UNIQUE (DepartmentName);
GO

----------------------------


USE ExaminationSystem;
GO
/* Branch: منع التكرار */

IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name='UX_Branch_BranchName')
    ALTER TABLE dbo.Branch
    ADD CONSTRAINT UX_Branch_BranchName UNIQUE (BranchName);
GO

------------------------------

USE ExaminationSystem;
GO
/* Track: منع تكرار اسم التراك داخل نفس القسم */

IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name='UX_Track_Department_TrackName')
    ALTER TABLE dbo.Track
    ADD CONSTRAINT UX_Track_Department_TrackName UNIQUE (DepartmentID, TrackName);
GO

-------------------------------

USE ExaminationSystem;
GO
/* Intake: Check بسيط للتواريخ */

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_Intake_DateRange')
    ALTER TABLE dbo.Intake
    ADD CONSTRAINT CK_Intake_DateRange CHECK (StartDate IS NULL OR EndDate IS NULL OR StartDate <= EndDate);
GO

------------------------------------

USE ExaminationSystem;
GO
/* Instructor: Index مساعد للبحث بالإيميل */

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Instructor_Email' AND object_id=OBJECT_ID('dbo.Instructor'))
    CREATE INDEX IX_Instructor_Email ON dbo.Instructor(Email);
GO


-------------------------------------------


USE ExaminationSystem;
GO
/* Student: Index مهم جدًا للفلاتر الشائعة (Intake/Branch/Track) */

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Student_Branch_Track_Intake' AND object_id=OBJECT_ID('dbo.Student'))
    CREATE INDEX IX_Student_Branch_Track_Intake
    ON dbo.Student(BranchID, TrackID, IntakeID)
    INCLUDE (Name, Email, UserID);
GO

----------------------------------------------

USE ExaminationSystem;
GO
/* Course: (اختياري) منع تكرار اسم الكورس */

IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name='UX_Course_CourseName')
    ALTER TABLE dbo.Course
    ADD CONSTRAINT UX_Course_CourseName UNIQUE (CourseName);
GO

---------------------------------------

USE ExaminationSystem;
GO
/* InstructorCourse: NULL-safe uniqueness باستخدام computed columns + unique index */

IF COL_LENGTH('dbo.InstructorCourse', 'BranchKey') IS NULL
    ALTER TABLE dbo.InstructorCourse ADD BranchKey AS ISNULL(BranchID, 0) PERSISTED;
GO
IF COL_LENGTH('dbo.InstructorCourse', 'TrackKey') IS NULL
    ALTER TABLE dbo.InstructorCourse ADD TrackKey AS ISNULL(TrackID, 0) PERSISTED;
GO
IF COL_LENGTH('dbo.InstructorCourse', 'IntakeKey') IS NULL
    ALTER TABLE dbo.InstructorCourse ADD IntakeKey AS ISNULL(IntakeID, 0) PERSISTED;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UX_InstructorCourse_ClassYear_NullSafe'
               AND object_id=OBJECT_ID('dbo.InstructorCourse'))
    CREATE UNIQUE INDEX UX_InstructorCourse_ClassYear_NullSafe
    ON dbo.InstructorCourse (CourseID, Year,[BranchID] ,[TrackID] ,[IntakeID] );
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_InstructorCourse_CourseYear'
               AND object_id=OBJECT_ID('dbo.InstructorCourse'))
    CREATE INDEX IX_InstructorCourse_CourseYear
    ON dbo.InstructorCourse(CourseID, Year)
    INCLUDE (InstructorID, BranchID, TrackID, IntakeID);
GO

/* PROC: تعيين مدرس لكورس لدفعة/فرع/تراك */
CREATE OR ALTER PROCEDURE dbo.usp_AssignInstructorToCourseClass
    @InstructorID INT,
    @CourseID INT,
    @Year INT,
    @BranchID INT = NULL,
    @TrackID INT = NULL,
    @IntakeID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM dbo.InstructorCourse
        WHERE CourseID = @CourseID AND Year = @Year
          AND ISNULL(BranchID,0) = ISNULL(@BranchID,0)
          AND ISNULL(TrackID,0)  = ISNULL(@TrackID,0)
          AND ISNULL(IntakeID,0) = ISNULL(@IntakeID,0)
    )
        THROW 50002, 'This class/year already has an instructor for this course.', 1;

    INSERT INTO dbo.InstructorCourse (InstructorID, CourseID, Year, BranchID, TrackID, IntakeID)
    VALUES (@InstructorID, @CourseID, @Year, @BranchID, @TrackID, @IntakeID);
END;
GO

-----------------------------------------------------------------------------------

USE ExaminationSystem;
GO
/* Question: منع السؤال الفاضي + Index لجلب الأسئلة حسب الكورس والنوع */

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_Question_TextNotEmpty')
    ALTER TABLE dbo.Question
    ADD CONSTRAINT CK_Question_TextNotEmpty CHECK (LEN(LTRIM(RTRIM(ISNULL(QuestionText,'')))) > 0);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Question_Course_Type' AND object_id=OBJECT_ID('dbo.Question'))
    CREATE INDEX IX_Question_Course_Type ON dbo.Question(CourseID, QuestionType) INCLUDE (InstructorID);
GO

/* PROC: إضافة سؤال (يتأكد إن المدرس مكلّف بالكورس) */
CREATE OR ALTER PROCEDURE dbo.usp_AddQuestion
    @CourseID INT,
    @InstructorID INT,
    @QuestionText NVARCHAR(MAX),
    @QuestionType NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.InstructorCourse WHERE InstructorID=@InstructorID AND CourseID=@CourseID)
        THROW 50003, 'Instructor is not assigned to this course.', 1;

    INSERT INTO dbo.Question (CourseID, InstructorID, QuestionText, QuestionType)
    VALUES (@CourseID, @InstructorID, @QuestionText, @QuestionType);

    SELECT SCOPE_IDENTITY() AS NewQuestionID;
END;
GO

------------------------------------------------------


USE ExaminationSystem;
GO
/* Choice: منع النص الفاضي + Index + Trigger يمنع أكثر من Correct اختيار */

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_Choice_TextNotEmpty')
    ALTER TABLE dbo.Choice
    ADD CONSTRAINT CK_Choice_TextNotEmpty CHECK (LEN(LTRIM(RTRIM(ISNULL(ChoiceText,'')))) > 0);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Choice_Question' AND object_id=OBJECT_ID('dbo.Choice'))
    CREATE INDEX IX_Choice_Question ON dbo.Choice(QuestionID) INCLUDE (IsCorrect);
GO

CREATE OR ALTER TRIGGER dbo.tr_Choice_OneCorrect
ON dbo.Choice
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inserted WHERE IsCorrect = 1)
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM dbo.Choice c
            JOIN inserted i ON i.QuestionID = c.QuestionID
            WHERE c.IsCorrect = 1
            GROUP BY c.QuestionID
            HAVING COUNT(*) > 1
        )
        BEGIN
            ROLLBACK;
            THROW 50100, 'Only one correct choice is allowed per question.', 1;
        END
    END
END;
GO

/* PROC: إضافة اختيار (MCQ/TF فقط) */
CREATE OR ALTER PROCEDURE dbo.usp_AddChoice
    @QuestionID INT,
    @ChoiceText NVARCHAR(500),
    @IsCorrect BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @qt NVARCHAR(20);
    SELECT @qt = QuestionType FROM dbo.Question WHERE QuestionID = @QuestionID;

    IF @qt NOT IN ('MCQ','TF')
        THROW 50004, 'Choices allowed only for MCQ or TF.', 1;

    INSERT INTO dbo.Choice (QuestionID, ChoiceText, IsCorrect)
    VALUES (@QuestionID, @ChoiceText, @IsCorrect);
END;
GO


----------------------------------------------------

USE ExaminationSystem;
GO
/* TextAnswer: accepted answer واحد لكل سؤال */

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UX_TextAnswer_Question' AND object_id=OBJECT_ID('dbo.TextAnswer'))
    CREATE UNIQUE INDEX UX_TextAnswer_Question ON dbo.TextAnswer(QuestionID);
GO

/* PROC: تعيين/تحديث الإجابة المقبولة لسؤال Text */
CREATE OR ALTER PROCEDURE dbo.usp_SetTextAcceptedAnswer
    @QuestionID INT,
    @AcceptedAnswer NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @qt NVARCHAR(20);
    SELECT @qt = QuestionType FROM dbo.Question WHERE QuestionID = @QuestionID;

    IF @qt <> 'Text'
        THROW 50005, 'Accepted text answer allowed only for Text questions.', 1;

    IF EXISTS (SELECT 1 FROM dbo.TextAnswer WHERE QuestionID=@QuestionID)
        UPDATE dbo.TextAnswer SET AcceptedAnswer=@AcceptedAnswer WHERE QuestionID=@QuestionID;
    ELSE
        INSERT INTO dbo.TextAnswer (QuestionID, AcceptedAnswer) VALUES (@QuestionID, @AcceptedAnswer);
END;
GO

---------------------------------------------------------------------

USE ExaminationSystem;
GO
/* Exam: Checks للوقت + Index للبحث */

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_Exam_TimeRange')
    ALTER TABLE dbo.Exam
    ADD CONSTRAINT CK_Exam_TimeRange CHECK (StartTime < EndTime);
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_Exam_TotalTime_Positive')
    ALTER TABLE dbo.Exam
    ADD CONSTRAINT CK_Exam_TotalTime_Positive CHECK (TotalTime IS NULL OR TotalTime > 0);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Exam_Class_Time' AND object_id=OBJECT_ID('dbo.Exam'))
    CREATE INDEX IX_Exam_Class_Time
    ON dbo.Exam(IntakeID, BranchID, TrackID, StartTime)
    INCLUDE (CourseID, InstructorID, ExamType, EndTime, Year);
GO

/* PROC: إنشاء Exam (Header) */
CREATE OR ALTER PROCEDURE dbo.usp_CreateExam
    @CourseID INT,
    @InstructorID INT,
    @ExamType NVARCHAR(50),
    @StartTime DATETIME,
    @EndTime DATETIME,
    @TotalTime INT,
    @Year INT,
    @IntakeID INT = NULL,
    @BranchID INT = NULL,
    @TrackID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.InstructorCourse WHERE InstructorID=@InstructorID AND CourseID=@CourseID)
        THROW 50006, 'Instructor is not assigned to this course.', 1;

    INSERT INTO dbo.Exam
    (CourseID, InstructorID, IntakeID, BranchID, TrackID, ExamType, StartTime, EndTime, TotalTime, Year)
    VALUES
    (@CourseID, @InstructorID, @IntakeID, @BranchID, @TrackID, @ExamType, @StartTime, @EndTime, @TotalTime, @Year);

    SELECT SCOPE_IDENTITY() AS NewExamID;
END;
GO

/* VIEW: تفاصيل الامتحان (تعتمد على Exam + Course + Instructor + Intake/Branch/Track) */
CREATE OR ALTER VIEW dbo.vExamDetails
AS
SELECT
    e.ExamID, e.ExamType,
    e.CourseID, c.CourseName,
    e.InstructorID, i.Name AS InstructorName,
    e.Year,
    e.IntakeID, it.IntakeName,
    e.BranchID, b.BranchName,
    e.TrackID,  t.TrackName,
    e.StartTime, e.EndTime, e.TotalTime
FROM dbo.Exam e
JOIN dbo.Course c ON c.CourseID = e.CourseID
JOIN dbo.Instructor i ON i.InstructorID = e.InstructorID
LEFT JOIN dbo.Intake it ON it.IntakeID = e.IntakeID
LEFT JOIN dbo.Branch b ON b.BranchID = e.BranchID
LEFT JOIN dbo.Track t ON t.TrackID = e.TrackID;
GO

--------------------------------------------------------------------------------------

USE ExaminationSystem;
GO
/* ExamQuestion: degree موجب + Index + Trigger يمنع مجموع الدرجات يتخطى MaxDegree */

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_ExamQuestion_Degree_Positive')
    ALTER TABLE dbo.ExamQuestion
    ADD CONSTRAINT CK_ExamQuestion_Degree_Positive CHECK (Degree > 0);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_ExamQuestion_Exam' AND object_id=OBJECT_ID('dbo.ExamQuestion'))
    CREATE INDEX IX_ExamQuestion_Exam ON dbo.ExamQuestion(ExamID) INCLUDE (QuestionID, Degree);
GO

-- Functions مرتبطة بالحساب
CREATE OR ALTER FUNCTION dbo.fn_ExamTotalDegree (@ExamID INT)
RETURNS INT
AS
BEGIN
    DECLARE @t INT = 0;
    SELECT @t = SUM(eq.Degree) FROM dbo.ExamQuestion eq WHERE eq.ExamID = @ExamID;
    RETURN ISNULL(@t, 0);
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_CourseMaxDegree (@CourseID INT)
RETURNS INT
AS
BEGIN
    DECLARE @m INT;
    SELECT @m = MaxDegree FROM dbo.Course WHERE CourseID = @CourseID;
    RETURN ISNULL(@m, 0);
END;
GO

-- Trigger حماية حتى لو حد عمل INSERT مباشر
CREATE OR ALTER TRIGGER dbo.tr_ExamQuestion_MaxDegree
ON dbo.ExamQuestion
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM (SELECT DISTINCT ExamID FROM inserted) a
        JOIN dbo.Exam e ON e.ExamID = a.ExamID
        JOIN dbo.Course c ON c.CourseID = e.CourseID
        CROSS APPLY (
            SELECT SUM(eq.Degree) AS TotalDegree
            FROM dbo.ExamQuestion eq
            WHERE eq.ExamID = a.ExamID
        ) s
        WHERE s.TotalDegree > c.MaxDegree
    )
    BEGIN
        ROLLBACK;
        THROW 50102, 'Exam total degrees exceed course MaxDegree.', 1;
    END
END;
GO

/* PROC: إضافة سؤال للامتحان (مع check نفس الكورس + maxdegree) */
CREATE OR ALTER PROCEDURE dbo.usp_AddExamQuestion
    @ExamID INT,
    @QuestionID INT,
    @Degree INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @courseId INT;
    SELECT @courseId = CourseID FROM dbo.Exam WHERE ExamID=@ExamID;

    IF NOT EXISTS (SELECT 1 FROM dbo.Question WHERE QuestionID=@QuestionID AND CourseID=@courseId)
        THROW 50007, 'Question not from same course as exam.', 1;

    INSERT INTO dbo.ExamQuestion (ExamID, QuestionID, Degree)
    VALUES (@ExamID, @QuestionID, @Degree);

    IF dbo.fn_ExamTotalDegree(@ExamID) > dbo.fn_CourseMaxDegree(@courseId)
    BEGIN
        DELETE FROM dbo.ExamQuestion WHERE ExamID=@ExamID AND QuestionID=@QuestionID;
        THROW 50008, 'Total degrees exceed course MaxDegree.', 1;
    END
END;
GO

/* VIEW: أسئلة الامتحان */
CREATE OR ALTER VIEW dbo.vExamQuestions
AS
SELECT eq.ExamID, eq.QuestionID, q.QuestionText, q.QuestionType, eq.Degree
FROM dbo.ExamQuestion eq
JOIN dbo.Question q ON q.QuestionID = eq.QuestionID;
GO

------------------------------------------------------------------------------------------------
USE ExaminationSystem;
GO
/* StudentExam: Index + Proc assign */

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_StudentExam_Exam' AND object_id=OBJECT_ID('dbo.StudentExam'))
    CREATE INDEX IX_StudentExam_Exam ON dbo.StudentExam(ExamID) INCLUDE (StudentID, Status);
GO

CREATE OR ALTER PROCEDURE dbo.usp_AssignStudentToExam
    @ExamID INT,
    @StudentID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.StudentExam WHERE ExamID=@ExamID AND StudentID=@StudentID)
        RETURN;

    INSERT INTO dbo.StudentExam (StudentID, ExamID, Status)
    VALUES (@StudentID, @ExamID, 'Assigned');
END;
GO

-----------------------------------------------------------------------------------------------------------

USE ExaminationSystem;
GO
/* StudentAnswer: قيود + FK ناقص + Index + Trigger لمنع الإجابة لسؤال مش في الامتحان */

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_StudentAnswer_Mark_NonNegative')
    ALTER TABLE dbo.StudentAnswer
    ADD CONSTRAINT CK_StudentAnswer_Mark_NonNegative CHECK (Mark IS NULL OR Mark >= 0);
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_StudentAnswer_OneAnswerType')
    ALTER TABLE dbo.StudentAnswer
    ADD CONSTRAINT CK_StudentAnswer_OneAnswerType CHECK
    (
        (ChoiceID IS NOT NULL AND TextAnswer IS NULL)
        OR (ChoiceID IS NULL AND TextAnswer IS NOT NULL)
        OR (ChoiceID IS NULL AND TextAnswer IS NULL)
    );
GO

-- FK ناقص: QuestionID -> Question
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_StudentAnswer_Question')
    ALTER TABLE dbo.StudentAnswer
    ADD CONSTRAINT FK_StudentAnswer_Question FOREIGN KEY (QuestionID) REFERENCES dbo.Question(QuestionID);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_StudentAnswer_ExamStudent' AND object_id=OBJECT_ID('dbo.StudentAnswer'))
    CREATE INDEX IX_StudentAnswer_ExamStudent
    ON dbo.StudentAnswer(ExamID, StudentID) INCLUDE (QuestionID, IsCorrect, Mark);
GO

CREATE OR ALTER TRIGGER dbo.tr_StudentAnswer_QuestionInExam
ON dbo.StudentAnswer
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- لازم السؤال يكون ضمن ExamQuestion
    IF EXISTS (
        SELECT 1
        FROM inserted i
        LEFT JOIN dbo.ExamQuestion eq
            ON eq.ExamID=i.ExamID AND eq.QuestionID=i.QuestionID
        WHERE eq.QuestionID IS NULL
    )
    BEGIN
        ROLLBACK;
        THROW 50103, 'StudentAnswer must reference a question that exists in ExamQuestion for that exam.', 1;
    END

    -- لو ChoiceID موجود لازم يتبع نفس QuestionID
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN dbo.Choice c ON c.ChoiceID=i.ChoiceID
        WHERE i.ChoiceID IS NOT NULL AND c.QuestionID <> i.QuestionID
    )
    BEGIN
        ROLLBACK;
        THROW 50104, 'ChoiceID must belong to the same QuestionID.', 1;
    END
END;
GO

/* PROC: Submit MCQ/TF */
CREATE OR ALTER PROCEDURE dbo.usp_SubmitChoiceAnswer
    @StudentID INT,
    @ExamID INT,
    @QuestionID INT,
    @ChoiceID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.StudentExam WHERE StudentID=@StudentID AND ExamID=@ExamID)
        THROW 50011, 'Student not assigned to this exam.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.ExamQuestion WHERE ExamID=@ExamID AND QuestionID=@QuestionID)
        THROW 50012, 'Question not in this exam.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Choice WHERE ChoiceID=@ChoiceID AND QuestionID=@QuestionID)
        THROW 50013, 'Choice does not belong to this question.', 1;

    DECLARE @isCorrect BIT = 0, @degree INT = 0;
    SELECT @isCorrect = IsCorrect FROM dbo.Choice WHERE ChoiceID=@ChoiceID;
    SELECT @degree = Degree FROM dbo.ExamQuestion WHERE ExamID=@ExamID AND QuestionID=@QuestionID;

    DECLARE @mark INT = CASE WHEN @isCorrect=1 THEN @degree ELSE 0 END;

    MERGE dbo.StudentAnswer AS t
    USING (SELECT @StudentID AS StudentID, @ExamID AS ExamID, @QuestionID AS QuestionID) AS s
    ON (t.StudentID=s.StudentID AND t.ExamID=s.ExamID AND t.QuestionID=s.QuestionID)
    WHEN MATCHED THEN
        UPDATE SET ChoiceID=@ChoiceID, TextAnswer=NULL, IsCorrect=@isCorrect, Mark=@mark
    WHEN NOT MATCHED THEN
        INSERT (StudentID, ExamID, QuestionID, ChoiceID, TextAnswer, IsCorrect, Mark)
        VALUES (@StudentID, @ExamID, @QuestionID, @ChoiceID, NULL, @isCorrect, @mark);
END;
GO

/* PROC: Submit Text (Auto check بسيط) */
CREATE OR ALTER PROCEDURE dbo.usp_SubmitTextAnswer
    @StudentID INT,
    @ExamID INT,
    @QuestionID INT,
    @TextAnswer NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.StudentExam WHERE StudentID=@StudentID AND ExamID=@ExamID)
        THROW 50014, 'Student not assigned to this exam.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.ExamQuestion WHERE ExamID=@ExamID AND QuestionID=@QuestionID)
        THROW 50015, 'Question not in this exam.', 1;

    DECLARE @accepted NVARCHAR(MAX);
    SELECT @accepted = AcceptedAnswer FROM dbo.TextAnswer WHERE QuestionID=@QuestionID;

    DECLARE @isCorrect BIT = 0;
    IF @accepted IS NOT NULL AND CHARINDEX(LOWER(@accepted), LOWER(@TextAnswer)) > 0
        SET @isCorrect = 1;

    MERGE dbo.StudentAnswer AS t
    USING (SELECT @StudentID AS StudentID, @ExamID AS ExamID, @QuestionID AS QuestionID) AS s
    ON (t.StudentID=s.StudentID AND t.ExamID=s.ExamID AND t.QuestionID=s.QuestionID)
    WHEN MATCHED THEN
        UPDATE SET ChoiceID=NULL, TextAnswer=@TextAnswer, IsCorrect=@isCorrect, Mark=NULL
    WHEN NOT MATCHED THEN
        INSERT (StudentID, ExamID, QuestionID, ChoiceID, TextAnswer, IsCorrect, Mark)
        VALUES (@StudentID, @ExamID, @QuestionID, NULL, @TextAnswer, @isCorrect, NULL);
END;
GO

/* PROC: Instructor review Text */
CREATE OR ALTER PROCEDURE dbo.usp_ReviewTextAnswer
    @InstructorID INT,
    @StudentID INT,
    @ExamID INT,
    @QuestionID INT,
    @Mark INT,
    @IsCorrect BIT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Exam WHERE ExamID=@ExamID AND InstructorID=@InstructorID)
        THROW 50016, 'Instructor does not own this exam.', 1;

    DECLARE @degree INT;
    SELECT @degree = Degree FROM dbo.ExamQuestion WHERE ExamID=@ExamID AND QuestionID=@QuestionID;

    IF @Mark < 0 OR @Mark > @degree
        THROW 50017, 'Mark must be between 0 and question degree.', 1;

    UPDATE dbo.StudentAnswer
    SET Mark=@Mark, IsCorrect=@IsCorrect
    WHERE StudentID=@StudentID AND ExamID=@ExamID AND QuestionID=@QuestionID;
END;
GO

---------------------------------------------------------------
USE ExaminationSystem;
GO
/* Result: View للـ PASS/FAIL + Proc لإعادة حساب نتيجة طالب في كورس */

CREATE OR ALTER VIEW dbo.vStudentCourseResult
AS
SELECT
    r.StudentID,
    s.Name AS StudentName,
    r.CourseID,
    c.CourseName,
    r.TotalMark,
    c.MinDegree,
    c.MaxDegree,
    CASE WHEN r.TotalMark >= c.MinDegree THEN 'PASS' ELSE 'FAIL' END AS ResultStatus
FROM dbo.Result r
JOIN dbo.Student s ON s.StudentID = r.StudentID
JOIN dbo.Course c ON c.CourseID = r.CourseID;
GO

CREATE OR ALTER PROCEDURE dbo.usp_RecalculateCourseResultForStudent
    @StudentID INT,
    @CourseID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @total INT = 0;

    SELECT @total = SUM(ISNULL(sa.Mark,0))
    FROM dbo.StudentAnswer sa
    JOIN dbo.Exam e ON e.ExamID = sa.ExamID
    WHERE sa.StudentID=@StudentID AND e.CourseID=@CourseID;

    MERGE dbo.Result AS t
    USING (SELECT @StudentID AS StudentID, @CourseID AS CourseID) AS s
    ON (t.StudentID=s.StudentID AND t.CourseID=s.CourseID)
    WHEN MATCHED THEN UPDATE SET TotalMark=@total
    WHEN NOT MATCHED THEN INSERT (StudentID, CourseID, TotalMark) VALUES (@StudentID, @CourseID, @total);
END;
GO

-------------------------------------------------------------------------------------------------------------------------


-- 7.A) Backup stored proc
BACKUP DATABASE [ExaminationSystem]
TO DISK = 'D:\Backups\Backups.bak'
WITH
    INIT,             
                       
    CHECKSUM,          
    STATS = 10;



 -- Differential Backup
BACKUP DATABASE [ExaminationSystem]
TO DISK = 'D:\Backups\Backups2.bak'
WITH
    DIFFERENTIAL,
    NOINIT,      
    CHECKSUM,
    STATS = 10;
