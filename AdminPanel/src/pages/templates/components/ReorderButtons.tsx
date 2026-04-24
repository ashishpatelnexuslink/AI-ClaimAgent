import { ArrowUp, ArrowDown } from 'lucide-react';

interface ReorderButtonsProps {
  onUp: () => void;
  onDown: () => void;
  isFirst: boolean;
  isLast: boolean;
}

export default function ReorderButtons({ onUp, onDown, isFirst, isLast }: ReorderButtonsProps) {
  return (
    <div className="inline-flex flex-col">
      <button
        type="button"
        onClick={onUp}
        disabled={isFirst}
        className="p-0.5 text-gray-400 hover:text-primary disabled:opacity-30 disabled:cursor-not-allowed"
        aria-label="Move up"
      >
        <ArrowUp size={14} />
      </button>
      <button
        type="button"
        onClick={onDown}
        disabled={isLast}
        className="p-0.5 text-gray-400 hover:text-primary disabled:opacity-30 disabled:cursor-not-allowed"
        aria-label="Move down"
      >
        <ArrowDown size={14} />
      </button>
    </div>
  );
}
