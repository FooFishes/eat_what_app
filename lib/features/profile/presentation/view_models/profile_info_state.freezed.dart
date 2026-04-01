// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_info_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProfileInfoState {

 bool get isLoading; bool get isLoadingLocations; bool get isUploadingAvatar; UserInfoResponse? get userInfo; List<ProvinceResponse> get provinces; List<CityResponse> get cities; Object? get error;
/// Create a copy of ProfileInfoState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileInfoStateCopyWith<ProfileInfoState> get copyWith => _$ProfileInfoStateCopyWithImpl<ProfileInfoState>(this as ProfileInfoState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileInfoState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingLocations, isLoadingLocations) || other.isLoadingLocations == isLoadingLocations)&&(identical(other.isUploadingAvatar, isUploadingAvatar) || other.isUploadingAvatar == isUploadingAvatar)&&(identical(other.userInfo, userInfo) || other.userInfo == userInfo)&&const DeepCollectionEquality().equals(other.provinces, provinces)&&const DeepCollectionEquality().equals(other.cities, cities)&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isLoadingLocations,isUploadingAvatar,userInfo,const DeepCollectionEquality().hash(provinces),const DeepCollectionEquality().hash(cities),const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'ProfileInfoState(isLoading: $isLoading, isLoadingLocations: $isLoadingLocations, isUploadingAvatar: $isUploadingAvatar, userInfo: $userInfo, provinces: $provinces, cities: $cities, error: $error)';
}


}

/// @nodoc
abstract mixin class $ProfileInfoStateCopyWith<$Res>  {
  factory $ProfileInfoStateCopyWith(ProfileInfoState value, $Res Function(ProfileInfoState) _then) = _$ProfileInfoStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isLoadingLocations, bool isUploadingAvatar, UserInfoResponse? userInfo, List<ProvinceResponse> provinces, List<CityResponse> cities, Object? error
});




}
/// @nodoc
class _$ProfileInfoStateCopyWithImpl<$Res>
    implements $ProfileInfoStateCopyWith<$Res> {
  _$ProfileInfoStateCopyWithImpl(this._self, this._then);

  final ProfileInfoState _self;
  final $Res Function(ProfileInfoState) _then;

/// Create a copy of ProfileInfoState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? isLoadingLocations = null,Object? isUploadingAvatar = null,Object? userInfo = freezed,Object? provinces = null,Object? cities = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingLocations: null == isLoadingLocations ? _self.isLoadingLocations : isLoadingLocations // ignore: cast_nullable_to_non_nullable
as bool,isUploadingAvatar: null == isUploadingAvatar ? _self.isUploadingAvatar : isUploadingAvatar // ignore: cast_nullable_to_non_nullable
as bool,userInfo: freezed == userInfo ? _self.userInfo : userInfo // ignore: cast_nullable_to_non_nullable
as UserInfoResponse?,provinces: null == provinces ? _self.provinces : provinces // ignore: cast_nullable_to_non_nullable
as List<ProvinceResponse>,cities: null == cities ? _self.cities : cities // ignore: cast_nullable_to_non_nullable
as List<CityResponse>,error: freezed == error ? _self.error : error ,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileInfoState].
extension ProfileInfoStatePatterns on ProfileInfoState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileInfoState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileInfoState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileInfoState value)  $default,){
final _that = this;
switch (_that) {
case _ProfileInfoState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileInfoState value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileInfoState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool isLoadingLocations,  bool isUploadingAvatar,  UserInfoResponse? userInfo,  List<ProvinceResponse> provinces,  List<CityResponse> cities,  Object? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileInfoState() when $default != null:
return $default(_that.isLoading,_that.isLoadingLocations,_that.isUploadingAvatar,_that.userInfo,_that.provinces,_that.cities,_that.error);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool isLoadingLocations,  bool isUploadingAvatar,  UserInfoResponse? userInfo,  List<ProvinceResponse> provinces,  List<CityResponse> cities,  Object? error)  $default,) {final _that = this;
switch (_that) {
case _ProfileInfoState():
return $default(_that.isLoading,_that.isLoadingLocations,_that.isUploadingAvatar,_that.userInfo,_that.provinces,_that.cities,_that.error);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool isLoadingLocations,  bool isUploadingAvatar,  UserInfoResponse? userInfo,  List<ProvinceResponse> provinces,  List<CityResponse> cities,  Object? error)?  $default,) {final _that = this;
switch (_that) {
case _ProfileInfoState() when $default != null:
return $default(_that.isLoading,_that.isLoadingLocations,_that.isUploadingAvatar,_that.userInfo,_that.provinces,_that.cities,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _ProfileInfoState implements ProfileInfoState {
  const _ProfileInfoState({this.isLoading = true, this.isLoadingLocations = false, this.isUploadingAvatar = false, this.userInfo, final  List<ProvinceResponse> provinces = const [], final  List<CityResponse> cities = const [], this.error}): _provinces = provinces,_cities = cities;
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isLoadingLocations;
@override@JsonKey() final  bool isUploadingAvatar;
@override final  UserInfoResponse? userInfo;
 final  List<ProvinceResponse> _provinces;
@override@JsonKey() List<ProvinceResponse> get provinces {
  if (_provinces is EqualUnmodifiableListView) return _provinces;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_provinces);
}

 final  List<CityResponse> _cities;
@override@JsonKey() List<CityResponse> get cities {
  if (_cities is EqualUnmodifiableListView) return _cities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cities);
}

@override final  Object? error;

/// Create a copy of ProfileInfoState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileInfoStateCopyWith<_ProfileInfoState> get copyWith => __$ProfileInfoStateCopyWithImpl<_ProfileInfoState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileInfoState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingLocations, isLoadingLocations) || other.isLoadingLocations == isLoadingLocations)&&(identical(other.isUploadingAvatar, isUploadingAvatar) || other.isUploadingAvatar == isUploadingAvatar)&&(identical(other.userInfo, userInfo) || other.userInfo == userInfo)&&const DeepCollectionEquality().equals(other._provinces, _provinces)&&const DeepCollectionEquality().equals(other._cities, _cities)&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isLoadingLocations,isUploadingAvatar,userInfo,const DeepCollectionEquality().hash(_provinces),const DeepCollectionEquality().hash(_cities),const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'ProfileInfoState(isLoading: $isLoading, isLoadingLocations: $isLoadingLocations, isUploadingAvatar: $isUploadingAvatar, userInfo: $userInfo, provinces: $provinces, cities: $cities, error: $error)';
}


}

/// @nodoc
abstract mixin class _$ProfileInfoStateCopyWith<$Res> implements $ProfileInfoStateCopyWith<$Res> {
  factory _$ProfileInfoStateCopyWith(_ProfileInfoState value, $Res Function(_ProfileInfoState) _then) = __$ProfileInfoStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isLoadingLocations, bool isUploadingAvatar, UserInfoResponse? userInfo, List<ProvinceResponse> provinces, List<CityResponse> cities, Object? error
});




}
/// @nodoc
class __$ProfileInfoStateCopyWithImpl<$Res>
    implements _$ProfileInfoStateCopyWith<$Res> {
  __$ProfileInfoStateCopyWithImpl(this._self, this._then);

  final _ProfileInfoState _self;
  final $Res Function(_ProfileInfoState) _then;

/// Create a copy of ProfileInfoState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isLoadingLocations = null,Object? isUploadingAvatar = null,Object? userInfo = freezed,Object? provinces = null,Object? cities = null,Object? error = freezed,}) {
  return _then(_ProfileInfoState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingLocations: null == isLoadingLocations ? _self.isLoadingLocations : isLoadingLocations // ignore: cast_nullable_to_non_nullable
as bool,isUploadingAvatar: null == isUploadingAvatar ? _self.isUploadingAvatar : isUploadingAvatar // ignore: cast_nullable_to_non_nullable
as bool,userInfo: freezed == userInfo ? _self.userInfo : userInfo // ignore: cast_nullable_to_non_nullable
as UserInfoResponse?,provinces: null == provinces ? _self._provinces : provinces // ignore: cast_nullable_to_non_nullable
as List<ProvinceResponse>,cities: null == cities ? _self._cities : cities // ignore: cast_nullable_to_non_nullable
as List<CityResponse>,error: freezed == error ? _self.error : error ,
  ));
}


}

// dart format on
