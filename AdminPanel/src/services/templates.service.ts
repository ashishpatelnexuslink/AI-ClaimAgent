import api from './api';
import type {
  Template,
  TemplateListItem,
  TemplateListQuery,
  PagedResult,
  CreateTemplatePayload,
  UpdateTemplatePayload,
  InsuranceType,
} from '../types';

interface ApiEnvelope<T> {
  success: boolean;
  data: T;
  message?: string;
  errors?: string[];
  statusCode: number;
}

const BASE = '/api/web/templates';

function cleanQuery(q: TemplateListQuery): Record<string, string | number> {
  const out: Record<string, string | number> = {};
  if (q.companyName) out.companyName = q.companyName;
  if (q.insuranceType) out.insuranceType = q.insuranceType;
  if (q.status) out.status = q.status;
  out.pageNumber = q.pageNumber ?? 1;
  out.pageSize = q.pageSize ?? 20;
  return out;
}

export const templatesService = {
  async list(query: TemplateListQuery): Promise<PagedResult<TemplateListItem>> {
    const { data } = await api.get<ApiEnvelope<PagedResult<TemplateListItem>>>(BASE, {
      params: cleanQuery(query),
    });
    return data.data;
  },

  async getById(id: string): Promise<Template> {
    const { data } = await api.get<ApiEnvelope<Template>>(`${BASE}/${id}`);
    return data.data;
  },

  async getActive(companyName: string, insuranceType: InsuranceType): Promise<Template> {
    const { data } = await api.get<ApiEnvelope<Template>>(`${BASE}/active`, {
      params: { company: companyName, type: insuranceType },
    });
    return data.data;
  },

  async create(payload: CreateTemplatePayload): Promise<Template> {
    const { data } = await api.post<ApiEnvelope<Template>>(BASE, payload);
    return data.data;
  },

  async update(id: string, payload: UpdateTemplatePayload): Promise<Template> {
    const { data } = await api.put<ApiEnvelope<Template>>(`${BASE}/${id}`, payload);
    return data.data;
  },

  async clone(id: string): Promise<Template> {
    const { data } = await api.post<ApiEnvelope<Template>>(`${BASE}/${id}/clone`);
    return data.data;
  },

  async activate(id: string): Promise<Template> {
    const { data } = await api.post<ApiEnvelope<Template>>(`${BASE}/${id}/activate`);
    return data.data;
  },

  async remove(id: string): Promise<void> {
    await api.delete(`${BASE}/${id}`);
  },
};
