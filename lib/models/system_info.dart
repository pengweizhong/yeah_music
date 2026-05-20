// Copyright (c) 2025 Yeah Music
//
// This file is part of Yeah Music.
//
// Yeah Music is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Yeah Music is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.

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
