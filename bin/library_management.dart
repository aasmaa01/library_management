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
enum BookStatus { available, loaned, reserved } //its life -> available -> loaned  -> available-> reserved 

enum MemberTier { standard, premium } // 

//→ exceptions ~ Custom errors
class BookNotFoundExcp implements Exception { //loan,find, return a book id that doesnt exist in my map 
  String message;
  BookNotFoundExcp(this.message);
}
class AlreadyLoanedExcp implements Exception{
  //when loan a book whose status already BookStatus.loaned
  String message;
  AlreadyLoanedExcp(this.message);

}

//→ mixins ~
mixin Loggable{
  void log(String message){
    //print a formated message with timestamp
    print("[${DateTime.now()}] $message");
  }
}
mixin Timestamped{
  DateTime createdAt = DateTime.now();
  //auto set to now 
  
}

//→ abstract
abstract class LibraryItem{
  int id;
  String title;

  LibraryItem(this.id, this.title);

  //abstract method
  String get details();
}
abstract class Person{
  int id;
  String name;

  Person(this.id, this.name);

  //abstract method
  String get contactInfo();
}

//→ classes Book, Member, Loan...
class Book extends LibraryItem implements Comparable<Book> with Loggable, Timestamped {
  String author;
  BookStatus status;
  String? description; //can be null

}

class Member extends Person with Loggable, Timestamped {
  int id;
  String name;
  String email;
  MemberTier tier; //standard or premium

  Member(int id, String title, this.name, this.email, this.tier) : super(id, title);
}

class Loan {
  int id;
  int bookId;
  int memberId;
  DateTime loanDate;
  DateTime? returnDate; //can be null if not returned yet
}

//→ manager  ~ handle all operations

//→ isolate worker

//→ helpers

//→ main() async menu loop
const version= '0.0.1';
 void printUsage(){
  print("hejeje: 'help', 'version', 'search <ARTICLE-TITLE>'");
 }
void main(List<String> arguments) {
  print('Welcome to the Library Management System! ');
  List<String> books=['Murder on the orient Express', 'Death on the Nile','The zahir', 'الداء والدواء'];
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