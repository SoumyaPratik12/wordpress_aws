import React from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { Authenticator, useAuthenticator } from "@aws-amplify/ui-react";
import "@aws-amplify/ui-react/styles.css";
import Dashboard from "./pages/Dashboard";
import SiteDetail from "./pages/SiteDetail";
import Navbar from "./components/Navbar";
import "./App.css";

function AppRoutes() {
  const { signOut, user } = useAuthenticator((ctx) => [ctx.user]);
  return (
    <BrowserRouter>
      <Navbar user={user} onSignOut={signOut} />
      <div className="page-container">
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/sites/:siteId" element={<SiteDetail />} />
          <Route path="*" element={<Navigate to="/" />} />
        </Routes>
      </div>
    </BrowserRouter>
  );
}

export default function App() {
  return (
    <Authenticator
      loginMechanisms={["email"]}
      formFields={{
        signIn: {
          username: { label: "Email", placeholder: "soumya.pratik2@gmail.com" },
        },
      }}
    >
      <AppRoutes />
    </Authenticator>
  );
}
