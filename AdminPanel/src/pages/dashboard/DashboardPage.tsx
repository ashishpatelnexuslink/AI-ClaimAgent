import { Link } from 'react-router-dom';
import {
  FileText, Clock, CheckCircle, XCircle, Users, MessageSquare, Timer,
} from 'lucide-react';
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend,
  PieChart, Pie, Cell,
} from 'recharts';
import {
  useDashboardStats,
  useClaimsTrend,
  useClaims,
  useClaimsByType,
} from '../../hooks/useClaims';
import StatCard from '../../components/ui/StatCard';
import Badge from '../../components/ui/Badge';
import Spinner from '../../components/ui/Spinner';
import { format } from 'date-fns';

const PIE_COLORS = ['#2A6FDB', '#FDCB6E', '#FF6B6B', '#9B59B6', '#00B894', '#E17055', '#6C5CE7', '#FAB1A0'];

function deltaSubtitle(pct: number | null | undefined, fallback: string) {
  if (pct === null || pct === undefined) return fallback;
  const dir = pct >= 0 ? '+' : '';
  return `${dir}${pct}% vs prior 30d`;
}

function deltaTrend(pct: number | null | undefined): { value: number; direction: 'up' | 'down' } | undefined {
  if (pct === null || pct === undefined) return undefined;
  return { value: Math.abs(pct), direction: pct >= 0 ? 'up' : 'down' };
}

export default function DashboardPage() {
  const { data: stats, isLoading: statsLoading } = useDashboardStats();
  const { data: trend, isLoading: trendLoading } = useClaimsTrend();
  const { data: claims } = useClaims();
  const { data: typeBreakdown, isLoading: typeLoading } = useClaimsByType();

  if (statsLoading) {
    return (
      <div className="flex items-center justify-center h-96">
        <Spinner size="lg" />
      </div>
    );
  }

  const recentClaims = claims?.slice(0, 5) ?? [];
  const pieData = (typeBreakdown ?? []).map((t) => ({ name: t.type, value: t.count }));
  const hasTypeData = pieData.some((p) => p.value > 0);

  return (
    <div className="space-y-6">
      {/* ROW 1: Stat Cards */}
      <div className="grid grid-cols-4 gap-5">
        <StatCard
          title="Total Claims"
          value={stats?.totalClaims ?? 0}
          icon={<FileText size={20} className="text-primary" />}
          color="blue"
          subtitle={deltaSubtitle(stats?.totalClaimsDeltaPct, 'All-time claims')}
          trend={deltaTrend(stats?.totalClaimsDeltaPct)}
        />
        <StatCard
          title="Pending Claims"
          value={stats?.pendingClaims ?? 0}
          icon={<Clock size={20} className="text-amber-500" />}
          color="amber"
          subtitle="Needs review"
        />
        <StatCard
          title="Approved"
          value={stats?.approvedClaims ?? 0}
          icon={<CheckCircle size={20} className="text-success" />}
          color="green"
          subtitle={deltaSubtitle(stats?.approvedDeltaPct, 'All-time approved')}
          trend={deltaTrend(stats?.approvedDeltaPct)}
        />
        <StatCard
          title="Rejected"
          value={stats?.rejectedClaims ?? 0}
          icon={<XCircle size={20} className="text-danger" />}
          color="red"
          subtitle={deltaSubtitle(stats?.rejectedDeltaPct, 'All-time rejected')}
          trend={deltaTrend(stats?.rejectedDeltaPct)}
        />
      </div>

      {/* ROW 2: Charts */}
      <div className="grid grid-cols-3 gap-5">
        <div className="col-span-2 bg-card rounded-2xl p-5 shadow-sm">
          <h3 className="text-base font-semibold text-secondary mb-4">Claims Overview (last 30 days)</h3>
          {trendLoading ? (
            <div className="h-64 flex items-center justify-center"><Spinner /></div>
          ) : (trend ?? []).length === 0 ? (
            <div className="h-64 flex items-center justify-center text-sm text-gray-400">
              No claim activity in the last 30 days.
            </div>
          ) : (
            <ResponsiveContainer width="100%" height={280}>
              <LineChart data={trend}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="date" tick={{ fontSize: 11 }} tickFormatter={(v) => format(new Date(v), 'dd MMM')} />
                <YAxis tick={{ fontSize: 11 }} allowDecimals={false} />
                <Tooltip labelFormatter={(v) => format(new Date(v), 'dd MMM yyyy')} />
                <Legend />
                <Line type="monotone" dataKey="submitted" stroke="#2A6FDB" strokeWidth={2} dot={false} name="Submitted" />
                <Line type="monotone" dataKey="approved" stroke="#00B894" strokeWidth={2} dot={false} name="Approved" />
                <Line type="monotone" dataKey="rejected" stroke="#FF6B6B" strokeWidth={2} dot={false} name="Rejected" />
              </LineChart>
            </ResponsiveContainer>
          )}
        </div>

        <div className="bg-card rounded-2xl p-5 shadow-sm">
          <h3 className="text-base font-semibold text-secondary mb-4">Claims by Type</h3>
          {typeLoading ? (
            <div className="h-56 flex items-center justify-center"><Spinner /></div>
          ) : !hasTypeData ? (
            <div className="h-56 flex items-center justify-center text-sm text-gray-400">
              No claims yet.
            </div>
          ) : (
            <>
              <ResponsiveContainer width="100%" height={220}>
                <PieChart>
                  <Pie data={pieData} cx="50%" cy="50%" innerRadius={50} outerRadius={80} dataKey="value" paddingAngle={4}>
                    {pieData.map((_, idx) => (
                      <Cell key={idx} fill={PIE_COLORS[idx % PIE_COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
              <div className="flex flex-wrap gap-3 justify-center">
                {pieData.map((item, idx) => (
                  <div key={item.name} className="flex items-center gap-1.5 text-xs text-gray-600">
                    <span className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: PIE_COLORS[idx % PIE_COLORS.length] }} />
                    {item.name} · {item.value}
                  </div>
                ))}
              </div>
            </>
          )}
        </div>
      </div>

      {/* ROW 3: Recent Claims */}
      <div className="bg-card rounded-2xl p-5 shadow-sm">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-base font-semibold text-secondary">Recent Claims</h3>
          <Link to="/claims" className="text-sm text-primary hover:underline">View All</Link>
        </div>
        <div className="space-y-0">
          <table className="w-full">
            <thead>
              <tr className="text-xs text-gray-500 uppercase border-b border-gray-100">
                <th className="text-left py-2 font-semibold">Claim #</th>
                <th className="text-left py-2 font-semibold">User</th>
                <th className="text-left py-2 font-semibold">Type</th>
                <th className="text-left py-2 font-semibold">Status</th>
                <th className="text-left py-2 font-semibold">Date</th>
              </tr>
            </thead>
            <tbody>
              {recentClaims.map((claim) => (
                <tr key={claim.id} className="border-b border-gray-50 hover:bg-gray-50/50">
                  <td className="py-2.5">
                    <Link to={`/claims/${claim.id}`} className="text-sm font-medium text-primary hover:underline">
                      {claim.claimNumber}
                    </Link>
                  </td>
                  <td className="py-2.5 text-sm text-gray-700">{claim.userName}</td>
                  <td className="py-2.5 text-sm text-gray-700">{claim.type}</td>
                  <td className="py-2.5"><Badge status={claim.status} /></td>
                  <td className="py-2.5 text-sm text-gray-500">{format(new Date(claim.submittedAt), 'dd MMM yyyy')}</td>
                </tr>
              ))}
              {recentClaims.length === 0 && (
                <tr>
                  <td colSpan={5} className="py-6 text-sm text-gray-400 text-center">
                    No claims submitted yet.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* ROW 4: Bottom Stats */}
      <div className="grid grid-cols-3 gap-5">
        <StatCard
          title="Total Users"
          value={stats?.totalUsers ?? 0}
          icon={<Users size={20} className="text-primary" />}
          color="blue"
          subtitle="Registered users"
        />
        <StatCard
          title="Active Conversations"
          value={stats?.activeConversations ?? 0}
          icon={<MessageSquare size={20} className="text-purple-500" />}
          color="purple"
          subtitle="Active in last 24h"
        />
        <StatCard
          title="Avg Resolution Time"
          value={`${stats?.avgResolutionDays ?? 0} days`}
          icon={<Timer size={20} className="text-success" />}
          color="green"
          subtitle="Approved / rejected / closed"
        />
      </div>
    </div>
  );
}
