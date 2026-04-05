import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  NavLink,
  Navigate,
  Outlet,
  Route,
  Routes,
  useNavigate,
  useOutletContext,
  useParams
} from 'react-router-dom';
import {
  API_BASE_URL,
  deleteReviewPhoto,
  fetchAdminReviewDetail,
  fetchAdminSiteDetail,
  fetchAdminStats,
  fetchContributorRequests,
  fetchPendingReviews,
  fetchPendingSites,
  fetchUserById,
  fetchUsers,
  getStoredToken,
  getStoredUser,
  isAdminRole,
  login,
  loginWithGoogle,
  logout,
  moderateReview,
  moderateSite,
  reviewContributorRequest,
  SESSION_CHANGE_EVENT,
  updateUserRole,
  updateUserStatus
} from './lib/api.js';
import {
  getGoogleFirebaseIdToken,
  isFirebaseAuthConfigured
} from './lib/firebase.js';
import {
  InfoChip,
  QueueExportActions,
  SectionHeader,
  StatCard,
  TopbarPulse,
  UserDetailCompact
} from './components/dashboard_shared.jsx';
import {
  ContributorRequestCard,
  PendingReviewCard,
  PendingSiteCard
} from './components/moderation_cards.jsx';

const DASHBOARD_HOME = '/dashboard/overview';

const siteModerationActions = [
  { value: 'APPROVE', label: 'Approuver' },
  { value: 'REJECT', label: 'Rejeter' },
  { value: 'ARCHIVE', label: 'Archiver' }
];

const reviewModerationActions = [
  { value: 'APPROVE', label: 'Publier' },
  { value: 'REJECT', label: 'Rejeter' },
  { value: 'FLAG', label: 'Masquer / signaler' },
  { value: 'SPAM', label: 'Marquer comme spam' }
];

const contributorRequestActions = [
  { value: 'APPROVE', label: 'Approuver' },
  { value: 'REJECT', label: 'Rejeter' }
];

const userStatusOptions = [
  { value: 'ACTIVE', label: 'Actif' },
  { value: 'SUSPENDED', label: 'Suspendu' },
  { value: 'INACTIVE', label: 'Inactif' }
];

const userRoleOptions = [
  { value: '', label: 'Tous les roles' },
  { value: 'ADMIN', label: 'ADMIN' },
  { value: 'PROFESSIONAL', label: 'PROFESSIONAL' },
  { value: 'CONTRIBUTOR', label: 'CONTRIBUTOR' },
  { value: 'TOURIST', label: 'TOURIST' }
];

const userRoleManagementOptions = userRoleOptions.filter((item) => item.value);

const userStatusFilters = [
  { value: '', label: 'Tous les statuts' },
  { value: 'ACTIVE', label: 'Actifs' },
  { value: 'SUSPENDED', label: 'Suspendus' },
  { value: 'INACTIVE', label: 'Inactifs' }
];

const siteSortOptions = [
  { value: 'oldest', label: 'Plus anciens' },
  { value: 'newest', label: 'Plus recents' },
  { value: 'city', label: 'Ville A-Z' },
  { value: 'name', label: 'Nom A-Z' }
];

const reviewSortOptions = [
  { value: 'oldest', label: 'Plus anciens' },
  { value: 'newest', label: 'Plus recents' },
  { value: 'rating_desc', label: 'Note decroissante' },
  { value: 'rating_asc', label: 'Note croissante' }
];

const contributorSortOptions = [
  { value: 'oldest', label: 'Plus anciennes' },
  { value: 'newest', label: 'Plus recentes' },
  { value: 'name', label: 'Nom A-Z' }
];

const contributorStatusOptions = [
  { value: '', label: 'Tous les statuts' },
  { value: 'PENDING', label: 'En attente' },
  { value: 'APPROVED', label: 'Approuvees' },
  { value: 'REJECTED', label: 'Rejetees' },
  { value: 'CANCELLED', label: 'Annulees' }
];

const defaultSiteFilters = {
  q: '',
  city: '',
  region: '',
  sort: 'oldest'
};

const defaultReviewFilters = {
  q: '',
  min_rating: '',
  sort: 'oldest'
};

const defaultContributorFilters = {
  q: '',
  status: 'PENDING',
  sort: 'oldest'
};

const adminLoginHighlights = [
  {
    title: 'Moderation centralisee',
    body: 'Traite les publications de sites, les avis et la qualite generale depuis un seul espace.',
    tone: 'ocean'
  },
  {
    title: 'Lecture rapide',
    body: 'Les cartes, badges de statut et syntheses reduisent le temps de verification.',
    tone: 'forest'
  },
  {
    title: 'Actions immediates',
    body: 'Chaque file propose des decisions claires avec un retour visible dans le produit.',
    tone: 'sand'
  }
];

const dashboardTabs = [
  { to: '/dashboard/overview', index: '01', label: 'Vue d ensemble' },
  { to: '/dashboard/sites', index: '02', label: 'Sites' },
  { to: '/dashboard/reviews', index: '03', label: 'Avis' },
  { to: '/dashboard/contributor-requests', index: '04', label: 'Demandes' },
  { to: '/dashboard/users', index: '05', label: 'Utilisateurs' }
];

function App() {
  const [session, setSession] = useState(() => ({
    token: getStoredToken(),
    user: getStoredUser()
  }));
  const [bootError, setBootError] = useState('');

  const isAuthorized = useMemo(
    () => Boolean(session.token) && isAdminRole(session.user?.role),
    [session]
  );

  useEffect(() => {
    if (session.token && session.user && !isAdminRole(session.user.role)) {
      setBootError(
        'Ce compte est connecte mais ne dispose pas des droits admin.'
      );
    } else {
      setBootError('');
    }
  }, [session]);

  useEffect(() => {
    if (typeof window === 'undefined') {
      return undefined;
    }

    const handleSessionChange = (event) => {
      const detail = event?.detail || {};
      setSession({
        token: getStoredToken(),
        user: getStoredUser()
      });

      if (detail.reason === 'expired') {
        setBootError('Votre session admin a expire. Reconnectez-vous.');
      }
    };

    window.addEventListener(SESSION_CHANGE_EVENT, handleSessionChange);
    return () => {
      window.removeEventListener(SESSION_CHANGE_EVENT, handleSessionChange);
    };
  }, []);

  const handleLoggedIn = (nextSession) => {
    setSession(nextSession);
    setBootError('');
  };

  const handleLoggedOut = async () => {
    await logout();
    setSession({ token: null, user: null });
  };

  return (
    <Routes>
      <Route
        path="/login"
        element={
          isAuthorized ? (
            <Navigate to={DASHBOARD_HOME} replace />
          ) : (
            <div className="app-shell">
              <AdminLoginPage
                bootError={bootError}
                onLoggedIn={handleLoggedIn}
              />
            </div>
          )
        }
      />
      <Route
        path="/dashboard"
        element={
          isAuthorized ? (
            <DashboardLayout user={session.user} onLogout={handleLoggedOut} />
          ) : (
            <Navigate to="/login" replace />
          )
        }
      >
        <Route index element={<Navigate to="overview" replace />} />
        <Route path="overview" element={<OverviewPage />} />
        <Route path="sites" element={<SitesPage />} />
        <Route path="sites/:siteId" element={<SiteDetailPage />} />
        <Route path="reviews" element={<ReviewsPage />} />
        <Route path="reviews/:reviewId" element={<ReviewDetailPage />} />
        <Route path="contributor-requests" element={<ContributorRequestsPage />} />
        <Route path="users" element={<UsersPage />} />
        <Route path="users/:userId" element={<UsersPage />} />
      </Route>
      <Route
        path="*"
        element={
          <Navigate to={isAuthorized ? DASHBOARD_HOME : '/login'} replace />
        }
      />
    </Routes>
  );
}

function AdminLoginPage({ onLoggedIn, bootError }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const googleAuthEnabled = isFirebaseAuthConfigured();

  const handleSubmit = async (event) => {
    event.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      const session = await login(email.trim(), password);
      if (!isAdminRole(session.user?.role)) {
        throw new Error(
          'Ce compte existe mais ne possede pas un role admin.'
        );
      }
      onLoggedIn(session);
    } catch (err) {
      setError(err.message || 'Connexion impossible.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleGoogleSubmit = async () => {
    setIsLoading(true);
    setError('');

    try {
      const idToken = await getGoogleFirebaseIdToken();
      const session = await loginWithGoogle(idToken);
      if (!isAdminRole(session.user?.role)) {
        await logout();
        throw new Error(
          'Ce compte Google existe mais ne possede pas un role admin.'
        );
      }
      onLoggedIn(session);
    } catch (err) {
      setError(err.message || 'Connexion Google impossible.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <main className="login-layout">
      <section className="login-hero">
        <div className="hero-chip-row">
          <span className="surface-chip strong">Console ADMIN</span>
          <span className="surface-chip">API {API_BASE_URL}</span>
        </div>
        <p className="eyebrow">MoroccoCheck Admin</p>
        <h1>Web app admin pour la moderation et le pilotage</h1>
        <p className="hero-copy">
          Interface web separee pour les comptes <code>ADMIN</code>,
          branchee directement sur le backend MoroccoCheck.
        </p>
        <dl className="hero-meta">
          <div>
            <dt>API</dt>
            <dd>{API_BASE_URL}</dd>
          </div>
          <div>
            <dt>Fonctions</dt>
            <dd>Stats, moderation, utilisateurs, suivi des files d attente</dd>
          </div>
        </dl>
        <div className="hero-feature-grid">
          {adminLoginHighlights.map((item) => (
            <article key={item.title} className={`hero-feature ${item.tone}`}>
              <p className="eyebrow muted">Admin flow</p>
              <h3>{item.title}</h3>
              <p>{item.body}</p>
            </article>
          ))}
        </div>
      </section>
      <section className="login-card-wrap">
        <form className="login-card" onSubmit={handleSubmit}>
          <div>
            <p className="eyebrow muted">Connexion securisee</p>
            <h2>Entrer dans le dashboard</h2>
            <p className="muted-copy">
              Utilise un compte <code>ADMIN</code> (email/mot de passe ou Google).
            </p>
          </div>
          {googleAuthEnabled ? (
            <>
              <button
                type="button"
                className="google-sso-button"
                onClick={handleGoogleSubmit}
                disabled={isLoading}
                aria-label="Continuer avec Google"
              >
                <span className="google-sso-icon" aria-hidden="true">
                  G
                </span>
                {isLoading ? 'Connexion...' : 'Continuer avec Google'}
              </button>
              <div className="divider-row" aria-hidden="true">
                <span />
                <p>ou</p>
                <span />
              </div>
            </>
          ) : null}
          <label className="field">
            <span>Email</span>
            <input
              type="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              required
            />
          </label>
          <label className="field">
            <span>Mot de passe</span>
            <input
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              required
            />
          </label>
          {(bootError || error) && (
            <div className="alert error">{bootError || error}</div>
          )}
          <button type="submit" className="primary-button" disabled={isLoading}>
            {isLoading ? 'Connexion...' : 'Se connecter'}
          </button>
        </form>
      </section>
    </main>
  );
}

function DashboardLayout({ onLogout, user }) {
  const [stats, setStats] = useState(null);
  const [pendingSites, setPendingSites] = useState([]);
  const [pendingReviews, setPendingReviews] = useState([]);
  const [contributorRequests, setContributorRequests] = useState([]);
  const [users, setUsers] = useState([]);
  const [sitePagination, setSitePagination] = useState({ page: 1, limit: 5, total: 0 });
  const [reviewPagination, setReviewPagination] = useState({
    page: 1,
    limit: 5,
    total: 0
  });
  const [contributorRequestPagination, setContributorRequestPagination] = useState({
    page: 1,
    limit: 5,
    total: 0
  });
  const [userPagination, setUserPagination] = useState({ page: 1, limit: 10, total: 0 });
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const [siteFilters, setSiteFilters] = useState(defaultSiteFilters);
  const [reviewFilters, setReviewFilters] = useState(defaultReviewFilters);
  const [contributorFilters, setContributorFilters] = useState(
    defaultContributorFilters
  );
  const [userFilters, setUserFilters] = useState({
    q: '',
    role: '',
    status: ''
  });
  const isAdmin = user?.role === 'ADMIN';
  const queueStats = [
    {
      label: 'Sites a traiter',
      value: isLoading ? '...' : stats?.pending_sites ?? 0,
      tone: 'sand'
    },
    {
      label: 'Avis a verifier',
      value: isLoading ? '...' : stats?.pending_reviews ?? 0,
      tone: 'ocean'
    },
    {
      label: 'Demandes contributeur',
      value: isLoading ? '...' : stats?.pending_contributor_requests ?? 0,
      tone: 'blue'
    },
    {
      label: 'Comptes suspendus',
      value: isLoading ? '...' : stats?.suspended_users ?? 0,
      tone: 'forest'
    }
  ];

  const loadDashboard = useCallback(async () => {
    setIsLoading(true);
    setError('');
    try {
      const [
        statsData,
        pendingSitesData,
        pendingReviewsData,
        contributorRequestsData,
        usersData
      ] =
        await Promise.all([
          fetchAdminStats(),
          fetchPendingSites({
            ...siteFilters,
            page: sitePagination.page,
            limit: sitePagination.limit
          }),
          fetchPendingReviews({
            ...reviewFilters,
            page: reviewPagination.page,
            limit: reviewPagination.limit
          }),
          fetchContributorRequests({
            ...contributorFilters,
            page: contributorRequestPagination.page,
            limit: contributorRequestPagination.limit
          }),
          fetchUsers({
            ...userFilters,
            page: userPagination.page,
            limit: userPagination.limit
          })
        ]);

      setStats(statsData);
      setPendingSites(pendingSitesData.items);
      setPendingReviews(pendingReviewsData.items);
      setContributorRequests(contributorRequestsData.items);
      setUsers(usersData?.items || []);
      setSitePagination((current) => ({
        ...current,
        ...pendingSitesData.meta
      }));
      setReviewPagination((current) => ({
        ...current,
        ...pendingReviewsData.meta
      }));
      setContributorRequestPagination((current) => ({
        ...current,
        ...contributorRequestsData.meta
      }));
      setUserPagination((current) => ({
        ...current,
        ...usersData.meta
      }));
    } catch (err) {
      setError(err.message || 'Impossible de charger le dashboard admin.');
    } finally {
      setIsLoading(false);
    }
  }, [
    contributorFilters,
    contributorRequestPagination.limit,
    contributorRequestPagination.page,
    reviewFilters,
    reviewPagination.limit,
    reviewPagination.page,
    siteFilters,
    sitePagination.limit,
    sitePagination.page,
    userFilters,
    userPagination.limit,
    userPagination.page
  ]);

  useEffect(() => {
    loadDashboard();
  }, [loadDashboard]);

  return (
    <div className="dashboard-layout">
      <header className="topbar">
        <div className="topbar-main">
          <div className="hero-chip-row">
            <span className="surface-chip strong">Tour de controle</span>
            <span className="surface-chip">Maj {formatDateTime(new Date())}</span>
          </div>
          <p className="eyebrow">Dashboard admin</p>
          <h1>MoroccoCheck Control Room</h1>
          <p className="topbar-copy">
            Vue operationnelle pour surveiller les contenus publies, les demandes en attente
            et les comptes sensibles.
          </p>
          <div className="topbar-identity">
            <span className="surface-chip strong">
              {user?.first_name} {user?.last_name}
            </span>
            <span className="role-pill">{user?.role}</span>
            <span className="surface-chip">API {API_BASE_URL}</span>
          </div>
        </div>
        <div className="topbar-side">
          <div className="topbar-pulse-grid">
            {queueStats.map((item) => (
              <TopbarPulse key={item.label} {...item} />
            ))}
          </div>
          <div className="topbar-actions">
            <button className="ghost-button" onClick={loadDashboard}>
              Actualiser
            </button>
            <button className="ghost-button danger" onClick={onLogout}>
              Deconnexion
            </button>
          </div>
        </div>
      </header>

      <DashboardTabs />

      {error && <div className="alert error">{error}</div>}

      <section className="stats-grid">
        <StatCard
          label="Utilisateurs"
          value={stats?.users}
          tone="blue"
          isLoading={isLoading}
        />
        <StatCard label="Sites" value={stats?.sites} tone="green" isLoading={isLoading} />
        <StatCard
          label="Sites en attente"
          value={stats?.pending_sites}
          tone="orange"
          isLoading={isLoading}
        />
        <StatCard
          label="Avis en attente"
          value={stats?.pending_reviews}
          tone="sand"
          isLoading={isLoading}
        />
        <StatCard
          label="Demandes contributeur"
          value={stats?.pending_contributor_requests}
          tone="blue"
          isLoading={isLoading}
        />
      </section>

      <Outlet
        context={{
          contributorRequestPagination,
          contributorRequests,
          isAdmin,
          isLoading,
          loadDashboard,
          pendingReviews,
          pendingSites,
          contributorFilters,
          reviewPagination,
          reviewFilters,
          setContributorFilters,
          setContributorRequestPagination,
          setReviewFilters,
          setReviewPagination,
          setSiteFilters,
          setSitePagination,
          setUserPagination,
          sitePagination,
          siteFilters,
          stats,
          userFilters,
          userPagination,
          users,
          setUserFilters
        }}
      />
    </div>
  );
}

function DashboardTabs() {
  return (
    <nav className="dashboard-tabs" aria-label="Navigation admin">
      {dashboardTabs.map((item) => (
        <NavLink
          key={item.to}
          className={({ isActive }) => tabClassName(isActive)}
          to={item.to}
        >
          <span className="tab-index">{item.index}</span>
          <span>{item.label}</span>
        </NavLink>
      ))}
    </nav>
  );
}

function OverviewPage() {
  const { isAdmin, isLoading, pendingReviews, pendingSites, stats, users } =
    useAdminContext();
  const navigate = useNavigate();
  const featuredUser = users[0] || null;

  return (
    <section className="overview-grid">
      <div className="panel overview-hero-panel">
        <SectionHeader
          eyebrow="Resume"
          title="Priorites du poste admin"
          copy="Vue rapide pour prioriser les actions du jour avant d entrer dans les ecrans specialises."
        />
        <div className="summary-grid">
          <SummaryActionCard
            label="Sites a traiter"
            value={isLoading ? '...' : stats?.pending_sites ?? pendingSites.length}
            helper="Demandes de publication ou de verification"
            tone="sand"
            onOpen={() => navigate('/dashboard/sites')}
          />
          <SummaryActionCard
            label="Avis a moderer"
            value={isLoading ? '...' : stats?.pending_reviews ?? pendingReviews.length}
            helper="Contributions de la communaute en attente"
            tone="ocean"
            onOpen={() => navigate('/dashboard/reviews')}
          />
          <SummaryActionCard
            label="Comptes a surveiller"
            value={isLoading ? '...' : stats?.suspended_users ?? 0}
            helper="Utilisateurs deja suspendus ou a verifier"
            tone="forest"
            onOpen={() => navigate('/dashboard/users')}
          />
          <SummaryActionCard
            label="Demandes contributeur"
            value={isLoading ? '...' : stats?.pending_contributor_requests ?? 0}
            helper="Demandes explicites a valider cote admin"
            tone="ocean"
            onOpen={() => navigate('/dashboard/contributor-requests')}
          />
        </div>
        <div className="overview-signal-row">
          <div className="signal-card">
            <span>Charge moderation</span>
            <strong>{isLoading ? '...' : (stats?.pending_sites ?? 0) + (stats?.pending_reviews ?? 0)}</strong>
            <p>Elements cumules en attente d une decision humaine.</p>
          </div>
          <div className="signal-card">
            <span>Etat plateforme</span>
            <strong>{isLoading ? '...' : stats?.users ?? 0} comptes</strong>
            <p>Base active actuellement remontee dans l espace de controle.</p>
          </div>
        </div>
      </div>
      <div className="panel">
        <SectionHeader
          eyebrow="Pilotage"
          title="Contexte du lot"
          copy="La web app couvre maintenant les trois zones critiques: sites, avis et comptes utilisateurs."
        />
        <ul className="feature-list">
          <li>Connexion reelle ADMIN</li>
          <li>Routes URL dediees pour chaque espace du dashboard</li>
          <li>Moderation des sites avec note persistante</li>
          <li>Moderation des avis en attente</li>
          <li>Detail utilisateur restorable via URL</li>
        </ul>
      </div>
      <div className="panel">
        <SectionHeader
          eyebrow="Focus"
          title="Utilisateur mis en avant"
          copy="Mini synthese pour garder un contexte humain pendant la gestion des comptes."
        />
        <UserDetailCompact
          user={featuredUser}
          statusToClass={statusToClass}
          formatDate={formatDate}
          formatDateTime={formatDateTime}
        />
      </div>
      <div className="panel">
        <SectionHeader
          eyebrow="Etat global"
          title="Vue d ensemble"
          copy="Ce bloc aide a verifier rapidement si la plateforme reste active et saine."
        />
        <dl className="kpi-list">
          <div>
            <dt>Total utilisateurs</dt>
            <dd>{isLoading ? '...' : stats?.users ?? 0}</dd>
          </div>
          <div>
            <dt>Total sites</dt>
            <dd>{isLoading ? '...' : stats?.sites ?? 0}</dd>
          </div>
          <div>
            <dt>Total reviews</dt>
            <dd>{isLoading ? '...' : stats?.reviews ?? 0}</dd>
          </div>
          <div>
            <dt>Total check-ins</dt>
            <dd>{isLoading ? '...' : stats?.checkins ?? 0}</dd>
          </div>
          <div>
            <dt>Acces utilisateur</dt>
            <dd>{isAdmin ? 'Edition complete' : 'Consultation + moderation'}</dd>
          </div>
          <div>
            <dt>Liste comptes chargee</dt>
            <dd>{isLoading ? '...' : users.length}</dd>
          </div>
        </dl>
      </div>
    </section>
  );
}

function SitesPage() {
  const {
    isLoading,
    loadDashboard,
    pendingSites,
    setSiteFilters,
    setSitePagination,
    siteFilters,
    sitePagination
  } = useAdminContext();

  return (
    <section className="panel">
      <SectionHeader
        eyebrow="Moderation sites"
        title="Sites en attente"
        count={pendingSites.length}
        copy="Validation ou rejet d un lieu avec note persistante visible ensuite cote professionnel."
      />
      <SiteQueueToolbar
        filters={siteFilters}
        items={pendingSites}
        onExportPdf={() => printCurrentPage()}
        onExportCsv={() =>
          exportRowsToCsv('admin-sites-en-attente.csv', [
            { key: 'id', label: 'ID' },
            { key: 'name', label: 'Nom' },
            { key: 'city', label: 'Ville' },
            { key: 'region', label: 'Region' },
            { key: 'category_name', label: 'Categorie' },
            { key: 'owner_name', label: 'Proprietaire' },
            { key: 'owner_email', label: 'Email proprietaire' },
            { key: 'status', label: 'Statut' },
            { key: 'verification_status', label: 'Verification' },
            { key: 'created_at', label: 'Soumis le' }
          ], pendingSites.map((item) => ({
            ...item,
            owner_name: [item.owner_first_name, item.owner_last_name]
              .filter(Boolean)
              .join(' ')
          })))
        }
        onFiltersChange={(updater) => {
          setSitePagination((current) => ({ ...current, page: 1 }));
          setSiteFilters(updater);
        }}
      />
      <PendingSitesList
        items={pendingSites}
        isLoading={isLoading}
        onModerated={loadDashboard}
      />
      <PaginationControls
        pagination={sitePagination}
        onPageChange={(page) =>
          setSitePagination((current) => ({ ...current, page }))
        }
        onLimitChange={(limit) =>
          setSitePagination((current) => ({ ...current, page: 1, limit }))
        }
      />
    </section>
  );
}

function SiteDetailPage() {
  const { siteId } = useParams();
  const { loadDashboard } = useAdminContext();
  const navigate = useNavigate();
  const [site, setSite] = useState(null);
  const [isLoadingDetail, setIsLoadingDetail] = useState(true);
  const [error, setError] = useState('');
  const [action, setAction] = useState('APPROVE');
  const [notes, setNotes] = useState('');
  const [feedback, setFeedback] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const loadDetail = useCallback(async () => {
    setIsLoadingDetail(true);
    setError('');
    try {
      const detail = await fetchAdminSiteDetail(siteId);
      setSite(detail);
      setNotes(detail.moderation_notes || '');
    } catch (err) {
      setError(err.message || 'Impossible de charger la fiche site.');
    } finally {
      setIsLoadingDetail(false);
    }
  }, [siteId]);

  useEffect(() => {
    loadDetail();
  }, [loadDetail]);

  const handleModeration = async () => {
    setIsSubmitting(true);
    setFeedback('');
    try {
      await moderateSite(siteId, action, notes);
      setFeedback('Decision de moderation enregistree.');
      await Promise.all([loadDetail(), loadDashboard()]);
    } catch (err) {
      setFeedback(err.message || 'Moderation impossible.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <section className="detail-page">
      <div className="detail-toolbar">
        <button
          type="button"
          className="ghost-button compact"
          onClick={() => navigate('/dashboard/sites')}
        >
          Retour aux sites
        </button>
      </div>
      {isLoadingDetail ? (
        <div className="panel empty-state">Chargement de la fiche site...</div>
      ) : error ? (
        <div className="panel alert error">{error}</div>
      ) : (
        <div className="detail-grid">
          <article className="panel">
            <SectionHeader
              eyebrow="Detail site"
              title={site?.name || 'Site'}
              badge={site?.verification_status || 'PENDING'}
              copy={`${site?.city || 'Ville inconnue'}${site?.region ? `, ${site.region}` : ''}`}
            />
            <dl className="kpi-list">
              <div>
                <dt>Categorie</dt>
                <dd>{site?.category_name || 'Non renseignee'}</dd>
              </div>
              <div>
                <dt>Statut publication</dt>
                <dd>{site?.status || 'Inconnu'}</dd>
              </div>
              <div>
                <dt>Adresse</dt>
                <dd>{site?.address || 'Non renseignee'}</dd>
              </div>
              <div>
                <dt>Contact</dt>
                <dd>{site?.phone_number || site?.email || 'Non renseigne'}</dd>
              </div>
              <div>
                <dt>Note moyenne</dt>
                <dd>{formatRating(site?.average_rating)}</dd>
              </div>
              <div>
                <dt>Total avis</dt>
                <dd>{site?.total_reviews ?? 0}</dd>
              </div>
              <div>
                <dt>Fraicheur</dt>
                <dd>
                  {site?.freshness_score ?? 0} / 100 · {site?.freshness_status || 'N/A'}
                </dd>
              </div>
              <div>
                <dt>Derniere verification</dt>
                <dd>{formatDateTime(site?.last_verified_at)}</dd>
              </div>
            </dl>
            <div className="detail-block">
              <p className="eyebrow muted">Description</p>
              <p>{site?.description || 'Aucune description soumise.'}</p>
            </div>
          </article>

          <article className="panel">
            <SectionHeader
              eyebrow="Soumission"
              title="Contexte proprietaire"
              copy="Informations utiles pour juger la publication ou demander une correction."
            />
            <dl className="kpi-list">
              <div>
                <dt>Proprietaire</dt>
                <dd>
                  {site?.owner_first_name || ''} {site?.owner_last_name || ''}
                </dd>
              </div>
              <div>
                <dt>Email proprietaire</dt>
                <dd>{site?.owner_email || 'Non renseigne'}</dd>
              </div>
              <div>
                <dt>Coordonnees GPS</dt>
                <dd>
                  {site?.latitude}, {site?.longitude}
                </dd>
              </div>
              <div>
                <dt>URL</dt>
                <dd>{site?.website || 'Aucune'}</dd>
              </div>
              <div>
                <dt>Cree le</dt>
                <dd>{formatDateTime(site?.created_at)}</dd>
              </div>
              <div>
                <dt>Mis a jour le</dt>
                <dd>{formatDateTime(site?.updated_at)}</dd>
              </div>
              <div>
                <dt>Derniere moderation</dt>
                <dd>{formatDateTime(site?.moderated_at)}</dd>
              </div>
              <div>
                <dt>Moderateur</dt>
                <dd>
                  {site?.moderator_first_name || site?.moderator_last_name
                    ? `${site?.moderator_first_name || ''} ${site?.moderator_last_name || ''}`.trim()
                    : 'Aucun'}
                </dd>
              </div>
            </dl>
          </article>

          <article className="panel">
            <SectionHeader
              eyebrow="Moderation"
              title="Decision admin"
              copy="Cette decision sera visible cote professionnel avec la note associee."
            />
            <ModerationForm
              action={action}
              actions={siteModerationActions}
              feedback={feedback}
              isSubmitting={isSubmitting}
              notes={notes}
              onActionChange={setAction}
              onNotesChange={setNotes}
              onSubmit={handleModeration}
              submitLabel="Enregistrer la decision"
            />
          </article>
        </div>
      )}
    </section>
  );
}

function ReviewsPage() {
  const {
    isLoading,
    loadDashboard,
    pendingReviews,
    reviewFilters,
    reviewPagination,
    setReviewFilters,
    setReviewPagination
  } = useAdminContext();

  return (
    <section className="panel">
      <SectionHeader
        eyebrow="Moderation avis"
        title="Avis en attente"
        count={pendingReviews.length}
        copy="Publication, rejet ou masquage des avis soumis par la communaute."
      />
      <ReviewQueueToolbar
        filters={reviewFilters}
        items={pendingReviews}
        onExportPdf={() => printCurrentPage()}
        onExportCsv={() =>
          exportRowsToCsv('admin-avis-en-attente.csv', [
            { key: 'id', label: 'ID' },
            { key: 'title', label: 'Titre' },
            { key: 'site_name', label: 'Site' },
            { key: 'author_name', label: 'Auteur' },
            { key: 'email', label: 'Email auteur' },
            { key: 'overall_rating', label: 'Note' },
            { key: 'visit_type', label: 'Type de visite' },
            { key: 'created_at', label: 'Soumis le' }
          ], pendingReviews.map((item) => ({
            ...item,
            author_name: [item.first_name, item.last_name].filter(Boolean).join(' ')
          })))
        }
        onFiltersChange={(updater) => {
          setReviewPagination((current) => ({ ...current, page: 1 }));
          setReviewFilters(updater);
        }}
      />
      <PendingReviewsList
        items={pendingReviews}
        isLoading={isLoading}
        onModerated={loadDashboard}
      />
      <PaginationControls
        pagination={reviewPagination}
        onPageChange={(page) =>
          setReviewPagination((current) => ({ ...current, page }))
        }
        onLimitChange={(limit) =>
          setReviewPagination((current) => ({ ...current, page: 1, limit }))
        }
      />
    </section>
  );
}

function ContributorRequestsPage() {
  const {
    contributorFilters,
    contributorRequestPagination,
    contributorRequests,
    isLoading,
    loadDashboard,
    setContributorFilters,
    setContributorRequestPagination
  } = useAdminContext();

  return (
    <section className="panel">
      <SectionHeader
        eyebrow="Promotion de role"
        title="Demandes CONTRIBUTOR"
        count={contributorRequests.length}
        copy="Validation manuelle des comptes TOURIST ayant complete le profil minimum et verifie leur email."
      />
      <ContributorQueueToolbar
        filters={contributorFilters}
        items={contributorRequests}
        onExportPdf={() => printCurrentPage()}
        onExportCsv={() =>
          exportRowsToCsv('admin-demandes-contributor.csv', [
            { key: 'id', label: 'ID' },
            { key: 'full_name', label: 'Nom' },
            { key: 'email', label: 'Email' },
            { key: 'requested_role', label: 'Role demande' },
            { key: 'status', label: 'Statut demande' },
            { key: 'account_status', label: 'Statut compte' },
            { key: 'is_email_verified', label: 'Email verifie' },
            { key: 'created_at', label: 'Cree le' }
          ], contributorRequests.map((item) => ({
            ...item,
            full_name: [item.first_name, item.last_name].filter(Boolean).join(' '),
            is_email_verified: item.is_email_verified ? 'Oui' : 'Non'
          })))
        }
        onFiltersChange={(updater) => {
          setContributorRequestPagination((current) => ({ ...current, page: 1 }));
          setContributorFilters(updater);
        }}
      />
      <PendingContributorRequestsList
        items={contributorRequests}
        isLoading={isLoading}
        onReviewed={loadDashboard}
      />
      <PaginationControls
        pagination={contributorRequestPagination}
        onPageChange={(page) =>
          setContributorRequestPagination((current) => ({ ...current, page }))
        }
        onLimitChange={(limit) =>
          setContributorRequestPagination((current) => ({ ...current, page: 1, limit }))
        }
      />
    </section>
  );
}

function ReviewDetailPage() {
  const { reviewId } = useParams();
  const { loadDashboard } = useAdminContext();
  const navigate = useNavigate();
  const [review, setReview] = useState(null);
  const [isLoadingDetail, setIsLoadingDetail] = useState(true);
  const [error, setError] = useState('');
  const [action, setAction] = useState('APPROVE');
  const [notes, setNotes] = useState('');
  const [feedback, setFeedback] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [photoFeedback, setPhotoFeedback] = useState('');
  const [deletingPhotoId, setDeletingPhotoId] = useState(null);

  const loadDetail = useCallback(async () => {
    setIsLoadingDetail(true);
    setError('');
    try {
      const detail = await fetchAdminReviewDetail(reviewId);
      setReview(detail);
      setNotes(detail.moderation_notes || '');
    } catch (err) {
      setError(err.message || 'Impossible de charger la fiche avis.');
    } finally {
      setIsLoadingDetail(false);
    }
  }, [reviewId]);

  useEffect(() => {
    loadDetail();
  }, [loadDetail]);

  const handleModeration = async () => {
    setIsSubmitting(true);
    setFeedback('');
    try {
      await moderateReview(reviewId, action, notes);
      setFeedback('Decision de moderation enregistree.');
      await Promise.all([loadDetail(), loadDashboard()]);
    } catch (err) {
      setFeedback(err.message || 'Moderation impossible.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeletePhoto = async (photoId) => {
    setDeletingPhotoId(photoId);
    setPhotoFeedback('');
    try {
      await deleteReviewPhoto(reviewId, photoId);
      setPhotoFeedback('Photo supprimee de la moderation.');
      await Promise.all([loadDetail(), loadDashboard()]);
    } catch (err) {
      setPhotoFeedback(err.message || 'Suppression de photo impossible.');
    } finally {
      setDeletingPhotoId(null);
    }
  };

  return (
    <section className="detail-page">
      <div className="detail-toolbar">
        <button
          type="button"
          className="ghost-button compact"
          onClick={() => navigate('/dashboard/reviews')}
        >
          Retour aux avis
        </button>
      </div>
      {isLoadingDetail ? (
        <div className="panel empty-state">Chargement de la fiche avis...</div>
      ) : error ? (
        <div className="panel alert error">{error}</div>
      ) : (
        <div className="detail-grid">
          <article className="panel">
            <SectionHeader
              eyebrow="Detail avis"
              title={review?.title || 'Avis sans titre'}
              badge={review?.moderation_status || 'PENDING'}
              copy={`${review?.site_name || 'Lieu inconnu'}${review?.site_city ? ` · ${review.site_city}` : ''}`}
            />
            <dl className="kpi-list">
              <div>
                <dt>Note globale</dt>
                <dd>{formatRating(review?.overall_rating)}</dd>
              </div>
              <div>
                <dt>Statut</dt>
                <dd>{review?.status || 'Inconnu'}</dd>
              </div>
              <div>
                <dt>Visite</dt>
                <dd>{review?.visit_type || 'Non renseignee'}</dd>
              </div>
              <div>
                <dt>Date de visite</dt>
                <dd>{formatDate(review?.visit_date)}</dd>
              </div>
              <div>
                <dt>Helpful</dt>
                <dd>{review?.helpful_count ?? 0}</dd>
              </div>
              <div>
                <dt>Reports</dt>
                <dd>{review?.reports_count ?? 0}</dd>
              </div>
            </dl>
            <div className="detail-block">
              <p className="eyebrow muted">Contenu</p>
              <p>{review?.content || 'Aucun contenu.'}</p>
            </div>
          </article>

          <article className="panel">
            <SectionHeader
              eyebrow="Auteur"
              title="Contexte moderation"
              copy="Conserve la trace de l auteur, du lieu et des dernieres decisions."
            />
            <dl className="kpi-list">
              <div>
                <dt>Auteur</dt>
                <dd>
                  {review?.author_first_name || ''} {review?.author_last_name || ''}
                </dd>
              </div>
              <div>
                <dt>Email auteur</dt>
                <dd>{review?.author_email || 'Non renseigne'}</dd>
              </div>
              <div>
                <dt>Lieu</dt>
                <dd>{review?.site_name || 'Inconnu'}</dd>
              </div>
              <div>
                <dt>Region</dt>
                <dd>
                  {review?.site_city || ''}{review?.site_region ? `, ${review.site_region}` : ''}
                </dd>
              </div>
              <div>
                <dt>Cree le</dt>
                <dd>{formatDateTime(review?.created_at)}</dd>
              </div>
              <div>
                <dt>Mis a jour le</dt>
                <dd>{formatDateTime(review?.updated_at)}</dd>
              </div>
              <div>
                <dt>Derniere moderation</dt>
                <dd>{formatDateTime(review?.moderated_at)}</dd>
              </div>
              <div>
                <dt>Moderateur</dt>
                <dd>
                  {review?.moderator_first_name || review?.moderator_last_name
                    ? `${review?.moderator_first_name || ''} ${review?.moderator_last_name || ''}`.trim()
                    : 'Aucun'}
                </dd>
              </div>
            </dl>
          </article>

          <article className="panel">
            <SectionHeader
              eyebrow="Photos"
              title="Medias de l avis"
              count={review?.photos?.length || 0}
              copy="Suppression directe des photos problematiques depuis la fiche de moderation."
            />
            {photoFeedback ? (
              <div
                className={
                  photoFeedback.includes('impossible')
                    ? 'alert error'
                    : 'alert success'
                }
              >
                {photoFeedback}
              </div>
            ) : null}
            {review?.photos?.length ? (
              <div className="photo-grid">
                {review.photos.map((photo) => (
                  <article key={photo.id} className="review-photo-card">
                    <img
                      src={photo.thumbnail_url || photo.url}
                      alt={photo.alt_text || photo.caption || 'Photo avis'}
                    />
                    <div className="review-photo-meta">
                      <strong>{photo.original_filename || photo.filename}</strong>
                      <span>{photo.caption || photo.moderation_status || 'Sans legende'}</span>
                    </div>
                    <button
                      type="button"
                      className="ghost-button compact danger"
                      onClick={() => handleDeletePhoto(photo.id)}
                      disabled={deletingPhotoId === photo.id}
                    >
                      {deletingPhotoId === photo.id ? 'Suppression...' : 'Supprimer la photo'}
                    </button>
                  </article>
                ))}
              </div>
            ) : (
              <div className="empty-state">
                Aucun media attache a cet avis.
              </div>
            )}
          </article>

          <article className="panel">
            <SectionHeader
              eyebrow="Moderation"
              title="Decision admin"
              copy="Publication, rejet ou masquage de l avis avec note explicative."
            />
            <ModerationForm
              action={action}
              actions={reviewModerationActions}
              feedback={feedback}
              isSubmitting={isSubmitting}
              notes={notes}
              onActionChange={setAction}
              onNotesChange={setNotes}
              onSubmit={handleModeration}
              submitLabel="Moderer l avis"
            />
          </article>
        </div>
      )}
    </section>
  );
}

function UsersPage() {
  const { userId } = useParams();
  const {
    isAdmin,
    isLoading,
    loadDashboard,
    setUserFilters,
    setUserPagination,
    userFilters,
    userPagination,
    users
  } = useAdminContext();
  const navigate = useNavigate();
  const userFromPage = users.find((item) => String(item.id) === userId) || null;
  const [selectedUser, setSelectedUser] = useState(userFromPage);
  const [selectedUserError, setSelectedUserError] = useState('');
  const [isLoadingSelectedUser, setIsLoadingSelectedUser] = useState(false);

  useEffect(() => {
    let isCancelled = false;

    const loadSelectedUser = async () => {
      if (!userId) {
        setSelectedUser(null);
        setSelectedUserError('');
        setIsLoadingSelectedUser(false);
        return;
      }

      if (userFromPage) {
        setSelectedUser(userFromPage);
        setSelectedUserError('');
        setIsLoadingSelectedUser(false);
        return;
      }

      setIsLoadingSelectedUser(true);
      setSelectedUserError('');

      try {
        const detail = await fetchUserById(userId);
        if (!isCancelled) {
          setSelectedUser(detail);
        }
      } catch (err) {
        if (!isCancelled) {
          setSelectedUser(null);
          setSelectedUserError(
            err.message || 'Impossible de charger cet utilisateur.'
          );
        }
      } finally {
        if (!isCancelled) {
          setIsLoadingSelectedUser(false);
        }
      }
    };

    loadSelectedUser();
    return () => {
      isCancelled = true;
    };
  }, [userId, userFromPage]);

  return (
    <section className="panel users-panel">
      <SectionHeader
        eyebrow="Gestion utilisateurs"
        title="Comptes et statuts"
        badge={isAdmin ? 'ADMIN' : 'Lecture seule'}
        copy="Les modificateurs de statut sont disponibles uniquement pour ADMIN."
      />
      <UsersSection
        canManage={isAdmin}
        filters={userFilters}
        isLoading={isLoading}
        items={users}
        onExportPdf={() => printCurrentPage()}
        onExportCsv={() =>
          exportRowsToCsv('admin-utilisateurs.csv', [
            { key: 'id', label: 'ID' },
            { key: 'full_name', label: 'Nom' },
            { key: 'email', label: 'Email' },
            { key: 'role', label: 'Role' },
            { key: 'status', label: 'Statut' },
            { key: 'points', label: 'Points' },
            { key: 'level', label: 'Niveau' },
            { key: 'rank', label: 'Rang' },
            { key: 'last_login_at', label: 'Derniere connexion' },
            { key: 'created_at', label: 'Inscrit le' }
          ], users.map((item) => ({
            ...item,
            full_name: [item.first_name, item.last_name].filter(Boolean).join(' ')
          })))
        }
        onFiltersChange={(updater) => {
          setUserPagination((current) => ({ ...current, page: 1 }));
          setUserFilters(updater);
        }}
        onSelectUser={(id) => navigate(`/dashboard/users/${id}`)}
        onUpdated={loadDashboard}
        selectedUserId={selectedUser?.id || null}
      />
      <PaginationControls
        pagination={userPagination}
        onPageChange={(page) =>
          setUserPagination((current) => ({ ...current, page }))
        }
        onLimitChange={(limit) =>
          setUserPagination((current) => ({ ...current, page: 1, limit }))
        }
      />
      <UserDetailPanel
        error={selectedUserError}
        isLoading={isLoadingSelectedUser}
        onClearSelection={() => navigate('/dashboard/users')}
        user={selectedUser}
      />
    </section>
  );
}

function SummaryActionCard({ helper, label, onOpen, tone = 'ocean', value }) {
  return (
    <article className={`summary-card ${tone}`}>
      <div className="summary-card-top">
        <p>{label}</p>
        <span className="surface-chip">Focus</span>
      </div>
      <strong>{value}</strong>
      <span>{helper}</span>
      <button type="button" className="ghost-button compact" onClick={onOpen}>
        Ouvrir
      </button>
    </article>
  );
}

function PaginationControls({ onLimitChange, onPageChange, pagination }) {
  const page = Number(pagination?.page || 1);
  const limit = Number(pagination?.limit || 1);
  const total = Number(pagination?.total || 0);
  const totalPages = Math.max(1, Math.ceil(total / Math.max(limit, 1)));

  return (
    <div className="pagination-bar">
      <div className="pagination-copy">
        <strong>
          Page {page} / {totalPages}
        </strong>
        <span>{total} elements au total</span>
      </div>
      <div className="pagination-actions">
        <label className="page-size-control">
          <span>Par page</span>
          <select
            value={limit}
            onChange={(event) => onLimitChange(Number(event.target.value))}
          >
            {[5, 10, 20, 50].map((option) => (
              <option key={option} value={option}>
                {option}
              </option>
            ))}
          </select>
        </label>
        <button
          type="button"
          className="ghost-button compact"
          onClick={() => onPageChange(page - 1)}
          disabled={page <= 1}
        >
          Precedent
        </button>
        <button
          type="button"
          className="ghost-button compact"
          onClick={() => onPageChange(page + 1)}
          disabled={page >= totalPages}
        >
          Suivant
        </button>
      </div>
    </div>
  );
}

function SiteQueueToolbar({
  filters,
  items,
  onExportCsv,
  onExportPdf,
  onFiltersChange
}) {
  const [searchDraft, setSearchDraft] = useState(filters.q);

  useEffect(() => {
    setSearchDraft(filters.q);
  }, [filters.q]);

  const handleSubmit = (event) => {
    event.preventDefault();
    onFiltersChange((current) => ({ ...current, q: searchDraft.trim() }));
  };

  return (
    <div className="queue-toolbar">
      <form className="filters-grid queue-filters-grid" onSubmit={handleSubmit}>
        <label className="field">
          <span>Recherche</span>
          <input
            type="search"
            value={searchDraft}
            placeholder="Nom, ville, categorie, proprietaire..."
            onChange={(event) => setSearchDraft(event.target.value)}
          />
        </label>
        <label className="field">
          <span>Ville</span>
          <input
            value={filters.city}
            placeholder="Ex. Marrakech"
            onChange={(event) =>
              onFiltersChange((current) => ({
                ...current,
                city: event.target.value
              }))
            }
          />
        </label>
        <label className="field">
          <span>Region</span>
          <input
            value={filters.region}
            placeholder="Ex. Souss-Massa"
            onChange={(event) =>
              onFiltersChange((current) => ({
                ...current,
                region: event.target.value
              }))
            }
          />
        </label>
        <label className="field">
          <span>Tri</span>
          <select
            value={filters.sort}
            onChange={(event) =>
              onFiltersChange((current) => ({
                ...current,
                sort: event.target.value
              }))
            }
          >
            {siteSortOptions.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </label>
        <div className="filters-actions">
          <button type="submit" className="primary-button">
            Filtrer
          </button>
          <button
            type="button"
            className="ghost-button"
            onClick={() => onFiltersChange(defaultSiteFilters)}
          >
            Reinitialiser
          </button>
        </div>
      </form>
      <QueueExportActions
        count={items.length}
        onExportCsv={onExportCsv}
        onExportPdf={onExportPdf}
      />
    </div>
  );
}

function ReviewQueueToolbar({
  filters,
  items,
  onExportCsv,
  onExportPdf,
  onFiltersChange
}) {
  const [searchDraft, setSearchDraft] = useState(filters.q);

  useEffect(() => {
    setSearchDraft(filters.q);
  }, [filters.q]);

  const handleSubmit = (event) => {
    event.preventDefault();
    onFiltersChange((current) => ({ ...current, q: searchDraft.trim() }));
  };

  return (
    <div className="queue-toolbar">
      <form className="filters-grid queue-filters-grid" onSubmit={handleSubmit}>
        <label className="field">
          <span>Recherche</span>
          <input
            type="search"
            value={searchDraft}
            placeholder="Titre, contenu, auteur, site..."
            onChange={(event) => setSearchDraft(event.target.value)}
          />
        </label>
        <label className="field">
          <span>Note minimale</span>
          <select
            value={filters.min_rating}
            onChange={(event) =>
              onFiltersChange((current) => ({
                ...current,
                min_rating: event.target.value
              }))
            }
          >
            <option value="">Toutes</option>
            {[5, 4, 3, 2, 1].map((value) => (
              <option key={value} value={value}>
                {value} / 5 et plus
              </option>
            ))}
          </select>
        </label>
        <label className="field">
          <span>Tri</span>
          <select
            value={filters.sort}
            onChange={(event) =>
              onFiltersChange((current) => ({
                ...current,
                sort: event.target.value
              }))
            }
          >
            {reviewSortOptions.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </label>
        <div className="filters-actions">
          <button type="submit" className="primary-button">
            Filtrer
          </button>
          <button
            type="button"
            className="ghost-button"
            onClick={() => onFiltersChange(defaultReviewFilters)}
          >
            Reinitialiser
          </button>
        </div>
      </form>
      <QueueExportActions
        count={items.length}
        onExportCsv={onExportCsv}
        onExportPdf={onExportPdf}
      />
    </div>
  );
}

function ContributorQueueToolbar({
  filters,
  items,
  onExportCsv,
  onExportPdf,
  onFiltersChange
}) {
  const [searchDraft, setSearchDraft] = useState(filters.q);

  useEffect(() => {
    setSearchDraft(filters.q);
  }, [filters.q]);

  const handleSubmit = (event) => {
    event.preventDefault();
    onFiltersChange((current) => ({ ...current, q: searchDraft.trim() }));
  };

  return (
    <div className="queue-toolbar">
      <form className="filters-grid queue-filters-grid" onSubmit={handleSubmit}>
        <label className="field">
          <span>Recherche</span>
          <input
            type="search"
            value={searchDraft}
            placeholder="Nom, email, role demande..."
            onChange={(event) => setSearchDraft(event.target.value)}
          />
        </label>
        <label className="field">
          <span>Statut</span>
          <select
            value={filters.status}
            onChange={(event) =>
              onFiltersChange((current) => ({
                ...current,
                status: event.target.value
              }))
            }
          >
            {contributorStatusOptions.map((option) => (
              <option key={option.value || 'all'} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </label>
        <label className="field">
          <span>Tri</span>
          <select
            value={filters.sort}
            onChange={(event) =>
              onFiltersChange((current) => ({
                ...current,
                sort: event.target.value
              }))
            }
          >
            {contributorSortOptions.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </label>
        <div className="filters-actions">
          <button type="submit" className="primary-button">
            Filtrer
          </button>
          <button
            type="button"
            className="ghost-button"
            onClick={() => onFiltersChange(defaultContributorFilters)}
          >
            Reinitialiser
          </button>
        </div>
      </form>
      <QueueExportActions
        count={items.length}
        onExportCsv={onExportCsv}
        onExportPdf={onExportPdf}
      />
    </div>
  );
}

function PendingSitesList({ items, isLoading, onModerated }) {
  if (isLoading) {
    return <div className="empty-state">Chargement des sites en attente...</div>;
  }

  if (!items.length) {
    return (
      <div className="empty-state">
        Aucun site en attente pour le moment. Le backlog moderation est vide.
      </div>
    );
  }

  return (
    <div className="card-list">
      {items.map((site) => (
        <PendingSiteCard
          key={site.id}
          site={site}
          onModerated={onModerated}
          InfoChipComponent={InfoChip}
          ModerationFormComponent={ModerationForm}
          formatDate={formatDate}
          moderateSite={moderateSite}
          siteModerationActions={siteModerationActions}
        />
      ))}
    </div>
  );
}

function PendingReviewsList({ items, isLoading, onModerated }) {
  if (isLoading) {
    return <div className="empty-state">Chargement des avis en attente...</div>;
  }

  if (!items.length) {
    return (
      <div className="empty-state">
        Aucun avis en attente. La file de moderation est propre.
      </div>
    );
  }

  return (
    <div className="card-list">
      {items.map((review) => (
        <PendingReviewCard
          key={review.id}
          review={review}
          onModerated={onModerated}
          InfoChipComponent={InfoChip}
          ModerationFormComponent={ModerationForm}
          formatDate={formatDate}
          formatRating={formatRating}
          moderateReview={moderateReview}
          reviewModerationActions={reviewModerationActions}
        />
      ))}
    </div>
  );
}

function PendingContributorRequestsList({ items, isLoading, onReviewed }) {
  if (isLoading) {
    return <div className="empty-state">Chargement des demandes contributor...</div>;
  }

  if (!items.length) {
    return (
      <div className="empty-state">
        Aucune demande contributor en attente pour le moment.
      </div>
    );
  }

  return (
    <div className="card-list">
      {items.map((request) => (
        <ContributorRequestCard
          key={request.id}
          request={request}
          onReviewed={onReviewed}
          InfoChipComponent={InfoChip}
          ModerationFormComponent={ModerationForm}
          formatDateTime={formatDateTime}
          reviewContributorRequest={reviewContributorRequest}
          contributorRequestActions={contributorRequestActions}
        />
      ))}
    </div>
  );
}

function ModerationForm({
  action,
  actions,
  feedback,
  isSubmitting,
  notes,
  onActionChange,
  onNotesChange,
  onSubmit,
  submitLabel
}) {
  return (
    <div className="moderation-box">
      <label className="field">
        <span>Decision</span>
        <select
          value={action}
          onChange={(event) => onActionChange(event.target.value)}
        >
          {actions.map((item) => (
            <option key={item.value} value={item.value}>
              {item.label}
            </option>
          ))}
        </select>
      </label>
      <label className="field">
        <span>Note de moderation</span>
        <textarea
          rows="3"
          placeholder="Expliquer clairement la decision..."
          value={notes}
          onChange={(event) => onNotesChange(event.target.value)}
        />
      </label>
      {feedback && (
        <div
          className={feedback.includes('impossible') ? 'alert error' : 'alert success'}
        >
          {feedback}
        </div>
      )}
      <button
        type="button"
        className="primary-button"
        onClick={onSubmit}
        disabled={isSubmitting}
      >
        {isSubmitting ? 'Enregistrement...' : submitLabel}
      </button>
    </div>
  );
}

function UsersSection({
  canManage,
  filters,
  isLoading,
  items,
  onExportCsv,
  onExportPdf,
  onFiltersChange,
  onSelectUser,
  onUpdated,
  selectedUserId
}) {
  const [searchDraft, setSearchDraft] = useState(filters.q);

  useEffect(() => {
    setSearchDraft(filters.q);
  }, [filters.q]);

  const submitFilters = (event) => {
    event.preventDefault();
    onFiltersChange((current) => ({ ...current, q: searchDraft.trim() }));
  };

  return (
    <div className="users-section">
      <form className="filters-grid" onSubmit={submitFilters}>
        <label className="field">
          <span>Recherche</span>
          <input
            type="search"
            value={searchDraft}
            placeholder="Email, prenom, nom..."
            onChange={(event) => setSearchDraft(event.target.value)}
          />
        </label>
        <label className="field">
          <span>Role</span>
          <select
            value={filters.role}
            onChange={(event) =>
              onFiltersChange((current) => ({
                ...current,
                role: event.target.value
              }))
            }
          >
            {userRoleOptions.map((option) => (
              <option key={option.value || 'all'} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </label>
        <label className="field">
          <span>Statut</span>
          <select
            value={filters.status}
            onChange={(event) =>
              onFiltersChange((current) => ({
                ...current,
                status: event.target.value
              }))
            }
          >
            {userStatusFilters.map((option) => (
              <option key={option.value || 'all'} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </label>
        <div className="filters-actions">
          <button type="submit" className="primary-button">
            Appliquer
          </button>
          <button
            type="button"
            className="ghost-button"
            onClick={() => onFiltersChange({ q: '', role: '', status: '' })}
          >
            Reinitialiser
          </button>
        </div>
      </form>
      <QueueExportActions
        count={items.length}
        onExportCsv={onExportCsv}
        onExportPdf={onExportPdf}
      />

      {isLoading ? (
        <div className="empty-state">Chargement des utilisateurs...</div>
      ) : !items.length ? (
        <div className="empty-state">
          Aucun utilisateur ne correspond aux filtres actuels.
        </div>
      ) : (
        <div className="table-wrap">
          <table className="users-table">
            <thead>
              <tr>
                <th>Utilisateur</th>
                <th>Role</th>
                <th>Statut</th>
                <th>Progression</th>
                <th>Derniere connexion</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {items.map((item) => (
                <UserRow
                  key={item.id}
                  canManage={canManage}
                  isSelected={selectedUserId === item.id}
                  item={item}
                  onSelect={onSelectUser}
                  onUpdated={onUpdated}
                />
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

function UserRow({ canManage, isSelected, item, onSelect, onUpdated }) {
  const [role, setRole] = useState(item.role || 'TOURIST');
  const [status, setStatus] = useState(item.status || 'ACTIVE');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [feedback, setFeedback] = useState('');

  const displayName = [item.first_name, item.last_name].filter(Boolean).join(' ');

  useEffect(() => {
    setRole(item.role || 'TOURIST');
    setStatus(item.status || 'ACTIVE');
  }, [item.role, item.status]);

  const handleUserUpdate = async () => {
    setIsSubmitting(true);
    setFeedback('');

    try {
      let nextRole = role;
      let nextStatus = status;

      if (role !== item.role) {
        const updatedRole = await updateUserRole(item.id, role);
        nextRole = updatedRole.role || nextRole;
      }

      if (status !== item.status) {
        const updatedStatus = await updateUserStatus(item.id, status);
        nextStatus = updatedStatus.status || nextStatus;
      }

      setRole(nextRole);
      setStatus(nextStatus);
      setFeedback('Compte mis a jour.');
      await onUpdated();
    } catch (err) {
      setFeedback(err.message || 'Mise a jour impossible.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <tr
      className={isSelected ? 'table-row-selected' : ''}
      onClick={() => onSelect(item.id)}
    >
      <td>
        <div className="user-identity">
          <strong>{displayName || 'Utilisateur sans nom'}</strong>
          <span>{item.email}</span>
        </div>
      </td>
      <td>
        {canManage ? (
          <select
            value={role}
            onChange={(event) => setRole(event.target.value)}
            onClick={(event) => event.stopPropagation()}
          >
            {userRoleManagementOptions.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        ) : (
          item.role
        )}
      </td>
      <td>
        <span className={`status-pill ${statusToClass(status)}`}>
          {status}
        </span>
      </td>
      <td>
        <div className="user-progress">
          <strong>{item.points ?? 0} pts</strong>
          <span>
            Niveau {item.level ?? 1} | {item.rank || 'BRONZE'}
          </span>
        </div>
      </td>
      <td>{formatDateTime(item.last_login_at)}</td>
      <td onClick={(event) => event.stopPropagation()}>
        {canManage ? (
          <div className="user-actions">
            <select
              value={status}
              onChange={(event) => setStatus(event.target.value)}
            >
              {userStatusOptions.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
            <button
              type="button"
              className="ghost-button compact"
              onClick={handleUserUpdate}
              disabled={
                isSubmitting ||
                (status === item.status && role === item.role)
              }
            >
              {isSubmitting ? 'Mise a jour...' : 'Enregistrer'}
            </button>
          </div>
        ) : (
          <span className="muted-inline">ADMIN requis</span>
        )}
        {feedback && (
          <div
            className={
              feedback.includes('impossible')
                ? 'table-feedback error'
                : 'table-feedback success'
            }
          >
            {feedback}
          </div>
        )}
      </td>
    </tr>
  );
}

function UserDetailPanel({ error, isLoading, onClearSelection, user }) {
  if (isLoading) {
    return (
      <aside className="detail-panel">
        <div className="empty-state">Chargement du detail utilisateur...</div>
      </aside>
    );
  }

  return (
    <aside className="detail-panel">
      <SectionHeader
        eyebrow="Detail utilisateur"
        title={user ? 'Fiche selectionnee' : 'Aucun utilisateur selectionne'}
        copy={
          user
            ? 'Lecture rapide du compte actif pour garder le contexte pendant la moderation.'
            : error || 'Choisis un compte dans le tableau pour voir ses informations ici.'
        }
      />
      {user ? (
        <button
          type="button"
          className="ghost-button compact detail-clear-button"
          onClick={onClearSelection}
        >
          Fermer la fiche
        </button>
      ) : null}
      <UserDetailCompact
        user={user}
        expanded
        statusToClass={statusToClass}
        formatDate={formatDate}
        formatDateTime={formatDateTime}
      />
    </aside>
  );
}

function useAdminContext() {
  return useOutletContext();
}

function tabClassName(isActive) {
  return `tab-button ${isActive ? 'active' : ''}`;
}

function statusToClass(status) {
  switch (status) {
    case 'ACTIVE':
      return 'verified';
    case 'SUSPENDED':
      return 'danger';
    case 'INACTIVE':
      return 'muted';
    default:
      return 'pending';
  }
}

function formatRating(value) {
  const rating = Number(value || 0);
  return `${rating.toFixed(1)} / 5`;
}

function formatDate(value) {
  if (!value) return 'Date inconnue';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return String(value);

  return new Intl.DateTimeFormat('fr-FR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric'
  }).format(date);
}

function formatDateTime(value) {
  if (!value) return 'Jamais';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return String(value);

  return new Intl.DateTimeFormat('fr-FR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  }).format(date);
}

function exportRowsToCsv(filename, columns, rows) {
  const header = columns.map((column) => escapeCsvCell(column.label)).join(',');
  const body = rows
    .map((row) =>
      columns
        .map((column) => escapeCsvCell(row[column.key]))
        .join(',')
    )
    .join('\n');
  const csvContent = `${header}\n${body}`;
  const blob = new Blob([csvContent], {
    type: 'text/csv;charset=utf-8;'
  });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}

function escapeCsvCell(value) {
  const normalized = `${value ?? ''}`.replace(/"/g, '""');
  return `"${normalized}"`;
}

function printCurrentPage() {
  if (typeof window !== 'undefined') {
    window.print();
  }
}

export default App;
