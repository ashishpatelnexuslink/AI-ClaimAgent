import { useState } from 'react';
import { Plus, Edit, Trash2 } from 'lucide-react';
import axios from 'axios';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import Button from '../../components/ui/Button';
import Badge from '../../components/ui/Badge';
import Modal from '../../components/ui/Modal';
import Spinner from '../../components/ui/Spinner';
import { useToastContext } from '../../hooks/ToastContext';
import {
  adminUsersService,
  type CreateAdminUserPayload,
  type UpdateAdminUserPayload,
} from '../../services/adminUsers.service';
import {
  appVersionsService,
  type AppPlatform,
  type AppVersion,
  type CreateAppVersionPayload,
} from '../../services/appVersions.service';
import type { AdminUser } from '../../types';

const tabs = ['General', 'API Configuration', 'Notifications', 'Admin Users', 'App Versions'] as const;

const APP_PLATFORMS: AppPlatform[] = ['Android', 'iOS', 'Web', 'BackendApi'];

const ADMIN_ROLES: AdminUser['role'][] = ['Super Admin', 'Reviewer', 'Viewer'];
const ADMIN_STATUSES: AdminUser['status'][] = ['Active', 'Suspended'];

function extractApiError(err: unknown, fallback: string): string {
  if (axios.isAxiosError(err)) {
    const data = err.response?.data as { errors?: string[]; message?: string } | undefined;
    if (data?.errors && data.errors.length > 0) return data.errors.join(' ');
    if (data?.message) return data.message;
  }
  return fallback;
}

export default function SettingsPage() {
  const [activeTab, setActiveTab] = useState<typeof tabs[number]>('General');
  const { addToast } = useToastContext();

  return (
    <div className="space-y-5">
      <h2 className="text-lg font-semibold text-secondary">Settings</h2>

      {/* Tabs */}
      <div className="bg-card rounded-xl shadow-sm">
        <div className="flex border-b border-gray-100">
          {tabs.map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`px-5 py-3 text-sm font-medium transition-colors relative ${
                activeTab === tab
                  ? 'text-primary'
                  : 'text-gray-500 hover:text-gray-700'
              }`}
            >
              {tab}
              {activeTab === tab && (
                <span className="absolute bottom-0 left-0 right-0 h-0.5 bg-primary rounded-t" />
              )}
            </button>
          ))}
        </div>

        <div className="p-6">
          {activeTab === 'General' && <GeneralTab onSave={() => addToast('Settings saved', 'success')} />}
          {activeTab === 'API Configuration' && <APITab onSave={() => addToast('API settings saved', 'success')} />}
          {activeTab === 'Notifications' && <NotificationsTab onSave={() => addToast('Notification settings saved', 'success')} />}
          {activeTab === 'Admin Users' && <AdminUsersTab />}
          {activeTab === 'App Versions' && <AppVersionsTab />}
        </div>
      </div>
    </div>
  );
}

function GeneralTab({ onSave }: { onSave: () => void }) {
  return (
    <div className="space-y-5 max-w-xl">
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">App Name</label>
        <input type="text" defaultValue="ClaimAI Admin" className="w-full px-4 py-2.5 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30" />
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Logo</label>
        <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center text-sm text-gray-500">
          Drop logo here or <button className="text-primary underline">browse</button>
        </div>
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Timezone</label>
        <select className="w-full px-4 py-2.5 text-sm border border-gray-300 rounded-lg">
          <option>Asia/Kolkata (IST)</option>
          <option>America/New_York (EST)</option>
          <option>Europe/London (GMT)</option>
          <option>Asia/Tokyo (JST)</option>
        </select>
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Default Language</label>
        <select className="w-full px-4 py-2.5 text-sm border border-gray-300 rounded-lg">
          <option>English</option>
          <option>Hindi</option>
          <option>Spanish</option>
        </select>
      </div>
      <Button onClick={onSave}>Save Changes</Button>
    </div>
  );
}

function APITab({ onSave }: { onSave: () => void }) {
  const { addToast } = useToastContext();
  const [testing, setTesting] = useState(false);

  const handleTest = () => {
    setTesting(true);
    setTimeout(() => {
      setTesting(false);
      addToast('Connection successful', 'success');
    }, 1500);
  };

  return (
    <div className="space-y-5 max-w-xl">
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Chatbot API Base URL</label>
        <input type="url" defaultValue="http://localhost:8000" className="w-full px-4 py-2.5 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30" />
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Username</label>
        <input type="text" defaultValue="admin" className="w-full px-4 py-2.5 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30" />
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Password</label>
        <input type="password" defaultValue="password" className="w-full px-4 py-2.5 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30" />
      </div>
      <div className="flex gap-3">
        <Button variant="outline" onClick={handleTest} loading={testing}>Test Connection</Button>
        <Button onClick={onSave}>Save</Button>
      </div>
    </div>
  );
}

function NotificationsTab({ onSave }: { onSave: () => void }) {
  const [settings, setSettings] = useState({
    newClaim: true,
    statusChanged: true,
    newUser: false,
    abandoned: true,
  });

  const toggle = (key: keyof typeof settings) => {
    setSettings((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  return (
    <div className="space-y-5 max-w-xl">
      <ToggleRow label="New claim submitted" checked={settings.newClaim} onChange={() => toggle('newClaim')} />
      <ToggleRow label="Claim status changed" checked={settings.statusChanged} onChange={() => toggle('statusChanged')} />
      <ToggleRow label="New user registered" checked={settings.newUser} onChange={() => toggle('newUser')} />
      <ToggleRow label="Conversation abandoned" checked={settings.abandoned} onChange={() => toggle('abandoned')} />
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">Notification Email</label>
        <input type="email" defaultValue="admin@claimai.com" className="w-full px-4 py-2.5 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30" />
      </div>
      <Button onClick={onSave}>Save Changes</Button>
    </div>
  );
}

function ToggleRow({ label, checked, onChange }: { label: string; checked: boolean; onChange: () => void }) {
  return (
    <div className="flex items-center justify-between py-2">
      <span className="text-sm text-gray-700">{label}</span>
      <button
        onClick={onChange}
        className={`w-11 h-6 rounded-full relative transition-colors ${checked ? 'bg-primary' : 'bg-gray-300'}`}
      >
        <span className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform ${checked ? 'left-[22px]' : 'left-0.5'}`} />
      </button>
    </div>
  );
}

function AdminUsersTab() {
  const { addToast } = useToastContext();
  const queryClient = useQueryClient();

  const { data: admins, isLoading, isError } = useQuery({
    queryKey: ['admin-users'],
    queryFn: adminUsersService.getAll,
  });

  const [showAddModal, setShowAddModal] = useState(false);
  const [editing, setEditing] = useState<AdminUser | null>(null);
  const [deleting, setDeleting] = useState<AdminUser | null>(null);

  const createMutation = useMutation({
    mutationFn: (payload: CreateAdminUserPayload) => adminUsersService.create(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-users'] });
      addToast('Admin created successfully', 'success');
      setShowAddModal(false);
    },
    onError: (err) => addToast(extractApiError(err, 'Failed to create admin'), 'error'),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: UpdateAdminUserPayload }) =>
      adminUsersService.update(id, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-users'] });
      addToast('Admin updated successfully', 'success');
      setEditing(null);
    },
    onError: (err) => addToast(extractApiError(err, 'Failed to update admin'), 'error'),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => adminUsersService.remove(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-users'] });
      addToast('Admin deleted successfully', 'success');
      setDeleting(null);
    },
    onError: (err) => addToast(extractApiError(err, 'Failed to delete admin'), 'error'),
  });

  return (
    <div className="space-y-4">
      <div className="flex justify-end">
        <Button size="sm" onClick={() => setShowAddModal(true)}>
          <Plus size={16} /> Add New Admin
        </Button>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center py-12"><Spinner size="md" /></div>
      ) : isError ? (
        <div className="text-center py-12 text-sm text-danger">Failed to load admin users.</div>
      ) : (
        <table className="w-full">
          <thead>
            <tr className="border-b border-gray-100">
              <th className="px-4 py-2 text-left text-xs font-semibold text-gray-500 uppercase">Name</th>
              <th className="px-4 py-2 text-left text-xs font-semibold text-gray-500 uppercase">Email</th>
              <th className="px-4 py-2 text-left text-xs font-semibold text-gray-500 uppercase">Role</th>
              <th className="px-4 py-2 text-left text-xs font-semibold text-gray-500 uppercase">Status</th>
              <th className="px-4 py-2 text-left text-xs font-semibold text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody>
            {(admins ?? []).map((admin) => (
              <tr key={admin.id} className="border-b border-gray-50">
                <td className="px-4 py-3 text-sm font-medium text-gray-800">{admin.name || '—'}</td>
                <td className="px-4 py-3 text-sm text-gray-600">{admin.email}</td>
                <td className="px-4 py-3 text-sm text-gray-600">{admin.role}</td>
                <td className="px-4 py-3"><Badge status={admin.status} /></td>
                <td className="px-4 py-3">
                  <div className="flex gap-1">
                    <button
                      className="p-1.5 text-gray-400 hover:text-primary hover:bg-gray-100 rounded-lg"
                      onClick={() => setEditing(admin)}
                    >
                      <Edit size={14} />
                    </button>
                    <button
                      className="p-1.5 text-gray-400 hover:text-danger hover:bg-red-50 rounded-lg"
                      onClick={() => setDeleting(admin)}
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
            {(admins ?? []).length === 0 && (
              <tr>
                <td colSpan={5} className="text-center py-12 text-sm text-gray-400">No admin users yet.</td>
              </tr>
            )}
          </tbody>
        </table>
      )}

      {showAddModal && (
        <AdminUserFormModal
          mode="create"
          onClose={() => setShowAddModal(false)}
          onSubmit={(payload) => createMutation.mutate(payload as CreateAdminUserPayload)}
          submitting={createMutation.isPending}
        />
      )}

      {editing && (
        <AdminUserFormModal
          mode="edit"
          initial={editing}
          onClose={() => setEditing(null)}
          onSubmit={(payload) =>
            updateMutation.mutate({ id: editing.id, payload: payload as UpdateAdminUserPayload })
          }
          submitting={updateMutation.isPending}
        />
      )}

      {deleting && (
        <Modal
          isOpen={!!deleting}
          onClose={() => setDeleting(null)}
          title="Delete Admin"
          footer={
            <>
              <Button variant="outline" onClick={() => setDeleting(null)}>Cancel</Button>
              <Button
                variant="danger"
                loading={deleteMutation.isPending}
                onClick={() => deleteMutation.mutate(deleting.id)}
              >
                Delete
              </Button>
            </>
          }
        >
          <p className="text-sm text-gray-600">
            Are you sure you want to delete <strong>{deleting.name || deleting.email}</strong>? This action cannot be undone.
          </p>
        </Modal>
      )}
    </div>
  );
}

interface AdminUserFormModalProps {
  mode: 'create' | 'edit';
  initial?: AdminUser;
  onClose: () => void;
  onSubmit: (payload: CreateAdminUserPayload | UpdateAdminUserPayload) => void;
  submitting: boolean;
}

function AdminUserFormModal({ mode, initial, onClose, onSubmit, submitting }: AdminUserFormModalProps) {
  const [name, setName] = useState(initial?.name ?? '');
  const [email, setEmail] = useState(initial?.email ?? '');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState<AdminUser['role']>(initial?.role ?? 'Viewer');
  const [status, setStatus] = useState<AdminUser['status']>(initial?.status ?? 'Active');

  const handleSubmit = () => {
    if (mode === 'create') {
      onSubmit({ name: name.trim(), email: email.trim(), password, role });
    } else {
      onSubmit({ name: name.trim(), role, status });
    }
  };

  return (
    <Modal
      isOpen
      onClose={onClose}
      title={mode === 'create' ? 'Add New Admin' : 'Edit Admin'}
      footer={
        <>
          <Button variant="outline" onClick={onClose}>Cancel</Button>
          <Button onClick={handleSubmit} loading={submitting}>
            {mode === 'create' ? 'Create Admin' : 'Save Changes'}
          </Button>
        </>
      }
    >
      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="w-full px-4 py-2.5 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30"
            placeholder="Full name"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            disabled={mode === 'edit'}
            className="w-full px-4 py-2.5 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30 disabled:bg-gray-50 disabled:text-gray-500"
            placeholder="Email address"
          />
        </div>
        {mode === 'create' && (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-2.5 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/30"
              placeholder="At least 8 chars, 1 upper, 1 lower, 1 digit, 1 special"
            />
          </div>
        )}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Role</label>
          <select
            value={role}
            onChange={(e) => setRole(e.target.value as AdminUser['role'])}
            className="w-full px-4 py-2.5 text-sm border border-gray-300 rounded-lg"
          >
            {ADMIN_ROLES.map((r) => <option key={r} value={r}>{r}</option>)}
          </select>
        </div>
        {mode === 'edit' && (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Status</label>
            <select
              value={status}
              onChange={(e) => setStatus(e.target.value as AdminUser['status'])}
              className="w-full px-4 py-2.5 text-sm border border-gray-300 rounded-lg"
            >
              {ADMIN_STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
            </select>
          </div>
        )}
      </div>
    </Modal>
  );
}

function AppVersionsTab() {
  const { addToast } = useToastContext();
  const queryClient = useQueryClient();

  const [platformFilter, setPlatformFilter] = useState<AppPlatform | ''>('');
  const [showAddModal, setShowAddModal] = useState(false);
  const [editing, setEditing] = useState<AppVersion | null>(null);
  const [deleting, setDeleting] = useState<AppVersion | null>(null);

  const { data: versions, isLoading, isError } = useQuery({
    queryKey: ['app-versions', platformFilter || 'all'],
    queryFn: () => appVersionsService.getAll(platformFilter || undefined),
  });

  const createMutation = useMutation({
    mutationFn: (payload: CreateAppVersionPayload) => appVersionsService.create(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['app-versions'] });
      addToast('App version created', 'success');
      setShowAddModal(false);
    },
    onError: (err) => addToast(extractApiError(err, 'Failed to create version'), 'error'),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: CreateAppVersionPayload }) =>
      appVersionsService.update(id, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['app-versions'] });
      addToast('App version updated', 'success');
      setEditing(null);
    },
    onError: (err) => addToast(extractApiError(err, 'Failed to update version'), 'error'),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => appVersionsService.remove(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['app-versions'] });
      addToast('App version deleted', 'success');
      setDeleting(null);
    },
    onError: (err) => addToast(extractApiError(err, 'Failed to delete version'), 'error'),
  });

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <select
          value={platformFilter}
          onChange={(e) => setPlatformFilter(e.target.value as AppPlatform | '')}
          className="px-3 py-2 text-sm border border-gray-300 rounded-lg"
        >
          <option value="">All platforms</option>
          {APP_PLATFORMS.map((p) => <option key={p} value={p}>{p}</option>)}
        </select>
        <Button size="sm" onClick={() => setShowAddModal(true)}>
          <Plus size={16} /> Add Version
        </Button>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center py-12"><Spinner size="md" /></div>
      ) : isError ? (
        <div className="text-center py-12 text-sm text-danger">Failed to load app versions.</div>
      ) : (
        <table className="w-full">
          <thead>
            <tr className="border-b border-gray-100">
              <th className="px-4 py-2 text-left text-xs font-semibold text-gray-500 uppercase">Platform</th>
              <th className="px-4 py-2 text-left text-xs font-semibold text-gray-500 uppercase">Version</th>
              <th className="px-4 py-2 text-left text-xs font-semibold text-gray-500 uppercase">Code</th>
              <th className="px-4 py-2 text-left text-xs font-semibold text-gray-500 uppercase">Min Code</th>
              <th className="px-4 py-2 text-left text-xs font-semibold text-gray-500 uppercase">Flags</th>
              <th className="px-4 py-2 text-left text-xs font-semibold text-gray-500 uppercase">Released</th>
              <th className="px-4 py-2 text-left text-xs font-semibold text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody>
            {(versions ?? []).map((v) => (
              <tr key={v.id} className="border-b border-gray-50">
                <td className="px-4 py-3 text-sm font-medium text-gray-800">{v.platform}</td>
                <td className="px-4 py-3 text-sm text-gray-600">{v.versionName}</td>
                <td className="px-4 py-3 text-sm text-gray-600">{v.versionCode}</td>
                <td className="px-4 py-3 text-sm text-gray-600">{v.minSupportedVersionCode}</td>
                <td className="px-4 py-3 text-sm text-gray-600">
                  <div className="flex gap-1 flex-wrap">
                    {v.isLatest && <span className="px-2 py-0.5 text-xs rounded bg-green-100 text-green-700">Latest</span>}
                    {v.isMandatory && <span className="px-2 py-0.5 text-xs rounded bg-red-100 text-red-700">Mandatory</span>}
                  </div>
                </td>
                <td className="px-4 py-3 text-sm text-gray-600">
                  {new Date(v.releaseDate).toLocaleDateString()}
                </td>
                <td className="px-4 py-3">
                  <div className="flex gap-1">
                    <button
                      className="p-1.5 text-gray-400 hover:text-primary hover:bg-gray-100 rounded-lg"
                      onClick={() => setEditing(v)}
                    >
                      <Edit size={14} />
                    </button>
                    <button
                      className="p-1.5 text-gray-400 hover:text-danger hover:bg-red-50 rounded-lg"
                      onClick={() => setDeleting(v)}
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
            {(versions ?? []).length === 0 && (
              <tr>
                <td colSpan={7} className="text-center py-12 text-sm text-gray-400">No app versions yet.</td>
              </tr>
            )}
          </tbody>
        </table>
      )}

      {showAddModal && (
        <AppVersionFormModal
          mode="create"
          onClose={() => setShowAddModal(false)}
          onSubmit={(payload) => createMutation.mutate(payload)}
          submitting={createMutation.isPending}
        />
      )}

      {editing && (
        <AppVersionFormModal
          mode="edit"
          initial={editing}
          onClose={() => setEditing(null)}
          onSubmit={(payload) => updateMutation.mutate({ id: editing.id, payload })}
          submitting={updateMutation.isPending}
        />
      )}

      {deleting && (
        <Modal
          isOpen={!!deleting}
          onClose={() => setDeleting(null)}
          title="Delete App Version"
          footer={
            <>
              <Button variant="outline" onClick={() => setDeleting(null)}>Cancel</Button>
              <Button
                variant="danger"
                loading={deleteMutation.isPending}
                onClick={() => deleteMutation.mutate(deleting.id)}
              >
                Delete
              </Button>
            </>
          }
        >
          <p className="text-sm text-gray-600">
            Delete <strong>{deleting.platform} {deleting.versionName}</strong>?
          </p>
        </Modal>
      )}
    </div>
  );
}

interface AppVersionFormModalProps {
  mode: 'create' | 'edit';
  initial?: AppVersion;
  onClose: () => void;
  onSubmit: (payload: CreateAppVersionPayload) => void;
  submitting: boolean;
}

function AppVersionFormModal({ mode, initial, onClose, onSubmit, submitting }: AppVersionFormModalProps) {
  const [platform, setPlatform] = useState<AppPlatform>(initial?.platform ?? 'Android');
  const [versionName, setVersionName] = useState(initial?.versionName ?? '');
  const [versionCode, setVersionCode] = useState<number>(initial?.versionCode ?? 1);
  const [minSupportedVersionCode, setMinSupportedVersionCode] = useState<number>(
    initial?.minSupportedVersionCode ?? 1,
  );
  const [isLatest, setIsLatest] = useState(initial?.isLatest ?? false);
  const [isMandatory, setIsMandatory] = useState(initial?.isMandatory ?? false);
  const [releaseNotes, setReleaseNotes] = useState(initial?.releaseNotes ?? '');
  const [storeUrl, setStoreUrl] = useState(initial?.storeUrl ?? '');
  const [releaseDate, setReleaseDate] = useState(
    initial?.releaseDate ? initial.releaseDate.slice(0, 10) : new Date().toISOString().slice(0, 10),
  );

  const handleSubmit = () => {
    onSubmit({
      platform,
      versionName: versionName.trim(),
      versionCode: Number(versionCode),
      minSupportedVersionCode: Number(minSupportedVersionCode),
      isLatest,
      isMandatory,
      releaseNotes: releaseNotes.trim() || null,
      storeUrl: storeUrl.trim() || null,
      releaseDate: new Date(releaseDate).toISOString(),
    });
  };

  return (
    <Modal
      isOpen
      onClose={onClose}
      title={mode === 'create' ? 'Add App Version' : 'Edit App Version'}
      footer={
        <>
          <Button variant="outline" onClick={onClose}>Cancel</Button>
          <Button onClick={handleSubmit} loading={submitting}>
            {mode === 'create' ? 'Create' : 'Save'}
          </Button>
        </>
      }
    >
      <div className="space-y-4">
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Platform</label>
            <select
              value={platform}
              onChange={(e) => setPlatform(e.target.value as AppPlatform)}
              className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg"
            >
              {APP_PLATFORMS.map((p) => <option key={p} value={p}>{p}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Version Name</label>
            <input
              type="text"
              value={versionName}
              onChange={(e) => setVersionName(e.target.value)}
              placeholder="1.4.2"
              className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Version Code</label>
            <input
              type="number"
              value={versionCode}
              onChange={(e) => setVersionCode(Number(e.target.value))}
              className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Min Supported Code</label>
            <input
              type="number"
              value={minSupportedVersionCode}
              onChange={(e) => setMinSupportedVersionCode(Number(e.target.value))}
              className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Release Date</label>
            <input
              type="date"
              value={releaseDate}
              onChange={(e) => setReleaseDate(e.target.value)}
              className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Store URL</label>
            <input
              type="url"
              value={storeUrl ?? ''}
              onChange={(e) => setStoreUrl(e.target.value)}
              placeholder="https://play.google.com/..."
              className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg"
            />
          </div>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Release Notes</label>
          <textarea
            value={releaseNotes ?? ''}
            onChange={(e) => setReleaseNotes(e.target.value)}
            rows={4}
            className="w-full px-3 py-2 text-sm border border-gray-300 rounded-lg"
          />
        </div>
        <div className="flex gap-6">
          <label className="flex items-center gap-2 text-sm text-gray-700">
            <input type="checkbox" checked={isLatest} onChange={(e) => setIsLatest(e.target.checked)} />
            Mark as latest
          </label>
          <label className="flex items-center gap-2 text-sm text-gray-700">
            <input type="checkbox" checked={isMandatory} onChange={(e) => setIsMandatory(e.target.checked)} />
            Mandatory update
          </label>
        </div>
      </div>
    </Modal>
  );
}
