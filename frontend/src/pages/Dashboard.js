import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { getSites, createSite } from "../api";
import StatusBadge from "../components/StatusBadge";

export default function Dashboard() {
  const [sites, setSites] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ name: "", domain: "" });
  const [creating, setCreating] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    getSites()
      .then(setSites)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  async function handleCreate(e) {
    e.preventDefault();
    setCreating(true);
    try {
      const site = await createSite(form);
      setSites((prev) => [site, ...prev]);
      setShowForm(false);
      setForm({ name: "", domain: "" });
    } catch (e) {
      setError(e.message);
    } finally {
      setCreating(false);
    }
  }

  return (
    <div>
      <div className="page-header">
        <h1>Sites</h1>
        <button className="btn-primary" onClick={() => setShowForm(!showForm)}>
          {showForm ? "Cancel" : "+ New Site"}
        </button>
      </div>

      {showForm && (
        <form className="card form-card" onSubmit={handleCreate}>
          <h2>Add a site</h2>
          <label>Site name
            <input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required />
          </label>
          <label>Domain / IP
            <input value={form.domain} placeholder="e.g. 65.2.205.51" onChange={(e) => setForm({ ...form, domain: e.target.value })} required />
          </label>
          <button className="btn-primary" type="submit" disabled={creating}>
            {creating ? "Creating…" : "Create"}
          </button>
        </form>
      )}

      {error && <div className="alert-error">{error}</div>}

      {loading ? (
        <p className="muted">Loading sites…</p>
      ) : sites.length === 0 ? (
        <div className="empty-state">
          <p>No sites yet. Click <strong>+ New Site</strong> to connect your first WordPress site.</p>
        </div>
      ) : (
        <div className="site-grid">
          {sites.map((s) => (
            <div key={s.siteId} className="card site-card" onClick={() => navigate(`/sites/${s.siteId}`)}>
              <div className="site-card-header">
                <h3>{s.name}</h3>
                <StatusBadge status={s.status} />
              </div>
              <p className="muted">{s.domain}</p>
              <p className="site-card-date">Added {new Date(s.createdAt).toLocaleDateString()}</p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
