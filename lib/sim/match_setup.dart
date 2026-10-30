/// One unit's identity in a match roster.
class UnitSpec {
  const UnitSpec({required this.familyId});
  final String familyId;
}

/// A unit placed explicitly (tests and scripted setups). [familyId] null =
/// a base unit with no passive.
class UnitPlacement {
  const UnitPlacement(this.team, this.x, this.y, {this.familyId});
  final int team;
  final int x;
  final int y;
  final String? familyId;
}
