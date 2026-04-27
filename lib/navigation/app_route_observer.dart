import 'package:flutter/material.dart';

/// 与 [MaterialApp.navigatorObservers] 配合，列表页 [RouteAware.didPopNext] 在从子页面返回时将列表滚到当前曲。
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
