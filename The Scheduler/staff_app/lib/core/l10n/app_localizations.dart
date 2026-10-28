// App Localizations for Staff App
//
// Provides localization support for the staff app.
// Uses a simple key-based approach that can be extended with ARB files.

import 'package:flutter/material.dart';

/// Supported locales.
const supportedLocales = [
  Locale('en', 'US'), // English (US) - Default
  Locale('es', 'US'), // Spanish (US)
  Locale('fr', 'CA'), // French (Canada)
];

/// Get localized strings for the current locale.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  /// Get instance from context.
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en', 'US'));
  }

  /// Localization delegate.
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Get localized string by key.
  String get(String key) {
    final translations = _getTranslations();
    return translations[key] ?? key;
  }

  /// Get localized string with parameters.
  String format(String key, Map<String, dynamic> params) {
    var text = get(key);
    params.forEach((k, v) {
      text = text.replaceAll('{$k}', v.toString());
    });
    return text;
  }

  Map<String, String> _getTranslations() {
    switch (locale.languageCode) {
      case 'es':
        return _spanishTranslations;
      case 'fr':
        return _frenchTranslations;
      default:
        return _englishTranslations;
    }
  }

  // Common strings
  String get appTitle => get('app_title');
  String get loading => get('loading');
  String get error => get('error');
  String get retry => get('retry');
  String get cancel => get('cancel');
  String get confirm => get('confirm');
  String get save => get('save');
  String get delete => get('delete');
  String get edit => get('edit');
  String get close => get('close');
  String get back => get('back');
  String get next => get('next');
  String get done => get('done');
  String get ok => get('ok');
  String get yes => get('yes');
  String get no => get('no');

  // Authentication
  String get login => get('login');
  String get logout => get('logout');
  String get email => get('email');
  String get password => get('password');
  String get forgotPassword => get('forgot_password');
  String get biometricPrompt => get('biometric_prompt');

  // Time Clock
  String get timeClock => get('time_clock');
  String get clockIn => get('clock_in');
  String get clockOut => get('clock_out');
  String get startBreak => get('start_break');
  String get endBreak => get('end_break');
  String get currentlyWorking => get('currently_working');
  String get onBreak => get('on_break');
  String get notClockedIn => get('not_clocked_in');
  String get shiftDuration => get('shift_duration');
  String get breakDuration => get('break_duration');

  // Schedule
  String get schedule => get('schedule');
  String get today => get('today');
  String get tomorrow => get('tomorrow');
  String get yesterday => get('yesterday');
  String get noAppointments => get('no_appointments');
  String get upcomingAppointments => get('upcoming_appointments');

  // Appointments
  String get appointment => get('appointment');
  String get appointments => get('appointments');
  String get client => get('client');
  String get service => get('service');
  String get duration => get('duration');
  String get notes => get('notes');
  String get status => get('status');
  String get accept => get('accept');
  String get decline => get('decline');

  // Settings
  String get settings => get('settings');
  String get notifications => get('notifications');
  String get appearance => get('appearance');
  String get darkMode => get('dark_mode');
  String get language => get('language');
  String get security => get('security');
  String get about => get('about');
  String get version => get('version');
  String get privacyPolicy => get('privacy_policy');
  String get termsOfService => get('terms_of_service');

  // Sync
  String get syncing => get('syncing');
  String get syncComplete => get('sync_complete');
  String get syncFailed => get('sync_failed');
  String get offline => get('offline');
  String get online => get('online');
  String get pendingChanges => get('pending_changes');

  // Errors
  String get networkError => get('network_error');
  String get unknownError => get('unknown_error');
  String get sessionExpired => get('session_expired');
  String get invalidCredentials => get('invalid_credentials');
  String get locationRequired => get('location_required');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// English translations (default)
const _englishTranslations = {
  // Common
  'app_title': 'Staff App',
  'loading': 'Loading...',
  'error': 'Error',
  'retry': 'Retry',
  'cancel': 'Cancel',
  'confirm': 'Confirm',
  'save': 'Save',
  'delete': 'Delete',
  'edit': 'Edit',
  'close': 'Close',
  'back': 'Back',
  'next': 'Next',
  'done': 'Done',
  'ok': 'OK',
  'yes': 'Yes',
  'no': 'No',

  // Authentication
  'login': 'Log In',
  'logout': 'Log Out',
  'email': 'Email',
  'password': 'Password',
  'forgot_password': 'Forgot Password?',
  'biometric_prompt': 'Authenticate to continue',

  // Time Clock
  'time_clock': 'Time Clock',
  'clock_in': 'Clock In',
  'clock_out': 'Clock Out',
  'start_break': 'Start Break',
  'end_break': 'End Break',
  'currently_working': 'Currently Working',
  'on_break': 'On Break',
  'not_clocked_in': 'Not Clocked In',
  'shift_duration': 'Shift Duration',
  'break_duration': 'Break Duration',

  // Schedule
  'schedule': 'Schedule',
  'today': 'Today',
  'tomorrow': 'Tomorrow',
  'yesterday': 'Yesterday',
  'no_appointments': 'No appointments',
  'upcoming_appointments': 'Upcoming Appointments',

  // Appointments
  'appointment': 'Appointment',
  'appointments': 'Appointments',
  'client': 'Client',
  'service': 'Service',
  'duration': 'Duration',
  'notes': 'Notes',
  'status': 'Status',
  'accept': 'Accept',
  'decline': 'Decline',

  // Settings
  'settings': 'Settings',
  'notifications': 'Notifications',
  'appearance': 'Appearance',
  'dark_mode': 'Dark Mode',
  'language': 'Language',
  'security': 'Security',
  'about': 'About',
  'version': 'Version',
  'privacy_policy': 'Privacy Policy',
  'terms_of_service': 'Terms of Service',

  // Sync
  'syncing': 'Syncing...',
  'sync_complete': 'Sync Complete',
  'sync_failed': 'Sync Failed',
  'offline': 'Offline',
  'online': 'Online',
  'pending_changes': 'Pending Changes',

  // Errors
  'network_error': 'Network error. Please check your connection.',
  'unknown_error': 'An unknown error occurred.',
  'session_expired': 'Your session has expired. Please log in again.',
  'invalid_credentials': 'Invalid email or password.',
  'location_required': 'Location is required for this action.',
};

// Spanish translations
const _spanishTranslations = {
  // Common
  'app_title': 'App de Personal',
  'loading': 'Cargando...',
  'error': 'Error',
  'retry': 'Reintentar',
  'cancel': 'Cancelar',
  'confirm': 'Confirmar',
  'save': 'Guardar',
  'delete': 'Eliminar',
  'edit': 'Editar',
  'close': 'Cerrar',
  'back': 'Atrás',
  'next': 'Siguiente',
  'done': 'Listo',
  'ok': 'OK',
  'yes': 'Sí',
  'no': 'No',

  // Authentication
  'login': 'Iniciar Sesión',
  'logout': 'Cerrar Sesión',
  'email': 'Correo Electrónico',
  'password': 'Contraseña',
  'forgot_password': '¿Olvidaste tu contraseña?',
  'biometric_prompt': 'Autentícate para continuar',

  // Time Clock
  'time_clock': 'Reloj de Tiempo',
  'clock_in': 'Marcar Entrada',
  'clock_out': 'Marcar Salida',
  'start_break': 'Iniciar Descanso',
  'end_break': 'Terminar Descanso',
  'currently_working': 'Trabajando',
  'on_break': 'En Descanso',
  'not_clocked_in': 'Sin Marcar Entrada',
  'shift_duration': 'Duración del Turno',
  'break_duration': 'Duración del Descanso',

  // Schedule
  'schedule': 'Horario',
  'today': 'Hoy',
  'tomorrow': 'Mañana',
  'yesterday': 'Ayer',
  'no_appointments': 'Sin citas',
  'upcoming_appointments': 'Próximas Citas',

  // Appointments
  'appointment': 'Cita',
  'appointments': 'Citas',
  'client': 'Cliente',
  'service': 'Servicio',
  'duration': 'Duración',
  'notes': 'Notas',
  'status': 'Estado',
  'accept': 'Aceptar',
  'decline': 'Rechazar',

  // Settings
  'settings': 'Configuración',
  'notifications': 'Notificaciones',
  'appearance': 'Apariencia',
  'dark_mode': 'Modo Oscuro',
  'language': 'Idioma',
  'security': 'Seguridad',
  'about': 'Acerca de',
  'version': 'Versión',
  'privacy_policy': 'Política de Privacidad',
  'terms_of_service': 'Términos de Servicio',

  // Sync
  'syncing': 'Sincronizando...',
  'sync_complete': 'Sincronización Completa',
  'sync_failed': 'Sincronización Fallida',
  'offline': 'Sin Conexión',
  'online': 'En Línea',
  'pending_changes': 'Cambios Pendientes',

  // Errors
  'network_error': 'Error de red. Por favor verifica tu conexión.',
  'unknown_error': 'Ocurrió un error desconocido.',
  'session_expired': 'Tu sesión ha expirado. Por favor inicia sesión de nuevo.',
  'invalid_credentials': 'Correo o contraseña inválidos.',
  'location_required': 'La ubicación es requerida para esta acción.',
};

// French translations
const _frenchTranslations = {
  // Common
  'app_title': 'App Personnel',
  'loading': 'Chargement...',
  'error': 'Erreur',
  'retry': 'Réessayer',
  'cancel': 'Annuler',
  'confirm': 'Confirmer',
  'save': 'Enregistrer',
  'delete': 'Supprimer',
  'edit': 'Modifier',
  'close': 'Fermer',
  'back': 'Retour',
  'next': 'Suivant',
  'done': 'Terminé',
  'ok': 'OK',
  'yes': 'Oui',
  'no': 'Non',

  // Authentication
  'login': 'Connexion',
  'logout': 'Déconnexion',
  'email': 'Courriel',
  'password': 'Mot de passe',
  'forgot_password': 'Mot de passe oublié?',
  'biometric_prompt': 'Authentifiez-vous pour continuer',

  // Time Clock
  'time_clock': 'Horloge',
  'clock_in': 'Pointer Entrée',
  'clock_out': 'Pointer Sortie',
  'start_break': 'Début Pause',
  'end_break': 'Fin Pause',
  'currently_working': 'En Service',
  'on_break': 'En Pause',
  'not_clocked_in': 'Non Pointé',
  'shift_duration': 'Durée du Quart',
  'break_duration': 'Durée de Pause',

  // Schedule
  'schedule': 'Horaire',
  'today': "Aujourd'hui",
  'tomorrow': 'Demain',
  'yesterday': 'Hier',
  'no_appointments': 'Aucun rendez-vous',
  'upcoming_appointments': 'Rendez-vous à Venir',

  // Appointments
  'appointment': 'Rendez-vous',
  'appointments': 'Rendez-vous',
  'client': 'Client',
  'service': 'Service',
  'duration': 'Durée',
  'notes': 'Notes',
  'status': 'Statut',
  'accept': 'Accepter',
  'decline': 'Refuser',

  // Settings
  'settings': 'Paramètres',
  'notifications': 'Notifications',
  'appearance': 'Apparence',
  'dark_mode': 'Mode Sombre',
  'language': 'Langue',
  'security': 'Sécurité',
  'about': 'À Propos',
  'version': 'Version',
  'privacy_policy': 'Politique de Confidentialité',
  'terms_of_service': "Conditions d'Utilisation",

  // Sync
  'syncing': 'Synchronisation...',
  'sync_complete': 'Synchronisation Terminée',
  'sync_failed': 'Synchronisation Échouée',
  'offline': 'Hors Ligne',
  'online': 'En Ligne',
  'pending_changes': 'Modifications en Attente',

  // Errors
  'network_error': 'Erreur réseau. Veuillez vérifier votre connexion.',
  'unknown_error': 'Une erreur inconnue est survenue.',
  'session_expired': 'Votre session a expiré. Veuillez vous reconnecter.',
  'invalid_credentials': 'Courriel ou mot de passe invalide.',
  'location_required': 'La localisation est requise pour cette action.',
};

/// Extension for easy access to localized strings.
extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
