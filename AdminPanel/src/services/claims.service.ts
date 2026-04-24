import api from './api';
import type {
  Claim,
  ClaimDocument,
  ClaimsByTypeItem,
  ClaimsTrendData,
  DashboardStats,
  PagedResult,
} from '../types';
import { mockClaims, mockClaimsTrend, mockDashboardStats } from '../mocks/mockData';

const USE_MOCK = import.meta.env.VITE_USE_MOCK === 'true';

interface AdminClaimListItemDto {
  id: string;
  claimNumber: string;
  userId: string;
  userName: string;
  type: string;
  status: string;
  vehicleReg?: string | null;
  incidentDate?: string | null;
  submittedAt: string;
  updatedAt?: string | null;
  amount?: number | null;
  assignedTo?: string | null;
  claimantType?: string | null;
}

function toClaim(row: AdminClaimListItemDto): Claim {
  return {
    id: row.id,
    claimNumber: row.claimNumber,
    userId: row.userId,
    userName: row.userName || '—',
    type: row.type || '—',
    status: (row.status as Claim['status']) ?? 'Pending',
    vehicleReg: row.vehicleReg ?? '',
    incidentDate: row.incidentDate ?? row.submittedAt,
    submittedAt: row.submittedAt,
    updatedAt: row.updatedAt ?? row.submittedAt,
    amount: row.amount ?? undefined,
    assignedTo: row.assignedTo ?? undefined,
    claimantType: row.claimantType ?? undefined,
  };
}

function unwrap<T>(payload: unknown): T {
  // Backend wraps every response in ApiResponse<T> → { success, data, errors, statusCode }.
  const envelope = payload as { data?: T } | T;
  if (envelope && typeof envelope === 'object' && 'data' in envelope) {
    return (envelope as { data: T }).data;
  }
  return envelope as T;
}

export const claimsService = {
  async getAll(): Promise<Claim[]> {
    if (USE_MOCK) return mockClaims as unknown as Claim[];
    const { data } = await api.get('/api/web/claims', {
      params: { pageNumber: 1, pageSize: 200 },
    });
    const paged = unwrap<PagedResult<AdminClaimListItemDto>>(data);
    return (paged?.items ?? []).map(toClaim);
  },

  async getById(id: string): Promise<Claim> {
    if (USE_MOCK) {
      const claim = (mockClaims as unknown as Claim[]).find((c) => c.id === id);
      if (!claim) throw new Error('Claim not found');
      return claim;
    }
    const { data } = await api.get(`/api/web/claims/${id}`);
    const row = unwrap<AdminClaimListItemDto>(data);
    return toClaim(row);
  },

  async updateStatus(id: string, status: Claim['status']): Promise<Claim> {
    if (USE_MOCK) {
      const claim = (mockClaims as unknown as Claim[]).find((c) => c.id === id);
      if (!claim) throw new Error('Claim not found');
      return { ...claim, status };
    }
    await api.patch(`/api/web/claims/${id}/status`, { status });
    return claimsService.getById(id);
  },

  async delete(id: string): Promise<void> {
    if (USE_MOCK) return;
    await api.delete(`/api/web/claims/${id}`);
  },

  async getDocuments(claimId: string): Promise<ClaimDocument[]> {
    if (USE_MOCK) return [];
    const { data } = await api.get(`/api/web/claims/${claimId}/documents`);
    return unwrap<ClaimDocument[]>(data) ?? [];
  },

  async getDashboardStats(): Promise<DashboardStats> {
    if (USE_MOCK) return mockDashboardStats;
    const { data } = await api.get('/api/web/dashboard/stats');
    return unwrap<DashboardStats>(data);
  },

  async getClaimsTrend(): Promise<ClaimsTrendData[]> {
    if (USE_MOCK) return mockClaimsTrend;
    const { data } = await api.get('/api/web/dashboard/claims-trend');
    return unwrap<ClaimsTrendData[]>(data);
  },

  async getClaimsByType(): Promise<ClaimsByTypeItem[]> {
    if (USE_MOCK) {
      const counts = new Map<string, number>();
      for (const c of mockClaims as unknown as Claim[]) {
        counts.set(c.type, (counts.get(c.type) ?? 0) + 1);
      }
      return Array.from(counts, ([type, count]) => ({ type, count }));
    }
    const { data } = await api.get('/api/web/dashboard/claims-by-type');
    return unwrap<ClaimsByTypeItem[]>(data);
  },
};
