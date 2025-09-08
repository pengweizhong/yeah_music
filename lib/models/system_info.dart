class SystemInfo {
  //KB
  double? _total;
  //KB
  double? _free;
  //KB
  double? _used;
  String? _platformName;

  double? get total => _total;

  set total(double? value) => _total = value;

  double? get free => _free;

  set free(double? value) => _free = value;

  double? get used => _used;

  set used(double? value) => _used = value;

  String? get platformName => _platformName;

  set platformName(String? value) => _platformName = value;

  @override
  String toString() {
    return 'SystemInfo{_total: $_total, _free: $_free, _used: $_used, _platformName: $_platformName}';
  }
}
