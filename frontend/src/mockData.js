// Mock data — replace with real API calls in the next phase
export const MOCK_SITES = [
  {
    siteId: "demo-site-001",
    name: "Demo WordPress Site",
    domain: "65.2.205.51",
    status: "active",
    createdAt: "2026-06-10T00:00:00Z",
    ec2InstanceId: "i-0aa04575477355173",
    ownerId: "system",
    uptime: "99.8%",
    lastChecked: "2026-06-10T05:00:00Z",
  },
  {
    siteId: "site-002",
    name: "Client Blog",
    domain: "blog.example.com",
    status: "active",
    createdAt: "2026-06-08T10:00:00Z",
    ec2InstanceId: null,
    ownerId: "user-1",
    uptime: "100%",
    lastChecked: "2026-06-10T05:00:00Z",
  },
  {
    siteId: "site-003",
    name: "E-commerce Store",
    domain: "shop.example.com",
    status: "provisioning",
    createdAt: "2026-06-10T04:30:00Z",
    ec2InstanceId: null,
    ownerId: "user-2",
    uptime: "—",
    lastChecked: null,
  },
];

export const MOCK_BACKUPS = [
  { backupId: "bk-001", siteId: "demo-site-001", createdAt: "2026-06-10T02:00:00Z", status: "completed", type: "scheduled" },
  { backupId: "bk-002", siteId: "demo-site-001", createdAt: "2026-06-09T02:00:00Z", status: "completed", type: "scheduled" },
  { backupId: "bk-003", siteId: "demo-site-001", createdAt: "2026-06-08T02:00:00Z", status: "completed", type: "scheduled" },
];

export const MOCK_STATS = {
  totalSites: 3,
  activeSites: 2,
  totalBackups: 3,
  avgUptime: "99.9%",
};
