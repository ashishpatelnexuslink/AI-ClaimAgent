import {
  useFieldArray,
  useFormContext,
  useWatch,
  type FieldErrors,
} from 'react-hook-form';
import {
  Plus,
  Trash2,
  AlertTriangle,
  ChevronDown,
  ChevronRight,
  ChevronUp,
  FolderPlus,
} from 'lucide-react';
import { useEffect, useMemo, useRef, useState } from 'react';
import type { WizardForm } from './wizardTypes';
import type { CreateIdentityField } from '../../../types';
import ReorderButtons from './ReorderButtons';

/**
 * Group-first editor for identity fields.
 *
 * Data model stays flat on the wire (identityFields[] with groupKey +
 * groupRules[]). The UI derives a nested view: "Ungrouped fields" at the top
 * (groupKey empty/null), then one collapsible card per group rule containing
 * the fields whose groupKey matches. Renaming a group propagates the new key
 * to every field in that group via an effect.
 */
export default function StepIdentityFields() {
  const {
    register,
    control,
    formState: { errors },
    getValues,
    setValue,
  } = useFormContext<WizardForm>();

  const fieldsArray = useFieldArray({ control, name: 'identityFields' });
  const rulesArray = useFieldArray({ control, name: 'groupRules' });

  const allFields = useWatch({ control, name: 'identityFields' }) ?? [];
  const allRules = useWatch({ control, name: 'groupRules' }) ?? [];

  // Collapse state keyed by groupKey string — survives group reordering.
  const [collapsedKeys, setCollapsedKeys] = useState<Set<string>>(new Set());
  const toggleCollapsed = (groupKey: string) =>
    setCollapsedKeys((s) => {
      const n = new Set(s);
      if (n.has(groupKey)) n.delete(groupKey);
      else n.add(groupKey);
      return n;
    });

  // Propagate group-key renames from a rule to its member fields so that a
  // rename in the group header automatically retags every field beneath it.
  const prevKeysRef = useRef<string[]>(allRules.map((r) => r.groupKey));
  useEffect(() => {
    const prev = prevKeysRef.current;
    allRules.forEach((rule, i) => {
      const oldKey = prev[i];
      const newKey = rule.groupKey;
      if (oldKey && newKey && oldKey !== newKey) {
        const current = getValues('identityFields') ?? [];
        current.forEach((f, fi) => {
          if (f.groupKey === oldKey) {
            setValue(`identityFields.${fi}.groupKey` as const, newKey, {
              shouldDirty: true,
            });
          }
        });
      }
    });
    prevKeysRef.current = allRules.map((r) => r.groupKey);
  }, [allRules, getValues, setValue]);

  // Derive the flat->nested view. Every field belongs to a group; any field
  // with a missing/unknown groupKey falls into an "orphan" bucket surfaced
  // via warnings below but not rendered as a first-class section.
  const { indicesByGroupKey, orphanIndices } = useMemo(() => {
    const byKey: Record<string, number[]> = {};
    const orphans: number[] = [];
    const ruleKeys = new Set(allRules.map((r) => r.groupKey));
    allFields.forEach((f, i) => {
      const gk = (f.groupKey ?? '').trim();
      if (gk && ruleKeys.has(gk)) (byKey[gk] ||= []).push(i);
      else orphans.push(i);
    });
    return { indicesByGroupKey: byKey, orphanIndices: orphans };
  }, [allFields, allRules]);

  const warnings = useMemo(() => {
    const out: string[] = [];
    const ruleKeys = new Set(allRules.map((r) => r.groupKey));

    // Duplicate group keys on rules
    const seenRuleKeys = new Set<string>();
    for (const r of allRules) {
      if (seenRuleKeys.has(r.groupKey))
        out.push(`Duplicate group key "${r.groupKey}".`);
      seenRuleKeys.add(r.groupKey);
    }

    // Orphan fields (no group or unknown group)
    orphanIndices.forEach((i) => {
      const f = allFields[i];
      const gk = (f.groupKey ?? '').trim();
      if (!gk) {
        out.push(`Field "${f.fieldKey || '(unnamed)'}" has no group. Assign it or delete it.`);
      } else if (!ruleKeys.has(gk)) {
        out.push(`Field "${f.fieldKey || '(unnamed)'}" references group "${gk}" with no rule.`);
      }
    });

    // Duplicate field keys
    const fieldKeyCounts: Record<string, number> = {};
    for (const f of allFields) if (f.fieldKey) fieldKeyCounts[f.fieldKey] = (fieldKeyCounts[f.fieldKey] ?? 0) + 1;
    Object.entries(fieldKeyCounts).forEach(([k, count]) => {
      if (count > 1) out.push(`Duplicate field key "${k}".`);
    });

    // minRequired feasibility
    allRules.forEach((r) => {
      const count = (indicesByGroupKey[r.groupKey] || []).length;
      if (r.minRequired > count)
        out.push(
          `Group "${r.groupKey}" requires at least ${r.minRequired} input${r.minRequired === 1 ? '' : 's'} but only ${count} field${count === 1 ? '' : 's'} assigned.`,
        );
    });

    return out;
  }, [allFields, allRules, indicesByGroupKey, orphanIndices]);

  const addFieldToGroup = (groupKey: string) =>
    fieldsArray.append({
      fieldKey: '',
      label: '',
      promptText: '',
      placeholder: '',
      validationRegex: '',
      groupKey,
      isSkippable: false,
      displayOrder: allFields.length + 1,
    });

  const addGroup = () => {
    let n = 1;
    const existing = new Set(allRules.map((r) => r.groupKey));
    while (existing.has(`group_${n}`)) n++;
    rulesArray.append({
      groupKey: `group_${n}`,
      minRequired: 1,
      maxAllowed: null,
      errorMessage: '',
    });
  };

  const removeGroup = (ruleIndex: number, groupKey: string) => {
    // Delete all member fields (descending order so indices stay valid)
    const current = getValues('identityFields') ?? [];
    const toRemove = current
      .map((f, i) => ({ f, i }))
      .filter(({ f }) => f.groupKey === groupKey)
      .map(({ i }) => i)
      .sort((a, b) => b - a);
    toRemove.forEach((i) => fieldsArray.remove(i));
    rulesArray.remove(ruleIndex);
  };

  // Reorder within a group using absolute indices into the flat array.
  const moveWithin = (indices: number[], posInGroup: number, dir: -1 | 1) => {
    const target = posInGroup + dir;
    if (target < 0 || target >= indices.length) return;
    fieldsArray.move(indices[posInGroup], indices[target]);
  };

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-semibold text-secondary">Identity fields</h3>
        <button
          type="button"
          onClick={addGroup}
          className="flex items-center gap-1 text-sm text-primary hover:underline"
        >
          <FolderPlus size={14} /> Add group
        </button>
      </div>

      {allRules.length === 0 && (
        <div className="bg-white border border-dashed border-gray-200 rounded-xl px-4 py-8 text-center">
          <p className="text-sm text-gray-500">
            No groups yet. Create a group, then add fields into it.
          </p>
        </div>
      )}

      {/* Groups */}
      {allRules.map((rule, ri) => {
        const groupKey = rule.groupKey;
        const isCollapsed = collapsedKeys.has(groupKey);
        const memberIndices = indicesByGroupKey[groupKey] ?? [];
        const ruleErr = errors.groupRules?.[ri];
        return (
          <section
            key={rulesArray.fields[ri]?.id ?? ri}
            className="bg-white border border-gray-200 rounded-xl overflow-hidden"
          >
            <header className="flex items-center gap-3 px-4 py-3 bg-gray-50 border-b border-gray-200">
              <button
                type="button"
                onClick={() => toggleCollapsed(groupKey)}
                className="p-1 text-gray-500 hover:text-primary"
                aria-label={isCollapsed ? 'Expand group' : 'Collapse group'}
              >
                {isCollapsed ? <ChevronRight size={16} /> : <ChevronDown size={16} />}
              </button>

              <label className="flex-1 min-w-0">
                <span className="sr-only">Group key</span>
                <input
                  {...register(`groupRules.${ri}.groupKey` as const, {
                    required: 'Group key required',
                  })}
                  className="w-full px-2 py-1 bg-transparent font-mono text-sm font-semibold text-gray-900 focus:outline-none focus:ring-2 focus:ring-primary/30 rounded"
                  placeholder="group_key"
                />
              </label>

              <div className="flex items-center gap-2 text-xs text-gray-600">
                <span>min</span>
                <input
                  type="number"
                  min={0}
                  {...register(`groupRules.${ri}.minRequired` as const, {
                    valueAsNumber: true,
                    min: { value: 0, message: '>= 0' },
                  })}
                  className="w-16 px-2 py-1 rounded border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
                />
                <span>max</span>
                <input
                  type="number"
                  min={0}
                  {...register(`groupRules.${ri}.maxAllowed` as const, {
                    setValueAs: (v) => (v === '' || v === null ? null : Number(v)),
                  })}
                  className="w-16 px-2 py-1 rounded border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
                  placeholder="—"
                />
              </div>

              <span className="text-xs text-gray-400 shrink-0">
                {memberIndices.length} field{memberIndices.length === 1 ? '' : 's'}
              </span>

              <button
                type="button"
                onClick={() => removeGroup(ri, groupKey)}
                className="p-1.5 text-gray-400 hover:text-danger hover:bg-danger-light rounded-lg"
                aria-label="Delete group and its fields"
              >
                <Trash2 size={16} />
              </button>
            </header>

            {!isCollapsed && (
              <div className="p-4 space-y-3">
                {(ruleErr?.groupKey || ruleErr?.minRequired || ruleErr?.maxAllowed) && (
                  <div className="text-xs text-danger space-y-1">
                    {ruleErr.groupKey && <div>{ruleErr.groupKey.message}</div>}
                    {ruleErr.minRequired && <div>Min: {ruleErr.minRequired.message}</div>}
                    {ruleErr.maxAllowed && <div>Max: {ruleErr.maxAllowed.message}</div>}
                  </div>
                )}

                <label className="block">
                  <span className="text-xs font-medium text-gray-600">
                    Error message <span className="text-gray-400">(optional)</span>
                  </span>
                  <textarea
                    rows={2}
                    {...register(`groupRules.${ri}.errorMessage` as const)}
                    className="mt-1 w-full px-3 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary resize-none"
                    placeholder="Leave blank to auto-generate from Min Required / Group Key."
                  />
                </label>

                {memberIndices.length === 0 ? (
                  <p className="text-sm text-gray-400 bg-gray-50 border border-dashed border-gray-200 rounded-lg px-4 py-4 text-center">
                    No fields in this group yet.
                  </p>
                ) : (
                  <div className="space-y-2">
                    {memberIndices.map((absoluteIndex, posInGroup) => (
                      <IdentityFieldRow
                        key={fieldsArray.fields[absoluteIndex]?.id ?? absoluteIndex}
                        absoluteIndex={absoluteIndex}
                        displayNumber={posInGroup + 1}
                        isFirst={posInGroup === 0}
                        isLast={posInGroup === memberIndices.length - 1}
                        onUp={() => moveWithin(memberIndices, posInGroup, -1)}
                        onDown={() => moveWithin(memberIndices, posInGroup, 1)}
                        onRemove={() => fieldsArray.remove(absoluteIndex)}
                        register={register}
                        error={errors.identityFields?.[absoluteIndex]}
                      />
                    ))}
                  </div>
                )}

                <button
                  type="button"
                  onClick={() => addFieldToGroup(groupKey)}
                  className="flex items-center gap-1 text-sm text-primary hover:underline"
                >
                  <Plus size={14} /> Add field to this group
                </button>
              </div>
            )}
          </section>
        );
      })}

      <button
        type="button"
        onClick={addGroup}
        className="w-full flex items-center justify-center gap-2 py-3 rounded-xl border-2 border-dashed border-gray-200 text-sm text-gray-500 hover:border-primary hover:text-primary transition-colors"
      >
        <FolderPlus size={16} /> Add group
      </button>

      {warnings.length > 0 && (
        <div className="rounded-xl border border-warning bg-warning-light px-4 py-3">
          <div className="flex items-start gap-2">
            <AlertTriangle size={16} className="text-yellow-700 mt-0.5 shrink-0" />
            <div className="text-sm text-yellow-900 space-y-1">
              {warnings.map((w, i) => (
                <div key={i}>{w}</div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

interface IdentityFieldRowProps {
  absoluteIndex: number;
  displayNumber: number;
  isFirst: boolean;
  isLast: boolean;
  onUp: () => void;
  onDown: () => void;
  onRemove: () => void;
  register: ReturnType<typeof useFormContext<WizardForm>>['register'];
  error: FieldErrors<CreateIdentityField> | undefined;
}

function IdentityFieldRow({
  absoluteIndex,
  displayNumber,
  isFirst,
  isLast,
  onUp,
  onDown,
  onRemove,
  register,
  error,
}: IdentityFieldRowProps) {
  const [showRegex, setShowRegex] = useState(false);
  const err = (k: keyof CreateIdentityField) => error?.[k]?.message as string | undefined;

  return (
    <div className="bg-white border border-gray-200 rounded-lg p-3">
      <div className="flex items-start gap-3">
        <div className="flex flex-col items-center gap-1 pt-1 shrink-0">
          <ReorderButtons onUp={onUp} onDown={onDown} isFirst={isFirst} isLast={isLast} />
          <span className="text-xs text-gray-400">#{displayNumber}</span>
        </div>

        <div className="flex-1 grid grid-cols-2 gap-3">
          <label className="block">
            <span className="text-xs font-medium text-gray-600">Field Key *</span>
            <input
              {...register(`identityFields.${absoluteIndex}.fieldKey` as const, {
                required: 'Required',
                pattern: { value: /^[a-z_]+$/, message: 'lowercase letters + underscores only' },
              })}
              className="mt-1 w-full px-3 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
              placeholder="full_name"
            />
            {err('fieldKey') && <p className="text-xs text-danger mt-1">{err('fieldKey')}</p>}
          </label>

          <label className="block">
            <span className="text-xs font-medium text-gray-600">Label *</span>
            <input
              {...register(`identityFields.${absoluteIndex}.label` as const, {
                required: 'Required',
              })}
              className="mt-1 w-full px-3 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
              placeholder="Full Name"
            />
            {err('label') && <p className="text-xs text-danger mt-1">{err('label')}</p>}
          </label>

          <div className="col-span-2 flex items-center justify-between gap-4 flex-wrap">
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                {...register(`identityFields.${absoluteIndex}.isSkippable` as const)}
                className="h-4 w-4"
              />
              <span className="text-sm text-gray-700">Skippable</span>
            </label>

            <button
              type="button"
              onClick={() => setShowRegex((s) => !s)}
              className="text-xs text-primary hover:underline inline-flex items-center gap-1"
            >
              {showRegex ? <ChevronUp size={12} /> : <ChevronDown size={12} />}
              Advanced (validation regex)
            </button>
          </div>

          {showRegex && (
            <div className="col-span-2">
              <input
                {...register(`identityFields.${absoluteIndex}.validationRegex` as const)}
                className="w-full px-3 py-2 rounded-lg border border-gray-300 text-sm font-mono focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
                placeholder="^[A-Z0-9-]+$"
              />
            </div>
          )}

          {/* Prompt text and placeholder remain in form state via hidden inputs;
              normalizeWizardForm backfills promptText from label at submit. */}
          <input type="hidden" {...register(`identityFields.${absoluteIndex}.promptText` as const)} />
          <input type="hidden" {...register(`identityFields.${absoluteIndex}.placeholder` as const)} />
          <input type="hidden" {...register(`identityFields.${absoluteIndex}.groupKey` as const)} />
        </div>

        <button
          type="button"
          onClick={onRemove}
          className="p-2 text-gray-400 hover:text-danger hover:bg-danger-light rounded-lg shrink-0"
          aria-label="Remove field"
        >
          <Trash2 size={16} />
        </button>
      </div>
    </div>
  );
}
