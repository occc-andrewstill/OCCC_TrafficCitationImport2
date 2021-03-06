USE [OdyClerkInternal]
GO
/****** Object:  UserDefinedFunction [dbo].[GetValidCode]    Script Date: 8/11/2020 11:44:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER Function [dbo].[GetValidCode](@Statute Varchar(100))
Returns Varchar(500)
As
Begin

DECLARE @OffenseCode Varchar(100)

IF EXISTS(SELECT Code FROM Justice..uCode WHERE Code = @Statute)
    SELECT @OffenseCode = @Statute
ELSE IF EXISTS(SELECT Code FROM Justice..uCode WHERE Code = @Statute+'-A' )
   SELECT @OffenseCode = @Statute+'-A'
ELSE IF EXISTS(SELECT Code FROM Justice..uCode WHERE Code = @Statute+'-B' )
   SELECT @OffenseCode = @Statute+'-B' 
ELSE IF EXISTS(SELECT Code FROM Justice..uCode WHERE Code = @Statute+'-C' )
   SELECT @OffenseCode = @Statute+'-C'  
ELSE IF EXISTS(SELECT Code FROM Justice..uCode WHERE Code = @Statute+'-D' )
   SELECT @OffenseCode = @Statute+'-D' 
ELSE   
   SELECT @OffenseCode = Code FROM Justice..uCode WHERE Code LIKE @Statute+'%'

  
Return @OffenseCode

End;



