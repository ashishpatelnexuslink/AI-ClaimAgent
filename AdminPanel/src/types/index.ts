// Server-native statuses (from ClaimStatus enum). The UI still renders
// "Under Review" for `InReview` — see STATUS_DISPLAY.
export type ClaimStatus =
  | 'Draft'
  | 'Pending'
  | 'Submitted'
  | 'InReview'
  | 'Approved'
  | 'Rejected'
  | 'Closed';

export interface Claim {
  id: string;
  claimNumber: string;
  userId: string;
  userName: string;
  /** Free-text coming from the backend (e.g. "Vehicle Insurance Claim", "Accident"). */
  type: string;
  status: ClaimStatus;
  vehicleReg: string;
  incidentDate: string;
  submittedAt: string;
  updatedAt: string;
  incidentDescription?: string;
  incidentLocation?: string;
  photos?: string[];
  claimantType?: string;
  amount?: number;
}

export interface User {
  id: string;
  name: string;
  email: string;
  phone: string;
  country: string;
  avatarPersonality: 'Professional' | 'Friendly' | 'Smart';
  memberSince: string;
  totalClaims: number;
  status: 'Active' | 'Suspended';
  profileImage?: string;
}

export interface Conversation {
  id: string;
  threadId: string;
  userId: string;
  userName: string;
  mode: 'Voice' | 'Chat';
  startedAt: string;
  endedAt?: string;
  duration: number;
  messageCount: number;
  claimId?: string;
  status: 'Active' | 'Completed' | 'Abandoned';
  chatJsonPath?: string;
  messages: Message[];
}

export interface Message {
  id: string;
  type: 'bot' | 'user';
  content: string;
  timestamp: string;
  suggestions?: string[];
}

export interface DashboardStats {
  totalClaims: number;
  pendingClaims: number;
  approvedClaims: number;
  rejectedClaims: number;
  totalUsers: number;
  activeConversations: number;
  claimsToday: number;
  avgResolutionDays: number;
  totalClaimsDeltaPct?: number | null;
  approvedDeltaPct?: number | null;
  rejectedDeltaPct?: number | null;
}

export interface ClaimsByTypeItem {
  type: string;
  count: number;
}

export interface ClaimDocument {
  id: string;
  claimId?: string | null;
  fileName: string;
  url: string;
  contentType: string;
  fileSize: number;
  kind: string;
  category?: string | null;
  createdAt: string;
}

export interface ClaimsTrendData {
  date: string;
  submitted: number;
  approved: number;
  rejected: number;
}

export interface AdminUser {
  id: string;
  name: string;
  email: string;
  role: 'Super Admin' | 'Reviewer' | 'Viewer';
  status: 'Active' | 'Suspended';
}

export interface TimelineEvent {
  id: string;
  date: string;
  action: string;
  actor: string;
}

// ===== Templates =====

export type InsuranceType = 'Motor' | 'Health' | 'Home' | 'Travel' | 'Life';
export type TemplateStatus = 'Draft' | 'Active' | 'Archived';
export type ClaimantType = 'PolicyHolder' | 'ThirdParty';

export const INSURANCE_TYPES: InsuranceType[] = ['Motor', 'Health', 'Home', 'Travel', 'Life'];
export const TEMPLATE_STATUSES: TemplateStatus[] = ['Draft', 'Active', 'Archived'];
export const CLAIMANT_TYPES: ClaimantType[] = ['PolicyHolder', 'ThirdParty'];

export interface TemplateIdentityField {
  id: string;
  fieldKey: string;
  label: string;
  promptText: string;
  placeholder?: string | null;
  validationRegex?: string | null;
  groupKey?: string | null;
  isSkippable: boolean;
  displayOrder: number;
}

export interface TemplateFieldGroupRule {
  id: string;
  groupKey: string;
  minRequired: number;
  maxAllowed?: number | null;
  errorMessage: string;
}

export interface TemplatePhotoSetting {
  id: string;
  groupKey: string;
  label: string;
  instruction?: string | null;
  minCount: number;
  maxCount: number;
  isRequired: boolean;
  allowedAngles: string[];
  sampleImageUrls: string[];
  showSample: boolean;
  maxFileSizeMb: number;
  allowedMimeTypes: string[];
  displayOrder: number;
}

export interface TemplateDocumentSetting {
  id: string;
  docKey: string;
  label: string;
  instruction?: string | null;
  minCount: number;
  maxCount: number;
  isRequired: boolean;
  maxFileSizeMb: number;
  allowedMimeTypes: string[];
  displayOrder: number;
}

export interface Template {
  id: string;
  companyName: string;
  insuranceType: InsuranceType;
  name: string;
  version: number;
  status: TemplateStatus;
  claimantTypes: ClaimantType[];
  requireIncidentDt: boolean;
  requireLocation: boolean;
  minDescriptionLen: number;
  identityFields: TemplateIdentityField[];
  groupRules: TemplateFieldGroupRule[];
  photoSettings: TemplatePhotoSetting[];
  documentSettings: TemplateDocumentSetting[];
  createdAt: string;
  updatedAt?: string | null;
}

export interface TemplateListItem {
  id: string;
  companyName: string;
  insuranceType: InsuranceType;
  name: string;
  version: number;
  status: TemplateStatus;
  createdAt: string;
  updatedAt?: string | null;
}

// Write-side payloads

export interface CreateIdentityField {
  fieldKey: string;
  label: string;
  promptText: string;
  placeholder?: string | null;
  validationRegex?: string | null;
  groupKey?: string | null;
  isSkippable: boolean;
  displayOrder: number;
}

export interface CreateGroupRule {
  groupKey: string;
  minRequired: number;
  maxAllowed?: number | null;
  errorMessage: string;
}

export interface CreatePhotoSetting {
  groupKey: string;
  label: string;
  instruction?: string | null;
  minCount: number;
  maxCount: number;
  isRequired: boolean;
  allowedAngles: string[];
  sampleImageUrls: string[];
  showSample: boolean;
  maxFileSizeMb: number;
  allowedMimeTypes: string[];
  displayOrder: number;
}

export interface CreateDocumentSetting {
  docKey: string;
  label: string;
  instruction?: string | null;
  minCount: number;
  maxCount: number;
  isRequired: boolean;
  maxFileSizeMb: number;
  allowedMimeTypes: string[];
  displayOrder: number;
}

export interface CreateTemplatePayload {
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

export interface UpdateTemplatePayload {
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

export interface TemplateListQuery {
  companyName?: string;
  insuranceType?: InsuranceType;
  status?: TemplateStatus;
  pageNumber?: number;
  pageSize?: number;
}

export interface PagedResult<T> {
  items: T[];
  totalCount: number;
  pageNumber: number;
  pageSize: number;
  totalPages: number;
}
