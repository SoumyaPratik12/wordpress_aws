import React, { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { getSite, getBackups } from "../api";
import StatusBadge from "../components/StatusBadge";

export default function SiteDetail() {
  const { siteId } = useParams();
  const navigate = useNavigate();
  const [site, setSite] = useState(null);
  const [backups, setBackups] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    Promise.all([getSite(siteId), getBackups(siteId)])
      .then(([s, b]) => { setSite(s); setBackups(b); })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [siteId]);

  if (loading) return <p className="muted">Loading…</p>;
  if (error) return <div className="alert-error">{error} <button onClick={() => navigate("/")}>Back</button></div>;
  if (!site) return null;

  return (
    <div>
      <button className="btn-back" onClick={() => navigate("/")}>← Back</button>

      <div className="page-header">
        <h1>{site.name}</h1>
        <StatusBadge status={site.status} />
      </div>

      <div className="detail-grid">
        <div className="card">
          <h2>Site Info</h2>
          <table className="info-table">
            <tbody>
              <tr><td>Domain / IP</td><td><a href={`http://${site.domain}`} target="_blank" rel="noreferrer">{site.domain}</a></td></tr>
              <tr><td>WP Admin</td><td><a href={`http://${site.domain}/wp-admin`} target="_blank" rel="noreferrer">wp-admin ↗</a></td></tr>
              <tr><td>Status</td><td><StatusBadge status={site.status} /></td></tr>
              <tr><td>Owner</td><td>{site.ownerId}</td></tr>
              <tr><td>Created</td><td>{new Date(site.createdAt).toLocaleString()}</td></tr>
              {site.ec2InstanceId && <tr><td>EC2 Instance</td><td>{site.ec2InstanceId}</td></tr>}
            </tbody>
          </table>
        </div>

        <div className="card">
          <h2>Backups ({backups.length})</h2>
          {backups.length === 0 ? (
            <p className="muted">No backups yet. The first automated backup runs at 02:00 UTC.</p>
          ) : (
            <ul className="backup-list">
              {backups
                .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
                .map((bk) => (
                  <li key={bk.backupId}>
                    <span>{new Date(bk.createdAt).toLocaleString()}</span>
                    <span className={`badge badge-${bk.status}`}>{bk.status}</span>
                  </li>
                ))}
            </ul>
          )}
        </div>
      </div>
    </div>
  );
}
