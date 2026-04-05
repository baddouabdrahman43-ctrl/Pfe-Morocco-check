/**
 * Application constants and configuration values
 * 
 * This module exports all the constant values used throughout the
 * MoroccoCheck application, including user roles, statuses, ranks,
 * site statuses, check-in statuses, point values, and GPS validation
 * parameters.
 */

/**
 * User role constants for role-based access control
 * Defines the hierarchy of user permissions in the application
 */
export const USER_ROLES = {
  TOURIST: 'TOURIST',           // Basic user with limited permissions
  CONTRIBUTOR: 'CONTRIBUTOR',   // Can contribute content
  PROFESSIONAL: 'PROFESSIONAL', // Professional user with enhanced features
  ADMIN: 'ADMIN'                // Full administrative access
};

/**
 * User status constants for account lifecycle management
 * Controls user account availability and access
 */
export const USER_STATUS = {
  ACTIVE: 'ACTIVE',         // User can access all features
  INACTIVE: 'INACTIVE',     // User account is temporarily inactive
  SUSPENDED: 'SUSPENDED',   // User account is suspended
  BANNED: 'BANNED'          // User account is permanently banned
};

/**
 * User rank constants based on accumulated points
 * Represents user achievement levels in the application
 */
export const USER_RANKS = {
  BRONZE: 'BRONZE',     // Entry level rank
  SILVER: 'SILVER',     // Intermediate rank
  GOLD: 'GOLD',         // Advanced rank
  PLATINUM: 'PLATINUM'  // Highest rank
};

/**
 * Point threshold constants for user rank progression
 * Defines the minimum points required for each rank level
 */
export const RANK_THRESHOLDS = {
  BRONZE: 0,      // 0+ points for Bronze rank
  SILVER: 100,    // 100+ points for Silver rank
  GOLD: 500,      // 500+ points for Gold rank
  PLATINUM: 2000  // 2000+ points for Platinum rank
};

/**
 * Site status constants for content lifecycle management
 * Controls the visibility and availability of tourist sites
 */
export const SITE_STATUS = {
  DRAFT: 'DRAFT',               // Site is being created/edited
  PENDING_REVIEW: 'PENDING_REVIEW', // Site awaiting moderation approval
  PUBLISHED: 'PUBLISHED',       // Site is live and visible to users
  ARCHIVED: 'ARCHIVED'          // Site is archived and hidden
};

/**
 * Check-in status constants for site availability tracking
 * Indicates the current operational status of a tourist site
 */
export const CHECKIN_STATUS = {
  OPEN: 'OPEN',                     // Site is open for visitors
  CLOSED: 'CLOSED',                 // Site is temporarily closed
  UNDER_CONSTRUCTION: 'UNDER_CONSTRUCTION' // Site is under renovation/construction
};

/**
 * Point value constants for user activities
 * Defines the reward points users earn for different actions
 */
export const POINTS = {
  CHECKIN: 10,              // Points for basic check-in
  CHECKIN_WITH_PHOTO: 15,   // Points for check-in with photo upload
  REVIEW: 15,               // Points for writing a review
  PHOTO: 5                  // Points for uploading a photo
};

/**
 * GPS validation constants for location-based features
 * Controls the accuracy and distance requirements for GPS validation
 */
export const GPS_VALIDATION = {
  MAX_DISTANCE: 100,  // Default maximum distance in meters for valid check-in
  MIN_ACCURACY: 50,   // Maximum accepted GPS accuracy error in meters
  STRICT_ACCURACY: 35,
  DEFAULT_MIN_VISIT_DURATION_SECONDS: 15,
  DYNAMIC_DISTANCE_RULES: {
    strict: 60,
    standard: 100,
    relaxed: 140
  }
};
