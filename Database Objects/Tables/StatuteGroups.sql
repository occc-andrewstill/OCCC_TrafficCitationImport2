USE [OdyClerkInternal]
GO

/****** Object:  Table [dbo].[StatuteGroups]    Script Date: 8/11/2020 12:10:05 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[StatuteGroups](
	[OffenseID] [int] NOT NULL,
	[StatuteGroupID] [int] NOT NULL,
	[Statute] [varchar](50) NULL,
	[StatuteCode] [varchar](50) NULL,
	[Description] [varchar](1000) NULL,
 CONSTRAINT [PK_StatuteGroups] PRIMARY KEY CLUSTERED 
(
	[OffenseID] ASC,
	[StatuteGroupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


