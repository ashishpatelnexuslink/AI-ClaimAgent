import { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { Eye, EyeOff, Mail, Lock } from 'lucide-react';
import axios from 'axios';
import { useAuthContext } from '../../hooks/AuthContext';
import Button from '../../components/ui/Button';
import draudita_logo from '../../assets/draudita_logo.png';

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
    <div className="min-h-screen relative flex items-center justify-center px-4 py-10 overflow-hidden bg-[#0b1224]">
      {/* Aurora gradient orbs */}
      <div className="absolute -top-32 -left-32 w-[36rem] h-[36rem] rounded-full blur-3xl pointer-events-none opacity-60 bg-[radial-gradient(circle_at_center,#3b82f6_0%,transparent_60%)]" />
      <div className="absolute top-1/2 -right-40 w-[40rem] h-[40rem] rounded-full blur-3xl pointer-events-none opacity-50 bg-[radial-gradient(circle_at_center,#6366f1_0%,transparent_60%)]" />
      <div className="absolute -bottom-40 left-1/3 w-[32rem] h-[32rem] rounded-full blur-3xl pointer-events-none opacity-40 bg-[radial-gradient(circle_at_center,#06b6d4_0%,transparent_60%)]" />

      {/* Fine grid overlay */}
      <div
        className="absolute inset-0 opacity-[0.06] pointer-events-none"
        style={{
          backgroundImage:
            'linear-gradient(to right, white 1px, transparent 1px), linear-gradient(to bottom, white 1px, transparent 1px)',
          backgroundSize: '48px 48px',
          maskImage: 'radial-gradient(ellipse at center, black 40%, transparent 80%)',
          WebkitMaskImage: 'radial-gradient(ellipse at center, black 40%, transparent 80%)',
        }}
      />

      {/* Noise / vignette */}
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,transparent_0%,rgba(0,0,0,0.45)_100%)] pointer-events-none" />

      {/* Glass card */}
      <div className="relative z-10 w-full max-w-md">
        <div className="backdrop-blur-xl bg-white/10 border border-white/20 rounded-3xl shadow-2xl p-8 sm:p-10">
          <div className="flex justify-center mb-6">
            <img src={draudita_logo} alt="Draudita" className="h-20 w-auto object-contain" />
          </div>

          <div className="text-center mb-8">
            <h1 className="text-3xl font-bold text-white mb-2">Welcome back</h1>
            <p className="text-blue-100/80 text-sm">
              Sign in to your ClaimAI admin account
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-5">
            {state?.justRegistered && !error && (
              <div className="bg-green-500/15 border border-green-400/30 text-green-100 text-sm px-4 py-3 rounded-lg backdrop-blur-sm">
                Account created. Sign in to continue.
              </div>
            )}
            {error && (
              <div className="bg-red-500/15 border border-red-400/30 text-red-100 text-sm px-4 py-3 rounded-lg backdrop-blur-sm">
                {error}
              </div>
            )}

            <div>
              <label className="block text-sm font-medium text-blue-50 mb-1.5">Email address</label>
              <div className="relative">
                <Mail
                  size={18}
                  className="absolute left-3.5 top-1/2 -translate-y-1/2 text-blue-100/60 pointer-events-none"
                />
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full pl-11 pr-4 py-3 rounded-lg border border-white/20 bg-white/10 text-white placeholder-blue-100/50 text-sm backdrop-blur-sm focus:outline-none focus:ring-2 focus:ring-white/40 focus:border-white/40 transition"
                  placeholder="you@company.com"
                  required
                />
              </div>
            </div>

            <div>
              <div className="flex items-center justify-between mb-1.5">
                <label className="block text-sm font-medium text-blue-50">Password</label>
                <Link to="/forgot-password" className="text-xs text-blue-200 font-medium hover:text-white hover:underline">
                  Forgot password?
                </Link>
              </div>
              <div className="relative">
                <Lock
                  size={18}
                  className="absolute left-3.5 top-1/2 -translate-y-1/2 text-blue-100/60 pointer-events-none"
                />
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full pl-11 pr-11 py-3 rounded-lg border border-white/20 bg-white/10 text-white placeholder-blue-100/50 text-sm backdrop-blur-sm focus:outline-none focus:ring-2 focus:ring-white/40 focus:border-white/40 transition"
                  placeholder="Enter your password"
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-blue-100/60 hover:text-white"
                >
                  {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>

            <Button type="submit" loading={loading} className="w-full h-12" size="lg">
              Sign In
            </Button>
          </form>

          <p className="text-center text-sm text-blue-100/80 mt-8">
            New admin?{' '}
            <Link to="/register" className="text-white font-semibold hover:underline">
              Create an account
            </Link>
          </p>
        </div>

        <p className="text-center text-xs text-blue-100/50 mt-6">
          &copy; {new Date().getFullYear()} Draudita Insurance. All rights reserved.
        </p>
      </div>
    </div>
  );
}
