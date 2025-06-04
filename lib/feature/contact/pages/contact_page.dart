import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';
import 'package:message_app/common/models/user_model.dart';
import 'package:message_app/common/routes/routes.dart';
import 'package:message_app/common/widgets/contact_card.dart';
import 'package:message_app/common/widgets/custom_icon_button.dart';
import 'package:message_app/feature/contact/controllers/contacts_controller_provider.dart';
import 'package:message_app/feature/contact/widgets/my_list_tile.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends ConsumerStatefulWidget {
  const ContactPage({super.key});

  @override
  ConsumerState<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends ConsumerState<ContactPage> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<UserModel> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchQuery != _searchController.text) {
      setState(() {
        _searchQuery = _searchController.text;
      });
      if (_searchQuery.isNotEmpty) {
        ref
            .read(contactControllerProvider.notifier)
            .searchContacts(_searchQuery)
            .then((contacts) {
              if (mounted) {
                setState(() {
                  _filteredContacts = contacts;
                });
              }
            });
      }
    }
  }

  void _toggleSearching() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
        _filteredContacts = [];
      }
    });
  }

  Future<void> shareSmsLink(String phoneNumber) async {
    Uri sms = Uri.parse("sms:$phoneNumber?body=Let's chat on Бундъварка!");
    if (await canLaunchUrl(sms)) {
      await launchUrl(sms);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not launch SMS')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading:
            _isSearching
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _toggleSearching,
                )
                : const BackButton(),
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search contacts...',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(color: Colors.white, fontSize: 18),
                  autofocus: true,
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select contact',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    ref
                        .watch(contactControllerProvider)
                        .when(
                          data: (allContacts) {
                            return Text(
                              "${allContacts[0].length} Contact${allContacts[0].length == 1 ? '' : 's'}",
                              style: const TextStyle(fontSize: 13),
                            );
                          },
                          error: (e, t) {
                            return const SizedBox();
                          },
                          loading: () {
                            return const Text(
                              'Counting',
                              style: TextStyle(fontSize: 12),
                            );
                          },
                        ),
                  ],
                ),
        actions: [
          if (!_isSearching)
            CustomIconButton(onPressed: _toggleSearching, icon: Icons.search),
          CustomIconButton(onPressed: () {}, icon: Icons.more_vert),
        ],
      ),
      body:
          _isSearching && _searchQuery.isNotEmpty
              ? ListView.builder(
                itemCount: _filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = _filteredContacts[index];
                  return ContactCard(
                    contactSource: contact,
                    onTap: () {
                      Navigator.of(
                        context,
                      ).pushNamed(Routes.chat, arguments: contact);
                    },
                  );
                },
              )
              : ref
                  .watch(contactControllerProvider)
                  .when(
                    data: (allContacts) {
                      final firebaseContacts = allContacts[0];
                      final phoneContacts = allContacts[1];

                      return ListView.builder(
                        itemCount:
                            firebaseContacts.length + phoneContacts.length,
                        itemBuilder: (context, index) {
                          if (index < firebaseContacts.length) {
                            if (index == 0) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  myListTile(
                                    leading: Icons.group,
                                    text: 'New group',
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).pushNamed(Routes.groupSettings);
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
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
                              );
                            }
                            return ContactCard(
                              contactSource: firebaseContacts[index],
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  Routes.chat,
                                  arguments: firebaseContacts[index],
                                );
                              },
                            );
                          } else {
                            if (index == firebaseContacts.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                child: Text(
                                  'Contacts on Phone',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: context.theme.greyColor,
                                  ),
                                ),
                              );
                            }
                            return ContactCard(
                              contactSource:
                                  phoneContacts[index -
                                      firebaseContacts.length],
                              onTap:
                                  () => shareSmsLink(
                                    phoneContacts[index -
                                            firebaseContacts.length]
                                        .phoneNumber,
                                  ),
                            );
                          }
                        },
                      );
                    },
                    error: (e, t) {
                      return Center(child: Text('Error: $e'));
                    },
                    loading: () {
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
    );
  }
}
