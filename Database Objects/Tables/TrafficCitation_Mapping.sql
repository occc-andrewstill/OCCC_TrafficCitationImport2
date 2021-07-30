USE [OdyClerkInternal]
GO

/****** Object:  Table [dbo].[TrafficCitation_Mapping]    Script Date: 8/11/2020 12:01:59 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TrafficCitation_Mapping](
	[FileCode] [varchar](50) NOT NULL,
	[OdyCode] [varchar](100) NOT NULL,
	[OdyCodeId] [varchar](100) NULL,
	[MappingType] [varchar](100) NOT NULL
) ON [PRIMARY]
GO


