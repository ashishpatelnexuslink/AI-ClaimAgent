import { useFormContext, Controller } from 'react-hook-form';
import type { WizardForm } from './wizardTypes';
import { CLAIMANT_TYPES, INSURANCE_TYPES } from '../../../types';

interface Props {
  isCreate: boolean;
  version?: number;
}

const claimantLabel: Record<string, string> = {
  PolicyHolder: 'Policy Holder',
  ThirdParty: 'Third Party',
};

export default function StepBasicInfo({ isCreate, version }: Props) {
  const {
    register,
    control,
    formState: { errors },
  } = useFormContext<WizardForm>();

  return (
    <div className="space-y-5">
      <div className="grid grid-cols-2 gap-4">
        <Field label="Template Name" required error={errors.name?.message}>
          <input
            type="text"
            {...register('name', {
              required: 'Template name is required',
              maxLength: { value: 200, message: 'Max 200 characters' },
            })}
            className="w-full px-3 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
            placeholder="Draudita Motor Comprehensive"
          />
        </Field>

        <Field label="Insurance Type" required error={errors.insuranceType?.message}>
          <select
            disabled={!isCreate}
            {...register('insuranceType', { required: 'Insurance type is required' })}
            className="w-full px-3 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary disabled:bg-gray-50 disabled:text-gray-500"
          >
            {INSURANCE_TYPES.map((t) => (
              <option key={t} value={t}>
                {t}
              </option>
            ))}
          </select>
        </Field>
      </div>

      <Field label="Company Name" error={errors.companyName?.message}>
        <input
          type="text"
          disabled={!isCreate}
          {...register('companyName', {
            maxLength: { value: 200, message: 'Max 200 characters' },
          })}
          className="w-full px-3 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary disabled:bg-gray-50 disabled:text-gray-500"
          placeholder="Draudita Insurance"
        />
      </Field>

      <div className="grid grid-cols-2 gap-4">
        <Field
          label="Version"
          hint={isCreate ? 'Auto-assigned on save (max existing + 1).' : undefined}
        >
          <input
            type="text"
            value={isCreate ? 'auto' : version != null ? `v${version}` : 'current'}
            disabled
            className="w-full px-3 py-2 rounded-lg border border-gray-200 bg-gray-50 text-sm text-gray-500"
          />
        </Field>

        <Field label="Min Description Length" error={errors.minDescriptionLen?.message}>
          <input
            type="number"
            min={0}
            {...register('minDescriptionLen', {
              valueAsNumber: true,
              min: { value: 0, message: 'Must be >= 0' },
            })}
            className="w-full px-3 py-2 rounded-lg border border-gray-300 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary"
          />
        </Field>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <ToggleField
          label="Require Incident Date/Time"
          register={register('requireIncidentDt')}
        />
        <ToggleField label="Require Location" register={register('requireLocation')} />
      </div>

      <Field
        label="Allowed Claimant Types"
        required
        error={errors.claimantTypes?.message as string | undefined}
        hint="At least one must be selected."
      >
        <Controller
          control={control}
          name="claimantTypes"
          rules={{
            validate: (v) =>
              (v && v.length > 0) || 'Select at least one claimant type',
          }}
          render={({ field }) => (
            <div className="flex gap-3">
              {CLAIMANT_TYPES.map((ct) => {
                const checked = field.value?.includes(ct);
                return (
                  <label
                    key={ct}
                    className={`flex items-center gap-2 px-4 py-2 rounded-lg border cursor-pointer transition-colors ${
                      checked
                        ? 'border-primary bg-primary-light text-primary'
                        : 'border-gray-300 hover:border-gray-400'
                    }`}
                  >
                    <input
                      type="checkbox"
                      checked={checked ?? false}
                      onChange={(e) => {
                        const next = new Set(field.value ?? []);
                        if (e.target.checked) next.add(ct);
                        else next.delete(ct);
                        field.onChange(Array.from(next));
                      }}
                      className="h-4 w-4"
                    />
                    <span className="text-sm font-medium">{claimantLabel[ct]}</span>
                  </label>
                );
              })}
            </div>
          )}
        />
      </Field>
    </div>
  );
}

function Field({
  label,
  required,
  error,
  hint,
  children,
}: {
  label: string;
  required?: boolean;
  error?: string;
  hint?: string;
  children: React.ReactNode;
}) {
  return (
    <div>
      <label className="block text-sm font-medium text-gray-700 mb-1.5">
        {label} {required && <span className="text-danger">*</span>}
      </label>
      {children}
      {hint && !error && <p className="text-xs text-gray-500 mt-1">{hint}</p>}
      {error && <p className="text-xs text-danger mt-1">{error}</p>}
    </div>
  );
}

function ToggleField({
  label,
  register,
}: {
  label: string;
  register: ReturnType<ReturnType<typeof useFormContext<WizardForm>>['register']>;
}) {
  return (
    <label className="flex items-center justify-between px-3 py-2.5 rounded-lg border border-gray-300 bg-white cursor-pointer">
      <span className="text-sm font-medium text-gray-700">{label}</span>
      <input type="checkbox" {...register} className="h-4 w-4" />
    </label>
  );
}
