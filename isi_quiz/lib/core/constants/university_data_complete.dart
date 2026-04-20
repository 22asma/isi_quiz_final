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
    'University of Carthage': [
      Faculty('École Polytechnique de Tunisie', 'ept@u-carthage.rnu.tn', 'EPT'),
      Faculty('École Supérieure des Sciences Économiques et Commerciales de Tunis', 'essect@u-carthage.rnu.tn', 'ESSECT'),
      Faculty('École Supérieure de la Statistique et de l\'Analyse de l\'Information', 'essai@u-carthage.rnu.tn', 'ESSAI'),
      Faculty('Institut des Hautes Études Commerciales de Carthage', 'ihec@u-carthage.rnu.tn', 'IHEC'),
      Faculty('Institut National des Sciences et Technologies de la Mer', 'instm@u-carthage.rnu.tn', 'INSTM'),
    ],
    'University of Monastir': [
      Faculty('Faculté de Médecine de Monastir', 'fmm@monastir.rnu.tn', 'FMM'),
      Faculty('Faculté de Pharmacie de Monastir', 'fpm@monastir.rnu.tn', 'FPM'),
      Faculty('École Nationale d\'Ingénieurs de Monastir', 'enim@monastir.rnu.tn', 'ENIM'),
      Faculty('Faculté des Sciences de Monastir', 'fsm@monastir.rnu.tn', 'FSM'),
      Faculty('Institut Supérieur d\'Informatique de Mahdia', 'isi@mahdia.rnu.tn', 'ISI'),
    ],
    'University of Manouba': [
      Faculty('École Supérieure de l\'Économie Numérique', 'esen@manouba.rnu.tn', 'ESEN'),
      Faculty('Institut Supérieur de Comptabilité et d\'Administration des Entreprises', 'iscae@manouba.rnu.tn', 'ISCAE'),
      Faculty('Institut Supérieur de Documentation', 'isd@manouba.rnu.tn', 'ISD'),
      Faculty('Institut Supérieur du Tourisme, des Arts et de l\'Artisanat', 'istaa@manouba.rnu.tn', 'ISTAA'),
      Faculty('Institut Supérieur de la Musique', 'ism@manouba.rnu.tn', 'ISM'),
    ],
    'University of Sousse': [
      Faculty('Faculté de Médecine de Sousse', 'fms@sousse.rnu.tn', 'FMS'),
      Faculty('École Nationale d\'Ingénieurs de Sousse', 'enis@sousse.rnu.tn', 'ENIS'),
      Faculty('Faculté des Sciences de Sousse', 'fs@sousse.rnu.tn', 'FS'),
      Faculty('Institut Supérieur d\'Informatique et de Technologies de Communication de Hammam Sousse', 'isitcom@sousse.rnu.tn', 'ISITCOM'),
    ],
    'Ez-Zitouna University': [
      Faculty('Faculté de Droit et de Sciences Politiques', 'fdsp@ez-zitouna.rnu.tn', 'FDSP'),
      Faculty('Faculté de la Charia et de la Civilisation Islamique', 'fsci@ez-zitouna.rnu.tn', 'FSCI'),
      Faculty('Faculté des Lettres, des Arts et des Humanités', 'flah@ez-zitouna.rnu.tn', 'FLAH'),
    ],
    'University of Gabès': [
      Faculty('Faculté des Sciences de Gabès', 'fs@gabes.rnu.tn', 'FS'),
      Faculty('École Nationale d\'Ingénieurs de Gabès', 'enig@gabes.rnu.tn', 'ENIG'),
      Faculty('Faculté des Sciences Juridiques, Économiques et de Gestion de Gabès', 'fsjeg@gabes.rnu.tn', 'FSJEG'),
      Faculty('Institut Supérieur des Sciences Appliquées et de Technologie de Gabès', 'issat@gabes.rnu.tn', 'ISSAT'),
    ],
    'University of Gafsa': [
      Faculty('Faculté des Sciences de Gafsa', 'fs@gafsa.rnu.tn', 'FS'),
      Faculty('École Nationale d\'Ingénieurs de Gafsa', 'enig@gafsa.rnu.tn', 'ENIG'),
      Faculty('Faculté des Sciences Juridiques, Économiques et de Gestion de Gafsa', 'fsjeg@gafsa.rnu.tn', 'FSJEG'),
    ],
    'University of Jendouba': [
      Faculty('Faculté des Sciences Juridiques, Économiques et de Gestion de Jendouba', 'fsjeg@jendouba.rnu.tn', 'FSJEG'),
      Faculty('Faculté des Sciences de Jendouba', 'fs@jendouba.rnu.tn', 'FS'),
      Faculty('École Supérieure d\'Agriculture de Mateur', 'esam@jendouba.rnu.tn', 'ESAM'),
      Faculty('Institut Supérieur des Langues Appliquées et d\'Informatique de Béja', 'islaib@jendouba.rnu.tn', 'ISLAIB'),
    ],
    'University of Kairouan': [
      Faculty('Faculté des Sciences Juridiques, Économiques et de Gestion de Kairouan', 'fsjeg@kairouan.rnu.tn', 'FSJEG'),
      Faculty('Faculté des Lettres et des Sciences Humaines de Kairouan', 'flsh@kairouan.rnu.tn', 'FLSH'),
      Faculty('Institut Supérieur des Arts et Métiers de Kairouan', 'isam@kairouan.rnu.tn', 'ISAM'),
    ],
    'Virtual University of Tunis': [
      Faculty('Formation Continue et à Distance', 'formation@uvt.rnu.tn', 'FCD'),
      Faculty('Programmes en Ligne', 'online@uvt.rnu.tn', 'POL'),
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
