import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:message_app/feature/contact/repository/contacts_repository.dart';

class ContactsController extends StateNotifier<AsyncValue<List<List<UserModel>>>> {
  final ContactsRepository _contactsRepository;

  ContactsController(this._contactsRepository) : super(const AsyncValue.loading()) {
    fetchContacts();
  }

  Future<void> fetchContacts() async {
    state = const AsyncValue.loading();
    try {
      final contacts = await _contactsRepository.getAllContacts();
      state = AsyncValue.data(contacts);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<List<UserModel>> searchContacts(String query) async {
    return await _contactsRepository.searchContacts(query);
  }
}
