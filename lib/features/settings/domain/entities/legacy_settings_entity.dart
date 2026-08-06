class LegacySettingsEntity {
  final bool isEnabled;
  final String? legacyContactId;
  final String? legacyContactName;
  final String inactivityPeriod; // '3_months', '6_months', '1_year'
  final String? note;

  const LegacySettingsEntity({
    this.isEnabled = false,
    this.legacyContactId,
    this.legacyContactName,
    this.inactivityPeriod = '6_months',
    this.note,
  });
}
