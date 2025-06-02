import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/common/models/user_model.dart';

final contactsRepositoryProvider = Provider((ref) {
  return ContactsRepository(firestore: FirebaseFirestore.instance);
});

class ContactsRepository {
  final FirebaseFirestore firestore;

  ContactsRepository({required this.firestore});

  Future<List<List<UserModel>>> getAllContacts() async {
    List<UserModel> firebaseContacts = [];
    List<UserModel> phoneContacts = [];

    try {
      if (await FlutterContacts.requestPermission()) {
        final userCollection = await firestore.collection('users').get();
        final allContactsInThePhone = await FlutterContacts.getContacts(
          withProperties: true,
        );
        bool isContactFound = false;

        for (var contact in allContactsInThePhone) {
          for (var firebaseContactData in userCollection.docs) {
            var firebaseContact = UserModel.fromMap(firebaseContactData.data());
            if (contact.phones.isNotEmpty &&
                contact.phones[0].number.replaceAll(' ', '') ==
                    firebaseContact.phoneNumber) {
              firebaseContacts.add(firebaseContact);
              isContactFound = true;
              break;
            }
          }
          if (!isContactFound && contact.phones.isNotEmpty) {
            phoneContacts.add(
              UserModel(
                username: contact.displayName,
                uid: '',
                profileImageUrl: '',
                active: false,
                lastSeen: 0,
                phoneNumber: contact.phones[0].number.replaceAll(' ', ''),
                groupId: [],
                isAdmin: false,
                fcmToken: '',
              ),
            );
          }
          isContactFound = false;
        }
      }
    } catch (e) {
      log(e.toString());
    }

    return [firebaseContacts, phoneContacts];
  }

  Future<List<UserModel>> searchContacts(String query) async {
    final firebaseContactsByName =
        await firestore
            .collection('users')
            .where('username', isGreaterThanOrEqualTo: query)
            .where('username', isLessThan: '${query}z')
            .get();

    final firebaseContactsByPhone =
        await firestore
            .collection('users')
            .where('phoneNumber', isGreaterThanOrEqualTo: query)
            .where('phoneNumber', isLessThan: '${query}z')
            .get();

    final phoneContacts = await getAllContacts();
    final filteredPhoneContacts =
        phoneContacts[1].where((contact) {
          final name = contact.username.toLowerCase();
          final phoneNumber = contact.phoneNumber.toLowerCase();
          return name.contains(query.toLowerCase()) ||
              phoneNumber.contains(query.toLowerCase());
        }).toList();

    final firebaseContactListByName =
        firebaseContactsByName.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList();
    final firebaseContactListByPhone =
        firebaseContactsByPhone.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList();

    final combinedFirebaseContacts = [
      ...firebaseContactListByName,
      ...firebaseContactListByPhone,
    ];

    return [...combinedFirebaseContacts, ...filteredPhoneContacts];
  }
}
