USE [OdyClerkInternal]
GO

/****** Object:  Table [dbo].[TrafficCitationImport_18Percent]    Script Date: 8/11/2020 12:03:12 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TrafficCitationImport_18Percent](
	[RecordId] [int] NOT NULL,
	[ViolationCode] [int] NULL,
	[Statute] [varchar](50) NULL,
	[StatuteCode] [varchar](50) NULL,
	[MinExcessSpeed] [float] NULL,
	[MaxExcessSpeed] [float] NULL,
	[SchoolZone] [varchar](5) NULL,
	[WorkZone] [varchar](5) NULL,
	[EffectiveDate] [datetime] NULL,
	[ObsoleteDate] [datetime] NULL,
	[CreatedDate] [datetime] NULL,
	[CreatedBy] [varchar](50) NULL,
	[ModifiedDate] [datetime2](7) NULL,
	[ModifiedBy] [varchar](50) NULL,
	[Void] [bit] NULL,
	[VoidedBy] [varchar](50) NULL,
	[VoidedDate] [datetime2](7) NULL
) ON [PRIMARY]
GO


