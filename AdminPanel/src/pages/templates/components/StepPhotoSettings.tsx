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

const ANGLE_SUGGESTIONS = [
  'front',
  'side',
  'close_up',
  'front_left',
  'front_right',
  'rear_left',
  'rear_right',
  'back',
];

const MIME_SUGGESTIONS = ['image/jpeg', 'image/png', 'image/webp', 'image/heic'];

export default function StepPhotoSettings() {
  const {
    register,
    control,
    formState: { errors },
  } = useFormContext<WizardForm>();

  const fa = useFieldArray({ control, name: 'photoSettings' });
  const allPhoto = useWatch({ control, name: 'photoSettings' }) ?? [];

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
    const id = `photo_group_${fa.fields.length + 1}`;
    fa.append({
      groupKey: id,
      label: '',
      instruction: '',
      minCount: 1,
      maxCount: 1,
      isRequired: true,
      allowedAngles: [],
      sampleImageUrls: [],
      maxFileSizeMb: 10,
      allowedMimeTypes: ['image/jpeg', 'image/png'],
      displayOrder: fa.fields.length + 1,
    });
  };

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-semibold text-secondary">Photo groups</h3>
        <button
          type="button"
          onClick={addGroup}
          className="flex items-center gap-1 text-sm text-primary hover:underline"
        >
          <FolderPlus size={14} /> Add photo group
        </button>
      </div>

      {fa.fields.length === 0 && (
        <div className="bg-white border border-dashed border-gray-200 rounded-xl px-4 py-8 text-center">
          <p className="text-sm text-gray-500">
            No photo groups yet. Add one to require photos from the claimant.
          </p>
        </div>
      )}

      {fa.fields.map((field, i) => {
        const fieldId = field.id;
        const isCollapsed = collapsedIds.has(fieldId);
        const current = allPhoto[i];
        const err = errors.photoSettings?.[i];

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
                <span className="sr-only">Group key</span>
                <input
                  {...register(`photoSettings.${i}.groupKey` as const, {
                    required: 'Required',
                  })}
                  className="w-full px-2 py-1 bg-transparent font-mono text-sm font-semibold text-gray-900 focus:outline-none focus:ring-2 focus:ring-primary/30 rounded"
                  placeholder="photo_group_key"
                />
              </label>

              <div className="flex items-center gap-2 text-xs text-gray-600">
                <span>min</span>
                <input
                  type="number"
                  min={0}
                  {...register(`photoSettings.${i}.minCount` as const, {
                    valueAsNumber: true,
                    min: { value: 0, message: '>= 0' },
                  })}
                  className="w-16 px-2 py-1 rounded border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
                />
                <span>max</span>
                <input
                  type="number"
                  min={0}
                  {...register(`photoSettings.${i}.maxCount` as const, {
                    valueAsNumber: true,
                    min: { value: 0, message: '>= 0' },
                  })}
                  className="w-16 px-2 py-1 rounded border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
                />
              </div>

              <label className="flex items-center gap-1.5 text-xs text-gray-700 shrink-0">
                <input
                  type="checkbox"
                  {...register(`photoSettings.${i}.isRequired` as const)}
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
                  aria-label="Remove photo group"
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
                      {...register(`photoSettings.${i}.label` as const, {
                        required: 'Required',
                      })}
                      className="mt-1 w-full px-3 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
                      placeholder="Vehicle Photos"
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
                      {...register(`photoSettings.${i}.maxFileSizeMb` as const, {
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
                    {...register(`photoSettings.${i}.instruction` as const)}
                    className="mt-1 w-full px-3 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary resize-none"
                    placeholder="e.g. Upload four photos of the vehicle from each corner."
                  />
                </label>

                <div>
                  <span className="text-xs font-medium text-gray-600">Allowed Angles</span>
                  <Controller
                    control={control}
                    name={`photoSettings.${i}.allowedAngles` as const}
                    render={({ field: f }) => (
                      <ChipInput
                        value={f.value ?? []}
                        onChange={f.onChange}
                        suggestions={ANGLE_SUGGESTIONS}
                        placeholder="e.g. front_left"
                        className="mt-1"
                      />
                    )}
                  />
                </div>

                <div>
                  <span className="text-xs font-medium text-gray-600">Allowed MIME Types</span>
                  <Controller
                    control={control}
                    name={`photoSettings.${i}.allowedMimeTypes` as const}
                    rules={{
                      validate: (v) => (v && v.length > 0) || 'At least one MIME type',
                    }}
                    render={({ field: f, fieldState }) => (
                      <>
                        <ChipInput
                          value={f.value ?? []}
                          onChange={f.onChange}
                          suggestions={MIME_SUGGESTIONS}
                          placeholder="image/jpeg"
                          className="mt-1"
                        />
                        {fieldState.error && (
                          <p className="text-xs text-danger mt-1">{fieldState.error.message}</p>
                        )}
                      </>
                    )}
                  />
                </div>

                {/* sampleImageUrls stays in form state as whatever was loaded/defaulted;
                    no UI for it. RHF tracks the field automatically via useFieldArray's
                    append(), no explicit register needed. */}
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
          <FolderPlus size={16} /> Add photo group
        </button>
      )}
    </div>
  );
}
