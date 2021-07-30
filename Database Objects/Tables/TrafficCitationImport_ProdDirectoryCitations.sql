USE [OdyClerkInternal]
GO

/****** Object:  Table [dbo].[TrafficCitationImport_ProdDirectoryCitations]    Script Date: 8/11/2020 12:06:24 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TrafficCitationImport_ProdDirectoryCitations](
	[CitationID] [int] IDENTITY(1,1) NOT NULL,
	[CitationImageNumber] [varchar](50) NOT NULL,
	[CitationNumber]  AS (replace([CitationImageNumber],'.pdf','')) PERSISTED,
	[depth] [int] NULL,
	[Isfile] [int] NULL,
	[Agency] [varchar](50) NULL,
	[Reason] [varchar](100) NULL,
	[Date_Received] [varchar](50) NULL,
	[Sent_to_Traffic] [varchar](5) NULL,
	[Date_Sent_to_Traffic] [smalldatetime] NULL,
	[FileCreateDate] [smalldatetime] NULL,
	[ErrorMessage] [varchar](max) NULL,
	[ZipParent] [int] NULL,
	[DataParent] [int] NULL,
 CONSTRAINT [PK_TrafficCitationImport_ProdDirectoryCitations] PRIMARY KEY CLUSTERED 
(
	[CitationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO


