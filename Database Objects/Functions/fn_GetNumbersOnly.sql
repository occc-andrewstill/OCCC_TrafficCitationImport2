USE [OdyClerkInternal]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_GetNumbersOnly]    Script Date: 8/11/2020 11:51:12 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER function [dbo].[fn_GetNumbersOnly](@pn varchar(100))
Returns varchar(max)
AS
BEGIN
  Declare @r varchar(max) ='', @len int ,@c char(1), @x int = 0

  Select @len = len(@pn)
  while @x <= @len 
  begin
    Select @c = SUBSTRING(@pn,@x,1)
    if ISNUMERIC(@c) = 1 and @c <> '-'
     Select @r = @r + @c

   Select @x = @x +1
  end
return @r
End

--declare @officerBadge varchar(50)
--set @officerBadge = dbo.fn_GetNumbersOnly('01541')
--select @officerBadge