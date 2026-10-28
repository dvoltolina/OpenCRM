import { lazy, Suspense } from 'react';
import type { ComponentType } from 'react';
import { Navigate, Route, Routes } from 'react-router-dom';

import { AuthProvider } from './context/AuthContext';
import { NotificationProvider } from './contexts/NotificationContext';
import { RequireAuth } from './components/RequireAuth';
import { RequireFeature } from './components/RequireFeature';
import { RequireRole } from './components/RequireRole';
import { RequireSettingsAccess } from './components/RequireSettingsAccess';
import { RootLayout } from './layout/RootLayout';
import { ErrorBoundary } from './components/ErrorBoundary';
import { isDemoMode } from './config/demo';

function lazyNamedImport<TModule extends Record<string, unknown>, TKey extends keyof TModule>(
  loader: () => Promise<TModule>,
  key: TKey
) {
  return lazy(async () => {
    const module = await loader();
    return {
      default: module[key] as ComponentType<any>,
    };
  });
}

function RouteLoadingScreen() {
  return (
    <div className="loading-screen">
      <div className="loading-spinner" />
      <p>Loading page...</p>
    </div>
  );
}

const LoginPage = lazyNamedImport(() => import('./pages/LoginPage'), 'LoginPage');
const MfaEnrollmentPage = lazyNamedImport(() => import('./pages/MfaEnrollmentPage'), 'MfaEnrollmentPage');
const BusinessRequiredPage = lazyNamedImport(() => import('./pages/BusinessRequiredPage'), 'BusinessRequiredPage');
const DashboardPage = lazyNamedImport(() => import('./pages/DashboardPage'), 'DashboardPage');
const PipelinePage = lazyNamedImport(() => import('./pages/PipelinePage'), 'PipelinePage');
const LeadsPage = lazyNamedImport(() => import('./pages/LeadsPage'), 'LeadsPage');
const DealsPage = lazyNamedImport(() => import('./pages/DealsPage'), 'DealsPage');
const ContactsPage = lazyNamedImport(() => import('./pages/ContactsPage'), 'ContactsPage');
const CompaniesPage = lazyNamedImport(() => import('./pages/CompaniesPage'), 'CompaniesPage');
const ActivitiesPage = lazyNamedImport(() => import('./pages/ActivitiesPage'), 'ActivitiesPage');
const ReportsPage = lazyNamedImport(() => import('./pages/ReportsPage'), 'ReportsPage');
const SettingsPage = lazyNamedImport(() => import('./pages/SettingsPage'), 'SettingsPage');
const DealDetailPage = lazyNamedImport(() => import('./pages/DealDetailPage'), 'DealDetailPage');
const LeadDetailPage = lazyNamedImport(() => import('./pages/LeadDetailPage'), 'LeadDetailPage');
const ContactDetailPage = lazyNamedImport(() => import('./pages/ContactDetailPage'), 'ContactDetailPage');
const GoalDetailPage = lazyNamedImport(() => import('./pages/GoalDetailPage'), 'GoalDetailPage');
const ManagerDashboardPage = lazyNamedImport(() => import('./pages/ManagerDashboardPage'), 'ManagerDashboardPage');
const AdminPage = lazyNamedImport(() => import('./pages/AdminPage'), 'AdminPage');
const SequencesPage = lazyNamedImport(() => import('./pages/SequencesPage'), 'SequencesPage');
const SequenceBuilder = lazyNamedImport(() => import('./components/sequences/SequenceBuilder'), 'SequenceBuilder');
const SequenceComparisonPage = lazyNamedImport(() => import('./pages/SequenceComparisonPage'), 'SequenceComparisonPage');
const SequenceEnrollmentDetailPage = lazyNamedImport(() => import('./pages/SequenceEnrollmentDetailPage'), 'SequenceEnrollmentDetailPage');
const RoutePlanningPage = lazyNamedImport(() => import('./pages/RoutePlanningPage'), 'RoutePlanningPage');
const TeamRoutePlanningPage = lazyNamedImport(() => import('./pages/TeamRoutePlanningPage'), 'TeamRoutePlanningPage');
const StaffSchedulesPage = lazyNamedImport(() => import('./pages/StaffSchedulesPage'), 'StaffSchedulesPage');
const TerritoriesPage = lazyNamedImport(() => import('./pages/TerritoriesPage'), 'TerritoriesPage');
const TimesheetPage = lazyNamedImport(() => import('./pages/TimesheetPage'), 'TimesheetPage');
const DocumentsPage = lazyNamedImport(() => import('./pages/DocumentsPage'), 'DocumentsPage');
const GoalsPage = lazyNamedImport(() => import('./pages/GoalsPage'), 'GoalsPage');
const IntegrationsPage = lazyNamedImport(() => import('./pages/IntegrationsPage'), 'IntegrationsPage');
const NotificationsPage = lazyNamedImport(() => import('./pages/NotificationsPage'), 'NotificationsPage');
const ReportingPage = lazyNamedImport(() => import('./pages/ReportingPage'), 'ReportingPage');
const WebFormsPage = lazyNamedImport(() => import('./pages/WebFormsPage'), 'WebFormsPage');
const NotFoundPage = lazyNamedImport(() => import('./pages/NotFoundPage'), 'NotFoundPage');

function App() {
  return (
    <ErrorBoundary>
      <AuthProvider>
        <NotificationProvider>
          <Suspense fallback={<RouteLoadingScreen />}>
            <Routes>
              <Route path="/demo" element={<Navigate to="/dashboard" replace />} />
              <Route path="/demo/*" element={<Navigate to="/dashboard" replace />} />
              <Route
                path="/login"
                element={isDemoMode ? <Navigate to="/dashboard" replace /> : <LoginPage />}
              />
              <Route
                path="/mfa"
                element={isDemoMode ? <Navigate to="/dashboard" replace /> : <MfaEnrollmentPage />}
              />
              <Route
                path="/business-required"
                element={isDemoMode ? <Navigate to="/dashboard" replace /> : <BusinessRequiredPage />}
              />
              <Route element={<RequireAuth />}>
                <Route element={<RootLayout />}>
                  <Route index element={<Navigate to="/dashboard" replace />} />
                  <Route path="/dashboard" element={<DashboardPage />} />
                  <Route
                    path="/admin"
                    element={
                      isDemoMode ? (
                        <Navigate to="/dashboard" replace />
                      ) : (
                        <RequireRole roles={['admin', 'owner']}>
                          <AdminPage />
                        </RequireRole>
                      )
                    }
                  />
                  <Route
                    path="/manager"
                    element={(
                      <RequireRole roles={['manager', 'admin', 'owner']}>
                        <ManagerDashboardPage />
                      </RequireRole>
                    )}
                  />
                  <Route path="/pipeline" element={<PipelinePage />} />
                  <Route path="/leads" element={<LeadsPage />} />
                  <Route path="/deals" element={<DealsPage />} />
                  <Route path="/deals/:dealId" element={<DealDetailPage />} />
                  <Route path="/contacts" element={<ContactsPage />} />
                  <Route path="/contacts/:contactId" element={<ContactDetailPage />} />
                  <Route
                    path="/companies"
                    element={(
                      <RequireFeature flag="enableCompanies">
                        <CompaniesPage />
                      </RequireFeature>
                    )}
                  />
                  <Route path="/activities" element={<ActivitiesPage />} />
                  <Route
                    path="/documents"
                    element={(
                      <RequireFeature flag="enableDocuments">
                        <DocumentsPage />
                      </RequireFeature>
                    )}
                  />
                  <Route
                    path="/goals"
                    element={(
                      <RequireFeature flag="enableGoals">
                        <GoalsPage />
                      </RequireFeature>
                    )}
                  />
                  <Route
                    path="/goals/:goalId"
                    element={(
                      <RequireFeature flag="enableGoals">
                        <GoalDetailPage />
                      </RequireFeature>
                    )}
                  />
                  <Route path="/notifications" element={<NotificationsPage />} />
                  <Route
                    path="/integrations"
                    element={(
                      <RequireFeature flags={['enableApi', 'enableWebhooks', 'enableCalendarSync']} mode="any">
                        <RequireRole roles={['admin', 'owner']}>
                          <IntegrationsPage />
                        </RequireRole>
                      </RequireFeature>
                    )}
                  />
                  <Route
                    path="/routes"
                    element={(
                      <RequireFeature flag="enableRoutePlanning">
                        <RoutePlanningPage />
                      </RequireFeature>
                    )}
                  />
                  <Route
                    path="/team-routes"
                    element={(
                      <RequireFeature flag="enableRoutePlanning">
                        <RequireRole roles={['manager', 'admin', 'owner']}>
                          <TeamRoutePlanningPage />
                        </RequireRole>
                      </RequireFeature>
                    )}
                  />
                  <Route
                    path="/staff-schedules"
                    element={(
                      <RequireFeature flag="enableRoutePlanning">
                        <RequireRole roles={['manager', 'admin', 'owner']}>
                          <StaffSchedulesPage />
                        </RequireRole>
                      </RequireFeature>
                    )}
                  />
                  <Route
                    path="/territories"
                    element={(
                      <RequireFeature flag="enableRoutePlanning">
                        <RequireRole roles={['manager', 'admin', 'owner']}>
                          <TerritoriesPage />
                        </RequireRole>
                      </RequireFeature>
                    )}
                  />
                  <Route
                    path="/timesheets"
                    element={(
                      <RequireRole roles={['manager', 'admin', 'owner']}>
                        <TimesheetPage />
                      </RequireRole>
                    )}
                  />
                  <Route
                    path="/sequences"
                    element={(
                      <RequireFeature flag="enableSequences">
                        <SequencesPage />
                      </RequireFeature>
                    )}
                  />
                  <Route
                    path="/sequences/new"
                    element={(
                      <RequireFeature flag="enableSequences">
                        <SequenceBuilder />
                      </RequireFeature>
                    )}
                  />
                  <Route
                    path="/sequences/compare"
                    element={(
                      <RequireFeature flag="enableSequences">
                        <SequenceComparisonPage />
                      </RequireFeature>
                    )}
                  />
                  <Route
                    path="/sequences/:sequenceId/enrollments/:enrollmentId"
                    element={(
                      <RequireFeature flag="enableSequences">
                        <SequenceEnrollmentDetailPage />
                      </RequireFeature>
                    )}
                  />
                  <Route
                    path="/sequences/:id"
                    element={(
                      <RequireFeature flag="enableSequences">
                        <SequenceBuilder />
                      </RequireFeature>
                    )}
                  />
                  <Route
                    path="/reports"
                    element={(
                      <RequireFeature flag="enableReports">
                        <ReportsPage />
                      </RequireFeature>
                    )}
                  />
                  <Route path="/reporting" element={<Navigate to="/reports/builder" replace />} />
                  <Route
                    path="/reports/builder"
                    element={(
                      <RequireFeature flags={['enableReports', 'enableAdvancedReporting']} mode="all">
                        <ReportingPage />
                      </RequireFeature>
                    )}
                  />
                  <Route path="/settings/notifications" element={<Navigate to="/settings?tab=notifications" replace />} />
                  <Route
                    path="/settings"
                    element={(
                      <RequireSettingsAccess>
                        <SettingsPage />
                      </RequireSettingsAccess>
                    )}
                  />
                  <Route
                    path="/web-forms"
                    element={(
                      <RequireFeature flag="enableWebForms">
                        <WebFormsPage />
                      </RequireFeature>
                    )}
                  />
                  <Route path="/leads/:leadId" element={<LeadDetailPage />} />
                  <Route path="*" element={<NotFoundPage />} />
                </Route>
              </Route>
              <Route path="*" element={<NotFoundPage />} />
            </Routes>
          </Suspense>
        </NotificationProvider>
      </AuthProvider>
    </ErrorBoundary>
  );
}

export default App;
