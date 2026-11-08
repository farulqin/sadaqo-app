enum Gender {
  male('male', 'Laki-laki'),
  female('female', 'Perempuan');

  const Gender(this.key, this.label);

  final String key;
  final String label;

  static Gender? fromKey(String? key) {
    for (final g in Gender.values) {
      if (g.key == key) return g;
    }
    return null;
  }
}