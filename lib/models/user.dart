enum Role {
  student,
  faculty,
  classIncharge,
  admin,
}

class User {
  final String id;
  final String name;
  final String username;
  final List<Role> roles;
  final bool mustChangePassword;

  // Additional mock data that will come from the backend later
  final String? profileImageUrl;
  final String? department;
  final String? section;
  final int? yearOfStudy;
  final String? courseGroup; // 'Engineering' or 'Arts & Science'

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.roles,
    this.mustChangePassword = false,
    this.profileImageUrl,
    this.department,
    this.section,
    this.yearOfStudy,
    this.courseGroup,
  });

  bool get isStudent => roles.contains(Role.student);
  bool get isFaculty => roles.contains(Role.faculty);
  bool get isIncharge => roles.contains(Role.classIncharge);
  bool get isAdmin => roles.contains(Role.admin);
  bool get isProfessor => isFaculty || isIncharge;
}
