USE [OdyClerkInternal]
GO
/****** Object:  UserDefinedFunction [dbo].[TrafficCitationImport_FormatStatute]    Script Date: 8/11/2020 11:48:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Tarig Mudawi
-- Create date: 1/30/2014
-- Description:	This function takes a section and subsection from the citation file
--              and returns a formated statute.
-- =============================================
ALTER FUNCTION [dbo].[TrafficCitationImport_FormatStatute](@Section Varchar(100), @Subsection Varchar(100))
RETURNS VARCHAR(100)
AS
BEGIN
DECLARE
@CitationNumber     VARCHAR(100),
@PrevCitationNumber VARCHAR(100),
@Subsection2        VARCHAR(100),
@SectionLength      VARCHAR(10),
@SubsectionLength   VARCHAR(20),
@SubsectionDigits   VARCHAR(20),
@SubsectionLetters  VARCHAR(10),
@Statute            VARCHAR(100),
@FileStatute1       VARCHAR(100),
@FileStatute2       VARCHAR(100),
@Code               VARCHAR(100),
@PrevStatute        VARCHAR(100),
@PrevCode           VARCHAR(100),
@CodeID             VARCHAR(100),
@Amount             VARCHAR(100),
@PrevAmount         VARCHAR(100),
@SectionSubsection  VARCHAR(100),
@Jurisdiction       VARCHAR(100),
@CurrChar           INT,
@TempSubString      VARCHAR(10),
@CurrStatute        VARCHAR(100)

SELECT @SubsectionDigits = '', @SubsectionLetters = '', @CurrChar = 0, @SectionLength = '', @SubsectionLength = '', @FileStatute1 = '', @FileStatute2 = '', @CurrStatute = ''
SET @Subsection2 = ''
	
	           
      SELECT @SectionLength = LEN(@Section), @SubsectionLength = LEN(ISNULL(@Subsection,''))
      
      IF(@SectionLength = 5)
          SELECT @Section = SUBSTRING(@Section,1,3)+'.'+SUBSTRING(@Section,4,2)
      ELSE IF(@SectionLength = 6)
          SELECT @Section = SUBSTRING(@Section,1,3)+'.'+SUBSTRING(@Section,4,3)
      ELSE IF(@SectionLength = 7)
          SELECT @Section = SUBSTRING(@Section,1,3)+'.'+SUBSTRING(@Section,4,4)
      ELSE 
          SELECT @Section = SUBSTRING(@Section,1,3)+'.'+SUBSTRING(@Section,4,5)
          
     IF(@Subsection IS NULL)
        SELECT @Subsection = '', @SubsectionLength = 0
          
     -- print ' @section :' + @section + ' @subsection: ' + @subsection     
      SET @CurrChar = 1
      While(@SubsectionLength >= @CurrChar)
      Begin 
            IF(ISNUMERIC(SUBSTRING(@Subsection,@CurrChar,1)) = 1 AND @CurrChar = 1 AND @CurrChar = @SubsectionLength)
                 Begin
                   SELECT @TempSubString = SUBSTRING(@Subsection,@CurrChar,1)
                   SELECT @SubsectionDigits = @SubsectionDigits + @TempSubString
                   SELECT @Subsection2 = '(' + @SubsectionDigits + ')'
                   SELECT @TempSubString = ''
                   --print 'Tarig3 @Subsection: ' + @Subsection2 + ' @SubsectionDigits: ' + @SubsectionDigits
                 End
            ELSE IF(ISNUMERIC(SUBSTRING(@Subsection,@CurrChar,1)) = 0 AND @CurrChar = 1 AND @CurrChar = @SubsectionLength)
                 Begin
                    SELECT @TempSubString = SUBSTRING(@Subsection,@CurrChar,1)
                    SELECT @SubsectionLetters = @SubsectionLetters + @TempSubString
                    SELECT @Subsection2 = '(' + @SubsectionLetters + ')'
                    SELECT @TempSubString = ''
                    --print ' @Subsection: ' + @Subsection2
                 End
            ELSE IF(ISNUMERIC(SUBSTRING(@Subsection,@CurrChar,1)) = 1 AND @CurrChar = 1 AND @CurrChar < @SubsectionLength)
                 Begin
                    SELECT @TempSubString = SUBSTRING(@Subsection,@CurrChar,1)
                   SELECT @SubsectionDigits = @SubsectionDigits + @TempSubString
                   SELECT @Subsection2 = '(' + @SubsectionDigits
                   SELECT @TempSubString = ''
                   --print ' @Subsection: ' + @Subsection2
                 End
            ELSE IF(ISNUMERIC(SUBSTRING(@Subsection,@CurrChar,1)) = 0 AND @CurrChar = 1 AND @CurrChar < @SubsectionLength)
                 Begin
                    SELECT @TempSubString = SUBSTRING(@Subsection,@CurrChar,1)
                    SELECT @SubsectionLetters = @SubsectionLetters + @TempSubString
                    SELECT @Subsection2 = '(' + @SubsectionLetters
                    SELECT @TempSubString = ''
                    --print ' @Subsection: ' + @Subsection2
                 End
            ELSE IF(ISNUMERIC(SUBSTRING(@Subsection,@CurrChar,1)) = 1 AND @CurrChar > 1 AND ISNUMERIC(SUBSTRING(@Subsection,@CurrChar-1,1)) = 0 AND @CurrChar < @SubsectionLength)
                 Begin
                   SELECT @TempSubString = SUBSTRING(@Subsection,@CurrChar,1)
                   --print '@TempSubString: ' + @TempSubString + ' @CurrChar: ' + cast(@CurrChar as varchar(10)) + ' @Subsection: ' + @Subsection
                   SELECT @SubsectionDigits = ''
                   SELECT @SubsectionDigits = @SubsectionDigits + @TempSubString
                   SELECT @Subsection2 = @Subsection2 + ')(' + @SubsectionDigits
                   SELECT @TempSubString = ''
                   --print ' @Subsection: ' + @Subsection2 + ' @CurrChar: ' + cast(@CurrChar as varchar(10))
                 End
             ELSE IF(ISNUMERIC(SUBSTRING(@Subsection,@CurrChar,1)) = 0 AND @CurrChar > 1 AND ISNUMERIC(SUBSTRING(@Subsection,@CurrChar-1,1)) = 1 AND @CurrChar < @SubsectionLength)
                 Begin
                   SELECT @TempSubString = SUBSTRING(@Subsection,@CurrChar,1)
                    SELECT @SubsectionLetters = ''
                   SELECT @SubsectionLetters = @SubsectionLetters + @TempSubString
                   SELECT @Subsection2 = @Subsection2 + ')(' + @SubsectionLetters
                   SELECT @TempSubString = ''
                   --print ' @Subsection: ' + @Subsection2
                 End
             ELSE IF(ISNUMERIC(SUBSTRING(@Subsection,@CurrChar,1)) = 1 AND @CurrChar > 1 AND ISNUMERIC(SUBSTRING(@Subsection,@CurrChar-1,1)) = 1 AND @CurrChar < @SubsectionLength)
                 Begin
                   SELECT @TempSubString = SUBSTRING(@Subsection,@CurrChar,1)
                   SELECT @SubsectionDigits = @SubsectionDigits + @TempSubString
                   --SELECT @Subsection2 = @Subsection2 + @SubsectionDigits
                   SELECT @Subsection2 = @Subsection2 + @TempSubString  -- Correction
                   SELECT @TempSubString = ''
                   --print ' @Subsection: ' + @Subsection2
                 End
              ELSE IF(ISNUMERIC(SUBSTRING(@Subsection,@CurrChar,1)) = 0 AND @CurrChar > 1 AND ISNUMERIC(SUBSTRING(@Subsection,@CurrChar-1,1)) = 0 AND @CurrChar < @SubsectionLength)
                 Begin
                  SELECT @TempSubString = SUBSTRING(@Subsection,@CurrChar,1)
                  SELECT @SubsectionLetters = @SubsectionLetters + @TempSubString
                  SELECT @Subsection2 = @Subsection2 + @SubsectionLetters
                  SELECT @TempSubString = ''
                  --print ' @Subsection: ' + @Subsection2
                 End   
             ELSE IF(ISNUMERIC(SUBSTRING(@Subsection,@CurrChar,1)) = 1 AND @CurrChar > 1 AND ISNUMERIC(SUBSTRING(@Subsection,@CurrChar-1,1)) = 1 AND @CurrChar = @SubsectionLength)
                 Begin
                   SELECT @TempSubString = SUBSTRING(@Subsection,@CurrChar,1)
                   SELECT @SubsectionDigits = @SubsectionDigits + @TempSubString
                   --SELECT @Subsection2 = @Subsection2 + @SubsectionDigits + ')'
                   SELECT @Subsection2 = @Subsection2 + @TempSubString + ')'
                   SELECT @TempSubString = ''
                   --print ' @Subsection: ' + @Subsection2
                 End
             ELSE IF(ISNUMERIC(SUBSTRING(@Subsection,@CurrChar,1)) = 1 AND @CurrChar > 1 AND ISNUMERIC(SUBSTRING(@Subsection,@CurrChar-1,1)) = 0 AND @CurrChar = @SubsectionLength)
                 Begin
                   SELECT @TempSubString = SUBSTRING(@Subsection,@CurrChar,1)
                   SELECT @SubsectionDigits = ''
                   SELECT @SubsectionDigits = @SubsectionDigits + @TempSubString
                   SELECT @Subsection2 = @Subsection2 + ')(' + @SubsectionDigits + ')'
                   SELECT @TempSubString = ''
                   --print ' @Subsection: ' + @Subsection2
                 End
                 ELSE IF(ISNUMERIC(SUBSTRING(@Subsection,@CurrChar,1)) = 0 AND @CurrChar > 1 AND ISNUMERIC(SUBSTRING(@Subsection,@CurrChar-1,1)) = 0 AND @CurrChar = @SubsectionLength)
                 Begin
                   SELECT @TempSubString = SUBSTRING(@Subsection,@CurrChar,1)
                   SELECT @SubsectionLetters = @SubsectionLetters + @TempSubString
                   SELECT @Subsection2 = @Subsection2 + @SubsectionLetters + ')'
                   SELECT @TempSubString = ''
                   --print ' @Subsection: ' + @Subsection2
                 End
             ELSE IF(ISNUMERIC(SUBSTRING(@Subsection,@CurrChar,1)) = 0 AND @CurrChar > 1 AND ISNUMERIC(SUBSTRING(@Subsection,@CurrChar-1,1)) = 1 AND @CurrChar = @SubsectionLength)
                 Begin
                   SELECT @TempSubString = SUBSTRING(@Subsection,@CurrChar,1)
                   SELECT @SubsectionLetters = ''
                   SELECT @SubsectionLetters = @SubsectionLetters + @TempSubString
                   SELECT @Subsection2 = @Subsection2 + ')(' + @SubsectionLetters + ')'
                   SELECT @TempSubString = ''
                   --print ' @Subsection: ' + @Subsection2
                 End
  
            SELECT @CurrChar = @CurrChar + 1
      End
      
      -- SET @FileStatute1 = @Section + @Subsection2 
      
      SELECT @FileStatute1 = @Section + @Subsection2 
      SELECT @FileStatute2 = @Section 
      
      --SET @Subsection2 = ''
      
       --IF(EXISTS(SELECT Statute FROM Justice..uOff WHERE Statute = @FileStatute1))
       --Begin
       --       SET @CurrStatute = @FileStatute1
       --End
       
       --ELSE IF(EXISTS(SELECT Statute FROM Justice..uOff WHERE Statute = @FileStatute2 AND Statute != @FileStatute1))
       --Begin
       --       SET @CurrStatute = @FileStatute2
       --End
       --ELSE 
       --     SET @CurrStatute =@Section + ISNULL(@Subsection2,'') --RETURN NULL
       /****** Special Code for Red Light Statute  T.M. 7/7/2015  *****/
           IF(@FileStatute1 = '316.075(1)(c)(1)')
               SET @FileStatute1 = '316.075(1)(c)1'
               
       RETURN @FileStatute1 --@CurrStatute
       --SELECT @FileStatute2 = @Section 

END

