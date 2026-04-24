import type { TemplateStatus } from '../../../types';

const styles: Record<TemplateStatus, string> = {
  Draft: 'bg-gray-100 text-gray-700 border border-gray-200',
  Active: 'bg-success-light text-green-800 border border-green-200',
  Archived: 'bg-slate-100 text-slate-600 border border-slate-200',
};

interface Props {
  status: TemplateStatus;
  className?: string;
}

export default function TemplateStatusBadge({ status, className = '' }: Props) {
  return (
    <span
      className={`inline-flex items-center px-3 py-1 rounded-[30px] text-xs font-semibold ${styles[status]} ${className}`}
    >
      {status}
    </span>
  );
}
