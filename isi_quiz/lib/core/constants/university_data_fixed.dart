class UniversityData {
  static final Map<String, List<Faculty>> universities = {
    'University of Tunis El Manar': [
      Faculty('Faculté de Droit et des Sciences Politiques de Tunis', 'fdsp@utm.tn', 'FDSPT'),
      Faculty('Faculté de Médecine de Tunis', 'fmt@utm.tn', 'FMT'),
      Faculty('Faculté des Sciences Économiques et de Gestion de Tunis', 'fsegt@utm.tn', 'FSEGT'),
      Faculty('Faculté des Sciences de Tunis', 'fst@utm.tn', 'FST'),
      Faculty('École Nationale d\'Ingénieurs de Tunis', 'enit@utm.tn', 'ENIT'),
      Faculty('École Supérieure des Sciences et Techniques de la Santé de Tunis', 'esstst@utm.tn', 'ESSTST'),
      Faculty('Institut Supérieur d\'Informatique', 'isi@utm.tn', 'ISI'),
      Faculty('Institut Préparatoire aux Études d\'Ingénieurs d\'El Manar', 'ipeim@utm.tn', 'IPEIM'),
      Faculty('Institut Supérieur des Sciences Humaines de Tunis', 'issht@utm.tn', 'ISSHT'),
      Faculty('Institut Supérieur des Technologies Médicales de Tunis', 'istmt@utm.tn', 'ISTMT'),
      Faculty('Institut Supérieur des Sciences Biologiques Appliquées de Tunis', 'issbat@utm.tn', 'ISSBAT'),
      Faculty('Institut Supérieur des Sciences Infirmières de Tunis', 'issit@utm.tn', 'ISSIT'),
      Faculty('Institut Bourguiba des Langues Vivantes', 'iblv@utm.tn', 'IBLV'),
      Faculty('Institut Pasteur de Tunis', 'ipt@utm.tn', 'IPT'),
      Faculty('Institut de Recherche Vétérinaire de Tunis', 'irvt@utm.tn', 'IRVT'),
    ],
    'University of Sfax': [
      Faculty('Faculté de Médecine de Sfax', 'fmt@sfax.rnu.tn', 'FMS'),
      Faculty('Faculté des Sciences de Sfax', 'fs@sfax.rnu.tn', 'FS'),
      Faculty('École Nationale d\'Ingénieurs de Sfax', 'enis@sfax.rnu.tn', 'ENIS'),
      Faculty('Faculté des Sciences Économiques et de Gestion de Sfax', 'fsegs@sfax.rnu.tn', 'FSEGS'),
      Faculty('Institut Supérieur d\'Informatique et de Multimédia de Sfax', 'isims@sfax.rnu.tn', 'ISIMS'),
      Faculty('Institut Supérieur d\'Administration des Affaires de Sfax', 'iaas@sfax.rnu.tn', 'IAAS'),
    ],
    'Other University': [
      Faculty('Other Faculty', 'other@domain.tn', 'OTHER'),
    ],
  };

  static List<String> getUniversityNames() {
    return universities.keys.toList();
  }

  static List<Faculty> getFacultiesForUniversity(String universityName) {
    return universities[universityName] ?? [];
  }
}

class Faculty {
  final String name;
  final String emailDomain;
  final String abbreviation;

  Faculty(this.name, this.emailDomain, this.abbreviation);
}
