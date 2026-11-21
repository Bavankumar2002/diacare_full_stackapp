// =============================================================================
// DiaCare - Patient Profile Data Model
// =============================================================================

class ProfileModel {
  final int? id;
  final int userId;
  final String fullName;
  final int age;
  final String? dob;
  final String gender;
  final double heightCm;
  final double weightKg;
  final double bmi;
  final String diabetesType;
  final int? yearDiagnosed;
  final String currentMedicines;
  final String allergies;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String doctorName;
  final String doctorHospital;
  final int dailyCalorieGoal;
  final String? profilePhoto;
  final bool isCompleted;

  ProfileModel({
    this.id,
    required this.userId,
    required this.fullName,
    required this.age,
    this.dob,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.bmi,
    required this.diabetesType,
    this.yearDiagnosed,
    required this.currentMedicines,
    required this.allergies,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.doctorName,
    required this.doctorHospital,
    this.dailyCalorieGoal = 1800,
    this.profilePhoto,
    this.isCompleted = true,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      fullName: json['full_name']?.toString() ?? '',
      age: int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      dob: json['dob']?.toString(),
      gender: json['gender']?.toString() ?? 'Male',
      heightCm: double.tryParse(json['height_cm']?.toString() ?? '0') ?? 0.0,
      weightKg: double.tryParse(json['weight_kg']?.toString() ?? '0') ?? 0.0,
      bmi: double.tryParse(json['bmi']?.toString() ?? '0') ?? 0.0,
      diabetesType: json['diabetes_type']?.toString() ?? 'Type 2',
      yearDiagnosed: json['year_diagnosed'] != null
          ? int.tryParse(json['year_diagnosed'].toString())
          : null,
      currentMedicines: json['current_medicines']?.toString() ?? '',
      allergies: json['allergies']?.toString() ?? '',
      emergencyContactName: json['emergency_contact_name']?.toString() ?? '',
      emergencyContactPhone: json['emergency_contact_phone']?.toString() ?? '',
      doctorName: json['doctor_name']?.toString() ?? '',
      doctorHospital: json['doctor_hospital']?.toString() ?? '',
      dailyCalorieGoal:
          int.tryParse(json['daily_calorie_goal']?.toString() ?? '1800') ?? 1800,
      profilePhoto: json['profile_photo']?.toString(),
      isCompleted: json['is_completed'] == 1 || json['is_completed'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'age': age,
      'dob': dob,
      'gender': gender,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'bmi': bmi,
      'diabetes_type': diabetesType,
      'year_diagnosed': yearDiagnosed,
      'current_medicines': currentMedicines,
      'allergies': allergies,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'doctor_name': doctorName,
      'doctor_hospital': doctorHospital,
      'daily_calorie_goal': dailyCalorieGoal,
      'profile_photo': profilePhoto,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  String get bmiCategory {
    if (bmi < 18.5) return 'Underweight';
    if (bmi <= 24.9) return 'Normal Weight';
    if (bmi <= 29.9) return 'Overweight';
    return 'Obese';
  }
}
