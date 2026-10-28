/**
 * Job Notes Component (Read-Only)
 * Displays job completion notes from Flutter providers
 *
 * Features:
 * - View service history for a client
 * - See provider notes, photos, and checklists
 * - Read-only (cannot edit from CRM)
 *
 * Per CRM-A Agent Prompt Task 4
 */

import { useState } from 'react';
import { useJobNotes, type JobNote } from '../../hooks/useClientNotes';

// ============================================
// Types
// ============================================

interface JobNotesProps {
  clientId: string;
  limit?: number;
}

interface JobNoteItemProps {
  note: JobNote;
  onViewPhotos: (urls: string[]) => void;
}

// ============================================
// Job Note Type Config
// ============================================

const JOB_NOTE_TYPE_CONFIG = {
  preJob: { icon: '📋', label: 'Pre-Job', color: '#3b82f6' },
  completion: { icon: '✅', label: 'Completion', color: '#10b981' },
  followUp: { icon: '🔔', label: 'Follow-up', color: '#f59e0b' },
};

// ============================================
// Helper Functions
// ============================================

function formatDate(date: Date): string {
  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

// ============================================
// Photo Lightbox
// ============================================

interface PhotoLightboxProps {
  photos: string[];
  isOpen: boolean;
  onClose: () => void;
}

function PhotoLightbox({ photos, isOpen, onClose }: PhotoLightboxProps) {
  const [currentIndex, setCurrentIndex] = useState(0);

  if (!isOpen || photos.length === 0) return null;

  const handlePrev = () => {
    setCurrentIndex((prev) => (prev > 0 ? prev - 1 : photos.length - 1));
  };

  const handleNext = () => {
    setCurrentIndex((prev) => (prev < photos.length - 1 ? prev + 1 : 0));
  };

  return (
    <div className="lightbox-overlay" onClick={onClose}>
      <div className="lightbox-content" onClick={(e) => e.stopPropagation()}>
        <button className="lightbox-close" onClick={onClose} aria-label="Close">
          ×
        </button>

        <div className="lightbox-image-container">
          <img
            src={photos[currentIndex]}
            alt={`Photo ${currentIndex + 1} of ${photos.length}`}
            className="lightbox-image"
          />
        </div>

        {photos.length > 1 && (
          <>
            <button className="lightbox-nav lightbox-prev" onClick={handlePrev} aria-label="Previous">
              ‹
            </button>
            <button className="lightbox-nav lightbox-next" onClick={handleNext} aria-label="Next">
              ›
            </button>
            <div className="lightbox-counter">
              {currentIndex + 1} / {photos.length}
            </div>
          </>
        )}
      </div>
    </div>
  );
}

// ============================================
// Job Note Item
// ============================================

function JobNoteItem({ note, onViewPhotos }: JobNoteItemProps) {
  const config = JOB_NOTE_TYPE_CONFIG[note.type] || JOB_NOTE_TYPE_CONFIG.completion;
  const checklistEntries = note.checklistItems ? Object.entries(note.checklistItems) : [];
  const completedCount = checklistEntries.filter(([, done]) => done).length;

  return (
    <div className="job-note-item">
      <div className="job-note-header">
        <div className="job-note-service">
          <span className="job-note-icon">🛠️</span>
          <span className="job-note-service-name">{note.serviceName}</span>
        </div>
        <div className="job-note-date">{formatDate(note.createdAt)}</div>
      </div>

      <div className="job-note-meta">
        <span className="job-note-provider">
          Provider: <strong>{note.providerName}</strong>
        </span>
        <span className="job-note-type-badge" style={{ backgroundColor: config.color }}>
          {config.icon} {config.label}
        </span>
      </div>

      {note.locationAddress && (
        <div className="job-note-location">
          📍 {note.locationAddress}
        </div>
      )}

      {note.noteContent && (
        <div className="job-note-content">
          <p>{note.noteContent}</p>
        </div>
      )}

      {checklistEntries.length > 0 && (
        <div className="job-note-checklist">
          <div className="checklist-header">
            Checklist ({completedCount}/{checklistEntries.length})
          </div>
          <div className="checklist-items">
            {checklistEntries.map(([item, done]) => (
              <span
                key={item}
                className={`checklist-item ${done ? 'completed' : 'incomplete'}`}
              >
                {done ? '✓' : '○'} {item}
              </span>
            ))}
          </div>
        </div>
      )}

      {note.photoUrls.length > 0 && (
        <button
          className="job-note-photos-btn"
          onClick={() => onViewPhotos(note.photoUrls)}
        >
          📷 {note.photoUrls.length} photo{note.photoUrls.length > 1 ? 's' : ''}
        </button>
      )}
    </div>
  );
}

// ============================================
// Job Notes Component
// ============================================

export function JobNotes({ clientId, limit }: JobNotesProps) {
  const { notes, isLoading, error, refetch } = useJobNotes(clientId, { limit });
  const [lightboxPhotos, setLightboxPhotos] = useState<string[]>([]);
  const [isLightboxOpen, setIsLightboxOpen] = useState(false);

  const handleViewPhotos = (photos: string[]) => {
    setLightboxPhotos(photos);
    setIsLightboxOpen(true);
  };

  if (isLoading) {
    return (
      <div className="job-notes-section">
        <div className="section-header">
          <h3>Service History</h3>
        </div>
        <div className="loading-state">Loading service history...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="job-notes-section">
        <div className="section-header">
          <h3>Service History</h3>
        </div>
        <div className="error-state">
          Failed to load service history
          <button className="btn btn-link" onClick={() => refetch()}>
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="job-notes-section">
      <div className="section-header">
        <h3>Service History</h3>
        <span className="section-badge">{notes.length} services</span>
      </div>

      {notes.length === 0 ? (
        <div className="empty-state">
          <p>No service history yet</p>
          <span className="empty-hint">Job notes from providers will appear here</span>
        </div>
      ) : (
        <div className="job-notes-list">
          {notes.map((note) => (
            <JobNoteItem
              key={note.id}
              note={note}
              onViewPhotos={handleViewPhotos}
            />
          ))}
        </div>
      )}

      <PhotoLightbox
        photos={lightboxPhotos}
        isOpen={isLightboxOpen}
        onClose={() => setIsLightboxOpen(false)}
      />
    </div>
  );
}

export default JobNotes;
