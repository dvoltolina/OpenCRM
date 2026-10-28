/**
 * Firestore Setup Script
 * Run with: node scripts/setupFirestore.js
 *
 * This script initializes the Firestore database with the required collections
 * and sample data for the Scheduler Admin Dashboard.
 */

import { initializeApp } from 'firebase/app';
import { getFirestore, collection, doc, setDoc } from 'firebase/firestore';

// Your Firebase config (copy from .env)
const firebaseConfig = {
  apiKey: process.env.VITE_FIREBASE_API_KEY,
  authDomain: process.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: process.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.VITE_FIREBASE_APP_ID,
};

const missingConfig = Object.entries(firebaseConfig).filter(([, value]) => !value);
if (missingConfig.length) {
  throw new Error(`Set your Firebase environment variables: ${missingConfig.map(([key]) => key).join(', ')}`);
}

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// Change this to your business ID
const BUSINESS_ID = process.env.BUSINESS_ID;
if (!BUSINESS_ID) throw new Error('Set BUSINESS_ID to the tenant you intend to seed.');

async function setupCollections() {
  console.log('Setting up Firestore collections...\n');

  try {
    // 1. Create sample clients
    console.log('Creating clients...');
    const clientsRef = collection(db, `businesses/${BUSINESS_ID}/clients`);

    await setDoc(doc(clientsRef, 'client-1'), {
      businessId: BUSINESS_ID,
      name: 'Jane Doe',
      firstName: 'Jane',
      lastName: 'Doe',
      email: 'jane@example.com',
      phone: '(415) 555-0100',
      lifecycle: 'active',
      tags: ['vip'],
      createdAt: new Date().toISOString(),
    });

    await setDoc(doc(clientsRef, 'client-2'), {
      businessId: BUSINESS_ID,
      name: 'Sam Rivera',
      firstName: 'Sam',
      lastName: 'Rivera',
      email: 'sam@example.com',
      phone: '(415) 555-0123',
      lifecycle: 'new',
      tags: ['membership'],
      createdAt: new Date().toISOString(),
    });

    await setDoc(doc(clientsRef, 'client-3'), {
      businessId: BUSINESS_ID,
      name: 'Taylor Poe',
      firstName: 'Taylor',
      lastName: 'Poe',
      email: 'tpoe@example.com',
      phone: '(415) 555-0144',
      lifecycle: 'inactive',
      tags: ['inactive'],
      createdAt: new Date().toISOString(),
    });

    console.log('Created 3 sample clients\n');

    await setDoc(
      doc(db, `businesses/${BUSINESS_ID}/clients/client-1/files/_placeholder`),
      { placeholder: true, createdAt: new Date().toISOString() },
    );

    // 2. Create sample services
    console.log('Creating services...');
    const servicesRef = collection(db, `businesses/${BUSINESS_ID}/services`);

    await setDoc(doc(servicesRef, 'service-1'), {
      businessId: BUSINESS_ID,
      name: 'Initial Consultation',
      durationMinutes: 60,
      price: 120,
      colorHex: '#3b82f6',
      category: 'Consultation',
      isActive: true,
    });

    await setDoc(doc(servicesRef, 'service-2'), {
      businessId: BUSINESS_ID,
      name: 'Follow-up Session',
      durationMinutes: 45,
      price: 90,
      colorHex: '#10b981',
      category: 'Session',
      isActive: true,
    });

    console.log('Created 2 sample services\n');

    // 3. Create sample appointments
    console.log('Creating appointments...');
    const appointmentsRef = collection(db, `businesses/${BUSINESS_ID}/appointments`);

    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(10, 0, 0, 0);

    await setDoc(doc(appointmentsRef, 'appt-1'), {
      businessId: BUSINESS_ID,
      clientId: 'client-1',
      staffId: 'staff-1',
      serviceId: 'service-1',
      start: tomorrow.toISOString(),
      end: new Date(tomorrow.getTime() + 60 * 60 * 1000).toISOString(),
      status: 'confirmed',
      createdAt: new Date().toISOString(),
    });

    console.log('Created 1 sample appointment\n');

    // 4. Create feature flags
    console.log('Creating feature flags...');
    await setDoc(doc(db, `businesses/${BUSINESS_ID}/settings/feature_flags`), {
      enableCalendarSync: true,
      enableTelehealth: true,
      enableAutomatedReminders: true,
      enableWaitlist: true,
      enablePayments: true,
      enableReporting: true,
      enableClientPortal: true,
      enableSessionNotes: true,
      enableMarketing: false,
      waitlistNotifyChannels: ['email', 'sms'],
    });

    console.log('Created feature flags\n');

    // 5. Create locations
    console.log('Creating locations...');
    const locationsRef = collection(db, `businesses/${BUSINESS_ID}/locations`);

    await setDoc(doc(locationsRef, 'location-1'), {
      businessId: BUSINESS_ID,
      name: 'Main Office',
      address: '123 Main St, San Francisco, CA 94102',
      timezone: 'America/Los_Angeles',
      hours: 'Mon-Fri: 9am-5pm',
      staffIds: [],
      notes: 'Primary location',
    });

    console.log('Created 1 location\n');

    // 6. Initialize empty collections (to make them visible in Firestore Console)
    console.log('Initializing empty collections...');

    const collections = [
      'providers',
      'waitlist_entries',
      'payments',
      'intakeFormTemplates',
      'intakeFormSubmissions',
      'intakeFormDrafts',
      'session_notes',
      'integrations',
      'message_templates',
      'automation_rules',
      'message_history',
      'resources',
    ];

    for (const collectionName of collections) {
      const ref = doc(db, `businesses/${BUSINESS_ID}/${collectionName}/_placeholder`);
      await setDoc(ref, { placeholder: true, createdAt: new Date().toISOString() });
    }

    console.log('Initialized empty collections\n');

    console.log('Setup complete. Your Firestore database is ready.\n');
    console.log('Next steps:');
    console.log('1. Go to http://localhost:5174');
    console.log('2. Login with your admin account');
    console.log('3. Navigate to Clients page to see the sample data');
    console.log('4. Click on a client to open the profile drawer\n');

  } catch (error) {
    console.error('Error setting up Firestore:', error);
    process.exit(1);
  }

  process.exit(0);
}

// Run setup
setupCollections();
