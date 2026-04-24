import { useQuery, useMutation, useQueryClient, keepPreviousData } from '@tanstack/react-query';
import { templatesService } from '../services/templates.service';
import type {
  InsuranceType,
  TemplateListQuery,
  CreateTemplatePayload,
  UpdateTemplatePayload,
} from '../types';

export function useTemplates(query: TemplateListQuery) {
  return useQuery({
    queryKey: ['templates', 'list', query],
    queryFn: () => templatesService.list(query),
    placeholderData: keepPreviousData,
  });
}

export function useTemplate(id: string | undefined) {
  return useQuery({
    queryKey: ['templates', 'detail', id],
    queryFn: () => templatesService.getById(id!),
    enabled: !!id,
  });
}

export function useActiveTemplate(companyName: string, insuranceType: InsuranceType | undefined) {
  return useQuery({
    queryKey: ['templates', 'active', companyName, insuranceType],
    queryFn: () => templatesService.getActive(companyName, insuranceType!),
    enabled: !!companyName && !!insuranceType,
  });
}

export function useCreateTemplate() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: CreateTemplatePayload) => templatesService.create(payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['templates'] });
    },
  });
}

export function useUpdateTemplate() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: UpdateTemplatePayload }) =>
      templatesService.update(id, payload),
    onSuccess: (_, { id }) => {
      qc.invalidateQueries({ queryKey: ['templates'] });
      qc.invalidateQueries({ queryKey: ['templates', 'detail', id] });
    },
  });
}

export function useCloneTemplate() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => templatesService.clone(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['templates'] });
    },
  });
}

export function useActivateTemplate() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => templatesService.activate(id),
    onSuccess: (_, id) => {
      qc.invalidateQueries({ queryKey: ['templates'] });
      qc.invalidateQueries({ queryKey: ['templates', 'detail', id] });
    },
  });
}

export function useDeleteTemplate() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => templatesService.remove(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['templates'] });
    },
  });
}
