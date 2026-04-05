import { useState } from 'react';
import { useNavigate } from 'react-router-dom';

export function PendingSiteCard({
  site,
  onModerated,
  _InfoChipComponent: InfoChipComponent,
  _ModerationFormComponent: ModerationFormComponent,
  formatDate,
  moderateSite,
  siteModerationActions
}) {
  const navigate = useNavigate();
  const [action, setAction] = useState('APPROVE');
  const [notes, setNotes] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [feedback, setFeedback] = useState('');
  const ownerName = [site.owner_first_name, site.owner_last_name]
    .filter(Boolean)
    .join(' ')
    .trim();

  const handleModeration = async () => {
    setIsSubmitting(true);
    setFeedback('');

    try {
      const result = await moderateSite(site.id, action, notes);
      setFeedback(
        action === 'APPROVE'
          ? 'Site approuve et publie.'
          : `Decision enregistree: ${result.verification_status}.`
      );
      setNotes('');
      await onModerated();
    } catch (err) {
      setFeedback(err.message || 'Moderation impossible.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <article className="admin-card">
      <div className="card-head">
        <div>
          <p className="eyebrow muted">Publication en attente</p>
          <h3>{site.name}</h3>
          <p className="site-meta">
            {site.city}, {site.region}
          </p>
        </div>
        <span className="status-pill pending">PENDING</span>
      </div>
      <div className="chip-row">
        <InfoChipComponent label="Owner" value={ownerName || 'Non renseigne'} />
        <InfoChipComponent label="Soumis" value={formatDate(site.created_at)} />
        <InfoChipComponent label="Etat" value={site.status || 'PENDING_REVIEW'} />
      </div>
      <dl className="entity-details">
        <div>
          <dt>Proprietaire</dt>
          <dd>{ownerName || 'Non renseigne'}</dd>
        </div>
        <div>
          <dt>Soumis le</dt>
          <dd>{formatDate(site.created_at)}</dd>
        </div>
      </dl>
      <div className="card-actions">
        <button
          type="button"
          className="ghost-button compact"
          onClick={() => navigate(`/dashboard/sites/${site.id}`)}
        >
          Ouvrir la fiche
        </button>
      </div>
      <ModerationFormComponent
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
  );
}

export function ContributorRequestCard({
  onReviewed,
  request,
  _InfoChipComponent: InfoChipComponent,
  _ModerationFormComponent: ModerationFormComponent,
  formatDateTime,
  reviewContributorRequest,
  contributorRequestActions
}) {
  const [action, setAction] = useState('APPROVE');
  const [notes, setNotes] = useState('');
  const [feedback, setFeedback] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const applicantName = [request.first_name, request.last_name].filter(Boolean).join(' ');
  const missingFields = request.eligibility?.missing_fields || [];

  const handleReview = async () => {
    setIsSubmitting(true);
    setFeedback('');

    try {
      const result = await reviewContributorRequest(request.id, action, notes);
      setFeedback(
        action === 'APPROVE'
          ? `Demande approuvee. Role mis a jour vers ${result.requested_role || 'CONTRIBUTOR'}.`
          : 'Demande rejetee.'
      );
      setNotes('');
      await onReviewed();
    } catch (err) {
      setFeedback(err.message || 'Traitement de la demande impossible.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <article className="admin-card">
      <div className="card-head">
        <div>
          <p className="eyebrow muted">Demande explicite</p>
          <h3>{applicantName || 'Utilisateur sans nom'}</h3>
          <p className="site-meta">{request.email}</p>
        </div>
        <span className="status-pill pending">{request.status || 'PENDING'}</span>
      </div>
      <div className="chip-row">
        <InfoChipComponent
          label="Statut compte"
          value={request.account_status || 'ACTIVE'}
        />
        <InfoChipComponent
          label="Email verifie"
          value={request.is_email_verified ? 'Oui' : 'Non'}
        />
        <InfoChipComponent
          label="Telephone"
          value={request.phone_number || 'Non renseigne'}
        />
        <InfoChipComponent
          label="Nationalite"
          value={request.nationality || 'Non renseignee'}
        />
      </div>
      <div className="detail-block">
        <p className="eyebrow muted">Motivation</p>
        <p>{request.motivation || 'Aucune motivation fournie.'}</p>
      </div>
      <dl className="entity-details">
        <div>
          <dt>Bio</dt>
          <dd>{request.bio || 'Bio non renseignee'}</dd>
        </div>
        <div>
          <dt>Demandee le</dt>
          <dd>{formatDateTime(request.created_at)}</dd>
        </div>
      </dl>
      {missingFields.length > 0 && (
        <div className="alert error">
          Profil incomplet: {missingFields.join(', ')}
        </div>
      )}
      <ModerationFormComponent
        action={action}
        actions={contributorRequestActions}
        feedback={feedback}
        isSubmitting={isSubmitting}
        notes={notes}
        onActionChange={setAction}
        onNotesChange={setNotes}
        onSubmit={handleReview}
        submitLabel="Traiter la demande"
      />
    </article>
  );
}

export function PendingReviewCard({
  review,
  onModerated,
  _InfoChipComponent: InfoChipComponent,
  _ModerationFormComponent: ModerationFormComponent,
  formatDate,
  formatRating,
  moderateReview,
  reviewModerationActions
}) {
  const navigate = useNavigate();
  const [action, setAction] = useState('APPROVE');
  const [notes, setNotes] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [feedback, setFeedback] = useState('');
  const authorName = [review.first_name, review.last_name]
    .filter(Boolean)
    .join(' ')
    .trim();

  const handleModeration = async () => {
    setIsSubmitting(true);
    setFeedback('');

    try {
      const result = await moderateReview(review.id, action, notes);
      setFeedback(`Decision enregistree: ${result.moderation_status}.`);
      setNotes('');
      await onModerated();
    } catch (err) {
      setFeedback(err.message || 'Moderation de l avis impossible.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <article className="admin-card">
      <div className="card-head">
        <div>
          <p className="eyebrow muted">Avis a verifier</p>
          <h3>{review.title || 'Avis sans titre'}</h3>
          <p className="site-meta">{review.site_name}</p>
        </div>
        <span className="rating-pill">{formatRating(review.overall_rating)}</span>
      </div>
      <div className="chip-row">
        <InfoChipComponent label="Auteur" value={authorName || 'Utilisateur inconnu'} />
        <InfoChipComponent label="Soumis" value={formatDate(review.created_at)} />
        <InfoChipComponent label="Type" value={review.visit_type || 'Standard'} />
      </div>
      <dl className="entity-details">
        <div>
          <dt>Auteur</dt>
          <dd>{authorName || 'Utilisateur inconnu'}</dd>
        </div>
        <div>
          <dt>Soumis le</dt>
          <dd>{formatDate(review.created_at)}</dd>
        </div>
      </dl>
      <div className="card-actions">
        <button
          type="button"
          className="ghost-button compact"
          onClick={() => navigate(`/dashboard/reviews/${review.id}`)}
        >
          Ouvrir la fiche
        </button>
      </div>
      <ModerationFormComponent
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
  );
}
