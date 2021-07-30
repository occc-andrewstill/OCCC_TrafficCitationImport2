USE [OdyClerkInternal]
GO

/****** Object:  Table [dbo].[TrafficCitation_AgencyVendorInfo]    Script Date: 8/11/2020 11:56:52 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TrafficCitation_AgencyVendorInfo](
	[RecordId] [int] IDENTITY(1,1) NOT NULL,
	[VendorAgencyId] [int] NOT NULL,
	[CitationType] [varchar](50) NULL,
	[VendorName] [varchar](100) NOT NULL,
	[AgencyName] [varchar](100) NOT NULL,
	[ConnectionType] [varchar](50) NULL,
	[ServerName] [varchar](200) NOT NULL,
	[ServerUserName] [varchar](100) NOT NULL,
	[ServerPassword] [varchar](50) NOT NULL,
	[ServerPort] [int] NULL,
	[LocalPath] [varchar](100) NOT NULL,
	[RemotePath] [varchar](100) NOT NULL,
	[SSHKey] [varchar](100) NOT NULL,
	[Description] [varchar](500) NULL,
	[Active] [bit] NULL,
	[BCPFormatFile] [varchar](500) NULL,
	[NodeID] [varchar](50) NULL,
	[AgencyCode] [varchar](50) NULL,
	[SLA] [int] NULL,
 CONSTRAINT [PK_TrafficCitation_AgencyVendorInfo] PRIMARY KEY CLUSTERED 
(
	[RecordId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


