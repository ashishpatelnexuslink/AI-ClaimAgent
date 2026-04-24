import { useState, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { LayoutGrid, List, Search } from 'lucide-react';
import { useQuery } from '@tanstack/react-query';
import { usersService } from '../../services/users.service';
import Badge from '../../components/ui/Badge';
import Button from '../../components/ui/Button';
import Avatar from '../../components/ui/Avatar';
import Spinner from '../../components/ui/Spinner';
import { format } from 'date-fns';
import type { User } from '../../types';

export default function UsersPage() {
  const { data: users, isLoading } = useQuery({ queryKey: ['users'], queryFn: usersService.getAll });
  const navigate = useNavigate();
  const [viewMode, setViewMode] = useState<'grid' | 'table'>('grid');
  const [search, setSearch] = useState('');

  const filtered = useMemo(() => {
    if (!users) return [];
    if (!search) return users;
    return users.filter((u) =>
      u.name.toLowerCase().includes(search.toLowerCase()) ||
      u.email.toLowerCase().includes(search.toLowerCase())
    );
  }, [users, search]);

  if (isLoading) {
    return <div className="flex items-center justify-center h-96"><Spinner size="lg" /></div>;
  }

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold text-secondary">User Management</h2>
        <div className="flex items-center gap-3">
          <div className="relative">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search users..."
              className="pl-9 pr-4 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30 w-60"
            />
          </div>
          <div className="flex border border-gray-300 rounded-lg overflow-hidden">
            <button
              onClick={() => setViewMode('grid')}
              className={`p-2 ${viewMode === 'grid' ? 'bg-primary text-white' : 'text-gray-500 hover:bg-gray-50'}`}
            >
              <LayoutGrid size={16} />
            </button>
            <button
              onClick={() => setViewMode('table')}
              className={`p-2 ${viewMode === 'table' ? 'bg-primary text-white' : 'text-gray-500 hover:bg-gray-50'}`}
            >
              <List size={16} />
            </button>
          </div>
        </div>
      </div>

      {viewMode === 'grid' ? (
        <div className="grid grid-cols-3 gap-5">
          {filtered.map((user: User) => (
            <div key={user.id} className="bg-card rounded-2xl p-5 shadow-sm hover:shadow-md transition-shadow">
              <div className="flex flex-col items-center text-center">
                <Avatar name={user.name} src={user.profileImage} size="lg" />
                <p className="text-sm font-semibold text-gray-800 mt-3">{user.name}</p>
                <p className="text-xs text-gray-500">{user.email}</p>
                <div className="flex gap-2 mt-3">
                  <Badge status={`${user.totalClaims} Claims`} />
                  <Badge status={user.status} />
                </div>
                <Button
                  variant="outline"
                  size="sm"
                  className="mt-4 w-full"
                  onClick={() => navigate(`/users/${user.id}`)}
                >
                  View Profile
                </Button>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="bg-card rounded-xl shadow-sm overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-100">
                <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">User</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Email</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Phone</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Country</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Member Since</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Claims</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Avatar</th>
                <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Status</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((user: User) => (
                <tr
                  key={user.id}
                  className="border-b border-gray-50 hover:bg-gray-50/50 cursor-pointer transition-colors"
                  onClick={() => navigate(`/users/${user.id}`)}
                >
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <Avatar name={user.name} src={user.profileImage} size="sm" />
                      <span className="text-sm font-medium text-gray-800">{user.name}</span>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-sm text-gray-600">{user.email}</td>
                  <td className="px-4 py-3 text-sm text-gray-600">{user.phone}</td>
                  <td className="px-4 py-3 text-sm text-gray-600">{user.country}</td>
                  <td className="px-4 py-3 text-sm text-gray-500">{format(new Date(user.memberSince), 'dd MMM yyyy')}</td>
                  <td className="px-4 py-3 text-sm font-medium text-gray-800">{user.totalClaims}</td>
                  <td className="px-4 py-3 text-sm text-gray-600">{user.avatarPersonality}</td>
                  <td className="px-4 py-3"><Badge status={user.status} /></td>
                </tr>
              ))}
            </tbody>
          </table>
          {filtered.length === 0 && (
            <div className="text-center py-12 text-gray-400 text-sm">No users found</div>
          )}
        </div>
      )}
    </div>
  );
}
