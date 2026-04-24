import { useFieldArray, useFormContext, Controller, useWatch } from 'react-hook-form';
import {
  Trash2,
  ChevronDown,
  ChevronRight,
  FolderPlus,
} from 'lucide-react';
import { useState } from 'react';
import type { WizardForm } from './wizardTypes';
import ChipInput from './ChipInput';
import ReorderButtons from './ReorderButtons';

const MIME_SUGGESTIONS = [
  'application/pdf',
  'image/jpeg',
  'image/png',
  'image/webp',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
];

export default function StepDocumentSettings() {
  const {
    register,
    control,
    formState: { errors },
  } = useFormContext<WizardForm>();

  const fa = useFieldArray({ control, name: 'documentSettings' });
  const allDocs = useWatch({ control, name: 'documentSettings' }) ?? [];

  // Collapse state keyed by RHF field id so it survives reorders cleanly.
  const [collapsedIds, setCollapsedIds] = useState<Set<string>>(new Set());
  const toggleCollapsed = (id: string) =>
    setCollapsedIds((s) => {
      const n = new Set(s);
      if (n.has(id)) n.delete(id);
      else n.add(id);
      return n;
    });

  const addGroup = () => {
    const id = `document_group_${fa.fields.length + 1}`;
    fa.append({
      docKey: id,
      label: '',
      instruction: '',
      minCount: 1,
      maxCount: 1,
      isRequired: true,
      maxFileSizeMb: 10,
      allowedMimeTypes: ['application/pdf', 'image/jpeg', 'image/png'],
      displayOrder: fa.fields.length + 1,
    });
  };

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-semibold text-secondary">Document groups</h3>
        <button
          type="button"
          onClick={addGroup}
          className="flex items-center gap-1 text-sm text-primary hover:underline"
        >
          <FolderPlus size={14} /> Add document group
        </button>
      </div>

      {fa.fields.length === 0 && (
        <div className="bg-white border border-dashed border-gray-200 rounded-xl px-4 py-8 text-center">
          <p className="text-sm text-gray-500">
            No document groups yet. Add one to require documents from the claimant.
          </p>
        </div>
      )}

      {fa.fields.map((field, i) => {
        const fieldId = field.id;
        const isCollapsed = collapsedIds.has(fieldId);
        const current = allDocs[i];
        const err = errors.documentSettings?.[i];

        return (
          <section
            key={fieldId}
            className="bg-white border border-gray-200 rounded-xl overflow-hidden"
          >
            <header className="flex items-center gap-3 px-4 py-3 bg-gray-50 border-b border-gray-200">
              <button
                type="button"
                onClick={() => toggleCollapsed(fieldId)}
                className="p-1 text-gray-500 hover:text-primary"
                aria-label={isCollapsed ? 'Expand group' : 'Collapse group'}
              >
                {isCollapsed ? <ChevronRight size={16} /> : <ChevronDown size={16} />}
              </button>

              <label className="flex-1 min-w-0">
                <span className="sr-only">Doc key</span>
                <input
                  {...register(`documentSettings.${i}.docKey` as const, {
                    required: 'Required',
                  })}
                  className="w-full px-2 py-1 bg-transparent font-mono text-sm font-semibold text-gray-900 focus:outline-none focus:ring-2 focus:ring-primary/30 rounded"
                  placeholder="document_group_key"
                />
              </label>

              <div className="flex items-center gap-2 text-xs text-gray-600">
                <span>min</span>
                <input
                  type="number"
                  min={0}
                  {...register(`documentSettings.${i}.minCount` as const, {
                    valueAsNumber: true,
                    min: { value: 0, message: '>= 0' },
                  })}
                  className="w-16 px-2 py-1 rounded border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
                />
                <span>max</span>
                <input
                  type="number"
                  min={0}
                  {...register(`documentSettings.${i}.maxCount` as const, {
                    valueAsNumber: true,
                    min: { value: 0, message: '>= 0' },
                  })}
                  className="w-16 px-2 py-1 rounded border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
                />
              </div>

              <label className="flex items-center gap-1.5 text-xs text-gray-700 shrink-0">
                <input
                  type="checkbox"
                  {...register(`documentSettings.${i}.isRequired` as const)}
                  className="h-4 w-4"
                />
                <span>required</span>
              </label>

              {current?.label && isCollapsed && (
                <span className="text-xs text-gray-500 truncate max-w-[140px] hidden md:inline">
                  · {current.label}
                </span>
              )}

              <div className="flex items-center gap-1 shrink-0">
                <ReorderButtons
                  onUp={() => fa.move(i, i - 1)}
                  onDown={() => fa.move(i, i + 1)}
                  isFirst={i === 0}
                  isLast={i === fa.fields.length - 1}
                />
                <button
                  type="button"
                  onClick={() => fa.remove(i)}
                  className="p-1.5 text-gray-400 hover:text-danger hover:bg-danger-light rounded-lg"
                  aria-label="Remove document group"
                >
                  <Trash2 size={16} />
                </button>
              </div>
            </header>

            {!isCollapsed && (
              <div className="p-4 space-y-4">
                <div className="grid grid-cols-2 gap-3">
                  <label className="block">
                    <span className="text-xs font-medium text-gray-600">Label *</span>
                    <input
                      {...register(`documentSettings.${i}.label` as const, {
                        required: 'Required',
                      })}
                      className="mt-1 w-full px-3 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
                      placeholder="Insurance Policy"
                    />
                    {err?.label && (
                      <p className="text-xs text-danger mt-1">{err.label.message}</p>
                    )}
                  </label>

                  <label className="block">
                    <span className="text-xs font-medium text-gray-600">Max File Size (MB)</span>
                    <input
                      type="number"
                      min={1}
                      max={100}
                      {...register(`documentSettings.${i}.maxFileSizeMb` as const, {
                        valueAsNumber: true,
                        min: { value: 1, message: '1–100' },
                        max: { value: 100, message: '1–100' },
                      })}
                      className="mt-1 w-full px-3 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
                    />
                  </label>
                </div>

                <label className="block">
                  <span className="text-xs font-medium text-gray-600">Instruction</span>
                  <textarea
                    rows={2}
                    {...register(`documentSettings.${i}.instruction` as const)}
                    className="mt-1 w-full px-3 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary resize-none"
                    placeholder="e.g. Upload a copy of the policy schedule and claim form."
                  />
                </label>

                <div>
                  <span className="text-xs font-medium text-gray-600">Allowed MIME Types</span>
                  <Controller
                    control={control}
                    name={`documentSettings.${i}.allowedMimeTypes` as const}
                    rules={{
                      validate: (v) => (v && v.length > 0) || 'At least one MIME type',
                    }}
                    render={({ field: f, fieldState }) => (
                      <>
                        <ChipInput
                          value={f.value ?? []}
                          onChange={f.onChange}
                          suggestions={MIME_SUGGESTIONS}
                          placeholder="application/pdf"
                          className="mt-1"
                        />
                        {fieldState.error && (
                          <p className="text-xs text-danger mt-1">{fieldState.error.message}</p>
                        )}
                      </>
                    )}
                  />
                </div>
              </div>
            )}
          </section>
        );
      })}

      {fa.fields.length > 0 && (
        <button
          type="button"
          onClick={addGroup}
          className="w-full flex items-center justify-center gap-2 py-3 rounded-xl border-2 border-dashed border-gray-200 text-sm text-gray-500 hover:border-primary hover:text-primary transition-colors"
        >
          <FolderPlus size={16} /> Add document group
        </button>
      )}
    </div>
  );
}
