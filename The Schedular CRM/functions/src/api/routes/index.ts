/**
 * API Routes Index
 * Aggregates all REST API routes
 *
 * Task 5: Cloud Functions - API Layer
 */

export { default as leadsRouter } from './leads';
export { default as dealsRouter } from './deals';
export { default as contactsRouter } from './contacts';
export { default as tasksRouter } from './tasks';
export { default as activitiesRouter } from './activities';
export { default as sequencesRouter } from './sequences';
export { default as webhooksRouter } from './webhooks';
