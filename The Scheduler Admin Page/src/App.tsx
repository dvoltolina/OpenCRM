import { Navigate, Route, Routes } from 'react-router-dom';

import { isDemoMode } from './config/demo';
import { AuthProvider } from './context/AuthContext';
import { RequireAuth } from './components/RequireAuth';
import { SuperAdminGuard } from './components/SuperAdminGuard';
import { BillingGuard } from './components/BillingGuard';
import { OnboardingGuard } from './components/OnboardingGuard';
import { HipaaMfaGuard } from './components/HipaaMfaGuard';
import { RootLayout } from './layout/RootLayout';
import { OpsLayout } from './layout/OpsLayout';
import { AppointmentsPage } from './pages/AppointmentsPage';
import { TenantsPage } from './pages/ops/TenantsPage';
import { OpsAuditPage } from './pages/ops/OpsAuditPage';
import { BillingPage } from './pages/BillingPage';
import { BillingGatePage } from './pages/BillingGatePage';
import { CalendarPage } from './pages/CalendarPage';
import { ClientsPage } from './pages/ClientsPage';
import { CommunicationsPage } from './pages/CommunicationsPage';
import { DashboardPage } from './pages/DashboardPage';
import { MfaPage } from './pages/MfaPage';
import { GroupSessionsPage } from './pages/GroupSessionsPage';
import { IntakeBuilderPage } from './pages/IntakeBuilderPage';
import { LocationsPage } from './pages/LocationsPage';
import { MarketingPage } from './pages/MarketingPage';
import { OnboardingPage } from './pages/OnboardingPage';
import { OnboardingSuccessPage } from './pages/OnboardingSuccessPage';
import { ServicesPage } from './pages/ServicesPage';
import { SettingsPage } from './pages/SettingsPage';
import { StaffPage } from './pages/StaffPage';
import { ReportsPage } from './pages/ReportsPage';
import { LoginPage } from './pages/LoginPage';
import { SignupPage } from './pages/SignupPage';
import { WaitlistPage } from './pages/WaitlistPage';
import { VerifyEmailPage } from './pages/VerifyEmailPage';
import { OwnerOnboardingPage } from './pages/OwnerOnboardingPage';

function App() {
  return (
    <AuthProvider>
      <Routes>
        <Route path="/login" element={isDemoMode ? <Navigate to="/dashboard" replace /> : <LoginPage />} />
        <Route path="/signup" element={isDemoMode ? <Navigate to="/dashboard" replace /> : <SignupPage />} />
        <Route path="/sign-up" element={<Navigate to="/signup" replace />} />
        <Route path="/verify-email" element={isDemoMode ? <Navigate to="/dashboard" replace /> : <VerifyEmailPage />} />
        <Route path="/owner-onboarding" element={isDemoMode ? <Navigate to="/dashboard" replace /> : <OwnerOnboardingPage />} />
        <Route path="/mfa" element={isDemoMode ? <Navigate to="/dashboard" replace /> : <MfaPage />} />
        <Route element={<RequireAuth />}>
          {/* Ops Portal (super-admin only) - before other guards */}
          <Route element={<SuperAdminGuard />}>
            <Route element={<OpsLayout />}>
              <Route path="/ops" element={<Navigate to="/ops/tenants" replace />} />
              <Route path="/ops/tenants" element={<TenantsPage />} />
              <Route path="/ops/audit" element={<OpsAuditPage />} />
            </Route>
          </Route>
          <Route element={<HipaaMfaGuard />}>
            <Route element={<BillingGuard />}>
              <Route path="/billing-gate" element={isDemoMode ? <Navigate to="/dashboard" replace /> : <BillingGatePage />} />
              <Route element={<OnboardingGuard />}>
                <Route path="/onboarding" element={isDemoMode ? <Navigate to="/dashboard" replace /> : <OnboardingPage />} />
                <Route path="/onboarding/success" element={isDemoMode ? <Navigate to="/dashboard" replace /> : <OnboardingSuccessPage />} />
                <Route element={<RootLayout />}>
                  <Route index element={<Navigate to="/dashboard" replace />} />
                  <Route path="/dashboard" element={<DashboardPage />} />
                  <Route path="/calendar" element={<CalendarPage />} />
                  <Route path="/staff" element={<StaffPage />} />
                  <Route path="/services" element={<ServicesPage />} />
                  <Route path="/intake-builder" element={<IntakeBuilderPage />} />
                  <Route path="/clients" element={<ClientsPage />} />
                  <Route path="/appointments" element={<AppointmentsPage />} />
                  <Route path="/group-sessions" element={<GroupSessionsPage />} />
                  <Route path="/waitlist" element={<WaitlistPage />} />
                  <Route path="/locations" element={<LocationsPage />} />
                  <Route path="/communications" element={<CommunicationsPage />} />
                  <Route path="/marketing" element={<MarketingPage />} />
                  <Route path="/settings" element={<SettingsPage />} />
                  <Route path="/billing" element={<BillingPage />} />
                  <Route path="/reports" element={<ReportsPage />} />
                </Route>
              </Route>
            </Route>
          </Route>
        </Route>
        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </AuthProvider>
  );
}

export default App;
