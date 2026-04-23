import React from 'react';

// JARVIS Generated: React + Tailwind v4
export default function GeneratedDashboard() {
  return (
    <div className="min-h-screen bg-slate-50 p-8 font-sans">
      <header className="flex justify-between items-center mb-8">
        <h1 className="text-3xl font-bold text-slate-800">Dashboard</h1>
        <button className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-medium transition-colors">
          Create New
        </button>
      </header>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Placeholder Cards */}
        <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-100">
          <h3 className="text-slate-500 text-sm font-medium uppercase tracking-wider mb-2">Total Users</h3>
          <p className="text-4xl font-black text-slate-900">1,248</p>
        </div>
      </div>
    </div>
  );
}