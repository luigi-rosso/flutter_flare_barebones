import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_cache.dart';
import 'package:flare_dart/math/aabb.dart';
import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_dart/math/vec2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:ui' as ui;
import 'dart:math';

void main() async {
  // Initialize Flutter's widget binding or loading assets from the bundle won't work.
  WidgetsFlutterBinding.ensureInitialized();

  // Get the Flare file.
  final asset = await cachedActor(rootBundle, "assets/Filip.flr");
  final artboard = asset.actor.artboard.makeInstance() as FlutterActorArtboard;
  artboard.initializeGraphics();

  const double width = 800;
  const double height = 600;
  final ui.PictureRecorder recorder = new ui.PictureRecorder();
  final ui.Canvas canvas =
      new ui.Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

  // advance the artboard (resolves constraints and updates transforms)
  artboard.advance(0.0);

  // Fit the artboard into the canvas. This scales and translates as necessary
  // so that the artboard is sized into the canvas with the right fit and alignment.
  fitAABB(canvas, Offset.zero, Size(width, height), artboard.artboardAABB(),
      BoxFit.contain, Alignment.center);

  // draw the artboard
  artboard.draw(canvas);

  final ui.Picture picture = recorder.endRecording();
  ui.Image image = await picture.toImage(width.floor(), height.floor());
  
  // RGBA raw byte data
  ByteData rgba = await image.toByteData();
  // png raw byte data
  ByteData data = await image.toByteData(format: ui.ImageByteFormat.png);
  // Do something with the byte data...
}

void fitAABB(Canvas canvas, Offset offset, Size size, AABB contentBounds,
    BoxFit fit, Alignment alignment) {
  double contentWidth = contentBounds[2] - contentBounds[0];
  double contentHeight = contentBounds[3] - contentBounds[1];
  double x = -1 * contentBounds[0] -
      contentWidth / 2.0 -
      (alignment.x * contentWidth / 2.0);
  double y = -1 * contentBounds[1] -
      contentHeight / 2.0 -
      (alignment.y * contentHeight / 2.0);

  double scaleX = 1.0, scaleY = 1.0;

  switch (fit) {
    case BoxFit.fill:
      scaleX = size.width / contentWidth;
      scaleY = size.height / contentHeight;
      break;
    case BoxFit.contain:
      double minScale =
          min(size.width / contentWidth, size.height / contentHeight);
      scaleX = scaleY = minScale;
      break;
    case BoxFit.cover:
      double maxScale =
          max(size.width / contentWidth, size.height / contentHeight);
      scaleX = scaleY = maxScale;
      break;
    case BoxFit.fitHeight:
      double minScale = size.height / contentHeight;
      scaleX = scaleY = minScale;
      break;
    case BoxFit.fitWidth:
      double minScale = size.width / contentWidth;
      scaleX = scaleY = minScale;
      break;
    case BoxFit.none:
      scaleX = scaleY = 1.0;
      break;
    case BoxFit.scaleDown:
      double minScale =
          min(size.width / contentWidth, size.height / contentHeight);
      scaleX = scaleY = minScale < 1.0 ? minScale : 1.0;
      break;
  }

  Mat2D transform = Mat2D();
  transform[4] =
      offset.dx + size.width / 2.0 + (alignment.x * size.width / 2.0);
  transform[5] =
      offset.dy + size.height / 2.0 + (alignment.y * size.height / 2.0);
  Mat2D.scale(transform, transform, Vec2D.fromValues(scaleX, scaleY));
  Mat2D center = Mat2D();
  center[4] = x;
  center[5] = y;
  Mat2D.multiply(transform, transform, center);

  canvas.translate(
    offset.dx + size.width / 2.0 + (alignment.x * size.width / 2.0),
    offset.dy + size.height / 2.0 + (alignment.y * size.height / 2.0),
  );

  canvas.scale(scaleX, scaleY);
  canvas.translate(x, y);
}
