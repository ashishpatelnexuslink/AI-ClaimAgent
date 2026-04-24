import { useParams, useNavigate, Link } from 'react-router-dom';
import { ArrowLeft, Bot, Download, Copy } from 'lucide-react';
import { useQuery } from '@tanstack/react-query';
import { conversationsService } from '../../services/conversations.service';
import Badge from '../../components/ui/Badge';
import Avatar from '../../components/ui/Avatar';
import Spinner from '../../components/ui/Spinner';
import { useToastContext } from '../../hooks/ToastContext';
import { format } from 'date-fns';

const API_BASE = (import.meta.env.VITE_API_BASE_URL as string | undefined) ?? '';

function resolveTranscriptUrl(path: string): string {
  if (/^https?:\/\//i.test(path)) return path;
  if (!API_BASE) return path;
  return `${API_BASE.replace(/\/$/, '')}${path.startsWith('/') ? path : `/${path}`}`;
}

function formatDuration(seconds: number): string {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m}m ${s}s`;
}

export default function ConversationDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { addToast } = useToastContext();
  const { data: conversation, isLoading } = useQuery({
    queryKey: ['conversations', id],
    queryFn: () => conversationsService.getById(id!),
    enabled: !!id,
  });

  if (isLoading) {
    return <div className="flex items-center justify-center h-96"><Spinner size="lg" /></div>;
  }

  if (!conversation) {
    return <div className="text-center py-12 text-gray-500">Conversation not found</div>;
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <button onClick={() => navigate(-1)} className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
          <ArrowLeft size={20} className="text-gray-600" />
        </button>
        <div className="flex-1">
          <div className="flex items-center gap-3">
            <h2 className="text-xl font-bold text-secondary">{conversation.threadId}</h2>
            <Badge status={conversation.mode} />
            <Badge status={conversation.status} />
          </div>
          <p className="text-sm text-gray-500 mt-1">{conversation.userName} &middot; {formatDuration(conversation.duration)}</p>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-6">
        {/* Chat Replay */}
        <div className="col-span-2 bg-card rounded-2xl shadow-sm flex flex-col">
          <div className="px-5 py-4 border-b border-gray-100">
            <h3 className="text-base font-semibold text-secondary">Conversation Replay</h3>
          </div>
          <div className="flex-1 p-5 space-y-4 max-h-[600px] overflow-y-auto">
            {conversation.messages.map((msg) => (
              <div key={msg.id} className={`flex gap-3 ${msg.type === 'user' ? 'justify-end' : ''}`}>
                {msg.type === 'bot' && (
                  <div className="w-8 h-8 rounded-full bg-secondary flex items-center justify-center shrink-0">
                    <Bot size={16} className="text-white" />
                  </div>
                )}
                <div className={`max-w-[70%] ${msg.type === 'bot' ? '' : ''}`}>
                  <div
                    className={`px-4 py-3 rounded-2xl text-sm ${
                      msg.type === 'bot'
                        ? 'bg-secondary text-white rounded-tl-sm'
                        : 'bg-primary text-white rounded-tr-sm'
                    }`}
                  >
                    {msg.content}
                  </div>
                  {msg.suggestions && msg.suggestions.length > 0 && (
                    <div className="flex flex-wrap gap-2 mt-2">
                      {msg.suggestions.map((s, i) => (
                        <span key={i} className="px-3 py-1 bg-gray-100 text-gray-600 rounded-full text-xs">
                          {s}
                        </span>
                      ))}
                    </div>
                  )}
                  <p className="text-xs text-gray-400 mt-1 px-1">
                    {format(new Date(msg.timestamp), 'HH:mm')}
                  </p>
                </div>
                {msg.type === 'user' && (
                  <div className="w-8 h-8 shrink-0">
                    <Avatar name={conversation.userName} size="sm" />
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Right Panel */}
        <div className="space-y-5">
          {/* Session Info */}
          <div className="bg-card rounded-2xl p-5 shadow-sm">
            <h3 className="text-base font-semibold text-secondary mb-4">Session Info</h3>
            <div className="space-y-3">
              <InfoItem label="Thread ID" value={conversation.threadId} />
              <InfoItem label="Conversation ID" value={conversation.id} />
              <InfoItem label="User ID" value={conversation.userId} />
              <InfoItem label="Start Time" value={format(new Date(conversation.startedAt), 'dd MMM yyyy, HH:mm')} />
              {conversation.endedAt && (
                <InfoItem label="End Time" value={format(new Date(conversation.endedAt), 'dd MMM yyyy, HH:mm')} />
              )}
              <InfoItem label="Duration" value={formatDuration(conversation.duration)} />
              <InfoItem label="Mode" value={conversation.mode} />
              <InfoItem label="Total Messages" value={String(conversation.messageCount)} />
              <InfoItem label="Status" value={conversation.status} />
            </div>
          </div>

          {/* Linked Claim */}
          {conversation.claimId && (
            <div className="bg-card rounded-2xl p-5 shadow-sm">
              <h3 className="text-base font-semibold text-secondary mb-3">Linked Claim</h3>
              <Link to={`/claims/${conversation.claimId}`} className="text-sm text-primary hover:underline font-medium">
                View Claim #{conversation.claimId}
              </Link>
            </div>
          )}

          {/* Chat Transcript */}
          <div className="bg-card rounded-2xl p-5 shadow-sm">
            <h3 className="text-base font-semibold text-secondary mb-3">Chat Transcript</h3>
            {conversation.chatJsonPath ? (
              <div className="space-y-3">
                <div>
                  <p className="text-xs text-gray-500 mb-1">File path</p>
                  <p className="text-xs font-mono text-gray-700 break-all bg-gray-50 rounded px-2 py-1.5 border border-gray-100">
                    {conversation.chatJsonPath}
                  </p>
                </div>
                <div className="flex gap-2">
                  <a
                    href={resolveTranscriptUrl(conversation.chatJsonPath)}
                    target="_blank"
                    rel="noreferrer"
                    download
                    className="inline-flex items-center gap-1.5 text-xs font-medium text-primary hover:underline"
                  >
                    <Download size={14} /> Download JSON
                  </a>
                  <button
                    type="button"
                    onClick={() => {
                      navigator.clipboard.writeText(resolveTranscriptUrl(conversation.chatJsonPath!));
                      addToast('Path copied', 'success');
                    }}
                    className="inline-flex items-center gap-1.5 text-xs font-medium text-gray-600 hover:text-gray-800"
                  >
                    <Copy size={14} /> Copy URL
                  </button>
                </div>
                <p className="text-[11px] text-gray-400 leading-relaxed">
                  Sensitive identifiers (vehicle, VIN, policy) are masked before the transcript is persisted.
                </p>
              </div>
            ) : (
              <p className="text-xs text-gray-400">No transcript file yet for this conversation.</p>
            )}
          </div>

          {/* Collected Data */}
          <div className="bg-card rounded-2xl p-5 shadow-sm">
            <h3 className="text-base font-semibold text-secondary mb-4">Collected Data</h3>
            <div className="space-y-3">
              <InfoItem label="User Name" value={conversation.userName} />
              <InfoItem label="Mode" value={conversation.mode} />
              <InfoItem label="Messages Exchanged" value={String(conversation.messages.length)} />
              {conversation.claimId && <InfoItem label="Claim Linked" value={`#${conversation.claimId}`} />}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function InfoItem({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between">
      <span className="text-xs text-gray-500">{label}</span>
      <span className="text-sm font-medium text-gray-800">{value}</span>
    </div>
  );
}
