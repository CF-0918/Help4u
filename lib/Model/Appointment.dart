class Appointment {
  final String vehicle;
  final String dateTime;
  final String location;
  final String type;
  final String? mileage;
  final String? comment;

  Appointment({
    required this.vehicle,
    required this.dateTime,
    required this.location,
    required this.type,
    this.mileage,
    this.comment,
  });
}
