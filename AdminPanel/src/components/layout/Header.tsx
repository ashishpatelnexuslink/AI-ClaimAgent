import { useState, useRef, useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { Search, Bell, ChevronDown, User, Lock, LogOut } from 'lucide-react';
import { useAuthContext } from '../../hooks/AuthContext';
import Avatar from '../ui/Avatar';

const pageTitles: Record<string, string> = {
  '/dashboard': 'Dashboard',
  '/claims': 'Claims Management',
  '/users': 'User Management',
  '/conversations': 'Conversations',
  '/settings': 'Settings',
};

export default function Header() {
  const location = useLocation();
  const { logout } = useAuthContext();
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  const basePath = '/' + location.pathname.split('/')[1];
  const title = pageTitles[basePath] || 'ClaimAI Admin';

  useEffect(() => {
    const handleClick = (e: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        setDropdownOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, []);

  return (
    <header className="bg-card border-b border-gray-200 h-16 px-6 flex items-center justify-between shrink-0">
      <h1 className="text-xl font-semibold text-secondary">{title}</h1>

      <div className="flex items-center gap-4">
        {/* Search */}
        <div className="relative">
          <Search size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Search claims, users..."
            className="pl-10 pr-4 py-2 text-sm bg-surface rounded-lg border-none focus:outline-none focus:ring-2 focus:ring-primary/30 w-64"
          />
        </div>

        {/* Notifications */}
        <button className="relative p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-lg transition-colors">
          <Bell size={20} />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-danger rounded-full" />
        </button>

        {/* Profile dropdown */}
        <div className="relative" ref={dropdownRef}>
          <button
            onClick={() => setDropdownOpen(!dropdownOpen)}
            className="flex items-center gap-2 hover:bg-gray-50 rounded-lg px-2 py-1 transition-colors"
          >
            <Avatar name="Admin User" size="sm" />
            <ChevronDown size={16} className="text-gray-400" />
          </button>

          {dropdownOpen && (
            <div className="absolute right-0 top-12 w-48 bg-white rounded-xl shadow-lg border border-gray-100 py-1 z-50">
              <button className="w-full flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50">
                <User size={16} /> Profile
              </button>
              <button className="w-full flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-gray-50">
                <Lock size={16} /> Change Password
              </button>
              <hr className="my-1 border-gray-100" />
              <button
                onClick={logout}
                className="w-full flex items-center gap-3 px-4 py-2.5 text-sm text-red-600 hover:bg-red-50"
              >
                <LogOut size={16} /> Logout
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
