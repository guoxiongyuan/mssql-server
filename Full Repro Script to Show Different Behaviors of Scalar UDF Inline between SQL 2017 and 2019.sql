USE master;
GO
--=======================================================--
--== Create a test database				               ==--
--=======================================================--
CREATE DATABASE TestDB;
GO
--=======================================================--
--== Switch to use the test database	               ==--
--=======================================================--
USE TestDB;
GO
--=======================================================--
--== Create table Word_List            	               ==--
--=======================================================--
DROP TABLE IF EXISTS [dbo].[Word_List];
GO
CREATE TABLE [dbo].[Word_List] (
	[Word_Id] int NOT NULL IDENTITY(1, 1),
	[Word] varchar(50) NOT NULL,
	CONSTRAINT [PK_Word_List] PRIMARY KEY CLUSTERED ([Word_Id] ASC)
);
GO
--=======================================================--
--== Insert data to table Word_List    	               ==--
--=======================================================--
INSERT INTO [dbo].[Word_List] ([Word]) 
SELECT TOP (100) 'Word_' + RIGHT('00' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS varchar(3)), 3)
FROM master.dbo.spt_values;
GO
-- Check data in the table
--SELECT * FROM [dbo].[Word_List];
--=======================================================--
--== Create a view vw_Get_RAND to get a random number  ==--
--== between 0 and 1								   ==--
--=======================================================--
DROP VIEW IF EXISTS [dbo].[vw_Get_RAND];
GO
CREATE VIEW [dbo].[vw_Get_RAND]
AS
	SELECT RAND() AS RAND_Value;
GO
--=======================================================--
--== Create functions:								   ==--
--== 1. udf_Get_Random_Number						   ==--
--== 2. udf_Get_Random_Word							   ==--
--=======================================================--
-- Function: udf_Get_Random_Number
DROP FUNCTION IF EXISTS [dbo].[udf_Get_Random_Number];
GO
CREATE FUNCTION [dbo].[udf_Get_Random_Number](@LowerBound INT, @UpperBound INT)
RETURNS INT
AS
BEGIN
	DECLARE @RAND_Value float;
	SELECT @RAND_Value = (SELECT RAND_Value FROM [vw_Get_RAND]);
	RETURN CAST(@RAND_Value * (@UpperBound - @LowerBound) + @LowerBound AS INT);
END 
GO
-- Function: udf_Get_Random_Word
DROP FUNCTION IF EXISTS [dbo].[udf_Get_Random_Word];
GO
CREATE FUNCTION [dbo].[udf_Get_Random_Word]()
RETURNS VARCHAR(255)
AS
BEGIN
	RETURN (
		SELECT UPPER(LEFT(Word, 1)) + LOWER(SUBSTRING(Word, 2, LEN(Word))) AS Word
		FROM [dbo].[Word_List]
		WHERE [Word_Id] = [dbo].[udf_Get_Random_Number](1, (SELECT MAX([Word_Id]) FROM [dbo].[Word_List]))
	);
END
GO
--=======================================================--
--== Test cases							               ==--
--== 1. For SQL Server 2017 or earlier                 ==--
--== 2. For SQL Server 2019 or later	               ==--
--=======================================================--
-- 1. For SQL Server 2017 or earlier
ALTER DATABASE TestDB SET COMPATIBILITY_LEVEL = 140;	-- SQL Server 2017
GO
SELECT compatibility_level FROM sys.databases WHERE name = 'TestDB';
GO
-- Execute the following query
SELECT TOP 10 [dbo].[udf_Get_Random_Word]() FROM master.dbo.spt_values;
GO
/*
== Output with the different words ==
Word_063
Word_040
Word_043
Word_064
Word_069
Word_030
Word_009
Word_051
Word_034
Word_094
*/

-- For SQL Server 2019 or later
ALTER DATABASE TestDB SET COMPATIBILITY_LEVEL = 150;	-- SQL Server 2019
GO
SELECT compatibility_level FROM sys.databases WHERE name = 'TestDB';
GO
-- Execute the following query
SELECT TOP 10 [dbo].[udf_Get_Random_Word]() FROM master.dbo.spt_values;
GO
/*
== Output with the same word ==
Word_067
Word_067
Word_067
Word_067
Word_067
Word_067
Word_067
Word_067
Word_067
Word_067
*/

--=======================================================--
--== Alter function	udf_Get_Random_Word				   ==--
--== to add WITH INLINE = OFF						   ==--
--=======================================================--
ALTER FUNCTION [dbo].[udf_Get_Random_Word]()
RETURNS VARCHAR(255)
WITH INLINE = OFF
AS
BEGIN
	RETURN (
		SELECT UPPER(LEFT(Word, 1)) + LOWER(SUBSTRING(Word, 2, LEN(Word))) AS Word
		FROM [dbo].[Word_List]
		WHERE [Word_Id] = [dbo].[udf_Get_Random_Number](1, (SELECT MAX([Word_Id]) FROM [dbo].[Word_List]))
	);
END
GO

-- Execute the following query again SQL Server 2019 
SELECT TOP 10 [dbo].[udf_Get_Random_Word]() FROM master.dbo.spt_values;
GO
/*
== Output with the different words ==
Word_039
Word_051
Word_070
Word_003
Word_081
Word_016
Word_021
Word_098
Word_023
Word_098
*/