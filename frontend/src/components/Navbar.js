import React from "react";
import { Link, useLocation } from "react-router-dom";
import { LayoutDashboard, Globe } from "lucide-react";

export default function Navbar() {
  const location = useLocation();
  return (
    <nav className="navbar">
      <div className="navbar-left">
        <span className="navbar-brand">⚡ WP Platform</span>
        <Link
          to="/"
          className={`nav-link ${location.pathname === "/" ? "active" : ""}`}
        >
          <LayoutDashboard size={15} />
          Dashboard
        </Link>
      </div>
      <div className="navbar-right">
        <span className="nav-env-badge">dev</span>
        <div className="nav-avatar">SP</div>
      </div>
    </nav>
  );
}
