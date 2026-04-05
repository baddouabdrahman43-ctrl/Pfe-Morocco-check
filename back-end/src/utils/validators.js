import Joi from "joi";

const mediaReferenceSchema = Joi.string()
  .trim()
  .custom((value, helpers) => {
    if (!value) {
      return value;
    }

    if (value.startsWith('/uploads/')) {
      return value;
    }

    try {
      const parsed = new URL(value);
      if (parsed.protocol === 'http:' || parsed.protocol === 'https:') {
        return value;
      }
    } catch (_error) {
    }

    return helpers.error('string.uri');
  }, 'media reference validation');

export const registerSchema = Joi.object({
  first_name: Joi.string().trim().min(2).max(100).required(),
  last_name: Joi.string().trim().min(2).max(100).required(),
  email: Joi.string().trim().email().required(),
  password: Joi.string().min(6).required(),
});

export const loginSchema = Joi.object({
  email: Joi.string().trim().email().required(),
  password: Joi.string().required(),
  device_info: Joi.object().optional(),
});

export const googleAuthSchema = Joi.object({
  id_token: Joi.string().trim().required(),
  device_info: Joi.object().optional(),
});

export const updateProfileSchema = Joi.object({
  first_name: Joi.string().trim().min(2).max(100).optional(),
  last_name: Joi.string().trim().min(2).max(100).optional(),
  email: Joi.string().trim().email().optional(),
  profile_picture: mediaReferenceSchema.allow("").optional(),
  phone_number: Joi.string()
    .pattern(/^[+]?[0-9]{8,15}$/)
    .allow("")
    .optional(),
  bio: Joi.string().max(1000).allow("").optional(),
  nationality: Joi.string().length(2).allow("").optional(),
});

export const contributorRequestCreateSchema = Joi.object({
  motivation: Joi.string().trim().min(20).max(1500).required(),
});

export const siteCreateSchema = Joi.object({
  name: Joi.string().trim().min(2).max(255).required(),
  name_ar: Joi.string().trim().max(255).allow("").optional(),
  description: Joi.string().max(4000).allow("").optional(),
  description_ar: Joi.string().max(4000).allow("").optional(),
  category_id: Joi.number().integer().positive().required(),
  subcategory: Joi.string().trim().max(100).allow("").optional(),
  latitude: Joi.number().min(27).max(36).required(),
  longitude: Joi.number().min(-13).max(-1).required(),
  address: Joi.string().max(500).allow("").optional(),
  city: Joi.string().max(100).allow("").optional(),
  region: Joi.string().max(100).allow("").optional(),
  postal_code: Joi.string().max(20).allow("").optional(),
  country: Joi.string().length(2).default("MA"),
  phone_number: Joi.string().max(20).allow("").optional(),
  email: Joi.string().email().allow("").optional(),
  website: Joi.string().uri().allow("").optional(),
  price_range: Joi.string()
    .valid("BUDGET", "MODERATE", "EXPENSIVE", "LUXURY")
    .optional(),
  accepts_card_payment: Joi.boolean().optional(),
  has_wifi: Joi.boolean().optional(),
  has_parking: Joi.boolean().optional(),
  is_accessible: Joi.boolean().optional(),
  amenities: Joi.array().items(Joi.string()).optional(),
  cover_photo: mediaReferenceSchema.allow("").optional(),
  status: Joi.string()
    .valid("DRAFT", "PENDING_REVIEW", "PUBLISHED", "ARCHIVED", "REPORTED")
    .optional(),
});

export const siteUpdateSchema = siteCreateSchema.fork(
  ["name", "category_id", "latitude", "longitude"],
  (schema) => schema.optional(),
);

export const checkinSchema = Joi.object({
  site_id: Joi.number().integer().positive().required(),
  status: Joi.string()
    .valid(
      "OPEN",
      "CLOSED",
      "UNDER_CONSTRUCTION",
      "CLOSED_TEMPORARILY",
      "CLOSED_PERMANENTLY",
      "RENOVATING",
      "RELOCATED",
      "NO_CHANGE",
    )
    .required(),
  comment: Joi.string().max(1000).allow("").optional(),
  latitude: Joi.number().min(27).max(36).required(),
  longitude: Joi.number().min(-13).max(-1).required(),
  accuracy: Joi.number().min(0).max(200).default(20),
  has_photo: Joi.boolean().default(false),
  device_info: Joi.object({
    is_mocked_location: Joi.boolean().optional(),
    visit_duration_seconds: Joi.number().integer().min(0).max(86400).optional(),
    collected_offline: Joi.boolean().optional(),
    queued_at: Joi.date().iso().optional(),
    synced_at: Joi.date().iso().optional(),
    app_platform: Joi.string().max(50).allow("").optional(),
    app_version: Joi.string().max(50).allow("").optional(),
  })
    .unknown(true)
    .optional(),
});

export const reviewSchema = Joi.object({
  site_id: Joi.number().integer().positive().required(),
  rating: Joi.number().min(1).max(5).required(),
  service_rating: Joi.number().min(1).max(5).optional(),
  cleanliness_rating: Joi.number().min(1).max(5).optional(),
  value_rating: Joi.number().min(1).max(5).optional(),
  location_rating: Joi.number().min(1).max(5).optional(),
  title: Joi.string().trim().max(255).allow("").optional(),
  content: Joi.string().min(20).max(4000).required(),
  visit_date: Joi.date().max("now").optional(),
  visit_type: Joi.string()
    .valid("BUSINESS", "COUPLE", "FAMILY", "FRIENDS", "SOLO")
    .optional(),
  recommendations: Joi.array().items(Joi.string()).optional(),
});

export const reviewUpdateSchema = Joi.object({
  rating: Joi.number().min(1).max(5).optional(),
  service_rating: Joi.number().min(1).max(5).allow(null).optional(),
  cleanliness_rating: Joi.number().min(1).max(5).allow(null).optional(),
  value_rating: Joi.number().min(1).max(5).allow(null).optional(),
  location_rating: Joi.number().min(1).max(5).allow(null).optional(),
  title: Joi.string().trim().max(255).allow("").optional(),
  content: Joi.string().min(20).max(4000).optional(),
  visit_date: Joi.date().max("now").allow(null).optional(),
  visit_type: Joi.string()
    .valid("BUSINESS", "COUPLE", "FAMILY", "FRIENDS", "SOLO")
    .allow(null)
    .optional(),
  recommendations: Joi.array().items(Joi.string()).allow(null).optional(),
});

export const reviewOwnerResponseSchema = Joi.object({
  response: Joi.string().trim().min(5).max(1500).required(),
});

export const adminSiteReviewSchema = Joi.object({
  action: Joi.string().valid("APPROVE", "REJECT", "ARCHIVE").required(),
  notes: Joi.string().max(1000).allow("").optional(),
});

export const adminReviewModerationSchema = Joi.object({
  action: Joi.string().valid("APPROVE", "REJECT", "FLAG", "SPAM").required(),
  notes: Joi.string().max(1000).allow("").optional(),
});

export const userStatusUpdateSchema = Joi.object({
  status: Joi.string()
    .valid("ACTIVE", "INACTIVE", "SUSPENDED", "BANNED", "PENDING_VERIFICATION")
    .required(),
});

export const userRoleUpdateSchema = Joi.object({
  role: Joi.string()
    .valid("ADMIN", "PROFESSIONAL", "CONTRIBUTOR", "TOURIST")
    .required(),
});

export const contributorRequestReviewSchema = Joi.object({
  action: Joi.string().valid("APPROVE", "REJECT").required(),
  admin_notes: Joi.string().max(1500).allow("").optional(),
});

export const refreshTokenSchema = Joi.object({
  refresh_token: Joi.string().trim().required(),
});

export const updatePasswordSchema = Joi.object({
  current_password: Joi.string().required(),
  new_password: Joi.string().min(6).required(),
});

export function validateRequest(
  schema,
  data,
  options = { abortEarly: false, stripUnknown: true },
) {
  const result = schema.validate(data, options);
  return {
    error: result.error,
    value: result.value,
  };
}
