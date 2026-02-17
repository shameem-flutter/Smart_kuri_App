class CashCollectorModel {
  final String username;
  final String email;
  final String phone;
  final String password;
  final int group;

  CashCollectorModel({
    required this.username,
    required this.email,
    required this.phone,
    required this.password,
    required this.group,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'phone': phone,
      'password': password,
      'group': group,
    };
  }
}
