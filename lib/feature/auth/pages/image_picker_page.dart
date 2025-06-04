import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';
import 'package:message_app/common/widgets/custom_icon_button.dart';
import 'package:photo_manager/photo_manager.dart';

class ImagePickerPage extends StatefulWidget {
  const ImagePickerPage({super.key});

  @override
  State<ImagePickerPage> createState() => _ImagePickerPageState();
}

class _ImagePickerPageState extends State<ImagePickerPage> {
  List<Widget> imageList = [];
  int currentPage = 0;
  int? lastPage;

  handleScrollEvent(ScrollNotification scroll) {
    if (scroll.metrics.pixels / scroll.metrics.maxScrollExtent <= 0.33) return;
    if (currentPage == lastPage) return;
    fetchAllImages();
  }

  fetchAllImages() async {
    lastPage = currentPage;
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) return PhotoManager.openSetting();

    List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    if (albums.isEmpty) {
      // Handle case where no albums are found
      log('No image albums found.');
      return;
    }

    List<AssetEntity> photos = await albums[0].getAssetListPaged(
      page: currentPage,
      size: 24,
    );

    List<Widget> temp = [];

    for (var asset in photos) {
      temp.add(
        FutureBuilder(
          future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data != null) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: InkWell(
                  // ИЗМЕНЕНИЕ ЗДЕСЬ: Получаем файл и возвращаем его
                  onTap: () async {
                    final file =
                        await asset.file; // Получаем объект File из AssetEntity
                    if (file != null) {
                      Navigator.pop(context, file); // Возвращаем объект File
                    } else {
                      // Обработка случая, если файл не получен
                      log('Error: Could not get file for asset.');
                      // Возможно, показать сообщение пользователю
                    }
                  },
                  borderRadius: BorderRadius.circular(5),
                  splashFactory: NoSplash.splashFactory,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.theme.greyColor!.withValues(alpha: 0.4),
                        width: 1,
                      ),
                      image: DecorationImage(
                        image: MemoryImage(snapshot.data as Uint8List),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              );
            }
            // Возвращаем пустой контейнер или индикатор загрузки, пока данные не готовы
            return Container();
          },
        ),
      );
    }
    setState(() {
      imageList.addAll(temp);
      currentPage++;
    });
  }

  @override
  void initState() {
    fetchAllImages();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        // elevation: 0,
        leading: CustomIconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icons.arrow_back,
        ),
        title: Text(
          'Бундъварка', // Замените на актуальный текст
          style: TextStyle(color: context.theme.authAppbarTextColor),
        ),
        actions: [CustomIconButton(onPressed: () {}, icon: Icons.more_vert)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(5),
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scroll) {
            handleScrollEvent(scroll);
            return true;
          },
          child: GridView.builder(
            itemCount: imageList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              // Добавил const
              crossAxisCount: 3,
            ),
            itemBuilder: (_, index) {
              return imageList[index];
            },
          ),
        ),
      ),
    );
  }
}
