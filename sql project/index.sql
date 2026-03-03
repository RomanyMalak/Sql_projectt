USE ExaminationSystem_new_version;
GO

/* Track.DepartmentID بيتعمل عليه JOIN كتير */
CREATE NONCLUSTERED INDEX IX_Track_DepartmentID ON dbo.Track(DepartmentID);

/* Instructor.UserID بيتعمل عليه Join مع Users */
CREATE NONCLUSTERED INDEX IX_Instructor_UserID ON dbo.Instructor(UserID);

/* Search Indexes (اختياري بس عملي جدًا للـ LIKE والفلترة) */
CREATE NONCLUSTERED INDEX IX_Users_Role     ON dbo.Users(Role);
CREATE NONCLUSTERED INDEX IX_Department_Name ON dbo.Department(DepartmentName);
CREATE NONCLUSTERED INDEX IX_Branch_Name     ON dbo.Branch(BranchName);
CREATE NONCLUSTERED INDEX IX_Track_Name      ON dbo.Track(TrackName);
CREATE NONCLUSTERED INDEX IX_Intake_Dates    ON dbo.Intake(StartDate, EndDate);
GO