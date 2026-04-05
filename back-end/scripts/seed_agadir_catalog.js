import pool from '../src/config/database.js';
import fs from 'fs/promises';
import path from 'path';
import { execFile } from 'child_process';
import { promisify } from 'util';
import {
  buildSitePhotoPublicPath,
  ensureUploadsDirectories,
  resolveStoredSitePhotoPath
} from '../src/utils/media.utils.js';

const DAYS = [
  'MONDAY',
  'TUESDAY',
  'WEDNESDAY',
  'THURSDAY',
  'FRIDAY',
  'SATURDAY',
  'SUNDAY'
];

ensureUploadsDirectories();
const execFileAsync = promisify(execFile);

const fullWeek = (opensAt, closesAt, notes = '') =>
  DAYS.map((dayOfWeek) => ({
    dayOfWeek,
    opensAt,
    closesAt,
    isClosed: false,
    is24Hours: false,
    notes
  }));

const fullWeek24 = (notes = '') =>
  DAYS.map((dayOfWeek) => ({
    dayOfWeek,
    opensAt: null,
    closesAt: null,
    isClosed: false,
    is24Hours: true,
    notes
  }));

const closedMonday = (opensAt, closesAt, notes = '') =>
  DAYS.map((dayOfWeek) => ({
    dayOfWeek,
    opensAt: dayOfWeek === 'MONDAY' ? null : opensAt,
    closesAt: dayOfWeek === 'MONDAY' ? null : closesAt,
    isClosed: dayOfWeek === 'MONDAY',
    is24Hours: false,
    notes
  }));

const agadirSites = [
  {
    name: 'Pure Passion Agadir',
    categoryName: 'Moroccan Cuisine',
    parentCategoryName: 'Restaurant',
    subcategory: 'Cuisine en bord de mer',
    description:
      'Adresse emblematique de la marina pour un repas face aux bateaux, pratique pour une pause dejeuner ou un diner en fin de promenade.',
    latitude: 30.4259,
    longitude: -9.6065,
    address: 'Marina d Agadir, Secteur Balneaire',
    phoneNumber: '+212 5 28 84 42 22',
    website: 'https://www.purepassion.ma',
    priceRange: 'EXPENSIVE',
    acceptsCardPayment: true,
    hasWifi: true,
    hasParking: true,
    isAccessible: true,
    isFeatured: true,
    averageRating: 4.5,
    totalReviews: 1,
    freshnessScore: 92,
    amenities: ['vue marina', 'terrasse', 'reservation', 'cadre couple'],
    openingHours: fullWeek('08:00:00', '23:00:00', 'Service continu en zone marina.'),
    photos: [
      {
        url: '/uploads/sites/seed-agadir-pure-passion-agadir-1.jpg',
        caption: 'Ambiance marina a Agadir, a quelques pas du restaurant Pure Passion.',
        altText: 'Marina d Agadir a proximite du restaurant Pure Passion'
      }
    ]
  },
  {
    name: 'Le Jardin d Eau',
    categoryName: 'Cafe',
    parentCategoryName: 'Restaurant',
    subcategory: 'Cafe terrasse',
    description:
      'Cafe restaurant de promenade a la marina, adapte pour une pause cafe, un dessert ou un repas leger avec vue agreable.',
    latitude: 30.4257,
    longitude: -9.608,
    address: 'Marina d Agadir, promenade principale',
    priceRange: 'MODERATE',
    acceptsCardPayment: true,
    hasWifi: true,
    hasParking: true,
    isAccessible: true,
    isFeatured: false,
    averageRating: 4.2,
    totalReviews: 0,
    freshnessScore: 88,
    amenities: ['terrasse', 'pause cafe', 'vue promenade', 'desserts'],
    openingHours: fullWeek('09:00:00', '23:00:00', 'Horaires etendus en haute saison.'),
    photos: [
      {
        url: '/uploads/sites/seed-agadir-le-jardin-d-eau-1.jpg',
        caption: 'Facade et terrasse du Jardin d Eau sur la marina d Agadir.',
        altText: 'Le Jardin d Eau a la marina d Agadir'
      }
    ]
  },
  {
    name: 'Sofitel Agadir Thalassa Sea & Spa',
    categoryName: 'Hotel',
    subcategory: 'Resort thalasso',
    description:
      'Resort haut de gamme en front de mer, recherche pour les sejours balneaires, la detente spa et un acces direct a la plage.',
    latitude: 30.3897,
    longitude: -9.5976,
    address: 'Baie des Palmiers, Cite Founty P5',
    phoneNumber: '+212 5 28 84 56 00',
    website: 'https://all.accor.com',
    priceRange: 'LUXURY',
    acceptsCardPayment: true,
    hasWifi: true,
    hasParking: true,
    isAccessible: true,
    isFeatured: true,
    averageRating: 4.7,
    totalReviews: 0,
    freshnessScore: 95,
    amenities: ['spa', 'thalasso', 'front de mer', 'piscine', 'restaurant'],
    openingHours: fullWeek24('Accueil hotel 24h/24.'),
    photos: [
      {
        url: '/uploads/sites/seed-agadir-sofitel-agadir-thalassa-sea-spa-1.png',
        caption: 'Front de mer d Agadir a proximite du Sofitel Agadir Thalassa Sea and Spa.',
        altText: 'Sofitel Agadir Thalassa Sea and Spa'
      }
    ]
  },
  {
    name: 'Hotel Riu Palace Tikida Agadir',
    categoryName: 'Hotel',
    subcategory: 'Resort tout confort',
    description:
      'Grand hotel de sejour a quelques minutes du front de mer, pratique pour les vacances familiales et les sejours club.',
    latitude: 30.3956,
    longitude: -9.596,
    address: 'Chemin des Dunes, Founty 2',
    priceRange: 'LUXURY',
    acceptsCardPayment: true,
    hasWifi: true,
    hasParking: true,
    isAccessible: true,
    isFeatured: true,
    averageRating: 4.6,
    totalReviews: 0,
    freshnessScore: 93,
    amenities: ['all inclusive', 'front de mer', 'piscine', 'famille'],
    openingHours: fullWeek24('Accueil hotel 24h/24.'),
    photos: [
      {
        url: '/uploads/sites/seed-agadir-hotel-riu-palace-tikida-agadir-1.jpg',
        caption: 'Front de mer d Agadir a proximite du Riu Palace Tikida Agadir.',
        altText: 'Hotel Riu Palace Tikida Agadir'
      }
    ]
  },
  {
    name: 'Musee du Patrimoine Amazigh d Agadir',
    categoryName: 'Museum',
    subcategory: 'Patrimoine amazigh',
    description:
      'Musee de reference pour comprendre la culture amazighe locale a travers bijoux, objets du quotidien et collections artisanales.',
    latitude: 30.4205,
    longitude: -9.5928,
    address: 'Avenue Hassan II',
    phoneNumber: '+212 5 28 82 00 20',
    priceRange: 'BUDGET',
    acceptsCardPayment: false,
    hasWifi: false,
    hasParking: false,
    isAccessible: true,
    isFeatured: true,
    averageRating: 4.4,
    totalReviews: 0,
    freshnessScore: 90,
    amenities: ['exposition', 'culture', 'artisanat', 'visite guidee'],
    openingHours: closedMonday('09:30:00', '17:30:00', 'Verification conseillee avant la visite.'),
    photos: [
      {
        url: '/uploads/sites/seed-agadir-musee-du-patrimoine-amazigh-d-agadir-1.jpg',
        caption: 'Salle d exposition du musee du patrimoine amazigh.',
        altText: 'Interieur du Musee du Patrimoine Amazigh d Agadir'
      }
    ]
  },
  {
    name: 'Kasbah Agadir Oufella',
    categoryName: 'Historical Site',
    subcategory: 'Point de vue historique',
    description:
      'Site historique dominant la baie, incontournable pour la vue panoramique sur Agadir, surtout en fin de journee.',
    latitude: 30.4276,
    longitude: -9.6226,
    address: 'Colline d Agadir Oufella',
    priceRange: 'BUDGET',
    acceptsCardPayment: false,
    hasWifi: false,
    hasParking: true,
    isAccessible: false,
    isFeatured: true,
    averageRating: 4.8,
    totalReviews: 0,
    freshnessScore: 97,
    amenities: ['panorama', 'coucher de soleil', 'site historique', 'photo spot'],
    openingHours: fullWeek('09:00:00', '20:00:00', 'Acces souvent lie aux conditions et a la saison.'),
    photos: [
      {
        url: '/uploads/sites/seed-agadir-kasbah-agadir-oufella-1.jpg',
        caption: 'Remparts illumines de la Kasbah d Agadir Oufella.',
        altText: 'Kasbah d Agadir Oufella'
      }
    ]
  },
  {
    name: 'Telepherique d Agadir',
    categoryName: 'Entertainment',
    subcategory: 'Experience panoramique',
    description:
      'Liaison panoramique vers la colline d Oufella, utile pour acceder au point de vue tout en profitant d une experience touristique marquante.',
    latitude: 30.4211,
    longitude: -9.6212,
    address: 'Depart cote marina et Oufella',
    priceRange: 'MODERATE',
    acceptsCardPayment: true,
    hasWifi: false,
    hasParking: true,
    isAccessible: true,
    isFeatured: true,
    averageRating: 4.6,
    totalReviews: 0,
    freshnessScore: 91,
    amenities: ['cabines', 'vue baie', 'acces Oufella', 'photo spot'],
    openingHours: fullWeek('10:00:00', '22:00:00', 'Horaires variables selon la saison.'),
    photos: [
      {
        url: '/uploads/sites/seed-agadir-telepherique-d-agadir-1.jpg',
        caption: 'Cabines du telepherique d Agadir en direction d Oufella.',
        altText: 'Telepherique d Agadir'
      }
    ]
  },
  {
    name: 'Plage d Agadir',
    categoryName: 'Beach',
    subcategory: 'Plage urbaine',
    description:
      'Grande plage urbaine de sable, ideale pour la marche, les activites nautiques legeres et la promenade en bord de mer.',
    latitude: 30.4069,
    longitude: -9.5986,
    address: 'Front de mer, Boulevard Mohammed V',
    priceRange: 'BUDGET',
    acceptsCardPayment: false,
    hasWifi: false,
    hasParking: true,
    isAccessible: true,
    isFeatured: true,
    averageRating: 4.7,
    totalReviews: 0,
    freshnessScore: 94,
    amenities: ['plage', 'promenade', 'famille', 'coucher de soleil'],
    openingHours: fullWeek24('Baignade et activites conseillees surtout en journee.'),
    photos: [
      {
        url: '/uploads/sites/seed-agadir-plage-d-agadir-1.jpg',
        caption: 'Promenade et plage urbaine d Agadir.',
        altText: 'Plage d Agadir et sa corniche'
      }
    ]
  },
  {
    name: 'Souk El Had d Agadir',
    categoryName: 'Shopping',
    subcategory: 'Marche traditionnel',
    description:
      'Grand marche couvert tres frequente pour les epices, artisanats, vetements et achats du quotidien, ideal pour une immersion locale.',
    latitude: 30.4224,
    longitude: -9.5769,
    address: 'Avenue Abderrahim Bouabid',
    priceRange: 'BUDGET',
    acceptsCardPayment: false,
    hasWifi: false,
    hasParking: true,
    isAccessible: true,
    isFeatured: true,
    averageRating: 4.5,
    totalReviews: 0,
    freshnessScore: 89,
    amenities: ['artisanat', 'epices', 'shopping local', 'souvenirs'],
    openingHours: fullWeek('08:30:00', '21:30:00', 'Affluence plus forte en fin d apres-midi.'),
    photos: [
      {
        url: '/uploads/sites/seed-agadir-souk-el-had-d-agadir-1.jpg',
        caption: 'Allee coloree et artisanale du Souk El Had.',
        altText: 'Souk El Had d Agadir'
      }
    ]
  },
  {
    name: 'Marina d Agadir',
    categoryName: 'Shopping',
    subcategory: 'Promenade marina',
    description:
      'Zone de promenade moderne avec restaurants, boutiques et vue portuaire, pratique pour les sorties en soiree et les balades.',
    latitude: 30.4265,
    longitude: -9.6127,
    address: 'Marina d Agadir',
    priceRange: 'MODERATE',
    acceptsCardPayment: true,
    hasWifi: true,
    hasParking: true,
    isAccessible: true,
    isFeatured: true,
    averageRating: 4.4,
    totalReviews: 0,
    freshnessScore: 90,
    amenities: ['restaurants', 'shopping', 'promenade', 'vue port'],
    openingHours: fullWeek24('Les commerces et restaurants ont leurs propres horaires.'),
    photos: [
      {
        url: '/uploads/sites/seed-agadir-marina-d-agadir-1.jpg',
        caption: 'Vue sur les quais et les residences de la marina.',
        altText: 'Marina d Agadir'
      }
    ]
  },
  {
    name: 'Vallee des Oiseaux d Agadir',
    categoryName: 'Park',
    subcategory: 'Parc familial',
    description:
      'Petit parc central agreable pour une pause ombragee, apprecie par les familles et les visiteurs qui explorent le centre-ville a pied.',
    latitude: 30.4194,
    longitude: -9.5989,
    address: 'Avenue du 20 Aout',
    priceRange: 'BUDGET',
    acceptsCardPayment: false,
    hasWifi: false,
    hasParking: false,
    isAccessible: true,
    isFeatured: true,
    averageRating: 4.1,
    totalReviews: 0,
    freshnessScore: 85,
    amenities: ['parc', 'famille', 'pause ombragee', 'centre-ville'],
    openingHours: fullWeek('09:00:00', '19:00:00', 'Parc urbain adapte aux promenades courtes.'),
    photos: [
      {
        url: '/uploads/sites/seed-agadir-vallee-des-oiseaux-d-agadir-1.jpg',
        caption: 'Bassin et oiseaux de la Vallee des Oiseaux.',
        altText: 'Vallee des Oiseaux d Agadir'
      }
    ]
  },
  {
    name: 'Jardin d Olhao',
    categoryName: 'Park',
    subcategory: 'Jardin urbain',
    description:
      'Jardin calme du centre d Agadir, interessant pour souffler entre deux visites et profiter d un cadre plus paisible.',
    latitude: 30.4199,
    longitude: -9.5882,
    address: 'Avenue du President Kennedy',
    priceRange: 'BUDGET',
    acceptsCardPayment: false,
    hasWifi: false,
    hasParking: false,
    isAccessible: true,
    isFeatured: false,
    averageRating: 4.0,
    totalReviews: 0,
    freshnessScore: 82,
    amenities: ['jardin', 'pause', 'balade', 'detente'],
    openingHours: fullWeek('08:00:00', '19:00:00', 'Cadre tranquille en journee.'),
    photos: [
      {
        url: '/uploads/sites/seed-agadir-jardin-d-olhao-1.jpg',
        caption: 'Allees vegetales du Jardin d Olhao.',
        altText: 'Jardin d Olhao a Agadir'
      }
    ]
  },
  {
    name: 'Medina d Agadir',
    categoryName: 'Historical Site',
    subcategory: 'Medina reconstituee',
    description:
      'Medina reconstituee a vocation culturelle et artisanale, utile pour decouvrir une ambiance medina dans un parcours simple a visiter.',
    latitude: 30.3929,
    longitude: -9.5506,
    address: 'Ben Sergaou',
    priceRange: 'MODERATE',
    acceptsCardPayment: true,
    hasWifi: false,
    hasParking: true,
    isAccessible: true,
    isFeatured: true,
    averageRating: 4.3,
    totalReviews: 0,
    freshnessScore: 87,
    amenities: ['artisanat', 'architecture', 'balade', 'souvenirs'],
    openingHours: fullWeek('09:00:00', '18:30:00', 'Verification conseillee lors des jours feries.'),
    photos: [
      {
        url: '/uploads/sites/seed-agadir-medina-d-agadir-1.jpg',
        caption: 'Cour principale de la Medina d Agadir.',
        altText: 'Cour de la Medina d Agadir'
      },
      {
        url: '/uploads/sites/seed-agadir-medina-d-agadir-2.jpg',
        caption: 'Couloir voute a l interieur de la Medina d Agadir.',
        altText: 'Couloir interieur de la Medina d Agadir'
      }
    ]
  },
  {
    name: 'Grande Mosquee Mohammed V d Agadir',
    categoryName: 'Religious Site',
    subcategory: 'Mosquee monumentale',
    description:
      'Mosquee majeure du centre d Agadir, remarquable dans le paysage urbain et pertinente pour un parcours culturel exterieur.',
    latitude: 30.4207,
    longitude: -9.589,
    address: 'Centre-ville d Agadir',
    priceRange: 'BUDGET',
    acceptsCardPayment: false,
    hasWifi: false,
    hasParking: true,
    isAccessible: true,
    isFeatured: false,
    averageRating: 4.4,
    totalReviews: 0,
    freshnessScore: 86,
    amenities: ['architecture', 'repere urbain', 'visite exterieure'],
    openingHours: fullWeek('05:00:00', '22:30:00', 'Respect des horaires de priere et des consignes sur place.'),
    photos: [
      {
        url: '/uploads/sites/seed-agadir-grande-mosquee-mohammed-v-d-agadir-1.jpg',
        caption: 'Minaret de la Grande Mosquee Mohammed V d Agadir.',
        altText: 'Grande Mosquee Mohammed V d Agadir'
      }
    ]
  },
  {
    name: 'Theatre de Verdure d Agadir',
    categoryName: 'Entertainment',
    subcategory: 'Scene plein air',
    description:
      'Espace evenementiel de plein air du centre-ville, a surveiller pour les concerts, festivals et rendez-vous culturels.',
    latitude: 30.4158,
    longitude: -9.6016,
    address: 'Proche Boulevard du 20 Aout',
    priceRange: 'MODERATE',
    acceptsCardPayment: true,
    hasWifi: false,
    hasParking: true,
    isAccessible: true,
    isFeatured: false,
    averageRating: 4.0,
    totalReviews: 0,
    freshnessScore: 81,
    amenities: ['concert', 'festival', 'plein air', 'evenementiel'],
    openingHours: fullWeek('10:00:00', '23:00:00', 'Programmation variable selon les evenements.'),
    photos: [
      {
        url: '/uploads/sites/seed-agadir-theatre-de-verdure-d-agadir-1.jpg',
        caption: 'Scene du Theatre de Verdure amenagee pour un evenement.',
        altText: 'Theatre de Verdure d Agadir'
      }
    ]
  }
];

function toFreshnessStatus(score) {
  if (score >= 85) return 'FRESH';
  if (score >= 65) return 'RECENT';
  if (score >= 40) return 'OLD';
  return 'OBSOLETE';
}

function slugify(value) {
  return String(value || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 80);
}

function inferExtension(sourceUrl, contentType = '') {
  const normalizedType = String(contentType || '').toLowerCase();
  if (normalizedType.includes('png')) return '.png';
  if (normalizedType.includes('webp')) return '.webp';
  if (normalizedType.includes('jpeg') || normalizedType.includes('jpg')) return '.jpg';

  try {
    const pathname = new URL(sourceUrl).pathname.toLowerCase();
    const parsedExtension = path.extname(pathname);
    if (['.jpg', '.jpeg', '.png', '.webp'].includes(parsedExtension)) {
      return parsedExtension === '.jpeg' ? '.jpg' : parsedExtension;
    }
  } catch (_error) {
  }

  return '.jpg';
}

async function fileExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch (_error) {
    return false;
  }
}

async function downloadSitePhoto(site, photo, index) {
  const slug = slugify(site.name) || 'site';
  const extension = inferExtension(photo.url, photo.mimeType);
  const filename = `seed-agadir-${slug}-${index + 1}${extension}`;
  const absolutePath = resolveStoredSitePhotoPath(filename);
  const curlBinary = process.platform === 'win32' ? 'curl.exe' : 'curl';

  try {
    await execFileAsync(curlBinary, [
      '--ssl-no-revoke',
      '--http1.1',
      '--fail',
      '--location',
      '--silent',
      '--show-error',
      '--connect-timeout',
      '20',
      '--max-time',
      '180',
      '--user-agent',
      'MoroccoCheckSeeder/1.0 (+http://127.0.0.1)',
      '--output',
      absolutePath,
      photo.url
    ]);
  } catch (error) {
    await fs.rm(absolutePath, { force: true });
    const details = error?.stderr?.trim() || error?.message || 'Erreur reseau inconnue';
    throw new Error(`Telechargement impossible pour ${photo.url}: ${details}`);
  }

  const stats = await fs.stat(absolutePath);
  const mimeType =
    photo.mimeType ||
    (extension === '.png'
      ? 'image/png'
      : extension === '.webp'
        ? 'image/webp'
        : 'image/jpeg');

  return {
    localUrl: buildSitePhotoPublicPath(filename),
    filename,
    mimeType,
    size: stats.size
  };
}

async function prepareLocalSitePhotos(site) {
  const photos = Array.isArray(site.photos)
    ? site.photos.filter((photo) => photo?.url)
    : [];

  if (!photos.length) {
    return [];
  }

  const prepared = [];
  for (const [index, photo] of photos.entries()) {
    const slug = slugify(site.name) || 'site';
    const knownExtensions = ['.jpg', '.png', '.webp'];
    const normalizedSourceUrl = String(photo.url || '').trim();

    if (normalizedSourceUrl.startsWith('/uploads/sites/')) {
      const localFilename = path.basename(normalizedSourceUrl);
      const localPath = resolveStoredSitePhotoPath(localFilename);
      if (!(await fileExists(localPath))) {
        throw new Error(
          `Asset local introuvable pour ${site.name}: ${normalizedSourceUrl}`
        );
      }

      const extension = path.extname(localFilename).toLowerCase();
      prepared.push({
        ...photo,
        url: buildSitePhotoPublicPath(localFilename),
        thumbnailUrl: buildSitePhotoPublicPath(localFilename),
        filename: localFilename,
        mimeType: extension === '.png'
            ? 'image/png'
            : extension === '.webp'
            ? 'image/webp'
            : 'image/jpeg',
        size: (await fs.stat(localPath)).size
      });
      continue;
    }

    let existingLocalPhoto = null;
    for (const extension of knownExtensions) {
      const candidateFilename = `seed-agadir-${slug}-${index + 1}${extension}`;
      const candidatePath = resolveStoredSitePhotoPath(candidateFilename);
      if (await fileExists(candidatePath)) {
        existingLocalPhoto = {
          localUrl: buildSitePhotoPublicPath(candidateFilename),
          filename: candidateFilename,
          mimeType: extension === '.png'
              ? 'image/png'
              : extension === '.webp'
              ? 'image/webp'
              : 'image/jpeg',
          size: (await fs.stat(candidatePath)).size
        };
        break;
      }
    }

    const asset = existingLocalPhoto || await downloadSitePhoto(site, photo, index);
    prepared.push({
      ...photo,
      url: asset.localUrl,
      thumbnailUrl: asset.localUrl,
      filename: asset.filename,
      mimeType: asset.mimeType,
      size: asset.size
    });
  }

  return prepared;
}

async function resolveSeederUserId(connection) {
  const [adminRows] = await connection.query(
    `SELECT id
     FROM users
     WHERE role = 'ADMIN'
     ORDER BY id ASC
     LIMIT 1`
  );

  if (adminRows.length) {
    return Number(adminRows[0].id);
  }

  const [fallbackRows] = await connection.query(
    `SELECT id
     FROM users
     ORDER BY id ASC
     LIMIT 1`
  );

  if (fallbackRows.length) {
    return Number(fallbackRows[0].id);
  }

  throw new Error('Aucun utilisateur disponible pour rattacher les photos seedees.');
}

async function resolveCategoryId(connection, { name, parentName = null }) {
  let rows;

  if (parentName) {
    [rows] = await connection.query(
      `SELECT c.id
       FROM categories c
       INNER JOIN categories parent ON parent.id = c.parent_id
       WHERE c.name = ?
         AND parent.name = ?
       ORDER BY c.id ASC
       LIMIT 1`,
      [name, parentName]
    );
  } else {
    [rows] = await connection.query(
      `SELECT id
       FROM categories
       WHERE name = ?
         AND parent_id IS NULL
       ORDER BY id ASC
       LIMIT 1`,
      [name]
    );
  }

  if (rows.length) {
    return Number(rows[0].id);
  }

  const parentId = parentName
    ? await resolveCategoryId(connection, { name: parentName })
    : null;

  const [result] = await connection.query(
    `INSERT INTO categories (
        name, name_ar, description, icon, color, parent_id, display_order, is_active
      ) VALUES (?, ?, ?, ?, ?, ?, 999, TRUE)`,
    [name, name, `Categorie ${name} pour le catalogue Agadir`, 'place', '#00AA6C', parentId]
  );

  return Number(result.insertId);
}

async function syncSitePhotos(connection, siteId, site, userId) {
  const photos = Array.isArray(site.photos)
    ? site.photos.filter((photo) => photo?.url)
    : [];

  await connection.query(
    `DELETE FROM photos
     WHERE entity_type = 'SITE'
       AND entity_id = ?
       AND filename LIKE 'seed-agadir-%'`,
    [siteId]
  );

  if (!photos.length) {
    return;
  }

  const slug = slugify(site.name) || `site-${siteId}`;
  const photoValues = photos.map((photo, index) => [
    photo.url,
    photo.thumbnailUrl || photo.url,
    photo.filename || `seed-agadir-${slug}-${index + 1}.jpg`,
    photo.filename || `seed-agadir-${slug}-${index + 1}.jpg`,
    photo.mimeType || 'image/jpeg',
    Number(photo.size || 0),
    photo.width || null,
    photo.height || null,
    userId,
    siteId,
    photo.caption || site.name,
    photo.altText || site.name,
    'ACTIVE',
    'APPROVED',
    index,
    index === 0 ? 1 : 0
  ]);

  await connection.query(
    `INSERT INTO photos (
        url, thumbnail_url, filename, original_filename, mime_type, size,
        width, height, user_id, entity_type, entity_id, caption, alt_text,
        status, moderation_status, display_order, is_primary
      ) VALUES ?`,
    [
      photoValues.map((values) => [
        values[0],
        values[1],
        values[2],
        values[3],
        values[4],
        values[5],
        values[6],
        values[7],
        values[8],
        'SITE',
        values[9],
        values[10],
        values[11],
        values[12],
        values[13],
        values[14],
        values[15]
      ])
    ]
  );
}

async function upsertSite(connection, site, userId) {
  const preparedPhotos = await prepareLocalSitePhotos(site);
  const categoryId = await resolveCategoryId(connection, {
    name: site.categoryName,
    parentName: site.parentCategoryName || null
  });
  const primaryPhotoUrl = site.coverPhoto || preparedPhotos[0]?.url || null;

  const [existingRows] = await connection.query(
    `SELECT id
     FROM tourist_sites
     WHERE name = ?
       AND city = 'Agadir'
       AND deleted_at IS NULL
     ORDER BY id ASC
     LIMIT 1`,
    [site.name]
  );

  const values = [
    site.name,
    site.name,
    site.description,
    null,
    categoryId,
    site.subcategory || null,
    site.latitude,
    site.longitude,
    site.address,
    'Agadir',
    'Souss-Massa',
    null,
    'MA',
    site.phoneNumber || null,
    null,
    site.website || null,
    site.priceRange || null,
    Boolean(site.acceptsCardPayment),
    Boolean(site.hasWifi),
    Boolean(site.hasParking),
    Boolean(site.isAccessible),
    JSON.stringify(site.amenities || []),
    primaryPhotoUrl,
    site.averageRating || 0,
    site.totalReviews || 0,
    site.freshnessScore || 0,
    toFreshnessStatus(site.freshnessScore || 0),
    Boolean(site.isFeatured)
  ];

  let siteId;

  if (existingRows.length) {
    siteId = Number(existingRows[0].id);
    await connection.query(
      `UPDATE tourist_sites
       SET
         name = ?,
         name_ar = ?,
         description = ?,
         description_ar = ?,
         category_id = ?,
         subcategory = ?,
         latitude = ?,
         longitude = ?,
         address = ?,
         city = ?,
         region = ?,
         postal_code = ?,
         country = ?,
         phone_number = ?,
         email = ?,
         website = ?,
         price_range = ?,
         accepts_card_payment = ?,
         has_wifi = ?,
         has_parking = ?,
         is_accessible = ?,
         amenities = ?,
         cover_photo = ?,
         average_rating = ?,
         total_reviews = ?,
         freshness_score = ?,
         freshness_status = ?,
         status = 'PUBLISHED',
         verification_status = 'VERIFIED',
         is_active = TRUE,
         is_featured = ?,
         last_verified_at = NOW(),
         last_updated_at = NOW(),
         updated_at = NOW()
       WHERE id = ?`,
      [...values, siteId]
    );
  } else {
    const [result] = await connection.query(
      `INSERT INTO tourist_sites (
          name, name_ar, description, description_ar, category_id, subcategory,
          latitude, longitude, address, city, region, postal_code, country,
          phone_number, email, website, price_range, accepts_card_payment,
          has_wifi, has_parking, is_accessible, amenities, cover_photo,
          average_rating, total_reviews, freshness_score, freshness_status,
          status, verification_status, is_active, is_featured,
          last_verified_at, last_updated_at
        ) VALUES (
          ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
          ?, ?, ?, ?, 'PUBLISHED', 'VERIFIED', TRUE, ?, NOW(), NOW()
        )`,
      values
    );

    siteId = Number(result.insertId);
  }

  await connection.query('DELETE FROM opening_hours WHERE site_id = ?', [siteId]);

  if (Array.isArray(site.openingHours) && site.openingHours.length) {
    for (const hours of site.openingHours) {
      await connection.query(
        `INSERT INTO opening_hours (
            site_id, day_of_week, opens_at, closes_at, is_closed, is_24_hours, notes
          ) VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [
          siteId,
          hours.dayOfWeek,
          hours.opensAt,
          hours.closesAt,
          Boolean(hours.isClosed),
          Boolean(hours.is24Hours),
          hours.notes || null
        ]
      );
    }
  }

  await syncSitePhotos(connection, siteId, { ...site, photos: preparedPhotos }, userId);

  return siteId;
}

async function seedAgadirCatalog() {
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();
    const seederUserId = await resolveSeederUserId(connection);

    const seededIds = [];
    for (const site of agadirSites) {
      const siteId = await upsertSite(connection, site, seederUserId);
      seededIds.push(siteId);
    }

    await connection.commit();

    console.log(`Agadir catalog seeded successfully: ${seededIds.length} sites prepared.`);
    console.log(`Site IDs: ${seededIds.join(', ')}`);
  } catch (error) {
    await connection.rollback();
    console.error('Failed to seed Agadir catalog:', error.message);
    process.exitCode = 1;
  } finally {
    connection.release();
    await pool.end();
  }
}

await seedAgadirCatalog();
