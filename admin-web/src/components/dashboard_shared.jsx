export function SectionHeader({ badge, copy, count, eyebrow, title }) {
  return (
    <>
      <div className="panel-head">
        <div>
          <p className="eyebrow muted">{eyebrow}</p>
          <h2>{title}</h2>
        </div>
        {(typeof count === 'number' || badge) && (
          <div className="panel-head-meta">
            {typeof count === 'number' && <span className="panel-count">{count}</span>}
            {badge ? <span className="role-pill admin-only">{badge}</span> : null}
          </div>
        )}
      </div>
      {copy ? <p className="panel-copy">{copy}</p> : null}
    </>
  );
}

export function QueueExportActions({ count, onExportCsv, onExportPdf }) {
  return (
    <div className="queue-export-bar">
      <span className="surface-chip strong">{count} element(s) visibles</span>
      <button type="button" className="ghost-button compact" onClick={onExportCsv}>
        Export CSV
      </button>
      <button type="button" className="ghost-button compact" onClick={onExportPdf}>
        Imprimer / PDF
      </button>
    </div>
  );
}

export function StatCard({ isLoading, label, tone, value }) {
  return (
    <article className={`stat-card ${tone}`}>
      <div className="stat-card-top">
        <p>{label}</p>
        <span className="surface-chip">Live</span>
      </div>
      <strong>{isLoading ? '...' : value ?? 0}</strong>
      <span className="stat-caption">Vue consolidee du dashboard admin</span>
    </article>
  );
}

export function TopbarPulse({ label, tone, value }) {
  return (
    <article className={`topbar-pulse ${tone}`}>
      <span>{label}</span>
      <strong>{value}</strong>
    </article>
  );
}

export function InfoChip({ label, value }) {
  return (
    <div className="info-chip">
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  );
}

export function UserDetailCompact({
  expanded = false,
  user,
  statusToClass,
  formatDate,
  formatDateTime
}) {
  if (!user) {
    return (
      <div className="empty-state">
        Aucun compte selectionne pour le moment.
      </div>
    );
  }

  const displayName = [user.first_name, user.last_name].filter(Boolean).join(' ');

  return (
    <div className={`user-detail-card ${expanded ? 'expanded' : ''}`}>
      <div className="user-detail-head">
        <div>
          <h3>{displayName || 'Utilisateur sans nom'}</h3>
          <p className="site-meta">{user.email}</p>
        </div>
        <span className={`status-pill ${statusToClass(user.status)}`}>
          {user.status}
        </span>
      </div>
      <dl className="kpi-list compact">
        <div>
          <dt>Role</dt>
          <dd>{user.role}</dd>
        </div>
        <div>
          <dt>Points</dt>
          <dd>{user.points ?? 0}</dd>
        </div>
        <div>
          <dt>Niveau</dt>
          <dd>{user.level ?? 1}</dd>
        </div>
        <div>
          <dt>Rang</dt>
          <dd>{user.rank || 'BRONZE'}</dd>
        </div>
        <div>
          <dt>Inscrit le</dt>
          <dd>{formatDate(user.created_at)}</dd>
        </div>
        <div>
          <dt>Derniere connexion</dt>
          <dd>{formatDateTime(user.last_login_at)}</dd>
        </div>
      </dl>
    </div>
  );
}
