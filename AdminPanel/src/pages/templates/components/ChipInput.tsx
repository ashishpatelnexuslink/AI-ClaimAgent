import { useState, type KeyboardEvent } from 'react';
import { X } from 'lucide-react';

interface ChipInputProps {
  value: string[];
  onChange: (next: string[]) => void;
  suggestions?: string[];
  placeholder?: string;
  id?: string;
  className?: string;
}

export default function ChipInput({
  value,
  onChange,
  suggestions = [],
  placeholder = 'Type and press Enter...',
  id,
  className = '',
}: ChipInputProps) {
  const [draft, setDraft] = useState('');

  const addChip = (raw: string) => {
    const v = raw.trim();
    if (!v) return;
    if (value.includes(v)) {
      setDraft('');
      return;
    }
    onChange([...value, v]);
    setDraft('');
  };

  const removeChip = (i: number) => {
    const next = value.slice();
    next.splice(i, 1);
    onChange(next);
  };

  const handleKey = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' || e.key === ',') {
      e.preventDefault();
      addChip(draft);
    } else if (e.key === 'Backspace' && !draft && value.length) {
      removeChip(value.length - 1);
    }
  };

  const unused = suggestions.filter((s) => !value.includes(s));

  return (
    <div className={className}>
      <div className="flex flex-wrap items-center gap-2 px-3 py-2 rounded-lg border border-gray-300 focus-within:border-primary focus-within:ring-2 focus-within:ring-primary/30 bg-white min-h-[42px]">
        {value.map((chip, i) => (
          <span
            key={`${chip}-${i}`}
            className="inline-flex items-center gap-1 bg-primary-light text-primary text-xs font-medium px-2 py-1 rounded-md"
          >
            {chip}
            <button
              type="button"
              onClick={() => removeChip(i)}
              className="hover:text-blue-900"
              aria-label={`Remove ${chip}`}
            >
              <X size={12} />
            </button>
          </span>
        ))}
        <input
          id={id}
          type="text"
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          onKeyDown={handleKey}
          onBlur={() => draft && addChip(draft)}
          placeholder={value.length === 0 ? placeholder : ''}
          className="flex-1 min-w-[120px] outline-none text-sm bg-transparent"
        />
      </div>
      {unused.length > 0 && (
        <div className="flex flex-wrap items-center gap-1 mt-2">
          <span className="text-xs text-gray-500 mr-1">Suggestions:</span>
          {unused.map((s) => (
            <button
              key={s}
              type="button"
              onClick={() => addChip(s)}
              className="text-xs text-primary hover:bg-primary-light px-2 py-0.5 rounded-md"
            >
              + {s}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
