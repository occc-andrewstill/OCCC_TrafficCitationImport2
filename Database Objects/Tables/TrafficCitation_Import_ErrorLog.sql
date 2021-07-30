USE [OdyClerkInternal]
GO

/****** Object:  Table [dbo].[TrafficCitation_Import_ErrorLog]    Script Date: 8/11/2020 11:59:15 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TrafficCitation_Import_ErrorLog](
	[ErrorLogId] [int] IDENTITY(1,1) NOT NULL,
	[ErrorMessage] [varchar](max) NULL,
	[EventTime] [datetime] NOT NULL,
 CONSTRAINT [PK_dbo.Citations_ErrorLog] PRIMARY KEY CLUSTERED 
(
	[ErrorLogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[TrafficCitation_Import_ErrorLog] ADD  CONSTRAINT [DF_Citations_ErrorLog_EventTime]  DEFAULT (getdate()) FOR [EventTime]
GO


