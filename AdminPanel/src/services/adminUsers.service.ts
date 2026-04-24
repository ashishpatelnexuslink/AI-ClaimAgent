import api from './api';
import type { AdminUser } from '../types';

export interface CreateAdminUserPayload {
  name: string;
  email: string;
  password: string;
  role: AdminUser['role'];
}

export interface UpdateAdminUserPayload {
  name: string;
  role: AdminUser['role'];
  status: AdminUser['status'];
}

interface ApiEnvelope<T> {
  success: boolean;
  data: T;
  message?: string;
  errors?: string[];
  statusCode: number;
}

const BASE = '/api/web/admin-users';

export const adminUsersService = {
  async getAll(): Promise<AdminUser[]> {
    const { data } = await api.get<ApiEnvelope<AdminUser[]>>(BASE);
    return data.data ?? [];
  },

  async create(payload: CreateAdminUserPayload): Promise<AdminUser> {
    const { data } = await api.post<ApiEnvelope<AdminUser>>(BASE, payload);
    return data.data;
  },

  async register(payload: CreateAdminUserPayload): Promise<AdminUser> {
    const { data } = await api.post<ApiEnvelope<AdminUser>>(`${BASE}/register`, payload);
    return data.data;
  },

  async update(id: string, payload: UpdateAdminUserPayload): Promise<AdminUser> {
    const { data } = await api.put<ApiEnvelope<AdminUser>>(`${BASE}/${id}`, payload);
    return data.data;
  },

  async remove(id: string): Promise<void> {
    await api.delete(`${BASE}/${id}`);
  },
};
