import { useEffect, useState } from 'react';
import { useNavigate, useParams, Link } from 'react-router-dom';
import { FormProvider, useForm } from 'react-hook-form';
import { ArrowLeft } from 'lucide-react';
import Button from '../../components/ui/Button';
import Spinner from '../../components/ui/Spinner';
import WizardStepper from './components/WizardStepper';
import StepBasicInfo from './components/StepBasicInfo';
import StepIdentityFields from './components/StepIdentityFields';
import StepPhotoSettings from './components/StepPhotoSettings';
import StepDocumentSettings from './components/StepDocumentSettings';
import StepReview from './components/StepReview';
import {
  defaultWizardValues,
  stepFieldMap,
  WIZARD_STEPS,
  type WizardForm,
} from './components/wizardTypes';
import {
  useCreateTemplate,
  useUpdateTemplate,
  useActivateTemplate,
  useTemplate,
} from '../../hooks/useTemplates';
import { useToastContext } from '../../hooks/ToastContext';
import type {
  CreateIdentityField,
  CreateGroupRule,
  CreatePhotoSetting,
  CreateDocumentSetting,
} from '../../types';

interface Props {
  mode: 'create' | 'edit';
}

export default function TemplateFormPage({ mode }: Props) {
  const navigate = useNavigate();
  const { id } = useParams<{ id: string }>();
  const { addToast } = useToastContext();

  const isEdit = mode === 'edit';
  const { data: existing, isLoading: loadingExisting } = useTemplate(isEdit ? id : undefined);

  const createMut = useCreateTemplate();
  const updateMut = useUpdateTemplate();
  const activateMut = useActivateTemplate();

  const methods = useForm<WizardForm>({
    defaultValues: defaultWizardValues,
    mode: 'onBlur',
  });

  const [step, setStep] = useState(0);
  const [furthestReached, setFurthestReached] = useState(0);
  const [submitError, setSubmitError] = useState<string[] | null>(null);

  // Populate form when editing an existing template.
  useEffect(() => {
    if (!isEdit || !existing) return;
    methods.reset({
      companyName: existing.companyName,
      insuranceType: existing.insuranceType,
      name: existing.name,
      claimantTypes: existing.claimantTypes,
      requireIncidentDt: existing.requireIncidentDt,
      requireLocation: existing.requireLocation,
      minDescriptionLen: existing.minDescriptionLen,
      identityFields: [...existing.identityFields]
        .sort((a, b) => a.displayOrder - b.displayOrder)
        .map((f) => ({
          fieldKey: f.fieldKey,
          label: f.label,
          promptText: f.promptText,
          placeholder: f.placeholder ?? '',
          validationRegex: f.validationRegex ?? '',
          groupKey: f.groupKey ?? '',
          isSkippable: f.isSkippable,
          displayOrder: f.displayOrder,
        })),
      groupRules: existing.groupRules.map((r) => ({
        groupKey: r.groupKey,
        minRequired: r.minRequired,
        maxAllowed: r.maxAllowed ?? null,
        errorMessage: r.errorMessage,
      })),
      photoSettings: [...existing.photoSettings]
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
          maxFileSizeMb: p.maxFileSizeMb,
          allowedMimeTypes: p.allowedMimeTypes,
          displayOrder: p.displayOrder,
        })),
      documentSettings: [...existing.documentSettings]
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
    });
  }, [existing, isEdit, methods]);

  const goNext = async () => {
    const fields = stepFieldMap[step];
    const valid = fields.length === 0 ? true : await methods.trigger(fields);
    if (!valid) {
      addToast('Please fix the highlighted fields before continuing.', 'error');
      return;
    }
    const next = Math.min(step + 1, WIZARD_STEPS.length - 1);
    setStep(next);
    setFurthestReached((f) => Math.max(f, next));
  };

  const goBack = () => setStep((s) => Math.max(0, s - 1));

  const jumpTo = (i: number) => {
    if (i <= furthestReached) setStep(i);
  };

  // Normalize displayOrder from array index at submit time.
  const normalize = (v: WizardForm): WizardForm => ({
    ...v,
    identityFields: v.identityFields.map((f, i) => ({
      ...f,
      placeholder: f.placeholder || null,
      validationRegex: f.validationRegex || null,
      groupKey: f.groupKey ? f.groupKey : null,
      displayOrder: i + 1,
    })) as CreateIdentityField[],
    groupRules: v.groupRules.map((r) => ({
      ...r,
      maxAllowed: r.maxAllowed === undefined ? null : r.maxAllowed,
    })) as CreateGroupRule[],
    photoSettings: v.photoSettings.map((p, i) => ({
      ...p,
      instruction: p.instruction || null,
      displayOrder: i + 1,
    })) as CreatePhotoSetting[],
    documentSettings: v.documentSettings.map((d, i) => ({
      ...d,
      instruction: d.instruction || null,
      displayOrder: i + 1,
    })) as CreateDocumentSetting[],
  });

  const handleSubmit = async (andActivate: boolean) => {
    setSubmitError(null);
    const allValid = await methods.trigger();
    if (!allValid) {
      addToast('Please fix the highlighted errors.', 'error');
      return;
    }
    const values = normalize(methods.getValues());

    const onApiError = (err: unknown) => {
      // Backend returns { success, errors: string[] } in the envelope.
      const axiosErr = err as { response?: { data?: { errors?: string[]; message?: string } } };
      const errs = axiosErr?.response?.data?.errors;
      const msg = axiosErr?.response?.data?.message;
      if (errs && errs.length) setSubmitError(errs);
      else if (msg) setSubmitError([msg]);
      else setSubmitError(['Save failed. Please try again.']);
      addToast('Save failed', 'error');
    };

    if (isEdit && id) {
      const { companyName: _c, insuranceType: _t, ...updatePayload } = values;
      void _c;
      void _t;
      updateMut.mutate(
        { id, payload: updatePayload },
        {
          onSuccess: async (tpl) => {
            addToast('Template updated', 'success');
            if (andActivate) {
              activateMut.mutate(tpl.id, {
                onSuccess: () => {
                  addToast('Template activated', 'success');
                  navigate('/templates');
                },
                onError: onApiError,
              });
            } else {
              navigate('/templates');
            }
          },
          onError: onApiError,
        },
      );
    } else {
      createMut.mutate(values, {
        onSuccess: async (tpl) => {
          addToast('Template created', 'success');
          if (andActivate) {
            activateMut.mutate(tpl.id, {
              onSuccess: () => {
                addToast('Template activated', 'success');
                navigate('/templates');
              },
              onError: onApiError,
            });
          } else {
            navigate(`/templates/${tpl.id}/edit`);
          }
        },
        onError: onApiError,
      });
    }
  };

  if (isEdit && loadingExisting) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <Spinner size="lg" />
      </div>
    );
  }

  if (isEdit && !existing) {
    return (
      <div className="bg-card rounded-xl p-12 text-center">
        <p className="text-gray-500">Template not found.</p>
        <Link to="/templates" className="text-primary text-sm mt-3 inline-block">
          Back to list
        </Link>
      </div>
    );
  }

  const submitting = createMut.isPending || updateMut.isPending || activateMut.isPending;
  const isLastStep = step === WIZARD_STEPS.length - 1;

  return (
    <div className="space-y-5 max-w-5xl mx-auto">
      <div>
        <Link
          to="/templates"
          className="text-sm text-gray-500 hover:text-gray-700 inline-flex items-center gap-1"
        >
          <ArrowLeft size={14} /> Cancel
        </Link>
        <h1 className="text-2xl font-bold text-secondary mt-1">
          {isEdit ? `Edit Template${existing ? ` · ${existing.name}` : ''}` : 'New Template'}
        </h1>
      </div>

      <div className="bg-card rounded-xl p-5">
        <WizardStepper
          steps={[...WIZARD_STEPS]}
          currentIndex={step}
          furthestReached={furthestReached}
          onStepClick={jumpTo}
        />
      </div>

      <div className="bg-card rounded-xl p-6">
        <FormProvider {...methods}>
          <form onSubmit={(e) => e.preventDefault()}>
            <div className="space-y-6">
              {step === 0 && (
                <StepBasicInfo isCreate={!isEdit} version={existing?.version} />
              )}
              {step === 1 && <StepIdentityFields />}
              {step === 2 && <StepPhotoSettings />}
              {step === 3 && <StepDocumentSettings />}
              {step === 4 && <StepReview />}
            </div>
          </form>
        </FormProvider>
      </div>

      {submitError && (
        <div className="rounded-xl border border-danger bg-danger-light px-4 py-3">
          <p className="text-sm text-red-800 font-medium">Save failed:</p>
          <ul className="list-disc list-inside text-sm text-red-700 mt-1">
            {submitError.map((e, i) => (
              <li key={i}>{e}</li>
            ))}
          </ul>
        </div>
      )}

      <div className="flex items-center justify-between">
        <Button variant="outline" onClick={goBack} disabled={step === 0 || submitting}>
          Back
        </Button>
        <div className="flex gap-2">
          {!isLastStep && (
            <Button onClick={goNext} disabled={submitting}>
              Next
            </Button>
          )}
          {isLastStep && (
            <>
              <Button
                variant="outline"
                onClick={() => handleSubmit(false)}
                loading={createMut.isPending || updateMut.isPending}
                disabled={submitting}
              >
                {isEdit ? 'Save Draft' : 'Create Draft'}
              </Button>
              <Button
                variant="success"
                onClick={() => handleSubmit(true)}
                loading={activateMut.isPending || createMut.isPending || updateMut.isPending}
                disabled={submitting}
              >
                Save & Activate
              </Button>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
