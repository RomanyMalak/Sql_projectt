
-- ============================================================
-- SECTION 8: TEST DATA
-- ============================================================

-- Branches
EXEC sp_AddBranch 'Cairo Branch',      'Cairo, Egypt';
EXEC sp_AddBranch 'Alexandria Branch', 'Alexandria, Egypt';
EXEC sp_AddBranch 'Giza Branch',       'Giza, Egypt';

-- Tracks
EXEC sp_AddTrack 1, 'Software Development', 'Full-stack web development';
EXEC sp_AddTrack 1, 'Data Science',         'Machine learning and analytics';
EXEC sp_AddTrack 2, 'Cybersecurity',        'Network and application security';
EXEC sp_AddTrack 3, 'Mobile Development',   'iOS and Android development';

-- Intakes
EXEC sp_AddIntake 'Intake 44', '2023-09-01', '2024-06-30';
EXEC sp_AddIntake 'Intake 45', '2024-03-01', '2024-12-31';
EXEC sp_AddIntake 'Intake 46', '2024-09-01', '2025-06-30';

-- Courses (direct INSERT — no procedure wraps Course)
INSERT INTO Course (CourseName, Description, MaxDegree, MinDegree) VALUES
                                                                       ('SQL Server',      'Database design and T-SQL programming', 100, 50),
                                                                       ('C# Programming',  'Object-oriented programming with C#',   100, 50),
                                                                       ('HTML & CSS',      'Web frontend fundamentals',             100, 50),
                                                                       ('Python Basics',   'Introduction to Python programming',    100, 50),
                                                                       ('Data Analysis',   'Data analysis with Python and pandas',  100, 50);

-- Instructors (InstructorID 1 = Training Manager)
EXEC sp_AddInstructor 'tm.ahmed',   'hashed_pass_1', 'Ahmed',  'Salah',   'ahmed.salah@iti.gov.eg',   '01001112233', 1;
EXEC sp_AddInstructor 'ins.sara',   'hashed_pass_2', 'Sara',   'Mohamed', 'sara.mohamed@iti.gov.eg',  '01112223344', 0;
EXEC sp_AddInstructor 'ins.khaled', 'hashed_pass_3', 'Khaled', 'Hassan',  'khaled.hassan@iti.gov.eg', '01223334455', 0;
EXEC sp_AddInstructor 'ins.mona',   'hashed_pass_4', 'Mona',   'Ali',     'mona.ali@iti.gov.eg',      '01334445566', 0;

-- Assign instructors to courses
-- (InstructorID, CourseID, IntakeID, BranchID, TrackID, AcademicYear)
EXEC sp_AssignInstructorToCourse 1, 1, 1, 1, 1, 2024;  -- Ahmed  -> SQL Server
EXEC sp_AssignInstructorToCourse 2, 2, 1, 1, 1, 2024;  -- Sara   -> C#
EXEC sp_AssignInstructorToCourse 3, 3, 1, 1, 1, 2024;  -- Khaled -> HTML & CSS
EXEC sp_AssignInstructorToCourse 1, 4, 2, 1, 2, 2024;  -- Ahmed  -> Python, Intake45, DS track
EXEC sp_AssignInstructorToCourse 4, 5, 2, 2, 3, 2024;  -- Mona   -> Data Analysis, Alex, Cyber

-- Students
EXEC sp_AddStudent 'std.ali',    'hashed_s1', 1,1,1, 'Ali',    'Ibrahim', 'ali.ibrahim@student.com',    '01500001111', '2001-05-10', '28501012345678';
EXEC sp_AddStudent 'std.nour',   'hashed_s2', 1,1,1, 'Nour',   'Mahmoud', 'nour.mahmoud@student.com',   '01500002222', '2002-03-20', '28703022345679';
EXEC sp_AddStudent 'std.omar',   'hashed_s3', 1,1,1, 'Omar',   'Youssef', 'omar.youssef@student.com',   '01500003333', '2001-11-05', '28611032345680';
EXEC sp_AddStudent 'std.rania',  'hashed_s4', 1,1,1, 'Rania',  'Tarek',   'rania.tarek@student.com',    '01500004444', '2003-07-15', '28907042345681';
EXEC sp_AddStudent 'std.hassan', 'hashed_s5', 2,1,2, 'Hassan', 'Farouk',  'hassan.farouk@student.com',  '01500005555', '2000-12-01', '28012052345682';
EXEC sp_AddStudent 'std.aya',    'hashed_s6', 2,2,3, 'Aya',    'Saber',   'aya.saber@student.com',      '01500006666', '2002-08-25', '28208062345683';

-- Questions for SQL Server (CourseID=1, InstructorID=1)
DECLARE @Q1 INT, @Q2 INT, @Q3 INT, @Q4 INT, @Q5 INT, @Q6 INT, @Q7 INT, @Q8 INT;

EXEC sp_AddQuestion 1, 1, 'MCQ', 'Which SQL statement retrieves data from a database?', NULL, 'Easy';
SET @Q1 = IDENT_CURRENT('Question');
EXEC sp_AddQuestionChoice @Q1, 'SELECT', 1, 1;
EXEC sp_AddQuestionChoice @Q1, 'INSERT', 0, 2;
EXEC sp_AddQuestionChoice @Q1, 'UPDATE', 0, 3;
EXEC sp_AddQuestionChoice @Q1, 'DELETE', 0, 4;

EXEC sp_AddQuestion 1, 1, 'MCQ', 'What does the PRIMARY KEY constraint do?', NULL, 'Easy';
SET @Q2 = IDENT_CURRENT('Question');
EXEC sp_AddQuestionChoice @Q2, 'Allows NULL values',          0, 1;
EXEC sp_AddQuestionChoice @Q2, 'Uniquely identifies each row', 1, 2;
EXEC sp_AddQuestionChoice @Q2, 'Links two tables',             0, 3;
EXEC sp_AddQuestionChoice @Q2, 'Creates an index only',        0, 4;

EXEC sp_AddQuestion 1, 1, 'TrueFalse', 'A FOREIGN KEY can reference a non-primary key column.', NULL, 'Medium';
SET @Q3 = IDENT_CURRENT('Question');
EXEC sp_AddQuestionChoice @Q3, 'True',  1, 1;
EXEC sp_AddQuestionChoice @Q3, 'False', 0, 2;

EXEC sp_AddQuestion 1, 1, 'TrueFalse', 'A table can have multiple PRIMARY KEY constraints.', NULL, 'Easy';
SET @Q4 = IDENT_CURRENT('Question');
EXEC sp_AddQuestionChoice @Q4, 'True',  0, 1;
EXEC sp_AddQuestionChoice @Q4, 'False', 1, 2;

EXEC sp_AddQuestion 1, 1, 'Text',
     'Explain the difference between WHERE and HAVING in SQL.',
     'WHERE filters rows before grouping; HAVING filters groups after GROUP BY.',
     'Medium';
SET @Q5 = IDENT_CURRENT('Question');

EXEC sp_AddQuestion 1, 1, 'Text',
     'What is normalization? Explain 1NF, 2NF, and 3NF.',
     'Normalization organises data to reduce redundancy. 1NF: atomic values; 2NF: full functional dependency; 3NF: no transitive dependency.',
     'Hard';
SET @Q6 = IDENT_CURRENT('Question');

EXEC sp_AddQuestion 1, 1, 'MCQ', 'Which JOIN returns all rows from both tables?', NULL, 'Medium';
SET @Q7 = IDENT_CURRENT('Question');
EXEC sp_AddQuestionChoice @Q7, 'INNER JOIN',      0, 1;
EXEC sp_AddQuestionChoice @Q7, 'LEFT JOIN',       0, 2;
EXEC sp_AddQuestionChoice @Q7, 'FULL OUTER JOIN', 1, 3;
EXEC sp_AddQuestionChoice @Q7, 'CROSS JOIN',      0, 4;

EXEC sp_AddQuestion 1, 1, 'MCQ', 'What is the default sort order of ORDER BY?', NULL, 'Easy';
SET @Q8 = IDENT_CURRENT('Question');
EXEC sp_AddQuestionChoice @Q8, 'DESC', 0, 1;
EXEC sp_AddQuestionChoice @Q8, 'ASC',  1, 2;
EXEC sp_AddQuestionChoice @Q8, 'RAND', 0, 3;
EXEC sp_AddQuestionChoice @Q8, 'NONE', 0, 4;

-- Create exam (CourseID=1, InstructorID=1, IntakeID=1, BranchID=1, TrackID=1, Year=2024)
DECLARE @ExamID INT;
EXEC sp_CreateExam 1, 1, 1, 1, 1, 2024, 'Exam', 'SQL Server Midterm Exam',
     '2024-11-15 09:00', '2024-11-15 11:00', 120, NULL;
SET @ExamID = IDENT_CURRENT('Exam');

-- Add questions to exam with degrees
EXEC sp_AddQuestionToExam @ExamID, @Q1, 10, 1;
EXEC sp_AddQuestionToExam @ExamID, @Q2, 10, 2;
EXEC sp_AddQuestionToExam @ExamID, @Q3, 10, 3;
EXEC sp_AddQuestionToExam @ExamID, @Q4, 10, 4;
EXEC sp_AddQuestionToExam @ExamID, @Q5, 30, 5;
EXEC sp_AddQuestionToExam @ExamID, @Q7, 10, 6;
EXEC sp_AddQuestionToExam @ExamID, @Q8, 10, 7;

-- Publish exam
UPDATE Exam SET IsPublished = 1 WHERE ExamID = @ExamID;

-- Enroll students
DECLARE @SE1 INT, @SE2 INT, @SE3 INT;
EXEC sp_EnrollStudentInExam 1, @ExamID, '2024-11-15'; SET @SE1 = IDENT_CURRENT('StudentExam');
EXEC sp_EnrollStudentInExam 2, @ExamID, '2024-11-15'; SET @SE2 = IDENT_CURRENT('StudentExam');
EXEC sp_EnrollStudentInExam 3, @ExamID, '2024-11-15'; SET @SE3 = IDENT_CURRENT('StudentExam');

-- Resolve ExamQuestionIDs for answer submission
DECLARE @EQ1 INT, @EQ2 INT, @EQ3 INT, @EQ4 INT, @EQ5 INT, @EQ6 INT, @EQ7 INT;
SELECT @EQ1 = ExamQuestionID FROM ExamQuestion WHERE ExamID = @ExamID AND QuestionID = @Q1;
SELECT @EQ2 = ExamQuestionID FROM ExamQuestion WHERE ExamID = @ExamID AND QuestionID = @Q2;
SELECT @EQ3 = ExamQuestionID FROM ExamQuestion WHERE ExamID = @ExamID AND QuestionID = @Q3;
SELECT @EQ4 = ExamQuestionID FROM ExamQuestion WHERE ExamID = @ExamID AND QuestionID = @Q4;
SELECT @EQ5 = ExamQuestionID FROM ExamQuestion WHERE ExamID = @ExamID AND QuestionID = @Q5;
SELECT @EQ6 = ExamQuestionID FROM ExamQuestion WHERE ExamID = @ExamID AND QuestionID = @Q7;
SELECT @EQ7 = ExamQuestionID FROM ExamQuestion WHERE ExamID = @ExamID AND QuestionID = @Q8;

-- Student 1: all correct
EXEC sp_SubmitStudentAnswer @SE1, @EQ1, 1,  NULL;
EXEC sp_SubmitStudentAnswer @SE1, @EQ2, 6,  NULL;
EXEC sp_SubmitStudentAnswer @SE1, @EQ3, 9,  NULL;
EXEC sp_SubmitStudentAnswer @SE1, @EQ4, 12, NULL;
EXEC sp_SubmitStudentAnswer @SE1, @EQ5, NULL, 'WHERE filters rows before grouping; HAVING filters after GROUP BY on aggregated results.';
EXEC sp_SubmitStudentAnswer @SE1, @EQ6, 15, NULL;
EXEC sp_SubmitStudentAnswer @SE1, @EQ7, 18, NULL;
EXEC sp_FinalizeStudentExam @SE1;

-- Instructor reviews Student 1 text answer
DECLARE @TextAnswerID INT;
SELECT @TextAnswerID = AnswerID
FROM StudentAnswer
WHERE StudentExamID = @SE1 AND ExamQuestionID = @EQ5;
EXEC sp_ReviewTextAnswer @TextAnswerID, 1, 28, 'Good answer — demonstrates understanding of both clauses.';

EXEC sp_RecalcStudentScore @SE1;

-- Student 2: some wrong
EXEC sp_SubmitStudentAnswer @SE2, @EQ1, 2,  NULL;   -- wrong
EXEC sp_SubmitStudentAnswer @SE2, @EQ2, 6,  NULL;   -- correct
EXEC sp_SubmitStudentAnswer @SE2, @EQ3, 9,  NULL;   -- correct
EXEC sp_SubmitStudentAnswer @SE2, @EQ4, 11, NULL;   -- wrong
EXEC sp_SubmitStudentAnswer @SE2, @EQ5, NULL, 'WHERE is used to filter, HAVING is also for filtering.';
EXEC sp_SubmitStudentAnswer @SE2, @EQ6, 14, NULL;   -- wrong
EXEC sp_SubmitStudentAnswer @SE2, @EQ7, 18, NULL;   -- correct
EXEC sp_FinalizeStudentExam @SE2;
EXEC sp_RecalcStudentScore @SE2;
GO
