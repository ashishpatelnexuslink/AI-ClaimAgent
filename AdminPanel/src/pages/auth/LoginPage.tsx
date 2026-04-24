import { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { Shield, Eye, EyeOff } from 'lucide-react';
import axios from 'axios';
import { useAuthContext } from '../../hooks/AuthContext';
import Button from '../../components/ui/Button';

interface LoginLocationState {
  justRegistered?: boolean;
  email?: string;
}

export default function LoginPage() {
  const location = useLocation();
  const state = (location.state as LoginLocationState | null) ?? null;
  const [email, setEmail] = useState(state?.email ?? '');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { login } = useAuthContext();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(email, password);
      navigate('/dashboard');
    } catch (err) {
      if (axios.isAxiosError(err)) {
        const data = err.response?.data as { errors?: string[]; message?: string } | undefined;
        if (data?.errors && data.errors.length > 0) setError(data.errors.join(' '));
        else if (data?.message) setError(data.message);
        else setError('Invalid email or password.');
      } else {
        setError('Invalid email or password.');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-secondary flex items-center justify-center px-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md p-8">
        <div className="flex items-center justify-center gap-3 mb-8">
          <div className="w-12 h-12 bg-primary rounded-xl flex items-center justify-center">
            <Shield size={28} className="text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-secondary">ClaimAI</h1>
            <p className="text-xs text-gray-500">Admin Panel</p>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="space-y-5">
          {state?.justRegistered && !error && (
            <div className="bg-green-50 text-green-700 text-sm px-4 py-3 rounded-lg">
              Account created. Sign in to continue.
            </div>
          )}
          {error && (
            <div className="bg-danger-light text-red-700 text-sm px-4 py-3 rounded-lg">
              {error}
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-3 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
              placeholder="you@claimai.com"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">Password</label>
            <div className="relative">
              <input
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-4 py-3 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary pr-11"
                placeholder="Enter your password"
                required
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
              >
                {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
          </div>

          <Button
            type="submit"
            loading={loading}
            className="w-full h-12"
            size="lg"
          >
            Sign In
          </Button>
        </form>

        <p className="text-center text-sm text-gray-500 mt-6">
          New admin?{' '}
          <Link to="/register" className="text-primary font-medium hover:underline">
            Sign up for a new admin account
          </Link>
        </p>
      </div>
    </div>
  );
}
