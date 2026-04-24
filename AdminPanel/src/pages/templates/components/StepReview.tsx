import { useFormContext } from 'react-hook-form';
import type { WizardForm } from './wizardTypes';

const claimantLabel: Record<string, string> = {
  PolicyHolder: 'Policy Holder',
  ThirdParty: 'Third Party',
};

export default function StepReview() {
  const { getValues } = useFormContext<WizardForm>();
  const v = getValues();

  return (
    <div className="space-y-5">
      <Section id="review-basic" title="Basic Info">
        <Row label="Company" value={v.companyName} />
        <Row label="Insurance Type" value={v.insuranceType} />
        <Row label="Template Name" value={v.name} />
        <Row label="Min Description Length" value={String(v.minDescriptionLen)} />
        <Row label="Require Incident Date/Time" value={v.requireIncidentDt ? 'Yes' : 'No'} />
        <Row label="Require Location" value={v.requireLocation ? 'Yes' : 'No'} />
        <Row
          label="Claimant Types"
          value={v.claimantTypes.map((c) => claimantLabel[c] ?? c).join(', ')}
        />
      </Section>

      <Section id="review-identity" title={`Identity Fields (${v.identityFields.length})`}>
        {v.identityFields.length === 0 ? (
          <p className="text-sm text-gray-400 italic">No identity fields.</p>
        ) : (
          <ul className="text-sm space-y-1">
            {v.identityFields.map((f, i) => (
              <li key={i} className="text-gray-700">
                <span className="font-mono text-xs text-primary">{f.fieldKey}</span>{' '}
                <span className="text-gray-600">· {f.label}</span>
                {f.groupKey && (
                  <span className="ml-1 text-xs text-gray-500">
                    [group: {f.groupKey}]
                  </span>
                )}
                {f.isSkippable && <span className="ml-1 text-xs text-gray-500">[skippable]</span>}
              </li>
            ))}
          </ul>
        )}
      </Section>

      <Section id="review-rules" title={`Group Rules (${v.groupRules.length})`}>
        {v.groupRules.length === 0 ? (
          <p className="text-sm text-gray-400 italic">No group rules.</p>
        ) : (
          <ul className="text-sm space-y-1">
            {v.groupRules.map((r, i) => (
              <li key={i} className="text-gray-700">
                <span className="font-mono text-xs text-primary">{r.groupKey}</span> · min{' '}
                {r.minRequired}
                {r.maxAllowed != null ? `, max ${r.maxAllowed}` : ''}
              </li>
            ))}
          </ul>
        )}
      </Section>

      <Section id="review-photos" title={`Photo Settings (${v.photoSettings.length})`}>
        {v.photoSettings.length === 0 ? (
          <p className="text-sm text-gray-400 italic">No photo requirements.</p>
        ) : (
          <ul className="text-sm space-y-1">
            {v.photoSettings.map((p, i) => (
              <li key={i} className="text-gray-700">
                <span className="font-mono text-xs text-primary">{p.groupKey}</span> · {p.label} ·{' '}
                {p.minCount}–{p.maxCount} · {p.isRequired ? 'required' : 'optional'}
                {p.allowedAngles.length > 0 && (
                  <span className="ml-1 text-xs text-gray-500">
                    [angles: {p.allowedAngles.join(', ')}]
                  </span>
                )}
              </li>
            ))}
          </ul>
        )}
      </Section>

      <Section id="review-docs" title={`Document Settings (${v.documentSettings.length})`}>
        {v.documentSettings.length === 0 ? (
          <p className="text-sm text-gray-400 italic">No document requirements.</p>
        ) : (
          <ul className="text-sm space-y-1">
            {v.documentSettings.map((d, i) => (
              <li key={i} className="text-gray-700">
                <span className="font-mono text-xs text-primary">{d.docKey}</span> · {d.label} ·{' '}
                {d.minCount}–{d.maxCount} · {d.isRequired ? 'required' : 'optional'}
              </li>
            ))}
          </ul>
        )}
      </Section>
    </div>
  );
}

function Section({ id, title, children }: { id: string; title: string; children: React.ReactNode }) {
  return (
    <section id={id} className="bg-white border border-gray-200 rounded-xl p-4 scroll-mt-4">
      <h4 className="text-sm font-semibold text-secondary mb-3">{title}</h4>
      {children}
    </section>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between text-sm py-1">
      <span className="text-gray-500">{label}</span>
      <span className="text-gray-800 font-medium text-right">{value}</span>
    </div>
  );
}
