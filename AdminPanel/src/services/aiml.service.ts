import axios from 'axios';
import type { ClaimantType, InsuranceType, Template } from '../types';

// NOTE: hardcoded to match the mobile app's AppConfig. Don't move the password
// into a `.env` file — Vite's dotenv-expand interprets `$zN8` as a variable
// reference and silently strips it, producing 401s at /auth/login.
const BASE_URL =
  (import.meta.env.VITE_AIML_BASE_URL as string) || 'https://aiagnetforclaim.nexuslink.co.in';
const LOGIN_PATH = (import.meta.env.VITE_AIML_LOGIN_PATH as string) || '/auth/login';
const CONFIG_PATH = (import.meta.env.VITE_AIML_CONFIG_PATH as string) || '/config';
const USERNAME = 'svc_claimbot_mobile_prod';
const PASSWORD = 'V9rQ2!mL7@tP4$zN8^wK3&x';

const aiml = axios.create({ baseURL: BASE_URL, timeout: 30000 });

let cachedToken: string | null = null;
let cachedTokenExpiresAt = 0;

const INSURANCE_INDEX: Record<InsuranceType, number> = {
  Motor: 0,
  Health: 1,
  Home: 2,
  Travel: 3,
  Life: 4,
};

const CLAIMANT_INDEX: Record<ClaimantType, number> = {
  PolicyHolder: 0,
  ThirdParty: 1,
};

function readJwtExpiryMs(token: string): number | null {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const payload = JSON.parse(atob(parts[1].replace(/-/g, '+').replace(/_/g, '/')));
    return typeof payload.exp === 'number' ? payload.exp * 1000 : null;
  } catch {
    return null;
  }
}

async function login(): Promise<string> {
  const { data } = await aiml.post<Record<string, unknown>>(LOGIN_PATH, {
    username: USERNAME,
    password: PASSWORD,
  });
  const token =
    (data.access_token as string) ||
    (data.accessToken as string) ||
    (data.token as string) ||
    (data.id_token as string);
  if (!token) throw new Error('AI/ML login response did not contain an access token.');
  cachedToken = token;
  cachedTokenExpiresAt = readJwtExpiryMs(token) ?? Date.now() + 55 * 60 * 1000;
  return token;
}

async function getToken(forceRefresh = false): Promise<string> {
  if (!forceRefresh && cachedToken && Date.now() < cachedTokenExpiresAt - 60_000) {
    return cachedToken;
  }
  return login();
}

function buildConfigBody(t: Template) {
  return {
    template: {
      template_id: t.id,
      company_name: t.companyName,
      insurance_type: INSURANCE_INDEX[t.insuranceType],
      name: t.name,
      version: t.version,
      claimant_types: t.claimantTypes.map((c) => CLAIMANT_INDEX[c]),
      require_incident_dt: t.requireIncidentDt,
      require_location: t.requireLocation,
      min_description_len: t.minDescriptionLen,
      identity_fields: [...t.identityFields]
        .sort((a, b) => a.displayOrder - b.displayOrder)
        .map((f) => ({
          field_key: f.fieldKey,
          label: f.label,
          prompt_text: f.promptText,
          placeholder: f.placeholder ?? null,
          validation_regex: f.validationRegex ?? null,
          group_key: f.groupKey ?? null,
          is_skippable: f.isSkippable,
          display_order: f.displayOrder,
        })),
      group_rules: t.groupRules.map((r) => ({
        group_key: r.groupKey,
        min_required: r.minRequired,
        max_allowed: r.maxAllowed ?? null,
        error_message: r.errorMessage,
      })),
      photo_settings: [...t.photoSettings]
        .sort((a, b) => a.displayOrder - b.displayOrder)
        .map((p) => ({
          group_key: p.groupKey,
          label: p.label,
          instruction: p.instruction ?? null,
          min_count: p.minCount,
          max_count: p.maxCount,
          is_required: p.isRequired,
          allowed_angles: p.allowedAngles,
          sample_image_urls: p.sampleImageUrls,
          max_file_size_mb: p.maxFileSizeMb,
          allowed_mime_types: p.allowedMimeTypes,
          display_order: p.displayOrder,
        })),
      document_settings: [...t.documentSettings]
        .sort((a, b) => a.displayOrder - b.displayOrder)
        .map((d) => ({
          doc_key: d.docKey,
          label: d.label,
          instruction: d.instruction ?? null,
          min_count: d.minCount,
          max_count: d.maxCount,
          is_required: d.isRequired,
          max_file_size_mb: d.maxFileSizeMb,
          allowed_mime_types: d.allowedMimeTypes,
          display_order: d.displayOrder,
        })),
    },
  };
}

export const aimlService = {
  /**
   * Logs into the AI/ML agent (caching the bearer token in-memory) and pushes
   * the activated template to its `/config` endpoint. Retries once on 401 with
   * a freshly-issued token.
   */
  async syncTemplateConfig(template: Template): Promise<void> {
    const body = buildConfigBody(template);

    const post = async (token: string) =>
      aiml.post(CONFIG_PATH, body, {
        headers: { Authorization: `Bearer ${token}` },
        validateStatus: () => true,
      });

    let token = await getToken(false);
    let response = await post(token);

    if (response.status === 401) {
      token = await getToken(true);
      response = await post(token);
    }

    if (response.status < 200 || response.status >= 300) {
      throw new Error(
        `AI/ML /config failed (${response.status}): ${
          typeof response.data === 'string' ? response.data : JSON.stringify(response.data)
        }`,
      );
    }
  },
};
