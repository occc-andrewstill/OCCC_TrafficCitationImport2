USE [OdyClerkInternal]
GO
/****** Object:  UserDefinedFunction [dbo].[GetOfficerBadgeNumber]    Script Date: 8/11/2020 11:44:10 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER FUNCTION [dbo].[GetOfficerBadgeNumber](@OfficerBadgeNum VARCHAR(50),@OfficerId VARCHAR(50), @AgencyCode VARCHAR(50), @OfficerLName VARCHAR(50))
RETURNS VARCHAR(50)
AS
Begin
    DECLARE @CountOfficers INT,
            @OfficerIdOdy VARCHAR(50)

	-- remove any letters from officer badge
	-- Exclude Belle Isle since its officers badges has letters on them 6/14/2016
	If(@AgencyCode = 'BIPD')
	  return @OfficerBadgeNum

		set @OfficerBadgeNum = dbo.fn_GetNumbersOnly(@OfficerBadgeNum)
		set @OfficerId = dbo.fn_GetNumbersOnly(@OfficerId)
	


  -- New Fix for officer warning T.M. 3/10/2016
     SELECT @CountOfficers = COUNT(*)  FROM Justice..Officer o JOIN Justice..uCode uc (NOLOCK) ON uc.CodeID = o.AgencyID And uc.Code = @AgencyCode
     WHERE ( BadgeNum IN(@OfficerBadgeNum, @OfficerId) OR 
	         (BadgeNum IN(SUBSTRING(@OfficerBadgeNum,2,3)) AND SUBSTRING(@OfficerBadgeNum,1,1) = 0) OR 
			 (BadgeNum IN(SUBSTRING(@OfficerId,2,4)) AND SUBSTRING(@OfficerId,1,1) = 0) OR 
			 (BadgeNum IN(SUBSTRING(@OfficerId,3,3)) AND (SUBSTRING(@OfficerId,1,1) = 0 AND SUBSTRING(@OfficerId,2,1) = 0) OR
			 (BadgeNum IN(SUBSTRING(@OfficerId,4,2)) AND SUBSTRING(@OfficerId,1,1) = 0 AND SUBSTRING(@OfficerId,2,1) = 0 AND SUBSTRING(@OfficerId,3,1) = 0)))

     --AND uc.Code = @AgencyCode
     AND (o.InactiveDate > GETDATE() OR o.InactiveDate IS NULL)
	 -- OfficerId is not all zeros  T.M. 12/18/2015
	 AND BadgeNum NOT IN('00000','0000','000','00','0')

	 /***********************************************************************/

     
     IF(@CountOfficers = 0)
        SELECT @OfficerIdOdy = '0000'
     ELSE IF(@CountOfficers = 1 AND @OfficerBadgeNum =(SELECT DISTINCT BadgeNum FROM Justice..Officer o JOIN Justice..uCode uc (NOLOCK) ON uc.CodeID = o.AgencyID
                               AND uc.Code = @AgencyCode AND BadgeNum = @OfficerBadgeNum AND (o.InactiveDate > GETDATE() OR o.InactiveDate IS NULL)))
        SELECT @OfficerIdOdy = @OfficerBadgeNum 
     ELSE IF(@CountOfficers = 1 AND SUBSTRING(@OfficerBadgeNum,2,3) =(SELECT DISTINCT BadgeNum FROM Justice..Officer o JOIN Justice..uCode uc (NOLOCK) ON uc.CodeID = o.AgencyID
                               AND uc.Code = @AgencyCode AND BadgeNum = SUBSTRING(@OfficerBadgeNum,2,3) AND SUBSTRING(@OfficerBadgeNum,1,1) = 0  AND (o.InactiveDate > GETDATE() OR o.InactiveDate IS NULL)))
        SELECT @OfficerIdOdy = SUBSTRING(@OfficerBadgeNum,2,3) --+'tarig1' --<-- here     
     ELSE IF(@CountOfficers = 1 AND @OfficerId =(SELECT DISTINCT BadgeNum FROM Justice..Officer o JOIN Justice..uCode uc (NOLOCK) ON uc.CodeID = o.AgencyID
                               AND uc.Code = @AgencyCode AND BadgeNum = @OfficerId))
        SELECT @OfficerIdOdy = @OfficerId 
     ELSE IF(@CountOfficers = 1 AND SUBSTRING(@OfficerId,2,4) =(SELECT DISTINCT BadgeNum FROM Justice..Officer o JOIN Justice..uCode uc (NOLOCK) ON uc.CodeID = o.AgencyID
                               AND uc.Code = @AgencyCode AND BadgeNum = SUBSTRING(@OfficerId,2,4) AND SUBSTRING(@OfficerId,1,1) = 0 AND (o.InactiveDate > GETDATE() OR o.InactiveDate IS NULL)))
        SELECT @OfficerIdOdy = SUBSTRING(@OfficerId,2,4)
     ELSE IF(@CountOfficers = 1 AND SUBSTRING(@OfficerId,3,3) =(SELECT DISTINCT BadgeNum FROM Justice..Officer o JOIN Justice..uCode uc (NOLOCK) ON uc.CodeID = o.AgencyID
                               AND uc.Code = @AgencyCode AND BadgeNum = SUBSTRING(@OfficerId,3,3) AND SUBSTRING(@OfficerId,1,1) = 0 AND SUBSTRING(@OfficerId,2,1) = 0 AND (o.InactiveDate > GETDATE() OR o.InactiveDate IS NULL)))
        SELECT @OfficerIdOdy = SUBSTRING(@OfficerId,3,3) 
     -------
          
      -- match against @OfficerBadgeNum and last name                                                                     
     ELSE IF(@CountOfficers >= 2 AND @OfficerLName = (SELECT TOP 1 NameLast FROM Justice..Name n JOIN Justice..Party p (NOLOCK) ON n.PartyID = p.PartyID
                                                      JOIN Justice..Officer o (NOLOCK) ON o.PartyID = p.PartyID
                                                       JOIN Justice..uCode uc (NOLOCK) ON uc.CodeID = o.AgencyID
                                                      WHERE o.BadgeNum = @OfficerBadgeNum AND (o.InactiveDate > GETDATE() OR o.InactiveDate IS NULL)  AND uc.Code = @AgencyCode) )
         SELECT @OfficerIdOdy = @OfficerBadgeNum  
         
      -- match against SUBSTRING(@OfficerBadgeNum,2,3) and last name                                                                     
     ELSE IF(@CountOfficers >= 2 AND @OfficerLName = (SELECT TOP 1 NameLast FROM Justice..Name n JOIN Justice..Party p (NOLOCK) ON n.NameID = p.NameIDCur
                                                      JOIN Justice..Officer o (NOLOCK) ON o.PartyID = p.PartyID
                                                       JOIN Justice..uCode uc (NOLOCK) ON uc.CodeID = o.AgencyID
                                                      WHERE o.BadgeNum = SUBSTRING(@OfficerBadgeNum,2,3) AND SUBSTRING(@OfficerBadgeNum,1,1) = 0 AND (o.InactiveDate > GETDATE() OR o.InactiveDate IS NULL)  AND uc.Code = @AgencyCode) )
         SELECT @OfficerIdOdy = SUBSTRING(@OfficerBadgeNum,2,3)  
     
     -- match against @OfficerId and last name 
     ELSE IF(@CountOfficers >= 2 AND @OfficerLName = (SELECT TOP 1 NameLast FROM Justice..Name n JOIN Justice..Party p (NOLOCK) ON n.NameID = p.NameIDCur
                                                      JOIN Justice..Officer o (NOLOCK) ON o.PartyID = p.PartyID
                                                       JOIN Justice..uCode uc (NOLOCK) ON uc.CodeID = o.AgencyID
                                                      WHERE o.BadgeNum = @OfficerId AND (o.InactiveDate > GETDATE() OR o.InactiveDate IS NULL)  AND uc.Code = @AgencyCode) )
         SELECT @OfficerIdOdy = @OfficerId                                                                            
     
      -- match against SUBSTRING(@OfficerId,2,4) and last name
      ELSE IF(@CountOfficers >= 2 AND @OfficerLName = (SELECT TOP 1 NameLast FROM Justice..Name n JOIN Justice..Party p (NOLOCK) ON n.NameID = p.NameIDCur
                                                      JOIN Justice..Officer o (NOLOCK) ON o.PartyID = p.PartyID
                                                      JOIN Justice..uCode uc (NOLOCK) ON uc.CodeID = o.AgencyID
                                                      WHERE o.BadgeNum = SUBSTRING(@OfficerId,2,4) AND SUBSTRING(@OfficerId,1,1) = 0 AND (o.InactiveDate > GETDATE() OR o.InactiveDate IS NULL) AND uc.Code = @AgencyCode) )
         SELECT @OfficerIdOdy = SUBSTRING(@OfficerId,2,4) 
         
      -- match against SUBSTRING(@OfficerId,3,3) and last name
       ELSE IF(@CountOfficers >= 2 AND @OfficerLName = (SELECT TOP 1 NameLast FROM Justice..Name n JOIN Justice..Party p (NOLOCK) ON n.NameID = p.NameIDCur
                                                      JOIN Justice..Officer o (NOLOCK) ON o.PartyID = p.PartyID
                                                       JOIN Justice..uCode uc (NOLOCK) ON uc.CodeID = o.AgencyID
                                                      WHERE o.BadgeNum = SUBSTRING(@OfficerId,3,3) AND SUBSTRING(@OfficerId,1,1) = 0 AND SUBSTRING(@OfficerId,2,1) = 0 AND (o.InactiveDate > GETDATE() OR o.InactiveDate IS NULL)  AND uc.Code = @AgencyCode) )
         SELECT @OfficerIdOdy = SUBSTRING(@OfficerId,3,3)
         
	  -- New Fix for officer warning T.M. 3/10/2016
	  ELSE IF(@CountOfficers >= 2 AND @OfficerLName NOT IN (SELECT DISTINCT NameLast FROM Justice..Name n JOIN Justice..Party p (NOLOCK) ON n.PartyID = p.PartyID
                                                      JOIN Justice..Officer o (NOLOCK) ON o.PartyID = p.PartyID
                                                      JOIN Justice..uCode uc (NOLOCK) ON uc.CodeID = o.AgencyID AND uc.Code = @AgencyCode
                                                      WHERE (o.BadgeNum IN(@OfficerBadgeNum, @OfficerId) OR 
															(o.BadgeNum IN(SUBSTRING(@OfficerBadgeNum,2,3)) AND SUBSTRING(@OfficerBadgeNum,1,1) = 0) OR
															(o.BadgeNum IN(SUBSTRING(@OfficerId,2,4)) AND SUBSTRING(@OfficerId,1,1) = 0)) OR 
															(o.BadgeNum IN(SUBSTRING(@OfficerId,3,3)) AND (SUBSTRING(@OfficerId,1,1) = 0 AND SUBSTRING(@OfficerId,2,1) = 0))
													AND (o.InactiveDate > GETDATE() OR o.InactiveDate IS NULL)))
													  
													                                             
         SELECT @OfficerIdOdy = '0000'
         
       ELSE 
            SELECT @OfficerIdOdy = '0000'
                  
   RETURN @OfficerIdOdy          
End
