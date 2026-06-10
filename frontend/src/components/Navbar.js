import React from "react";
import { Link, useLocation } from "react-router-dom";
import { LayoutDashboard, LogOut } from "lucide-react";

export default function Navbar({ user, onSignOut }) {
  const location = useLocation();
  const email = user?.signInDetails?.loginId || "";
  const initials = email.slice(0, 2).toUpperCase();

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
        <span className="nav-email">{email}</span>
        <div className="nav-avatar">{initials}</div>
        <button className="btn-signout" onClick={onSignOut} title="Sign out">
          <LogOut size={14} />
        </button>
      </div>
    </nav>
  );
}
