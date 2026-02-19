import 'dart:async';
import 'dart:isolate';
import 'dart:io';
//we have local library.!
//The librarian needs to manage books
/*
What owns the StreamController?

Where does the Isolate get triggered?

Who throws exceptions?

Who catches them?

Who converts objects to Map?
 */
//Manage books - books i think ndirhom f Map<int, Book>

//Manage members (people who borrow books)

//Track loans (borrowed books)

//Handle reservations (books held for members)

//enums ~ Book status (available, borrowed, reserved) ~ Member status (active, inactive) ~ Loan status (active, overdue, returned) ~ Reservation status (active, fulfilled, cancelled)

enum BookStatus {
  //its life -> available -> loaned  -> available-> reserved
  available, // on the shelf, anyone can borrow it
  loaned, // currently borrowed by a member
  reserved, // held for a specific premium member
}

enum MemberTier {
  standard,
  premium,
} // premium can reserve books, standard cannot

//→ exceptions ~ Custom errors
class BookNotFoundExcp implements Exception {
  //loan,find, return a book id that doesnt exist in my map
  final String message;
  const BookNotFoundExcp(this.message);

  @override
  String toString() => 'BookNotFoundExcp: $message';
}

class AlreadyLoanedExcp implements Exception {
  //when loan a book whose status already BookStatus.loaned
  final String message;
  const AlreadyLoanedExcp(this.message);

  @override
  String toString() => 'AlreadyLoanedExcp: $message';
}

class MemberLimitExcp implements Exception {
  final String message;
  const MemberLimitExcp(this.message);

  @override
  String toString() => 'MemberLimitExcp: $message';
}

//→ mixins ~
mixin Loggable {
  void log(String message) {
    //print a formated message with timestamp
    print("\u{1F4DD} [${DateTime.now()}] $message");
  }
}
mixin Timestamped {
  final DateTime createdAt = DateTime.now();
  //auto set to now
}

//→ abstract
abstract class Item {
  final String id;
  final String title;

  Item(this.id, this.title);
  void displayInfo() {
    print("ID: $id, Title: $title");
  }

  //abstract method
  String get details;
}

abstract class Person {
  final String id;
  String name;

  Person(this.id, this.name);

  //abstract method
  String get contactInfo;
}

//searchable interface
abstract class IsSearchable {
  bool matches(String query);
}

//→ classes Book, Member, Loan
class Book extends Item with Loggable, Timestamped implements IsSearchable {
  final String author;
  final Set<String>
  genres; //crime, fiction, mystery, science, history, religion
  BookStatus status;
  String? description; //can be null

  Book(
    String id,
    String title,
    this.author, {
    required this.genres,
    this.status = BookStatus.available,
    this.description,
  }) : super(id, title);

  Book.mystery(String id, String title, String author)
    : author = author,
      genres = {'Mystery'},
      status = BookStatus.available,
      description = null,
      super(id, title);

  @override
  String get details =>
      "Book \u{1F4D6} : $title by $author | Status: ${status.name.toUpperCase()} | Genres: ${genres.join(', ')} | ${description ?? 'No description'}";

  @override
  bool matches(String query) =>
      title.toLowerCase().contains(query.toLowerCase()) ||
      author.toLowerCase().contains(query.toLowerCase()); //search by title or author

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'author': author,
    'genres': genres.toList(),
    'status': status.name,
    'description': description,
  };

  factory Book.fromMap(Map<String, dynamic> map) {
    //convert a Map back to a Book object
    return Book(
      map['id'] as String,
      map['title'] as String,
      map['author'] as String,
      genres: Set<String>.from(map['genres'] as List),
      status: BookStatus.values.byName(map['status'] as String),
      description: map['description'] as String?,
    );
  }
}

class Member extends Person with Loggable, Timestamped {
  final String email;
  final MemberTier tier; //standard or premium

  Member(String id, String name, this.email, this.tier) : super(id, name);

  Member.premium(String id, String name, String email)
    : email = email,
      tier = MemberTier.premium,
      super(id, name);

  @override
  String get contactInfo =>
      "Member \u{1F464} : $name | Email: $email | Tier: ${tier.name.toUpperCase()}";
}

class PremiumMember extends Member {
  final List<String> reservationHistory = [];

  PremiumMember(String id, String name, String email)
    : super.premium(id, name, email);

  @override
  String get contactInfo => '${super.contactInfo}  Premium Member \u{1F451}';

  void addReservation(String bookId) {
    reservationHistory.add(bookId);
    log("Added reservation for book ID: $bookId to member $name's history.");
  }

  void cancelReservation(String bookId) {
    reservationHistory.remove(bookId);
    log(
      "Cancelled reservation for book ID: $bookId from member $name's history.",
    );
  }
}

class Loan with Timestamped {
  final String id;
  final int bookId;
  final int memberId;
  final DateTime loanDate;
  DateTime? returnDate; //can be null if not returned yet

  Loan({
    required this.id,
    required this.bookId,
    required this.memberId,
    required this.loanDate,
  });

  Loan.returned({
    required this.id,
    required this.bookId,
    required this.memberId,
    required this.loanDate,
    required this.returnDate,
  });//named constructor for returned loans

  bool get isReturned => returnDate != null;//check if the loan has been returned
  String get summary=>
    'Loan[$id]: Book $bookId loaned to Member $memberId'
    'Loaned: ${loanDate.toLocal().toString().substring(0, 10)} |'
    'Returned: ${returnDate?.toLocal().toString().substring(0, 10) ?? "Not returned yet"}';
}

//→ manager  ~ handle all operations

//→ isolate worker

//→ helpers

//→ main() async menu loop

void main(List<String> arguments) {
  print('Welcome to the Library Management System! ');
  //Map<String, dynamic>
  //DATA — Books in Map, Loans in List, Members in Map

  //menu options : add/update/find/delete book, loans, members, reservations
}
 

 /*
 Domain Layer
  - Enums
  - Exceptions
  - Abstract base
  - Mixins
  - Entities

Application Layer
  - LibraryManager
  - Repository logic

Infrastructure Layer
  - Stream logging
  - Isolate worker

Presentation Layer
  - Console menu

  */