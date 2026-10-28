import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import type { Request, Response } from 'express';
import {
  extractIp,
  hashIp,
  hashValue,
  safeRedirect,
  sanitizeError,
  sanitizeTrackedUrl,
  sendJsonError,
  TRACKING_PIXEL,
} from './email-security';

export async function handleTrackOpen(req: Request, res: Response) {
  try {
    const trackingId = String(req.query.tid || '').trim();
    const businessId = String(req.query.bid || '').trim();
    const messageId = String(req.query.mid || '').trim();
    if (!trackingId || !businessId || !messageId) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing tracking identifiers');
    }

    const messageRef = admin.firestore().doc(`businesses/${businessId}/email_messages/${messageId}`);
    const messageSnap = await messageRef.get();
    if (messageSnap.exists && messageSnap.get('trackingId') === trackingId) {
      const ipHash = hashIp(extractIp(req));
      const userAgent = String(req.headers['user-agent'] || '').slice(0, 300);
      const eventId = hashValue(`${trackingId}:open:${ipHash}:${userAgent}`).slice(0, 32);
      const eventRef = admin.firestore().doc(`businesses/${businessId}/email_tracking_events/${eventId}`);
      const existing = await eventRef.get();

      if (!existing.exists) {
        await eventRef.set({
          businessId,
          messageId,
          trackingId,
          eventType: 'open',
          ipAddress: ipHash,
          userAgent,
          occurredAt: new Date(),
        });
        await messageRef.set(
          {
            opens: admin.firestore.FieldValue.increment(1),
            firstOpenedAt: messageSnap.get('firstOpenedAt') || new Date(),
            lastOpenedAt: new Date(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      }
    }
  } catch (error) {
    functions.logger.warn('track_email_open_failed', { message: sanitizeError(error) });
  }

  res.set('Cache-Control', 'no-store, max-age=0');
  res.set('Content-Type', 'image/gif');
  res.status(200).send(TRACKING_PIXEL);
}

export async function handleTrackClick(req: Request, res: Response) {
  try {
    const trackingId = String(req.query.tid || '').trim();
    const businessId = String(req.query.bid || '').trim();
    const messageId = String(req.query.mid || '').trim();
    const destination = safeRedirect(String(req.query.url || '').trim());
    if (!trackingId || !businessId || !messageId || !destination) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid click tracking request');
    }

    const messageRef = admin.firestore().doc(`businesses/${businessId}/email_messages/${messageId}`);
    const messageSnap = await messageRef.get();
    if (messageSnap.exists && messageSnap.get('trackingId') === trackingId) {
      const eventId = hashValue(`${trackingId}:click:${Date.now()}:${destination}`).slice(0, 32);
      await admin.firestore().doc(`businesses/${businessId}/email_tracking_events/${eventId}`).set({
        businessId,
        messageId,
        trackingId,
        eventType: 'click',
        linkUrl: sanitizeTrackedUrl(destination),
        occurredAt: new Date(),
      });

      await messageRef.set(
        {
          clicks: admin.firestore.FieldValue.increment(1),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    res.redirect(302, destination);
  } catch (error) {
    sendJsonError(res, 400, sanitizeError(error));
  }
}
