import { useState } from 'react';
import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard,
  FileText,
  Users,
  Settings,
  ChevronLeft,
  ChevronRight,
  LogOut,
  FileCog,
} from 'lucide-react';
import { useAuthContext } from '../../hooks/AuthContext';
import Avatar from '../ui/Avatar';

const navItems = [
  { to: '/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/claims', icon: FileText, label: 'Claims' },
  { to: '/templates', icon: FileCog, label: 'Templates' },
  { to: '/users', icon: Users, label: 'Users' },
  { to: '/settings', icon: Settings, label: 'Settings' },
];

export default function Sidebar() {
  const [collapsed, setCollapsed] = useState(false);
  const { logout } = useAuthContext();

  return (
    <aside
      className={`fixed left-0 top-0 h-screen bg-secondary flex flex-col transition-all duration-300 z-40 ${
        collapsed ? 'w-[72px]' : 'w-[260px]'
      }`}
    >
      {/* Logo — transparent PNG rendered directly on the dark sidebar.
          brightness(0) flattens the image to black (keeping alpha), invert() lifts
          it to a grey that matches text-gray-400 (the inactive-nav color). */}
      <div className={`pt-5 pb-4 ${collapsed ? 'px-2' : 'px-3'}`}>
        <div
          className={`flex items-center justify-center transition-all duration-300 ${
            collapsed ? 'h-12' : 'h-16'
          }`}
        >
          <img
            src="/draudita_logo.png"
            alt="Draudita Insurance"
            className="h-full w-auto object-contain"
            style={{ filter: 'brightness(0) invert(0.65)' }}
          />
        </div>
      </div>

      <div className="mx-5 border-t border-white/10" />

      {/* Navigation */}
      <nav className="flex-1 py-4 px-3 space-y-1 overflow-y-auto">
        {navItems.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            className={({ isActive }) =>
              `flex items-center gap-3 px-3 py-2.5 rounded-[10px] transition-colors text-sm font-medium ${
                isActive
                  ? 'bg-primary text-white'
                  : 'text-gray-400 hover:text-white hover:bg-white/5'
              }`
            }
          >
            <Icon size={20} className="shrink-0" />
            {!collapsed && <span>{label}</span>}
          </NavLink>
        ))}
      </nav>

      {/* Collapse toggle */}
      <button
        onClick={() => setCollapsed(!collapsed)}
        className="mx-3 mb-2 p-2 rounded-lg text-gray-400 hover:text-white hover:bg-white/5 transition-colors"
      >
        {collapsed ? <ChevronRight size={18} /> : <ChevronLeft size={18} />}
      </button>

      {/* Admin profile */}
      <div className="border-t border-white/10 px-3 py-4">
        <div className="flex items-center gap-3">
          <Avatar name="Admin User" size="sm" />
          {!collapsed && (
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-white truncate">Admin User</p>
              <p className="text-xs text-gray-400 truncate">Super Admin</p>
            </div>
          )}
          {!collapsed && (
            <button
              onClick={logout}
              className="p-1.5 text-gray-400 hover:text-white transition-colors"
              title="Logout"
            >
              <LogOut size={16} />
            </button>
          )}
        </div>
      </div>
    </aside>
  );
}
