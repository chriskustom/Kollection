import 'package:flutter/material.dart';
import 'package:kollection/app/utils/constants.dart';

class SortOption {
  final SortBy sortBy;
  final SortOrder order;
  final String label;
  final IconData icon;

  const SortOption(this.sortBy, this.order, this.label, this.icon);
}

class GroupOption {
  final GroupBy groupBy;
  final String label;
  final IconData icon;

  const GroupOption(this.groupBy, this.label, this.icon);
}
