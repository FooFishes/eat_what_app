import 'package:eat/core/platform/photo_picker.dart';
import 'package:eat/design/tokens/stage_color.dart';
import 'package:eat/domain/models/dish.dart';
import 'package:eat/domain/models/taste.dart';
import 'package:eat/features/publish/publish_providers.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  const original = Dish(
    id: 1,
    name: '鲜虾云吞',
    shopId: 7,
    price: 18,
    category: DishCategory.staple,
    stage: StageColor.broth,
    tags: [Taste.spicy, Taste.sweet],
    description: '汤很鲜',
  );

  const unchanged = PublishDraft(
    category: DishCategory.staple,
    tastes: {Taste.sweet, Taste.spicy},
  );

  DishChange? change(
    PublishDraft draft, {
    String name = '鲜虾云吞',
    double? price,
    String description = '汤很鲜',
  }) => draft.changeFrom(
    original,
    name: name,
    price: price,
    description: description,
  );

  test('内容和原菜一样时没有改动，口味顺序不同不算改动', () {
    expect(change(unchanged), isNull);
    expect(change(unchanged, price: 18), isNull);
  });

  test('只带改了的字段；说明清空传空串，口味清空传空列表', () {
    final result = change(
      unchanged.copy(tastes: const {}, signature: true),
      price: 20,
      description: '',
    )!;
    expect(result.name, isNull);
    expect(result.category, isNull);
    expect(result.price, 20);
    expect(result.description, '');
    expect(result.tags, isEmpty);
    expect(result.signature, isTrue);
    expect(result.imageKeys, isNull);
    expect(result.stage, isNull);
    expect(result.crop, isNull);
  });

  test('换了照片时带上整组新照片和新封面的舞台色、备选色、取景', () {
    final photo = DraftPhoto(
      id: 0,
      photo: PickedPhoto(bytes: transparentImage, width: 1, height: 1),
      image: MemoryImage(transparentImage),
      status: UploadStatus.done,
      progress: 1,
      key: 'foods/a.jpg',
    );
    final result = change(
      unchanged.copy(photos: [photo], pickedStage: StageColor.chili),
    )!;
    expect(result.imageKeys, ['foods/a.jpg']);
    expect(result.stage, StageColor.chili);
    expect(result.stageAlternates, hasLength(2));
    expect(result.crop, isNotNull);
    expect(result.tags, isNull);
  });
}
