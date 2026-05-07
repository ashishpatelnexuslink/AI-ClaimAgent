import type { Template } from '../../../types';
import type { WizardForm } from './wizardTypes';

/** Populate a wizard form from a fetched template (for edit mode).
 *
 *  The UI is group-first — every identity field must belong to a group.
 *  Existing templates may have orphan fields (groupKey null/empty) left over
 *  from the older flat UI; we migrate those into a default group on load so
 *  they stay visible and editable.
 */
export function templateToForm(t: Template): WizardForm {
  const sortedFields = [...t.identityFields].sort((a, b) => a.displayOrder - b.displayOrder);
  const orphans = sortedFields.filter((f) => !(f.groupKey ?? '').trim());

  const rules = t.groupRules.map((r) => ({
    groupKey: r.groupKey,
    minRequired: r.minRequired,
    maxAllowed: r.maxAllowed ?? null,
    errorMessage: r.errorMessage,
  }));

  let defaultKey: string | null = null;
  if (orphans.length > 0) {
    const existing = new Set(rules.map((r) => r.groupKey));
    defaultKey = 'general';
    let n = 2;
    while (existing.has(defaultKey)) defaultKey = `general_${n++}`;
    rules.push({
      groupKey: defaultKey,
      minRequired: orphans.length,
      maxAllowed: null,
      errorMessage: '',
    });
  }

  return {
    companyName: t.companyName,
    insuranceType: t.insuranceType,
    name: t.name,
    claimantTypes: t.claimantTypes,
    requireIncidentDt: t.requireIncidentDt,
    requireLocation: t.requireLocation,
    minDescriptionLen: t.minDescriptionLen,
    identityFields: sortedFields.map((f) => ({
      fieldKey: f.fieldKey,
      label: f.label,
      promptText: f.promptText,
      placeholder: f.placeholder ?? '',
      validationRegex: f.validationRegex ?? '',
      groupKey: (f.groupKey ?? '').trim() || defaultKey || '',
      isSkippable: f.isSkippable,
      displayOrder: f.displayOrder,
    })),
    groupRules: rules,
    photoSettings: [...t.photoSettings]
      .sort((a, b) => a.displayOrder - b.displayOrder)
      .map((p) => ({
        groupKey: p.groupKey,
        label: p.label,
        instruction: p.instruction ?? '',
        minCount: p.minCount,
        maxCount: p.maxCount,
        isRequired: p.isRequired,
        allowedAngles: p.allowedAngles,
        sampleImageUrls: p.sampleImageUrls,
        showSample: p.showSample,
        maxFileSizeMb: p.maxFileSizeMb,
        allowedMimeTypes: p.allowedMimeTypes,
        displayOrder: p.displayOrder,
      })),
    documentSettings: [...t.documentSettings]
      .sort((a, b) => a.displayOrder - b.displayOrder)
      .map((d) => ({
        docKey: d.docKey,
        label: d.label,
        instruction: d.instruction ?? '',
        minCount: d.minCount,
        maxCount: d.maxCount,
        isRequired: d.isRequired,
        maxFileSizeMb: d.maxFileSizeMb,
        allowedMimeTypes: d.allowedMimeTypes,
        displayOrder: d.displayOrder,
      })),
  };
}

/**
 * Normalize form values for submission: re-index displayOrder from array
 * position, blank-to-null for optional strings, handle optional maxAllowed.
 */
export function normalizeWizardForm(v: WizardForm): WizardForm {
  return {
    ...v,
    identityFields: v.identityFields.map((f, i) => ({
      ...f,
      // Prompt text and placeholder are no longer UI inputs — fall back to the
      // label so the chatbot still has something conversational to say, but
      // preserve any pre-existing prompt typed on older records.
      promptText: f.promptText && f.promptText.trim() ? f.promptText : f.label,
      placeholder: f.placeholder || null,
      validationRegex: f.validationRegex || null,
      groupKey: f.groupKey ? f.groupKey : null,
      displayOrder: i + 1,
    })),
    groupRules: v.groupRules.map((r) => ({
      ...r,
      maxAllowed: r.maxAllowed === undefined ? null : r.maxAllowed,
      // Error message is optional in the UI; synthesize a generic one when
      // blank so the chatbot still has something to say on rule violation.
      errorMessage: r.errorMessage && r.errorMessage.trim()
        ? r.errorMessage
        : `A minimum of ${r.minRequired} entr${r.minRequired === 1 ? 'y' : 'ies'} from the "${r.groupKey}" group is required.`,
    })),
    photoSettings: v.photoSettings.map((p, i) => ({
      ...p,
      instruction: p.instruction || null,
      displayOrder: i + 1,
    })),
    documentSettings: v.documentSettings.map((d, i) => ({
      ...d,
      instruction: d.instruction || null,
      displayOrder: i + 1,
    })),
  };
}
