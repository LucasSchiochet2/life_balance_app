class User {
  final int id;
  final String name;
  final String email;
  final double salary;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.salary,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      salary: double.tryParse(json['salary'].toString()) ?? 0.0,
    );
  }
}
