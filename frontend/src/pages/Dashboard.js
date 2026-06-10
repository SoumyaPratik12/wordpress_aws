import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  Globe, ShieldCheck, Database, TrendingUp,
  Plus, ExternalLink, RefreshCw, Search
} from "lucide-react";
import StatusBadge from "../components/StatusBadge";
import { MOCK_SITES, MOCK_STATS } from "../mockData";

function StatCard({ icon: Icon, label, value, color }) {
  return (
    <div className="stat-card">
      <div className="stat-icon" style={{ background: color }}>
        <Icon size={20} color="#fff" />
      </div>
      <div>
        <div className="stat-value">{value}</div>
        <div className="stat-label">{label}</div>
      </div>
    </div>
  );
}

export default function Dashboard() {
  const [sites] = useState(MOCK_SITES);
  const [search, setSearch] = useState("");
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ name: "", domain: "" });
  const navigate = useNavigate();

  const filtered = sites.filter(
    (s) =>
      s.name.toLowerCase().includes(search.toLowerCase()) ||
      s.domain.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div>
      {/* Stats row */}
      <div className="stats-row">
        <StatCard icon={Globe}       label="Total Sites"    value={MOCK_STATS.totalSites}  color="#2563eb" />
        <StatCard icon={ShieldCheck} label="Active Sites"   value={MOCK_STATS.activeSites} color="#16a34a" />
        <StatCard icon={Database}    label="Total Backups"  value={MOCK_STATS.totalBackups} color="#7c3aed" />
        <StatCard icon={TrendingUp}  label="Avg Uptime"     value={MOCK_STATS.avgUptime}   color="#d97706" />
      </div>

      {/* Toolbar */}
      <div className="toolbar">
        <div className="search-wrap">
          <Search size={15} className="search-icon" />
          <input
            className="search-input"
            placeholder="Search sites…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <div className="toolbar-right">
          <button className="btn-ghost" title="Refresh">
            <RefreshCw size={15} />
          </button>
          <button className="btn-primary" onClick={() => setShowForm(!showForm)}>
            <Plus size={15} />
            New Site
          </button>
        </div>
      </div>

      {/* New site form */}
      {showForm && (
        <div className="card form-card">
          <h2>Connect a site</h2>
          <div className="form-row">
            <label>
              Site name
              <input
                value={form.name}
                placeholder="My WordPress Blog"
                onChange={(e) => setForm({ ...form, name: e.target.value })}
              />
            </label>
            <label>
              Domain / IP
              <input
                value={form.domain}
                placeholder="65.2.205.51 or example.com"
                onChange={(e) => setForm({ ...form, domain: e.target.value })}
              />
            </label>
          </div>
          <div className="form-actions">
            <button className="btn-ghost" onClick={() => setShowForm(false)}>Cancel</button>
            <button className="btn-primary">
              <Plus size={14} /> Add Site
            </button>
          </div>
        </div>
      )}

      {/* Sites table */}
      <div className="card">
        <table className="sites-table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Domain</th>
              <th>Status</th>
              <th>Uptime</th>
              <th>Created</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={6} className="empty-row">No sites match your search.</td>
              </tr>
            ) : (
              filtered.map((s) => (
                <tr
                  key={s.siteId}
                  className="site-row"
                  onClick={() => navigate(`/sites/${s.siteId}`)}
                >
                  <td className="site-name">{s.name}</td>
                  <td className="site-domain">
                    <Globe size={13} className="domain-icon" />
                    {s.domain}
                  </td>
                  <td><StatusBadge status={s.status} /></td>
                  <td className="uptime">{s.uptime}</td>
                  <td className="muted">{new Date(s.createdAt).toLocaleDateString()}</td>
                  <td onClick={(e) => e.stopPropagation()}>
                    <a
                      href={`http://${s.domain}`}
                      target="_blank"
                      rel="noreferrer"
                      className="btn-icon"
                      title="Open site"
                    >
                      <ExternalLink size={14} />
                    </a>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
