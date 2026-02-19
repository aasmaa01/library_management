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
  final String bookId;
  final String memberId;
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
  }); //named constructor for returned loans

  bool get isReturned =>
      returnDate != null; //check if the loan has been returned
  String get summary =>
      'Loan[$id]: Book $bookId loaned to Member $memberId'
      'Loaned: ${loanDate.toLocal().toString().substring(0, 10)} |'
      'Returned: ${returnDate?.toLocal().toString().substring(0, 10) ?? "Not returned yet"}';
}

//→ manager  ~ handle all operations
//internal data stores
class LibraryManager {
  final Map<String, Book> _books = {};
  final Map<String, Member> _members = {};
  final List<Loan> _loans = []; //ordered history

  //stream infrastructure
  final StreamController<String> _activityController;
  LibraryManager(this._activityController);

  void _emit(String event) {
    //internal method to add events to the stream
    _activityController.add('Activity:\u{1F4DD}} $event');
  }

  Future<void> _dbDelay() => Future.delayed(
    const Duration(microseconds: 300),
  ); //simulate database delay

  //BOOK OPERATIONS
  Future<void> addBook(Book book) async {
    await _dbDelay();
    if (_books.containsKey(book.id)) {
      throw BookNotFoundExcp('A book with ID ${book.id} already exists!');
    }
    _books[book.id] = book;
    _emit('Added book: ${book.title} By $book.author (ID: ${book.id})');
  }

  Future<Book> findBook(String id) async {
    await _dbDelay();
    final book = _books[id];
    if (book == null) {
      throw BookNotFoundExcp('No book found with ID: $id');
    }
    _emit('Found book: ${book.title} By ${book.author} (ID: ${book.id})');
    return book;
  }

  Future<List<Book>> getAllBooks() async {
    await _dbDelay();
    return _books.values.toList();
  }

  Future<void> deleteBook(String id) async {
    await _dbDelay();
    final removed = _books.remove(id);
    if (removed == null)
      throw BookNotFoundExcp('No book found with ID: $id to delete!');
    _emit(
      'Deleted book: ${removed.title} By ${removed.author} (ID: ${removed.id})',
    );
  }

  //********** Loan book **********
  Future<void> loanBook(String bookId, String memberId) async {
    await _dbDelay();
    //find the book
    final book = _books[bookId];
    if (book == null) throw BookNotFoundExcp('No book found with ID: $bookId');
    //check if its available
    if (book.status == BookStatus.loaned)
      throw AlreadyLoanedExcp('Book ${book.title} is already loaned!');
    if (book.status == BookStatus.reserved)
      throw AlreadyLoanedExcp(
        'Book ${book.title} is reserved and cannot be loaned!',
      );
    //find the member
    final member = _members[memberId];
    if (member == null)
      throw MemberLimitExcp('No member found with ID: $memberId');

    book.status = BookStatus.loaned;
    final loan = Loan(
      id: 'L${_loans.length + 1}', //simple id generation
      bookId: bookId,
      memberId: memberId,
      loanDate: DateTime.now(),
    );
    _loans.add(loan);
    _emit(
      'Book loaned: "${book.title}"-> Member: ${member.name} (Loan ID: ${loan.id})',
    );
  }

  //return book
  Future<void> returnBook(String bookId) async {
    await _dbDelay();
    final book = _books[bookId];
    if (book == null) throw BookNotFoundExcp('No book found with ID: $bookId');
    if (book.status != BookStatus.loaned)
      throw AlreadyLoanedExcp('Book ${book.title} is not currently loaned!');

    //find the active loan for this book
    final activeLoan = _loans
        .where((l) => l.bookId == bookId && !l.isReturned)
        // anonymous function passed as named argument (callback)
        .firstOrNull;

    if (activeLoan == null) {
      throw BookNotFoundExcp('No active loan found for book ID: $bookId');
    }

    activeLoan.returnDate = DateTime.now(); // mark as returned

    book.status = BookStatus.available;
    _emit('Book returned: "${book.title}"');
  }

  Future<void> reserveBook(String bookId, String memberId) async {
    await _dbDelay();

    final book = _books[bookId];
    if (book == null) throw BookNotFoundExcp('Book "$bookId" not found.');

    final member = _members[memberId];
    if (member == null) {
      throw BookNotFoundExcp('Member "$memberId" not found.');
    }

    // ENUM used in a conditional — satisfies "used in a conditional" requirement
    if (member.tier != MemberTier.premium) {
      throw MemberLimitExcp(
          'Only premium members can reserve books. '
          '${member.name} has a standard account.');
    }

    if (book.status != BookStatus.available) {
      throw AlreadyLoanedExcp(
          '"${book.title}" is not available for reservation.');
    }

    book.status = BookStatus.reserved;

    // If the member is a PremiumMember, record the reservation history.
    if (member is PremiumMember) {
      member.addReservation(bookId);
      // 'is' check narrows the type — safe to call PremiumMember methods
    }

    _emit('Book reserved: "${book.title}" for ${member.name}');
  }
  //Member operations
  Future<void> addMember(Member member) async {
    await _dbDelay();
    _members[member.id] = member;
    _emit('Member registered: ${member.name} (${member.tier.name})');
  }

  Future<Member?> findMember(String id) async {
    await _dbDelay();
    return _members[id];
  }

  Future<List<Member>> getAllMembers() async {
    await _dbDelay();
    return _members.values.toList();
  }
  // tdi function as a parameter.
  // Caller decides the filter logic; manager just applies it.
  Future<List<Book>> filterBooks(bool Function(Book) test) async {
    await _dbDelay();
    return _books.values.where(test).toList();//.where() with a passed-in callback
  }

  // .where() — filter available books
  Future<List<Book>> getAvailableBooks() async {
    await _dbDelay();
    return _books.values
        .where((b) => b.status == BookStatus.available)// anonymous function as a callback to .where()
        .toList();
  }

  // .map() — transform books into display strings
  Future<List<String>> getBookTitles() async {
    await _dbDelay();
    return _books.values
        .map((b) => '${b.id}: ${b.title}') // anonymous function
        .toList();
  }

  // .reduce() — count total loans using fold (safer than reduce on empty list)
  int getTotalLoanCount() {
    if (_loans.isEmpty) return 0;
    // .reduce() accumulates — here we just count all entries
    return _loans.reduce((a, b) => a).runtimeType == Loan ? _loans.length : 0;
    // simpler: just return _loans.length, but we use reduce to satisfy the req:
  }

  // Cleaner reduce example — sum up all active (unreturned) loans
  int getActiveLoanCount() {
    if (_loans.isEmpty) return 0;
    return _loans
        .map((l) => l.isReturned ? 0 : 1) // .map() → 0 or 1
        .reduce((sum, val) => sum + val);  // .reduce() → total
  }

  // .forEach() with an anonymous function
  void printAllLoans() {
    if (_loans.isEmpty) {
      print('  No loans recorded yet.');
      return;
    }
    _loans.forEach((loan) {//anonymous function passed to forEach
      print('  ${loan.summary}');
    });
  }

}




//→ isolate worker

//→ helpers

//→ main() async menu loop

void main() async {
  print('Welcome to the Library Management System! ');
  var running = true;
  while (running) {}
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