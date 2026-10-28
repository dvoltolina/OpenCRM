import type { FormEvent } from 'react';

import type { AppointmentStatus, Client, Location, Service, StaffMember } from '../../types/models';

export type AppointmentFormState = {
  clientId: string;
  providerId: string;
  serviceId: string;
  locationId: string;
  startTime: string;
  endTime: string;
  notes: string;
};

export const EMPTY_APPOINTMENT_FORM: AppointmentFormState = {
  clientId: '',
  providerId: '',
  serviceId: '',
  locationId: '',
  startTime: '',
  endTime: '',
  notes: '',
};

type CreateAppointmentDialogProps = {
  open: boolean;
  form: AppointmentFormState;
  clients: Client[];
  staff: StaffMember[];
  services: Service[];
  locations: Location[];
  saving: boolean;
  formError: string | null;
  onClose: () => void;
  onSubmit: (event: FormEvent<HTMLFormElement>) => void;
  onChange: (field: keyof AppointmentFormState, value: string) => void;
};

export function CreateAppointmentDialog({
  open,
  form,
  clients,
  staff,
  services,
  locations,
  saving,
  formError,
  onClose,
  onSubmit,
  onChange,
}: CreateAppointmentDialogProps) {
  if (!open) return null;

  return (
    <div className="dialog-overlay" onClick={onClose}>
      <div className="dialog" onClick={(event) => event.stopPropagation()}>
        <h2>New Appointment</h2>
        <form onSubmit={onSubmit}>
          <label>
            Client
            <select value={form.clientId} onChange={(event) => onChange('clientId', event.target.value)} required>
              <option value="">Select client</option>
              {clients.map((client) => (
                <option key={client.id} value={client.id}>
                  {client.name}
                </option>
              ))}
            </select>
          </label>

          <label>
            Provider
            <select value={form.providerId} onChange={(event) => onChange('providerId', event.target.value)} required>
              <option value="">Select provider</option>
              {staff.map((member) => (
                <option key={member.id} value={member.id}>
                  {member.displayName}
                </option>
              ))}
            </select>
          </label>

          <label>
            Service
            <select value={form.serviceId} onChange={(event) => onChange('serviceId', event.target.value)} required>
              <option value="">Select service</option>
              {services.map((service) => (
                <option key={service.id} value={service.id}>
                  {service.name}
                </option>
              ))}
            </select>
          </label>

          <label>
            Location
            <select value={form.locationId} onChange={(event) => onChange('locationId', event.target.value)}>
              <option value="">No location</option>
              {locations.map((location) => (
                <option key={location.id} value={location.id}>
                  {location.name}
                </option>
              ))}
            </select>
          </label>

          <label>
            Start
            <input
              type="datetime-local"
              value={form.startTime}
              onChange={(event) => onChange('startTime', event.target.value)}
              required
            />
          </label>

          <label>
            End
            <input
              type="datetime-local"
              value={form.endTime}
              onChange={(event) => onChange('endTime', event.target.value)}
              required
            />
          </label>

          <label>
            Notes
            <textarea rows={3} value={form.notes} onChange={(event) => onChange('notes', event.target.value)} />
          </label>

          {formError ? <p className="error">{formError}</p> : null}

          <div className="dialog-actions">
            <button type="button" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" disabled={saving}>
              {saving ? 'Saving…' : 'Create'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

type EditAppointmentDialogProps = {
  open: boolean;
  title: string;
  serviceName: string;
  form: AppointmentFormState;
  status: AppointmentStatus;
  cancelReason: string;
  staff: StaffMember[];
  services: Service[];
  locations: Location[];
  saving: boolean;
  formError: string | null;
  onClose: () => void;
  onSubmit: (event: FormEvent<HTMLFormElement>) => void;
  onCancelAppointment: () => void;
  onChange: (field: keyof AppointmentFormState, value: string) => void;
  onStatusChange: (status: AppointmentStatus) => void;
  onCancelReasonChange: (value: string) => void;
};

export function EditAppointmentDialog({
  open,
  title,
  serviceName,
  form,
  status,
  cancelReason,
  staff,
  services,
  locations,
  saving,
  formError,
  onClose,
  onSubmit,
  onCancelAppointment,
  onChange,
  onStatusChange,
  onCancelReasonChange,
}: EditAppointmentDialogProps) {
  if (!open) return null;

  return (
    <div className="dialog-overlay" onClick={onClose}>
      <div className="dialog" onClick={(event) => event.stopPropagation()}>
        <h2>Edit Appointment</h2>
        <p className="muted">
          {title} · {serviceName}
        </p>
        <form onSubmit={onSubmit}>
          <label>
            Status
            <select value={status} onChange={(event) => onStatusChange(event.target.value as AppointmentStatus)}>
              <option value="pending">Pending</option>
              <option value="confirmed">Confirmed</option>
              <option value="completed">Completed</option>
              <option value="cancelled">Cancelled</option>
              <option value="noShow">No show</option>
            </select>
          </label>

          <label>
            Provider
            <select value={form.providerId} onChange={(event) => onChange('providerId', event.target.value)}>
              {staff.map((member) => (
                <option key={member.id} value={member.id}>
                  {member.displayName}
                </option>
              ))}
            </select>
          </label>

          <label>
            Service
            <select value={form.serviceId} onChange={(event) => onChange('serviceId', event.target.value)}>
              {services.map((service) => (
                <option key={service.id} value={service.id}>
                  {service.name}
                </option>
              ))}
            </select>
          </label>

          <label>
            Location
            <select value={form.locationId} onChange={(event) => onChange('locationId', event.target.value)}>
              <option value="">No location</option>
              {locations.map((location) => (
                <option key={location.id} value={location.id}>
                  {location.name}
                </option>
              ))}
            </select>
          </label>

          <label>
            Start
            <input
              type="datetime-local"
              value={form.startTime}
              onChange={(event) => onChange('startTime', event.target.value)}
              required
            />
          </label>

          <label>
            End
            <input
              type="datetime-local"
              value={form.endTime}
              onChange={(event) => onChange('endTime', event.target.value)}
              required
            />
          </label>

          <label>
            Notes
            <textarea rows={3} value={form.notes} onChange={(event) => onChange('notes', event.target.value)} />
          </label>

          <label>
            Cancellation reason
            <input
              type="text"
              value={cancelReason}
              onChange={(event) => onCancelReasonChange(event.target.value)}
              placeholder="Only used if you click Cancel appointment"
            />
          </label>

          {formError ? <p className="error">{formError}</p> : null}

          <div className="dialog-actions">
            <button type="button" onClick={onClose}>
              Close
            </button>
            <button type="button" onClick={onCancelAppointment} disabled={saving}>
              Cancel appointment
            </button>
            <button type="submit" disabled={saving}>
              {saving ? 'Saving…' : 'Save changes'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
