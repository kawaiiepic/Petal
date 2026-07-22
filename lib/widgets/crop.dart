import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';

class AvatarCropDialog extends StatefulWidget {
  final File image;

  const AvatarCropDialog({super.key, required this.image});

  @override
  State<AvatarCropDialog> createState() => _AvatarCropDialogState();
}

class _AvatarCropDialogState extends State<AvatarCropDialog> {
  final CropController controller = CropController();

  Uint8List? croppedImage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crop Profile Picture'),
      content: SizedBox(
        width: 500,
        height: 500,
        child: Crop(
          image: widget.image.readAsBytesSync(),
          controller: controller,
          aspectRatio: 1,
          withCircleUi: true,
          onCropped: (result) {
            switch (result) {
              case CropSuccess(:final croppedImage):
                print(croppedImage);
              // do something with cropped image data
              case CropFailure(:final cause):
              // do something with error
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),

        FilledButton(
          onPressed: () {
            controller.crop();
          },
          child: const Text('Crop'),
        ),
      ],
    );
  }
}
