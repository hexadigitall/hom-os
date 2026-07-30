import 'package:flutter/material.dart';
import '../models/role.dart';
import '../data/role_store.dart';

class RoleGate extends StatelessWidget {
  final Permission requiredPermission;
  final Widget child;
  final Widget? fallback;

  const RoleGate({
    super.key,
    required this.requiredPermission,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (RoleStore.has(requiredPermission)) return child;
    return fallback ?? const SizedBox.shrink();
  }
}

class RoleGateGroup extends StatelessWidget {
  final Set<Permission> anyOf;
  final Widget child;
  final Widget? fallback;

  const RoleGateGroup({
    super.key,
    required this.anyOf,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (RoleStore.hasAny(anyOf)) return child;
    return fallback ?? const SizedBox.shrink();
  }
}
