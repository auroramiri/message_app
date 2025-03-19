import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:message_app/common/routes/routes.dart';
import 'package:message_app/common/utils/coloors.dart';
import 'package:message_app/common/widgets/contact_card.dart';
import 'package:message_app/common/widgets/custom_icon_button.dart';
import 'package:message_app/feature/contact/controllers/contacts_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends ConsumerWidget {
  const ContactPage({super.key});

  shareSmsLink(phoneNumber) async {
    Uri sms = Uri.parse("sms:$phoneNumber?body=Let's chat on Бундъварка!");
    if (await launchUrl(sms)) {
    } else {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select contact', style: TextStyle(color: Colors.white)),
            SizedBox(height: 3),
            ref
                .watch(contactControllerProvider)
                .when(
                  data: (allContacts) {
                    return Text(
                      "${allContacts[0].length} Contact${allContacts[0].length == 1 ? '' : 's'}",
                      style: TextStyle(fontSize: 13),
                    );
                  },
                  error: (e, t) {
                    return SizedBox();
                  },
                  loading: () {
                    return Text('Counting', style: TextStyle(fontSize: 12));
                  },
                ),
          ],
        ),
        actions: [
          CustomIconButton(onTap: () {}, icon: Icons.search),
          CustomIconButton(onTap: () {}, icon: Icons.more_vert),
        ],
      ),
      body: ref
          .watch(contactControllerProvider)
          .when(
            data: (allContacts) {
              return ListView.builder(
                itemCount: allContacts[0].length + allContacts[1].length,
                itemBuilder: (context, index) {
                  late UserModel firebaseContacts;
                  late UserModel phoneContacts;

                  if (index < allContacts[0].length) {
                    firebaseContacts = allContacts[0][index];
                  } else {
                    phoneContacts =
                        allContacts[1][index - allContacts[0].length];
                  }
                  return index < allContacts[0].length
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (index == 0)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                myListTile(
                                  leading: Icons.group,
                                  text: 'New group',
                                ),
                                myListTile(
                                  leading: Icons.contacts,
                                  text: 'New contact',
                                  trailing: Icons.qr_code,
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    'Contacts on Бундъварка',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: context.theme.greyColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ContactCard(
                            contactSource: firebaseContacts,
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                Routes.chat,
                                arguments: firebaseContacts,
                              );
                            },
                          ),
                        ],
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (index == allContacts[0].length)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              child: Text(
                                'Contacts on Бундъварка',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: context.theme.greyColor,
                                ),
                              ),
                            ),
                          ContactCard(
                            contactSource: phoneContacts,
                            onTap:
                                () => shareSmsLink(phoneContacts.phoneNumber),
                          ),
                        ],
                      );
                },
              );
            },
            error: (e, t) {
              return null;
            },
            loading: () {
              return Center(
                child: CircularProgressIndicator(
                  color: context.theme.authAppbarTextColor,
                ),
              );
            },
          ),
    );
  }

  ListTile myListTile({
    required IconData leading,
    required String text,
    IconData? trailing,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.only(top: 10, left: 20, right: 10),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Coloors.blueDark,
        child: Icon(leading, color: Colors.white),
      ),
      title: Text(
        text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(trailing, color: Coloors.greyDark),
    );
  }
}
