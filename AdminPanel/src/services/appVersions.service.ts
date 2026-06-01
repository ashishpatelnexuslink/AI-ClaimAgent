import api from './api';

export type AppPlatform = 'Android' | 'iOS' | 'Web' | 'BackendApi';

export interface AppVersion {
  id: string;
  platform: AppPlatform;
  versionName: string;
  versionCode: number;
  minSupportedVersionCode: number;
  isLatest: boolean;
  isMandatory: boolean;
  releaseNotes?: string | null;
  releaseDate: string;
  storeUrl?: string | null;
  createdAt: string;
  updatedAt?: string | null;
}

export interface CreateAppVersionPayload {
  platform: AppPlatform;
  versionName: string;
  versionCode: number;
  minSupportedVersionCode: number;
  isLatest: boolean;
  isMandatory: boolean;
  releaseNotes?: string | null;
  releaseDate?: string | null;
  storeUrl?: string | null;
}

export type UpdateAppVersionPayload = CreateAppVersionPayload;

interface ApiEnvelope<T> {
  success: boolean;
  data: T;
  message?: string;
  errors?: string[];
  statusCode: number;
}

const BASE = '/api/web/app-versions';

export const appVersionsService = {
  async getAll(platform?: AppPlatform): Promise<AppVersion[]> {
    const { data } = await api.get<ApiEnvelope<AppVersion[]>>(BASE, {
      params: platform ? { platform } : undefined,
    });
    return data.data ?? [];
  },

  async getById(id: string): Promise<AppVersion> {
    const { data } = await api.get<ApiEnvelope<AppVersion>>(`${BASE}/${id}`);
    return data.data;
  },

  async create(payload: CreateAppVersionPayload): Promise<AppVersion> {
    const { data } = await api.post<ApiEnvelope<AppVersion>>(BASE, payload);
    return data.data;
  },

  async update(id: string, payload: UpdateAppVersionPayload): Promise<AppVersion> {
    const { data } = await api.put<ApiEnvelope<AppVersion>>(`${BASE}/${id}`, payload);
    return data.data;
  },

  async remove(id: string): Promise<void> {
    await api.delete(`${BASE}/${id}`);
  },
};
