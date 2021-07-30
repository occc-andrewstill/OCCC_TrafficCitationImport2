using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TrafficCitationImport2.Models
{
    public class VendorsInfo
    {
        private int recordId;
        private int vendorAgencyId;
        private string citationType;
        private string vendorName;
        private string agencyName;
        private string connectionType;
        private string serverName;
        private string serverUserName;
        private string serverPassword;
        private Nullable<int> serverPort;
        private string localPath;
        private string remotePath;
        private string sSHKey;
        private string description;
        private Nullable<bool> active;
        private string bCPFormatFile;
        private string nodeID;
        private string agencyCode;
        private Nullable<int> sLA;
        private List<string> remoteFileList;

        public VendorsInfo(TrafficCitation_AgencyVendorInfo info)
        {
            recordId = info.RecordId;
            vendorAgencyId = info.VendorAgencyId;
            citationType = info.CitationType;
            vendorName = info.VendorName;
            agencyName = info.AgencyName;
            connectionType = info.ConnectionType;
            serverName = info.ServerName;
            serverUserName = info.ServerUserName;
            serverPassword = info.ServerPassword;
            serverPort = info.ServerPort;
            localPath = info.LocalPath;
            remotePath = info.RemotePath;
            sSHKey = info.SSHKey;
            description = info.Description;
            active = info.Active;
            bCPFormatFile = info.BCPFormatFile;
            nodeID = info.NodeID;
            agencyCode = info.AgencyCode;
            sLA = info.SLA;
        }
        public int RecordId { get; }
        public int VendorAgencyId { get { return vendorAgencyId; } }
        public string CitationType { get { return citationType; } }
        public string VendorName { get { return vendorName; } }
        public string AgencyName { get { return agencyName; } }
        public string ConnectionType { get { return connectionType; } }
        public string ServerName { get { return serverName; } }
        public string ServerUserName { get { return serverUserName; } }
        public string ServerPassword { get { return serverPassword; } }
        public Nullable<int> ServerPort { get { return serverPort; } }
        public string LocalPath { get { return localPath; } }
        public string RemotePath { get { return remotePath; } }
        public string SSHKey { get; }
        public string Description { get; }
        public Nullable<bool> Active { get { return active; } }
        public string BCPFormatFile { get; }
        public string NodeID { get; }
        public string AgencyCode { get { return agencyCode; } }
        public Nullable<int> SLA { get; }
        public List<string> RemoteFileList
        {
            get { return remoteFileList; }
            set { remoteFileList = value; }
        }

    }
}
