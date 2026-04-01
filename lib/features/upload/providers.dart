import 'package:eat_what_app/core/network/network_providers.dart';
import 'package:eat_what_app/core/network/request_client.dart';
import 'package:eat_what_app/features/upload/data/data_sources/restaurant_search_hint_data_source.dart';
import 'package:eat_what_app/features/upload/data/repositories/image_upload_repository.dart';
import 'package:eat_what_app/features/upload/data/repositories/upload_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
RequestClient uploadRawClient(Ref ref) {
  return RequestClient.raw();
}

@Riverpod(keepAlive: true)
RestaurantSearchHintDataSource restaurantSearchHintDataSource(Ref ref) {
  return const RestaurantSearchHintDataSource();
}

@Riverpod(keepAlive: true)
UploadRepository uploadRepository(Ref ref) {
  return UploadRepository(
    api: ref.read(apiProvider),
    rawApi: ref.read(uploadRawClientProvider),
  );
}

@Riverpod(keepAlive: true)
ImageUploadRepository imageUploadRepository(Ref ref) {
  return ImageUploadRepository(
    api: ref.read(apiProvider),
    rawApi: ref.read(uploadRawClientProvider),
  );
}
