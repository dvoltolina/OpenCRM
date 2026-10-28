import {
  BUSINESS_ID,
  OWNER_EMAIL,
  OWNER_NAME,
  OWNER_UID,
  addDocument,
  clientNames,
  companySeeds,
  dateOnly,
  fullName,
  locations,
  phoneAt,
  services,
  shareable,
  shiftDate,
  staffMembers,
  type DocEntry,
} from './common';

export function buildSharedSchedulerDocuments(docs: DocEntry[]): void {
  addDocument(docs, 'businesses', 'businesses/' + BUSINESS_ID, {
    id: BUSINESS_ID,
    name: 'OpenCRM Demo Workspace',
    slug: 'opencrm-demo',
    publicBookingUrl: 'https://demo.example.com/opencrm-demo',
    createdAt: shiftDate(-90, 9),
    updatedAt: new Date(),
    ownerId: OWNER_UID,
    ownerEmail: OWNER_EMAIL,
    requiresHipaaCompliance: false,
    auditLoggingEnabled: true,
    demoModeEnabled: true,
    seedLabel: 'agent-prompts-demo-mode-agent-1',
  });

  staffMembers.forEach((staff, index) => {
    addDocument(docs, 'users', 'users/' + staff.id, {
      businessId: BUSINESS_ID,
      role: staff.role,
      email: index === 0 ? OWNER_EMAIL : staff.email,
      displayName: index === 0 ? OWNER_NAME : fullName(staff.firstName, staff.lastName),
      createdAt: shiftDate(-120 + index, 8),
      providerId: staff.id,
      teamIds: staff.teamIds.slice(),
      managedTeamIds: staff.managedTeamIds ? staff.managedTeamIds.slice() : [],
    });

    addDocument(docs, 'providers', 'businesses/' + BUSINESS_ID + '/providers/' + staff.id, {
      id: staff.id,
      businessId: BUSINESS_ID,
      firstName: index === 0 ? OWNER_NAME.split(' ')[0] : staff.firstName,
      lastName: index === 0 ? OWNER_NAME.split(' ').slice(1).join(' ') || 'Demo' : staff.lastName,
      email: index === 0 ? OWNER_EMAIL : staff.email,
      phone: staff.phone,
      serviceIds: services.filter((service) => service.providerIds.indexOf(staff.id) >= 0).map((service) => service.id),
      locationIds: staff.locationIds.slice(),
      colorHex: staff.colorHex,
      role: staff.role,
      status: 'active',
      workingHours: [
        { dayOfWeek: 1, start: '09:00', end: '17:00' },
        { dayOfWeek: 2, start: '09:00', end: '17:00' },
        { dayOfWeek: 3, start: '09:00', end: '17:00' },
        { dayOfWeek: 4, start: '09:00', end: '17:00' },
        { dayOfWeek: 5, start: '09:00', end: '15:00' },
      ],
      createdAt: shiftDate(-120 + index, 9),
      updatedAt: new Date(),
    });
  });

  locations.forEach((location, index) => {
    addDocument(docs, 'locations', 'businesses/' + BUSINESS_ID + '/locations/' + location.id, {
      id: location.id,
      businessId: BUSINESS_ID,
      name: location.name,
      address: location.address,
      city: location.city,
      state: location.state,
      zipCode: location.zipCode,
      timezone: location.timezone,
      hours: {
        monday: ['09:00-17:00'],
        tuesday: ['09:00-17:00'],
        wednesday: ['09:00-17:00'],
        thursday: ['09:00-17:00'],
        friday: ['09:00-16:00'],
      },
      createdAt: shiftDate(-150 + index, 8),
    });
  });

  services.forEach((service, index) => {
    addDocument(docs, 'services', 'businesses/' + BUSINESS_ID + '/services/' + service.id, {
      id: service.id,
      businessId: BUSINESS_ID,
      name: service.name,
      durationMinutes: service.durationMinutes,
      price: service.price,
      category: service.category,
      providerIds: service.providerIds.slice(),
      locationIds: service.locationIds.slice(),
      requiredResources: [],
      bufferMinutes: service.bufferMinutes,
      isActive: true,
      createdAt: shiftDate(-80 + index, 10),
    });
  });

  clientNames.forEach((client, index) => {
    const companyId = 'company-demo-' + String((index % companySeeds.length) + 1).padStart(2, '0');
    addDocument(docs, 'clients', 'businesses/' + BUSINESS_ID + '/clients/client-demo-' + String(index + 1).padStart(2, '0'), {
      id: 'client-demo-' + String(index + 1).padStart(2, '0'),
      businessId: BUSINESS_ID,
      firstName: client[0],
      lastName: client[1],
      email: client[0].toLowerCase() + '.' + client[1].toLowerCase() + String(index + 1).padStart(2, '0') + '@demo.example.com',
      phone: phoneAt(30 + index),
      lifecycle: index % 5 === 0 ? 'prospect' : index % 4 === 0 ? 'inactive' : 'active',
      tags: index % 3 === 0 ? ['demo', 'vip'] : ['demo'],
      userId: index < 6 ? staffMembers[index].id : undefined,
      companyId,
      companyName: companySeeds[index % companySeeds.length][0],
      title: index % 2 === 0 ? 'Operations Lead' : 'Growth Manager',
      address: {
        street: String(600 + index) + ' Client Demo Road',
        city: 'Example Hills',
        state: 'CO',
        zipCode: '802' + String(index).padStart(2, '0'),
        country: 'USA',
      },
      crmNotes: 'Fake client profile used for demo browsing only.',
      lastContactedAt: shiftDate(-1 * ((index % 12) + 1), 14),
      leadSource: ['website', 'referral', 'social', 'event'][index % 4],
      createdAt: shiftDate(-60 + index, 9),
      updatedAt: new Date(),
      ...shareable(index),
    });
  });

  for (let index = 0; index < 48; index += 1) {
    const appointmentId = 'appointment-demo-' + String(index + 1).padStart(2, '0');
    const clientId = 'client-demo-' + String((index % clientNames.length) + 1).padStart(2, '0');
    const providerId = staffMembers[index % staffMembers.length].id;
    const service = services[index % services.length];
    const startTime = shiftDate(index - 24, 9 + (index % 6), index % 2 === 0 ? 0 : 30);
    const endTime = new Date(startTime.getTime() + service.durationMinutes * 60000);
    const status =
      index < 22
        ? ['completed', 'completed', 'confirmed', 'noShow', 'cancelled'][index % 5]
        : index < 34
          ? ['completed', 'confirmed', 'confirmed', 'pending'][index % 4]
          : ['confirmed', 'pending', 'confirmed', 'confirmed'][index % 4];
    addDocument(docs, 'appointments', 'businesses/' + BUSINESS_ID + '/appointments/' + appointmentId, {
      id: appointmentId,
      businessId: BUSINESS_ID,
      clientId,
      providerId,
      serviceId: service.id,
      serviceType: service.name,
      locationId: service.locationIds[index % service.locationIds.length],
      startTime,
      endTime,
      date: dateOnly(startTime),
      status,
      notes: 'Demo appointment for scheduler previews.',
      createdAt: new Date(startTime.getTime() - 5 * 24 * 60 * 60 * 1000),
      requiresPayment: true,
      paymentType: 'full',
      paymentStatus: status === 'completed' ? 'completed' : status === 'confirmed' ? 'pending' : 'none',
      paymentAmountCents: service.price * 100,
      isGroupSession: index % 12 === 0,
      capacity: index % 12 === 0 ? 8 : undefined,
      attendeeIds: index % 12 === 0 ? [clientId, 'client-demo-002', 'client-demo-003'] : [],
      publicVisibility: false,
    });
  }

  for (let index = 0; index < 8; index += 1) {
    const clientId = 'client-demo-' + String(17 + index).padStart(2, '0');
    const service = services[(index + 2) % services.length];
    const provider = staffMembers[(index + 1) % staffMembers.length];
    addDocument(docs, 'waitlist_entries', 'businesses/' + BUSINESS_ID + '/waitlist_entries/waitlist-demo-' + String(index + 1).padStart(2, '0'), {
      id: 'waitlist-demo-' + String(index + 1).padStart(2, '0'),
      businessId: BUSINESS_ID,
      clientId,
      clientName: clientNames[16 + index][0] + ' ' + clientNames[16 + index][1],
      clientEmail: 'waitlist' + String(index + 1).padStart(2, '0') + '@demo.example.com',
      clientPhone: phoneAt(80 + index),
      serviceId: service.id,
      serviceName: service.name,
      providerId: provider.id,
      providerName: fullName(provider.firstName, provider.lastName),
      locationId: service.locationIds[0],
      preferredDaysOfWeek: [1, 2, 3, 4, 5],
      timeOfDayPreferences: index % 2 === 0 ? ['morning'] : ['afternoon'],
      earliestDate: shiftDate(2 + index, 0),
      latestDate: shiftDate(9 + index, 0),
      priorityScore: 0.5 + index * 0.05,
      notificationPreference: index % 3 === 0 ? 'both' : 'email',
      status: ['active', 'active', 'notified', 'converted'][index % 4],
      createdAt: shiftDate(-5 + index, 10),
      updatedAt: new Date(),
      notes: 'Fake waitlist entry for demo automation previews.',
    });
  }

  for (let index = 0; index < 18; index += 1) {
    const appointmentId = 'appointment-demo-' + String(index + 1).padStart(2, '0');
    const service = services[index % services.length];
    addDocument(docs, 'payments', 'businesses/' + BUSINESS_ID + '/payments/payment-demo-' + String(index + 1).padStart(2, '0'), {
      id: 'payment-demo-' + String(index + 1).padStart(2, '0'),
      businessId: BUSINESS_ID,
      appointmentId,
      clientId: 'client-demo-' + String((index % clientNames.length) + 1).padStart(2, '0'),
      clientName: clientNames[index % clientNames.length][0] + ' ' + clientNames[index % clientNames.length][1],
      amountCents: service.price * 100,
      currency: 'USD',
      status: index % 7 === 0 ? 'refunded' : 'completed',
      method: ['card', 'bank_transfer', 'cash'][index % 3],
      type: index % 7 === 0 ? 'refund' : index % 4 === 0 ? 'deposit' : 'full',
      description: service.name + ' demo payment',
      dealId: 'deal-demo-' + String((index % 14) + 1).padStart(2, '0'),
      dealTitle: companySeeds[index % companySeeds.length][0] + ' Demo Expansion',
      providerId: 'pay_demo_' + String(index + 1).padStart(2, '0'),
      receiptUrl: 'https://demo.example.com/receipts/payment-' + String(index + 1).padStart(2, '0'),
      last4: String(4242 + index).slice(-4),
      cardBrand: index % 2 === 0 ? 'visa' : 'mastercard',
      processedById: staffMembers[index % staffMembers.length].id,
      processedByName: fullName(staffMembers[index % staffMembers.length].firstName, staffMembers[index % staffMembers.length].lastName),
      processedAt: shiftDate(-18 + index, 16),
      createdAt: shiftDate(-18 + index, 16),
      updatedAt: new Date(),
    });
  }
}
