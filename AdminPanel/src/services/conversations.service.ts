import api from './api';
import type { Conversation } from '../types';
import { mockConversations } from '../mocks/mockData';

const USE_MOCK = import.meta.env.VITE_USE_MOCK === 'true';

export const conversationsService = {
  async getAll(): Promise<Conversation[]> {
    if (USE_MOCK) return mockConversations;
    const { data } = await api.get('/api/conversations');
    return data;
  },

  async getById(id: string): Promise<Conversation> {
    if (USE_MOCK) {
      const conv = mockConversations.find((c) => c.id === id);
      if (!conv) throw new Error('Conversation not found');
      return conv;
    }
    const { data } = await api.get(`/api/conversations/${id}`);
    return data;
  },
};
