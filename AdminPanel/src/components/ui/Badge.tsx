interface BadgeProps {
  status: string;
  className?: string;
}

const badgeStyles: Record<string, string> = {
  'Draft': 'bg-gray-100 text-gray-600',
  'Pending': 'bg-warning-light text-yellow-800',
  'Submitted': 'bg-primary-light text-blue-800',
  'Approved': 'bg-success-light text-green-800',
  'Rejected': 'bg-danger-light text-red-700',
  'Under Review': 'bg-primary-light text-blue-800',
  'InReview': 'bg-primary-light text-blue-800',
  'Closed': 'bg-gray-100 text-gray-600',
  'Active': 'bg-success-light text-green-800',
  'Suspended': 'bg-danger-light text-red-700',
  'Completed': 'bg-success-light text-green-800',
  'Abandoned': 'bg-gray-100 text-gray-600',
  'Voice': 'bg-purple-100 text-purple-800',
  'Chat': 'bg-teal-100 text-teal-800',
  'Policy Holder': 'bg-blue-100 text-blue-800',
  'Third-party': 'bg-orange-100 text-orange-800',
};

const displayLabel: Record<string, string> = {
  'InReview': 'Under Review',
};

export default function Badge({ status, className = '' }: BadgeProps) {
  const style = badgeStyles[status] || 'bg-gray-100 text-gray-600';
  const label = displayLabel[status] ?? status;
  return (
    <span className={`inline-flex items-center px-3 py-1 rounded-[30px] text-xs font-semibold ${style} ${className}`}>
      {label}
    </span>
  );
}
