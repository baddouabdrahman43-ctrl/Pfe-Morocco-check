# UI/UX IMPROVEMENT PLAN - App_Touriste

## SECTION 1 - Global Problems

### 1. Hardcoded colors instead of theme
- What is wrong:
  `AppTheme.lightTheme` already defines `AppBarTheme` at `front-end/lib/core/theme/app_theme.dart:21-28`, button themes at `:75-98`, and card theme at `:106-114`, but many screens bypass them with direct `Colors.*`, custom gradients, and local `styleFrom`.
- Which screens are affected:
  `front-end/lib/features/auth/presentation/login_screen.dart`, `front-end/lib/features/auth/presentation/register_screen.dart`, `front-end/lib/features/sites/presentation/site_detail_screen.dart`, `front-end/lib/features/sites/presentation/add_review_screen.dart`, `front-end/lib/features/sites/presentation/checkin_screen.dart`, `front-end/lib/features/profile/presentation/profile_screen.dart`, `front-end/lib/features/profile/presentation/leaderboard_screen.dart`, `front-end/lib/features/profile/presentation/badges_catalog_screen.dart`, `front-end/lib/features/professional/presentation/professional_site_detail_screen.dart`, `front-end/lib/features/sites/presentation/widgets/review_card.dart`, `front-end/lib/features/sites/presentation/widgets/site_detail_sections.dart`.
- Exact fix to apply:
  Replace local `backgroundColor`, `foregroundColor`, `Colors.amber`, `Colors.grey`, and `ElevatedButton.styleFrom` / `OutlinedButton.styleFrom` calls with `Theme.of(context).colorScheme`, `Theme.of(context).appBarTheme`, shared semantic colors in `AppColors`, and shared widget variants. Start with `login_screen.dart:184-187`, `register_screen.dart:281-346`, `site_detail_screen.dart:208-222`, `add_review_screen.dart:265-268`, `checkin_screen.dart:425-440`, and `profile_screen.dart:209-212`.
- Effort: ~8h

### 2. Inconsistent spacing and radius scale
- What is wrong:
  The app mixes `8`, `10`, `12`, `14`, `16`, `18`, `20`, `22`, `24`, `30`, `32`, and `999` directly in almost every screen, so cards and fields never feel part of one system.
- Which screens are affected:
  All screens, with the largest drift in `login_screen.dart`, `register_screen.dart`, `sites_list_screen.dart`, `profile_screen.dart`, `professional_site_detail_screen.dart`, and `site_card.dart`.
- Exact fix to apply:
  Add a spacing/radius token file under `front-end/lib/core/theme/` and replace direct `EdgeInsets` / `BorderRadius.circular(...)` values screen by screen. Normalize forms to the theme radius `18`, cards to `24`, chips to `999`, and section gaps to a 8/12/16/24 scale. Start with `login_screen.dart:101-249`, `register_screen.dart:131-346`, `site_card.dart:51-376`, and `settings_screen.dart:334-595`.
- Effort: ~10h

### 3. Missing empty states on list and history screens
- What is wrong:
  Several screens show text-only empty states or no recovery CTA, so the user reaches a dead end.
- Which screens are affected:
  `my_checkins_screen.dart:195-207`, `my_reviews_screen.dart:438-444`, `professional_sites_screen.dart:147-166`, `badges_catalog_screen.dart:92-99`, `leaderboard_screen.dart:253-321`, `public_user_profile_screen.dart:174-194`, `site_detail_sections.dart:300-322`.
- Exact fix to apply:
  Extract one shared `EmptyStateWidget` into `front-end/lib/shared/widgets/` with icon, title, message, and optional primary/secondary buttons. Add "Explorer des lieux" CTA to `_buildEmptyState()` in `my_checkins_screen.dart:469-497` and `my_reviews_screen.dart:759-787`, and add "Ajouter un etablissement" CTA to the empty block in `professional_sites_screen.dart:147-166`.
- Effort: ~5h

### 4. Missing loading states on async actions
- What is wrong:
  Most async pages still fall back to a plain centered spinner, even when the layout is rich enough to deserve skeletons or inline loading placeholders.
- Which screens are affected:
  `settings_screen.dart:323-325`, `public_user_profile_screen.dart:56-63`, `badges_catalog_screen.dart:56-61`, `leaderboard_screen.dart:76-80`, `my_checkins_screen.dart:183-184`, `my_reviews_screen.dart:426-427`, `professional_site_detail_screen.dart:150-153`, `sites_list_screen.dart:219-221`, `site_detail_sections.dart:300-304`.
- Exact fix to apply:
  Add a shared `LoadingSkeleton` and swap every `Center(child: CircularProgressIndicator())` on collection/detail pages with content-shaped placeholders. Keep button-level loaders where they already exist, but add inline disabled state text for `_isLoadingMore` blocks in `my_checkins_screen.dart:210-214` and `my_reviews_screen.dart:447-451`.
- Effort: ~6h

### 5. Wrong button variants are used for the wrong action weight
- What is wrong:
  Secondary and destructive actions often use the same visual weight as the main CTA, and several screens restyle buttons locally instead of relying on the theme.
- Which screens are affected:
  `site_detail_screen.dart:390-416`, `my_reviews_screen.dart:724-751`, `professional_sites_screen.dart:287-304`, `professional_site_detail_screen.dart:325-333`, `checkin_sections.dart:220-233`, `login_screen.dart:184-249`, `register_screen.dart:281-346`.
- Exact fix to apply:
  Use one dominant `ElevatedButton` per screen, demote supporting actions to `OutlinedButton` or `TextButton`, and move destructive actions into confirmation dialogs or menus. Remove the redundant `Voir la fiche` text button in `professional_sites_screen.dart:287-293` because the full card is already tappable, and replace the three peer buttons in `my_reviews_screen.dart:724-751` with one visible primary action plus an overflow menu.
- Effort: ~7h

### 6. Inconsistent AppBar usage
- What is wrong:
  The theme defines a light surface AppBar, but some screens force a green AppBar with white text while others keep the default. The auth flow is also inconsistent because `RegisterScreen` has an AppBar and `LoginScreen` does not.
- Which screens are affected:
  `profile_screen.dart:209-212`, `site_detail_screen.dart:208-222` and `:261-265`, `add_review_screen.dart:265-268`, `checkin_screen.dart:425-440`, `checkin_detail_screen.dart:105-108`, `checkin_photo_gallery_screen.dart:47-52`, `register_screen.dart:98`, `login_screen.dart`.
- Exact fix to apply:
  Standardize on the themed AppBar for standard screens and reserve immersive dark AppBars only for full-screen media (`checkin_photo_gallery_screen.dart`). Remove local AppBar color overrides from profile, review, check-in, and site detail pages; then align `LoginScreen` and `RegisterScreen` under one shared auth shell.
- Effort: ~4h

### 7. Text encoding and copy inconsistencies
- What is wrong:
  Several strings render as mojibake (`biomÃ©trique`, `Â·`, `â€¢`) and the splash subtitle is in English and about food safety, not tourism.
- Which screens are affected:
  `settings_screen.dart:420-424`, `professional_sites_screen.dart:243`, `professional_site_detail_screen.dart:278` and `:318`, `public_user_profile_screen.dart:122`, `badges_catalog_screen.dart:195`, `leaderboard_screen.dart:396`, `sites_list_screen.dart:1021-1024`, `site_detail_sections.dart:459`, `checkin_detail_screen.dart:442`, `splash_screen.dart:72`.
- Exact fix to apply:
  Replace corrupted separators with ASCII `" - "` or a shared bullet formatter, reuse localized copy from `front-end/lib/l10n/*.arb`, and rewrite the splash subtitle in the product language. Do this before any UI polish because the broken text damages trust on first read.
- Effort: ~3h

### 8. Duplicate local components instead of a shared UI kit
- What is wrong:
  The codebase already has `front-end/lib/shared/widgets/custom_button.dart` and `custom_textfield.dart`, but they are not used, while multiple screens re-implement chips, status pills, cards, and dialogs.
- Which screens are affected:
  `sites_list_screen.dart`, `site_card.dart`, `site_detail_sections.dart`, `my_checkins_screen.dart`, `my_reviews_screen.dart`, `professional_sites_screen.dart`, `professional_site_detail_screen.dart`, `badges_catalog_screen.dart`, `leaderboard_screen.dart`, `settings_screen.dart`, `profile_screen.dart`.
- Exact fix to apply:
  Extract a real shared widget set into `front-end/lib/shared/widgets/` and refactor the screens to consume it. Start with `SitePreviewCard`, `StatusChip`, `EmptyStateWidget`, `LoadingSkeleton`, `SectionHeader`, and `ConfirmationDialog`.
- Effort: ~12h

## SECTION 2 - Screen by Screen

### SplashScreen
**File:** `front-end/lib/splash/splash_screen.dart`  
**Actor:** Visiteur / TOURIST / CONTRIBUTOR / PROFESSIONAL / ADMIN

**What is currently on this screen:**  
A centered logo circle, app name, English subtitle, and spinner are shown for a fixed 2-second delay before auto-login redirects.

**Problems:**
- The subtitle text at `splash_screen.dart:72` says `"Your Trusted Food Safety Companion"`, which does not match the tourism product.
- The white `Scaffold` background at `:31` ignores the app visual system and feels disconnected from the rest of the onboarding flow.
- The user gets a passive wait state only; `_checkAuthAndNavigate()` always waits 2 seconds even when auth is already ready.

**What to remove or hide:**
- Remove the subtitle at `splash_screen.dart:72` and replace it with one short status line tied to auth/loading.

**What to simplify:**
- Keep only logo, app name, and one progress label; remove the extra empty vertical space created by `SizedBox(height: 32)` and `SizedBox(height: 48)`.

**Primary action fix:**
- Before: there is no visible next step, only a spinner.
- After: show a single status message such as "Connexion en cours..." and shorten the enforced delay to the minimum needed for branding.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Subtitle | English product mismatch at `:72` | One tourism-specific loading line tied to auth |
| Layout | White static screen with long wait | Branded splash with shorter, clearer transition |

**Effort:** ~1.5h

### WelcomeScreen
**File:** `front-end/lib/features/auth/presentation/welcome_screen.dart`  
**Actor:** Visiteur

**What is currently on this screen:**  
A marketing page shows a large hero, three highlight chips, two feature cards, and three entry actions: register, login, and guest mode.

**Problems:**
- The first fold is text-heavy because `_HeroPanel`, the chip `Wrap`, and two `_FeatureCard`s all appear before the user acts.
- The hardcoded hero stats at `welcome_screen.dart:154-161` look like product facts but are not connected to live data.
- The screen mixes brochure content and onboarding action, so the CTA competes with explanatory blocks.

**What to remove or hide:**
- Hide the `_HeroStat` row in `_HeroPanel` and keep only one `_FeatureCard` below the CTA.

**What to simplify:**
- Move the highlight chip `Wrap` at `welcome_screen.dart:50-63` under the main CTA or fold it into one short "Pourquoi utiliser l'app" section.

**Primary action fix:**
- Before: register is primary, but two large content sections weaken urgency.
- After: keep `Creer mon compte` as the only above-the-fold dominant action and move secondary explanation below login.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Above the fold | Hero + chips + 2 feature cards | Hero + one CTA + login link |
| Credibility stats | Hardcoded labels | Removed until real metrics are available |

**Effort:** ~3h

### LoginScreen
**File:** `front-end/lib/features/auth/presentation/login_screen.dart`  
**Actor:** Visiteur

**What is currently on this screen:**  
A centered form shows brand title, subtitle, email field, password field, inline error box, login button, optional Google button, and a register link.

**Problems:**
- The form bypasses the theme with `OutlineInputBorder(borderRadius: 8)` and local button styles at `login_screen.dart:101-249`.
- `LoginScreen` has no AppBar while `RegisterScreen` does, so the auth flow changes shell between two consecutive screens.
- The vertical rhythm is loose because `SizedBox(height: 40)` and `SizedBox(height: 48)` push the form too low on smaller phones.

**What to remove or hide:**
- Remove the extra top gap before the title and replace it with a shared auth header block.

**What to simplify:**
- Replace the locally styled inputs/buttons with the theme-defined input and button variants from `app_theme.dart:46-98`.

**Primary action fix:**
- Before: the login button is primary, but the screen does not help the user recover when the password is forgotten.
- After: keep `Se connecter` as the single primary CTA and add a low-emphasis "Mot de passe oublie" text action below the password field.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Form controls | Custom 8px radius + local `styleFrom` | Shared auth form components using theme tokens |
| Shell | No AppBar | Same auth shell as register |

**Effort:** ~3h

### RegisterScreen
**File:** `front-end/lib/features/auth/presentation/register_screen.dart`  
**Actor:** Visiteur

**What is currently on this screen:**  
A long registration form shows AppBar, title, subtitle, five text fields, inline error box, primary register button, optional Google button, and a login link.

**Problems:**
- The screen repeats the same local border radius and button overrides as login at `register_screen.dart:131-346`.
- The AppBar at `register_screen.dart:98` makes the auth shell inconsistent with `LoginScreen`.
- The full identity and password form is presented in one dense block with no grouping or section labels.

**What to remove or hide:**
- Remove the standalone AppBar at `:98` and use the same auth shell/header as `LoginScreen`.

**What to simplify:**
- Split the form into two labeled groups inside the same screen: `Identite` and `Securite`, keeping Google sign-up visually below the main form completion path.

**Primary action fix:**
- Before: the register button appears after a long undifferentiated form.
- After: keep one main CTA at the bottom, but add short section headers so the user clearly sees progress toward account creation.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Header shell | AppBar only on register | Shared auth shell across login and register |
| Form structure | Five equal-weight fields | Two clearly labeled form groups |

**Effort:** ~4h

### HomeScreen
**File:** `front-end/lib/features/home/presentation/home_screen.dart`  
**Actor:** Visiteur / TOURIST / CONTRIBUTOR / PROFESSIONAL / ADMIN

**What is currently on this screen:**  
An `IndexedStack` hosts four tabs (`MapScreen`, `SitesListScreen`, `ProfileScreen`, `SettingsScreen`) behind a bottom `NavigationBar`.

**Problems:**
- `HomeScreen` embeds full screens in tabs while `AppRouter` also exposes standalone `/map`, `/sites`, and `/profile` routes, so navigation patterns are duplicated.
- The profile destination redirects guests to `/login` only after they tap the tab, which creates a dead-end feeling.
- `SettingsScreen` occupies a primary bottom tab even though it is a low-frequency destination compared with exploration.

**What to remove or hide:**
- Hide the profile tab for guests and replace it with a `Connexion` destination or a non-blocking prompt.

**What to simplify:**
- Move settings out of the bottom `NavigationBar` and place it behind profile or an overflow menu.

**Primary action fix:**
- Before: the bottom nav gives equal weight to exploration and settings.
- After: keep the bottom bar focused on high-frequency flows: map, explorer, and profile/account.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Bottom navigation | Map / Explorer / Profil / Reglages | Map / Explorer / Profil, with settings nested |
| Guest profile access | Redirect after tap | Clear guest-specific account entry point |

**Effort:** ~3h

### MapScreen
**File:** `front-end/lib/features/map/presentation/map_screen.dart`  
**Actor:** Visiteur / TOURIST / CONTRIBUTOR / PROFESSIONAL / ADMIN

**What is currently on this screen:**  
A `FlutterMap` shows site markers with a top filter card overlay, fixed-position loading/error banners, a bottom summary card, and a location FAB.

**Problems:**
- The filter overlay at `map_screen.dart:302-490` consumes up to 34% of the screen height and keeps all chips visible at once.
- The location action is duplicated in the AppBar (`:166-170`) and the FAB (`:280-289`).
- Loading and error banners use fixed `Positioned` offsets at `:194-266`, so they can overlap the filter panel and cover the map content awkwardly.

**What to remove or hide:**
- Remove the AppBar `Icons.my_location` action and keep only the bottom-right FAB for recentering.

**What to simplify:**
- Replace the always-open filter `Card` with a collapsible bottom sheet opened from a single filter button showing the active filter count.

**Primary action fix:**
- Before: filters, banners, summary, and location buttons all compete with marker exploration.
- After: make marker discovery the default focus and reveal filters only on demand.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Filters | Persistent overlay card | Collapsible sheet opened by one filter trigger |
| Location CTA | AppBar icon + FAB | FAB only |

**Effort:** ~6h

### SitesListScreen
**File:** `front-end/lib/features/sites/presentation/sites_list_screen.dart`  
**Actor:** Visiteur / TOURIST / CONTRIBUTOR / PROFESSIONAL / ADMIN

**What is currently on this screen:**  
A long `ListView` stacks a hero card, search, advanced filters, suggested rail, recent rail, category chips, subcategory chips, curated chips, results header, nearby summary, and full site cards.

**Problems:**
- The body block at `sites_list_screen.dart:259-493` tries to expose every discovery tool before the first result card, which is too much information.
- `_buildAdvancedFilters()` at `:588-859` is permanently open and duplicates several filters that also exist lower in the page.
- `_buildCompactSiteCard()` at `:903-1104` duplicates UI already present in `SiteCard`, creating two separate visual systems for the same entity.

**What to remove or hide:**
- Hide the suggested and recent rails when the user has an active search, selected category, or nearby mode enabled.

**What to simplify:**
- Turn `_buildAdvancedFilters()` into a collapsed section and merge `Categories populaires` plus `Collections premium` into one horizontal filter system.

**Primary action fix:**
- Before: search, nearby mode, multiple chip rows, and rails all compete.
- After: make search plus one nearby CTA the first action area, then show results immediately.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Discovery header | Hero + search + advanced filters + 2 rails + 3 chip rows | Hero + search + one collapsible filter row |
| Site preview card | `_buildCompactSiteCard()` and `SiteCard` coexist | One shared site preview component |

**Effort:** ~10h

### SiteDetailScreen
**File:** `front-end/lib/features/sites/presentation/site_detail_screen.dart`  
**Actor:** Visiteur / TOURIST / CONTRIBUTOR / PROFESSIONAL / ADMIN

**What is currently on this screen:**  
A sliver hero, metric cards, auth banners, favorite and CTA buttons, then a `TabBar` / `TabBarView` show site information, reviews, and photos.

**Problems:**
- The `TabBarView` is wrapped in `SizedBox(height: 500)` at `site_detail_screen.dart:605-618`, which creates nested scrolling and truncation on long tabs.
- The top content before the tabs includes hero chips, three metrics, multiple banners, favorite, check-in, and review actions, so hierarchy is diluted.
- The AppBar is manually forced to green/white in loading, error, and hero states at `:208-222` and `:261-265`, breaking the screen-level shell consistency.

**What to remove or hide:**
- Hide the secondary review CTA from the hero action row when the user is not eligible; keep it inside the reviews tab as the contextual action.

**What to simplify:**
- Reduce the metric strip to the two strongest values and move lower-priority metadata into the `Info` tab sections.

**Primary action fix:**
- Before: `Faire un check-in` and `Ajouter un avis` are peer CTAs in the same row.
- After: make check-in the dominant action on the header for eligible users and demote review to an outlined or in-tab action.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Tab container | Fixed `SizedBox(height: 500)` | Natural-height tab content without nested scroll trap |
| Header actions | Two competing primary buttons | One primary CTA + one secondary contextual action |

**Effort:** ~8h

### AddReviewScreen
**File:** `front-end/lib/features/sites/presentation/add_review_screen.dart`  
**Actor:** TOURIST / CONTRIBUTOR / PROFESSIONAL / ADMIN

**What is currently on this screen:**  
A scrollable form shows the site summary, star rating, comment input, photo picker, and submit button.

**Problems:**
- The screen overrides the AppBar color at `add_review_screen.dart:265-268` instead of using the theme shell.
- Local radius values at `:287`, `:342`, and the button style at `:461-463` do not match the theme-defined form system.
- Rating, comment, and photo steps are visually equal, even though rating is the real decision point and the others are optional.

**What to remove or hide:**
- Hide optional helper copy in the photo area until at least one photo has been selected.

**What to simplify:**
- Split the body into two sections: required `Votre note` first, optional `Commentaire et photos` second.

**Primary action fix:**
- Before: the submit button appears at the bottom but the required step is not visually isolated.
- After: make the rating block the clear first milestone and keep the submit button disabled until rating is set.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Styling | Local AppBar and button overrides | Theme-driven shell and button variants |
| Form hierarchy | All inputs appear equal | Rating first, optional enrichments second |

**Effort:** ~4h

### CheckinScreen
**File:** `front-end/lib/features/sites/presentation/checkin_screen.dart`  
**Actor:** TOURIST / CONTRIBUTOR / PROFESSIONAL / ADMIN

**What is currently on this screen:**  
The screen shows site summary, policy card, live location checks, status selection, optional comment, photo upload, and a submit CTA.

**Problems:**
- `CheckinPolicyCard` at `checkin_sections.dart:35-71` compresses multiple constraints into one dense sentence that is hard to scan on mobile.
- The page surfaces location loading, distance result, restriction, status choice, comment, and photos in one long flow at `checkin_screen.dart:447-559`.
- The AppBar is manually green/white at `checkin_screen.dart:425-440`, outside the app shell.

**What to remove or hide:**
- Hide the full policy details behind an info affordance once the short validation summary is visible.

**What to simplify:**
- Show the status radio choice and optional comment only after location validation succeeds, instead of rendering the full form stack immediately.

**Primary action fix:**
- Before: the submit button is present even while the validation context is still noisy.
- After: reveal the final CTA only after the user has passed the location gate and selected a status.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Validation copy | Long inline policy sentence | Short summary + expandable details |
| Flow | Entire form visible at once | Progressive flow after location success |

**Effort:** ~6h

### CheckinDetailScreen
**File:** `front-end/lib/features/sites/presentation/checkin_detail_screen.dart`  
**Actor:** TOURIST / CONTRIBUTOR / PROFESSIONAL / ADMIN

**What is currently on this screen:**  
The detail view stacks a header card, gallery card, metrics card, verification notes, comment card, and location card.

**Problems:**
- The page is fragmented into too many small cards (`_buildHeaderCard`, `_buildMetricsCard`, `_buildVerificationNotesCard`, `_buildCommentCard`, `_buildLocationCard`), which slows scanning.
- The AppBar is overridden to green/white at `checkin_detail_screen.dart:105-108`.
- Verification context text at `:442-511` is secondary information but it can visually rival the main summary.

**What to remove or hide:**
- Hide verbose verification notes behind an expandable section unless moderation notes are present.

**What to simplify:**
- Merge metrics and location summary into one `Resume du check-in` card above the optional detail cards.

**Primary action fix:**
- Before: there is no clear dominant next action once the detail is open.
- After: make `Voir les photos` the main contextual action when photos exist and keep other details passive.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Content structure | 5-6 small stacked cards | One summary card + optional detail cards |
| Optional notes | Always occupy full card space | Collapsed until needed |

**Effort:** ~3h

### CheckinPhotoGalleryScreen
**File:** `front-end/lib/features/sites/presentation/checkin_photo_gallery_screen.dart`  
**Actor:** TOURIST / CONTRIBUTOR / PROFESSIONAL / ADMIN

**What is currently on this screen:**  
A black full-screen gallery shows one network image per page with zoom, caption, hint text, and a bottom thumbnail rail.

**Problems:**
- The bottom panel at `checkin_photo_gallery_screen.dart:86-159` is always visible, which reduces image immersion even when there is only one photo.
- The guidance text repeats on every image, adding noise once the user already understands the interaction.
- Error placeholders exist inside `Image.network`, but there is no loading placeholder for the main image or thumbnails.

**What to remove or hide:**
- Hide the thumbnail rail when `widget.photos.length == 1`.

**What to simplify:**
- Show the interaction hint only on the first image open, then keep only caption plus photo count.

**Primary action fix:**
- Before: the bottom overlay gives equal weight to hint text and navigation thumbnails.
- After: make the photo itself the dominant content and reveal navigation aids only when useful.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Bottom overlay | Caption + hint + thumbnails always visible | Caption only by default, thumbnails only when multiple photos |
| Media loading | Direct network load | Lightweight image skeleton / fade-in |

**Effort:** ~1.5h

### SettingsScreen
**File:** `front-end/lib/features/settings/presentation/settings_screen.dart`  
**Actor:** Visiteur / TOURIST / CONTRIBUTOR / PROFESSIONAL / ADMIN

**What is currently on this screen:**  
A single `ListView` shows a hero and six sections: preferences, API, localization, optional technical info, professional, and about.

**Problems:**
- The screen mixes everyday preferences with technical/API tools and support/reset actions in one uninterrupted flow (`settings_screen.dart:334-595`).
- The biometric copy is corrupted at `settings_screen.dart:420-424`, which makes a security setting look broken.
- Low-frequency debug information becomes user-facing when `_technicalInfoVisible` is enabled at `:510-529`, but it uses the same card weight as core preferences.

**What to remove or hide:**
- Hide the full `Connexion API` section behind an advanced/debug entry unless the build is explicitly for technical users.

**What to simplify:**
- Reorder into three groups only: `Preferences`, `Permissions`, and `About`, then move the professional link out of settings into profile/hub navigation.

**Primary action fix:**
- Before: every tile has equal visual weight, including reset and debug actions.
- After: keep preference toggles as the main flow and isolate reset/support into a separate low-emphasis footer section.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Information architecture | 6 mixed sections | 3 user-facing groups + advanced/debug entry |
| Security copy | Mojibake biometric strings | Clean localized strings from `l10n` |

**Effort:** ~6h

### ProfileScreen
**File:** `front-end/lib/features/profile/presentation/profile_screen.dart`  
**Actor:** TOURIST / CONTRIBUTOR / PROFESSIONAL / ADMIN

**What is currently on this screen:**  
A very long profile feed shows header, stats, level progress, account links, contributor request card, journal, recent viewed sites, leaderboard entry point, badges, professional entry points, bio, recent activity, refresh, and logout.

**Problems:**
- The main `ListView` at `profile_screen.dart:313-992` tries to be dashboard, account center, progress hub, and activity feed at the same time.
- The profile AppBar is forced to green/white at `:209-212`, unlike most standard screens.
- Several sections repeat the same information hierarchy: stat cards, level card, account info list, contributor card, badges grid, and recent activity all compete as primary content.

**What to remove or hide:**
- Hide the contributor request card by default once the request is approved, and move rarely used items like `Rafraichir le profil` out of the main feed into an overflow menu.

**What to simplify:**
- Rebuild the screen into four sections only: `Compte`, `Progression`, `Activite`, and `Acces rapides`; move `Mes badges` and `Activite recente` behind compact previews with `Voir tout`.

**Primary action fix:**
- Before: there is no single dominant action because every card looks actionable.
- After: keep one main account CTA block near the top (`Modifier mon profil`, `Mes check-ins`, `Mes avis`) and demote the rest to secondary navigation.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Screen scope | Full dashboard feed with 10+ sections | 4 clear sections with previews |
| Header shell | Custom green AppBar | Theme AppBar + stronger internal section hierarchy |

**Effort:** ~12h

### PublicUserProfileScreen
**File:** `front-end/lib/features/profile/presentation/public_user_profile_screen.dart`  
**Actor:** Visiteur / TOURIST / CONTRIBUTOR / PROFESSIONAL / ADMIN

**What is currently on this screen:**  
A public profile page loads a gradient hero, two rows of stats, and an optional bio card.

**Problems:**
- The stats are split into two separate `Row`s at `public_user_profile_screen.dart:158-180`, which uses vertical space inefficiently.
- The hero member-since line contains a corrupted bullet separator at `:122`.
- The loading state is only a centered spinner, even though the final layout is simple enough for a skeleton.

**What to remove or hide:**
- Remove the plain `Activite visible` heading once the stat cards are converted into a more self-explanatory grid.

**What to simplify:**
- Replace the two `Row`s of `_StatCard` with a 2x2 grid so the overview fits above the fold.

**Primary action fix:**
- Before: the screen is purely informational and the only recovery action is on the error state.
- After: keep it intentionally read-only, but make retry a low-emphasis action and prioritize the profile summary.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Stats layout | Two stacked rows | Compact 2x2 stat grid |
| Copy quality | Corrupted bullet in hero text | Clean, localized summary line |

**Effort:** ~3h

### EditProfileScreen
**File:** `front-end/lib/features/profile/presentation/edit_profile_screen.dart`  
**Actor:** TOURIST / CONTRIBUTOR / PROFESSIONAL / ADMIN

**What is currently on this screen:**  
A profile edit form shows an info banner, core identity fields, optional contact fields, profile picture URL, bio, and a save button.

**Problems:**
- Optional and required data are visually mixed in one continuous form at `edit_profile_screen.dart:203-287`.
- The info banner at `:171-178` explains the photo URL constraint, but the form gives no visual hint that `Photo de profil` is advanced/optional.
- There is no live preview for the profile picture URL field, so the user edits a visual property blindly.

**What to remove or hide:**
- Hide `Photo de profil` and `Bio` inside an `Informations complementaires` section instead of exposing them at equal weight with name and email.

**What to simplify:**
- Keep `Prenom`, `Nom`, and `Email` as the first section, then group phone/nationality and advanced profile fields below a divider.

**Primary action fix:**
- Before: the save CTA is correct, but the path to completion is not obvious.
- After: make the required profile identity block visually complete before the optional fields start.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Field priority | Required and optional fields mixed | Required identity first, advanced data collapsed |
| Media edit | URL text field only | URL field with inline preview or helper thumbnail |

**Effort:** ~3h

### ChangePasswordScreen
**File:** `front-end/lib/features/profile/presentation/change_password_screen.dart`  
**Actor:** TOURIST / CONTRIBUTOR / PROFESSIONAL / ADMIN

**What is currently on this screen:**  
An info banner explains session invalidation, then three password fields and a submit button update the account password.

**Problems:**
- All three fields have equal weight even though the real progression is `current` then `new` then `confirm`.
- The banner at `change_password_screen.dart:138-146` is long and occupies top space before the user sees the first input.
- Password quality expectations are only surfaced through validation after input.

**What to remove or hide:**
- Shorten the banner and move the session invalidation explanation under the submit button as a caption.

**What to simplify:**
- Add a small requirement hint below `Nouveau mot de passe` and visually separate current password from the new-password pair.

**Primary action fix:**
- Before: the primary CTA is clear, but the form offers little guidance before validation errors appear.
- After: keep the CTA, but make the new-password step the main focus with pre-emptive guidance.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Guidance | Long banner only | Short banner + inline password rule hint |
| Field grouping | 3 equal fields | Current password separated from new password pair |

**Effort:** ~2h

### BadgesCatalogScreen
**File:** `front-end/lib/features/profile/presentation/badges_catalog_screen.dart`  
**Actor:** TOURIST / CONTRIBUTOR / PROFESSIONAL / ADMIN

**What is currently on this screen:**  
The page loads a hero summary and then a vertical list of badge cards with rarity, category, bonus points, conditions, and award count.

**Problems:**
- Every badge card repeats three pills plus two text rows, so scanning becomes repetitive on long lists.
- Rarity colors are hardcoded in `_rarityColor()` and are not tied to the app theme.
- The conditions line uses a corrupted separator at `badges_catalog_screen.dart:164-166`.

**What to remove or hide:**
- Hide the low-priority `Attribue X fois` line unless the card is expanded or tapped.

**What to simplify:**
- Replace the long conditions sentence with a short bullet/chip list so each requirement is readable at a glance.

**Primary action fix:**
- Before: the screen is list-only and every card has the same scanning cost.
- After: make rarity and progress conditions the dominant read path, with secondary meta hidden by default.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Conditions | One long sentence with corrupted separator | Short structured criteria chips |
| Card density | 5-6 repeated text layers | Two-tier card with optional metadata |

**Effort:** ~3h

### LeaderboardScreen
**File:** `front-end/lib/features/profile/presentation/leaderboard_screen.dart`  
**Actor:** TOURIST / CONTRIBUTOR / PROFESSIONAL / ADMIN

**What is currently on this screen:**  
A hero, podium for top 3, and a full ranking list show contributors with points, level, rank, and activity counts.

**Problems:**
- The title remains English (`Leaderboard`) at `leaderboard_screen.dart:76` while the rest of the product is French.
- The top 3 appear twice because the list begins again from entry 1 right after the podium.
- The subtitle line in `_LeaderboardTile` uses a corrupted separator at `:396`.

**What to remove or hide:**
- Hide the top three entries from the full list and start the `Classement complet` list at rank 4.

**What to simplify:**
- Reduce the hero copy and podium height so the actual ranking starts higher on the screen.

**Primary action fix:**
- Before: the eye is pulled first to the hero, then to the podium, then to the same users again in the list.
- After: keep the podium as a highlight, then move directly into the remaining ranking with one consistent scanning path.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Ranking flow | Podium + duplicated top 3 list items | Podium + list starting at rank 4 |
| Screen title | English `Leaderboard` | French product label |

**Effort:** ~4h

### MyCheckinsScreen
**File:** `front-end/lib/features/profile/presentation/my_checkins_screen.dart`  
**Actor:** TOURIST / CONTRIBUTOR / PROFESSIONAL / ADMIN

**What is currently on this screen:**  
The history page shows a hero summary, filter chips, check-in cards with status badges and metadata, plus empty and loading-more states.

**Problems:**
- The hero summary at `my_checkins_screen.dart:233-279` duplicates counts that are also encoded again in the filter chips.
- `_buildCheckinCard()` at `:352-467` packs preview, three badges, and four meta lines into a dense card.
- `_buildEmptyState()` at `:469-497` explains the situation but offers no path back to exploration.

**What to remove or hide:**
- Hide the hero card once the list is scrolled or reduce it to one compact summary strip above the filters.

**What to simplify:**
- Keep only one status badge plus one validation badge visible on the card, and move secondary metrics like GPS accuracy behind the detail screen.

**Primary action fix:**
- Before: the empty state is passive.
- After: add a primary CTA in `_buildEmptyState()` to return to `/sites` and create the first check-in.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Header summary | Large hero + counted chips | Compact summary strip |
| Empty state | Icon + message only | Icon + message + `Explorer des lieux` CTA |

**Effort:** ~4h

### MyReviewsScreen
**File:** `front-end/lib/features/profile/presentation/my_reviews_screen.dart`  
**Actor:** TOURIST / CONTRIBUTOR / PROFESSIONAL / ADMIN

**What is currently on this screen:**  
The page shows a hero summary, filter chips, review cards with status pills, optional owner response, and three action buttons per card.

**Problems:**
- `_buildReviewCard()` at `my_reviews_screen.dart:578-757` is visually dense because rating, status, body text, owner response, and three buttons all live in one card.
- The action row uses three equal `OutlinedButton.icon` controls at `:728-751`, so edit and delete feel as prominent as `Voir le site`.
- The empty state at `:759-787` has no recovery CTA back to discovery.

**What to remove or hide:**
- Hide edit and delete behind a `PopupMenuButton` or overflow action and keep only one visible contextual button on the card.

**What to simplify:**
- Collapse long owner responses behind a `Voir la reponse` affordance when they exceed one short paragraph.

**Primary action fix:**
- Before: three peer actions fragment the card footer.
- After: keep `Voir le site` as the visible action and move `Modifier` / `Supprimer` into an overflow menu plus confirmation dialog.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Card footer | 3 equal-width buttons | 1 visible action + overflow menu |
| Empty state | Message only | Message + CTA back to site list |

**Effort:** ~5h

### ProfessionalHubScreen
**File:** `front-end/lib/features/professional/presentation/professional_hub_screen.dart`  
**Actor:** PROFESSIONAL / ADMIN

**What is currently on this screen:**  
The hub page shows a hero, a `what this space does` section, a recommended flow section, and role-based quick access actions.

**Problems:**
- For eligible professionals, the real actions are at the bottom while two explanatory cards come first.
- The page is brochure-heavy: `_SectionCard` blocks at `professional_hub_screen.dart:34-126` add a lot of reading before task entry.
- The same card weight is used for explanation and action, so hierarchy is weak.

**What to remove or hide:**
- Hide `Ce que permet cet espace` and `Parcours recommande` behind collapsible help sections once the user has access to management actions.

**What to simplify:**
- Reorder the screen so `Acces rapide` becomes the first content block after the hero for authenticated professionals.

**Primary action fix:**
- Before: the user lands on information first and action second.
- After: make `Ouvrir mon espace professionnel` or `Se connecter` the first visible CTA under the hero.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Content order | Explanation before actions | Actions before documentation |
| Section weight | All cards equal | Action card visually dominant |

**Effort:** ~4h

### ProfessionalSitesScreen
**File:** `front-end/lib/features/professional/presentation/professional_sites_screen.dart`  
**Actor:** PROFESSIONAL / ADMIN

**What is currently on this screen:**  
The screen loads professional sites, filters by status, shows an intro card, then one card per site with status pills and actions, plus a FAB to add a site.

**Problems:**
- The card is already tappable, but the footer still exposes a redundant `Voir la fiche` text button at `professional_sites_screen.dart:287-293`.
- Status filter labels and city/category text expose raw backend-like strings and one corrupted separator at `:243`.
- The empty state at `:147-166` has no CTA even though a FAB exists for the next step.

**What to remove or hide:**
- Remove the `Voir la fiche` text button and rely on card tap plus one visible `Modifier` secondary action.

**What to simplify:**
- Map `_statusFilters` to human-readable labels and reuse the same `StatusChip` component as the cards.

**Primary action fix:**
- Before: the FAB and per-card buttons compete.
- After: keep the FAB as the creation CTA and reduce each card to one edit affordance plus tap-to-open behavior.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Card actions | Tap card + `Voir la fiche` + `Modifier` | Tap card + one edit action |
| Empty state | Informational only | Add `Ajouter un etablissement` CTA |

**Effort:** ~4h

### ProfessionalClaimSiteScreen
**File:** `front-end/lib/features/professional/presentation/professional_claim_site_screen.dart`  
**Actor:** PROFESSIONAL / ADMIN

**What is currently on this screen:**  
The page shows an intro card, a search field, then a list of claimable site cards with metrics and a `Revendiquer ce site` CTA.

**Problems:**
- The search field suffix arrow at `professional_claim_site_screen.dart:138-149` is ambiguous compared with a standard search action icon.
- Every card repeats three mini metric pills even when counts are zero, which adds noise before the claim action.
- The intro card and the search box are both tall, so the first claimable result can start too low on mobile.

**What to remove or hide:**
- Hide zero-value `_MiniInfo` pills and keep only the metrics that carry actual signal for the claim decision.

**What to simplify:**
- Shorten the intro copy and use one compact search bar with a standard search icon trigger.

**Primary action fix:**
- Before: search and claim have similar visual weight at the top of the screen.
- After: make the search field the single discovery action, then keep `Revendiquer ce site` as the dominant CTA on each result card.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Search affordance | Arrow suffix button | Standard search trigger |
| Result cards | All metrics always visible | Only meaningful metrics shown before CTA |

**Effort:** ~3h

### CreateSiteScreen
**File:** `front-end/lib/features/professional/presentation/create_site_screen.dart`  
**Actor:** PROFESSIONAL / ADMIN

**What is currently on this screen:**  
A long create-site form exposes identity, category, description, address, coordinates, contact, pricing, and four service toggles before the submit button.

**Problems:**
- The form is a single long sequence of fields from `create_site_screen.dart:457-715`, so the screen tries to show everything at once.
- Required and optional fields are visually mixed, which raises perceived effort for the first submission.
- The final CTA is only visible after a long scroll, so the screen lacks a clear completion rhythm.

**What to remove or hide:**
- Hide optional fields such as website, email, phone complements, and service flags inside an `Informations complementaires` section until the required data is complete.

**What to simplify:**
- Split the form into four visible sections inside the same screen: `Identite`, `Localisation`, `Contact`, and `Services`.

**Primary action fix:**
- Before: the primary create action sits after a very tall wall of inputs.
- After: keep the main CTA visible with a sticky bottom action bar or at least clear section endings before the final submit button.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Form layout | 15+ fields in one uninterrupted scroll | 4 grouped sections with optional fields collapsed |
| Completion cue | CTA only at the bottom | Sticky or clearly staged completion CTA |

**Effort:** ~10h

### ProfessionalSiteDetailScreen
**File:** `front-end/lib/features/professional/presentation/professional_site_detail_screen.dart`  
**Actor:** PROFESSIONAL / ADMIN

**What is currently on this screen:**  
The owner detail page stacks a hero, validation section, analytics, contact, services, opening hours, activity timeline, and recent reviews.

**Problems:**
- The screen is dashboard-dense because the `ListView` at `professional_site_detail_screen.dart:156-209` exposes every available management section in one pass.
- The hero at `:227-338` contains status chips, five metric badges, description, views/owner line, and an edit button, so the edit action has weak focus.
- Several sections use long explanatory text blocks (`_AnalyticsSection` at `:384-410`, `_ActivitySection` at `:680-783`) that are better as secondary details.

**What to remove or hide:**
- Hide the long `Lecture rapide` text in `_AnalyticsSection` behind a `Voir l'analyse` affordance and keep only the four tiles by default.

**What to simplify:**
- Reduce the hero to site name, two key statuses, one metric strip, and the edit CTA; move the rest into lower cards.

**Primary action fix:**
- Before: `Modifier` exists, but it competes with too much hero metadata.
- After: make `Modifier` the only high-emphasis action in the hero and demote most metrics below the fold.

**Before / After:**
| Element | Before | After |
|---------|--------|-------|
| Hero density | 3 status chips + 5 metrics + description + footer meta + CTA | Name + 2 statuses + primary edit CTA |
| Analytics section | Tiles + long narrative block | Tiles first, details on demand |

**Effort:** ~8h

## SECTION 3 - Missing Shared Components

### 1. `SitePreviewCard`
- Screens that need it:
  `sites_list_screen.dart`, `site_card.dart`, `site_detail_sections.dart` (`RelatedSiteCard`), `professional_claim_site_screen.dart`, `professional_sites_screen.dart`
- What it replaces:
  `SiteCard`, `_buildCompactSiteCard`, `RelatedSiteCard`, and the repeated professional site summary cards
- Exact fix to apply:
  Extract a configurable card with image, title, subtitle, badges, rating, distance, favorite state, and action slots into `front-end/lib/shared/widgets/site_preview_card.dart`.
- Effort: ~6h

### 2. `EmptyStateWidget`
- Screens that need it:
  `sites_list_screen.dart`, `site_detail_sections.dart`, `my_checkins_screen.dart`, `my_reviews_screen.dart`, `professional_sites_screen.dart`, `professional_claim_site_screen.dart`, `leaderboard_screen.dart`, `public_user_profile_screen.dart`, `badges_catalog_screen.dart`
- What it replaces:
  Every icon + title + message empty block currently built inline
- Exact fix to apply:
  Add icon, title, message, and optional CTA slots so empty screens stop dead-ending.
- Effort: ~3h

### 3. `LoadingSkeleton`
- Screens that need it:
  `sites_list_screen.dart`, `site_detail_screen.dart`, `settings_screen.dart`, `public_user_profile_screen.dart`, `badges_catalog_screen.dart`, `leaderboard_screen.dart`, `my_checkins_screen.dart`, `my_reviews_screen.dart`, `professional_site_detail_screen.dart`
- What it replaces:
  Plain `Center(child: CircularProgressIndicator())` placeholders
- Exact fix to apply:
  Create list, card, and media skeleton variants under `front-end/lib/shared/widgets/loading_skeleton.dart`.
- Effort: ~4h

### 4. `ErrorStateWidget`
- Screens that need it:
  `site_detail_screen.dart`, `public_user_profile_screen.dart`, `professional_site_detail_screen.dart`, `sites_list_screen.dart`, `leaderboard_screen.dart`
- What it replaces:
  Repeated centered icon/error/retry layouts and one-off orange banners
- Exact fix to apply:
  Provide full-screen and inline variants with retry button and optional secondary help text.
- Effort: ~3h

### 5. `RatingStars`
- Screens that need it:
  `add_review_screen.dart`, `my_reviews_screen.dart`, `review_card.dart`, `site_card.dart`, `professional_site_detail_screen.dart`
- What it replaces:
  Inline `List.generate(5, ...)` stars and custom dot/rating mini-systems
- Exact fix to apply:
  Create one shared `RatingStars` widget supporting read-only and editable modes.
- Effort: ~2h

### 6. `StatusChip`
- Screens that need it:
  `my_checkins_screen.dart`, `my_reviews_screen.dart`, `professional_sites_screen.dart`, `professional_site_detail_screen.dart`, `site_detail_screen.dart`, `checkin_detail_screen.dart`
- What it replaces:
  `_HistoryBadge`, `_StatusBadge`, `_StatusPill`, `_HeroChip`, inline status containers
- Exact fix to apply:
  Extract a semantic chip component with icon, label, tone, and size variants.
- Effort: ~3h

### 7. `SectionHeader`
- Screens that need it:
  `sites_list_screen.dart`, `profile_screen.dart`, `professional_hub_screen.dart`, `professional_site_detail_screen.dart`, `badges_catalog_screen.dart`
- What it replaces:
  Repeated `Text + subtitle + spacing` patterns built inline
- Exact fix to apply:
  Add a reusable header with title, subtitle, optional trailing action, and consistent spacing.
- Effort: ~2h

### 8. `ConfirmationDialog`
- Screens that need it:
  `profile_screen.dart`, `my_reviews_screen.dart`, `change_password_screen.dart`, future destructive settings actions
- What it replaces:
  Inline `AlertDialog` implementations and ad-hoc destructive button styling
- Exact fix to apply:
  Extract a dialog with title, message, confirm tone (`default`, `danger`), and primary/secondary labels.
- Effort: ~2h

### 9. `AuthFormShell`
- Screens that need it:
  `login_screen.dart`, `register_screen.dart`
- What it replaces:
  Duplicated auth title/subtitle spacing, inline error card, and footer links
- Exact fix to apply:
  Create a shared auth page scaffold that receives title, subtitle, form body, and footer actions.
- Effort: ~3h

### 10. `SummaryPill`
- Screens that need it:
  `sites_list_screen.dart`, `my_checkins_screen.dart`, `my_reviews_screen.dart`, `professional_site_detail_screen.dart`, `welcome_screen.dart`
- What it replaces:
  `_summaryPill`, `_SummaryPill`, `_MetricBadge`, `_HeroStat`, and similar mini-stat containers
- Exact fix to apply:
  Add one shared stat pill with dark/light variants and icon support.
- Effort: ~3h

## SECTION 4 - Quick Wins

| # | Screen | What to change | Impact | Effort |
|---|--------|---------------|--------|--------|
| 1 | `SiteDetailScreen` | Remove `SizedBox(height: 500)` around `TabBarView` at `site_detail_screen.dart:605-618` | High | ~30m |
| 2 | `LoginScreen` | Replace local `styleFrom` and 8px radii with theme button/input styles at `login_screen.dart:101-249` | High | ~45m |
| 3 | `RegisterScreen` | Remove the standalone AppBar at `register_screen.dart:98` and align shell with login | High | ~30m |
| 4 | `SettingsScreen` | Fix corrupted biometric strings at `settings_screen.dart:420-424` using existing `l10n` copy | High | ~20m |
| 5 | `SplashScreen` | Replace the English subtitle at `splash_screen.dart:72` with tourism-specific product copy | High | ~15m |
| 6 | `ProfessionalSitesScreen` | Remove redundant `Voir la fiche` button from each card at `professional_sites_screen.dart:287-293` | High | ~30m |
| 7 | `MyReviewsScreen` | Demote `Modifier` and `Supprimer` from the visible footer and keep one visible CTA | High | ~1h |
| 8 | `MyCheckinsScreen` | Add a CTA button in `_buildEmptyState()` at `my_checkins_screen.dart:469-497` | High | ~30m |
| 9 | `SitesListScreen` | Collapse `_buildAdvancedFilters()` so it is closed by default | High | ~1h |
| 10 | `MapScreen` | Remove the duplicate AppBar location icon at `map_screen.dart:166-170` | Medium | ~20m |
| 11 | `LeaderboardScreen` | Rename the AppBar title from `Leaderboard` to a French label and fix the corrupted separators | Medium | ~20m |
| 12 | `BadgesCatalogScreen` | Replace `criteria.join(' Â· ')` with a clean separator or chips at `badges_catalog_screen.dart:164-166` | Medium | ~20m |
| 13 | `PublicUserProfileScreen` | Replace the two stat `Row`s with a compact 2x2 grid | Medium | ~1h |
| 14 | `AddReviewScreen` | Remove AppBar color override at `add_review_screen.dart:265-268` and use theme AppBar | Medium | ~20m |
| 15 | `CheckinScreen` | Remove AppBar color override at `checkin_screen.dart:425-440` and use theme AppBar | Medium | ~20m |
| 16 | `ProfileScreen` | Remove AppBar color override at `profile_screen.dart:209-212` and use theme AppBar | Medium | ~20m |
| 17 | `ProfessionalHubScreen` | Move the quick-action card above the two explanation cards | Medium | ~45m |
| 18 | `CheckinPhotoGalleryScreen` | Hide the thumbnail rail when only one photo is available | Medium | ~20m |

## SECTION 5 - Implementation Order

### Wave 1 - Do First (foundation)
- Fix global theme drift: AppBars, button variants, radii, spacing tokens, corrupted copy
- Create the first shared components: `SitePreviewCard`, `EmptyStateWidget`, `LoadingSkeleton`, `ErrorStateWidget`, `StatusChip`, `ConfirmationDialog`
- Add empty/loading/error states everywhere they are still plain text or bare spinners
- Total: ~3 days

### Wave 2 - High Traffic Screens
- `HomeScreen`, `MapScreen`, `SitesListScreen`, `SiteDetailScreen`
- `LoginScreen`, `RegisterScreen`, `ProfileScreen`, `SettingsScreen`
- `AddReviewScreen`, `CheckinScreen`
- Total: ~6 days

### Wave 3 - Remaining Screens
- `SplashScreen`, `PublicUserProfileScreen`, `EditProfileScreen`, `ChangePasswordScreen`
- `BadgesCatalogScreen`, `LeaderboardScreen`, `MyCheckinsScreen`, `MyReviewsScreen`
- `ProfessionalHubScreen`, `ProfessionalSitesScreen`, `ProfessionalClaimSiteScreen`, `CreateSiteScreen`, `ProfessionalSiteDetailScreen`, `CheckinDetailScreen`, `CheckinPhotoGalleryScreen`
- Total: ~5 days

## SECTION 6 - Summary Table

| Screen | Problems found | Priority | Effort |
|--------|---------------|----------|--------|
| SplashScreen | 3 | Medium | ~1.5h |
| WelcomeScreen | 3 | Medium | ~3h |
| LoginScreen | 3 | High | ~3h |
| RegisterScreen | 3 | High | ~4h |
| HomeScreen | 3 | High | ~3h |
| MapScreen | 3 | High | ~6h |
| SitesListScreen | 4 | High | ~10h |
| SiteDetailScreen | 4 | High | ~8h |
| AddReviewScreen | 3 | Medium | ~4h |
| CheckinScreen | 3 | High | ~6h |
| CheckinDetailScreen | 3 | Medium | ~3h |
| CheckinPhotoGalleryScreen | 3 | Low | ~1.5h |
| SettingsScreen | 3 | High | ~6h |
| ProfileScreen | 4 | High | ~12h |
| PublicUserProfileScreen | 3 | Medium | ~3h |
| EditProfileScreen | 3 | Medium | ~3h |
| ChangePasswordScreen | 3 | Medium | ~2h |
| BadgesCatalogScreen | 3 | Medium | ~3h |
| LeaderboardScreen | 3 | Medium | ~4h |
| MyCheckinsScreen | 3 | Medium | ~4h |
| MyReviewsScreen | 3 | Medium | ~5h |
| ProfessionalHubScreen | 3 | Medium | ~4h |
| ProfessionalSitesScreen | 3 | Medium | ~4h |
| ProfessionalClaimSiteScreen | 3 | Medium | ~3h |
| CreateSiteScreen | 3 | High | ~10h |
| ProfessionalSiteDetailScreen | 4 | High | ~8h |
| **TOTAL** | **82 issues** |  | **~14 days** |
