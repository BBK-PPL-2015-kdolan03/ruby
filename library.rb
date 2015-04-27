class Calendar

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

  end

  #  Removes this Book object from the set of books checked out by this member
  # This may fail if the member does not have the book

   def give_back(book)
     if @books[b] == "Empty"
       raise "#{@name} trying to return a book they don't have!"
     end
     @books.delete(b)
   end

  # Returns the set of Book objects checked out to this member (may be the empty set)

  def get_books()
    return @books
  end

  # Tells this member that he/she has overdue books

  def send_overdue_notice(notice)
  end

end


class Library

    def initialize()
      @open = false
      @members = Hash.new("Unknown")
      @books = Hash.new("Empty")
      @nowServing = nil

      begin
        read_inventory
        @calendar = Calendar.new
      rescue Exception => msg
        puts msg
      end
    end

    # helper method to reduce typing

    def checkOpen
      if @open == false
        raise "Library closed"
      end
    end

    def read_inventory()
      begin
        arr = IO.readlines("/Users/keithdolan/Documents/collection.txt")
        arr.each { |x| words = x.split(/\,/)
            if words.length != 2
              raise "Inventory is corrupted"
            end
            b = Book.new(@books.length + 1, words[0], words[1])
            @books[@books.length + 1] = b
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
    end

    def find_all_overdue_books()
      checkOpen
      @outStr = ""
      @members.each { |m| m.get_books.each {
          |b| if b.get_due_date > @calendar.get_date then @outStr += "#{m.get_name}: #{b.to_s}" end }
        }
       if @outStr.length == 0
         return "No books are overdue."
       else
         return @outStr
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
      @book_count = 0
      @missing = []
      book_ids.each { |b| if @books[b] != "Empty"
                            @books[b].check_out(@calendar.get_date + 7)
                            @nowServing.check_out(@books[b])
                            @books.delete(b)
                            @book_count += 1
                          else
                            # May have already checked out some books and
                            # having one missing should not stop the others
                            # being check out. It's not all or nothing!
                            # The specification said "MAY throw an exception"
                            @missing << b
                            # raise "The library does not have book id #{b}."
                          end
                    }
        @retStr = "Checked out #{@book_count} book(s) to #{@nowServing.get_name}."
        if @missing.length > 0
          @retStr += " Unavailable books: "
          for i in 0..@missing.length - 1
            if i > 0 then @retStr += "," end
            @retStr += "#{@missing[i]}"
          end
        end

      return @retStr
    end


    def check_in(*book_numbers)
      checkOpen
      if @nowServing == nil
        raise "No member is currently being served."
       end
       @membersBooks = @nowServing.get_books
       @book_count = 0
       @unowned = []

       book_numbers.each { |b| if @membersBooks[b] != "Empty" && @books[b] == "Empty"
                                 @nowServing.give_back(b)
                                 @book_count += 1
                               else
                                 @failed << b
                               end
                         }


    end
    The book is being returned by the current member (there must be one!), so return it to the collection and remove it
     from the set of books currently checked out to the member. The book_numbers are
    taken from the list printed by the search command. Checking in a Book will involve both
     telling the Book that it is checked in and returning the Book to this library's collection of available Books.
    If successful, returns "name_of_member has returned n books.”.
    May throw an Exception with an appropriate message:
    • "The library is not open."
    • "No member is currently being served."
    • "The member does not have book id.”





    def find_overdue_books()
      checkOpen

    end

    def search(string)
      if string.length < 4
        return "Search string must contain at least four characters."
      end
      @outStr = ""
      @searchStr = string.downcase
      @books.each_value { |b| if (b.to_s.downcase).include? @searchStr then @outStr += b.to_s end }
      if @outStr.length == 0
        return "No books found."
      end
      return @outStr
    end

end


lib = Library.new
puts lib.open
begin
puts  lib.issue_card("Bruce Banner")
puts lib.search("KiTt")
puts lib.serve("Dr. Evil")
puts lib.serve("Bruce Banner")
puts lib.check_out(1,2)
puts lib.check_out(2,3,1)
puts lib.give_back
rescue Exception => msg
  puts "Oops! #{msg}"
end
