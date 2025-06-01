import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:message_app/feature/contact/controllers/contacts_controller.dart';
import 'package:message_app/feature/contact/repository/contacts_repository.dart';

final contactControllerProvider = StateNotifierProvider<ContactsController, AsyncValue<List<List<UserModel>>>>((ref) {
  return ContactsController(ref.read(contactsRepositoryProvider));
});
