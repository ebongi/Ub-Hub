import 'dart:math';

class Quote {
  final String text;
  final String author;

  Quote({required this.text, required this.author});
}

class QuoteService {
  static final List<Quote> _quotes = [
    Quote(
      text: "Education is the most powerful weapon which you can use to change the world.",
      author: "Nelson Mandela",
    ),
    Quote(
      text: "The beautiful thing about learning is that no one can take it away from you.",
      author: "B.B. King",
    ),
    Quote(
      text: "The mind is not a vessel to be filled but a fire to be ignited.",
      author: "Plutarch",
    ),
    Quote(
      text: "Live as if you were to die tomorrow. Learn as if you were to live forever.",
      author: "Mahatma Gandhi",
    ),
    Quote(
      text: "An investment in knowledge pays the best interest.",
      author: "Benjamin Franklin",
    ),
    Quote(
      text: "Education is the passport to the future, for tomorrow belongs to those who prepare for it today.",
      author: "Malcolm X",
    ),
    Quote(
      text: "Innovation distinguishes between a leader and a follower.",
      author: "Steve Jobs",
    ),
    Quote(
      text: "The best way to predict the future is to create it.",
      author: "Abraham Lincoln",
    ),
    Quote(
      text: "A person who never made a mistake never tried anything new.",
      author: "Albert Einstein",
    ),
    Quote(
      text: "Innovation is the ability to see change as an opportunity, not a threat.",
      author: "Steve Jobs",
    ),
    Quote(
      text: "The only way to discover the limits of the possible is to go beyond them into the impossible.",
      author: "Arthur C. Clarke",
    ),
    Quote(
      text: "It always seems impossible until it's done.",
      author: "Nelson Mandela",
    ),
    Quote(
      text: "Success is not final, failure is not fatal: it is the courage to continue that counts.",
      author: "Winston Churchill",
    ),
    Quote(
      text: "Intelligence plus character — that is the goal of true education.",
      author: "Martin Luther King Jr.",
    ),
    Quote(
      text: "Innovation is creativity with a job to do.",
      author: "John Emmerling",
    ),
  ];

  static Quote getRandomQuote() {
    final random = Random();
    return _quotes[random.nextInt(_quotes.length)];
  }
}
