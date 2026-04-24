import type {
  InsuranceType,
  ClaimantType,
  CreateIdentityField,
  CreateGroupRule,
  CreatePhotoSetting,
  CreateDocumentSetting,
} from '../../../types';

export interface WizardForm {
  companyName: string;
  insuranceType: InsuranceType;
  name: string;
  claimantTypes: ClaimantType[];
  requireIncidentDt: boolean;
  requireLocation: boolean;
  minDescriptionLen: number;
  identityFields: CreateIdentityField[];
  groupRules: CreateGroupRule[];
  photoSettings: CreatePhotoSetting[];
  documentSettings: CreateDocumentSetting[];
}

export const defaultWizardValues: WizardForm = {
  companyName: '',
  insuranceType: 'Motor',
  name: '',
  claimantTypes: ['PolicyHolder'],
  requireIncidentDt: true,
  requireLocation: true,
  minDescriptionLen: 40,
  identityFields: [],
  groupRules: [],
  photoSettings: [],
  documentSettings: [],
};

export const WIZARD_STEPS = [
  'Basic Info',
  'Identity Fields',
  'Photo Settings',
  'Document Settings',
  'Review',
] as const;

// Fields that belong to each step — used for trigger() validation before Next.
export const stepFieldMap: Record<number, (keyof WizardForm)[]> = {
  0: ['companyName', 'insuranceType', 'name', 'claimantTypes', 'minDescriptionLen'],
  1: ['identityFields', 'groupRules'],
  2: ['photoSettings'],
  3: ['documentSettings'],
  4: [],
};
