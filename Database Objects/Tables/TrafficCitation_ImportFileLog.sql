USE [OdyClerkInternal]
GO

/****** Object:  Table [dbo].[TrafficCitation_ImportFileLog]    Script Date: 8/11/2020 12:01:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TrafficCitation_ImportFileLog](
	[FileLogId] [int] IDENTITY(1,1) NOT NULL,
	[FileDate] [date] NOT NULL,
	[FileName] [varchar](255) NULL,
	[RecordCount] [int] NULL,
	[ProcessStartTime] [datetime] NULL,
	[ProcessEndTime] [datetime] NULL,
	[ProcessStatus] [varchar](500) NULL,
	[VendorAgencyId] [int] NULL,
 CONSTRAINT [PK_TrafficCitation_ImportFileLog2] PRIMARY KEY CLUSTERED 
(
	[FileLogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


