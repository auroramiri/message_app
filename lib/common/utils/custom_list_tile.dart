import 'package:flutter/material.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';

class CustomListTile extends StatefulWidget {
  const CustomListTile({
    super.key,
    required this.title,
    required this.leading,
    this.subTitle,
    this.onTimeSelected,
    this.onTap,
  });

  final String title;
  final IconData leading;
  final String? subTitle;
  final Function(String)? onTimeSelected;
  final VoidCallback? onTap;

  @override
  State<CustomListTile> createState() => _CustomListTileState();
}

class _CustomListTileState extends State<CustomListTile> {
  String _selectedTime = 'Off';

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(25, 5, 10, 5),
      title: Text(widget.title),
      onTap: widget.onTap,
      subtitle:
          widget.subTitle != null
              ? Text(
                widget.subTitle!,
                style: TextStyle(color: context.theme.greyColor),
              )
              : null,
      leading: Icon(widget.leading),
      trailing: DropdownButton<String>(
        value: _selectedTime,
        items:
            <String>['Off', '1 hour', '1 day', '1 week'].map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedTime = newValue!;
          });
          if (widget.onTimeSelected != null) {
            widget.onTimeSelected!(_selectedTime);
          }
        },
      ),
    );
  }
}
