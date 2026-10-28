import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/data/models/user_role.dart';

void main() {
  group('UserRole Model', () {
    group('UserRole Enum', () {
      test('has all expected roles', () {
        expect(UserRole.owner.name, 'owner');
        expect(UserRole.admin.name, 'admin');
        expect(UserRole.staff.name, 'staff');
        expect(UserRole.client.name, 'client');
      });

      test('role hierarchy is correct', () {
        expect(UserRole.owner.index, 0);
        expect(UserRole.admin.index, 1);
        expect(UserRole.staff.index, 2);
        expect(UserRole.client.index, 3);
      });
    });

    group('canManageBusiness', () {
      test('only owner can manage business', () {
        expect(UserRole.owner.canManageBusiness, true);
        expect(UserRole.admin.canManageBusiness, false);
        expect(UserRole.staff.canManageBusiness, false);
        expect(UserRole.client.canManageBusiness, false);
      });
    });

    group('canManageUsers', () {
      test('owner and admin can manage users', () {
        expect(UserRole.owner.canManageUsers, true);
        expect(UserRole.admin.canManageUsers, true);
        expect(UserRole.staff.canManageUsers, false);
        expect(UserRole.client.canManageUsers, false);
      });
    });

    group('canManageAllAppointments', () {
      test('owner and admin can manage all appointments', () {
        expect(UserRole.owner.canManageAllAppointments, true);
        expect(UserRole.admin.canManageAllAppointments, true);
        expect(UserRole.staff.canManageAllAppointments, false);
        expect(UserRole.client.canManageAllAppointments, false);
      });
    });

    group('canManageProviders', () {
      test('owner and admin can manage providers', () {
        expect(UserRole.owner.canManageProviders, true);
        expect(UserRole.admin.canManageProviders, true);
        expect(UserRole.staff.canManageProviders, false);
        expect(UserRole.client.canManageProviders, false);
      });
    });

    group('canManageClients', () {
      test('owner and admin can manage clients', () {
        expect(UserRole.owner.canManageClients, true);
        expect(UserRole.admin.canManageClients, true);
        expect(UserRole.staff.canManageClients, true);
        expect(UserRole.client.canManageClients, false);
      });
    });

    group('canManagePayments', () {
      test('owner, admin, and staff can manage payments', () {
        expect(UserRole.owner.canManagePayments, true);
        expect(UserRole.admin.canManagePayments, true);
        expect(UserRole.staff.canManagePayments, true);
        expect(UserRole.client.canManagePayments, false);
      });
    });

    group('canViewOwnAppointments', () {
      test('all roles can view own appointments', () {
        expect(UserRole.owner.canViewOwnAppointments, true);
        expect(UserRole.admin.canViewOwnAppointments, true);
        expect(UserRole.staff.canViewOwnAppointments, true);
        expect(UserRole.client.canViewOwnAppointments, true);
      });
    });

    group('canManageOwnSchedule', () {
      test('owner, admin, and staff can manage own schedule', () {
        expect(UserRole.owner.canManageOwnSchedule, true);
        expect(UserRole.admin.canManageOwnSchedule, true);
        expect(UserRole.staff.canManageOwnSchedule, true);
        expect(UserRole.client.canManageOwnSchedule, false);
      });
    });

    group('UserProfile', () {
      group('JSON Serialization', () {
        test('creates user profile from JSON', () {
          final json = {
            'id': 'user-1',
            'businessId': 'business-1',
            'role': 'admin',
            'providerId': null,
            'clientId': null,
            'email': 'admin@example.com',
            'displayName': 'Admin User',
            'createdAt': '2025-12-01T10:00:00.000Z',
            'lastLoginAt': '2025-12-01T12:00:00.000Z',
          };

          final profile = UserProfile.fromJson(json);

          expect(profile.id, 'user-1');
          expect(profile.businessId, 'business-1');
          expect(profile.role, UserRole.admin);
          expect(profile.email, 'admin@example.com');
          expect(profile.displayName, 'Admin User');
        });

        test('converts user profile to JSON', () {
          final profile = UserProfile(
            id: 'user-1',
            businessId: 'business-1',
            role: UserRole.staff,
            providerId: 'provider-1',
            email: 'staff@example.com',
            displayName: 'Staff Member',
            createdAt: DateTime(2025, 12, 1),
          );

          final json = profile.toJson();

          expect(json['id'], 'user-1');
          expect(json['businessId'], 'business-1');
          expect(json['role'], 'staff');
          expect(json['providerId'], 'provider-1');
          expect(json['email'], 'staff@example.com');
        });
      });

      test('owner profile', () {
        final owner = UserProfile(
          id: 'owner-1',
          businessId: 'business-1',
          role: UserRole.owner,
          email: 'owner@example.com',
          displayName: 'Dr. Smith',
          createdAt: DateTime(2025, 1, 1),
        );

        expect(owner.role, UserRole.owner);
        expect(owner.role.canManageBusiness, true);
        expect(owner.role.canManageUsers, true);
        expect(owner.role.canManageAllAppointments, true);
      });

      test('admin profile', () {
        final admin = UserProfile(
          id: 'admin-1',
          businessId: 'business-1',
          role: UserRole.admin,
          email: 'admin@example.com',
          displayName: 'Office Manager',
          createdAt: DateTime(2025, 1, 1),
        );

        expect(admin.role, UserRole.admin);
        expect(admin.role.canManageBusiness, false);
        expect(admin.role.canManageUsers, true);
        expect(admin.role.canManageAllAppointments, true);
        expect(admin.role.canManageProviders, true);
        expect(admin.role.canManageClients, true);
      });

      test('staff profile with provider ID', () {
        final staff = UserProfile(
          id: 'staff-1',
          businessId: 'business-1',
          role: UserRole.staff,
          providerId: 'provider-1',
          email: 'staff@example.com',
          displayName: 'Dr. Johnson',
          createdAt: DateTime(2025, 1, 1),
        );

        expect(staff.role, UserRole.staff);
        expect(staff.providerId, 'provider-1');
        expect(staff.role.canManageOwnSchedule, true);
        expect(staff.role.canManageAllAppointments, false);
        expect(staff.role.canManageClients, true);
      });

      test('client profile with client ID', () {
        final client = UserProfile(
          id: 'client-1',
          businessId: 'business-1',
          role: UserRole.client,
          clientId: 'client-1',
          email: 'client@example.com',
          displayName: 'Jane Doe',
          createdAt: DateTime(2025, 1, 1),
        );

        expect(client.role, UserRole.client);
        expect(client.clientId, 'client-1');
        expect(client.role.canViewOwnAppointments, true);
        expect(client.role.canManageOwnSchedule, false);
        expect(client.role.canManageClients, false);
      });

      test('hasAccessToBusiness checks business ID match', () {
        final profile = UserProfile(
          id: 'user-1',
          businessId: 'business-1',
          role: UserRole.admin,
          createdAt: DateTime(2025, 1, 1),
        );

        expect(profile.hasAccessToBusiness('business-1'), true);
        expect(profile.hasAccessToBusiness('business-2'), false);
      });

      test('canAccessClient allows admin to access any client', () {
        final admin = UserProfile(
          id: 'admin-1',
          businessId: 'business-1',
          role: UserRole.admin,
          createdAt: DateTime(2025, 1, 1),
        );

        expect(admin.canAccessClient('client-1', 'business-1'), true);
        expect(admin.canAccessClient('client-2', 'business-1'), true);
        expect(admin.canAccessClient('client-1', 'business-2'), false);
      });

      test('canAccessClient restricts client to own data', () {
        final client = UserProfile(
          id: 'client-user-1',
          businessId: 'business-1',
          role: UserRole.client,
          clientId: 'client-1',
          createdAt: DateTime(2025, 1, 1),
        );

        expect(client.canAccessClient('client-1', 'business-1'), true);
        expect(client.canAccessClient('client-2', 'business-1'), false);
        expect(client.canAccessClient('client-1', 'business-2'), false);
      });

      test('canAccessProvider allows admin to access any provider', () {
        final admin = UserProfile(
          id: 'admin-1',
          businessId: 'business-1',
          role: UserRole.admin,
          createdAt: DateTime(2025, 1, 1),
        );

        expect(admin.canAccessProvider('provider-1', 'business-1'), true);
        expect(admin.canAccessProvider('provider-2', 'business-1'), true);
        expect(admin.canAccessProvider('provider-1', 'business-2'), false);
      });

      test('canAccessProvider restricts staff to own data', () {
        final staff = UserProfile(
          id: 'staff-1',
          businessId: 'business-1',
          role: UserRole.staff,
          providerId: 'provider-1',
          createdAt: DateTime(2025, 1, 1),
        );

        expect(staff.canAccessProvider('provider-1', 'business-1'), true);
        expect(staff.canAccessProvider('provider-2', 'business-1'), false);
        expect(staff.canAccessProvider('provider-1', 'business-2'), false);
      });

      test('tracks last login time', () {
        final lastLoginTime = DateTime(2025, 12, 1, 14, 30);
        final profile = UserProfile(
          id: 'user-1',
          businessId: 'business-1',
          role: UserRole.admin,
          createdAt: DateTime(2025, 1, 1),
        );

        expect(profile.lastLoginAt, null);

        final updated = profile.copyWith(lastLoginAt: lastLoginTime);
        expect(updated.lastLoginAt, lastLoginTime);
      });
    });

    group('Real-World RBAC Examples', () {
      test('dental clinic owner scenario', () {
        final owner = UserProfile(
          id: 'owner-1',
          businessId: 'dental-1',
          role: UserRole.owner,
          email: 'dr.smith@example.com',
          displayName: 'Dr. Smith',
          createdAt: DateTime(2025, 1, 1),
        );

        expect(owner.role.canManageBusiness, true);
        expect(owner.role.canManageUsers, true);
        expect(owner.role.canManageProviders, true);
        expect(owner.role.canManageClients, true);
        expect(owner.role.canManagePayments, true);
        expect(owner.hasAccessToBusiness('dental-1'), true);
      });

      test('office manager scenario', () {
        final manager = UserProfile(
          id: 'manager-1',
          businessId: 'dental-1',
          role: UserRole.admin,
          email: 'manager@example.com',
          displayName: 'Office Manager',
          createdAt: DateTime(2025, 1, 15),
        );

        expect(manager.role.canManageBusiness, false); // Can't change settings
        expect(manager.role.canManageUsers, true);
        expect(manager.role.canManageAllAppointments, true);
        expect(manager.role.canManageClients, true);
      });

      test('dentist staff member scenario', () {
        final dentist = UserProfile(
          id: 'dentist-1',
          businessId: 'dental-1',
          role: UserRole.staff,
          providerId: 'provider-1',
          email: 'dr.johnson@example.com',
          displayName: 'Dr. Johnson',
          createdAt: DateTime(2025, 2, 1),
        );

        expect(dentist.role.canManageOwnSchedule, true);
        expect(dentist.role.canManageAllAppointments, false);
        expect(dentist.role.canManageClients, true);
        expect(dentist.canAccessProvider('provider-1', 'dental-1'), true);
        expect(dentist.canAccessProvider('provider-2', 'dental-1'), false);
      });

      test('patient client scenario', () {
        final patient = UserProfile(
          id: 'patient-1',
          businessId: 'dental-1',
          role: UserRole.client,
          clientId: 'client-1',
          email: 'patient@example.com',
          displayName: 'John Doe',
          createdAt: DateTime(2025, 3, 1),
        );

        expect(patient.role.canViewOwnAppointments, true);
        expect(patient.role.canManageClients, false);
        expect(patient.canAccessClient('client-1', 'dental-1'), true);
        expect(patient.canAccessClient('client-2', 'dental-1'), false);
      });

      test('multi-tenant isolation enforced', () {
        final adminBusiness1 = UserProfile(
          id: 'admin-1',
          businessId: 'business-1',
          role: UserRole.admin,
          createdAt: DateTime(2025, 1, 1),
        );

        final adminBusiness2 = UserProfile(
          id: 'admin-2',
          businessId: 'business-2',
          role: UserRole.admin,
          createdAt: DateTime(2025, 1, 1),
        );

        expect(adminBusiness1.hasAccessToBusiness('business-1'), true);
        expect(adminBusiness1.hasAccessToBusiness('business-2'), false);
        expect(adminBusiness2.hasAccessToBusiness('business-2'), true);
        expect(adminBusiness2.hasAccessToBusiness('business-1'), false);
      });
    });
  });
}
