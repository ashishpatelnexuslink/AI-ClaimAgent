import { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { Eye, EyeOff } from 'lucide-react';
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
  const [rememberMe, setRememberMe] = useState(false);
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
    <div className="min-h-screen flex bg-white">
      {/* Left: form */}
      <div className="flex-1 flex flex-col px-6 sm:px-10 lg:px-20 py-10">
        <div className="flex-1 flex items-center justify-center">
          <div className="w-full max-w-sm">
            <img src={draudita_logo} alt="Draudita" className="h-20 w-auto object-contain mb-6" />
            <h1 className="text-3xl font-bold text-slate-900 mb-2">Log in</h1>
            <p className="text-sm text-slate-500 mb-8">Welcome back! Please enter your details.</p>

            <form onSubmit={handleSubmit} className="space-y-5">
              {state?.justRegistered && !error && (
                <div className="bg-green-50 border border-green-200 text-green-700 text-sm px-4 py-3 rounded-lg">
                  Account created. Sign in to continue.
                </div>
              )}
              {error && (
                <div className="bg-red-50 border border-red-200 text-red-700 text-sm px-4 py-3 rounded-lg">
                  {error}
                </div>
              )}

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1.5">
                  Email <span className="text-red-500">*</span>
                </label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full px-3.5 py-2.5 rounded-lg border border-slate-300 text-slate-900 placeholder-slate-400 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/30 focus:border-blue-500 transition"
                  placeholder="you@draudita.com"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1.5">
                  Password <span className="text-red-500">*</span>
                </label>
                <div className="relative">
                  <input
                    type={showPassword ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="w-full px-3.5 pr-11 py-2.5 rounded-lg border border-slate-300 text-slate-900 placeholder-slate-400 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/30 focus:border-blue-500 transition"
                    placeholder="Enter your password"
                    required
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-700"
                  >
                    {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                  </button>
                </div>
              </div>

              <div className="flex items-center justify-between">
                <label className="flex items-center gap-2 text-sm text-slate-600 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={rememberMe}
                    onChange={(e) => setRememberMe(e.target.checked)}
                    className="h-4 w-4 rounded border-slate-300 text-blue-600 focus:ring-blue-500"
                  />
                  Remember me
                </label>
                <Link to="/forgot-password" className="text-sm font-medium text-blue-600 hover:text-blue-700">
                  Forgot password?
                </Link>
              </div>

              <Button type="submit" loading={loading} className="w-full h-11" size="lg">
                Sign in
              </Button>
            </form>

            <p className="text-center text-sm text-slate-600 mt-8">
              Don&apos;t have an account?{' '}
              <Link to="/register" className="text-blue-600 font-medium hover:text-blue-700">
                Sign up
              </Link>
            </p>
          </div>
        </div>

        <p className="text-xs text-slate-400 text-center">
          &copy; {new Date().getFullYear()} Draudita Insurance. All rights reserved.
        </p>
      </div>

      {/* Right: hero panel */}
      <div className="hidden lg:flex flex-1 relative overflow-hidden bg-[#1e3a8a]">
        {/* Decorative blobs */}
        <div className="absolute -top-32 -left-24 w-[28rem] h-[28rem] rounded-full opacity-20 bg-[radial-gradient(circle_at_center,#60a5fa_0%,transparent_60%)]" />
        <div className="absolute -bottom-32 -right-24 w-[32rem] h-[32rem] rounded-full opacity-25 bg-[radial-gradient(circle_at_center,#93c5fd_0%,transparent_60%)]" />
        <div className="absolute top-1/3 right-1/4 w-72 h-72 rounded-full opacity-10 bg-[radial-gradient(circle_at_center,white_0%,transparent_60%)]" />

        <div className="relative z-10 flex flex-col w-full px-12 xl:px-20 py-16">
          <div className="flex flex-col items-center text-center max-w-lg mx-auto">
            <img src={draudita_logo} alt="Draudita" className="h-12 w-auto object-contain mb-6 brightness-0 invert" />
            <h2 className="text-3xl xl:text-4xl font-bold text-white mb-4">Welcome to ClaimAI</h2>
            <p className="text-blue-100/90 text-sm xl:text-base leading-relaxed">
              AI-powered claim management at your fingertips. Streamline intake, accelerate
              reviews, and deliver a smarter experience for every claimant.
            </p>
          </div>

          {/* Sample chat preview */}
          <div className="mt-auto">
            <div className="flex items-start gap-3 mb-3">
              <div className="h-9 w-9 rounded-full bg-white/15 backdrop-blur flex items-center justify-center flex-shrink-0">
                <img src={draudita_logo} alt="" className="h-5 w-5 object-contain brightness-0 invert" />
              </div>
              <div className="max-w-md">
                <p className="text-xs text-white/70 mb-1">ClaimAI Assistant</p>
                <div className="bg-white text-slate-800 text-sm rounded-2xl rounded-tl-sm px-4 py-3 shadow-lg">
                  Hi, I&apos;m your ClaimAI assistant. I can help you file a new claim, upload
                  documents, or check the status of an existing claim. How can I help today?
                </div>
              </div>
            </div>
            <div className="flex justify-end">
              <div className="max-w-sm">
                <p className="text-xs text-white/70 mb-1 text-right">You</p>
                <div className="bg-blue-500 text-white text-sm rounded-2xl rounded-tr-sm px-4 py-3 shadow-lg">
                  Let&apos;s start a new auto claim.
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
