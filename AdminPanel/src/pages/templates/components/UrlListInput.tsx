import { Trash2, Plus, ImageIcon } from 'lucide-react';
import { useState } from 'react';

interface UrlListInputProps {
  value: string[];
  onChange: (next: string[]) => void;
}

export default function UrlListInput({ value, onChange }: UrlListInputProps) {
  const update = (i: number, url: string) => {
    const next = value.slice();
    next[i] = url;
    onChange(next);
  };
  const remove = (i: number) => {
    const next = value.slice();
    next.splice(i, 1);
    onChange(next);
  };
  const add = () => onChange([...value, '']);

  return (
    <div className="space-y-2">
      {value.map((url, i) => (
        <UrlRow key={i} url={url} onChange={(v) => update(i, v)} onRemove={() => remove(i)} />
      ))}
      <button
        type="button"
        onClick={add}
        className="flex items-center gap-1 text-sm text-primary hover:underline"
      >
        <Plus size={14} /> Add URL
      </button>
    </div>
  );
}

function UrlRow({ url, onChange, onRemove }: { url: string; onChange: (v: string) => void; onRemove: () => void }) {
  const [broken, setBroken] = useState(false);
  return (
    <div className="flex items-center gap-2">
      <input
        type="url"
        value={url}
        onChange={(e) => {
          setBroken(false);
          onChange(e.target.value);
        }}
        placeholder="https://..."
        className="flex-1 px-3 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
      />
      <div className="w-10 h-10 shrink-0 rounded-md border border-gray-200 overflow-hidden flex items-center justify-center bg-gray-50">
        {url && !broken ? (
          <img
            src={url}
            alt="preview"
            className="w-full h-full object-cover"
            onError={() => setBroken(true)}
          />
        ) : (
          <ImageIcon size={16} className="text-gray-300" />
        )}
      </div>
      <button
        type="button"
        onClick={onRemove}
        className="p-2 text-gray-400 hover:text-danger hover:bg-danger-light rounded-lg"
        aria-label="Remove URL"
      >
        <Trash2 size={16} />
      </button>
    </div>
  );
}
