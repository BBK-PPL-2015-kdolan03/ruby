require 'singleton'

# ===================================================
# Class Calendar
# ===================================================

class Calendar

  include Singleton

  def initialize()
    @date = 0
  end

  def get_date()
    return @date
  end

  def advance()
    @date += 1
  end

end

# ===================================================
# Class Book
# ===================================================

class Book

  # The constructor. Saves the provided information.
  # When created, the book is not checked out.

  def initialize(id, title, author)
    @id = id
    @title = title
    @author = author
    @due_date = nil
  end

  # Returns this book's unique identification number

  def get_id
    return @id
  end

  # Returns this book's title

  def get_title
    return @title
  end

  # Returns this book's author

  def get_author
    return @author
  end

  # Returns the date (as an integer) that this book is due

  def get_due_date
    return @due_date
  end

  # Sets the due date of this Book. Doesn't return anything

  def check_out(due_date)
    @due_date = due_date
  end

  # Sets the due date of this Book to nil. Doesn't return anything

  def check_in
    @due_date = nil
  end

  # Returns a string of the form "id: title, by author”

    def to_s
      return "#{get_id}: #{get_title}, #{get_author}"
    end

end

# ===================================================
# Class Member
# ===================================================

class Member

  # Constructs a member with the given name, and no books.
  # The member must also have a reference to the Library object that he/she uses.

  def initialize(name, library)
    @name = name
    @library = library
    @books = Hash.new("Empty")
  end

  # Returns this member's name.

  def get_name()
    return @name
  end

  # Adds this Book object to the set of books checked out by this member

  def check_out(book)
    @books[book.get_id] = book
  end

  #  Removes this Book object from the set of books checked out by this member
  # This may fail if the member does not have the book

   def give_back(book)
     if @books[book] == "Empty"
       raise "#{@name} is trying to return a book they don't have!"
     end
     @books.delete(book)
   end

  # Returns the set of Book objects checked out to this member (may be the empty set)

  def get_books()
    return @books
  end

  # Tells this member that he/she has overdue books

  def send_overdue_notice(notice)
    puts "#{@name}: #{notice}"
  end

end

# ===================================================
# Class Library
# ===================================================

class Library

  include Singleton

  def initialize()
    @open = false
    @shut = false
    @members = Hash.new("Unknown")
    @books = Hash.new("Empty")
    @nowServing = nil

    begin
      read_inventory
      @calendar = Calendar.instance
    rescue Exception => msg
      puts msg
    end
  end

  # Helper method to reduce typing

  def checkOpen
    if @open == false  || @shut == true
      raise "Library closed"
    end
  end

  # Helper method to read in inventory

  def read_inventory()
    begin
      _arr = IO.readlines("/Users/keithdolan/Documents/collection.txt")
      _arr.each { |x| words = x.split(/\,/)
          if words.length != 2
            raise "Inventory is corrupted"
          end
          _b = Book.new(@books.length + 1, words[0], words[1])
          @books[@books.length + 1] = _b
      }
    rescue Exception => msg
     puts "Unable to get inventory: #{msg}."
    end
  end

  def open
    if @open == true
      raise "The library is already open!"
    else
       if @books.length == 0
         return "No inventory due to government cutbacks. Library closed"
       end
       @open = true
       @nowServing = nil
       @calendar.advance()
       return "Today is day #{@calendar.get_date}."
    end
  end

  def close
    if @open == false
      raise "The library is not open."
    end
    @open = false
    return "Good night."
  end

  def quit
    @shut = true
    return "The library is now closed for renovations."
  end

  def find_all_overdue_books()
    checkOpen
    _found = false
    _outStr = ""
    @members.each_value { |m| _obs = list_members_overdue_books(m)
                          if _obs.length > 0
                            _outStr += "#{m.get_name} has these books overdue:\n#{_obs} "
                            _found = true
                          end
                        }
    if @found == false
      return "No books are overdue."
    else
      return _outStr
    end
  end

  def issue_card(name_of_member)
    checkOpen
    if @members[name_of_member] == "Unknown"
      @members[name_of_member] = Member.new(name_of_member, self)
      return "Library card issued to #{name_of_member}."
    else
     return "#{name_of_member} already has a library card."
    end
  end

  def serve(name_of_member)
    checkOpen
    if @members[name_of_member] == "Unknown"
      return "#{name_of_member} does not have a library card."
    else
      @nowServing = @members[name_of_member]
      return "Now serving #{name_of_member}."
    end
  end

  def check_out(*book_ids)
    checkOpen
    if @nowServing == nil
      raise "No member is currently being served."
    end
    if @books.length == 0
      raise "No books left in the library"
    end
    _book_count = 0
    _missing = []
    book_ids.each { |b| if @books[b] != "Empty"
                          @books[b].check_out(@calendar.get_date + 7)
                          @nowServing.check_out(@books[b])
                          @books.delete(b)
                          _book_count += 1
                        else
                          # May have already checked out some books and
                          # having one missing should not stop the others
                          # being check out. It's not all or nothing!
                          # The specification said "MAY throw an exception"
                          _missing << b
                        end
                    }
    _retStr = "Checked out #{_book_count} book(s) to #{@nowServing.get_name}."
    if _missing.length > 0
      _retStr += " Unavailable books: "
      for i in 0.._missing.length - 1
        if i > 0 then _retStr += "," end
        _retStr += "#{_missing[i]}"
      end
    end

    return _retStr
  end


  def check_in(*book_numbers)
    checkOpen
    if @nowServing == nil
      raise "No member is currently being served."
    end
    _membersBooks = @nowServing.get_books
    if _membersBooks.length == 0
      raise "#{@nowServing.get_name} has no books checked out."
    end

    _book_count = 0
    _unowned = []
    _duplicated = []

    book_numbers.each { |b| if _membersBooks[b] != "Empty" && @books[b] == "Empty"
                              @nowServing.give_back(b.get_id)
                              @books[b].check_in
                              _book_count += 1
                            else
                              # As with check_out we may have already checked in some books.
                              # Accumulate the errors and report them
                              # Again, the specification said "MAY throw an exception"
                              if _membersBooks[b] == "Empty"
                                _unowned << b
                              else
                                _duplicated << b
                              end
                            end
                      }
    _retStr = "#{@nowServing.get_name} returned #{_book_count} book(s)."
    if _unowned.length > 0
      _retStr += "\n#{@nowServing.get_name} does not have book id(s): "
      for i in 0.._unowned.length - 1
        if i > 0 then _retStr += "," end
        _retStr += "#{_unowned[i]}"
      end
    end
    if _duplicated.length > 0
      _retStr += "\nDuplicated books: "
        for i in 0.._duplicated.length - 1
          if i > 0 then _retStr += "," end
          _retStr += "#{_duplicated[i]}"
      end
    end

    return _retStr
  end

  def find_overdue_books()
    checkOpen
    if @nowServing == nil
      raise "No member is currently being served."
    end
    _ob = list_members_overdue_books(@nowServing)
    if _ob.length == 0
      _ob = "None"
    end
    _ob
  end

  def list_members_overdue_books(member)
    _outStr = ""
    member.get_books.each_value { |b| if b.get_due_date < @calendar.get_date then _outStr += b.to_s end }
    _outStr
  end

  def search(string)
    checkOpen
    if string.length < 4
      return "Search string must contain at least four characters."
    end
    _outStr = ""
    _searchStr = string.downcase
    @books.each_value { |b| if (b.to_s.downcase).include? _searchStr then _outStr += b.to_s end }
    if _outStr.length == 0
      return "No books found."
    end
    return _outStr
  end

end

# ===================================================
# Test
# ===================================================

lib = Library.instance

begin
  puts lib.open
  puts lib.issue_card("Bruce Banner")
  puts lib.search("KiTt")
  puts lib.serve("Dr. Evil")
  puts lib.serve("Bruce Banner")
  puts lib.check_out(1,2)
  puts lib.check_out(2,3,1)
  puts lib.check_in(4)
  for i in 0..6
    puts lib.close
    puts lib.open
  end
  puts lib.serve("Bruce Banner")
  puts lib.find_overdue_books()
  puts lib.find_all_overdue_books()
  for i in 0..3
    puts lib.close
    puts lib.open
  end
  puts lib.serve("Bruce Banner")
  puts lib.find_overdue_books()
  puts lib.find_all_overdue_books()
rescue Exception => msg
  puts "Oops! #{msg}"
end
