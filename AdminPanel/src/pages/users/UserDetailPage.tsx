import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Ban, KeyRound, Trash2 } from 'lucide-react';
import { useQuery } from '@tanstack/react-query';
import { usersService } from '../../services/users.service';
import { claimsService } from '../../services/claims.service';
import { authService } from '../../services/auth.service';
import Badge from '../../components/ui/Badge';
import Button from '../../components/ui/Button';
import Avatar from '../../components/ui/Avatar';
import Spinner from '../../components/ui/Spinner';
import Modal from '../../components/ui/Modal';
import { useToastContext } from '../../hooks/ToastContext';
import { format } from 'date-fns';
import { useState } from 'react';

export default function UserDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { addToast } = useToastContext();
  const { data: user, isLoading } = useQuery({
    queryKey: ['users', id],
    queryFn: () => usersService.getById(id!),
    enabled: !!id,
  });
  const { data: allClaims } = useQuery({
    queryKey: ['claims'],
    queryFn: claimsService.getAll,
  });

  const [confirmDelete, setConfirmDelete] = useState(false);
  const [confirmReset, setConfirmReset] = useState(false);
  const [resetting, setResetting] = useState(false);

  const handleResetPassword = async () => {
    if (!user) return;
    setResetting(true);
    try {
      await authService.forgotPassword(user.email);
      addToast(`Password reset link sent to ${user.email}`, 'success');
      setConfirmReset(false);
    } catch {
      addToast('Failed to send password reset link', 'error');
    } finally {
      setResetting(false);
    }
  };

  const userClaims = allClaims?.filter((c) => c.userId === id) ?? [];
  const approvedCount = userClaims.filter((c) => c.status === 'Approved').length;
  const rejectedCount = userClaims.filter((c) => c.status === 'Rejected').length;
  const pendingCount = userClaims.filter((c) => c.status === 'Pending').length;

  if (isLoading) {
    return <div className="flex items-center justify-center h-96"><Spinner size="lg" /></div>;
  }

  if (!user) {
    return <div className="text-center py-12 text-gray-500">User not found</div>;
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <button onClick={() => navigate(-1)} className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
          <ArrowLeft size={20} className="text-gray-600" />
        </button>
        <h2 className="text-xl font-bold text-secondary">User Profile</h2>
      </div>

      {/* Profile Card */}
      <div className="bg-card rounded-2xl p-6 shadow-sm">
        <div className="flex items-start gap-6">
          <Avatar name={user.name} src={user.profileImage} size="lg" className="w-20 h-20 text-2xl" />
          <div className="flex-1">
            <div className="flex items-center gap-3">
              <h3 className="text-xl font-bold text-secondary">{user.name}</h3>
              <Badge status={user.status} />
            </div>
            <p className="text-sm text-gray-500 mt-1">Member since {format(new Date(user.memberSince), 'MMMM yyyy')}</p>
            <div className="grid grid-cols-2 gap-4 mt-4">
              <InfoItem label="Email" value={user.email} />
              <InfoItem label="Phone" value={user.phone} />
              <InfoItem label="Country" value={user.country} />
              <InfoItem label="Avatar Personality" value={user.avatarPersonality} />
            </div>
          </div>
          <div className="flex flex-col gap-2">
            <Button variant="outline" size="sm"><Ban size={14} /> {user.status === 'Active' ? 'Suspend' : 'Activate'}</Button>
            <Button variant="outline" size="sm" onClick={() => setConfirmReset(true)}><KeyRound size={14} /> Reset Password</Button>
            <Button variant="danger" size="sm" onClick={() => setConfirmDelete(true)}><Trash2 size={14} /> Delete</Button>
          </div>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4">
        <StatBox label="Total Claims" value={userClaims.length} color="bg-primary" />
        <StatBox label="Approved" value={approvedCount} color="bg-success" />
        <StatBox label="Rejected" value={rejectedCount} color="bg-danger" />
        <StatBox label="Pending" value={pendingCount} color="bg-warning" />
      </div>

      {/* Claims History */}
      <div className="bg-card rounded-2xl p-5 shadow-sm">
        <h3 className="text-base font-semibold text-secondary mb-4">Claims History</h3>
        {userClaims.length > 0 ? (
          <table className="w-full">
            <thead>
              <tr className="border-b border-gray-100">
                <th className="px-4 py-2 text-left text-xs font-semibold text-gray-500 uppercase">Claim #</th>
                <th className="px-4 py-2 text-left text-xs font-semibold text-gray-500 uppercase">Type</th>
                <th className="px-4 py-2 text-left text-xs font-semibold text-gray-500 uppercase">Date</th>
                <th className="px-4 py-2 text-left text-xs font-semibold text-gray-500 uppercase">Status</th>
                <th className="px-4 py-2 text-left text-xs font-semibold text-gray-500 uppercase">Amount</th>
              </tr>
            </thead>
            <tbody>
              {userClaims.map((claim) => (
                <tr
                  key={claim.id}
                  className="border-b border-gray-50 hover:bg-gray-50/50 cursor-pointer"
                  onClick={() => navigate(`/claims/${claim.id}`)}
                >
                  <td className="px-4 py-2.5 text-sm font-medium text-primary">{claim.claimNumber}</td>
                  <td className="px-4 py-2.5 text-sm text-gray-700">{claim.type}</td>
                  <td className="px-4 py-2.5 text-sm text-gray-500">{format(new Date(claim.submittedAt), 'dd MMM yyyy')}</td>
                  <td className="px-4 py-2.5"><Badge status={claim.status} /></td>
                  <td className="px-4 py-2.5 text-sm font-medium">{claim.amount ? `₹${claim.amount.toLocaleString('en-IN')}` : '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <p className="text-sm text-gray-400 text-center py-4">No claims found</p>
        )}
      </div>

      {/* Reset Password Confirmation */}
      <Modal
        isOpen={confirmReset}
        onClose={() => !resetting && setConfirmReset(false)}
        title="Reset Password"
        footer={
          <>
            <Button variant="outline" onClick={() => setConfirmReset(false)} disabled={resetting}>Cancel</Button>
            <Button variant="primary" onClick={handleResetPassword} disabled={resetting}>
              {resetting ? 'Sending...' : 'Send Reset Link'}
            </Button>
          </>
        }
      >
        <p className="text-sm text-gray-600">
          Send a password reset link to <strong>{user.email}</strong>?
        </p>
      </Modal>

      {/* Delete Confirmation */}
      <Modal
        isOpen={confirmDelete}
        onClose={() => setConfirmDelete(false)}
        title="Delete User"
        footer={
          <>
            <Button variant="outline" onClick={() => setConfirmDelete(false)}>Cancel</Button>
            <Button variant="danger" onClick={() => {
              setConfirmDelete(false);
              addToast('User deleted successfully', 'success');
              navigate('/users');
            }}>
              Delete User
            </Button>
          </>
        }
      >
        <p className="text-sm text-gray-600">
          Are you sure you want to delete <strong>{user.name}</strong>? This action cannot be undone and will remove all associated data.
        </p>
      </Modal>
    </div>
  );
}

function InfoItem({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-xs text-gray-500">{label}</p>
      <p className="text-sm font-medium text-gray-800">{value}</p>
    </div>
  );
}

function StatBox({ label, value, color }: { label: string; value: number; color: string }) {
  return (
    <div className="bg-card rounded-xl p-4 shadow-sm text-center">
      <p className="text-2xl font-bold text-secondary">{value}</p>
      <div className={`h-1 w-12 mx-auto rounded-full mt-2 mb-1 ${color}`} />
      <p className="text-xs text-gray-500">{label}</p>
    </div>
  );
}
