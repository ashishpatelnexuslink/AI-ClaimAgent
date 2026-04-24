import { useState, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search, RotateCcw } from 'lucide-react';
import { useQuery } from '@tanstack/react-query';
import { conversationsService } from '../../services/conversations.service';
import Badge from '../../components/ui/Badge';
import Spinner from '../../components/ui/Spinner';
import Avatar from '../../components/ui/Avatar';
import { format } from 'date-fns';

function formatDuration(seconds: number): string {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m}m ${s}s`;
}

export default function ConversationsPage() {
  const { data: conversations, isLoading } = useQuery({
    queryKey: ['conversations'],
    queryFn: conversationsService.getAll,
  });
  const navigate = useNavigate();

  const [search, setSearch] = useState('');
  const [modeFilter, setModeFilter] = useState('All');
  const [statusFilter, setStatusFilter] = useState('All');

  const filtered = useMemo(() => {
    if (!conversations) return [];
    return conversations.filter((c) => {
      if (search && !c.userName.toLowerCase().includes(search.toLowerCase()) && !c.threadId.toLowerCase().includes(search.toLowerCase())) return false;
      if (modeFilter !== 'All' && c.mode !== modeFilter) return false;
      if (statusFilter !== 'All' && c.status !== statusFilter) return false;
      return true;
    });
  }, [conversations, search, modeFilter, statusFilter]);

  if (isLoading) {
    return <div className="flex items-center justify-center h-96"><Spinner size="lg" /></div>;
  }

  return (
    <div className="space-y-5">
      <h2 className="text-lg font-semibold text-secondary">Conversations</h2>

      {/* Filters */}
      <div className="bg-card rounded-xl p-4 shadow-sm flex flex-wrap items-end gap-4">
        <div>
          <label className="block text-xs font-medium text-gray-500 mb-1">Search</label>
          <div className="relative">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="User or thread ID"
              className="pl-9 pr-4 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30 w-52"
            />
          </div>
        </div>
        <div>
          <label className="block text-xs font-medium text-gray-500 mb-1">Mode</label>
          <select value={modeFilter} onChange={(e) => setModeFilter(e.target.value)} className="px-3 py-2 text-sm border border-gray-300 rounded-lg">
            <option>All</option>
            <option>Voice</option>
            <option>Chat</option>
          </select>
        </div>
        <div>
          <label className="block text-xs font-medium text-gray-500 mb-1">Status</label>
          <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="px-3 py-2 text-sm border border-gray-300 rounded-lg">
            <option>All</option>
            <option>Active</option>
            <option>Completed</option>
            <option>Abandoned</option>
          </select>
        </div>
        <button
          onClick={() => { setSearch(''); setModeFilter('All'); setStatusFilter('All'); }}
          className="flex items-center gap-1 text-sm text-primary hover:underline pb-2"
        >
          <RotateCcw size={14} /> Reset
        </button>
      </div>

      {/* Table */}
      <div className="bg-card rounded-xl shadow-sm overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="border-b border-gray-100">
              <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Thread ID</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">User</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Mode</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Started</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Duration</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Messages</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Linked Claim</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Status</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((conv) => (
              <tr
                key={conv.id}
                className="border-b border-gray-50 hover:bg-gray-50/50 cursor-pointer transition-colors"
                onClick={() => navigate(`/conversations/${conv.id}`)}
              >
                <td className="px-4 py-3 text-sm font-mono text-primary font-medium">{conv.threadId}</td>
                <td className="px-4 py-3">
                  <div className="flex items-center gap-2">
                    <Avatar name={conv.userName} size="sm" />
                    <span className="text-sm text-gray-700">{conv.userName}</span>
                  </div>
                </td>
                <td className="px-4 py-3"><Badge status={conv.mode} /></td>
                <td className="px-4 py-3 text-sm text-gray-500">{format(new Date(conv.startedAt), 'dd MMM yyyy, HH:mm')}</td>
                <td className="px-4 py-3 text-sm text-gray-700">{formatDuration(conv.duration)}</td>
                <td className="px-4 py-3 text-sm text-gray-700">{conv.messageCount}</td>
                <td className="px-4 py-3 text-sm">{conv.claimId ? <span className="text-primary font-medium">CLM-{conv.claimId}</span> : <span className="text-gray-400">-</span>}</td>
                <td className="px-4 py-3"><Badge status={conv.status} /></td>
              </tr>
            ))}
          </tbody>
        </table>
        {filtered.length === 0 && (
          <div className="text-center py-12 text-gray-400 text-sm">No conversations found</div>
        )}
      </div>
    </div>
  );
}
