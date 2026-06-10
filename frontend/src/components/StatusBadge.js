import React from "react";

const STYLES = {
  active:           { bg: "#dcfce7", color: "#15803d" },
  pending:          { bg: "#fef9c3", color: "#a16207" },
  provisioning:     { bg: "#dbeafe", color: "#1d4ed8" },
  installing:       { bg: "#ede9fe", color: "#6d28d9" },
  configuring_dns:  { bg: "#e0f2fe", color: "#0369a1" },
  failed:           { bg: "#fee2e2", color: "#b91c1c" },
  completed:        { bg: "#dcfce7", color: "#15803d" },
};

export default function StatusBadge({ status }) {
  const s = STYLES[status] || { bg: "#f1f5f9", color: "#475569" };
  return (
    <span style={{
      background: s.bg,
      color: s.color,
      padding: "3px 10px",
      borderRadius: 20,
      fontSize: 12,
      fontWeight: 600,
      textTransform: "capitalize",
      whiteSpace: "nowrap",
      display: "inline-block",
    }}>
      {status?.replace(/_/g, " ") || "unknown"}
    </span>
  );
}
