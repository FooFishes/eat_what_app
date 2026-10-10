class UpdateUserInfoRequest {
  static const Object _unset = Object();

  final Object? _userName;
  final Object? _avatar;
  final Object? _gender;
  final Object? _birthday;
  final Object? _signature;
  final Object? _hometownProvinceId;
  final Object? _hometownCityId;

  const new({
    this._userName = _unset,
    this._avatar = _unset,
    this._gender = _unset,
    this._birthday = _unset,
    this._signature = _unset,
    this._hometownProvinceId = _unset,
    this._hometownCityId = _unset,
  });

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
