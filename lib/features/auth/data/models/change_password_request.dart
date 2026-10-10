class ChangePasswordRequest({
  required final String oldPassword,
  required final String newPassword,
}) {
  Map<String, dynamic> toJson() {
    return {'oldPassword': oldPassword, 'newPassword': newPassword};
  }
}
