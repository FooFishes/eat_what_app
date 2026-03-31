// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_overview_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProfileOverviewState {

 bool get isLoading; UserInfoResponse? get userInfo; UserProfileStatsResponse? get stats; Object? get error;
/// Create a copy of ProfileOverviewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileOverviewStateCopyWith<ProfileOverviewState> get copyWith => _$ProfileOverviewStateCopyWithImpl<ProfileOverviewState>(this as ProfileOverviewState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileOverviewState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.userInfo, userInfo) || other.userInfo == userInfo)&&(identical(other.stats, stats) || other.stats == stats)&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,userInfo,stats,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'ProfileOverviewState(isLoading: $isLoading, userInfo: $userInfo, stats: $stats, error: $error)';
}


}

/// @nodoc
abstract mixin class $ProfileOverviewStateCopyWith<$Res>  {
  factory $ProfileOverviewStateCopyWith(ProfileOverviewState value, $Res Function(ProfileOverviewState) _then) = _$ProfileOverviewStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, UserInfoResponse? userInfo, UserProfileStatsResponse? stats, Object? error
});




}
/// @nodoc
class _$ProfileOverviewStateCopyWithImpl<$Res>
    implements $ProfileOverviewStateCopyWith<$Res> {
  _$ProfileOverviewStateCopyWithImpl(this._self, this._then);

  final ProfileOverviewState _self;
  final $Res Function(ProfileOverviewState) _then;

/// Create a copy of ProfileOverviewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? userInfo = freezed,Object? stats = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,userInfo: freezed == userInfo ? _self.userInfo : userInfo // ignore: cast_nullable_to_non_nullable
as UserInfoResponse?,stats: freezed == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as UserProfileStatsResponse?,error: freezed == error ? _self.error : error ,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileOverviewState].
extension ProfileOverviewStatePatterns on ProfileOverviewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileOverviewState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileOverviewState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileOverviewState value)  $default,){
final _that = this;
switch (_that) {
case _ProfileOverviewState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileOverviewState value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileOverviewState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  UserInfoResponse? userInfo,  UserProfileStatsResponse? stats,  Object? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileOverviewState() when $default != null:
return $default(_that.isLoading,_that.userInfo,_that.stats,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  UserInfoResponse? userInfo,  UserProfileStatsResponse? stats,  Object? error)  $default,) {final _that = this;
switch (_that) {
case _ProfileOverviewState():
return $default(_that.isLoading,_that.userInfo,_that.stats,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  UserInfoResponse? userInfo,  UserProfileStatsResponse? stats,  Object? error)?  $default,) {final _that = this;
switch (_that) {
case _ProfileOverviewState() when $default != null:
return $default(_that.isLoading,_that.userInfo,_that.stats,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _ProfileOverviewState implements ProfileOverviewState {
  const _ProfileOverviewState({this.isLoading = true, this.userInfo, this.stats, this.error});
  

@override@JsonKey() final  bool isLoading;
@override final  UserInfoResponse? userInfo;
@override final  UserProfileStatsResponse? stats;
@override final  Object? error;

/// Create a copy of ProfileOverviewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileOverviewStateCopyWith<_ProfileOverviewState> get copyWith => __$ProfileOverviewStateCopyWithImpl<_ProfileOverviewState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileOverviewState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.userInfo, userInfo) || other.userInfo == userInfo)&&(identical(other.stats, stats) || other.stats == stats)&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,userInfo,stats,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'ProfileOverviewState(isLoading: $isLoading, userInfo: $userInfo, stats: $stats, error: $error)';
}


}

/// @nodoc
abstract mixin class _$ProfileOverviewStateCopyWith<$Res> implements $ProfileOverviewStateCopyWith<$Res> {
  factory _$ProfileOverviewStateCopyWith(_ProfileOverviewState value, $Res Function(_ProfileOverviewState) _then) = __$ProfileOverviewStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, UserInfoResponse? userInfo, UserProfileStatsResponse? stats, Object? error
});




}
/// @nodoc
class __$ProfileOverviewStateCopyWithImpl<$Res>
    implements _$ProfileOverviewStateCopyWith<$Res> {
  __$ProfileOverviewStateCopyWithImpl(this._self, this._then);

  final _ProfileOverviewState _self;
  final $Res Function(_ProfileOverviewState) _then;

/// Create a copy of ProfileOverviewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? userInfo = freezed,Object? stats = freezed,Object? error = freezed,}) {
  return _then(_ProfileOverviewState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,userInfo: freezed == userInfo ? _self.userInfo : userInfo // ignore: cast_nullable_to_non_nullable
as UserInfoResponse?,stats: freezed == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as UserProfileStatsResponse?,error: freezed == error ? _self.error : error ,
  ));
}


}

// dart format on
