import api from './api';

interface ApiEnvelope<T> {
  success: boolean;
  data: T;
  message?: string;
  errors?: string[];
  statusCode: number;
}

interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  accessTokenExpiration: string;
  userId: string;
  email: string;
  fullName: string;
  roles: string[];
}

export const authService = {
  async login(email: string, password: string): Promise<AuthResponse> {
    const { data } = await api.post<ApiEnvelope<AuthResponse>>(
      '/api/web/Auth/login',
      { email, password }
    );
    return data.data;
  },
};
