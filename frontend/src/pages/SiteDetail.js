import React, { useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import {
  ArrowLeft, Globe, Server, Clock, Activity,
  Download, Play, RefreshCw, CheckCircle2, AlertCircle
} from "lucide-react";
import StatusBadge from "../components/StatusBadge";
import { MOCK_SITES, MOCK_BACKUPS } from "../mockData";

function InfoRow({ label, value }) {
  return (
    <div className="info-row">
      <span className="info-label">{label}</span>
      <span className="info-value">{value}</span>
    </div>
  );
}

export default function SiteDetail() {
  const { siteId } = useParams();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState("overview");

  const site = MOCK_SITES.find((s) => s.siteId === siteId);
  const backups = MOCK_BACKUPS.filter((b) => b.siteId === siteId);

  if (!site) {
    return (
      <div className="empty-state">
        <p>Site not found.</p>
        <button className="btn-primary" onClick={() => navigate("/")}>Back to Dashboard</button>
      </div>
    );
  }

  return (
    <div>
      {/* Header */}
      <div className="detail-header">
        <button className="btn-back" onClick={() => navigate("/")}>
          <ArrowLeft size={15} /> Back
        </button>
        <div className="detail-title-row">
          <div>
            <h1>{site.name}</h1>
            <span className="muted">{site.domain}</span>
          </div>
          <div className="detail-actions">
            <StatusBadge status={site.status} />
            <a href={`http://${site.domain}`} target="_blank" rel="noreferrer" className="btn-ghost">
              <Globe size={14} /> Open Site
            </a>
            <a href={`http://${site.domain}/wp-admin`} target="_blank" rel="noreferrer" className="btn-ghost">
              <Server size={14} /> WP Admin
            </a>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="tabs">
        {["overview", "backups", "deployments"].map((tab) => (
          <button
            key={tab}
            className={`tab ${activeTab === tab ? "active" : ""}`}
            onClick={() => setActiveTab(tab)}
          >
            {tab.charAt(0).toUpperCase() + tab.slice(1)}
          </button>
        ))}
      </div>

      {/* Overview tab */}
      {activeTab === "overview" && (
        <div className="detail-grid">
          <div className="card">
            <h2><Activity size={16} /> Site Info</h2>
            <div className="info-list">
              <InfoRow label="Domain" value={<a href={`http://${site.domain}`} target="_blank" rel="noreferrer">{site.domain}</a>} />
              <InfoRow label="Status" value={<StatusBadge status={site.status} />} />
              <InfoRow label="Uptime" value={site.uptime} />
              <InfoRow label="EC2 Instance" value={site.ec2InstanceId || "—"} />
              <InfoRow label="Created" value={new Date(site.createdAt).toLocaleString()} />
              {site.lastChecked && (
                <InfoRow label="Last Health Check" value={new Date(site.lastChecked).toLocaleString()} />
              )}
            </div>
          </div>

          <div className="card">
            <h2><Clock size={16} /> Quick Actions</h2>
            <div className="action-list">
              <button className="action-btn">
                <RefreshCw size={15} /> Run Health Check
              </button>
              <button className="action-btn">
                <Download size={15} /> Take Backup Now
              </button>
              <button className="action-btn action-btn-primary">
                <Play size={15} /> Trigger Deploy Workflow
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Backups tab */}
      {activeTab === "backups" && (
        <div className="card">
          <div className="card-header">
            <h2><Download size={16} /> Backups</h2>
            <button className="btn-primary btn-sm">
              <Download size={13} /> Take Backup
            </button>
          </div>
          {backups.length === 0 ? (
            <div className="empty-state small">
              <p>No backups yet. First automated backup runs at 02:00 UTC.</p>
            </div>
          ) : (
            <table className="sites-table">
              <thead>
                <tr>
                  <th>Backup ID</th>
                  <th>Date</th>
                  <th>Type</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {backups
                  .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
                  .map((bk) => (
                    <tr key={bk.backupId}>
                      <td className="muted" style={{ fontFamily: "monospace", fontSize: 13 }}>{bk.backupId}</td>
                      <td>{new Date(bk.createdAt).toLocaleString()}</td>
                      <td><span className="type-badge">{bk.type}</span></td>
                      <td>
                        <span className="status-inline">
                          {bk.status === "completed"
                            ? <CheckCircle2 size={14} color="#16a34a" />
                            : <AlertCircle size={14} color="#dc2626" />}
                          {bk.status}
                        </span>
                      </td>
                    </tr>
                  ))}
              </tbody>
            </table>
          )}
        </div>
      )}

      {/* Deployments tab */}
      {activeTab === "deployments" && (
        <div className="card">
          <div className="card-header">
            <h2><Play size={16} /> Deployments</h2>
            <button className="btn-primary btn-sm">
              <Play size={13} /> New Deployment
            </button>
          </div>
          <div className="empty-state small">
            <p>No deployments yet. Click <strong>New Deployment</strong> to trigger the Step Functions workflow.</p>
          </div>
        </div>
      )}
    </div>
  );
}
