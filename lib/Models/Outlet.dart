class Outlet {
  final String outletID;
  final String outletName;
  final String? outletAddress;
  final String? outletPhoneNo;
  final String? operationDay;
  final String outletStatus;
  final double latitude;
  final double longitude;
  final DateTime? createdAt;

  const Outlet({
    required this.outletID,
    required this.outletName,
    this.outletAddress,
    this.outletPhoneNo,
    this.operationDay,
    this.outletStatus = 'active',
    required this.latitude,
    required this.longitude,
    this.createdAt,
  });

  Map<String, dynamic> toInsertMap() => {
    // write using the actual column names you created in DB
    'outletname': outletName,
    'outletaddress': outletAddress,
    'outletphoneno': outletPhoneNo,
    'operationday': operationDay,
    'outletstatus': outletStatus,
    'latitude': latitude,
    'longitude': longitude,
  };

  Map<String, dynamic> toUpdateMap() => toInsertMap();

  factory Outlet.fromMap(Map<String, dynamic> d) {
    T? pick<T>(List<String> keys) {
      for (final k in keys) {
        if (d[k] != null) return d[k] as T;
      }
      return null;
    }

    final id = pick<String>(['outletid', 'outletID', 'id']) ?? '';
    final name = pick<String>(['outletname', 'outletName']) ?? '';
    final status =
        pick<String>(['outletstatus', 'outlet_status', 'outletStatus']) ??
            'active';

    final latNum = pick<num>(['latitude']);
    final lngNum = pick<num>(['longitude']);

    return Outlet(
      outletID: id,
      outletName: name,
      outletAddress: pick<String>(['outletaddress', 'outletAddress']),
      outletPhoneNo: pick<String>(['outletphoneno', 'outletPhoneNo']),
      operationDay: pick<String>(['operationday', 'operationDay']),
      outletStatus: status,
      latitude: (latNum ?? 0).toDouble(),
      longitude: (lngNum ?? 0).toDouble(),
      createdAt: pick<String>(['created_at']) != null
          ? DateTime.parse(pick<String>(['created_at'])!)
          : null,
    );
  }
}
