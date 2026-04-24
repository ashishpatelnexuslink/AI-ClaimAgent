import { BrowserRouter, Routes, Route, Navigate, Outlet } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider, useAuthContext } from './hooks/AuthContext';
import { ToastProvider } from './hooks/ToastContext';
import Layout from './components/layout/Layout';
import LoginPage from './pages/auth/LoginPage';
import RegisterPage from './pages/auth/RegisterPage';
import DashboardPage from './pages/dashboard/DashboardPage';
import ClaimsListPage from './pages/claims/ClaimsListPage';
import ClaimDetailPage from './pages/claims/ClaimDetailPage';
import UsersPage from './pages/users/UsersPage';
import UserDetailPage from './pages/users/UserDetailPage';
import ConversationsPage from './pages/conversations/ConversationsPage';
import ConversationDetailPage from './pages/conversations/ConversationDetailPage';
import SettingsPage from './pages/settings/SettingsPage';
import TemplatesListPage from './pages/templates/TemplatesListPage';
import TemplateFormPage from './pages/templates/TemplateFormPage';
import TemplateClonePage from './pages/templates/TemplateClonePage';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,
      retry: 1,
    },
  },
});

function PrivateRoute() {
  const { isAuthenticated } = useAuthContext();
  return isAuthenticated ? <Outlet /> : <Navigate to="/login" replace />;
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <AuthProvider>
          <ToastProvider>
            <Routes>
              <Route path="/login" element={<LoginPage />} />
              <Route path="/register" element={<RegisterPage />} />
              <Route element={<PrivateRoute />}>
                <Route element={<Layout />}>
                  <Route path="/dashboard" element={<DashboardPage />} />
                  <Route path="/claims" element={<ClaimsListPage />} />
                  <Route path="/claims/:id" element={<ClaimDetailPage />} />
                  <Route path="/users" element={<UsersPage />} />
                  <Route path="/users/:id" element={<UserDetailPage />} />
                  <Route path="/conversations" element={<ConversationsPage />} />
                  <Route path="/conversations/:id" element={<ConversationDetailPage />} />
                  <Route path="/templates" element={<TemplatesListPage />} />
                  <Route path="/templates/new" element={<TemplateFormPage mode="create" />} />
                  <Route path="/templates/:id" element={<Navigate to="edit" replace />} />
                  <Route path="/templates/:id/edit" element={<TemplateFormPage mode="edit" />} />
                  <Route path="/templates/:id/clone" element={<TemplateClonePage />} />
                  <Route path="/settings" element={<SettingsPage />} />
                  <Route path="/" element={<Navigate to="/dashboard" replace />} />
                </Route>
              </Route>
            </Routes>
          </ToastProvider>
        </AuthProvider>
      </BrowserRouter>
    </QueryClientProvider>
  );
}
