import 'package:flutter/material.dart';
import 'package:message_app/common/utils/coloors.dart';

ListTile myListTile({
    required IconData leading,
    required String text,
    IconData? trailing,
    VoidCallback? onTap, // Добавлен параметр onTap
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.only(top: 10, left: 20, right: 10),
      onTap: onTap, // Установлен обработчик нажатия
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Coloors.blueDark,
        child: Icon(leading, color: Colors.white),
      ),
      title: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing:
          trailing != null ? Icon(trailing, color: Coloors.greyDark) : null,
    );
  }