// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'activity_upload_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ActivityUploadFeedback {

 int get id; ActivityUploadFeedbackKind get kind; String get content;
/// Create a copy of ActivityUploadFeedback
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityUploadFeedbackCopyWith<ActivityUploadFeedback> get copyWith => _$ActivityUploadFeedbackCopyWithImpl<ActivityUploadFeedback>(this as ActivityUploadFeedback, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ActivityUploadFeedback;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivityUploadFeedback&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.content, _this.content) || other.content == _this.content));
}


@override
int get hashCode {
  final _this = this as ActivityUploadFeedback;
  return Object.hash(runtimeType,_this.id,_this.kind,_this.content);
}

@override
String toString() {
  final _this = this as ActivityUploadFeedback;
  return 'ActivityUploadFeedback(id: ${_this.id}, kind: ${_this.kind}, content: ${_this.content})';
}


}

/// @nodoc
abstract mixin class $ActivityUploadFeedbackCopyWith<$Res>  {
  factory $ActivityUploadFeedbackCopyWith(ActivityUploadFeedback value, $Res Function(ActivityUploadFeedback) _then) = _$ActivityUploadFeedbackCopyWithImpl;
@useResult
$Res call({
 int id, ActivityUploadFeedbackKind kind, String content
});




}
/// @nodoc
class _$ActivityUploadFeedbackCopyWithImpl<$Res>
    implements $ActivityUploadFeedbackCopyWith<$Res> {
  _$ActivityUploadFeedbackCopyWithImpl(this._self, this._then);

  final ActivityUploadFeedback _self;
  final $Res Function(ActivityUploadFeedback) _then;

/// Create a copy of ActivityUploadFeedback
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? content = null,}) {
  return _then(ActivityUploadFeedback(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ActivityUploadFeedbackKind,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ActivityUploadFeedback].
extension ActivityUploadFeedbackPatterns on ActivityUploadFeedback {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivityUploadFeedback value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivityUploadFeedback() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivityUploadFeedback value)  $default,){
final _that = this;
switch (_that) {
case _ActivityUploadFeedback():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivityUploadFeedback value)?  $default,){
final _that = this;
switch (_that) {
case _ActivityUploadFeedback() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  ActivityUploadFeedbackKind kind,  String content)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivityUploadFeedback() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  ActivityUploadFeedbackKind kind,  String content)  $default,) {final _that = this;
switch (_that) {
case _ActivityUploadFeedback():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  ActivityUploadFeedbackKind kind,  String content)?  $default,) {final _that = this;
switch (_that) {
case _ActivityUploadFeedback() when $default != null:
return $default(_that.id,_that.kind,_that.content);case _:
  return null;

}
}

}

/// @nodoc


class _ActivityUploadFeedback implements ActivityUploadFeedback {
  const _ActivityUploadFeedback({required this.id, required this.kind, required this.content});
  

@override final  int id;
@override final  ActivityUploadFeedbackKind kind;
@override final  String content;

/// Create a copy of ActivityUploadFeedback
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivityUploadFeedbackCopyWith<_ActivityUploadFeedback> get copyWith => __$ActivityUploadFeedbackCopyWithImpl<_ActivityUploadFeedback>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivityUploadFeedback&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.content, content) || other.content == content));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,kind,content);
}

@override
String toString() {
    return 'ActivityUploadFeedback(id: $id, kind: $kind, content: $content)';
}


}

/// @nodoc
abstract mixin class _$ActivityUploadFeedbackCopyWith<$Res> implements $ActivityUploadFeedbackCopyWith<$Res> {
  factory _$ActivityUploadFeedbackCopyWith(_ActivityUploadFeedback value, $Res Function(_ActivityUploadFeedback) _then) = __$ActivityUploadFeedbackCopyWithImpl;
@override @useResult
$Res call({
 int id, ActivityUploadFeedbackKind kind, String content
});




}
/// @nodoc
class __$ActivityUploadFeedbackCopyWithImpl<$Res>
    implements _$ActivityUploadFeedbackCopyWith<$Res> {
  __$ActivityUploadFeedbackCopyWithImpl(this._self, this._then);

  final _ActivityUploadFeedback _self;
  final $Res Function(_ActivityUploadFeedback) _then;

/// Create a copy of ActivityUploadFeedback
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? content = null,}) {
  return _then(_ActivityUploadFeedback(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ActivityUploadFeedbackKind,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ActivityUploadState {

 bool get isLoadingProvinces; bool get isLoadingCities; bool get isSubmitting; List<ProvinceResponse> get provinces; List<CityResponse> get cities; ProvinceResponse? get selectedProvince; CityResponse? get selectedCity; ActivityUploadFeedback? get feedback;
/// Create a copy of ActivityUploadState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityUploadStateCopyWith<ActivityUploadState> get copyWith => _$ActivityUploadStateCopyWithImpl<ActivityUploadState>(this as ActivityUploadState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ActivityUploadState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivityUploadState&&(identical(other.isLoadingProvinces, _this.isLoadingProvinces) || other.isLoadingProvinces == _this.isLoadingProvinces)&&(identical(other.isLoadingCities, _this.isLoadingCities) || other.isLoadingCities == _this.isLoadingCities)&&(identical(other.isSubmitting, _this.isSubmitting) || other.isSubmitting == _this.isSubmitting)&&const DeepCollectionEquality().equals(other.provinces, _this.provinces)&&const DeepCollectionEquality().equals(other.cities, _this.cities)&&(identical(other.selectedProvince, _this.selectedProvince) || other.selectedProvince == _this.selectedProvince)&&(identical(other.selectedCity, _this.selectedCity) || other.selectedCity == _this.selectedCity)&&(identical(other.feedback, _this.feedback) || other.feedback == _this.feedback));
}


@override
int get hashCode {
  final _this = this as ActivityUploadState;
  return Object.hash(runtimeType,_this.isLoadingProvinces,_this.isLoadingCities,_this.isSubmitting,const DeepCollectionEquality().hash(_this.provinces),const DeepCollectionEquality().hash(_this.cities),_this.selectedProvince,_this.selectedCity,_this.feedback);
}

@override
String toString() {
  final _this = this as ActivityUploadState;
  return 'ActivityUploadState(isLoadingProvinces: ${_this.isLoadingProvinces}, isLoadingCities: ${_this.isLoadingCities}, isSubmitting: ${_this.isSubmitting}, provinces: ${_this.provinces}, cities: ${_this.cities}, selectedProvince: ${_this.selectedProvince}, selectedCity: ${_this.selectedCity}, feedback: ${_this.feedback})';
}


}

/// @nodoc
abstract mixin class $ActivityUploadStateCopyWith<$Res>  {
  factory $ActivityUploadStateCopyWith(ActivityUploadState value, $Res Function(ActivityUploadState) _then) = _$ActivityUploadStateCopyWithImpl;
@useResult
$Res call({
 bool isLoadingProvinces, bool isLoadingCities, bool isSubmitting, List<ProvinceResponse> provinces, List<CityResponse> cities, ProvinceResponse? selectedProvince, CityResponse? selectedCity, ActivityUploadFeedback? feedback
});


$ActivityUploadFeedbackCopyWith<$Res>? get feedback;

}
/// @nodoc
class _$ActivityUploadStateCopyWithImpl<$Res>
    implements $ActivityUploadStateCopyWith<$Res> {
  _$ActivityUploadStateCopyWithImpl(this._self, this._then);

  final ActivityUploadState _self;
  final $Res Function(ActivityUploadState) _then;

/// Create a copy of ActivityUploadState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoadingProvinces = null,Object? isLoadingCities = null,Object? isSubmitting = null,Object? provinces = null,Object? cities = null,Object? selectedProvince = freezed,Object? selectedCity = freezed,Object? feedback = freezed,}) {
  return _then(ActivityUploadState(
isLoadingProvinces: null == isLoadingProvinces ? _self.isLoadingProvinces : isLoadingProvinces // ignore: cast_nullable_to_non_nullable
as bool,isLoadingCities: null == isLoadingCities ? _self.isLoadingCities : isLoadingCities // ignore: cast_nullable_to_non_nullable
as bool,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,provinces: null == provinces ? _self.provinces : provinces // ignore: cast_nullable_to_non_nullable
as List<ProvinceResponse>,cities: null == cities ? _self.cities : cities // ignore: cast_nullable_to_non_nullable
as List<CityResponse>,selectedProvince: freezed == selectedProvince ? _self.selectedProvince : selectedProvince // ignore: cast_nullable_to_non_nullable
as ProvinceResponse?,selectedCity: freezed == selectedCity ? _self.selectedCity : selectedCity // ignore: cast_nullable_to_non_nullable
as CityResponse?,feedback: freezed == feedback ? _self.feedback : feedback // ignore: cast_nullable_to_non_nullable
as ActivityUploadFeedback?,
  ));
}
/// Create a copy of ActivityUploadState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActivityUploadFeedbackCopyWith<$Res>? get feedback {
    if (_self.feedback == null) {
    return null;
  }

  return $ActivityUploadFeedbackCopyWith<$Res>(_self.feedback!, (value) {
    return _then(_self.copyWith(feedback: value));
  });
}
}


/// Adds pattern-matching-related methods to [ActivityUploadState].
extension ActivityUploadStatePatterns on ActivityUploadState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivityUploadState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivityUploadState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivityUploadState value)  $default,){
final _that = this;
switch (_that) {
case _ActivityUploadState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivityUploadState value)?  $default,){
final _that = this;
switch (_that) {
case _ActivityUploadState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoadingProvinces,  bool isLoadingCities,  bool isSubmitting,  List<ProvinceResponse> provinces,  List<CityResponse> cities,  ProvinceResponse? selectedProvince,  CityResponse? selectedCity,  ActivityUploadFeedback? feedback)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivityUploadState() when $default != null:
return $default(_that.isLoadingProvinces,_that.isLoadingCities,_that.isSubmitting,_that.provinces,_that.cities,_that.selectedProvince,_that.selectedCity,_that.feedback);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoadingProvinces,  bool isLoadingCities,  bool isSubmitting,  List<ProvinceResponse> provinces,  List<CityResponse> cities,  ProvinceResponse? selectedProvince,  CityResponse? selectedCity,  ActivityUploadFeedback? feedback)  $default,) {final _that = this;
switch (_that) {
case _ActivityUploadState():
return $default(_that.isLoadingProvinces,_that.isLoadingCities,_that.isSubmitting,_that.provinces,_that.cities,_that.selectedProvince,_that.selectedCity,_that.feedback);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoadingProvinces,  bool isLoadingCities,  bool isSubmitting,  List<ProvinceResponse> provinces,  List<CityResponse> cities,  ProvinceResponse? selectedProvince,  CityResponse? selectedCity,  ActivityUploadFeedback? feedback)?  $default,) {final _that = this;
switch (_that) {
case _ActivityUploadState() when $default != null:
return $default(_that.isLoadingProvinces,_that.isLoadingCities,_that.isSubmitting,_that.provinces,_that.cities,_that.selectedProvince,_that.selectedCity,_that.feedback);case _:
  return null;

}
}

}

/// @nodoc


class _ActivityUploadState implements ActivityUploadState {
  const _ActivityUploadState({this.isLoadingProvinces = false, this.isLoadingCities = false, this.isSubmitting = false,  List<ProvinceResponse> provinces = const [],  List<CityResponse> cities = const [], this.selectedProvince, this.selectedCity, this.feedback}): _provinces = provinces,_cities = cities;
  

@override@JsonKey() final  bool isLoadingProvinces;
@override@JsonKey() final  bool isLoadingCities;
@override@JsonKey() final  bool isSubmitting;
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

@override final  ProvinceResponse? selectedProvince;
@override final  CityResponse? selectedCity;
@override final  ActivityUploadFeedback? feedback;

/// Create a copy of ActivityUploadState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivityUploadStateCopyWith<_ActivityUploadState> get copyWith => __$ActivityUploadStateCopyWithImpl<_ActivityUploadState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivityUploadState&&(identical(other.isLoadingProvinces, isLoadingProvinces) || other.isLoadingProvinces == isLoadingProvinces)&&(identical(other.isLoadingCities, isLoadingCities) || other.isLoadingCities == isLoadingCities)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&const DeepCollectionEquality().equals(other.provinces, _provinces)&&const DeepCollectionEquality().equals(other.cities, _cities)&&(identical(other.selectedProvince, selectedProvince) || other.selectedProvince == selectedProvince)&&(identical(other.selectedCity, selectedCity) || other.selectedCity == selectedCity)&&(identical(other.feedback, feedback) || other.feedback == feedback));
}


@override
int get hashCode {
    return Object.hash(runtimeType,isLoadingProvinces,isLoadingCities,isSubmitting,const DeepCollectionEquality().hash(_provinces),const DeepCollectionEquality().hash(_cities),selectedProvince,selectedCity,feedback);
}

@override
String toString() {
    return 'ActivityUploadState(isLoadingProvinces: $isLoadingProvinces, isLoadingCities: $isLoadingCities, isSubmitting: $isSubmitting, provinces: $provinces, cities: $cities, selectedProvince: $selectedProvince, selectedCity: $selectedCity, feedback: $feedback)';
}


}

/// @nodoc
abstract mixin class _$ActivityUploadStateCopyWith<$Res> implements $ActivityUploadStateCopyWith<$Res> {
  factory _$ActivityUploadStateCopyWith(_ActivityUploadState value, $Res Function(_ActivityUploadState) _then) = __$ActivityUploadStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoadingProvinces, bool isLoadingCities, bool isSubmitting, List<ProvinceResponse> provinces, List<CityResponse> cities, ProvinceResponse? selectedProvince, CityResponse? selectedCity, ActivityUploadFeedback? feedback
});


@override $ActivityUploadFeedbackCopyWith<$Res>? get feedback;

}
/// @nodoc
class __$ActivityUploadStateCopyWithImpl<$Res>
    implements _$ActivityUploadStateCopyWith<$Res> {
  __$ActivityUploadStateCopyWithImpl(this._self, this._then);

  final _ActivityUploadState _self;
  final $Res Function(_ActivityUploadState) _then;

/// Create a copy of ActivityUploadState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoadingProvinces = null,Object? isLoadingCities = null,Object? isSubmitting = null,Object? provinces = null,Object? cities = null,Object? selectedProvince = freezed,Object? selectedCity = freezed,Object? feedback = freezed,}) {
  return _then(_ActivityUploadState(
isLoadingProvinces: null == isLoadingProvinces ? _self.isLoadingProvinces : isLoadingProvinces // ignore: cast_nullable_to_non_nullable
as bool,isLoadingCities: null == isLoadingCities ? _self.isLoadingCities : isLoadingCities // ignore: cast_nullable_to_non_nullable
as bool,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,provinces: null == provinces ? _self._provinces : provinces // ignore: cast_nullable_to_non_nullable
as List<ProvinceResponse>,cities: null == cities ? _self._cities : cities // ignore: cast_nullable_to_non_nullable
as List<CityResponse>,selectedProvince: freezed == selectedProvince ? _self.selectedProvince : selectedProvince // ignore: cast_nullable_to_non_nullable
as ProvinceResponse?,selectedCity: freezed == selectedCity ? _self.selectedCity : selectedCity // ignore: cast_nullable_to_non_nullable
as CityResponse?,feedback: freezed == feedback ? _self.feedback : feedback // ignore: cast_nullable_to_non_nullable
as ActivityUploadFeedback?,
  ));
}

/// Create a copy of ActivityUploadState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActivityUploadFeedbackCopyWith<$Res>? get feedback {
    if (_self.feedback == null) {
    return null;
  }

  return $ActivityUploadFeedbackCopyWith<$Res>(_self.feedback!, (value) {
    return _then(_self.copyWith(feedback: value));
  });
}
}

// dart format on
