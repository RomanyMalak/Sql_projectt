

-- ============================================================
-- SECTION 9: SQL SERVER LOGINS & PERMISSIONS
-- ============================================================
use [ExaminationSystemDB];
GO

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'AdminLogin')
CREATE LOGIN AdminLogin          WITH PASSWORD = 'Admin@SecureP@ss1!';
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'TrainingManagerLogin')
CREATE LOGIN TrainingManagerLogin WITH PASSWORD = 'TM@SecureP@ss2!';
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'InstructorLogin')
CREATE LOGIN InstructorLogin      WITH PASSWORD = 'Inst@SecureP@ss3!';
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'StudentLogin')
CREATE LOGIN StudentLogin         WITH PASSWORD = 'Stud@SecureP@ss4!';
GO

USE ExaminationSystemDB;
GO

-- Guard against re-running
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'AdminUser')
CREATE USER AdminUser       FOR LOGIN AdminLogin;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'TrainingMgrUser')
CREATE USER TrainingMgrUser FOR LOGIN TrainingManagerLogin;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'InstructorUser')
CREATE USER InstructorUser  FOR LOGIN InstructorLogin;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'StudentUser')
CREATE USER StudentUser     FOR LOGIN StudentLogin;
GO

use [ExaminationSystemDB];
-- Admin: full database owner
ALTER ROLE db_owner ADD MEMBER AdminUser;

-- Training Manager: organisation + reporting
GRANT EXECUTE ON sp_AddBranch                TO TrainingMgrUser;
GRANT EXECUTE ON sp_AddTrack                 TO TrainingMgrUser;
GRANT EXECUTE ON sp_AddIntake                TO TrainingMgrUser;
GRANT EXECUTE ON sp_AddInstructor            TO TrainingMgrUser;
GRANT EXECUTE ON sp_AddStudent               TO TrainingMgrUser;
GRANT EXECUTE ON sp_AssignInstructorToCourse TO TrainingMgrUser;
GRANT EXECUTE ON sp_SearchStudents           TO TrainingMgrUser;
GRANT SELECT  ON vw_StudentFullInfo          TO TrainingMgrUser;
GRANT SELECT  ON vw_CourseInstructors        TO TrainingMgrUser;
GRANT SELECT  ON vw_ExamOverview             TO TrainingMgrUser;
GRANT SELECT  ON vw_StudentResults           TO TrainingMgrUser;

-- Instructor: question and exam management
GRANT EXECUTE ON sp_AddQuestion              TO InstructorUser;
GRANT EXECUTE ON sp_AddQuestionChoice        TO InstructorUser;
GRANT EXECUTE ON sp_UpdateQuestion           TO InstructorUser;
GRANT EXECUTE ON sp_DeleteQuestion           TO InstructorUser;
GRANT EXECUTE ON sp_SearchQuestions          TO InstructorUser;
GRANT EXECUTE ON sp_CreateExam               TO InstructorUser;
GRANT EXECUTE ON sp_AddQuestionToExam        TO InstructorUser;
GRANT EXECUTE ON sp_AutoSelectExamQuestions  TO InstructorUser;
GRANT EXECUTE ON sp_EnrollStudentInExam      TO InstructorUser;
GRANT EXECUTE ON sp_ReviewTextAnswer         TO InstructorUser;
GRANT EXECUTE ON sp_RecalcStudentScore       TO InstructorUser;
GRANT EXECUTE ON sp_GetStudentExamResult     TO InstructorUser;
GRANT SELECT  ON vw_QuestionPool             TO InstructorUser;
GRANT SELECT  ON vw_ExamOverview             TO InstructorUser;
GRANT SELECT  ON vw_StudentResults           TO InstructorUser;
GRANT SELECT  ON vw_PendingTextReview        TO InstructorUser;

-- Student: submit answers and view own results only
GRANT EXECUTE ON sp_SubmitStudentAnswer      TO StudentUser;
GRANT EXECUTE ON sp_FinalizeStudentExam      TO StudentUser;
GRANT EXECUTE ON sp_GetStudentExamResult     TO StudentUser;
GO
