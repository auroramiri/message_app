import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:message_app/common/utils/coloors.dart';
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
                          ListTile(
                            contentPadding: EdgeInsets.only(
                              left: 20,
                              right: 10,
                              top: 0,
                              bottom: 0,
                            ),
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor: context.theme.greyColor!
                                  .withValues(alpha: 0.3),
                              radius: 20,
                              backgroundImage:
                                  firebaseContacts.profileImageUrl.isNotEmpty
                                      ? NetworkImage(
                                        firebaseContacts.profileImageUrl,
                                      )
                                      : null,
                              child:
                                  firebaseContacts.profileImageUrl.isEmpty
                                      ? Icon(
                                        Icons.person,
                                        size: 30,
                                        color: Colors.white,
                                      )
                                      : null,
                            ),
                            title: Text(
                              firebaseContacts.username,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              "Hey there! I'm using Бундъварка",
                              style: TextStyle(
                                color: context.theme.greyColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                          ListTile(
                            onTap:
                                () => shareSmsLink(phoneContacts.phoneNumber),
                            contentPadding: EdgeInsets.only(
                              left: 20,
                              right: 10,
                              top: 0,
                              bottom: 0,
                            ),
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor: context.theme.greyColor!
                                  .withValues(alpha: 0.3),
                              radius: 20,
                              child: Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              phoneContacts.username,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: TextButton(
                              onPressed:
                                  () => shareSmsLink(phoneContacts.phoneNumber),
                              style: TextButton.styleFrom(
                                foregroundColor: Coloors.blueDark,
                              ),
                              child: Text('INVITE'),
                            ),
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
}
