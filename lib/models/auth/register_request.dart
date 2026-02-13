class RegisterRequest {
  final String groupName;
  final String phone;
  final String email;
  final String password;
  final String confirmPassword;
  final int planId;

  RegisterRequest({
    required this.groupName,
    required this.phone,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.planId,
  });

  Map<String, dynamic> toJson() {
    return {
      'group_name': groupName,
      'phone': phone,
      'email': email,
      'password1': password,
      'password2': confirmPassword,
      'plan_id': planId,
    };
  }
}
