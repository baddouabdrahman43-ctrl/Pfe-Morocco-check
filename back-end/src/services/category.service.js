import pool from '../config/database.js';

export async function listCategories(query = {}) {
  const topLevelOnly =
    query.top_level === 'true' ||
    query.top_level === '1' ||
    query.top_level === true;

  const filters = ['c.is_active = TRUE'];
  const params = [];

  const [rows] = await pool.query(
    `SELECT
        c.id,
        c.name,
        c.name_ar,
        c.description,
        c.icon,
        c.color,
        c.parent_id,
        c.display_order,
        COUNT(ts.id) AS active_sites_count
     FROM categories c
     LEFT JOIN tourist_sites ts
       ON ts.category_id = c.id
      AND ts.deleted_at IS NULL
      AND ts.is_active = TRUE
     WHERE ${filters.join(' AND ')}
     GROUP BY
       c.id,
       c.name,
       c.name_ar,
       c.description,
       c.icon,
       c.color,
       c.parent_id,
       c.display_order
     ORDER BY
       CASE WHEN c.parent_id IS NULL THEN 0 ELSE 1 END,
       c.display_order ASC,
       c.name ASC`,
    params
  );

  const canonicalByKey = new Map();
  const canonicalIdBySourceId = new Map();

  for (const row of rows) {
    const canonicalParentId =
      row.parent_id == null ? null : (canonicalIdBySourceId.get(row.parent_id) ?? row.parent_id);
    const key = `${canonicalParentId ?? 'root'}::${String(row.name || '').trim().toLowerCase()}`;
    const existing = canonicalByKey.get(key);

    if (existing) {
      existing.active_sites_count += Number(row.active_sites_count || 0);
      canonicalIdBySourceId.set(row.id, existing.id);
      continue;
    }

    const category = {
      ...row,
      parent_id: canonicalParentId,
      active_sites_count: Number(row.active_sites_count || 0),
      children: []
    };
    canonicalByKey.set(key, category);
    canonicalIdBySourceId.set(row.id, category.id);
  }

  const categories = [...canonicalByKey.values()];

  const byId = new Map(categories.map((category) => [category.id, category]));
  const roots = [];

  for (const category of categories) {
    if (category.parent_id == null) {
      roots.push(category);
      continue;
    }

    const canonicalParentId = canonicalIdBySourceId.get(category.parent_id);
    const parent = byId.get(canonicalParentId);
    if (parent) {
      parent.children.push(category);
    }
  }

  if (topLevelOnly) {
    return roots;
  }

  return categories;
}
