import api from './api';
import type { User } from '../types';

interface ApiEnvelope<T> {
  success: boolean;
  data: T;
  message?: string;
  errors?: string[];
  statusCode: number;
}

interface MobileUserResponse {
  id: string;
  name: string;
  email: string;
  phone: string;
  country: string;
  avatarPersonality: string;
  memberSince: string;
  totalClaims: number;
  status: string;
  profileImage?: string | null;
}

const BASE = '/api/web/mobile-users';

function toUser(r: MobileUserResponse): User {
  return {
    id: r.id,
    name: r.name || r.email || r.phone || '—',
    email: r.email ?? '',
    phone: r.phone ?? '',
    country: r.country ?? '',
    avatarPersonality: (r.avatarPersonality as User['avatarPersonality']) || 'Professional',
    memberSince: r.memberSince,
    totalClaims: r.totalClaims,
    status: (r.status as User['status']) || 'Active',
    profileImage: r.profileImage ?? undefined,
  };
}

export const usersService = {
  async getAll(): Promise<User[]> {
    const { data } = await api.get<ApiEnvelope<MobileUserResponse[]>>(BASE);
    return (data.data ?? []).map(toUser);
  },

  async getById(id: string): Promise<User> {
    const { data } = await api.get<ApiEnvelope<MobileUserResponse>>(`${BASE}/${id}`);
    return toUser(data.data);
  },
};
