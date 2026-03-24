class UpdateUserInfoRequest {
  static const Object _unset = Object();

  final Object? _userName;
  final Object? _avatar;
  final Object? _gender;
  final Object? _birthday;
  final Object? _signature;
  final Object? _hometownProvinceId;
  final Object? _hometownCityId;

  const UpdateUserInfoRequest({
    Object? userName = _unset,
    Object? avatar = _unset,
    Object? gender = _unset,
    Object? birthday = _unset,
    Object? signature = _unset,
    Object? hometownProvinceId = _unset,
    Object? hometownCityId = _unset,
  }) : _userName = userName,
       _avatar = avatar,
       _gender = gender,
       _birthday = birthday,
       _signature = signature,
       _hometownProvinceId = hometownProvinceId,
       _hometownCityId = hometownCityId;

  Map<String, dynamic> toJson() {
    return {
      if (!identical(_userName, _unset)) 'userName': _userName,
      if (!identical(_avatar, _unset)) 'avatar': _avatar,
      if (!identical(_gender, _unset)) 'gender': _gender,
      if (!identical(_birthday, _unset)) 'birthday': _birthday,
      if (!identical(_signature, _unset)) 'signature': _signature,
      if (!identical(_hometownProvinceId, _unset))
        'hometownProvinceId': _hometownProvinceId,
      if (!identical(_hometownCityId, _unset))
        'hometownCityId': _hometownCityId,
    };
  }
}
