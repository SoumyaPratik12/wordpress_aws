import { fetchAuthSession } from "aws-amplify/auth";
import { API_ENDPOINT } from "./aws-config";

async function authHeaders() {
  const session = await fetchAuthSession();
  const token = session.tokens?.idToken?.toString();
  return { Authorization: `Bearer ${token}`, "Content-Type": "application/json" };
}

export async function getSites() {
  const headers = await authHeaders();
  const res = await fetch(`${API_ENDPOINT}/sites`, { headers });
  if (!res.ok) throw new Error(`getSites failed: ${res.status}`);
  return res.json();
}

export async function getSite(siteId) {
  const headers = await authHeaders();
  const res = await fetch(`${API_ENDPOINT}/sites/${siteId}`, { headers });
  if (!res.ok) throw new Error(`getSite failed: ${res.status}`);
  return res.json();
}

export async function createSite(data) {
  const headers = await authHeaders();
  const res = await fetch(`${API_ENDPOINT}/sites`, {
    method: "POST",
    headers,
    body: JSON.stringify(data),
  });
  if (!res.ok) throw new Error(`createSite failed: ${res.status}`);
  return res.json();
}

export async function getBackups(siteId) {
  const headers = await authHeaders();
  const res = await fetch(`${API_ENDPOINT}/backups?siteId=${siteId}`, { headers });
  if (!res.ok) throw new Error(`getBackups failed: ${res.status}`);
  return res.json();
}
