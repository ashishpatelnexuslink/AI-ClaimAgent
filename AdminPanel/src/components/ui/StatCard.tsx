import type { ReactNode } from 'react';
import { TrendingUp, TrendingDown } from 'lucide-react';

interface StatCardProps {
  title: string;
  value: string | number;
  icon: ReactNode;
  color: string;
  subtitle: string;
  trend?: { value: number; direction: 'up' | 'down' };
}

const colorMap: Record<string, { bg: string; bar: string }> = {
  blue: { bg: 'bg-primary-light', bar: 'bg-primary' },
  amber: { bg: 'bg-warning-light', bar: 'bg-warning' },
  green: { bg: 'bg-success-light', bar: 'bg-success' },
  red: { bg: 'bg-danger-light', bar: 'bg-danger' },
  purple: { bg: 'bg-purple-100', bar: 'bg-purple-500' },
};

export default function StatCard({ title, value, icon, color, subtitle, trend }: StatCardProps) {
  const colors = colorMap[color] || colorMap.blue;

  return (
    <div className="bg-card rounded-2xl p-5 shadow-sm hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between mb-3">
        <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${colors.bg}`}>
          {icon}
        </div>
        {trend && (
          <div className={`flex items-center gap-1 text-xs font-medium ${trend.direction === 'up' ? 'text-success' : 'text-danger'}`}>
            {trend.direction === 'up' ? <TrendingUp size={14} /> : <TrendingDown size={14} />}
            {trend.value}%
          </div>
        )}
      </div>
      <p className="text-xs text-gray-500 mb-1">{title}</p>
      <p className="text-[28px] font-bold text-secondary mb-1">{value}</p>
      <p className="text-xs text-gray-500">{subtitle}</p>
      <div className={`h-1 rounded-full mt-3 ${colors.bar}`} />
    </div>
  );
}
