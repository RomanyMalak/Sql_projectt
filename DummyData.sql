-- ============================================================
-- EXAMINATION SYSTEM DATABASE
-- Dummy / Test Data
-- Run AFTER Abdulrahman_Refactored.sql
-- ============================================================

USE ExaminationSystem;
GO

-- ============================================================
-- SECTION 1: USERS
-- ============================================================
-- Passwords are stored as hashes (plain text shown in comments)
-- Format: Role + sequence for easy identification

INSERT INTO Users (Username, PasswordHash, Role) VALUES
('admin.manager',   'hash_Manager@123',    'Manager'),
('sara.manager',    'hash_Manager@456',    'Manager'),
('ahmed.inst',      'hash_Inst@123',       'Instructor'),
('mona.inst',       'hash_Inst@456',       'Instructor'),
('khaled.inst',     'hash_Inst@789',       'Instructor'),
('layla.inst',      'hash_Inst@321',       'Instructor'),
('ali.student',     'hash_Stud@001',       'Student'),
('nour.student',    'hash_Stud@002',       'Student'),
('omar.student',    'hash_Stud@003',       'Student'),
('hana.student',    'hash_Stud@004',       'Student'),
('youssef.student', 'hash_Stud@005',       'Student'),
('dina.student',    'hash_Stud@006',       'Student'),
('tarek.student',   'hash_Stud@007',       'Student'),
('reem.student',    'hash_Stud@008',       'Student'),
('kareem.student',  'hash_Stud@009',       'Student'),
('salma.student',   'hash_Stud@010',       'Student');
GO

-- ============================================================
-- SECTION 2: DEPARTMENTS
-- ============================================================

INSERT INTO Department (DepartmentName) VALUES
('Computer Science'),
('Information Technology'),
('Software Engineering'),
('Data Science');
GO

-- ============================================================
-- SECTION 3: BRANCHES
-- ============================================================

INSERT INTO Branch (BranchName) VALUES
('Cairo Branch'),
('Alexandria Branch'),
('Giza Branch'),
('Aswan Branch');
GO

-- ============================================================
-- SECTION 4: TRACKS
-- ============================================================
-- DepartmentID: 1=CS, 2=IT, 3=SE, 4=DS

INSERT INTO Track (TrackName, DepartmentID) VALUES
('Backend Development',    1),
('Frontend Development',   1),
('Database Administration',2),
('Network Engineering',    2),
('Mobile Development',     3),
('DevOps',                 3),
('Machine Learning',       4),
('Business Intelligence',  4);
GO

-- ============================================================
-- SECTION 5: INTAKES
-- ============================================================

INSERT INTO Intake (IntakeName, StartDate, EndDate) VALUES
('Intake 40', '2022-09-01', '2023-06-30'),
('Intake 41', '2023-09-01', '2024-06-30'),
('Intake 42', '2024-09-01', '2025-06-30'),
('Intake 43', '2025-09-01', '2026-06-30');
GO

-- ============================================================
-- SECTION 6: INSTRUCTORS
-- ============================================================
-- UserID: 3=ahmed.inst, 4=mona.inst, 5=khaled.inst, 6=layla.inst

INSERT INTO Instructor (UserID, Name, Email) VALUES
(3, 'Ahmed Hassan',   'ahmed.hassan@exam.edu'),
(4, 'Mona Saleh',     'mona.saleh@exam.edu'),
(5, 'Khaled Nasser',  'khaled.nasser@exam.edu'),
(6, 'Layla Ibrahim',  'layla.ibrahim@exam.edu');
GO

-- ============================================================
-- SECTION 7: STUDENTS
-- ============================================================
-- UserIDs: 7–16 | BranchIDs: 1–4 | TrackIDs: 1–8 | IntakeIDs: 1–4

INSERT INTO Student (UserID, Name, Email, BranchID, TrackID, IntakeID) VALUES
(7,  'Ali Mahmoud',      'ali.mahmoud@student.edu',     1, 1, 2),
(8,  'Nour Adel',        'nour.adel@student.edu',        1, 1, 2),
(9,  'Omar Farouk',      'omar.farouk@student.edu',      2, 2, 2),
(10, 'Hana Mostafa',     'hana.mostafa@student.edu',     2, 3, 3),
(11, 'Youssef Sami',     'youssef.sami@student.edu',     1, 1, 3),
(12, 'Dina Walid',       'dina.walid@student.edu',       3, 5, 2),
(13, 'Tarek Kamal',      'tarek.kamal@student.edu',      3, 5, 2),
(14, 'Reem Ashraf',      'reem.ashraf@student.edu',      4, 7, 3),
(15, 'Kareem Yasser',    'kareem.yasser@student.edu',    4, 7, 3),
(16, 'Salma Nabil',      'salma.nabil@student.edu',      1, 2, 4);
GO

-- ============================================================
-- SECTION 8: COURSES
-- ============================================================

INSERT INTO Course (CourseName, Description, MaxDegree, MinDegree) VALUES
('Database Fundamentals',    'Intro to relational databases, SQL basics',           100, 50),
('Web Development Basics',   'HTML, CSS, JavaScript foundations',                   100, 50),
('Python Programming',       'Core Python language and OOP concepts',               100, 50),
('Data Structures',          'Arrays, linked lists, trees, graphs',                 100, 60),
('Operating Systems',        'Process management, memory, file systems',             80, 40),
('Machine Learning 101',     'Supervised & unsupervised learning fundamentals',     100, 50),
('Mobile App Development',   'Cross-platform mobile development with Flutter',      100, 50),
('Network Fundamentals',     'TCP/IP, routing, switching, and network security',     80, 40);
GO

-- ============================================================
-- SECTION 9: INSTRUCTOR-COURSE ASSIGNMENTS
-- ============================================================
-- InstructorIDs: 1=Ahmed, 2=Mona, 3=Khaled, 4=Layla
-- CourseIDs: 1–8

INSERT INTO InstructorCourse (InstructorID, CourseID, Year, BranchID, TrackID, IntakeID) VALUES
(1, 1, 2023, 1, 1, 2),   -- Ahmed teaches DB Fundamentals, Cairo, Backend, Intake41
(1, 1, 2024, 1, 1, 3),   -- Ahmed teaches DB Fundamentals again, Intake42
(2, 2, 2023, 1, 2, 2),   -- Mona teaches Web Dev, Cairo, Frontend, Intake41
(2, 2, 2024, 1, 2, 3),   -- Mona teaches Web Dev, Intake42
(3, 3, 2023, 2, 1, 2),   -- Khaled teaches Python, Alexandria, Intake41
(3, 4, 2024, 2, 1, 3),   -- Khaled teaches Data Structures, Intake42
(4, 6, 2024, 4, 7, 3),   -- Layla teaches ML101, Aswan, ML Track, Intake42
(1, 5, 2024, 1, 3, 3),   -- Ahmed teaches OS, Cairo, DBA Track, Intake42
(2, 7, 2023, 3, 5, 2),   -- Mona teaches Mobile Dev, Giza, Intake41
(3, 8, 2024, 2, 4, 3);   -- Khaled teaches Networks, Alexandria, Intake42
GO

-- ============================================================
-- SECTION 10: QUESTIONS
-- ============================================================

-- ---- Course 1: Database Fundamentals (InstructorID = 1) ----

-- MCQ Questions
INSERT INTO Question (CourseID, InstructorID, QuestionText, QuestionType) VALUES
(1, 1, 'Which SQL statement is used to retrieve data from a database?',                         'MCQ'),
(1, 1, 'Which of the following is NOT a valid SQL aggregate function?',                         'MCQ'),
(1, 1, 'What does the PRIMARY KEY constraint enforce?',                                         'MCQ'),
(1, 1, 'Which JOIN returns all rows from both tables including unmatched rows?',                 'MCQ'),
(1, 1, 'What is the correct SQL clause to filter grouped results?',                              'MCQ');

-- TF Questions
INSERT INTO Question (CourseID, InstructorID, QuestionText, QuestionType) VALUES
(1, 1, 'A foreign key can reference a column in the same table.',                                'TF'),
(1, 1, 'NULL values are considered equal in SQL comparisons.',                                   'TF'),
(1, 1, 'The GROUP BY clause must come before the WHERE clause in a SELECT statement.',           'TF');

-- Text Questions
INSERT INTO Question (CourseID, InstructorID, QuestionText, QuestionType) VALUES
(1, 1, 'Explain the difference between DELETE and TRUNCATE in SQL.',                             'Text'),
(1, 1, 'What is database normalization and why is it important?',                                'Text');


-- ---- Course 2: Web Development Basics (InstructorID = 2) ----

INSERT INTO Question (CourseID, InstructorID, QuestionText, QuestionType) VALUES
(2, 2, 'Which HTML tag is used to create a hyperlink?',                                          'MCQ'),
(2, 2, 'Which CSS property is used to change the text color?',                                   'MCQ'),
(2, 2, 'Which JavaScript method is used to select an element by its ID?',                        'MCQ'),
(2, 2, 'HTML stands for HyperText Markup Language.',                                             'TF'),
(2, 2, 'CSS can only be applied using an external stylesheet.',                                  'TF'),
(2, 2, 'Describe the difference between block-level and inline HTML elements.',                  'Text');


-- ---- Course 3: Python Programming (InstructorID = 3) ----

INSERT INTO Question (CourseID, InstructorID, QuestionText, QuestionType) VALUES
(3, 3, 'Which keyword is used to define a function in Python?',                                  'MCQ'),
(3, 3, 'What is the output of: print(type(3.14))?',                                              'MCQ'),
(3, 3, 'Which of the following is a mutable data type in Python?',                               'MCQ'),
(3, 3, 'Python is a statically typed language.',                                                 'TF'),
(3, 3, 'Indentation is optional in Python.',                                                     'TF'),
(3, 3, 'Explain the concept of list comprehension in Python with an example.',                   'Text');


-- ---- Course 6: Machine Learning 101 (InstructorID = 4) ----

INSERT INTO Question (CourseID, InstructorID, QuestionText, QuestionType) VALUES
(6, 4, 'Which algorithm is used for classification tasks?',                                      'MCQ'),
(6, 4, 'What does overfitting mean in machine learning?',                                        'MCQ'),
(6, 4, 'Supervised learning requires labeled training data.',                                    'TF'),
(6, 4, 'A neural network can only solve linear problems.',                                       'TF'),
(6, 4, 'What is the difference between supervised and unsupervised learning?',                   'Text');
GO

-- ============================================================
-- SECTION 11: CHOICES  (MCQ & TF)
-- ============================================================
-- QuestionIDs reference the order of inserts above:
--   1–5   : DB MCQ  | 6–8  : DB TF
--   11–13 : Web MCQ | 14–15: Web TF
--   17–19 : Py MCQ  | 20–21: Py TF
--   23–24 : ML MCQ  | 25–26: ML TF

-- Q1: Which SQL statement retrieves data?
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect) VALUES
(1, 'SELECT',  1),
(1, 'INSERT',  0),
(1, 'UPDATE',  0),
(1, 'DELETE',  0);

-- Q2: NOT a valid aggregate function?
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect) VALUES
(2, 'SUM',     0),
(2, 'AVG',     0),
(2, 'TOTAL',   1),
(2, 'COUNT',   0);

-- Q3: What does PRIMARY KEY enforce?
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect) VALUES
(3, 'Uniqueness and NOT NULL',  1),
(3, 'Only uniqueness',          0),
(3, 'Only NOT NULL',            0),
(3, 'Referential integrity',    0);

-- Q4: Which JOIN returns all rows from both tables?
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect) VALUES
(4, 'INNER JOIN',  0),
(4, 'LEFT JOIN',   0),
(4, 'RIGHT JOIN',  0),
(4, 'FULL OUTER JOIN', 1);

-- Q5: Clause to filter grouped results?
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect) VALUES
(5, 'WHERE',   0),
(5, 'HAVING',  1),
(5, 'FILTER',  0),
(5, 'GROUP',   0);

-- Q6 TF: Foreign key can reference same table?
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect) VALUES
(6, 'True',   1),
(6, 'False',  0);

-- Q7 TF: NULL values are equal in comparisons?
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect) VALUES
(7, 'True',   0),
(7, 'False',  1);

-- Q8 TF: GROUP BY must come before WHERE?
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect) VALUES
(8, 'True',   0),
(8, 'False',  1);

-- Q11: HTML hyperlink tag?
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect) VALUES
(11, '<a>',    1),
(11, '<link>', 0),
(11, '<href>', 0),
(11, '<url>',  0);

-- Q12: CSS text color property?
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect) VALUES
(12, 'font-color',  0),
(12, 'text-color',  0),
(12, 'color',       1),
(12, 'foreground',  0);

-- Q13: JS select by ID?
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect) VALUES
(13, 'document.getElement()',          0),
(13, 'document.getElementById()',      1),
(13, 'document.selectById()',          0),
(13, 'document.querySelector(".id")',  0);

-- Q14 TF: HTML stands for HyperText Markup Language?
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect) VALUES
(14, 'True',   1),
(14, 'False',  0);

-- Q15 TF: CSS only via external stylesheet?
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect) VALUES
(15, 'True',   0),
(15, 'False',  1);

-- Q17: Python function keyword?
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect) VALUES
(17, 'function',  0),
(17, 'def',       1),
(17, 'fun',       0),
(17, 'define',    0);

-- Q18: type(3.14) output?
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect) VALUES
(18, "<class 'int'>",    0),
(18, "<class 'float'>",  1),
(18, "<class 'double'>", 0),
(18, "<class 'num'>",    0);

-- Q19: Mutable data type in Python?
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect) VALUES
(19, 'Tuple',   0),
(19, 'String',  0),
(19, 'List',    1),
(19, 'Integer', 0);

-- Q20 TF: Python is statically typed?
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect) VALUES
(20, 'True',   0),
(20, 'False',  1);

-- Q21 TF: Indentation is optional in Python?
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect) VALUES
(21, 'True',   0),
(21, 'False',  1);

-- Q23: Classification algorithm?
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect) VALUES
(23, 'K-Means',               0),
(23, 'Linear Regression',     0),
(23, 'Decision Tree',         1),
(23, 'PCA',                   0);

-- Q24: What does overfitting mean?
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect) VALUES
(24, 'Model performs well on training but poorly on new data',  1),
(24, 'Model performs poorly on both training and test data',    0),
(24, 'Model is too simple to capture patterns',                 0),
(24, 'Model has too few parameters',                            0);

-- Q25 TF: Supervised learning needs labeled data?
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect) VALUES
(25, 'True',   1),
(25, 'False',  0);

-- Q26 TF: Neural network only solves linear problems?
INSERT INTO Choice (QuestionID, ChoiceText, IsCorrect) VALUES
(26, 'True',   0),
(26, 'False',  1);
GO

-- ============================================================
-- SECTION 12: TEXT ANSWERS
-- ============================================================

-- Q9: DELETE vs TRUNCATE
INSERT INTO TextAnswer (QuestionID, AcceptedAnswer) VALUES
(9, 'DELETE removes rows one at a time and can be rolled back, while TRUNCATE removes all rows at once and cannot be rolled back');

-- Q10: Database normalization
INSERT INTO TextAnswer (QuestionID, AcceptedAnswer) VALUES
(10, 'Normalization is the process of organizing a database to reduce redundancy and improve data integrity');

-- Q16: Block vs Inline HTML elements
INSERT INTO TextAnswer (QuestionID, AcceptedAnswer) VALUES
(16, 'Block-level elements start on a new line and take full width, while inline elements do not start on a new line and only take necessary width');

-- Q22: List comprehension
INSERT INTO TextAnswer (QuestionID, AcceptedAnswer) VALUES
(22, 'List comprehension is a concise way to create lists using a single line expression with an optional condition');

-- Q27: Supervised vs Unsupervised
INSERT INTO TextAnswer (QuestionID, AcceptedAnswer) VALUES
(27, 'Supervised learning uses labeled data to train a model, while unsupervised learning finds patterns in unlabeled data');
GO

-- ============================================================
-- SECTION 13: EXAMS
-- ============================================================
-- CourseID 1 = DB Fundamentals, InstructorID 1 = Ahmed
-- CourseID 2 = Web Dev,         InstructorID 2 = Mona
-- CourseID 3 = Python,          InstructorID 3 = Khaled
-- CourseID 6 = ML101,           InstructorID 4 = Layla

INSERT INTO Exam (CourseID, InstructorID, IntakeID, BranchID, TrackID,
                  ExamType, StartTime, EndTime, TotalTime, Year, AllowanceOptions) VALUES
(1, 1, 2, 1, 1, 'Exam',       '2024-01-15 09:00', '2024-01-15 11:00', 120, 2024, 'Open Book'),
(1, 1, 2, 1, 1, 'Corrective', '2024-02-10 09:00', '2024-02-10 10:00',  60, 2024, NULL),
(2, 2, 2, 1, 2, 'Exam',       '2024-01-20 10:00', '2024-01-20 12:00', 120, 2024, NULL),
(3, 3, 2, 2, 1, 'Exam',       '2024-01-22 09:00', '2024-01-22 11:00', 120, 2024, NULL),
(6, 4, 3, 4, 7, 'Exam',       '2024-03-05 09:00', '2024-03-05 11:00', 120, 2024, NULL);
GO

-- ============================================================
-- SECTION 14: EXAM QUESTIONS  (with degrees per question)
-- ============================================================

-- Exam 1: DB Fundamentals (questions from course 1)
-- 3 MCQ (Q1,Q2,Q3) + 2 TF (Q6,Q7) + 1 Text (Q9) = 60 pts total
INSERT INTO ExamQuestion (ExamID, QuestionID, Degree) VALUES
(1, 1,  15),   -- MCQ
(1, 2,  15),   -- MCQ
(1, 3,  10),   -- MCQ
(1, 6,  10),   -- TF
(1, 7,  10),   -- TF
(1, 9,  20);   -- Text

-- Exam 2: DB Corrective (fewer questions, lighter)
INSERT INTO ExamQuestion (ExamID, QuestionID, Degree) VALUES
(2, 4,  25),
(2, 5,  25),
(2, 8,  25),
(2, 10, 25);

-- Exam 3: Web Dev
INSERT INTO ExamQuestion (ExamID, QuestionID, Degree) VALUES
(3, 11, 20),
(3, 12, 20),
(3, 13, 20),
(3, 14, 20),
(3, 16, 20);

-- Exam 4: Python
INSERT INTO ExamQuestion (ExamID, QuestionID, Degree) VALUES
(4, 17, 20),
(4, 18, 20),
(4, 19, 20),
(4, 20, 20),
(4, 22, 20);

-- Exam 5: ML101
INSERT INTO ExamQuestion (ExamID, QuestionID, Degree) VALUES
(5, 23, 25),
(5, 24, 25),
(5, 25, 25),
(5, 27, 25);
GO

-- ============================================================
-- SECTION 15: STUDENT EXAM ENROLLMENTS
-- ============================================================
-- StudentIDs: 1=Ali, 2=Nour, 3=Omar, 4=Hana, 5=Youssef,
--             6=Dina, 7=Tarek, 8=Reem, 9=Kareem, 10=Salma

-- Exam 1: DB Fundamentals - students from Backend/Cairo
INSERT INTO StudentExam (StudentID, ExamID, Status) VALUES
(1, 1, 'Completed'),
(2, 1, 'Completed'),
(5, 1, 'Completed'),
(3, 1, 'Absent');

-- Exam 2: DB Corrective - only those who failed exam 1
INSERT INTO StudentExam (StudentID, ExamID, Status) VALUES
(5, 2, 'Completed');

-- Exam 3: Web Dev
INSERT INTO StudentExam (StudentID, ExamID, Status) VALUES
(3, 3, 'Completed'),
(9, 3, 'Completed'),
(10, 3, 'Completed');

-- Exam 4: Python
INSERT INTO StudentExam (StudentID, ExamID, Status) VALUES
(1, 4, 'Completed'),
(2, 4, 'Completed'),
(5, 4, 'Completed');

-- Exam 5: ML101
INSERT INTO StudentExam (StudentID, ExamID, Status) VALUES
(8, 5, 'Completed'),
(9, 5, 'Completed');
GO

-- ============================================================
-- SECTION 16: STUDENT ANSWERS
-- ============================================================
-- ChoiceIDs can be verified by counting inserts in Section 11.
-- Correct answers are marked with comments.

-- ---- EXAM 1: DB Fundamentals ----

-- Student 1 (Ali) - strong student
INSERT INTO StudentAnswer (StudentID, ExamID, QuestionID, ChoiceID, TextAnswer, IsCorrect, Mark) VALUES
(1, 1, 1, 1,    NULL, 1, 15),  -- Q1 correct: SELECT
(1, 1, 2, 7,    NULL, 1, 15),  -- Q2 correct: TOTAL
(1, 1, 3, 9,    NULL, 1, 10),  -- Q3 correct: Uniqueness and NOT NULL
(1, 1, 6, 17,   NULL, 1, 10),  -- Q6 TF correct: True
(1, 1, 7, 19,   NULL, 1, 10),  -- Q7 TF correct: False
(1, 1, 9, NULL, 'DELETE removes rows one at a time and can be rolled back. TRUNCATE removes all rows instantly and cannot be rolled back.', NULL, NULL);

-- Student 2 (Nour) - good student
INSERT INTO StudentAnswer (StudentID, ExamID, QuestionID, ChoiceID, TextAnswer, IsCorrect, Mark) VALUES
(2, 1, 1, 1,    NULL, 1, 15),  -- Q1 correct
(2, 1, 2, 6,    NULL, 0,  0),  -- Q2 wrong: chose AVG
(2, 1, 3, 9,    NULL, 1, 10),  -- Q3 correct
(2, 1, 6, 17,   NULL, 1, 10),  -- Q6 correct
(2, 1, 7, 20,   NULL, 0,  0),  -- Q7 wrong: chose True
(2, 1, 9, NULL, 'DELETE removes specific rows and can be rolled back. TRUNCATE deletes all rows and is faster.', NULL, NULL);

-- Student 5 (Youssef) - average student
INSERT INTO StudentAnswer (StudentID, ExamID, QuestionID, ChoiceID, TextAnswer, IsCorrect, Mark) VALUES
(5, 1, 1, 2,    NULL, 0,  0),  -- Q1 wrong: chose INSERT
(5, 1, 2, 7,    NULL, 1, 15),  -- Q2 correct
(5, 1, 3, 10,   NULL, 0,  0),  -- Q3 wrong
(5, 1, 6, 18,   NULL, 0,  0),  -- Q6 wrong
(5, 1, 7, 19,   NULL, 1, 10),  -- Q7 correct
(5, 1, 9, NULL, 'TRUNCATE is faster than DELETE', NULL, NULL);

-- ---- EXAM 2: DB Corrective (Student 5 retake) ----
INSERT INTO StudentAnswer (StudentID, ExamID, QuestionID, ChoiceID, TextAnswer, IsCorrect, Mark) VALUES
(5, 2, 4,  13,   NULL, 1, 25),  -- Q4 correct: FULL OUTER JOIN
(5, 2, 5,  15,   NULL, 1, 25),  -- Q5 correct: HAVING
(5, 2, 8,  22,   NULL, 1, 25),  -- Q8 correct: False
(5, 2, 10, NULL, 'Normalization organizes data to reduce redundancy and dependency', NULL, NULL);

-- ---- EXAM 3: Web Dev ----

-- Student 3 (Omar)
INSERT INTO StudentAnswer (StudentID, ExamID, QuestionID, ChoiceID, TextAnswer, IsCorrect, Mark) VALUES
(3, 3, 11, 25,   NULL, 1, 20),  -- correct: <a>
(3, 3, 12, 29,   NULL, 1, 20),  -- correct: color
(3, 3, 13, 33,   NULL, 1, 20),  -- correct: getElementById
(3, 3, 14, 37,   NULL, 1, 20),  -- correct: True
(3, 3, 16, NULL, 'Block elements take full width and start on new line. Inline elements only take needed space.', NULL, NULL);

-- Student 9 (Kareem)
INSERT INTO StudentAnswer (StudentID, ExamID, QuestionID, ChoiceID, TextAnswer, IsCorrect, Mark) VALUES
(9, 3, 11, 26,   NULL, 0,  0),  -- wrong: chose <link>
(9, 3, 12, 29,   NULL, 1, 20),  -- correct
(9, 3, 13, 34,   NULL, 0,  0),  -- wrong
(9, 3, 14, 37,   NULL, 1, 20),  -- correct
(9, 3, 16, NULL, 'Block level elements are div p h1. Inline are span a img.', NULL, NULL);

-- Student 10 (Salma)
INSERT INTO StudentAnswer (StudentID, ExamID, QuestionID, ChoiceID, TextAnswer, IsCorrect, Mark) VALUES
(10, 3, 11, 25,   NULL, 1, 20),
(10, 3, 12, 27,   NULL, 0,  0),  -- wrong: font-color
(10, 3, 13, 33,   NULL, 1, 20),
(10, 3, 14, 37,   NULL, 1, 20),
(10, 3, 16, NULL, 'Block elements start on a new line. Inline elements stay in line.', NULL, NULL);

-- ---- EXAM 4: Python ----

-- Student 1 (Ali)
INSERT INTO StudentAnswer (StudentID, ExamID, QuestionID, ChoiceID, TextAnswer, IsCorrect, Mark) VALUES
(1, 4, 17, 42,   NULL, 1, 20),  -- correct: def
(1, 4, 18, 46,   NULL, 1, 20),  -- correct: float
(1, 4, 19, 51,   NULL, 1, 20),  -- correct: List
(1, 4, 20, 54,   NULL, 1, 20),  -- correct: False
(1, 4, 22, NULL, 'List comprehension is a concise way to create lists. Example: [x*2 for x in range(10)]', NULL, NULL);

-- Student 2 (Nour)
INSERT INTO StudentAnswer (StudentID, ExamID, QuestionID, ChoiceID, TextAnswer, IsCorrect, Mark) VALUES
(2, 4, 17, 41,   NULL, 0,  0),  -- wrong: function
(2, 4, 18, 46,   NULL, 1, 20),
(2, 4, 19, 49,   NULL, 0,  0),  -- wrong: Tuple
(2, 4, 20, 54,   NULL, 1, 20),
(2, 4, 22, NULL, 'List comprehension allows creating a new list by iterating over a sequence.', NULL, NULL);

-- Student 5 (Youssef)
INSERT INTO StudentAnswer (StudentID, ExamID, QuestionID, ChoiceID, TextAnswer, IsCorrect, Mark) VALUES
(5, 4, 17, 42,   NULL, 1, 20),
(5, 4, 18, 45,   NULL, 0,  0),  -- wrong: int
(5, 4, 19, 51,   NULL, 1, 20),
(5, 4, 20, 54,   NULL, 1, 20),
(5, 4, 22, NULL, 'A compact way to write a for loop that builds a list.', NULL, NULL);

-- ---- EXAM 5: ML101 ----

-- Student 8 (Reem)
INSERT INTO StudentAnswer (StudentID, ExamID, QuestionID, ChoiceID, TextAnswer, IsCorrect, Mark) VALUES
(8, 5, 23, 59,   NULL, 1, 25),  -- correct: Decision Tree
(8, 5, 24, 61,   NULL, 1, 25),  -- correct: overfitting definition
(8, 5, 25, 65,   NULL, 1, 25),  -- correct: True
(8, 5, 27, NULL, 'Supervised uses labeled data for training like classification. Unsupervised finds hidden patterns like clustering.', NULL, NULL);

-- Student 9 (Kareem)
INSERT INTO StudentAnswer (StudentID, ExamID, QuestionID, ChoiceID, TextAnswer, IsCorrect, Mark) VALUES
(9, 5, 23, 57,   NULL, 0,  0),  -- wrong: K-Means
(9, 5, 24, 62,   NULL, 0,  0),  -- wrong
(9, 5, 25, 65,   NULL, 1, 25),  -- correct
(9, 5, 27, NULL, 'Supervised learning has labels, unsupervised does not.', NULL, NULL);
GO

-- ============================================================
-- SECTION 17: RESULTS  (manually calculated totals)
-- ============================================================
-- Exam 1 (max=60 enforced by degrees): Ali=60, Nour=45, Youssef=25
-- Corrective (max=75+text): Youssef retake = 75
-- Exam 3 Web Dev (max=80+text): Omar=80, Kareem=40, Salma=60
-- Exam 4 Python  (max=80+text): Ali=80, Nour=40, Youssef=60
-- Exam 5 ML101   (max=75+text): Reem=75, Kareem=25

INSERT INTO Result (StudentID, CourseID, TotalMark) VALUES
(1, 1, 60),   -- Ali     - DB Fundamentals
(2, 1, 45),   -- Nour    - DB Fundamentals
(5, 1, 75),   -- Youssef - DB Fundamentals (after corrective)
(3, 2, 80),   -- Omar    - Web Dev
(9, 2, 40),   -- Kareem  - Web Dev
(10, 2, 60),  -- Salma   - Web Dev
(1, 3, 80),   -- Ali     - Python
(2, 3, 40),   -- Nour    - Python
(5, 3, 60),   -- Youssef - Python
(8, 6, 75),   -- Reem    - ML101
(9, 6, 25);   -- Kareem  - ML101
GO

-- ============================================================
-- SECTION 18: QUICK VERIFICATION QUERIES
-- ============================================================

PRINT '===== VERIFICATION QUERIES =====';

-- Count rows per table
SELECT 'Users'            AS TableName, COUNT(*) AS 'RowCount' FROM Users           UNION ALL
SELECT 'Department',                    COUNT(*)             FROM Department       UNION ALL
SELECT 'Branch',                        COUNT(*)             FROM Branch           UNION ALL
SELECT 'Track',                         COUNT(*)             FROM Track            UNION ALL
SELECT 'Intake',                        COUNT(*)             FROM Intake           UNION ALL
SELECT 'Instructor',                    COUNT(*)             FROM Instructor       UNION ALL
SELECT 'Student',                       COUNT(*)             FROM Student          UNION ALL
SELECT 'Course',                        COUNT(*)             FROM Course           UNION ALL
SELECT 'InstructorCourse',              COUNT(*)             FROM InstructorCourse UNION ALL
SELECT 'Question',                      COUNT(*)             FROM Question         UNION ALL
SELECT 'Choice',                        COUNT(*)             FROM Choice           UNION ALL
SELECT 'TextAnswer',                    COUNT(*)             FROM TextAnswer       UNION ALL
SELECT 'Exam',                          COUNT(*)             FROM Exam             UNION ALL
SELECT 'ExamQuestion',                  COUNT(*)             FROM ExamQuestion     UNION ALL
SELECT 'StudentExam',                   COUNT(*)             FROM StudentExam      UNION ALL
SELECT 'StudentAnswer',                 COUNT(*)             FROM StudentAnswer    UNION ALL
SELECT 'Result',                        COUNT(*)             FROM Result;

-- Student results with pass/fail
SELECT * FROM vw_StudentResults ORDER BY CourseName, TotalMark DESC;

-- Question pool breakdown by course and type
SELECT * FROM vw_QuestionCountByCourseType ORDER BY CourseName, QuestionType;

-- Instructor teaching assignments
SELECT * FROM vw_InstructorCourseDetails ORDER BY Year, CourseName;

-- Full exam details
SELECT * FROM vw_ExamDetails ORDER BY Year, CourseName;
GO

-- ============================================================
-- END OF DUMMY DATA
-- ============================================================
