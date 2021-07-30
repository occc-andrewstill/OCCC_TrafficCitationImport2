USE [OdyClerkInternal]
GO

/****** Object:  Table [dbo].[TrafficCitation_ApiMessageLog]    Script Date: 8/11/2020 11:57:41 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TrafficCitation_ApiMessageLog](
	[CitationNumber] [varchar](50) NOT NULL,
	[ApiRequest] [xml] NULL,
	[ApiResponse] [xml] NULL,
	[AddDocRequest] [xml] NULL,
	[AddDocResponse] [xml] NULL,
	[LinkDocRequest] [xml] NULL,
	[LinkDocResponse] [xml] NULL,
	[LastApiAttempt] [datetime] NULL,
	[UnpaidTollFeeRequest] [xml] NULL,
	[UnpaidTollFeeResponse] [xml] NULL,
 CONSTRAINT [PK_TrafficCitation_ApiMessageLog] PRIMARY KEY CLUSTERED 
(
	[CitationNumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = ON, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO


