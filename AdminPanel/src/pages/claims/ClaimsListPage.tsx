import { useState, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { Filter, RotateCcw, Eye } from 'lucide-react';
import { useClaims } from '../../hooks/useClaims';
import Badge from '../../components/ui/Badge';
import Button from '../../components/ui/Button';
import Avatar from '../../components/ui/Avatar';
import Spinner from '../../components/ui/Spinner';
import { format } from 'date-fns';
import type { Claim } from '../../types';

const PAGE_SIZES = [10, 25, 50];

export default function ClaimsListPage() {
  const { data: claims, isLoading, error } = useClaims();
  const navigate = useNavigate();

  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('All');
  const [typeFilter, setTypeFilter] = useState('All');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [showFilters, setShowFilters] = useState(false);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);

  const filtered = useMemo(() => {
    if (!claims) return [];
    return claims.filter((c) => {
      if (search && !c.claimNumber.toLowerCase().includes(search.toLowerCase()) && !c.userName.toLowerCase().includes(search.toLowerCase())) return false;
      if (statusFilter !== 'All' && c.status !== statusFilter) return false;
      if (typeFilter !== 'All' && !c.type.toLowerCase().includes(typeFilter.toLowerCase())) return false;
      if (dateFrom && c.incidentDate < dateFrom) return false;
      if (dateTo && c.incidentDate > dateTo) return false;
      return true;
    });
  }, [claims, search, statusFilter, typeFilter, dateFrom, dateTo]);

  const totalPages = Math.ceil(filtered.length / pageSize);
  const paged = filtered.slice((page - 1) * pageSize, page * pageSize);

  const resetFilters = () => {
    setSearch(''); setStatusFilter('All'); setTypeFilter('All');
    setDateFrom(''); setDateTo(''); setPage(1);
  };

  if (isLoading) {
    return <div className="flex items-center justify-center h-96"><Spinner size="lg" /></div>;
  }

  return (
    <div className="space-y-5">
      {/* Top Bar */}
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold text-secondary">Claims Management</h2>
        <div className="flex gap-3">
          <Button variant="outline" size="sm" onClick={() => setShowFilters(!showFilters)}>
            <Filter size={16} /> Filter
          </Button>
        </div>
      </div>

      {/* Filters */}
      {showFilters && (
        <div className="bg-card rounded-xl p-4 shadow-sm flex flex-wrap items-end gap-4">
          <div>
            <label className="block text-xs font-medium text-gray-500 mb-1">Search</label>
            <input
              type="text"
              value={search}
              onChange={(e) => { setSearch(e.target.value); setPage(1); }}
              placeholder="Claim # or user name"
              className="px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30 w-52"
            />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-500 mb-1">Status</label>
            <select
              value={statusFilter}
              onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }}
              className="px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30"
            >
              <option value="All">All</option>
              <option value="Pending">Pending</option>
              <option value="Submitted">Submitted</option>
              <option value="InReview">Under Review</option>
              <option value="Approved">Approved</option>
              <option value="Rejected">Rejected</option>
              <option value="Closed">Closed</option>
            </select>
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-500 mb-1">Type</label>
            <input
              type="text"
              value={typeFilter === 'All' ? '' : typeFilter}
              onChange={(e) => {
                setTypeFilter(e.target.value ? e.target.value : 'All');
                setPage(1);
              }}
              placeholder="Any type"
              className="px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30 w-44"
            />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-500 mb-1">From</label>
            <input type="date" value={dateFrom} onChange={(e) => { setDateFrom(e.target.value); setPage(1); }} className="px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30" />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-500 mb-1">To</label>
            <input type="date" value={dateTo} onChange={(e) => { setDateTo(e.target.value); setPage(1); }} className="px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30" />
          </div>
          <button onClick={resetFilters} className="flex items-center gap-1 text-sm text-primary hover:underline pb-2">
            <RotateCcw size={14} /> Reset
          </button>
        </div>
      )}

      {/* Table */}
      <div className="bg-card rounded-xl shadow-sm overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="border-b border-gray-100">
              <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Claim #</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">User</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Type</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Vehicle Reg</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Incident Date</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Submitted</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Status</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody>
            {paged.map((claim: Claim) => (
              <tr key={claim.id} className="border-b border-gray-50 hover:bg-gray-50/50 transition-colors">
                <td className="px-4 py-3">
                  <button
                    onClick={() => navigate(`/claims/${claim.id}`)}
                    className="text-sm font-semibold text-primary hover:underline"
                  >
                    {claim.claimNumber}
                  </button>
                </td>
                <td className="px-4 py-3">
                  <div className="flex items-center gap-2">
                    <Avatar name={claim.userName} size="sm" />
                    <span className="text-sm text-gray-700">{claim.userName}</span>
                  </div>
                </td>
                <td className="px-4 py-3 text-sm text-gray-700">{claim.type}</td>
                <td className="px-4 py-3 text-sm text-gray-700 font-mono">{claim.vehicleReg}</td>
                <td className="px-4 py-3 text-sm text-gray-500">{format(new Date(claim.incidentDate), 'dd MMM yyyy')}</td>
                <td className="px-4 py-3 text-sm text-gray-500">{format(new Date(claim.submittedAt), 'dd MMM yyyy')}</td>
                <td className="px-4 py-3"><Badge status={claim.status} /></td>
                <td className="px-4 py-3">
                  <div className="flex items-center gap-1">
                    <button
                      onClick={() => navigate(`/claims/${claim.id}`)}
                      className="p-1.5 text-gray-400 hover:text-primary hover:bg-gray-100 rounded-lg"
                      title="View"
                    >
                      <Eye size={16} />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {paged.length === 0 && !error && (
          <div className="text-center py-12 text-gray-400 text-sm">No claims match the current filters</div>
        )}
        {error && (
          <div className="text-center py-12 text-red-600 text-sm">
            Failed to load claims: {(error as Error).message}
          </div>
        )}
      </div>

      {/* Pagination */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2 text-sm text-gray-500">
          Show
          <select
            value={pageSize}
            onChange={(e) => { setPageSize(Number(e.target.value)); setPage(1); }}
            className="border border-gray-300 rounded-lg px-2 py-1 text-sm"
          >
            {PAGE_SIZES.map((s) => <option key={s} value={s}>{s}</option>)}
          </select>
          per page
        </div>
        <div className="flex items-center gap-2 text-sm">
          <span className="text-gray-500">
            Showing {((page - 1) * pageSize) + 1} to {Math.min(page * pageSize, filtered.length)} of {filtered.length} results
          </span>
          <Button variant="outline" size="sm" disabled={page === 1} onClick={() => setPage(page - 1)}>Previous</Button>
          <Button variant="outline" size="sm" disabled={page >= totalPages} onClick={() => setPage(page + 1)}>Next</Button>
        </div>
      </div>

    </div>
  );
}
