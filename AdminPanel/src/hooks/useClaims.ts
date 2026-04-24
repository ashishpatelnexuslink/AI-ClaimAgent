import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { claimsService } from '../services/claims.service';
import type { Claim } from '../types';

export function useClaims() {
  return useQuery({
    queryKey: ['claims'],
    queryFn: claimsService.getAll,
  });
}

export function useClaim(id: string) {
  return useQuery({
    queryKey: ['claims', id],
    queryFn: () => claimsService.getById(id),
    enabled: !!id,
  });
}

export function useClaimDocuments(id: string) {
  return useQuery({
    queryKey: ['claims', id, 'documents'],
    queryFn: () => claimsService.getDocuments(id),
    enabled: !!id,
  });
}

export function useDashboardStats() {
  return useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: claimsService.getDashboardStats,
  });
}

export function useClaimsTrend() {
  return useQuery({
    queryKey: ['claims-trend'],
    queryFn: claimsService.getClaimsTrend,
  });
}

export function useClaimsByType() {
  return useQuery({
    queryKey: ['claims-by-type'],
    queryFn: claimsService.getClaimsByType,
  });
}

export function useUpdateClaimStatus() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, status }: { id: string; status: Claim['status'] }) =>
      claimsService.updateStatus(id, status),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['claims'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
    },
  });
}

export function useDeleteClaim() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => claimsService.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['claims'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
    },
  });
}
