import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:introduction_screen/introduction_screen.dart';

// Custom widget for image customization
Widget buildImage({String? path}) {
  return Center(
    child: Image.asset(
      path.toString(),
      width: 400,
      height: 300,
      fit: BoxFit.fitWidth,
    ),
  );
}

// custom Scrolldecoration
PageDecoration pageDecoration() {
  return PageDecoration(
    titleTextStyle: TextStyle(fontSize: 35, color: Colors.black),
    bodyTextStyle: TextStyle(fontSize: 20, color: Colors.grey[600]),
    bodyPadding: EdgeInsets.all(16),
    pageColor: Colors.white,
    imagePadding: EdgeInsets.all(2),
  );
}

class UserModel extends ChangeNotifier {
  final String? _uid;
  String? _name;
  final String?_email;
  String? _matricule;
  String? _phonenumber;

  UserModel({
      String? uid,
      String? name,
      String? email,
    String? matricule,
    String? phonenumber,
  }) : _uid = uid,
       _name = name,
       _email = email,
       _matricule = matricule,
       _phonenumber = phonenumber;
  // Gettters
  String? get uid => _uid;
  String? get name =>_name;
  String ?get email => _email;
  String? get matricule => _matricule;
  String? get phoneNumber => _phonenumber;
  void setName(String name) {
    _name = name;
    notifyListeners(); //Notify listeners when the code changes
  }

  void update({String? name, String? matricule, String? phoneNumber}){
    if(name != null) _name = name;
    if(matricule != null) _matricule = matricule;
    if(phoneNumber != null) _phonenumber = phoneNumber;
    notifyListeners();
  }
}

class DepartmentUI extends StatelessWidget {
  const DepartmentUI({
    super.key,
    required this.color,
    required this.imageurl,
    required this.title,
    required this.description,
    required this.hostid,
  });
  final Color color;
  final String imageurl, title, description, hostid;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height / 3.5,
      width: MediaQuery.sizeOf(context).width / 2.275,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 100,
            width: MediaQuery.sizeOf(context).width / 2.5,
            child: Image.asset(imageurl, fit: BoxFit.cover),
          ),
          SizedBox(height: 2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 18)),
              Text(description),
              Text(hostid),
            ],
          ),
        ],
      ),
    );
  }
}

List<Map<String, String>> computersciencecourses = [
  {'CSC205': 'Introduction to Computer Science'},
  {'CSC207': 'Introduction to  Algorithms'},
  {'CSC208': 'Programming in Python and C'},
  {'CSC209': 'Mathematical Foundations of Computer Science'},
  {'CSC210': 'Matrices and Linear Transformations'},
  {'CSC211': 'Probability and Statistics'},
  {'CSC212': 'Issues in Computing'},
  {'CSC214': 'Internet Technology and Web Design'},
  {'CSC301': 'Data Structures and Algorithms'},
  {'CSC303': 'Computer Organization and Architecture'},
  {'CSC304': 'Database Design'},
  {'CSC305': 'Object Oriented Programming'},
  {'CSC308': 'Java Programming'},
  {'CSC310': 'Database Design'},
  {'CSC311': 'Introduction to Computer Networks'},
  {'CSC314': 'Operating Systems'},
  {'CSC316': 'Functional Programming'},
  {'CSC402': 'Languages and Compilers'},
  {'CSC403': 'Numerical Analysis'},
  {'CSC404': 'Software Engineering'},
  {'CSC405': 'Artificial Intelligence'},
  {'CSC407': 'Programming and Language Paradigms'},
  {'CSC498': 'Computer Science Project'},
];

List<Map<String, String>> mathematicsCourses = [
  {'MAT201': 'Calculus I'},
  {'MAT202': 'Calculus II'},
  {'MAT203': 'Abstract Algebra'},
  {'MAT204': 'Linear Methods'},
  {'MAT207': 'Mathematical Methods IA'},
  {'MAT208': 'Mathematical Methods IIA'},
  {'MAT211': 'Mathematical Methods'},
  {'MAT301': 'Analysis I'},
  {'MAT302': 'Analysis II'},
  {'MAT303': 'Linear Algebra I'},
  {'MAT304': 'Linear Algebra II'},
  {'MAT305': 'Mathematical Probability I'},
  {'MAT306': 'Introduction to Mathematical Statistics'},
  {'MAT307': 'Introduction to Differential Equations'},
  {'MAT310': 'Mathematical Methods III'},
  {'MAT311': 'Analytical Mechanics'},
  {'MAT312': 'Electromagnetism'},
  {'MAT314': 'Analytic Geometry'},
  {'MAT401': 'Analysis III'},
  {'MAT402': 'General Topology'},
  {'MAT403': 'Set Theory'},
  {'MAT404': 'Group Theory'},
  {'MAT406': 'Mathematical Probability II'},
  {'MAT407': 'Complex Analysis I'},
  {'MAT409': 'Ordinary Differential Equations'},
  {'MAT411': 'Analytical Dynamics'},
  {'MAT412': 'Hydromechanics'},
  {'MAT413': 'Affine and Projective Geometry'},
  {'MAT415': 'Differential Geometry'},
  {'MAT416': 'Measure Theory and Integration'},
  {'MAT417': 'Calculus of Variations'},
  {'MAT418': 'Numerical Methods'},
  {'MAT419': 'Elements of Stochastic Processes'},
  {'MAT420': 'Elements of Queuing Theory'},
  {'MAT421': 'Multivariate Statistics'},
  {'MAT422': 'Introduction to Optimization'},
  {'MAT423': 'Combinatorics and Graph Theory'},
  {'MAT498': 'Research Project'},
];

List<Map<String, String>> physicsCourses = [
  {'ELT201': 'Electronic Devices'},
  {'ELT204': 'Analogue Electronics and basic circuit analysis'},
  {'ELT301': 'Digital Electronics'},
  {'ELT302': 'Microprocessors'},
  {'ELT303': 'Applied Electronics and Workshop Practice'},
  {'ELT304': 'Digital design laboratory'},
  {'ELT307': 'RF and Microwave Systems'},
  {'ELT401': 'Power Electronics'},
  {'ELT402': 'Communication systems'},
  {'ELT403': 'Analogue Integrated circuits'},
  {'ELT404': 'Introduction to control systems'},
  {'ELT406': 'Digital signal processing'},
  {'ELT408': 'Introduction toPHYsical design and Integrated circuits'},
  {'ELT410': 'Signal and systems'},
  {'ELT412': 'Computer architecture and data networks'},
  {'ELT426': 'Analogue Integrated circuits laboratory'},
  {'ELT491': 'Professional Internship'},
  {'ELT498': 'Project'},
  {'PHY202': 'Mechanics I'},
  {'PHY205': 'Thermodynamics and Structure of Matter'},
  {'PHY207': 'Mathematical Methods forPHYsics I'},
  {'PHY208': 'Electricity and Magnetism I'},
  {'PHY211': 'Waves and Optics I'},
  {'PHY212': 'GeneralPHYsics'},
  {'PHY215': 'Basic Concepts of Waves and Optics'},
  {'PHY218': 'Principles of Electricity and Magnetism'},
  {'PHY220': 'GeneralPHYsics'},
  {'PHY301': 'Mechanics II'},
  {'PHY305': 'Electricity and Magnetism II'},
  {'PHY306': 'Mathematical Methods of PHYsics II'},
  {'PHY308': 'Quantum Mechanics I'},
  {'PHY311': 'General Physics IIA'},
  {'PHY312': 'ThermalPHYsics'},
  {'PHY314': 'Special Relativity'},
  {'PHY317': 'Electronics I'},
  {'PHY405': 'Solid StatePHYsics'},
  {'PHY406': 'Atomic and NuclearPHYsics'},
  {'PHY410': 'Quantum Mechanics II'},
  {'PHY411': 'Electrodynamics'},
  {'PHY412': 'Waves and Optics II'},
  {'PHY417': 'Introduction to General Relativity and Cosmology'},
  {'PHY419': 'Introduction to Geophysics'},
  {'PHY420': 'Introduction to StatisticalPHYsics and Applications'},
  {'PHY422': 'Electronics II'},
  {'PHY424': 'Introduction to fluid mechanics'},
  {'PHY498': 'Physics project'},
];

Future<Map<String, dynamic>> getquestions() async {
  await Future.delayed(Duration(seconds: 2));
  final url = Uri.parse("https://opentdb.com/api.php?amount=50&category=18");
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the JSON.
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      print("Error: ${response.body}");
      // If the server did not return a 200 OK response, throw an exception.
      throw Exception('Failed to load questions: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching questions: $e');
  }
}

class SampleFrenchExamples {
  static const List<Map<String, dynamic>> examples = [
    // Greetings (20 entries)
    {
      'topic': 'greetings',
      'french': 'Bonjour',
      'english_translation': 'Hello',
      'example_usage': 'Bonjour, comment ça va ?',
    },
    {
      'topic': 'greetings',
      'french': 'Salut',
      'english_translation': 'Hi',
      'example_usage': 'Salut, mon ami !',
    },
    {
      'topic': 'greetings',
      'french': 'Au revoir',
      'english_translation': 'Goodbye',
      'example_usage': 'Au revoir, à bientôt.',
    },
    {
      'topic': 'greetings',
      'french': 'Bonne nuit',
      'english_translation': 'Good night',
      'example_usage': 'Bonne nuit, dors bien.',
    },
    {
      'topic': 'greetings',
      'french': 'Merci',
      'english_translation': 'Thank you',
      'example_usage': 'Merci pour le cadeau.',
    },
    {
      'topic': 'greetings',
      'french': 'S\'il vous plaît',
      'english_translation': 'Please',
      'example_usage': 'S\'il vous plaît, aidez-moi.',
    },
    {
      'topic': 'greetings',
      'french': 'Excusez-moi',
      'english_translation': 'Excuse me',
      'example_usage': 'Excusez-moi, où est la gare ?',
    },
    {
      'topic': 'greetings',
      'french': 'Comment allez-vous ?',
      'english_translation': 'How are you?',
      'example_usage': 'Comment allez-vous aujourd\'hui ?',
    },
    {
      'topic': 'greetings',
      'french': 'Très bien',
      'english_translation': 'Very well',
      'example_usage': 'Très bien, merci.',
    },
    {
      'topic': 'greetings',
      'french': 'À plus tard',
      'english_translation': 'See you later',
      'example_usage': 'À plus tard !',
    },
    {
      'topic': 'greetings',
      'french': 'Enchanté',
      'english_translation': 'Nice to meet you',
      'example_usage': 'Enchanté de vous connaître.',
    },
    {
      'topic': 'greetings',
      'french': 'Bonne journée',
      'english_translation': 'Have a good day',
      'example_usage': 'Bonne journée à vous.',
    },
    {
      'topic': 'greetings',
      'french': 'Bonsoir',
      'english_translation': 'Good evening',
      'example_usage': 'Bonsoir, madame.',
    },
    {
      'topic': 'greetings',
      'french': 'Adieu',
      'english_translation': 'Farewell',
      'example_usage': 'Adieu, mon ami.',
    },
    {
      'topic': 'greetings',
      'french': 'De rien',
      'english_translation': 'You\'re welcome',
      'example_usage': 'De rien, avec plaisir.',
    },
    {
      'topic': 'greetings',
      'french': 'Pardon',
      'english_translation': 'Pardon',
      'example_usage': 'Pardon, je suis en retard.',
    },
    {
      'topic': 'greetings',
      'french': 'Comment ça va ?',
      'english_translation': 'How\'s it going?',
      'example_usage': 'Comment ça va ce matin ?',
    },
    {
      'topic': 'greetings',
      'french': 'Bienvenue',
      'english_translation': 'Welcome',
      'example_usage': 'Bienvenue en France.',
    },
    {
      'topic': 'greetings',
      'french': 'À demain',
      'english_translation': 'See you tomorrow',
      'example_usage': 'À demain pour le café.',
    },
    {
      'topic': 'greetings',
      'french': 'Bonne chance',
      'english_translation': 'Good luck',
      'example_usage': 'Bonne chance pour l\'examen.',
    },

    // More Greetings
    {
      'topic': 'greetings',
      'french': 'Ça va ?',
      'english_translation': 'How\'s it going? (informal)',
      'example_usage': 'Salut, ça va ?',
    },
    {
      'topic': 'greetings',
      'french': 'Pas mal',
      'english_translation': 'Not bad',
      'example_usage': 'Ça va ? - Pas mal.',
    },
    {
      'topic': 'greetings',
      'french': 'Et toi ?',
      'english_translation': 'And you? (informal)',
      'example_usage': 'Je vais bien, et toi ?',
    },
    {
      'topic': 'greetings',
      'french': 'Et vous ?',
      'english_translation': 'And you? (formal)',
      'example_usage': 'Je vais bien, et vous ?',
    },
    {
      'topic': 'greetings',
      'french': 'À tout à l\'heure',
      'english_translation': 'See you in a bit',
      'example_usage': 'Je reviens, à tout à l\'heure.',
    },
    {
      'topic': 'greetings',
      'french': 'Bon appétit',
      'english_translation': 'Enjoy your meal',
      'example_usage': 'Le dîner est servi, bon appétit !',
    },
    {
      'topic': 'greetings',
      'french': 'À tes souhaits',
      'english_translation': 'Bless you (informal)',
      'example_usage': 'Atchoum ! - À tes souhaits.',
    },
    {
      'topic': 'greetings',
      'french': 'Félicitations',
      'english_translation': 'Congratulations',
      'example_usage': 'Félicitations pour ton succès.',
    },
    {
      'topic': 'greetings',
      'french': 'Joyeux anniversaire',
      'english_translation': 'Happy birthday',
      'example_usage': 'Joyeux anniversaire, mon ami !',
    },
    {
      'topic': 'greetings',
      'french': 'Bonne année',
      'english_translation': 'Happy New Year',
      'example_usage': 'Bonne année et bonne santé.',
    },
    {
      'topic': 'greetings',
      'french': 'Joyeux Noël',
      'english_translation': 'Merry Christmas',
      'example_usage': 'Joyeux Noël à toute la famille.',
    },
    {
      'topic': 'greetings',
      'french': 'S\'il te plaît',
      'english_translation': 'Please (informal)',
      'example_usage': 'Passe-moi le sel, s\'il te plaît.',
    },
    {
      'topic': 'greetings',
      'french': 'Je vous en prie',
      'english_translation': 'You\'re welcome (formal)',
      'example_usage': 'Merci beaucoup. - Je vous en prie.',
    },
    {
      'topic': 'greetings',
      'french': 'Comment vous appelez-vous ?',
      'english_translation': 'What is your name? (formal)',
      'example_usage': 'Bonjour, comment vous appelez-vous ?',
    },
    {
      'topic': 'greetings',
      'french': 'Je m\'appelle...',
      'english_translation': 'My name is...',
      'example_usage': 'Je m\'appelle Jean.',
    },
    {
      'topic': 'greetings',
      'french': 'D\'où venez-vous ?',
      'english_translation': 'Where are you from? (formal)',
      'example_usage': 'D\'où venez-vous, madame ?',
    },
    {
      'topic': 'greetings',
      'french': 'Je suis de...',
      'english_translation': 'I am from...',
      'example_usage': 'Je suis de Paris.',
    },
    {
      'topic': 'greetings',
      'french': 'Quel âge avez-vous ?',
      'english_translation': 'How old are you? (formal)',
      'example_usage': 'Quel âge avez-vous ?',
    },
    {
      'topic': 'greetings',
      'french': 'J\'ai ... ans',
      'english_translation': 'I am ... years old',
      'example_usage': 'J\'ai trente ans.',
    },
    {
      'topic': 'greetings',
      'french': 'Parlez-vous anglais ?',
      'english_translation': 'Do you speak English?',
      'example_usage': 'Excusez-moi, parlez-vous anglais ?',
    },

    // Adjectives (20 entries - trimmed)
    {
      'topic': 'adjectives',
      'french': 'Grand',
      'english_translation': 'Big/Tall',
      'example_usage': 'La maison est grande.',
    },
    {
      'topic': 'adjectives',
      'french': 'Petit',
      'english_translation': 'Small',
      'example_usage': 'Le chien est petit.',
    },
    {
      'topic': 'adjectives',
      'french': 'Beau',
      'english_translation': 'Beautiful',
      'example_usage': 'Le jardin est beau.',
    },
    {
      'topic': 'adjectives',
      'french': 'Bon',
      'english_translation': 'Good',
      'example_usage': 'Le pain est bon.',
    },
    {
      'topic': 'adjectives',
      'french': 'Mauvais',
      'english_translation': 'Bad',
      'example_usage': 'Le temps est mauvais.',
    },
    {
      'topic': 'adjectives',
      'french': 'Heureux',
      'english_translation': 'Happy',
      'example_usage': 'Je suis heureux.',
    },
    {
      'topic': 'adjectives',
      'french': 'Triste',
      'english_translation': 'Sad',
      'example_usage': 'Elle est triste.',
    },
    {
      'topic': 'adjectives',
      'french': 'Nouveau',
      'english_translation': 'New',
      'example_usage': 'La voiture est nouvelle.',
    },
    {
      'topic': 'adjectives',
      'french': 'Vieux',
      'english_translation': 'Old',
      'example_usage': 'Le livre est vieux.',
    },
    {
      'topic': 'adjectives',
      'french': 'Rouge',
      'english_translation': 'Red',
      'example_usage': 'La pomme est rouge.',
    },
    {
      'topic': 'adjectives',
      'french': 'Bleu',
      'english_translation': 'Blue',
      'example_usage': 'Le ciel est bleu.',
    },
    {
      'topic': 'adjectives',
      'french': 'Vert',
      'english_translation': 'Green',
      'example_usage': 'L\'herbe est verte.',
    },
    {
      'topic': 'adjectives',
      'french': 'Jaune',
      'english_translation': 'Yellow',
      'example_usage': 'Le soleil est jaune.',
    },
    {
      'topic': 'adjectives',
      'french': 'Noir',
      'english_translation': 'Black',
      'example_usage': 'Le chat est noir.',
    },
    {
      'topic': 'adjectives',
      'french': 'Blanc',
      'english_translation': 'White',
      'example_usage': 'La neige est blanche.',
    },
    {
      'topic': 'adjectives',
      'french': 'Froid',
      'english_translation': 'Cold',
      'example_usage': 'L\'eau est froide.',
    },
    {
      'topic': 'adjectives',
      'french': 'Chaud',
      'english_translation': 'Hot',
      'example_usage': 'Le thé est chaud.',
    },
    {
      'topic': 'adjectives',
      'french': 'Rapide',
      'english_translation': 'Fast',
      'example_usage': 'La voiture est rapide.',
    },
    {
      'topic': 'adjectives',
      'french': 'Lent',
      'english_translation': 'Slow',
      'example_usage': 'Le train est lent.',
    },
    {
      'topic': 'adjectives',
      'french': 'Facile',
      'english_translation': 'Easy',
      'example_usage': 'La leçon est facile.',
    },

    // More Adjectives
    {
      'topic': 'adjectives',
      'french': 'Difficile',
      'english_translation': 'Difficult',
      'example_usage': 'Cet exercice est difficile.',
    },
    {
      'topic': 'adjectives',
      'french': 'Jeune',
      'english_translation': 'Young',
      'example_usage': 'Mon frère est jeune.',
    },
    {
      'topic': 'adjectives',
      'french': 'Joli',
      'english_translation': 'Pretty',
      'example_usage': 'C\'est une jolie robe.',
    },
    {
      'topic': 'adjectives',
      'french': 'Laid',
      'english_translation': 'Ugly',
      'example_usage': 'Ce bâtiment est laid.',
    },
    {
      'topic': 'adjectives',
      'french': 'Riche',
      'english_translation': 'Rich',
      'example_usage': 'Il est un homme riche.',
    },
    {
      'topic': 'adjectives',
      'french': 'Pauvre',
      'english_translation': 'Poor',
      'example_usage': 'La famille était pauvre.',
    },
    {
      'topic': 'adjectives',
      'french': 'Fort',
      'english_translation': 'Strong',
      'example_usage': 'Il est très fort.',
    },
    {
      'topic': 'adjectives',
      'french': 'Faible',
      'english_translation': 'Weak',
      'example_usage': 'Le signal est faible.',
    },
    {
      'topic': 'adjectives',
      'french': 'Intelligent',
      'english_translation': 'Intelligent',
      'example_usage': 'C\'est une idée intelligente.',
    },
    {
      'topic': 'adjectives',
      'french': 'Drôle',
      'english_translation': 'Funny',
      'example_usage': 'Cette histoire est drôle.',
    },
    {
      'topic': 'adjectives',
      'french': 'Sérieux',
      'english_translation': 'Serious',
      'example_usage': 'C\'est un problème sérieux.',
    },
    {
      'topic': 'adjectives',
      'french': 'Gentil',
      'english_translation': 'Kind',
      'example_usage': 'Votre voisin est très gentil.',
    },
    {
      'topic': 'adjectives',
      'french': 'Court',
      'english_translation': 'Short',
      'example_usage': 'Le film était court.',
    },
    {
      'topic': 'adjectives',
      'french': 'Long',
      'english_translation': 'Long',
      'example_usage': 'La route est longue.',
    },
    {
      'topic': 'adjectives',
      'french': 'Léger',
      'english_translation': 'Light (weight)',
      'example_usage': 'Ce sac est léger.',
    },
    {
      'topic': 'adjectives',
      'french': 'Lourd',
      'english_translation': 'Heavy',
      'example_usage': 'La boîte est lourde.',
    },
    {
      'topic': 'adjectives',
      'french': 'Propre',
      'english_translation': 'Clean',
      'example_usage': 'La chambre est propre.',
    },
    {
      'topic': 'adjectives',
      'french': 'Sale',
      'english_translation': 'Dirty',
      'example_usage': 'Tes chaussures sont sales.',
    },
    {
      'topic': 'adjectives',
      'french': 'Cher',
      'english_translation': 'Expensive/Dear',
      'example_usage': 'Cette montre est chère.',
    },
    {
      'topic': 'adjectives',
      'french': 'Délicieux',
      'english_translation': 'Delicious',
      'example_usage': 'Le gâteau est délicieux.',
    },

    // Nouns (20 entries - trimmed)
    {
      'topic': 'nouns',
      'french': 'Maison',
      'english_translation': 'House',
      'example_usage': 'La maison est grande.',
    },
    {
      'topic': 'nouns',
      'french': 'Voiture',
      'english_translation': 'Car',
      'example_usage': 'La voiture est rouge.',
    },
    {
      'topic': 'nouns',
      'french': 'Livre',
      'english_translation': 'Book',
      'example_usage': 'Le livre est intéressant.',
    },
    {
      'topic': 'nouns',
      'french': 'Chat',
      'english_translation': 'Cat',
      'example_usage': 'Le chat est noir.',
    },
    {
      'topic': 'nouns',
      'french': 'Chien',
      'english_translation': 'Dog',
      'example_usage': 'Le chien court vite.',
    },
    {
      'topic': 'nouns',
      'french': 'Arbre',
      'english_translation': 'Tree',
      'example_usage': 'L\'arbre est vert.',
    },
    {
      'topic': 'nouns',
      'french': 'Fleur',
      'english_translation': 'Flower',
      'example_usage': 'La fleur est belle.',
    },
    {
      'topic': 'nouns',
      'french': 'Table',
      'english_translation': 'Table',
      'example_usage': 'La table est en bois.',
    },
    {
      'topic': 'nouns',
      'french': 'Chaise',
      'english_translation': 'Chair',
      'example_usage': 'La chaise est confortable.',
    },
    {
      'topic': 'nouns',
      'french': 'Fenêtre',
      'english_translation': 'Window',
      'example_usage': 'La fenêtre est ouverte.',
    },
    {
      'topic': 'nouns',
      'french': 'Porte',
      'english_translation': 'Door',
      'example_usage': 'La porte est fermée.',
    },
    {
      'topic': 'nouns',
      'french': 'École',
      'english_translation': 'School',
      'example_usage': 'L\'école est près.',
    },
    {
      'topic': 'nouns',
      'french': 'Ville',
      'english_translation': 'City',
      'example_usage': 'La ville est grande.',
    },
    {
      'topic': 'nouns',
      'french': 'Pays',
      'english_translation': 'Country',
      'example_usage': 'Le pays est beau.',
    },
    {
      'topic': 'nouns',
      'french': 'Ami',
      'english_translation': 'Friend',
      'example_usage': 'Mon ami est gentil.',
    },
    {
      'topic': 'nouns',
      'french': 'Famille',
      'english_translation': 'Family',
      'example_usage': 'Ma famille est grande.',
    },
    {
      'topic': 'nouns',
      'french': 'Eau',
      'english_translation': 'Water',
      'example_usage': 'L\'eau est froide.',
    },
    {
      'topic': 'nouns',
      'french': 'Pain',
      'english_translation': 'Bread',
      'example_usage': 'Le pain est frais.',
    },
    {
      'topic': 'nouns',
      'french': 'Fruit',
      'english_translation': 'Fruit',
      'example_usage': 'Le fruit est sucré.',
    },
    {
      'topic': 'nouns',
      'french': 'Légume',
      'english_translation': 'Vegetable',
      'example_usage': 'Le légume est sain.',
    },

    // More Nouns
    {
      'topic': 'nouns',
      'french': 'Homme',
      'english_translation': 'Man',
      'example_usage': 'Un homme marche dans la rue.',
    },
    {
      'topic': 'nouns',
      'french': 'Femme',
      'english_translation': 'Woman',
      'example_usage': 'La femme lit un journal.',
    },
    {
      'topic': 'nouns',
      'french': 'Enfant',
      'english_translation': 'Child',
      'example_usage': 'L\'enfant joue dans le parc.',
    },
    {
      'topic': 'nouns',
      'french': 'Travail',
      'english_translation': 'Work',
      'example_usage': 'Le travail est important.',
    },
    {
      'topic': 'nouns',
      'french': 'Amour',
      'english_translation': 'Love',
      'example_usage': 'L\'amour est un beau sentiment.',
    },
    {
      'topic': 'nouns',
      'french': 'Temps',
      'english_translation': 'Time/Weather',
      'example_usage': 'Le temps passe vite.',
    },
    {
      'topic': 'nouns',
      'french': 'Argent',
      'english_translation': 'Money',
      'example_usage': 'J\'ai besoin d\'argent.',
    },
    {
      'topic': 'nouns',
      'french': 'Monde',
      'english_translation': 'World',
      'example_usage': 'Le monde est vaste.',
    },
    {
      'topic': 'nouns',
      'french': 'Jour',
      'english_translation': 'Day',
      'example_usage': 'C\'est un beau jour.',
    },
    {
      'topic': 'nouns',
      'french': 'Nuit',
      'english_translation': 'Night',
      'example_usage': 'La nuit est calme.',
    },
    {
      'topic': 'nouns',
      'french': 'Matin',
      'english_translation': 'Morning',
      'example_usage': 'Le matin, je bois du café.',
    },
    {
      'topic': 'nouns',
      'french': 'Soir',
      'english_translation': 'Evening',
      'example_usage': 'Le soir, je regarde un film.',
    },
    {
      'topic': 'nouns',
      'french': 'Tête',
      'english_translation': 'Head',
      'example_usage': 'J\'ai mal à la tête.',
    },
    {
      'topic': 'nouns',
      'french': 'Main',
      'english_translation': 'Hand',
      'example_usage': 'Lave tes mains.',
    },
    {
      'topic': 'nouns',
      'french': 'Pied',
      'english_translation': 'Foot',
      'example_usage': 'J\'ai froid aux pieds.',
    },
    {
      'topic': 'nouns',
      'french': 'Coeur',
      'english_translation': 'Heart',
      'example_usage': 'Mon coeur bat vite.',
    },
    {
      'topic': 'nouns',
      'french': 'Soleil',
      'english_translation': 'Sun',
      'example_usage': 'Le soleil brille.',
    },
    {
      'topic': 'nouns',
      'french': 'Lune',
      'english_translation': 'Moon',
      'example_usage': 'La lune est pleine ce soir.',
    },
    {
      'topic': 'nouns',
      'french': 'Étoile',
      'english_translation': 'Star',
      'example_usage': 'Regarde cette belle étoile.',
    },
    {
      'topic': 'nouns',
      'french': 'Ciel',
      'english_translation': 'Sky',
      'example_usage': 'Le ciel est dégagé.',
    },

    // Pronouns (20 entries - trimmed)
    {
      'topic': 'pronouns',
      'french': 'Je',
      'english_translation': 'I',
      'example_usage': 'Je suis heureux.',
    },
    {
      'topic': 'pronouns',
      'french': 'Tu',
      'english_translation': 'You (informal)',
      'example_usage': 'Tu es gentil.',
    },
    {
      'topic': 'pronouns',
      'french': 'Il',
      'english_translation': 'He/It (masc.)',
      'example_usage': 'Il court vite.',
    },
    {
      'topic': 'pronouns',
      'french': 'Elle',
      'english_translation': 'She/It (fem.)',
      'example_usage': 'Elle chante bien.',
    },
    {
      'topic': 'pronouns',
      'french': 'Nous',
      'english_translation': 'We',
      'example_usage': 'Nous mangeons.',
    },
    {
      'topic': 'pronouns',
      'french': 'Vous',
      'english_translation': 'You (formal/plural)',
      'example_usage': 'Vous parlez français.',
    },
    {
      'topic': 'pronouns',
      'french': 'Ils',
      'english_translation': 'They (masc.)',
      'example_usage': 'Ils jouent au football.',
    },
    {
      'topic': 'pronouns',
      'french': 'Elles',
      'english_translation': 'They (fem.)',
      'example_usage': 'Elles lisent un livre.',
    },
    {
      'topic': 'pronouns',
      'french': 'Me',
      'english_translation': 'Me',
      'example_usage': 'Il me voit.',
    },
    {
      'topic': 'pronouns',
      'french': 'Te',
      'english_translation': 'You (informal)',
      'example_usage': 'Je te donne.',
    },
    {
      'topic': 'pronouns',
      'french': 'Le',
      'english_translation': 'Him/It (masc.)',
      'example_usage': 'Je le mange.',
    },
    {
      'topic': 'pronouns',
      'french': 'La',
      'english_translation': 'Her/It (fem.)',
      'example_usage': 'Je la bois.',
    },
    {
      'topic': 'pronouns',
      'french': 'Nous',
      'english_translation': 'Us',
      'example_usage': 'Il nous aide.',
    },
    {
      'topic': 'pronouns',
      'french': 'Vous',
      'english_translation': 'You',
      'example_usage': 'Je vous appelle.',
    },
    {
      'topic': 'pronouns',
      'french': 'Les',
      'english_translation': 'Them',
      'example_usage': 'Je les aime.',
    },
    {
      'topic': 'pronouns',
      'french': 'Moi',
      'english_translation': 'Me (emphasized)',
      'example_usage': 'C\'est moi.',
    },
    {
      'topic': 'pronouns',
      'french': 'Toi',
      'english_translation': 'You (emphasized)',
      'example_usage': 'C\'est toi.',
    },
    {
      'topic': 'pronouns',
      'french': 'Lui',
      'english_translation': 'Him',
      'example_usage': 'Je parle à lui.',
    },
    {
      'topic': 'pronouns',
      'french': 'Elle',
      'english_translation': 'Her',
      'example_usage': 'Je parle à elle.',
    },
    {
      'topic': 'pronouns',
      'french': 'Nous',
      'english_translation': 'Us (emphasized)',
      'example_usage': 'C\'est nous.',
    },

    // More Pronouns
    {
      'topic': 'pronouns',
      'french': 'Eux',
      'english_translation': 'Them (masc. emphasized)',
      'example_usage': 'Je pense à eux.',
    },
    {
      'topic': 'pronouns',
      'french': 'Elles',
      'english_translation': 'Them (fem. emphasized)',
      'example_usage': 'C\'est pour elles.',
    },
    {
      'topic': 'pronouns',
      'french': 'Celui-ci',
      'english_translation': 'This one (masc.)',
      'example_usage': 'Je préfère celui-ci.',
    },
    {
      'topic': 'pronouns',
      'french': 'Celle-ci',
      'english_translation': 'This one (fem.)',
      'example_usage': 'Celle-ci est plus jolie.',
    },
    {
      'topic': 'pronouns',
      'french': 'Ceux-ci',
      'english_translation': 'These (masc.)',
      'example_usage': 'Ceux-ci sont à moi.',
    },
    {
      'topic': 'pronouns',
      'french': 'Celles-ci',
      'english_translation': 'These (fem.)',
      'example_usage': 'Celles-ci sont nouvelles.',
    },
    {
      'topic': 'pronouns',
      'french': 'Celui-là',
      'english_translation': 'That one (masc.)',
      'example_usage': 'Non, je veux celui-là.',
    },
    {
      'topic': 'pronouns',
      'french': 'Celle-là',
      'english_translation': 'That one (fem.)',
      'example_usage': 'Celle-là est trop chère.',
    },
    {
      'topic': 'pronouns',
      'french': 'Ceux-là',
      'english_translation': 'Those (masc.)',
      'example_usage': 'Ceux-là sont vieux.',
    },
    {
      'topic': 'pronouns',
      'french': 'Celles-là',
      'english_translation': 'Those (fem.)',
      'example_usage': 'Celles-là sont cassées.',
    },
    {
      'topic': 'pronouns',
      'french': 'Lequel',
      'english_translation': 'Which one (masc.)',
      'example_usage': 'Lequel choisis-tu ?',
    },
    {
      'topic': 'pronouns',
      'french': 'Laquelle',
      'english_translation': 'Which one (fem.)',
      'example_usage': 'Laquelle est la tienne ?',
    },
    {
      'topic': 'pronouns',
      'french': 'Lesquels',
      'english_translation': 'Which ones (masc.)',
      'example_usage': 'Lesquels sont les meilleurs ?',
    },
    {
      'topic': 'pronouns',
      'french': 'Lesquelles',
      'english_translation': 'Which ones (fem.)',
      'example_usage': 'Lesquelles sont prêtes ?',
    },
    {
      'topic': 'pronouns',
      'french': 'Quelqu\'un',
      'english_translation': 'Someone',
      'example_usage': 'Quelqu\'un a appelé.',
    },
    {
      'topic': 'pronouns',
      'french': 'Quelque chose',
      'english_translation': 'Something',
      'example_usage': 'J\'ai vu quelque chose.',
    },
    {
      'topic': 'pronouns',
      'french': 'Personne',
      'english_translation': 'No one',
      'example_usage': 'Personne n\'est venu.',
    },
    {
      'topic': 'pronouns',
      'french': 'Rien',
      'english_translation': 'Nothing',
      'example_usage': 'Je n\'ai rien fait.',
    },
    {
      'topic': 'pronouns',
      'french': 'Chacun',
      'english_translation': 'Each one',
      'example_usage': 'Chacun a sa propre opinion.',
    },
    {
      'topic': 'pronouns',
      'french': 'Plusieurs',
      'english_translation': 'Several',
      'example_usage': 'Plusieurs sont partis.',
    },

    // Verbs (20 entries - trimmed)
    {
      'topic': 'verbs',
      'french': 'Être',
      'english_translation': 'To be',
      'example_usage': 'Je suis français.',
    },
    {
      'topic': 'verbs',
      'french': 'Avoir',
      'english_translation': 'To have',
      'example_usage': 'J\'ai un livre.',
    },
    {
      'topic': 'verbs',
      'french': 'Aller',
      'english_translation': 'To go',
      'example_usage': 'Je vais à l\'école.',
    },
    {
      'topic': 'verbs',
      'french': 'Faire',
      'english_translation': 'To do/make',
      'example_usage': 'Je fais du sport.',
    },
    {
      'topic': 'verbs',
      'french': 'Dire',
      'english_translation': 'To say',
      'example_usage': 'Je dis bonjour.',
    },
    {
      'topic': 'verbs',
      'french': 'Voir',
      'english_translation': 'To see',
      'example_usage': 'Je vois un chat.',
    },
    {
      'topic': 'verbs',
      'french': 'Savoir',
      'english_translation': 'To know',
      'example_usage': 'Je sais la réponse.',
    },
    {
      'topic': 'verbs',
      'french': 'Pouvoir',
      'english_translation': 'To be able to',
      'example_usage': 'Je peux nager.',
    },
    {
      'topic': 'verbs',
      'french': 'Venir',
      'english_translation': 'To come',
      'example_usage': 'Je viens de France.',
    },
    {
      'topic': 'verbs',
      'french': 'Vouloir',
      'english_translation': 'To want',
      'example_usage': 'Je veux du café.',
    },
    {
      'topic': 'verbs',
      'french': 'Manger',
      'english_translation': 'To eat',
      'example_usage': 'Je mange une pomme.',
    },
    {
      'topic': 'verbs',
      'french': 'Boire',
      'english_translation': 'To drink',
      'example_usage': 'Je bois de l\'eau.',
    },
    {
      'topic': 'verbs',
      'french': 'Dormir',
      'english_translation': 'To sleep',
      'example_usage': 'Je dors huit heures.',
    },
    {
      'topic': 'verbs',
      'french': 'Lire',
      'english_translation': 'To read',
      'example_usage': 'Je lis un livre.',
    },
    {
      'topic': 'verbs',
      'french': 'Écrire',
      'english_translation': 'To write',
      'example_usage': 'J\'écris une lettre.',
    },
    {
      'topic': 'verbs',
      'french': 'Parler',
      'english_translation': 'To speak',
      'example_usage': 'Je parle français.',
    },
    {
      'topic': 'verbs',
      'french': 'Écouter',
      'english_translation': 'To listen',
      'example_usage': 'J\'écoute la musique.',
    },
    {
      'topic': 'verbs',
      'french': 'Regarder',
      'english_translation': 'To watch',
      'example_usage': 'Je regarde la TV.',
    },
    {
      'topic': 'verbs',
      'french': 'Courir',
      'english_translation': 'To run',
      'example_usage': 'Je cours vite.',
    },
    {
      'topic': 'verbs',
      'french': 'Marcher',
      'english_translation': 'To walk',
      'example_usage': 'Je marche lentement.',
    },

    // More Verbs
    {
      'topic': 'verbs',
      'french': 'Prendre',
      'english_translation': 'To take',
      'example_usage': 'Je prends le bus.',
    },
    {
      'topic': 'verbs',
      'french': 'Mettre',
      'english_translation': 'To put',
      'example_usage': 'Je mets la table.',
    },
    {
      'topic': 'verbs',
      'french': 'Devoir',
      'english_translation': 'To have to/must',
      'example_usage': 'Je dois partir.',
    },
    {
      'topic': 'verbs',
      'french': 'Partir',
      'english_translation': 'To leave',
      'example_usage': 'Il part demain.',
    },
    {
      'topic': 'verbs',
      'french': 'Sortir',
      'english_translation': 'To go out',
      'example_usage': 'Nous sortons ce soir.',
    },
    {
      'topic': 'verbs',
      'french': 'Ouvrir',
      'english_translation': 'To open',
      'example_usage': 'Ouvre la fenêtre.',
    },
    {
      'topic': 'verbs',
      'french': 'Fermer',
      'english_translation': 'To close',
      'example_usage': 'Ferme la porte.',
    },
    {
      'topic': 'verbs',
      'french': 'Aimer',
      'english_translation': 'To like/love',
      'example_usage': 'J\'aime le chocolat.',
    },
    {
      'topic': 'verbs',
      'french': 'Penser',
      'english_translation': 'To think',
      'example_usage': 'Je pense à toi.',
    },
    {
      'topic': 'verbs',
      'french': 'Trouver',
      'english_translation': 'To find',
      'example_usage': 'Je ne trouve pas mes clés.',
    },
    {
      'topic': 'verbs',
      'french': 'Donner',
      'english_translation': 'To give',
      'example_usage': 'Donne-moi le livre.',
    },
    {
      'topic': 'verbs',
      'french': 'Aider',
      'english_translation': 'To help',
      'example_usage': 'Peux-tu m\'aider ?',
    },
    {
      'topic': 'verbs',
      'french': 'Jouer',
      'english_translation': 'To play',
      'example_usage': 'Les enfants jouent dehors.',
    },
    {
      'topic': 'verbs',
      'french': 'Travailler',
      'english_translation': 'To work',
      'example_usage': 'Je travaille à Paris.',
    },
    {
      'topic': 'verbs',
      'french': 'Étudier',
      'english_translation': 'To study',
      'example_usage': 'Elle étudie la médecine.',
    },
    {
      'topic': 'verbs',
      'french': 'Habiter',
      'english_translation': 'To live',
      'example_usage': 'J\'habite en ville.',
    },
    {
      'topic': 'verbs',
      'french': 'Acheter',
      'english_translation': 'To buy',
      'example_usage': 'Je vais acheter du pain.',
    },
    {
      'topic': 'verbs',
      'french': 'Vendre',
      'english_translation': 'To sell',
      'example_usage': 'Il vend sa voiture.',
    },
    {
      'topic': 'verbs',
      'french': 'Attendre',
      'english_translation': 'To wait',
      'example_usage': 'J\'attends le bus.',
    },
    {
      'topic': 'verbs',
      'french': 'Comprendre',
      'english_translation': 'To understand',
      'example_usage': 'Je ne comprends pas.',
    },

    // Continue with other topics, trimmed to reach ~200 total...
    // Prepositions (15 entries)
    {
      'topic': 'prepositions',
      'french': 'À',
      'english_translation': 'To/At',
      'example_usage': 'Je vais à Paris.',
    },
    {
      'topic': 'prepositions',
      'french': 'De',
      'english_translation': 'From/Of',
      'example_usage': 'Je viens de Lyon.',
    },
    {
      'topic': 'prepositions',
      'french': 'Dans',
      'english_translation': 'In',
      'example_usage': 'Le livre est dans le sac.',
    },
    {
      'topic': 'prepositions',
      'french': 'Sur',
      'english_translation': 'On',
      'example_usage': 'Le chat est sur la table.',
    },
    {
      'topic': 'prepositions',
      'french': 'Sous',
      'english_translation': 'Under',
      'example_usage': 'Le chien est sous la chaise.',
    },
    {
      'topic': 'prepositions',
      'french': 'Avec',
      'english_translation': 'With',
      'example_usage': 'Je mange avec une fourchette.',
    },
    {
      'topic': 'prepositions',
      'french': 'Sans',
      'english_translation': 'Without',
      'example_usage': 'Je bois sans sucre.',
    },
    {
      'topic': 'prepositions',
      'french': 'Pour',
      'english_translation': 'For',
      'example_usage': 'C\'est pour toi.',
    },
    {
      'topic': 'prepositions',
      'french': 'Par',
      'english_translation': 'By/Through',
      'example_usage': 'Je voyage par train.',
    },
    {
      'topic': 'prepositions',
      'french': 'En',
      'english_translation': 'In/By',
      'example_usage': 'Je voyage en voiture.',
    },
    {
      'topic': 'prepositions',
      'french': 'Entre',
      'english_translation': 'Between',
      'example_usage': 'La table est entre les chaises.',
    },
    {
      'topic': 'prepositions',
      'french': 'Devant',
      'english_translation': 'In front of',
      'example_usage': 'La voiture est devant la maison.',
    },
    {
      'topic': 'prepositions',
      'french': 'Derrière',
      'english_translation': 'Behind',
      'example_usage': 'Le jardin est derrière la maison.',
    },
    {
      'topic': 'prepositions',
      'french': 'Près de',
      'english_translation': 'Near',
      'example_usage': 'L\'école est près de la maison.',
    },
    {
      'topic': 'prepositions',
      'french': 'Loin de',
      'english_translation': 'Far from',
      'example_usage': 'La ville est loin de la campagne.',
    },

    // More Prepositions
    {
      'topic': 'prepositions',
      'french': 'Avant',
      'english_translation': 'Before',
      'example_usage': 'Avant le dîner.',
    },
    {
      'topic': 'prepositions',
      'french': 'Après',
      'english_translation': 'After',
      'example_usage': 'Après le film.',
    },
    {
      'topic': 'prepositions',
      'french': 'Pendant',
      'english_translation': 'During',
      'example_usage': 'Pendant les vacances.',
    },
    {
      'topic': 'prepositions',
      'french': 'Depuis',
      'english_translation': 'Since/For',
      'example_usage': 'J\'attends depuis une heure.',
    },
    {
      'topic': 'prepositions',
      'french': 'Chez',
      'english_translation': 'At someone\'s place',
      'example_usage': 'Je vais chez Paul.',
    },

    // Conjunctions (15 entries)
    {
      'topic': 'conjunctions',
      'french': 'Et',
      'english_translation': 'And',
      'example_usage': 'Je mange et je bois.',
    },
    {
      'topic': 'conjunctions',
      'french': 'Ou',
      'english_translation': 'Or',
      'example_usage': 'Thé ou café ?',
    },
    {
      'topic': 'conjunctions',
      'french': 'Mais',
      'english_translation': 'But',
      'example_usage': 'Je veux, mais je ne peux pas.',
    },
    {
      'topic': 'conjunctions',
      'french': 'Donc',
      'english_translation': 'So',
      'example_usage': 'Il pleut, donc je reste.',
    },
    {
      'topic': 'conjunctions',
      'french': 'Car',
      'english_translation': 'Because',
      'example_usage': 'Je reste, car il pleut.',
    },
    {
      'topic': 'conjunctions',
      'french': 'Si',
      'english_translation': 'If',
      'example_usage': 'Si tu veux, viens.',
    },
    {
      'topic': 'conjunctions',
      'french': 'Quand',
      'english_translation': 'When',
      'example_usage': 'Quand tu arrives, appelle.',
    },
    {
      'topic': 'conjunctions',
      'french': 'Parce que',
      'english_translation': 'Because',
      'example_usage': 'Je mange parce que j\'ai faim.',
    },
    {
      'topic': 'conjunctions',
      'french': 'Afin que',
      'english_translation': 'So that',
      'example_usage': 'Je travaille afin que je gagne.',
    },
    {
      'topic': 'conjunctions',
      'french': 'Bien que',
      'english_translation': 'Although',
      'example_usage': 'Bien que fatigué, je continue.',
    },
    {
      'topic': 'conjunctions',
      'french': 'Puisque',
      'english_translation': 'Since',
      'example_usage': 'Puisque tu es là, aide-moi.',
    },
    {
      'topic': 'conjunctions',
      'french': 'Tandis que',
      'english_translation': 'While',
      'example_usage': 'Tandis que je lis, tu écris.',
    },
    {
      'topic': 'conjunctions',
      'french': 'Avant que',
      'english_translation': 'Before',
      'example_usage': 'Avant que tu partes, dis-moi.',
    },
    {
      'topic': 'conjunctions',
      'french': 'Après que',
      'english_translation': 'After',
      'example_usage': 'Après que je mange, je dors.',
    },
    {
      'topic': 'conjunctions',
      'french': 'Pour que',
      'english_translation': 'So that',
      'example_usage': 'Je parle fort pour que tu entendes.',
    },

    // More Conjunctions
    {
      'topic': 'conjunctions',
      'french': 'Comme',
      'english_translation': 'As/Like',
      'example_usage': 'Fais comme tu veux.',
    },
    {
      'topic': 'conjunctions',
      'french': 'Où',
      'english_translation': 'Where',
      'example_usage': 'La ville où je suis né.',
    },
    {
      'topic': 'conjunctions',
      'french': 'Que',
      'english_translation': 'That',
      'example_usage': 'Je pense que tu as raison.',
    },
    {
      'topic': 'conjunctions',
      'french': 'Qui',
      'english_translation': 'Who/That',
      'example_usage': 'L\'homme qui parle.',
    },
    {
      'topic': 'conjunctions',
      'french': 'Ni...ni',
      'english_translation': 'Neither...nor',
      'example_usage': 'Je ne veux ni thé ni café.',
    },

    // Adverbs (15 entries)
    {
      'topic': 'adverbs',
      'french': 'Vite',
      'english_translation': 'Quickly',
      'example_usage': 'Je cours vite.',
    },
    {
      'topic': 'adverbs',
      'french': 'Lentement',
      'english_translation': 'Slowly',
      'example_usage': 'Marche lentement.',
    },
    {
      'topic': 'adverbs',
      'french': 'Bien',
      'english_translation': 'Well',
      'example_usage': 'Je chante bien.',
    },
    {
      'topic': 'adverbs',
      'french': 'Mal',
      'english_translation': 'Badly',
      'example_usage': 'Il joue mal.',
    },
    {
      'topic': 'adverbs',
      'french': 'Très',
      'english_translation': 'Very',
      'example_usage': 'C\'est très bon.',
    },
    {
      'topic': 'adverbs',
      'french': 'Trop',
      'english_translation': 'Too',
      'example_usage': 'C\'est trop chaud.',
    },
    {
      'topic': 'adverbs',
      'french': 'Peu',
      'english_translation': 'Little',
      'example_usage': 'Je mange peu.',
    },
    {
      'topic': 'adverbs',
      'french': 'Beaucoup',
      'english_translation': 'A lot',
      'example_usage': 'Je lis beaucoup.',
    },
    {
      'topic': 'adverbs',
      'french': 'Ici',
      'english_translation': 'Here',
      'example_usage': 'Viens ici.',
    },
    {
      'topic': 'adverbs',
      'french': 'Là',
      'english_translation': 'There',
      'example_usage': 'Regarde là.',
    },
    {
      'topic': 'adverbs',
      'french': 'Maintenant',
      'english_translation': 'Now',
      'example_usage': 'Viens maintenant.',
    },
    {
      'topic': 'adverbs',
      'french': 'Demain',
      'english_translation': 'Tomorrow',
      'example_usage': 'À demain.',
    },
    {
      'topic': 'adverbs',
      'french': 'Hier',
      'english_translation': 'Yesterday',
      'example_usage': 'Hier était beau.',
    },
    {
      'topic': 'adverbs',
      'french': 'Toujours',
      'english_translation': 'Always',
      'example_usage': 'Je suis toujours heureux.',
    },
    {
      'topic': 'adverbs',
      'french': 'Jamais',
      'english_translation': 'Never',
      'example_usage': 'Je ne fume jamais.',
    },

    // More Adverbs
    {
      'topic': 'adverbs',
      'french': 'Souvent',
      'english_translation': 'Often',
      'example_usage': 'Je vais souvent au cinéma.',
    },
    {
      'topic': 'adverbs',
      'french': 'Parfois',
      'english_translation': 'Sometimes',
      'example_usage': 'Parfois, il pleut.',
    },
    {
      'topic': 'adverbs',
      'french': 'Rarement',
      'english_translation': 'Rarely',
      'example_usage': 'Je mange rarement de la viande.',
    },
    {
      'topic': 'adverbs',
      'french': 'Ensemble',
      'english_translation': 'Together',
      'example_usage': 'Nous travaillons ensemble.',
    },
    {
      'topic': 'adverbs',
      'french': 'Seulement',
      'english_translation': 'Only',
      'example_usage': 'J\'ai seulement un frère.',
    },

    // Numbers (15 entries)
    {
      'topic': 'numbers',
      'french': 'Un',
      'english_translation': 'One',
      'example_usage': 'Un livre.',
    },
    {
      'topic': 'numbers',
      'french': 'Deux',
      'english_translation': 'Two',
      'example_usage': 'Deux chats.',
    },
    {
      'topic': 'numbers',
      'french': 'Trois',
      'english_translation': 'Three',
      'example_usage': 'Trois pommes.',
    },
    {
      'topic': 'numbers',
      'french': 'Quatre',
      'english_translation': 'Four',
      'example_usage': 'Quatre voitures.',
    },
    {
      'topic': 'numbers',
      'french': 'Cinq',
      'english_translation': 'Five',
      'example_usage': 'Cinq amis.',
    },
    {
      'topic': 'numbers',
      'french': 'Six',
      'english_translation': 'Six',
      'example_usage': 'Six livres.',
    },
    {
      'topic': 'numbers',
      'french': 'Sept',
      'english_translation': 'Seven',
      'example_usage': 'Sept jours.',
    },
    {
      'topic': 'numbers',
      'french': 'Huit',
      'english_translation': 'Eight',
      'example_usage': 'Huit heures.',
    },
    {
      'topic': 'numbers',
      'french': 'Neuf',
      'english_translation': 'Nine',
      'example_usage': 'Neuf mois.',
    },
    {
      'topic': 'numbers',
      'french': 'Dix',
      'english_translation': 'Ten',
      'example_usage': 'Dix doigts.',
    },
    {
      'topic': 'numbers',
      'french': 'Onze',
      'english_translation': 'Eleven',
      'example_usage': 'Onze joueurs.',
    },
    {
      'topic': 'numbers',
      'french': 'Douze',
      'english_translation': 'Twelve',
      'example_usage': 'Douze œufs.',
    },
    {
      'topic': 'numbers',
      'french': 'Treize',
      'english_translation': 'Thirteen',
      'example_usage': 'Treize ans.',
    },
    {
      'topic': 'numbers',
      'french': 'Quatorze',
      'english_translation': 'Fourteen',
      'example_usage': 'Quatorze juillet.',
    },
    {
      'topic': 'numbers',
      'french': 'Quinze',
      'english_translation': 'Fifteen',
      'example_usage': 'Quinze minutes.',
    },

    // More Numbers
    {
      'topic': 'numbers',
      'french': 'Seize',
      'english_translation': 'Sixteen',
      'example_usage': 'Seize bougies.',
    },
    {
      'topic': 'numbers',
      'french': 'Vingt',
      'english_translation': 'Twenty',
      'example_usage': 'Vingt euros.',
    },
    {
      'topic': 'numbers',
      'french': 'Trente',
      'english_translation': 'Thirty',
      'example_usage': 'Trente jours.',
    },
    {
      'topic': 'numbers',
      'french': 'Cinquante',
      'english_translation': 'Fifty',
      'example_usage': 'Cinquante étoiles.',
    },
    {
      'topic': 'numbers',
      'french': 'Cent',
      'english_translation': 'One hundred',
      'example_usage': 'Cent personnes.',
    },
    {
      'topic': 'numbers',
      'french': 'Mille',
      'english_translation': 'One thousand',
      'example_usage': 'Mille mercis.',
    },

    // Colors (15 entries)
    {
      'topic': 'colors',
      'french': 'Rouge',
      'english_translation': 'Red',
      'example_usage': 'La tomate est rouge.',
    },
    {
      'topic': 'colors',
      'french': 'Bleu',
      'english_translation': 'Blue',
      'example_usage': 'Le ciel est bleu.',
    },
    {
      'topic': 'colors',
      'french': 'Vert',
      'english_translation': 'Green',
      'example_usage': 'L\'herbe est verte.',
    },
    {
      'topic': 'colors',
      'french': 'Jaune',
      'english_translation': 'Yellow',
      'example_usage': 'Le citron est jaune.',
    },
    {
      'topic': 'colors',
      'french': 'Orange',
      'english_translation': 'Orange',
      'example_usage': 'L\'orange est orange.',
    },
    {
      'topic': 'colors',
      'french': 'Violet',
      'english_translation': 'Purple',
      'example_usage': 'La fleur est violette.',
    },
    {
      'topic': 'colors',
      'french': 'Rose',
      'english_translation': 'Pink',
      'example_usage': 'La robe est rose.',
    },
    {
      'topic': 'colors',
      'french': 'Marron',
      'english_translation': 'Brown',
      'example_usage': 'Le chocolat est marron.',
    },
    {
      'topic': 'colors',
      'french': 'Gris',
      'english_translation': 'Gray',
      'example_usage': 'Le nuage est gris.',
    },
    {
      'topic': 'colors',
      'french': 'Noir',
      'english_translation': 'Black',
      'example_usage': 'La nuit est noire.',
    },
    {
      'topic': 'colors',
      'french': 'Blanc',
      'english_translation': 'White',
      'example_usage': 'Le lait est blanc.',
    },
    {
      'topic': 'colors',
      'french': 'Turquoise',
      'english_translation': 'Turquoise',
      'example_usage': 'La mer est turquoise.',
    },
    {
      'topic': 'colors',
      'french': 'Doré',
      'english_translation': 'Golden',
      'example_usage': 'L\'anneau est doré.',
    },
    {
      'topic': 'colors',
      'french': 'Argenté',
      'english_translation': 'Silver',
      'example_usage': 'Le bijou est argenté.',
    },
    {
      'topic': 'colors',
      'french': 'Beige',
      'english_translation': 'Beige',
      'example_usage': 'Le manteau est beige.',
    },

    // More Colors
    {
      'topic': 'colors',
      'french': 'Bordeaux',
      'english_translation': 'Burgundy',
      'example_usage': 'Un vin de couleur bordeaux.',
    },
    {
      'topic': 'colors',
      'french': 'Crème',
      'english_translation': 'Cream',
      'example_usage': 'Un mur de couleur crème.',
    },
    {
      'topic': 'colors',
      'french': 'Indigo',
      'english_translation': 'Indigo',
      'example_usage': 'Un jean indigo.',
    },
    {
      'topic': 'colors',
      'french': 'Lavande',
      'english_translation': 'Lavender',
      'example_usage': 'Les champs de lavande.',
    },
    {
      'topic': 'colors',
      'french': 'Saphir',
      'english_translation': 'Sapphire',
      'example_usage': 'Des yeux bleu saphir.',
    },

    // Grammar (20 entries)
    {
      'topic': 'grammar',
      'french': 'Le chat mange.',
      'english_translation': 'The cat eats.',
      'example_usage': 'Simple present tense.',
    },
    {
      'topic': 'grammar',
      'french': 'Je suis allé au magasin.',
      'english_translation': 'I went to the store.',
      'example_usage': 'Passé composé.',
    },
    {
      'topic': 'grammar',
      'french': 'La pomme est rouge.',
      'english_translation': 'The apple is red.',
      'example_usage': 'Adjective agreement.',
    },
    {
      'topic': 'grammar',
      'french': 'Les pommes sont rouges.',
      'english_translation': 'The apples are red.',
      'example_usage': 'Plural adjective.',
    },
    {
      'topic': 'grammar',
      'french': 'Mon livre est ici.',
      'english_translation': 'My book is here.',
      'example_usage': 'Possessive adjective.',
    },
    {
      'topic': 'grammar',
      'french': 'Ma maison est grande.',
      'english_translation': 'My house is big.',
      'example_usage': 'Feminine possessive.',
    },
    {
      'topic': 'grammar',
      'french': 'J\'aime le français.',
      'english_translation': 'I like French.',
      'example_usage': 'Definite article.',
    },
    {
      'topic': 'grammar',
      'french': 'J\'ai un chien.',
      'english_translation': 'I have a dog.',
      'example_usage': 'Indefinite article.',
    },
    {
      'topic': 'grammar',
      'french': 'Il y a du pain.',
      'english_translation': 'There is some bread.',
      'example_usage': 'Partitive article.',
    },
    {
      'topic': 'grammar',
      'french': 'Je vais au parc.',
      'english_translation': 'I go to the park.',
      'example_usage': 'Contraction au.',
    },
    {
      'topic': 'grammar',
      'french': 'De la ville.',
      'english_translation': 'From the city.',
      'example_usage': 'Contraction de la.',
    },
    {
      'topic': 'grammar',
      'french': 'Je ne sais pas.',
      'english_translation': 'I don\'t know.',
      'example_usage': 'Negation ne...pas.',
    },
    {
      'topic': 'grammar',
      'french': 'Où est le livre ?',
      'english_translation': 'Where is the book?',
      'example_usage': 'Question formation.',
    },
    {
      'topic': 'grammar',
      'french': 'Est-ce que tu viens ?',
      'english_translation': 'Are you coming?',
      'example_usage': 'Est-ce que question.',
    },
    {
      'topic': 'grammar',
      'french': 'Le livre que j\'ai lu.',
      'english_translation': 'The book that I read.',
      'example_usage': 'Relative pronoun que.',
    },
    {
      'topic': 'grammar',
      'french': 'La ville où je vis.',
      'english_translation': 'The city where I live.',
      'example_usage': 'Relative pronoun où.',
    },
    {
      'topic': 'grammar',
      'french': 'Je mange avant de sortir.',
      'english_translation': 'I eat before going out.',
      'example_usage': 'Infinitive clause.',
    },
    {
      'topic': 'grammar',
      'french': 'Il est plus grand que moi.',
      'english_translation': 'He is taller than me.',
      'example_usage': 'Comparative.',
    },
    {
      'topic': 'grammar',
      'french': 'Le plus beau jour.',
      'english_translation': 'The most beautiful day.',
      'example_usage': 'Superlative.',
    },
    {
      'topic': 'grammar',
      'french': 'Je l\'ai vu hier.',
      'english_translation': 'I saw it yesterday.',
      'example_usage': 'Object pronoun.',
    },

    // More Grammar
    {
      'topic': 'grammar',
      'french': 'Si j\'étais riche, j\'achèterais une voiture.',
      'english_translation': 'If I were rich, I would buy a car.',
      'example_usage': 'Conditional (si clause).',
    },
    {
      'topic': 'grammar',
      'french': 'Il faut que tu viennes.',
      'english_translation': 'It is necessary that you come.',
      'example_usage': 'Subjunctive with il faut que.',
    },
    {
      'topic': 'grammar',
      'french': 'Je viens de manger.',
      'english_translation': 'I have just eaten.',
      'example_usage': 'Recent past (venir de).',
    },
    {
      'topic': 'grammar',
      'french': 'Je suis en train de lire.',
      'english_translation': 'I am in the process of reading.',
      'example_usage': 'Present progressive (être en train de).',
    },
    {
      'topic': 'grammar',
      'french': 'Je vais parler.',
      'english_translation': 'I am going to speak.',
      'example_usage': 'Near future (aller + infinitive).',
    },
    {
      'topic': 'grammar',
      'french': 'La voiture de mon père.',
      'english_translation': 'My father\'s car.',
      'example_usage': 'Possession with de.',
    },
    {
      'topic': 'grammar',
      'french': 'C\'est un bon film.',
      'english_translation': 'It\'s a good film.',
      'example_usage': 'C\'est vs. Il est.',
    },
    {
      'topic': 'grammar',
      'french': 'Il est médecin.',
      'english_translation': 'He is a doctor.',
      'example_usage': 'Il est vs. C\'est.',
    },
    {
      'topic': 'grammar',
      'french': 'Je lui donne le livre.',
      'english_translation': 'I give him/her the book.',
      'example_usage': 'Indirect object pronoun.',
    },
    {
      'topic': 'grammar',
      'french': 'J\'y vais.',
      'english_translation': 'I\'m going there.',
      'example_usage': 'Adverbial pronoun y.',
    },
    {
      'topic': 'grammar',
      'french': 'J\'en veux.',
      'english_translation': 'I want some (of it).',
      'example_usage': 'Adverbial pronoun en.',
    },
    {
      'topic': 'grammar',
      'french': 'Ne... rien',
      'english_translation': 'Nothing',
      'example_usage': 'Je ne vois rien.',
    },
    {
      'topic': 'grammar',
      'french': 'Ne... personne',
      'english_translation': 'No one',
      'example_usage': 'Je ne vois personne.',
    },
    {
      'topic': 'grammar',
      'french': 'Ne... plus',
      'english_translation': 'No longer/Not anymore',
      'example_usage': 'Je ne fume plus.',
    },
    {
      'topic': 'grammar',
      'french': 'Ne... que',
      'english_translation': 'Only',
      'example_usage': 'Je n\'ai que dix euros.',
    },
    {
      'topic': 'grammar',
      'french': 'Le mien, la mienne.',
      'english_translation': 'Mine (masc./fem.)',
      'example_usage': 'Ce livre est le mien.',
    },
    {
      'topic': 'grammar',
      'french': 'Le tien, la tienne.',
      'english_translation': 'Yours (informal, masc./fem.)',
      'example_usage': 'Cette voiture est la tienne.',
    },
    {
      'topic': 'grammar',
      'french': 'Le sien, la sienne.',
      'english_translation': 'His/Hers (masc./fem.)',
      'example_usage': 'C\'est son problème, pas le sien.',
    },
    {
      'topic': 'grammar',
      'french': 'Le nôtre, la nôtre.',
      'english_translation': 'Ours (masc./fem.)',
      'example_usage': 'Notre maison est grande, la nôtre aussi.',
    },
    {
      'topic': 'grammar',
      'french': 'Le vôtre, la vôtre.',
      'english_translation': 'Yours (formal, masc./fem.)',
      'example_usage': 'Votre jardin est beau, et le vôtre ?',
    },
  ];

  /// Helper method to get examples by topic.
  static List<Map<String, dynamic>> getExamplesByTopic(String topic) {
    return examples.where((ex) => ex['topic'] == topic).toList();
  }

  /// Helper method to get all examples as a flat list (already the case).
  static List<Map<String, dynamic>> getAllExamples() {
    return List.from(examples);
  }
}
