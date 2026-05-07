import { useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { ArrowLeft, UserCircle, X } from 'lucide-react';
import { useClaim, useClaimDocuments } from '../../hooks/useClaims';
import { useQuery } from '@tanstack/react-query';
import { usersService } from '../../services/users.service';
import Badge from '../../components/ui/Badge';
import Avatar from '../../components/ui/Avatar';
import Spinner from '../../components/ui/Spinner';
import { format } from 'date-fns';

export default function ClaimDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { data: claim, isLoading } = useClaim(id!);
  const { data: documents = [] } = useClaimDocuments(id!);
  const [preview, setPreview] = useState<{ url: string; name: string } | null>(null);
  const { data: user } = useQuery({
    queryKey: ['users', claim?.userId],
    queryFn: () => usersService.getById(claim!.userId),
    enabled: !!claim?.userId,
  });

  const mockTimeline = [
    { id: '1', date: claim?.submittedAt ?? '', action: `Claim Submitted by ${claim?.userName}`, actor: claim?.userName ?? '' },
    { id: '2', date: claim?.updatedAt ?? '', action: `Status changed to ${claim?.status}`, actor: 'Admin' },
  ];

  if (isLoading) {
    return <div className="flex items-center justify-center h-96"><Spinner size="lg" /></div>;
  }

  if (!claim) {
    return <div className="text-center py-12 text-gray-500">Claim not found</div>;
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button onClick={() => navigate(-1)} className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
            <ArrowLeft size={20} className="text-gray-600" />
          </button>
          <div>
            <h2 className="text-xl font-bold text-secondary">{claim.claimNumber}</h2>
            <Badge status={claim.status} className="mt-1" />
          </div>
        </div>
      </div>

      {/* Two Column Layout */}
      <div className="grid grid-cols-3 gap-6">
        {/* Left Column */}
        <div className="col-span-2 space-y-5">
          {/* Claim Info */}
          <div className="bg-card rounded-2xl p-5 shadow-sm">
            <h3 className="text-base font-semibold text-secondary mb-4">Claim Information</h3>
            <div className="grid grid-cols-2 gap-4">
              <InfoItem label="Claim Number" value={claim.claimNumber} />
              <InfoItem label="Claimant Type" value={claim.claimantType ?? '—'} />
              <InfoItem label="Incident Date" value={format(new Date(claim.incidentDate), 'dd MMM yyyy')} />
              <InfoItem label="Submitted Date" value={format(new Date(claim.submittedAt), 'dd MMM yyyy')} />
              <InfoItem label="Vehicle Registration" value={claim.vehicleReg} />
              <InfoItem label="Claim Type" value={claim.type} />
              <InfoItem label="Last Updated" value={format(new Date(claim.updatedAt), 'dd MMM yyyy')} />
              <InfoItem label="Incident Location" value={claim.incidentLocation ?? '—'} />
              {claim.amount && <InfoItem label="Claim Amount" value={`₹${claim.amount.toLocaleString('en-IN')}`} />}
            </div>
          </div>

          {/* Description */}
          <div className="bg-card rounded-2xl p-5 shadow-sm">
            <h3 className="text-base font-semibold text-secondary mb-3">Description</h3>
            {claim.incidentDescription ? (
              <p className="text-sm text-gray-600 leading-relaxed whitespace-pre-line">
                {claim.incidentDescription}
              </p>
            ) : (
              <p className="text-sm text-gray-400">No description</p>
            )}
          </div>

          {/* Photos */}
          {(() => {
            const photos = documents.filter((d) => d.kind === 'Image');
            return (
              <div className="bg-card rounded-2xl p-5 shadow-sm">
                <h3 className="text-base font-semibold text-secondary mb-3">
                  Photos / Evidence{photos.length > 0 ? ` (${photos.length})` : ''}
                </h3>
                {photos.length > 0 ? (
                  <div className="grid grid-cols-3 gap-3">
                    {photos.map((photo) => (
                      <button
                        key={photo.id}
                        type="button"
                        onClick={() => setPreview({ url: photo.url, name: photo.fileName })}
                        className="block aspect-square bg-gray-100 rounded-xl overflow-hidden hover:opacity-90 transition cursor-zoom-in"
                        title={`${photo.fileName}${photo.category ? ` • ${photo.category}` : ''}`}
                      >
                        <img
                          src={photo.url}
                          alt={photo.fileName}
                          className="w-full h-full object-cover"
                        />
                      </button>
                    ))}
                  </div>
                ) : (
                  <p className="text-sm text-gray-400">No photos uploaded</p>
                )}
              </div>
            );
          })()}

          {/* Documents */}
          {(() => {
            const docs = documents.filter((d) => d.kind !== 'Image');
            if (docs.length === 0) return null;
            return (
              <div className="bg-card rounded-2xl p-5 shadow-sm">
                <h3 className="text-base font-semibold text-secondary mb-3">
                  Documents ({docs.length})
                </h3>
                <div className="space-y-2">
                  {docs.map((doc) => {
                    const sizeKb = Math.max(1, Math.round(doc.fileSize / 1024));
                    return (
                      <a
                        key={doc.id}
                        href={doc.url}
                        target="_blank"
                        rel="noreferrer"
                        className="flex items-center gap-3 px-3 py-2 border border-gray-200 rounded-lg hover:bg-gray-50 transition"
                      >
                        <div className="w-9 h-9 rounded-lg bg-primary/10 flex items-center justify-center text-primary text-xs font-bold">
                          {doc.fileName.split('.').pop()?.slice(0, 3).toUpperCase() ?? 'DOC'}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium text-gray-800 truncate">
                            {doc.fileName}
                          </p>
                          <p className="text-xs text-gray-500">
                            {doc.category ?? 'Document'} • {sizeKb} KB
                          </p>
                        </div>
                      </a>
                    );
                  })}
                </div>
              </div>
            );
          })()}
        </div>

        {/* Right Column */}
        <div className="space-y-5">
          {/* Claimant Info */}
          <div className="bg-card rounded-2xl p-5 shadow-sm">
            <h3 className="text-base font-semibold text-secondary mb-4">Claimant Info</h3>
            <div className="flex flex-col items-center text-center mb-4">
              <Avatar name={claim.userName} size="lg" />
              <p className="text-sm font-semibold text-gray-800 mt-2">{claim.userName}</p>
              <p className="text-xs text-gray-500">{user?.email}</p>
              <p className="text-xs text-gray-500">{user?.phone}</p>
              <p className="text-xs text-gray-400 mt-1">Member since {user ? format(new Date(user.memberSince), 'MMM yyyy') : '-'}</p>
            </div>
            <Link to={`/users/${claim.userId}`} className="block text-center text-sm text-primary hover:underline">
              <UserCircle size={14} className="inline mr-1" /> View Profile
            </Link>
          </div>

          {/* Timeline */}
          <div className="bg-card rounded-2xl p-5 shadow-sm">
            <h3 className="text-base font-semibold text-secondary mb-4">Timeline</h3>
            <div className="space-y-4">
              {mockTimeline.map((event) => (
                <div key={event.id} className="flex gap-3">
                  <div className="flex flex-col items-center">
                    <div className="w-2.5 h-2.5 rounded-full bg-primary mt-1" />
                    <div className="w-px flex-1 bg-gray-200" />
                  </div>
                  <div className="pb-4">
                    <p className="text-sm text-gray-700">{event.action}</p>
                    <p className="text-xs text-gray-400">{event.date ? format(new Date(event.date), 'dd MMM yyyy, HH:mm') : ''}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

        </div>
      </div>

      {preview && (
        <div
          className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center p-6"
          onClick={() => setPreview(null)}
        >
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              setPreview(null);
            }}
            aria-label="Close preview"
            className="absolute top-4 right-4 w-10 h-10 rounded-full bg-white/10 hover:bg-white/20 text-white flex items-center justify-center transition"
          >
            <X size={20} />
          </button>
          <img
            src={preview.url}
            alt={preview.name}
            onClick={(e) => e.stopPropagation()}
            className="max-w-full max-h-full object-contain rounded-lg shadow-2xl"
          />
        </div>
      )}
    </div>
  );
}

function InfoItem({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-xs text-gray-500 mb-0.5">{label}</p>
      <p className="text-sm font-medium text-gray-800">{value}</p>
    </div>
  );
}
