import React from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { Authenticator } from "@aws-amplify/ui-react";
import "@aws-amplify/ui-react/styles.css";
import Dashboard from "./pages/Dashboard";
import SiteDetail from "./pages/SiteDetail";
import "./App.css";

function App() {
  return (
    <Authenticator>
      {({ signOut, user }) => (
        <BrowserRouter>
          <nav className="navbar">
            <span className="navbar-brand">⚡ WP Platform</span>
            <span className="navbar-user">{user?.signInDetails?.loginId}</span>
            <button className="btn-signout" onClick={signOut}>Sign out</button>
          </nav>
          <div className="page-container">
            <Routes>
              <Route path="/" element={<Dashboard user={user} />} />
              <Route path="/sites/:siteId" element={<SiteDetail user={user} />} />
              <Route path="*" element={<Navigate to="/" />} />
            </Routes>
          </div>
        </BrowserRouter>
      )}
    </Authenticator>
  );
}

export default App;
