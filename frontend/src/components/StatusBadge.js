import React from "react";

const COLOR = {
  active: "#16a34a",
  pending: "#d97706",
  provisioning: "#2563eb",
  installing: "#7c3aed",
  configuring_dns: "#0891b2",
  failed: "#dc2626",
  completed: "#16a34a",
};

export default function StatusBadge({ status }) {
  const color = COLOR[status] || "#6b7280";
  return (
    <span style={{
      background: color,
      color: "#fff",
      padding: "2px 10px",
      borderRadius: 12,
      fontSize: 12,
      fontWeight: 600,
      textTransform: "capitalize",
      whiteSpace: "nowrap",
    }}>
      {status?.replace(/_/g, " ") || "unknown"}
    </span>
  );
}
