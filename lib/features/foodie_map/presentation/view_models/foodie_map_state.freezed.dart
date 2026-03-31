// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'foodie_map_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FoodieMapFeedback {

 int get id; FoodieMapFeedbackKind get kind; String get content;
/// Create a copy of FoodieMapFeedback
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FoodieMapFeedbackCopyWith<FoodieMapFeedback> get copyWith => _$FoodieMapFeedbackCopyWithImpl<FoodieMapFeedback>(this as FoodieMapFeedback, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FoodieMapFeedback&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.content, content) || other.content == content));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind,content);

@override
String toString() {
  return 'FoodieMapFeedback(id: $id, kind: $kind, content: $content)';
}


}

/// @nodoc
abstract mixin class $FoodieMapFeedbackCopyWith<$Res>  {
  factory $FoodieMapFeedbackCopyWith(FoodieMapFeedback value, $Res Function(FoodieMapFeedback) _then) = _$FoodieMapFeedbackCopyWithImpl;
@useResult
$Res call({
 int id, FoodieMapFeedbackKind kind, String content
});




}
/// @nodoc
class _$FoodieMapFeedbackCopyWithImpl<$Res>
    implements $FoodieMapFeedbackCopyWith<$Res> {
  _$FoodieMapFeedbackCopyWithImpl(this._self, this._then);

  final FoodieMapFeedback _self;
  final $Res Function(FoodieMapFeedback) _then;

/// Create a copy of FoodieMapFeedback
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? content = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as FoodieMapFeedbackKind,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FoodieMapFeedback].
extension FoodieMapFeedbackPatterns on FoodieMapFeedback {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FoodieMapFeedback value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FoodieMapFeedback() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FoodieMapFeedback value)  $default,){
final _that = this;
switch (_that) {
case _FoodieMapFeedback():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FoodieMapFeedback value)?  $default,){
final _that = this;
switch (_that) {
case _FoodieMapFeedback() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  FoodieMapFeedbackKind kind,  String content)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FoodieMapFeedback() when $default != null:
return $default(_that.id,_that.kind,_that.content);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  FoodieMapFeedbackKind kind,  String content)  $default,) {final _that = this;
switch (_that) {
case _FoodieMapFeedback():
return $default(_that.id,_that.kind,_that.content);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  FoodieMapFeedbackKind kind,  String content)?  $default,) {final _that = this;
switch (_that) {
case _FoodieMapFeedback() when $default != null:
return $default(_that.id,_that.kind,_that.content);case _:
  return null;

}
}

}

/// @nodoc


class _FoodieMapFeedback implements FoodieMapFeedback {
  const _FoodieMapFeedback({required this.id, required this.kind, required this.content});
  

@override final  int id;
@override final  FoodieMapFeedbackKind kind;
@override final  String content;

/// Create a copy of FoodieMapFeedback
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FoodieMapFeedbackCopyWith<_FoodieMapFeedback> get copyWith => __$FoodieMapFeedbackCopyWithImpl<_FoodieMapFeedback>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FoodieMapFeedback&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.content, content) || other.content == content));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind,content);

@override
String toString() {
  return 'FoodieMapFeedback(id: $id, kind: $kind, content: $content)';
}


}

/// @nodoc
abstract mixin class _$FoodieMapFeedbackCopyWith<$Res> implements $FoodieMapFeedbackCopyWith<$Res> {
  factory _$FoodieMapFeedbackCopyWith(_FoodieMapFeedback value, $Res Function(_FoodieMapFeedback) _then) = __$FoodieMapFeedbackCopyWithImpl;
@override @useResult
$Res call({
 int id, FoodieMapFeedbackKind kind, String content
});




}
/// @nodoc
class __$FoodieMapFeedbackCopyWithImpl<$Res>
    implements _$FoodieMapFeedbackCopyWith<$Res> {
  __$FoodieMapFeedbackCopyWithImpl(this._self, this._then);

  final _FoodieMapFeedback _self;
  final $Res Function(_FoodieMapFeedback) _then;

/// Create a copy of FoodieMapFeedback
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? content = null,}) {
  return _then(_FoodieMapFeedback(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as FoodieMapFeedbackKind,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$FoodieMapPageState {

 bool get isInitialLoading; bool get isLoadingProvinces; bool get hasProvincesError; int? get localProvinceId; List<ProvinceResponse> get provinces; int? get selectedProvinceId; int? get committedProvinceId; FoodieMapFeedback? get feedback;
/// Create a copy of FoodieMapPageState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FoodieMapPageStateCopyWith<FoodieMapPageState> get copyWith => _$FoodieMapPageStateCopyWithImpl<FoodieMapPageState>(this as FoodieMapPageState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FoodieMapPageState&&(identical(other.isInitialLoading, isInitialLoading) || other.isInitialLoading == isInitialLoading)&&(identical(other.isLoadingProvinces, isLoadingProvinces) || other.isLoadingProvinces == isLoadingProvinces)&&(identical(other.hasProvincesError, hasProvincesError) || other.hasProvincesError == hasProvincesError)&&(identical(other.localProvinceId, localProvinceId) || other.localProvinceId == localProvinceId)&&const DeepCollectionEquality().equals(other.provinces, provinces)&&(identical(other.selectedProvinceId, selectedProvinceId) || other.selectedProvinceId == selectedProvinceId)&&(identical(other.committedProvinceId, committedProvinceId) || other.committedProvinceId == committedProvinceId)&&(identical(other.feedback, feedback) || other.feedback == feedback));
}


@override
int get hashCode => Object.hash(runtimeType,isInitialLoading,isLoadingProvinces,hasProvincesError,localProvinceId,const DeepCollectionEquality().hash(provinces),selectedProvinceId,committedProvinceId,feedback);

@override
String toString() {
  return 'FoodieMapPageState(isInitialLoading: $isInitialLoading, isLoadingProvinces: $isLoadingProvinces, hasProvincesError: $hasProvincesError, localProvinceId: $localProvinceId, provinces: $provinces, selectedProvinceId: $selectedProvinceId, committedProvinceId: $committedProvinceId, feedback: $feedback)';
}


}

/// @nodoc
abstract mixin class $FoodieMapPageStateCopyWith<$Res>  {
  factory $FoodieMapPageStateCopyWith(FoodieMapPageState value, $Res Function(FoodieMapPageState) _then) = _$FoodieMapPageStateCopyWithImpl;
@useResult
$Res call({
 bool isInitialLoading, bool isLoadingProvinces, bool hasProvincesError, int? localProvinceId, List<ProvinceResponse> provinces, int? selectedProvinceId, int? committedProvinceId, FoodieMapFeedback? feedback
});


$FoodieMapFeedbackCopyWith<$Res>? get feedback;

}
/// @nodoc
class _$FoodieMapPageStateCopyWithImpl<$Res>
    implements $FoodieMapPageStateCopyWith<$Res> {
  _$FoodieMapPageStateCopyWithImpl(this._self, this._then);

  final FoodieMapPageState _self;
  final $Res Function(FoodieMapPageState) _then;

/// Create a copy of FoodieMapPageState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isInitialLoading = null,Object? isLoadingProvinces = null,Object? hasProvincesError = null,Object? localProvinceId = freezed,Object? provinces = null,Object? selectedProvinceId = freezed,Object? committedProvinceId = freezed,Object? feedback = freezed,}) {
  return _then(_self.copyWith(
isInitialLoading: null == isInitialLoading ? _self.isInitialLoading : isInitialLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingProvinces: null == isLoadingProvinces ? _self.isLoadingProvinces : isLoadingProvinces // ignore: cast_nullable_to_non_nullable
as bool,hasProvincesError: null == hasProvincesError ? _self.hasProvincesError : hasProvincesError // ignore: cast_nullable_to_non_nullable
as bool,localProvinceId: freezed == localProvinceId ? _self.localProvinceId : localProvinceId // ignore: cast_nullable_to_non_nullable
as int?,provinces: null == provinces ? _self.provinces : provinces // ignore: cast_nullable_to_non_nullable
as List<ProvinceResponse>,selectedProvinceId: freezed == selectedProvinceId ? _self.selectedProvinceId : selectedProvinceId // ignore: cast_nullable_to_non_nullable
as int?,committedProvinceId: freezed == committedProvinceId ? _self.committedProvinceId : committedProvinceId // ignore: cast_nullable_to_non_nullable
as int?,feedback: freezed == feedback ? _self.feedback : feedback // ignore: cast_nullable_to_non_nullable
as FoodieMapFeedback?,
  ));
}
/// Create a copy of FoodieMapPageState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FoodieMapFeedbackCopyWith<$Res>? get feedback {
    if (_self.feedback == null) {
    return null;
  }

  return $FoodieMapFeedbackCopyWith<$Res>(_self.feedback!, (value) {
    return _then(_self.copyWith(feedback: value));
  });
}
}


/// Adds pattern-matching-related methods to [FoodieMapPageState].
extension FoodieMapPageStatePatterns on FoodieMapPageState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FoodieMapPageState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FoodieMapPageState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FoodieMapPageState value)  $default,){
final _that = this;
switch (_that) {
case _FoodieMapPageState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FoodieMapPageState value)?  $default,){
final _that = this;
switch (_that) {
case _FoodieMapPageState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isInitialLoading,  bool isLoadingProvinces,  bool hasProvincesError,  int? localProvinceId,  List<ProvinceResponse> provinces,  int? selectedProvinceId,  int? committedProvinceId,  FoodieMapFeedback? feedback)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FoodieMapPageState() when $default != null:
return $default(_that.isInitialLoading,_that.isLoadingProvinces,_that.hasProvincesError,_that.localProvinceId,_that.provinces,_that.selectedProvinceId,_that.committedProvinceId,_that.feedback);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isInitialLoading,  bool isLoadingProvinces,  bool hasProvincesError,  int? localProvinceId,  List<ProvinceResponse> provinces,  int? selectedProvinceId,  int? committedProvinceId,  FoodieMapFeedback? feedback)  $default,) {final _that = this;
switch (_that) {
case _FoodieMapPageState():
return $default(_that.isInitialLoading,_that.isLoadingProvinces,_that.hasProvincesError,_that.localProvinceId,_that.provinces,_that.selectedProvinceId,_that.committedProvinceId,_that.feedback);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isInitialLoading,  bool isLoadingProvinces,  bool hasProvincesError,  int? localProvinceId,  List<ProvinceResponse> provinces,  int? selectedProvinceId,  int? committedProvinceId,  FoodieMapFeedback? feedback)?  $default,) {final _that = this;
switch (_that) {
case _FoodieMapPageState() when $default != null:
return $default(_that.isInitialLoading,_that.isLoadingProvinces,_that.hasProvincesError,_that.localProvinceId,_that.provinces,_that.selectedProvinceId,_that.committedProvinceId,_that.feedback);case _:
  return null;

}
}

}

/// @nodoc


class _FoodieMapPageState implements FoodieMapPageState {
  const _FoodieMapPageState({this.isInitialLoading = true, this.isLoadingProvinces = false, this.hasProvincesError = false, this.localProvinceId, final  List<ProvinceResponse> provinces = const [], this.selectedProvinceId, this.committedProvinceId, this.feedback}): _provinces = provinces;
  

@override@JsonKey() final  bool isInitialLoading;
@override@JsonKey() final  bool isLoadingProvinces;
@override@JsonKey() final  bool hasProvincesError;
@override final  int? localProvinceId;
 final  List<ProvinceResponse> _provinces;
@override@JsonKey() List<ProvinceResponse> get provinces {
  if (_provinces is EqualUnmodifiableListView) return _provinces;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_provinces);
}

@override final  int? selectedProvinceId;
@override final  int? committedProvinceId;
@override final  FoodieMapFeedback? feedback;

/// Create a copy of FoodieMapPageState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FoodieMapPageStateCopyWith<_FoodieMapPageState> get copyWith => __$FoodieMapPageStateCopyWithImpl<_FoodieMapPageState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FoodieMapPageState&&(identical(other.isInitialLoading, isInitialLoading) || other.isInitialLoading == isInitialLoading)&&(identical(other.isLoadingProvinces, isLoadingProvinces) || other.isLoadingProvinces == isLoadingProvinces)&&(identical(other.hasProvincesError, hasProvincesError) || other.hasProvincesError == hasProvincesError)&&(identical(other.localProvinceId, localProvinceId) || other.localProvinceId == localProvinceId)&&const DeepCollectionEquality().equals(other._provinces, _provinces)&&(identical(other.selectedProvinceId, selectedProvinceId) || other.selectedProvinceId == selectedProvinceId)&&(identical(other.committedProvinceId, committedProvinceId) || other.committedProvinceId == committedProvinceId)&&(identical(other.feedback, feedback) || other.feedback == feedback));
}


@override
int get hashCode => Object.hash(runtimeType,isInitialLoading,isLoadingProvinces,hasProvincesError,localProvinceId,const DeepCollectionEquality().hash(_provinces),selectedProvinceId,committedProvinceId,feedback);

@override
String toString() {
  return 'FoodieMapPageState(isInitialLoading: $isInitialLoading, isLoadingProvinces: $isLoadingProvinces, hasProvincesError: $hasProvincesError, localProvinceId: $localProvinceId, provinces: $provinces, selectedProvinceId: $selectedProvinceId, committedProvinceId: $committedProvinceId, feedback: $feedback)';
}


}

/// @nodoc
abstract mixin class _$FoodieMapPageStateCopyWith<$Res> implements $FoodieMapPageStateCopyWith<$Res> {
  factory _$FoodieMapPageStateCopyWith(_FoodieMapPageState value, $Res Function(_FoodieMapPageState) _then) = __$FoodieMapPageStateCopyWithImpl;
@override @useResult
$Res call({
 bool isInitialLoading, bool isLoadingProvinces, bool hasProvincesError, int? localProvinceId, List<ProvinceResponse> provinces, int? selectedProvinceId, int? committedProvinceId, FoodieMapFeedback? feedback
});


@override $FoodieMapFeedbackCopyWith<$Res>? get feedback;

}
/// @nodoc
class __$FoodieMapPageStateCopyWithImpl<$Res>
    implements _$FoodieMapPageStateCopyWith<$Res> {
  __$FoodieMapPageStateCopyWithImpl(this._self, this._then);

  final _FoodieMapPageState _self;
  final $Res Function(_FoodieMapPageState) _then;

/// Create a copy of FoodieMapPageState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isInitialLoading = null,Object? isLoadingProvinces = null,Object? hasProvincesError = null,Object? localProvinceId = freezed,Object? provinces = null,Object? selectedProvinceId = freezed,Object? committedProvinceId = freezed,Object? feedback = freezed,}) {
  return _then(_FoodieMapPageState(
isInitialLoading: null == isInitialLoading ? _self.isInitialLoading : isInitialLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingProvinces: null == isLoadingProvinces ? _self.isLoadingProvinces : isLoadingProvinces // ignore: cast_nullable_to_non_nullable
as bool,hasProvincesError: null == hasProvincesError ? _self.hasProvincesError : hasProvincesError // ignore: cast_nullable_to_non_nullable
as bool,localProvinceId: freezed == localProvinceId ? _self.localProvinceId : localProvinceId // ignore: cast_nullable_to_non_nullable
as int?,provinces: null == provinces ? _self._provinces : provinces // ignore: cast_nullable_to_non_nullable
as List<ProvinceResponse>,selectedProvinceId: freezed == selectedProvinceId ? _self.selectedProvinceId : selectedProvinceId // ignore: cast_nullable_to_non_nullable
as int?,committedProvinceId: freezed == committedProvinceId ? _self.committedProvinceId : committedProvinceId // ignore: cast_nullable_to_non_nullable
as int?,feedback: freezed == feedback ? _self.feedback : feedback // ignore: cast_nullable_to_non_nullable
as FoodieMapFeedback?,
  ));
}

/// Create a copy of FoodieMapPageState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FoodieMapFeedbackCopyWith<$Res>? get feedback {
    if (_self.feedback == null) {
    return null;
  }

  return $FoodieMapFeedbackCopyWith<$Res>(_self.feedback!, (value) {
    return _then(_self.copyWith(feedback: value));
  });
}
}

/// @nodoc
mixin _$FoodieMapFoodListState {

 List<RegionalFood> get foods; bool get isLoading; bool get hasError; bool get hasNext; int get currentPage; Set<int> get pendingLikeIds; FoodieMapFeedback? get feedback;
/// Create a copy of FoodieMapFoodListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FoodieMapFoodListStateCopyWith<FoodieMapFoodListState> get copyWith => _$FoodieMapFoodListStateCopyWithImpl<FoodieMapFoodListState>(this as FoodieMapFoodListState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FoodieMapFoodListState&&const DeepCollectionEquality().equals(other.foods, foods)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.hasError, hasError) || other.hasError == hasError)&&(identical(other.hasNext, hasNext) || other.hasNext == hasNext)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&const DeepCollectionEquality().equals(other.pendingLikeIds, pendingLikeIds)&&(identical(other.feedback, feedback) || other.feedback == feedback));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(foods),isLoading,hasError,hasNext,currentPage,const DeepCollectionEquality().hash(pendingLikeIds),feedback);

@override
String toString() {
  return 'FoodieMapFoodListState(foods: $foods, isLoading: $isLoading, hasError: $hasError, hasNext: $hasNext, currentPage: $currentPage, pendingLikeIds: $pendingLikeIds, feedback: $feedback)';
}


}

/// @nodoc
abstract mixin class $FoodieMapFoodListStateCopyWith<$Res>  {
  factory $FoodieMapFoodListStateCopyWith(FoodieMapFoodListState value, $Res Function(FoodieMapFoodListState) _then) = _$FoodieMapFoodListStateCopyWithImpl;
@useResult
$Res call({
 List<RegionalFood> foods, bool isLoading, bool hasError, bool hasNext, int currentPage, Set<int> pendingLikeIds, FoodieMapFeedback? feedback
});


$FoodieMapFeedbackCopyWith<$Res>? get feedback;

}
/// @nodoc
class _$FoodieMapFoodListStateCopyWithImpl<$Res>
    implements $FoodieMapFoodListStateCopyWith<$Res> {
  _$FoodieMapFoodListStateCopyWithImpl(this._self, this._then);

  final FoodieMapFoodListState _self;
  final $Res Function(FoodieMapFoodListState) _then;

/// Create a copy of FoodieMapFoodListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? foods = null,Object? isLoading = null,Object? hasError = null,Object? hasNext = null,Object? currentPage = null,Object? pendingLikeIds = null,Object? feedback = freezed,}) {
  return _then(_self.copyWith(
foods: null == foods ? _self.foods : foods // ignore: cast_nullable_to_non_nullable
as List<RegionalFood>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,hasError: null == hasError ? _self.hasError : hasError // ignore: cast_nullable_to_non_nullable
as bool,hasNext: null == hasNext ? _self.hasNext : hasNext // ignore: cast_nullable_to_non_nullable
as bool,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,pendingLikeIds: null == pendingLikeIds ? _self.pendingLikeIds : pendingLikeIds // ignore: cast_nullable_to_non_nullable
as Set<int>,feedback: freezed == feedback ? _self.feedback : feedback // ignore: cast_nullable_to_non_nullable
as FoodieMapFeedback?,
  ));
}
/// Create a copy of FoodieMapFoodListState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FoodieMapFeedbackCopyWith<$Res>? get feedback {
    if (_self.feedback == null) {
    return null;
  }

  return $FoodieMapFeedbackCopyWith<$Res>(_self.feedback!, (value) {
    return _then(_self.copyWith(feedback: value));
  });
}
}


/// Adds pattern-matching-related methods to [FoodieMapFoodListState].
extension FoodieMapFoodListStatePatterns on FoodieMapFoodListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FoodieMapFoodListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FoodieMapFoodListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FoodieMapFoodListState value)  $default,){
final _that = this;
switch (_that) {
case _FoodieMapFoodListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FoodieMapFoodListState value)?  $default,){
final _that = this;
switch (_that) {
case _FoodieMapFoodListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<RegionalFood> foods,  bool isLoading,  bool hasError,  bool hasNext,  int currentPage,  Set<int> pendingLikeIds,  FoodieMapFeedback? feedback)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FoodieMapFoodListState() when $default != null:
return $default(_that.foods,_that.isLoading,_that.hasError,_that.hasNext,_that.currentPage,_that.pendingLikeIds,_that.feedback);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<RegionalFood> foods,  bool isLoading,  bool hasError,  bool hasNext,  int currentPage,  Set<int> pendingLikeIds,  FoodieMapFeedback? feedback)  $default,) {final _that = this;
switch (_that) {
case _FoodieMapFoodListState():
return $default(_that.foods,_that.isLoading,_that.hasError,_that.hasNext,_that.currentPage,_that.pendingLikeIds,_that.feedback);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<RegionalFood> foods,  bool isLoading,  bool hasError,  bool hasNext,  int currentPage,  Set<int> pendingLikeIds,  FoodieMapFeedback? feedback)?  $default,) {final _that = this;
switch (_that) {
case _FoodieMapFoodListState() when $default != null:
return $default(_that.foods,_that.isLoading,_that.hasError,_that.hasNext,_that.currentPage,_that.pendingLikeIds,_that.feedback);case _:
  return null;

}
}

}

/// @nodoc


class _FoodieMapFoodListState implements FoodieMapFoodListState {
  const _FoodieMapFoodListState({final  List<RegionalFood> foods = const [], this.isLoading = true, this.hasError = false, this.hasNext = true, this.currentPage = 0, final  Set<int> pendingLikeIds = const {}, this.feedback}): _foods = foods,_pendingLikeIds = pendingLikeIds;
  

 final  List<RegionalFood> _foods;
@override@JsonKey() List<RegionalFood> get foods {
  if (_foods is EqualUnmodifiableListView) return _foods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_foods);
}

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool hasError;
@override@JsonKey() final  bool hasNext;
@override@JsonKey() final  int currentPage;
 final  Set<int> _pendingLikeIds;
@override@JsonKey() Set<int> get pendingLikeIds {
  if (_pendingLikeIds is EqualUnmodifiableSetView) return _pendingLikeIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_pendingLikeIds);
}

@override final  FoodieMapFeedback? feedback;

/// Create a copy of FoodieMapFoodListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FoodieMapFoodListStateCopyWith<_FoodieMapFoodListState> get copyWith => __$FoodieMapFoodListStateCopyWithImpl<_FoodieMapFoodListState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FoodieMapFoodListState&&const DeepCollectionEquality().equals(other._foods, _foods)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.hasError, hasError) || other.hasError == hasError)&&(identical(other.hasNext, hasNext) || other.hasNext == hasNext)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&const DeepCollectionEquality().equals(other._pendingLikeIds, _pendingLikeIds)&&(identical(other.feedback, feedback) || other.feedback == feedback));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_foods),isLoading,hasError,hasNext,currentPage,const DeepCollectionEquality().hash(_pendingLikeIds),feedback);

@override
String toString() {
  return 'FoodieMapFoodListState(foods: $foods, isLoading: $isLoading, hasError: $hasError, hasNext: $hasNext, currentPage: $currentPage, pendingLikeIds: $pendingLikeIds, feedback: $feedback)';
}


}

/// @nodoc
abstract mixin class _$FoodieMapFoodListStateCopyWith<$Res> implements $FoodieMapFoodListStateCopyWith<$Res> {
  factory _$FoodieMapFoodListStateCopyWith(_FoodieMapFoodListState value, $Res Function(_FoodieMapFoodListState) _then) = __$FoodieMapFoodListStateCopyWithImpl;
@override @useResult
$Res call({
 List<RegionalFood> foods, bool isLoading, bool hasError, bool hasNext, int currentPage, Set<int> pendingLikeIds, FoodieMapFeedback? feedback
});


@override $FoodieMapFeedbackCopyWith<$Res>? get feedback;

}
/// @nodoc
class __$FoodieMapFoodListStateCopyWithImpl<$Res>
    implements _$FoodieMapFoodListStateCopyWith<$Res> {
  __$FoodieMapFoodListStateCopyWithImpl(this._self, this._then);

  final _FoodieMapFoodListState _self;
  final $Res Function(_FoodieMapFoodListState) _then;

/// Create a copy of FoodieMapFoodListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? foods = null,Object? isLoading = null,Object? hasError = null,Object? hasNext = null,Object? currentPage = null,Object? pendingLikeIds = null,Object? feedback = freezed,}) {
  return _then(_FoodieMapFoodListState(
foods: null == foods ? _self._foods : foods // ignore: cast_nullable_to_non_nullable
as List<RegionalFood>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,hasError: null == hasError ? _self.hasError : hasError // ignore: cast_nullable_to_non_nullable
as bool,hasNext: null == hasNext ? _self.hasNext : hasNext // ignore: cast_nullable_to_non_nullable
as bool,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,pendingLikeIds: null == pendingLikeIds ? _self._pendingLikeIds : pendingLikeIds // ignore: cast_nullable_to_non_nullable
as Set<int>,feedback: freezed == feedback ? _self.feedback : feedback // ignore: cast_nullable_to_non_nullable
as FoodieMapFeedback?,
  ));
}

/// Create a copy of FoodieMapFoodListState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FoodieMapFeedbackCopyWith<$Res>? get feedback {
    if (_self.feedback == null) {
    return null;
  }

  return $FoodieMapFeedbackCopyWith<$Res>(_self.feedback!, (value) {
    return _then(_self.copyWith(feedback: value));
  });
}
}

// dart format on
