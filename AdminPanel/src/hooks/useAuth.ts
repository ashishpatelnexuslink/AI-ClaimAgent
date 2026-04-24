import { useState, useCallback } from 'react';
import { authService } from '../services/auth.service';

export function useAuth() {
  const [token, setToken] = useState<string | null>(
    () => localStorage.getItem('admin_token')
  );

  const isAuthenticated = !!token;

  const login = useCallback(async (email: string, password: string) => {
    const { accessToken } = await authService.login(email, password);
    localStorage.setItem('admin_token', accessToken);
    setToken(accessToken);
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem('admin_token');
    setToken(null);
  }, []);

  return { isAuthenticated, token, login, logout };
}
