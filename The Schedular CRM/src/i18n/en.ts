/**
 * English Translations
 * Agent CRM-35: Default language translations
 *
 * Namespaced translation strings for the CRM application.
 * Organized by feature area for maintainability.
 */

import type { Translations } from './config';

export const translations: Translations = {
  // ============================================
  // Common UI Strings
  // ============================================
  common: {
    // Actions
    save: 'Save',
    cancel: 'Cancel',
    delete: 'Delete',
    edit: 'Edit',
    create: 'Create',
    update: 'Update',
    close: 'Close',
    back: 'Back',
    next: 'Next',
    submit: 'Submit',
    confirm: 'Confirm',
    search: 'Search',
    filter: 'Filter',
    sort: 'Sort',
    export: 'Export',
    import: 'Import',
    refresh: 'Refresh',
    view: 'View',
    download: 'Download',
    upload: 'Upload',
    add: 'Add',
    remove: 'Remove',
    clear: 'Clear',
    apply: 'Apply',
    reset: 'Reset',

    // Status
    loading: 'Loading...',
    saving: 'Saving...',
    saved: 'Saved',
    error: 'Error',
    success: 'Success',
    warning: 'Warning',
    info: 'Info',
    pending: 'Pending',
    active: 'Active',
    inactive: 'Inactive',
    archived: 'Archived',

    // General
    name: 'Name',
    email: 'Email',
    phone: 'Phone',
    address: 'Address',
    notes: 'Notes',
    tags: 'Tags',
    date: 'Date',
    time: 'Time',
    status: 'Status',
    type: 'Type',
    description: 'Description',
    title: 'Title',
    value: 'Value',
    owner: 'Owner',
    assignee: 'Assignee',
    created_at: 'Created',
    updated_at: 'Updated',
    created_by: 'Created By',
    updated_by: 'Updated By',

    // Validation
    required: 'This field is required',
    invalid_email: 'Please enter a valid email address',
    invalid_phone: 'Please enter a valid phone number',
    invalid_date: 'Please enter a valid date',
    min_length: 'Minimum {{count}} characters required',
    max_length: 'Maximum {{count}} characters allowed',

    // Empty states
    no_data: 'No data available',
    no_results: 'No results found',
    empty_state: 'Nothing to show yet',

    // Confirmation
    are_you_sure: 'Are you sure?',
    cannot_be_undone: 'This action cannot be undone.',
  },

  // ============================================
  // Leads
  // ============================================
  leads: {
    // General
    lead: 'Lead',
    leads: 'Leads',
    new_lead: 'New Lead',
    create_lead: 'Create Lead',
    edit_lead: 'Edit Lead',
    delete_lead: 'Delete Lead',
    convert_lead: 'Convert Lead',
    lead_details: 'Lead Details',
    all_leads: 'All Leads',

    // Fields
    first_name: 'First Name',
    last_name: 'Last Name',
    company_name: 'Company Name',
    job_title: 'Job Title',
    source: 'Source',
    score: 'Score',
    qualified: 'Qualified',
    unqualified: 'Unqualified',

    // Status
    status_new: 'New',
    status_contacted: 'Contacted',
    status_qualified: 'Qualified',
    status_unqualified: 'Unqualified',
    status_converted: 'Converted',

    // Sources
    source_website: 'Website',
    source_referral: 'Referral',
    source_cold_call: 'Cold Call',
    source_social: 'Social Media',
    source_event: 'Event',
    source_scheduler: 'Scheduler',
    source_other: 'Other',

    // Messages
    lead_created: 'Lead created successfully',
    lead_updated: 'Lead updated successfully',
    lead_deleted: 'Lead deleted successfully',
    lead_converted: 'Lead converted successfully',
    confirm_delete_lead: 'Are you sure you want to delete this lead?',
  },

  // ============================================
  // Deals
  // ============================================
  deals: {
    // General
    deal: 'Deal',
    deals: 'Deals',
    new_deal: 'New Deal',
    create_deal: 'Create Deal',
    edit_deal: 'Edit Deal',
    delete_deal: 'Delete Deal',
    deal_details: 'Deal Details',
    all_deals: 'All Deals',
    pipeline: 'Pipeline',

    // Fields
    deal_title: 'Deal Title',
    deal_value: 'Deal Value',
    expected_close_date: 'Expected Close Date',
    probability: 'Probability',
    stage: 'Stage',
    won: 'Won',
    lost: 'Lost',
    currency: 'Currency',

    // Metrics
    total_value: 'Total Value',
    pipeline_value: 'Pipeline Value',
    deal_count_one: '{{count}} deal',
    deal_count_other: '{{count}} deals',
    weighted_value: 'Weighted Value',
    win_rate: 'Win Rate',
    avg_deal_size: 'Avg Deal Size',

    // Messages
    deal_created: 'Deal created successfully',
    deal_updated: 'Deal updated successfully',
    deal_deleted: 'Deal deleted successfully',
    deal_moved: 'Deal moved to {{stage}}',
    confirm_delete_deal: 'Are you sure you want to delete this deal?',
    confirm_mark_won: 'Mark this deal as won?',
    confirm_mark_lost: 'Mark this deal as lost?',
  },

  // ============================================
  // Contacts
  // ============================================
  contacts: {
    // General
    contact: 'Contact',
    contacts: 'Contacts',
    new_contact: 'New Contact',
    create_contact: 'Create Contact',
    edit_contact: 'Edit Contact',
    delete_contact: 'Delete Contact',
    contact_details: 'Contact Details',
    all_contacts: 'All Contacts',

    // Fields
    first_name: 'First Name',
    last_name: 'Last Name',
    full_name: 'Full Name',
    job_title: 'Job Title',
    company: 'Company',
    lifecycle: 'Lifecycle',
    last_contacted: 'Last Contacted',

    // Lifecycle
    lifecycle_lead: 'Lead',
    lifecycle_prospect: 'Prospect',
    lifecycle_active: 'Active',
    lifecycle_inactive: 'Inactive',
    lifecycle_churned: 'Churned',

    // Messages
    contact_created: 'Contact created successfully',
    contact_updated: 'Contact updated successfully',
    contact_deleted: 'Contact deleted successfully',
    confirm_delete_contact: 'Are you sure you want to delete this contact?',
  },

  // ============================================
  // Companies
  // ============================================
  companies: {
    // General
    company: 'Company',
    companies: 'Companies',
    new_company: 'New Company',
    create_company: 'Create Company',
    edit_company: 'Edit Company',
    delete_company: 'Delete Company',
    company_details: 'Company Details',
    all_companies: 'All Companies',

    // Fields
    company_name: 'Company Name',
    industry: 'Industry',
    size: 'Company Size',
    website: 'Website',
    annual_revenue: 'Annual Revenue',
    employee_count: 'Employee Count',

    // Messages
    company_created: 'Company created successfully',
    company_updated: 'Company updated successfully',
    company_deleted: 'Company deleted successfully',
    confirm_delete_company: 'Are you sure you want to delete this company?',
  },

  // ============================================
  // Settings
  // ============================================
  settings: {
    // General
    settings: 'Settings',
    crm_settings: 'CRM Settings',
    pipeline_settings: 'Pipeline Settings',
    team_settings: 'Team Settings',
    custom_fields: 'Custom Fields',
    preferences: 'Preferences',

    // Pipeline
    add_stage: 'Add Stage',
    edit_stage: 'Edit Stage',
    delete_stage: 'Delete Stage',
    stage_name: 'Stage Name',
    stage_order: 'Order',
    stage_color: 'Color',
    stage_probability: 'Win Probability',
    default_pipeline: 'Default Pipeline',

    // Team
    team_members: 'Team Members',
    invite_member: 'Invite Member',
    member_role: 'Role',
    remove_member: 'Remove Member',

    // Messages
    settings_saved: 'Settings saved successfully',
    stage_created: 'Stage created successfully',
    stage_updated: 'Stage updated successfully',
    stage_deleted: 'Stage deleted successfully',
    member_invited: 'Team member invited',
    member_removed: 'Team member removed',
  },

  // ============================================
  // Pipeline/Kanban
  // ============================================
  pipeline: {
    // General
    pipeline: 'Pipeline',
    stage: 'Stage',
    add_deal: 'Add Deal',
    move_deal: 'Move Deal',
    drag_to_move: 'Drag to move',

    // Actions
    move_to_stage: 'Move to {{stage}}',
    moved_successfully: 'Deal moved successfully',
    move_failed: 'Failed to move deal',

    // Metrics
    total_deals: 'Total Deals',
    stage_value: 'Stage Value',

    // Empty
    no_deals_in_stage: 'No deals in this stage',
    drag_deal_here: 'Drag a deal here',
  },

  // ============================================
  // Dashboard
  // ============================================
  dashboard: {
    // General
    dashboard: 'Dashboard',
    overview: 'Overview',
    metrics: 'Metrics',
    analytics: 'Analytics',

    // KPIs
    revenue: 'Revenue',
    deals_won: 'Deals Won',
    conversion_rate: 'Conversion Rate',
    avg_deal_value: 'Avg Deal Value',
    active_deals: 'Active Deals',
    new_leads: 'New Leads',

    // Sections
    recent_activity: 'Recent Activity',
    upcoming_tasks: 'Upcoming Tasks',
    recent_deals: 'Recent Deals',
    pipeline_overview: 'Pipeline Overview',
    sales_trend: 'Sales Trend',
    quick_actions: 'Quick Actions',

    // Time periods
    today: 'Today',
    this_week: 'This Week',
    this_month: 'This Month',
    this_quarter: 'This Quarter',
    this_year: 'This Year',
    last_30_days: 'Last 30 Days',
    last_90_days: 'Last 90 Days',
  },

  // ============================================
  // Forms
  // ============================================
  forms: {
    // Validation
    field_required: 'This field is required',
    invalid_email: 'Invalid email address',
    invalid_phone: 'Invalid phone number',
    invalid_url: 'Invalid URL',
    invalid_number: 'Must be a valid number',
    min_value: 'Must be at least {{min}}',
    max_value: 'Must be at most {{max}}',

    // Actions
    save_changes: 'Save Changes',
    cancel_changes: 'Cancel Changes',
    form_saved: 'Form saved successfully',
    form_error: 'Please fix the errors and try again',

    // Help text
    select_option: 'Select an option',
    enter_value: 'Enter a value',
    optional: 'Optional',
    required_field: 'Required field',
  },

  // ============================================
  // Errors
  // ============================================
  errors: {
    // General
    error_occurred: 'An error occurred',
    something_went_wrong: 'Something went wrong',
    please_try_again: 'Please try again',
    not_found: 'Not found',
    unauthorized: 'Unauthorized',
    forbidden: 'Forbidden',
    server_error: 'Server error',

    // Network
    network_error: 'Network error. Please check your connection.',
    timeout_error: 'Request timed out. Please try again.',

    // Validation
    validation_error: 'Validation error',
    invalid_data: 'Invalid data provided',

    // Operations
    load_failed: 'Failed to load data',
    save_failed: 'Failed to save changes',
    delete_failed: 'Failed to delete',
    update_failed: 'Failed to update',
    create_failed: 'Failed to create',
  },

  // ============================================
  // Actions
  // ============================================
  actions: {
    // Activities
    log_activity: 'Log Activity',
    activity_type: 'Activity Type',
    call: 'Call',
    email: 'Email',
    meeting: 'Meeting',
    note: 'Note',
    task: 'Task',

    // Activity types
    activity_call: 'Phone Call',
    activity_email: 'Email',
    activity_meeting: 'Meeting',
    activity_note: 'Note',
    activity_task: 'Task',

    // Messages
    activity_logged: 'Activity logged successfully',
    task_created: 'Task created successfully',
    task_completed: 'Task completed',
  },
};
