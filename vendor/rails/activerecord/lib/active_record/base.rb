require 'yaml'
require 'set'

module ActiveRecord #:nodoc:
  # Generic ActiveRecord exception class.
  class ActiveRecordError < StandardError
  end

  # Raised when the single-table inheritance mechanism failes to locate the subclass
  # (for example due to improper usage of column that +inheritance_column+ points to).
  class SubclassNotFound < ActiveRecordError #:nodoc:
  end

  # Raised when object assigned to association is of incorrect type.
  #
  # Example:
  #
  # class Ticket < ActiveRecord::Base
  #   has_many :patches
  # end
  #
  # class Patch < ActiveRecord::Base
  #   belongs_to :ticket
  # end
  #
  # and somewhere in the code:
  #
  # @ticket.patches << Comment.new(:content => "Please attach tests to your patch.")
  # @ticket.save
  class AssociationTypeMismatch < ActiveRecordError
  end

  # Raised when unserialized object's type mismatches one specified for serializable field.
  class SerializationTypeMismatch < ActiveRecordError
  end

  # Raised when adapter not specified on connection (or configuration file config/database.yml misses adapter field).
  class AdapterNotSpecified < ActiveRecordError
  end

  # Raised when ActiveRecord cannot find database adapter specified in config/database.yml or programmatically.
  class AdapterNotFound < ActiveRecordError
  end

  # Raised when connection to the database could not been established (for example when connection= is given a nil object).
  class ConnectionNotEstablished < ActiveRecordError
  end

  # Raised when ActiveRecord cannot find record by given id or set of ids.
  class RecordNotFound < ActiveRecordError
  end

  # Raised by ActiveRecord::Base.save! and ActiveRecord::Base.create! methods when record cannot be
  # saved because record is invalid.
  class RecordNotSaved < ActiveRecordError
  end

  # Raised when SQL statement cannot be executed by the database (for example, it's often the case for MySQL when Ruby driver used is too old).
  class StatementInvalid < ActiveRecordError
  end

  # Raised when number of bind variables in statement given to :condition key (for example, when using +find+ method)
  # does not match number of expected variables.
  #
  # Example:
  #
  # Location.find :all, :conditions => ["lat = ? AND lng = ?", 53.7362]
  #
  # in example above two placeholders are given but only one variable to fill them.
  class PreparedStatementInvalid < ActiveRecordError
  end

  # Raised on attempt to save stale record. Record is stale when it's being saved in another query after
  # instantiation, for example, when two users edit the same wiki page and one starts editing and saves
  # the page before the other.
  #
  # Read more about optimistic locking in +ActiveRecord::Locking+ module RDoc.
  class StaleObjectError < ActiveRecordError
  end

  # Raised when association is being configured improperly or
  # user tries to use offset and limit together with has_many or has_and_belongs_to_many associations.
  class ConfigurationError < ActiveRecordError
  end

  # Raised on attempt to update record that is instantiated as read only.
  class ReadOnlyRecord < ActiveRecordError
  end

  # Used by ActiveRecord transaction mechanism to distinguish rollback from other exceptional situations.
  # You can use it to roll your transaction back explicitly in the block passed to +transaction+ method.
  class Rollback < ActiveRecordError
  end

  # Raised when attribute has a name reserved by ActiveRecord (when attribute has name of one of ActiveRecord instance methods).
  class DangerousAttributeError < ActiveRecordError
  end

  # Raised when you've tried to access a column which wasn't
  # loaded by your finder.  Typically this is because :select
  # has been specified
  class MissingAttributeError < NoMethodError
  end

  class AttributeAssignmentError < ActiveRecordError #:nodoc:
    attr_reader :exception, :attribute
    def initialize(message, exception, attribute)
      @exception = exception
      @attribute = attribute
      @message = message
    end
  end

  class MultiparameterAssignmentErrors < ActiveRecordError #:nodoc:
    attr_reader :errors
    def initialize(errors)
      @errors = errors
    end
  end

  # Active Record objects don't specify their attributes directly, but rather infer them from the table definition with
  # which they're linked. Adding, removing, and changing attributes and their type is done directly in the database. Any change
  # is instantly reflected in the Active Record objects. The mapping that binds a given Active Record class to a certain
  # database table will happen automatically in most common cases, but can be overwritten for the uncommon ones.
  #
  # See the mapping rules in table_name and the full example in link:files/README.html for more insight.
  #
  # == Creation
  #
  # Active Records accept constructor parameters either in a hash or as a block. The hash method is especially useful when
  # you're receiving the data from somewhere else, like an HTTP request. It works like this:
  #
  #   user = User.new(:name => "David", :occupation => "Code Artist")
  #   user.name # => "David"
  #
  # You can also use block initialization:
  #
  #   user = User.new do |u|
  #     u.name = "David"
  #     u.occupation = "Code Artist"
  #   end
  #
  # And of course you can just create a bare object and specify the attributes after the fact:
  #
  #   user = User.new
  #   user.name = "David"
  #   user.occupation = "Code Artist"
  #
  # == Conditions
  #
  # Conditions can either be specified as a string, array, or hash representing the WHERE-part of an SQL statement.
  # The array form is to be used when the condition input is tainted and requires sanitization. The string form can
  # be used for statements that don't involve tainted data. The hash form works much like the array form, except
  # only equality and range is possible. Examples:
  #
  #   class User < ActiveRecord::Base
  #     def self.authenticate_unsafely(user_name, password)
  #       find(:first, :conditions => "user_name = '#{user_name}' AND password = '#{password}'")
  #     end
  #
  #     def self.authenticate_safely(user_name, password)
  #       find(:first, :conditions => [ "user_name = ? AND password = ?", user_name, password ])
  #     end
  #
  #     def self.authenticate_safely_simply(user_name, password)
  #       find(:first, :conditions => { :user_name => user_name, :password => password })
  #     end
  #   end
  #
  # The <tt>authenticate_unsafely</tt> method inserts the parameters directly into the query and is thus susceptible to SQL-injection
  # attacks if the <tt>user_name</tt> and +password+ parameters come directly from an HTTP request. The <tt>authenticate_safely</tt>  and
  # <tt>authenticate_safely_simply</tt> both will sanitize the <tt>user_name</tt> and +password+ before inserting them in the query,
  # which will ensure that an attacker can't escape the query and fake the login (or worse).
  #
  # When using multiple parameters in the conditions, it can easily become hard to read exactly what the fourth or fifth
  # question mark is supposed to represent. In those cases, you can resort to named bind variables instead. That's done by replacing
  # the question marks with symbols and supplying a hash with values for the matching symbol keys:
  #
  #   Company.find(:first, :conditions => [
  #     "id = :id AND name = :name AND division = :division AND created_at > :accounting_date",
  #     { :id => 3, :name => "37signals", :division => "First", :accounting_date => '2005-01-01' }
  #   ])
  #
  # Similarly, a simple hash without a statement will generate conditions based on equality with the SQL AND
  # operator. For instance:
  #
  #   Student.find(:all, :conditions => { :first_name => "Harvey", :status => 1 })
  #   Student.find(:all, :conditions => params[:student])
  #
  # A range may be used in the hash to use the SQL BETWEEN operator:
  #
  #   Student.find(:all, :conditions => { :grade => 9..12 })
  #
  # == Overwriting default accessors
  #
  # All column values are automatically available through basic accessors on the Active Record object, but sometimes you
  # want to specialize this behavior. This can be done by overwriting the default accessors (using the same
  # name as the attribute) and calling read_attribute(attr_name) and write_attribute(attr_name, value) to actually change things.
  # Example:
  #
  #   class Song < ActiveRecord::Base
  #     # Uses an integer of seconds to hold the length of the song
  #
  #     def length=(minutes)
  #       write_attribute(:length, minutes * 60)
  #     end
  #
  #     def length
  #       read_attribute(:length) / 60
  #     end
  #   end
  #
  # You can alternatively use self[:attribute]=(value) and self[:attribute] instead of write_attribute(:attribute, value) and
  # read_attribute(:attribute) as a shorter form.
  #
  # == Attribute query methods
  #
  # In addition to the basic accessors, query methods are also automatically available on the Active Record object.
  # Query methods allow you to test whether an attribute value is present.
  #
  # For example, an Active Record User with the <tt>name</tt> attribute has a <tt>name?</tt> method that you can call
  # to determine whether the user has a name:
  #
  #   user = User.new(:name => "David")
  #   user.name? # => true
  #
  #   anonymous = User.new(:name => "")
  #   anonymous.name? # => false
  #
  # == Accessing attributes before they have been typecasted
  #
  # Sometimes you want to be able to read the raw attribute data without having the column-determined typecast run its course first.
  # That can be done by using the <attribute>_before_type_cast accessors that all attributes have. For example, if your Account model
  # has a balance attribute, you can call account.balance_before_type_cast or account.id_before_type_cast.
  #
  # This is especially useful in validation situations where the user might supply a string for an integer field and you want to display
  # the original string back in an error message. Accessing the attribute normally would typecast the string to 0, which isn't what you
  # want.
  #
  # == Dynamic attribute-based finders
  #
  # Dynamic attribute-based finders are a cleaner way of getting (and/or creating) objects by simple queries without turning to SQL. They work by
  # appending the name of an attribute to <tt>find_by_</tt> or <tt>find_all_by_</tt>, so you get finders like Person.find_by_user_name,
  # Person.find_all_by_last_name, Payment.find_by_transaction_id. So instead of writing
  # <tt>Person.find(:first, :conditions => ["user_name = ?", user_name])</tt>, you just do <tt>Person.find_by_user_name(user_name)</tt>.
  # And instead of writing <tt>Person.find(:all, :conditions => ["last_name = ?", last_name])</tt>, you just do <tt>Person.find_all_by_last_name(last_name)</tt>.
  #
  # It's also possible to use multiple attributes in the same find by separating them with "_and_", so you get finders like
  # <tt>Person.find_by_user_name_and_password</tt> or even <tt>Payment.find_by_purchaser_and_state_and_country</tt>. So instead of writing
  # <tt>Person.find(:first, :conditions => ["user_name = ? AND password = ?", user_name, password])</tt>, you just do
  # <tt>Person.find_by_user_name_and_password(user_name, password)</tt>.
  #
  # It's even possible to use all the additional parameters to find. For example, the full interface for Payment.find_all_by_amount
  # is actually Payment.find_all_by_amount(amount, options). And the full interface to Person.find_by_user_name is
  # actually Person.find_by_user_name(user_name, options). So you could call <tt>Payment.find_all_by_amount(50, :order => "created_on")</tt>.
  #
  # The same dynamic finder style can be used to create the object if it doesn't already exist. This dynamic finder is called with
  # <tt>find_or_create_by_</tt> and will return the object if it already exists and otherwise creates it, then returns it. Example:
  #
  #   # No 'Summer' tag exists
  #   Tag.find_or_create_by_name("Summer") # equal to Tag.create(:name => "Summer")
  #
  #   # Now the 'Summer' tag does exist
  #   Tag.find_or_create_by_name("Summer") # equal to Tag.find_by_name("Summer")
  #
  # Use the <tt>find_or_initialize_by_</tt> finder if you want to return a new record without saving it first. Example:
  #
  #   # No 'Winter' tag exists
  #   winter = Tag.find_or_initialize_by_name("Winter")
  #   winter.new_record? # true
  #
  # To find by a subset of the attributes to be used for instantiating a new object, pass a hash instead of
  # a list of parameters. For example:
  #
  #   Tag.find_or_create_by_name(:name => "rails", :creator => current_user)
  #
  # That will either find an existing tag named "rails", or create a new one while setting the user that created it.
  #
  # == Saving arrays, hashes, and other non-mappable objects in text columns
  #
  # Active Record can serialize any object in text columns using YAML. To do so, you must specify this with a call to the class method +serialize+.
  # This makes it possible to store arrays, hashes, and other non-mappable objects without doing any additional work. Example:
  #
  #   class User < ActiveRecord::Base
  #     serialize :preferences
  #   end
  #
  #   user = User.create(:preferences => { "background" => "black", "display" => large })
  #   User.find(user.id).preferences # => { "background" => "black", "display" => large }
  #
  # You can also specify a class option as the second parameter that'll raise an exception if a serialized object is retrieved as a
  # descendent of a class not in the hierarchy. Example:
  #
  #   class User < ActiveRecord::Base
  #     serialize :preferences, Hash
  #   end
  #
  #   user = User.create(:preferences => %w( one two three ))
  #   User.find(user.id).preferences    # raises SerializationTypeMismatch
  #
  # == Single table inheritance
  #
  # Active Record allows inheritance by storing the name of the class in a column that by default is named "type" (can be changed
  # by overwriting <tt>Base.inheritance_column</tt>). This means that an inheritance looking like this:
  #
  #   class Company < ActiveRecord::Base; end
  #   class Firm < Company; end
  #   class Client < Company; end
  #   class PriorityClient < Client; end
  #
  # When you do Firm.create(:name => "37signals"), this record will be saved in the companies table with type = "Firm". You can then
  # fetch this row again using Company.find(:first, "name = '37signals'") and it will return a Firm object.
  #
  # If you don't have a type column defined in your table, single-table inheritance won't be triggered. In that case, it'll work just
  # like normal subclasses with no special magic for differentiating between them or reloading the right type with find.
  #
  # Note, all the attributes for all the cases are kept in the same table. Read more:
  # http://www.martinfowler.com/eaaCatalog/singleTableInheritance.html
  #
  # == Connection to multiple databases in different models
  #
  # Connections are usually created through ActiveRecord::Base.establish_connection and retrieved by ActiveRecord::Base.connection.
  # All classes inheriting from ActiveRecord::Base will use this connection. But you can also set a class-specific connection.
  # For example, if Course is an ActiveRecord::Base, but resides in a different database, you can just say Course.establish_connection
  # and Course *and all its subclasses* will use this connection instead.
  #
  # This feature is implemented by keeping a connection pool in ActiveRecord::Base that is a Hash indexed by the class. If a connection is
  # requested, the retrieve_connection method will go up the class-hierarchy until a connection is found in the connection pool.
  #
  # == Exceptions
  #
  # * +ActiveRecordError+ -- generic error class and superclass of all other errors raised by Active Record
  # * +AdapterNotSpecified+ -- the configuration hash used in <tt>establish_connection</tt> didn't include an
  #   <tt>:adapter</tt> key.
  # * +AdapterNotFound+ -- the <tt>:adapter</tt> key used in <tt>establish_connection</tt> specified a non-existent adapter
  #   (or a bad spelling of an existing one).
  # * +AssociationTypeMismatch+ -- the object assigned to the association wasn't of the type specified in the association definition.
  # * +SerializationTypeMismatch+ -- the serialized object wasn't of the class specified as the second parameter.
  # * +ConnectionNotEstablished+ -- no connection has been established. Use <tt>establish_connection</tt> before querying.
  # * +RecordNotFound+ -- no record responded to the find* method.
  #   Either the row with the given ID doesn't exist or the row didn't meet the additional restrictions.
  # * +StatementInvalid+ -- the database server rejected the SQL statement. The precise error is added in the  message.
  #   Either the record with the given ID doesn't exist or the record didn't meet the additional restrictions.
  # * +MultiparameterAssignmentErrors+ -- collection of errors that occurred during a mass assignment using the
  #   +attributes=+ method. The +errors+ property of this exception contains an array of +AttributeAssignmentError+
  #   objects that should be inspected to determine which attributes triggered the errors.
  # * +AttributeAssignmentError+ -- an error occurred while doing a mass assignment through the +attributes=+ method.
  #   You can inspect the +attribute+ property of the exception object to determine which attribute triggered the error.
  #
  # *Note*: The attributes listed are class-level attributes (accessible from both the class and instance level).
  # So it's possible to assign a logger to the class through Base.logger= which will then be used by all
  # instances in the current object space.
  class Base
    # Accepts a logger conforming to the interface of Log4r or the default Ruby 1.8+ Logger class, which is then passed
    # on to any new database connections made and which can be retrieved on both a class and instance level by calling +logger+.
    cattr_accessor :logger, :instance_writer => false

    def self.inherited(child) #:nodoc:
      @@subclasses[self] ||= []
      @@subclasses[self] << child
      super
    end

    def self.reset_subclasses #:nodoc:
      nonreloadables = []
      subclasses.each do |klass|
        unless Dependencies.autoloaded? klass
          nonreloadables << klass
          next
        end
        klass.instance_variables.each { |var| klass.send(:remove_instance_variable, var) }
        klass.instance_methods(false).each { |m| klass.send :undef_method, m }
      end
      @@subclasses = {}
      nonreloadables.each { |klass| (@@subclasses[klass.superclass] ||= []) << klass }
    end

    @@subclasses = {}

    cattr_accessor :configurations, :instance_writer => false
    @@configurations = {}

    # Accessor for the prefix type that will be prepended to every primary key column name. The options are :table_name and
    # :table_name_with_underscore. If the first is specified, the Product class will look for "productid" instead of "id" as
    # the primary column. If the latter is specified, the Product class will look for "product_id" instead of "id". Remember
    # that this is a global setting for all Active Records.
    cattr_accessor :primary_key_prefix_type, :instance_writer => false
    @@primary_key_prefix_type = nil

    # Accessor for the name of the prefix string to prepend to every table name. So if set to "basecamp_", all
    # table names will be named like "basecamp_projects", "basecamp_people", etc. This is a convenient way of creating a namespace
    # for tables in a shared database. By default, the prefix is the empty string.
    cattr_accessor :table_name_prefix, :instance_writer => false
    @@table_name_prefix = ""

    # Works like +table_name_prefix+, but appends instead of prepends (set to "_basecamp" gives "projects_basecamp",
    # "people_basecamp"). By default, the suffix is the empty string.
    cattr_accessor :table_name_suffix, :instance_writer => false
    @@table_name_suffix = ""

    # Indicates whether table names should be the pluralized versions of the corresponding class names.
    # If true, the default table name for a +Product+ class will be +products+. If false, it would just be +product+.
    # See table_name for the full rules on table/class naming. This is true, by default.
    cattr_accessor :pluralize_table_names, :instance_writer => false
    @@pluralize_table_names = true

    # Determines whether to use ANSI codes to colorize the logging statements committed by the connection adapter. These colors
    # make it much easier to overview things during debugging (when used through a reader like +tail+ and on a black background), but
    # may complicate matters if you use software like syslog. This is true, by default.
    cattr_accessor :colorize_logging, :instance_writer => false
    @@colorize_logging = true

    # Determines whether to use Time.local (using :local) or Time.utc (using :utc) when pulling dates and times from the database.
    # This is set to :local by default.
    cattr_accessor :default_timezone, :instance_writer => false
    @@default_timezone = :local

    # Determines whether to use a connection for each thread, or a single shared connection for all threads.
    # Defaults to false. Set to true if you're writing a threaded application.
    cattr_accessor :allow_concurrency, :instance_writer => false
    @@allow_concurrency = false

    # Specifies the format to use when dumping the database schema with Rails'
    # Rakefile.  If :sql, the schema is dumped as (potentially database-
    # specific) SQL statements.  If :ruby, the schema is dumped as an
    # ActiveRecord::Schema file which can be loaded into any database that
    # supports migrations.  Use :ruby if you want to have different database
    # adapters for, e.g., your development and test environments.
    cattr_accessor :schema_format , :instance_writer => false
    @@schema_format = :ruby

    class << self # Class methods
      # Find operates with three different retrieval approaches:
      #
      # * Find by id: This can either be a specific id (1), a list of ids (1, 5, 6), or an array of ids ([5, 6, 10]).
      #   If no record can be found for all of the listed ids, then RecordNotFound will be raised.
      # * Find first: This will return the first record matched by the options used. These options can either be specific
      #   conditions or merely an order. If no record can be matched, nil is returned.
      # * Find all: This will return all the records matched by the options used. If no records are found, an empty array is returned.
      #
      # All approaches accept an options hash as their last parameter. The options are:
      #
      # * <tt>:conditions</tt>: An SQL fragment like "administrator = 1" or [ "user_name = ?", username ]. See conditions in the intro.
      # * <tt>:order</tt>: An SQL fragment like "created_at DESC, name".
      # * <tt>:group</tt>: An attribute name by which the result should be grouped. Uses the GROUP BY SQL-clause.
      # * <tt>:limit</tt>: An integer determining the limit on the number of rows that should be returned.
      # * <tt>:offset</tt>: An integer determining the offset from where the rows should be fetched. So at 5, it would skip rows 0 through 4.
      # * <tt>:joins</tt>: Either an SQL fragment for additional joins like "LEFT JOIN comments ON comments.post_id = id" (rarely needed)
      #   or named associations in the same form used for the :include option, which will perform an INNER JOIN on the associated table(s).
      #   If the value is a string, then the records will be returned read-only since they will have attributes that do not correspond to the table's columns.
      #   Pass :readonly => false to override.
      # * <tt>:include</tt>: Names associations that should be loaded alongside using LEFT OUTER JOINs. The symbols named refer
      #   to already defined associations. See eager loading under Associations.
      # * <tt>:select</tt>: By default, this is * as in SELECT * FROM, but can be changed if you, for example, want to do a join but not
      #   include the joined columns.
      # * <tt>:from</tt>: By default, this is the table name of the class, but can be changed to an alternate table name (or even the name
      #   of a database view).
      # * <tt>:readonly</tt>: Mark the returned records read-only so they cannot be saved or updated.
      # * <tt>:lock</tt>: An SQL fragment like "FOR UPDATE" or "LOCK IN SHARE MODE".
      #   :lock => true gives connection's default exclusive lock, usually "FOR UPDATE".
      #
      # Examples for find by id:
      #   Person.find(1)       # returns the object for ID = 1
      #   Person.find(1, 2, 6) # returns an array for objects with IDs in (1, 2, 6)
      #   Person.find([7, 17]) # returns an array for objects with IDs in (7, 17)
      #   Person.find([1])     # returns an array for the object with ID = 1
      #   Person.find(1, :conditions => "administrator = 1", :order => "created_on DESC")
      #
      # Note that returned records may not be in the same order as the ids you
      # provide since database rows are unordered. Give an explicit :order
      # to ensure the results are sorted.
      #
      # Examples for find first:
      #   Person.find(:first) # returns the first object fetched by SELECT * FROM people
      #   Person.find(:first, :conditions => [ "user_name = ?", user_name])
      #   Person.find(:first, :order => "created_on DESC", :offset => 5)
      #
      # Examples for find all:
      #   Person.find(:all) # returns an array of objects for all the rows fetched by SELECT * FROM people
      #   Person.find(:all, :conditions => [ "category IN (?)", categories], :limit => 50)
      #   Person.find(:all, :offset => 10, :limit => 10)
      #   Person.find(:all, :include => [ :account, :friends ])
      #   Person.find(:all, :group => "category")
      #
      # Example for find with a lock. Imagine two concurrent transactions:
      # each will read person.visits == 2, add 1 to it, and save, resulting
      # in two saves of person.visits = 3.  By locking the row, the second
      # transaction has to wait until the first is finished; we get the
      # expected person.visits == 4.
      #   Person.transaction do
      #     person = Person.find(1, :lock => true)
      #     person.visits += 1
      #     person.save!
      #   end
      def find(*args)
        options = args.extract_options!
        validate_find_options(options)
        set_readonly_option!(options)

        case args.first
          when :first then find_initial(options)
          when :all   then find_every(options)
          else             find_from_ids(args, options)
        end
      end

      #
      # Executes a custom sql query against your database and returns all the results.  The results will
      # be returned as an array with columns requested encapsulated as attributes of the model you call
      # this method from.  If you call +Product.find_by_sql+ then the results will be returned in a Product
      # object with the attributes you specified in the SQL query.
      #
      # If you call a complicated SQL query which spans multiple tables the columns specified by the
      # SELECT will be attributes of the model, whether or not they are columns of the corresponding
      # table.
      #
      # The +sql+ parameter is a full sql query as a string.  It will be called as is, there will be
      # no database agnostic conversions performed.  This should be a last resort because using, for example,
      # MySQL specific terms will lock you to using that particular database engine or require you to
      # change your call if you switch engines
      #
      # ==== Examples
      #   # A simple sql query spanning multiple tables
      #   Post.find_by_sql "SELECT p.title, c.author FROM posts p, comments c WHERE p.id = c.post_id"
      #   > [#<Post:0x36bff9c @attributes={"title"=>"Ruby Meetup", "first_name"=>"Quentin"}>, ...]
      #
      #   # You can use the same string replacement techniques as you can with ActiveRecord#find
      #   Post.find_by_sql ["SELECT title FROM posts WHERE author = ? AND created > ?", author_id, start_date]
      #   > [#<Post:0x36bff9c @attributes={"first_name"=>"The Cheap Man Buys Twice"}>, ...]
      def find_by_sql(sql)
        connection.select_all(sanitize_sql(sql), "#{name} Load").collect! { |record| instantiate(record) }
      end

      # Checks whether a record exists in the database that matches conditions given.  These conditions
      # can either be a single integer representing a primary key id to be found, or a condition to be
      # matched like using ActiveRecord#find.
      #
      # The +id_or_conditions+ parameter can be an Integer or a String if you want to search the primary key
      # column of the table for a matching id, or if you're looking to match against a condition you can use
      # an Array or a Hash.
      #
      # Possible gotcha: You can't pass in a condition as a string e.g. "name = 'Jamie'", this would be
      # sanitized and then queried against the primary key column as "id = 'name = \'Jamie"
      #
      # ==== Examples
      #   Person.exists?(5)
      #   Person.exists?('5')
      #   Person.exists?(:name => "David")
      #   Person.exists?(['name LIKE ?', "%#{query}%"])
      def exists?(id_or_conditions)
        connection.select_all(
          construct_finder_sql(
            :select     => "#{quoted_table_name}.#{primary_key}", 
            :conditions => expand_id_conditions(id_or_conditions), 
            :limit      => 1
          ), 
          "#{name} Exists"
        ).size > 0
      end

      # Creates an object (or multiple objects) and saves it to the database, if validations pass.
      # The resulting object is returned whether the object was saved successfully to the database or not.
      #
      # The +attributes+ parameter can be either be a Hash or an Array of Hashes.  These Hashes describe the
      # attributes on the objects that are to be created.
      #
      # ==== Examples
      #   # Create a single new object
      #   User.create(:first_name => 'Jamie')
      #   # Create an Array of new objects
      #   User.create([{:first_name => 'Jamie'}, {:first_name => 'Jeremy'}])
      def create(attributes = nil)
        if attributes.is_a?(Array)
          attributes.collect { |attr| create(attr) }
        else
          object = new(attributes)
          object.save
          object
        end
      end

      # Updates an object (or multiple objects) and saves it to the database, if validations pass.
      # The resulting object is returned whether the object was saved successfully to the database or not.
      #
      # ==== Options
      #
      # +id+          This should be the id or an array of ids to be updated
      # +attributes+  This should be a Hash of attributes to be set on the object, or an array of Hashes.
      #
      # ==== Examples
      #
      #   # Updating one record:
      #   Person.update(15, {:user_name => 'Samuel', :group => 'expert'})
      #
      #   # Updating multiple records:
      #   people = { 1 => { "first_name" => "David" }, 2 => { "first_name" => "Jeremy"} }
      #   Person.update(people.keys, people.values)
      def update(id, attributes)
        if id.is_a?(Array)
          idx = -1
          id.collect { |one_id| idx += 1; update(one_id, attributes[idx]) }
        else
          object = find(id)
          object.update_attributes(attributes)
          object
        end
      end

      # Delete an object (or multiple objects) where the +id+ given matches the primary_key.  A SQL +DELETE+ command
      # is executed on the database which means that no callbacks are fired off running this.  This is an efficient method
      # of deleting records that don't need cleaning up after or other actions to be taken.
      #
      # Objects are _not_ instantiated with this method.
      #
      # ==== Options
      #
      # +id+  Can be either an Integer or an Array of Integers
      #
      # ==== Examples
      #
      #   # Delete a single object
      #   Todo.delete(1)
      #
      #   # Delete multiple objects
      #   todos = [1,2,3]
      #   Todo.delete(todos)
      def delete(id)
        delete_all([ "#{connection.quote_column_name(primary_key)} IN (?)", id ])
      end

      # Destroy an object (or multiple objects) that has the given id, the object is instantiated first,
      # therefore all callbacks and filters are fired off before the object is deleted.  This method is
      # less efficient than ActiveRecord#delete but allows cleanup methods and other actions to be run.
      #
      # This essentially finds the object (or multiple objects) with the given id, creates a new object
      # from the attributes, and then calls destroy on it.
      #
      # ==== Options
      #
      # +id+  Can be either an Integer or an Array of Integers
      #
      # ==== Examples
      #
      #   # Destroy a single object
      #   Todo.destroy(1)
      #
      #   # Destroy multiple objects
      #   todos = [1,2,3]
      #   Todo.destroy(todos)
      def destroy(id)
        if id.is_a?(Array)
          id.map { |one_id| destroy(one_id) }
        else
          find(id).destroy
        end
      end

      # Updates all records with details given if they match a set of conditions supplied, limits and order can
      # also be supplied.
      #
      # ==== Options
      #
      # +updates+     A String of column and value pairs that will be set on any records that match conditions
      # +conditions+  An SQL fragment like "administrator = 1" or [ "user_name = ?", username ].
      #               See conditions in the intro for more info.
      # +options+     Additional options are :limit and/or :order, see the examples for usage.
      #
      # ==== Examples
      #
      #   # Update all billing objects with the 3 different attributes given
      #   Billing.update_all( "category = 'authorized', approved = 1, author = 'David'" )
      #
      #   # Update records that match our conditions
      #   Billing.update_all( "author = 'David'", "title LIKE '%Rails%'" )
      #
      #   # Update records that match our conditions but limit it to 5 ordered by date
      #   Billing.update_all( "author = 'David'", "title LIKE '%Rails%'",
      #                         :order => 'created_at', :limit => 5 )
      def update_all(updates, conditions = nil, options = {})
        sql  = "UPDATE #{quoted_table_name} SET #{sanitize_sql_for_assignment(updates)} "
        scope = scope(:find)
        add_conditions!(sql, conditions, scope)
        add_order!(sql, options[:order], nil)
        add_limit!(sql, options, nil)
        connection.update(sql, "#{name} Update")
      end

      # Destroys the records matching +conditions+ by instantiating each record and calling the destroy method.
      # This means at least 2*N database queries to destroy N records, so avoid destroy_all if you are deleting
      # many records. If you want to simply delete records without worrying about dependent associations or
      # callbacks, use the much faster +delete_all+ method instead.
      #
      # ==== Options
      #
      # +conditions+   Conditions are specified the same way as with +find+ method.
      #
      # ==== Example
      #
      #   Person.destroy_all "last_login < '2004-04-04'"
      #
      # This loads and destroys each person one by one, including its dependent associations and before_ and
      # after_destroy callbacks.
      def destroy_all(conditions = nil)
        find(:all, :conditions => conditions).each { |object| object.destroy }
      end

      # Deletes the records matching +conditions+ without instantiating the records first, and hence not
      # calling the destroy method and invoking callbacks. This is a single SQL query, much more efficient
      # than destroy_all.
      #
      # ==== Options
      #
      # +conditions+   Conditions are specified the same way as with +find+ method.
      #
      # ==== Example
      #
      #   Post.delete_all "person_id = 5 AND (category = 'Something' OR category = 'Else')"
      #
      # This deletes the affected posts all at once with a single DELETE query. If you need to destroy dependent
      # associations or call your before_ or after_destroy callbacks, use the +destroy_all+ method instead.
      def delete_all(conditions = nil)
        sql = "DELETE FROM #{quoted_table_name} "
        add_conditions!(sql, conditions, scope(:find))
        connection.delete(sql, "#{name} Delete all")
      end

      # Returns the result of an SQL statement that should only include a COUNT(*) in the SELECT part.
      # The use of this method should be restricted to complicated SQL queries that can't be executed
      # using the ActiveRecord::Calculations class methods.  Look into those before using this.
      #
      # ==== Options
      #
      # +sql+: An SQL statement which should return a count query from the database, see the example below
      #
      # ==== Examples
      #
      #   Product.count_by_sql "SELECT COUNT(*) FROM sales s, customers c WHERE s.customer_id = c.id"
      def count_by_sql(sql)
        sql = sanitize_conditions(sql)
        connection.select_value(sql, "#{name} Count").to_i
      end

      # A generic "counter updater" implementation, intended primarily to be
      # used by increment_counter and decrement_counter, but which may also
      # be useful on its own. It simply does a direct SQL update for the record
      # with the given ID, altering the given hash of counters by the amount
      # given by the corresponding value:
      #
      # ==== Options
      #
      # +id+        The id of the object you wish to update a counter on
      # +counters+  An Array of Hashes containing the names of the fields
      #             to update as keys and the amount to update the field by as
      #             values
      #
      # ==== Examples
      #
      #   # For the Post with id of 5, decrement the comment_count by 1, and
      #   # increment the action_count by 1
      #   Post.update_counters 5, :comment_count => -1, :action_count => 1
      #   # Executes the following SQL:
      #   # UPDATE posts
      #   #    SET comment_count = comment_count - 1,
      #   #        action_count = action_count + 1
      #   #  WHERE id = 5
      def update_counters(id, counters)
        updates = counters.inject([]) { |list, (counter_name, increment)|
          sign = increment < 0 ? "-" : "+"
          list << "#{connection.quote_column_name(counter_name)} = #{connection.quote_column_name(counter_name)} #{sign} #{increment.abs}"
        }.join(", ")
        update_all(updates, "#{connection.quote_column_name(primary_key)} = #{quote_value(id)}")
      end

      # Increment a number field by one, usually representing a count.
      #
      # This is used for caching aggregate values, so that they don't need to be computed every time.
      # For example, a DiscussionBoard may cache post_count and comment_count otherwise every time the board is
      # shown it would have to run an SQL query to find how many posts and comments there are.
      #
      # ==== Options
      #
      # +counter_name+  The name of the field that should be incremented
      # +id+            The id of the object that should be incremented
      #
      # ==== Examples
      #
      #   # Increment the post_count column for the record with an id of 5
      #   DiscussionBoard.increment_counter(:post_count, 5)
      def increment_counter(counter_name, id)
        update_counters(id, counter_name => 1)
      end

      # Decrement a number field by one, usually representing a count.
      #
      # This works the same as increment_counter but reduces the column value by 1 instead of increasing it.
      #
      # ==== Options
      #
      # +counter_name+  The name of the field that should be decremented
      # +id+            The id of the object that should be decremented
      #
      # ==== Examples
      #
      #   # Decrement the post_count column for the record with an id of 5
      #   DiscussionBoard.decrement_counter(:post_count, 5)
      def decrement_counter(counter_name, id)
        update_counters(id, counter_name => -1)
      end


      # Attributes named in this macro are protected from mass-assignment, such as <tt>new(attributes)</tt> and
      # <tt>attributes=(attributes)</tt>. Their assignment will simply be ignored. Instead, you can use the direct writer
      # methods to do assignment. This is meant to protect sensitive attributes from being overwritten by URL/form hackers. Example:
      #
      #   class Customer < ActiveRecord::Base
      #     attr_protected :credit_rating
      #   end
      #
      #   customer = Customer.new("name" => David, "credit_rating" => "Excellent")
      #   customer.credit_rating # => nil
      #   customer.attributes = { "description" => "Jolly fellow", "credit_rating" => "Superb" }
      #   customer.credit_rating # => nil
      #
      #   customer.credit_rating = "Average"
      #   customer.credit_rating # => "Average"
      #
      # To start from an all-closed default and enable attributes as needed, have a look at attr_accessible.
      def attr_protected(*attributes)
        write_inheritable_attribute("attr_protected", Set.new(attributes.map(&:to_s)) + (protected_attributes || []))
      end

      # Returns an array of all the attributes that have been protected from mass-assignment.
      def protected_attributes # :nodoc:
        read_inheritable_attribute("attr_protected")
      end

      # Similar to the attr_protected macro, this protects attributes of your model from mass-assignment,
      # such as <tt>new(attributes)</tt> and <tt>attributes=(attributes)</tt>
      # however, it does it in the opposite way.  This locks all attributes and only allows access to the
      # attributes specified.  Assignment to attributes not in this list will be ignored and need to be set
      # using the direct writer methods instead.  This is meant to protect sensitive attributes from being
      # overwritten by URL/form hackers. If you'd rather start from an all-open default and restrict
      # attributes as needed, have a look at attr_protected.
      #
      # ==== Options
      #
      # <tt>*attributes</tt>   A comma separated list of symbols that represent columns _not_ to be protected
      #
      # ==== Examples
      #
      #   class Customer < ActiveRecord::Base
      #     attr_accessible :name, :nickname
      #   end
      #
      #   customer = Customer.new(:name => "David", :nickname => "Dave", :credit_rating => "Excellent")
      #   customer.credit_rating # => nil
      #   customer.attributes = { :name => "Jolly fellow", :credit_rating => "Superb" }
      #   customer.credit_rating # => nil
      #
      #   customer.credit_rating = "Average"
      #   customer.credit_rating # => "Average"
      def attr_accessible(*attributes)
        write_inheritable_attribute("attr_accessible", Set.new(attributes.map(&:to_s)) + (accessible_attributes || []))
      end

      # Returns an array of all the attributes that have been made accessible to mass-assignment.
      def accessible_attributes # :nodoc:
        read_inheritable_attribute("attr_accessible")
      end

       # Attributes listed as readonly can be set for a new record, but will be ignored in database updates afterwards.
       def attr_readonly(*attributes)
         write_inheritable_attribute("attr_readonly", Set.new(attributes.map(&:to_s)) + (readonly_attributes || []))
       end

       # Returns an array of all the attributes that have been specified as readonly.
       def readonly_attributes
         read_inheritable_attribute("attr_readonly")
       end

      # If you have an attribute that needs to be saved to the database as an object, and retrieved as the same object,
      # then specify the name of that attribute using this method and it will be handled automatically.
      # The serialization is done through YAML. If +class_name+ is specified, the serialized object must be of that
      # class on retrieval or +SerializationTypeMismatch+ will be raised.
      #
      # ==== Options
      #
      # +attr_name+   The field name that should be serialized
      # +class_name+  Optional, class name that the object type should be equal to
      #
      # ==== Example
      #   # Serialize a preferences attribute
      #   class User
      #     serialize :preferences
      #   end
      def serialize(attr_name, class_name = Object)
        serialized_attributes[attr_name.to_s] = class_name
      end

      # Returns a hash of all the attributes that have been specified for serialization as keys and their class restriction as values.
      def serialized_attributes
        read_inheritable_attribute("attr_serialized") or write_inheritable_attribute("attr_serialized", {})
      end


      # Guesses the table name (in forced lower-case) based on the name of the class in the inheritance hierarchy descending
      # directly from ActiveRecord. So if the hierarchy looks like: Reply < Message < ActiveRecord, then Message is used
      # to guess the table name even when called on Reply. The rules used to do the guess are handled by the Inflector class
      # in Active Support, which knows almost all common English inflections. You can add new inflections in config/initializers/inflections.rb.
      #
      # Nested classes are given table names prefixed by the singular form of
      # the parent's table name. Enclosing modules are not considered. Examples:
      #
      #   class Invoice < ActiveRecord::Base; end;
      #   file                  class               table_name
      #   invoice.rb            Invoice             invoices
      #
      #   class Invoice < ActiveRecord::Base; class Lineitem < ActiveRecord::Base; end; end;
      #   file                  class               table_name
      #   invoice.rb            Invoice::Lineitem   invoice_lineitems
      #
      #   module Invoice; class Lineitem < ActiveRecord::Base; end; end;
      #   file                  class               table_name
      #   invoice/lineitem.rb   Invoice::Lineitem   lineitems
      #
      # Additionally, the class-level table_name_prefix is prepended and the
      # table_name_suffix is appended.  So if you have "myapp_" as a prefix,
      # the table name guess for an Invoice class becomes "myapp_invoices".
      # Invoice::Lineitem becomes "myapp_invoice_lineitems".
      #
      # You can also overwrite this class method to allow for unguessable
      # links, such as a Mouse class with a link to a "mice" table. Example:
      #
      #   class Mouse < ActiveRecord::Base
      #     set_table_name "mice"
      #   end
      def table_name
        reset_table_name
      end

      def reset_table_name #:nodoc:
        base = base_class

        name =
          # STI subclasses always use their superclass' table.
          unless self == base
            base.table_name
          else
            # Nested classes are prefixed with singular parent table name.
            if parent < ActiveRecord::Base && !parent.abstract_class?
              contained = parent.table_name
              contained = contained.singularize if parent.pluralize_table_names
              contained << '_'
            end
            name = "#{table_name_prefix}#{contained}#{undecorated_table_name(base.name)}#{table_name_suffix}"
          end

        set_table_name(name)
        name
      end

      # Defines the primary key field -- can be overridden in subclasses. Overwriting will negate any effect of the
      # primary_key_prefix_type setting, though.
      def primary_key
        reset_primary_key
      end

      def reset_primary_key #:nodoc:
        key = 'id'
        case primary_key_prefix_type
          when :table_name
            key = Inflector.foreign_key(base_class.name, false)
          when :table_name_with_underscore
            key = Inflector.foreign_key(base_class.name)
        end
        set_primary_key(key)
        key
      end

      # Defines the column name for use with single table inheritance
      # -- can be set in subclasses like so: self.inheritance_column = "type_id"
      def inheritance_column
        @inheritance_column ||= "type".freeze
      end

      # Lazy-set the sequence name to the connection's default.  This method
      # is only ever called once since set_sequence_name overrides it.
      def sequence_name #:nodoc:
        reset_sequence_name
      end

      def reset_sequence_name #:nodoc:
        default = connection.default_sequence_name(table_name, primary_key)
        set_sequence_name(default)
        default
      end

      # Sets the table name to use to the given value, or (if the value
      # is nil or false) to the value returned by the given block.
      #
      # Example:
      #
      #   class Project < ActiveRecord::Base
      #     set_table_name "project"
      #   end
      def set_table_name(value = nil, &block)
        define_attr_method :table_name, value, &block
      end
      alias :table_name= :set_table_name

      # Sets the name of the primary key column to use to the given value,
      # or (if the value is nil or false) to the value returned by the given
      # block.
      #
      # Example:
      #
      #   class Project < ActiveRecord::Base
      #     set_primary_key "sysid"
      #   end
      def set_primary_key(value = nil, &block)
        define_attr_method :primary_key, value, &block
      end
      alias :primary_key= :set_primary_key

      # Sets the name of the inheritance column to use to the given value,
      # or (if the value # is nil or false) to the value returned by the
      # given block.
      #
      # Example:
      #
      #   class Project < ActiveRecord::Base
      #     set_inheritance_column do
      #       original_inheritance_column + "_id"
      #     end
      #   end
      def set_inheritance_column(value = nil, &block)
        define_attr_method :inheritance_column, value, &block
      end
      alias :inheritance_column= :set_inheritance_column

      # Sets the name of the sequence to use when generating ids to the given
      # value, or (if the value is nil or false) to the value returned by the
      # given block. This is required for Oracle and is useful for any
      # database which relies on sequences for primary key generation.
      #
      # If a sequence name is not explicitly set when using Oracle or Firebird,
      # it will default to the commonly used pattern of: #{table_name}_seq
      #
      # If a sequence name is not explicitly set when using PostgreSQL, it
      # will discover the sequence corresponding to your primary key for you.
      #
      # Example:
      #
      #   class Project < ActiveRecord::Base
      #     set_sequence_name "projectseq"   # default would have been "project_seq"
      #   end
      def set_sequence_name(value = nil, &block)
        define_attr_method :sequence_name, value, &block
      end
      alias :sequence_name= :set_sequence_name

      # Turns the +table_name+ back into a class name following the reverse rules of +table_name+.
      def class_name(table_name = table_name) # :nodoc:
        # remove any prefix and/or suffix from the table name
        class_name = table_name[table_name_prefix.length..-(table_name_suffix.length + 1)].camelize
        class_name = class_name.singularize if pluralize_table_names
        class_name
      end

      # Indicates whether the table associated with this class exists
      def table_exists?
        if connection.respond_to?(:tables)
          connection.tables.include? table_name
        else
          # if the connection adapter hasn't implemented tables, there are two crude tests that can be
          # used - see if getting column info raises an error, or if the number of columns returned is zero
          begin
            reset_column_information
            columns.size > 0
          rescue ActiveRecord::StatementInvalid
            false
          end
        end
      end

      # Returns an array of column objects for the table associated with this class.
      def columns
        unless defined?(@columns) && @columns
          @columns = connection.columns(table_name, "#{name} Columns")
          @columns.each { |column| column.primary = column.name == primary_key }
        end
        @columns
      end

      # Returns a hash of column objects for the table associated with this class.
      def columns_hash
        @columns_hash ||= columns.inject({}) { |hash, column| hash[column.name] = column; hash }
      end

      # Returns an array of column names as strings.
      def column_names
        @column_names ||= columns.map { |column| column.name }
      end

      # Returns an array of column objects where the primary id, all columns ending in "_id" or "_count",
      # and columns used for single table inheritance have been removed.
      def content_columns
        @content_columns ||= columns.reject { |c| c.primary || c.name =~ /(_id|_count)$/ || c.name == inheritance_column }
      end

      # Returns a hash of all the methods added to query each of the columns in the table with the name of the method as the key
      # and true as the value. This makes it possible to do O(1) lookups in respond_to? to check if a given method for attribute
      # is available.
      def column_methods_hash #:nodoc:
        @dynamic_methods_hash ||= column_names.inject(Hash.new(false)) do |methods, attr|
          attr_name = attr.to_s
          methods[attr.to_sym]       = attr_name
          methods["#{attr}=".to_sym] = attr_name
          methods["#{attr}?".to_sym] = attr_name
          methods["#{attr}_before_type_cast".to_sym] = attr_name
          methods
        end
      end

      # Resets all the cached information about columns, which will cause them to be reloaded on the next request.
      def reset_column_information
        generated_methods.each { |name| undef_method(name) }
        @column_names = @columns = @columns_hash = @content_columns = @dynamic_methods_hash = @generated_methods = @inheritance_column = nil
      end

      def reset_column_information_and_inheritable_attributes_for_all_subclasses#:nodoc:
        subclasses.each { |klass| klass.reset_inheritable_attributes; klass.reset_column_information }
      end

      # Transforms attribute key names into a more humane format, such as "First name" instead of "first_name". Example:
      #   Person.human_attribute_name("first_name") # => "First name"
      # Deprecated in favor of just calling "first_name".humanize
      def human_attribute_name(attribute_key_name) #:nodoc:
        attribute_key_name.humanize
      end

      # True if this isn't a concrete subclass needing a STI type condition.
      def descends_from_active_record?
        if superclass.abstract_class?
          superclass.descends_from_active_record?
        else
          superclass == Base || !columns_hash.include?(inheritance_column)
        end
      end

      def finder_needs_type_condition? #:nodoc:
        # This is like this because benchmarking justifies the strange :false stuff
        :true == (@finder_needs_type_condition ||= descends_from_active_record? ? :false : :true)
      end

      # Returns a string like 'Post id:integer, title:string, body:text'
      def inspect
        if self == Base
          super
        elsif abstract_class?
          "#{super}(abstract)"
        elsif table_exists?
          attr_list = columns.map { |c| "#{c.name}: #{c.type}" } * ', '
          "#{super}(#{attr_list})"
        else
          "#{super}(Table doesn't exist)"
        end
      end


      def quote_value(value, column = nil) #:nodoc:
        connection.quote(value,column)
      end

      # Used to sanitize objects before they're used in an SQL SELECT statement. Delegates to <tt>connection.quote</tt>.
      def sanitize(object) #:nodoc:
        connection.quote(object)
      end

      # Log and benchmark multiple statements in a single block. Example:
      #
      #   Project.benchmark("Creating project") do
      #     project = Project.create("name" => "stuff")
      #     project.create_manager("name" => "David")
      #     project.milestones << Milestone.find(:all)
      #   end
      #
      # The benchmark is only recorded if the current level of the logger is less than or equal to the <tt>log_level</tt>,
      # which makes it easy to include benchmarking statements in production software that will remain inexpensive because
      # the benchmark will only be conducted if the log level is low enough.
      #
      # The logging of the multiple statements is turned off unless <tt>use_silence</tt> is set to false.
      def benchmark(title, log_level = Logger::DEBUG, use_silence = true)
        if logger && logger.level <= log_level
          result = nil
          seconds = Benchmark.realtime { result = use_silence ? silence { yield } : yield }
          logger.add(log_level, "#{title} (#{'%.5f' % seconds})")
          result
        else
          yield
        end
      end

      # Silences the logger for the duration of the block.
      def silence
        old_logger_level, logger.level = logger.level, Logger::ERROR if logger
        yield
      ensure
        logger.level = old_logger_level if logger
      end

      # Overwrite the default class equality method to provide support for association proxies.
      def ===(object)
        object.is_a?(self)
      end

      # Returns the base AR subclass that this class descends from. If A
      # extends AR::Base, A.base_class will return A. If B descends from A
      # through some arbitrarily deep hierarchy, B.base_class will return A.
      def base_class
        class_of_active_record_descendant(self)
      end

      # Set this to true if this is an abstract class (see #abstract_class?).
      attr_accessor :abstract_class

      # Returns whether this class is a base AR class.  If A is a base class and
      # B descends from A, then B.base_class will return B.
      def abstract_class?
        defined?(@abstract_class) && @abstract_class == true
      end

      private
        def find_initial(options)
          options.update(:limit => 1) unless options[:include]
          find_every(options).first
        end

        def find_every(options)
          include_associations = merge_includes(scope(:find, :include), options[:include])

          if include_associations.any? && references_eager_loaded_tables?(options)
            records = find_with_associations(options)
          else
            records = find_by_sql(construct_finder_sql(options))
            if include_associations.any?
              preload_associations(records, include_associations)
            end
          end

          records.each { |record| record.readonly! } if options[:readonly]

          records
        end

        def find_from_ids(ids, options)
          expects_array = ids.first.kind_of?(Array)
          return ids.first if expects_array && ids.first.empty?

          ids = ids.flatten.compact.uniq

          case ids.size
            when 0
              raise RecordNotFound, "Couldn't find #{name} without an ID"
            when 1
              result = find_one(ids.first, options)
              expects_array ? [ result ] : result
            else
              find_some(ids, options)
          end
        end

        def find_one(id, options)
          conditions = " AND (#{sanitize_sql(options[:conditions])})" if options[:conditions]
          options.update :conditions => "#{quoted_table_name}.#{connection.quote_column_name(primary_key)} = #{quote_value(id,columns_hash[primary_key])}#{conditions}"

          # Use find_every(options).first since the primary key condition
          # already ensures we have a single record. Using find_initial adds
          # a superfluous :limit => 1.
          if result = find_every(options).first
            result
          else
            raise RecordNotFound, "Couldn't find #{name} with ID=#{id}#{conditions}"
          end
        end

        def find_some(ids, options)
          conditions = " AND (#{sanitize_sql(options[:conditions])})" if options[:conditions]
          ids_list   = ids.map { |id| quote_value(id,columns_hash[primary_key]) }.join(',')
          options.update :conditions => "#{quoted_table_name}.#{connection.quote_column_name(primary_key)} IN (#{ids_list})#{conditions}"

          result = find_every(options)

          # Determine expected size from limit and offset, not just ids.size.
          expected_size =
            if options[:limit] && ids.size > options[:limit]
              options[:limit]
            else
              ids.size
            end

          # 11 ids with limit 3, offset 9 should give 2 results.
          if options[:offset] && (ids.size - options[:offset] < expected_size)
            expected_size = ids.size - options[:offset]
          end

          if result.size == expected_size
            result
          else
            raise RecordNotFound, "Couldn't find all #{name.pluralize} with IDs (#{ids_list})#{conditions} (found #{result.size} results, but was looking for #{expected_size})"
          end
        end

        # Finder methods must instantiate through this method to work with the
        # single-table inheritance model that makes it possible to create
        # objects of different types from the same table.
        def instantiate(record)
          object =
            if subclass_name = record[inheritance_column]
              # No type given.
              if subclass_name.empty?
                allocate

              else
                # Ignore type if no column is present since it was probably
                # pulled in from a sloppy join.
                unless columns_hash.include?(inheritance_column)
                  allocate

                else
                  begin
                    compute_type(subclass_name).allocate
                  rescue NameError
                    raise SubclassNotFound,
                      "The single-table inheritance mechanism failed to locate the subclass: '#{record[inheritance_column]}'. " +
                      "This error is raised because the column '#{inheritance_column}' is reserved for storing the class in case of inheritance. " +
                      "Please rename this column if you didn't intend it to be used for storing the inheritance class " +
                      "or overwrite #{self.to_s}.inheritance_column to use another column for that information."
                  end
                end
              end
            else
              allocate
            end

          object.instance_variable_set("@attributes", record)
          object.instance_variable_set("@attributes_cache", Hash.new)

          if object.respond_to_without_attributes?(:after_find)
            object.send(:callback, :after_find)
          end

          if object.respond_to_without_attributes?(:after_initialize)
            object.send(:callback, :after_initialize)
          end

          object
        end

        # Nest the type name in the same module as this class.
        # Bar is "MyApp::Business::Bar" relative to MyApp::Business::Foo
        def type_name_with_module(type_name)
          (/^::/ =~ type_name) ? type_name : "#{parent.name}::#{type_name}"
        end

        def construct_finder_sql(options)
          scope = scope(:find)
          sql  = "SELECT #{(scope && scope[:select]) || options[:select] || (options[:joins] && quoted_table_name + '.*') || '*'} "
          sql << "FROM #{(scope && scope[:from]) || options[:from] || quoted_table_name} "

          add_joins!(sql, options, scope)
          add_conditions!(sql, options[:conditions], scope)

          add_group!(sql, options[:group], scope)
          add_order!(sql, options[:order], scope)
          add_limit!(sql, options, scope)
          add_lock!(sql, options, scope)

          sql
        end

        # Merges includes so that the result is a valid +include+
        def merge_includes(first, second)
         (safe_to_array(first) + safe_to_array(second)).uniq
        end

        # Object#to_a is deprecated, though it does have the desired behavior
        def safe_to_array(o)
          case o
          when NilClass
            []
          when Array
            o
          else
            [o]
          end
        end

        def add_order!(sql, order, scope = :auto)
          scope = scope(:find) if :auto == scope
          scoped_order = scope[:order] if scope
          if order
            sql << " ORDER BY #{order}"
            sql << ", #{scoped_order}" if scoped_order
          else
            sql << " ORDER BY #{scoped_order}" if scoped_order
          end
        end

        def add_group!(sql, group, scope = :auto)
          if group
            sql << " GROUP BY #{group}"
          else
            scope = scope(:find) if :auto == scope
            if scope && (scoped_group = scope[:group])
              sql << " GROUP BY #{scoped_group}"
            end
          end
        end

        # The optional scope argument is for the current :find scope.
        def add_limit!(sql, options, scope = :auto)
          scope = scope(:find) if :auto == scope

          if scope
            options[:limit] ||= scope[:limit]
            options[:offset] ||= scope[:offset]
          end

          connection.add_limit_offset!(sql, options)
        end

        # The optional scope argument is for the current :find scope.
        # The :lock option has precedence over a scoped :lock.
        def add_lock!(sql, options, scope = :auto)
          scope = scope(:find) if :auto == scope
          options = options.reverse_merge(:lock => scope[:lock]) if scope
          connection.add_lock!(sql, options)
        end

        # The optional scope argument is for the current :find scope.
        def add_joins!(sql, options, scope = :auto)
          scope = scope(:find) if :auto == scope
          join = (scope && scope[:joins]) || options[:joins]
          case join
          when Symbol, Hash, Array
            join_dependency = ActiveRecord::Associations::ClassMethods::InnerJoinDependency.new(self, join, nil)
            sql << " #{join_dependency.join_associations.collect { |assoc| assoc.association_join }.join} "
          else
            sql << " #{join} "
          end
        end

        # Adds a sanitized version of +conditions+ to the +sql+ string. Note that the passed-in +sql+ string is changed.
        # The optional scope argument is for the current :find scope.
        def add_conditions!(sql, conditions, scope = :auto)
          scope = scope(:find) if :auto == scope
          segments = []
          segments << sanitize_sql(scope[:conditions]) if scope && !scope[:conditions].blank?
          segments << sanitize_sql(conditions) unless conditions.blank?
          segments << type_condition if finder_needs_type_condition?
          segments.delete_if{|s| s.blank?}
          sql << "WHERE (#{segments.join(") AND (")}) " unless segments.empty?
        end

        def type_condition
          quoted_inheritance_column = connection.quote_column_name(inheritance_column)
          type_condition = subclasses.inject("#{quoted_table_name}.#{quoted_inheritance_column} = '#{name.demodulize}' ") do |condition, subclass|
            condition << "OR #{quoted_table_name}.#{quoted_inheritance_column} = '#{subclass.name.demodulize}' "
          end

          " (#{type_condition}) "
        end

        # Guesses the table name, but does not decorate it with prefix and suffix information.
        def undecorated_table_name(class_name = base_class.name)
          table_name = Inflector.underscore(Inflector.demodulize(class_name))
          table_name = Inflector.pluralize(table_name) if pluralize_table_names
          table_name
        end

        # Enables dynamic finders like find_by_user_name(user_name) and find_by_user_name_and_password(user_name, password) that are turned into
        # find(:first, :conditions => ["user_name = ?", user_name]) and  find(:first, :conditions => ["user_name = ? AND password = ?", user_name, password])
        # respectively. Also works for find(:all) by using find_all_by_amount(50) that is turned into find(:all, :conditions => ["amount = ?", 50]).
        #
        # It's even possible to use all the additional parameters to find. For example, the full interface for find_all_by_amount
        # is actually find_all_by_amount(amount, options).
        #
        # This also enables you to initialize a record if it is not found, such as find_or_initialize_by_amount(amount)
        # or find_or_create_by_user_and_password(user, password).
        #
        # Each dynamic finder or initializer/creator is also defined in the class after it is first invoked, so that future
        # attempts to use it do not run through method_missing.
        def method_missing(method_id, *arguments)
          if match = /^find_(all_by|by)_([_a-zA-Z]\w*)$/.match(method_id.to_s)
            finder = determine_finder(match)

            attribute_names = extract_attribute_names_from_match(match)
            super unless all_attributes_exists?(attribute_names)

            self.class_eval %{
              def self.#{method_id}(*args)
                options = args.extract_options!
                attributes = construct_attributes_from_arguments([:#{attribute_names.join(',:')}], args)
                finder_options = { :conditions => attributes }
                validate_find_options(options)
                set_readonly_option!(options)

                if options[:conditions]
                  with_scope(:find => finder_options) do
                    ActiveSupport::Deprecation.silence { send(:#{finder}, options) }
                  end
                else
                  ActiveSupport::Deprecation.silence { send(:#{finder}, options.merge(finder_options)) }
                end
              end
            }, __FILE__, __LINE__
            send(method_id, *arguments)
          elsif match = /^find_or_(initialize|create)_by_([_a-zA-Z]\w*)$/.match(method_id.to_s)
            instantiator = determine_instantiator(match)
            attribute_names = extract_attribute_names_from_match(match)
            super unless all_attributes_exists?(attribute_names)

            self.class_eval %{
              def self.#{method_id}(*args)
                if args[0].is_a?(Hash)
                  attributes = args[0].with_indifferent_access
                  find_attributes = attributes.slice(*[:#{attribute_names.join(',:')}])
                else
                  find_attributes = attributes = construct_attributes_from_arguments([:#{attribute_names.join(',:')}], args)
                end

                options = { :conditions => find_attributes }
                set_readonly_option!(options)

                record = find_initial(options)
                if record.nil?
                  record = self.new { |r| r.send(:attributes=, attributes, false) }
                  #{'record.save' if instantiator == :create}
                  record
                else
                  record
                end
              end
            }, __FILE__, __LINE__
            send(method_id, *arguments)
          else
            super
          end
        end

        def determine_finder(match)
          match.captures.first == 'all_by' ? :find_every : :find_initial
        end

        def determine_instantiator(match)
          match.captures.first == 'initialize' ? :new : :create
        end

        def extract_attribute_names_from_match(match)
          match.captures.last.split('_and_')
        end

        def construct_attributes_from_arguments(attribute_names, arguments)
          attributes = {}
          attribute_names.each_with_index { |name, idx| attributes[name] = arguments[idx] }
          attributes
        end

        # Similar in purpose to +expand_hash_conditions_for_aggregates+.
        def expand_attribute_names_for_aggregates(attribute_names)
          expanded_attribute_names = []
          attribute_names.each do |attribute_name|
            unless (aggregation = reflect_on_aggregation(attribute_name.to_sym)).nil?
              aggregate_mapping(aggregation).each do |field_attr, aggregate_attr|
                expanded_attribute_names << field_attr
              end
            else
              expanded_attribute_names << attribute_name
            end
          end
          expanded_attribute_names
        end

        def all_attributes_exists?(attribute_names)
          attribute_names = expand_attribute_names_for_aggregates(attribute_names)
          attribute_names.all? { |name| column_methods_hash.include?(name.to_sym) }
        end

        def attribute_condition(argument)
          case argument
            when nil   then "IS ?"
            when Array, ActiveRecord::Associations::AssociationCollection then "IN (?)"
            when Range then "BETWEEN ? AND ?"
            else            "= ?"
          end
        end

        # Interpret Array and Hash as conditions and anything else as an id.
        def expand_id_conditions(id_or_conditions)
          case id_or_conditions
            when Array, Hash then id_or_conditions
            else sanitize_sql(primary_key => id_or_conditions)
          end
        end


        # Defines an "attribute" method (like #inheritance_column or
        # #table_name). A new (class) method will be created with the
        # given name. If a value is specified, the new method will
        # return that value (as a string). Otherwise, the given block
        # will be used to compute the value of the method.
        #
        # The original method will be aliased, with the new name being
        # prefixed with "original_". This allows the new method to
        # access the original value.
        #
        # Example:
        #
        #   class A < ActiveRecord::Base
        #     define_attr_method :primary_key, "sysid"
        #     define_attr_method( :inheritance_column ) do
        #       original_inheritance_column + "_id"
        #     end
        #   end
        def define_attr_method(name, value=nil, &block)
          sing = class << self; self; end
          sing.send :alias_method, "original_#{name}", name
          if block_given?
            sing.send :define_method, name, &block
          else
            # use eval instead of a block to work around a memory leak in dev
            # mode in fcgi
            sing.class_eval "def #{name}; #{value.to_s.inspect}; end"
          end
        end

      protected
        # Scope parameters to method calls within the block.  Takes a hash of method_name => parameters hash.
        # method_name may be :find or :create. :find parameters may include the <tt>:conditions</tt>, <tt>:joins</tt>,
        # <tt>:include</tt>, <tt>:offset</tt>, <tt>:limit</tt>, and <tt>:readonly</tt> options. :create parameters are an attributes hash.
        #
        #   class Article < ActiveRecord::Base
        #     def self.create_with_scope
        #       with_scope(:find => { :conditions => "blog_id = 1" }, :create => { :blog_id => 1 }) do
        #         find(1) # => SELECT * from articles WHERE blog_id = 1 AND id = 1
        #         a = create(1)
        #         a.blog_id # => 1
        #       end
        #     end
        #   end
        #
        # In nested scopings, all previous parameters are overwritten by the innermost rule, with the exception of
        # :conditions and :include options in :find, which are merged.
        #
        #   class Article < ActiveRecord::Base
        #     def self.find_with_scope
        #       with_scope(:find => { :conditions => "blog_id = 1", :limit => 1 }, :create => { :blog_id => 1 }) do
        #         with_scope(:find => { :limit => 10})
        #           find(:all) # => SELECT * from articles WHERE blog_id = 1 LIMIT 10
        #         end
        #         with_scope(:find => { :conditions => "author_id = 3" })
        #           find(:all) # => SELECT * from articles WHERE blog_id = 1 AND author_id = 3 LIMIT 1
        #         end
        #       end
        #     end
        #   end
        #
        # You can ignore any previous scopings by using the <tt>with_exclusive_scope</tt> method.
        #
        #   class Article < ActiveRecord::Base
        #     def self.find_with_exclusive_scope
        #       with_scope(:find => { :conditions => "blog_id = 1", :limit => 1 }) do
        #         with_exclusive_scope(:find => { :limit => 10 })
        #           find(:all) # => SELECT * from articles LIMIT 10
        #         end
        #       end
        #     end
        #   end
        def with_scope(method_scoping = {}, action = :merge, &block)
          method_scoping = method_scoping.method_scoping if method_scoping.respond_to?(:method_scoping)

          # Dup first and second level of hash (method and params).
          method_scoping = method_scoping.inject({}) do |hash, (method, params)|
            hash[method] = (params == true) ? params : params.dup
            hash
          end

          method_scoping.assert_valid_keys([ :find, :create ])

          if f = method_scoping[:find]
            f.assert_valid_keys(VALID_FIND_OPTIONS)
            set_readonly_option! f
          end

          # Merge scopings
          if action == :merge && current_scoped_methods
            method_scoping = current_scoped_methods.inject(method_scoping) do |hash, (method, params)|
              case hash[method]
                when Hash
                  if method == :find
                    (hash[method].keys + params.keys).uniq.each do |key|
                      merge = hash[method][key] && params[key] # merge if both scopes have the same key
                      if key == :conditions && merge
                        hash[method][key] = [params[key], hash[method][key]].collect{ |sql| "( %s )" % sanitize_sql(sql) }.join(" AND ")
                      elsif key == :include && merge
                        hash[method][key] = merge_includes(hash[method][key], params[key]).uniq
                      else
                        hash[method][key] = hash[method][key] || params[key]
                      end
                    end
                  else
                    hash[method] = params.merge(hash[method])
                  end
                else
                  hash[method] = params
              end
              hash
            end
          end

          self.scoped_methods << method_scoping

          begin
            yield
          ensure
            self.scoped_methods.pop
          end
        end

        # Works like with_scope, but discards any nested properties.
        def with_exclusive_scope(method_scoping = {}, &block)
          with_scope(method_scoping, :overwrite, &block)
        end

        def subclasses #:nodoc:
          @@subclasses[self] ||= []
          @@subclasses[self] + extra = @@subclasses[self].inject([]) {|list, subclass| list + subclass.subclasses }
        end

        # Test whether the given method and optional key are scoped.
        def scoped?(method, key = nil) #:nodoc:
          if current_scoped_methods && (scope = current_scoped_methods[method])
            !key || scope.has_key?(key)
          end
        end

        # Retrieve the scope for the given method and optional key.
        def scope(method, key = nil) #:nodoc:
          if current_scoped_methods && (scope = current_scoped_methods[method])
            key ? scope[key] : scope
          end
        end

        def thread_safe_scoped_methods #:nodoc:
          scoped_methods = (Thread.current[:scoped_methods] ||= {})
          scoped_methods[self] ||= []
        end

        def single_threaded_scoped_methods #:nodoc:
          @scoped_methods ||= []
        end

        # pick up the correct scoped_methods version from @@allow_concurrency
        if @@allow_concurrency
          alias_method :scoped_methods, :thread_safe_scoped_methods
        else
          alias_method :scoped_methods, :single_threaded_scoped_methods
        end

        def current_scoped_methods #:nodoc:
          scoped_methods.last
        end

        # Returns the class type of the record using the current module as a prefix. So descendents of
        # MyApp::Business::Account would appear as MyApp::Business::AccountSubclass.
        def compute_type(type_name)
          modularized_name = type_name_with_module(type_name)
          begin
            class_eval(modularized_name, __FILE__, __LINE__)
          rescue NameError
            class_eval(type_name, __FILE__, __LINE__)
          end
        end

        # Returns the class descending directly from ActiveRecord in the inheritance hierarchy.
        def class_of_active_record_descendant(klass)
          if klass.superclass == Base || klass.superclass.abstract_class?
            klass
          elsif klass.superclass.nil?
            raise ActiveRecordError, "#{name} doesn't belong in a hierarchy descending from ActiveRecord"
          else
            class_of_active_record_descendant(klass.superclass)
          end
        end

        # Returns the name of the class descending directly from ActiveRecord in the inheritance hierarchy.
        def class_name_of_active_record_descendant(klass) #:nodoc:
          klass.base_class.name
        end

        # Accepts an array, hash, or string of sql conditions and sanitizes
        # them into a valid SQL fragment for a WHERE clause.
        #   ["name='%s' and group_id='%s'", "foo'bar", 4]  returns  "name='foo''bar' and group_id='4'"
        #   { :name => "foo'bar", :group_id => 4 }  returns "name='foo''bar' and group_id='4'"
        #   "name='foo''bar' and group_id='4'" returns "name='foo''bar' and group_id='4'"
        def sanitize_sql_for_conditions(condition)
          case condition
            when Array; sanitize_sql_array(condition)
            when Hash;  sanitize_sql_hash_for_conditions(condition)
            else        condition
          end
        end
        alias_method :sanitize_sql, :sanitize_sql_for_conditions

        # Accepts an array, hash, or string of sql conditions and sanitizes
        # them into a valid SQL fragment for a SET clause.
        #   { :name => nil, :group_id => 4 }  returns "name = NULL , group_id='4'"
        def sanitize_sql_for_assignment(assignments)
          case assignments
            when Array; sanitize_sql_array(assignments)
            when Hash;  sanitize_sql_hash_for_assignment(assignments)
            else        assignments
          end
        end

        def aggregate_mapping(reflection)
          mapping = reflection.options[:mapping] || [reflection.name, reflection.name]
          mapping.first.is_a?(Array) ? mapping : [mapping]
        end

        # Accepts a hash of sql conditions and replaces those attributes
        # that correspond to a +composed_of+ relationship with their expanded
        # aggregate attribute values.
        # Given:
        #     class Person < ActiveRecord::Base
        #       composed_of :address, :class_name => "Address",
        #         :mapping => [%w(address_street street), %w(address_city city)]
        #     end
        # Then:
        #     { :address => Address.new("813 abc st.", "chicago") }
        #       # => { :address_street => "813 abc st.", :address_city => "chicago" }
        def expand_hash_conditions_for_aggregates(attrs)
          expanded_attrs = {}
          attrs.each do |attr, value|
            unless (aggregation = reflect_on_aggregation(attr.to_sym)).nil?
              mapping = aggregate_mapping(aggregation)
              mapping.each do |field_attr, aggregate_attr|
                if mapping.size == 1 && !value.respond_to?(aggregate_attr)
                  expanded_attrs[field_attr] = value
                else
                  expanded_attrs[field_attr] = value.send(aggregate_attr)
                end
              end
            else
              expanded_attrs[attr] = value
            end
          end
          expanded_attrs
        end

        # Sanitizes a hash of attribute/value pairs into SQL conditions for a WHERE clause.
        #   { :name => "foo'bar", :group_id => 4 }
        #     # => "name='foo''bar' and group_id= 4"
        #   { :status => nil, :group_id => [1,2,3] }
        #     # => "status IS NULL and group_id IN (1,2,3)"
        #   { :age => 13..18 }
        #     # => "age BETWEEN 13 AND 18"
        #   { 'other_records.id' => 7 }
        #     # => "`other_records`.`id` = 7"
        # And for value objects on a composed_of relationship:
        #   { :address => Address.new("123 abc st.", "chicago") }
        #     # => "address_street='123 abc st.' and address_city='chicago'"
        def sanitize_sql_hash_for_conditions(attrs)
          attrs = expand_hash_conditions_for_aggregates(attrs)

          conditions = attrs.map do |attr, value|
            attr = attr.to_s

            # Extract table name from qualified attribute names.
            if attr.include?('.')
              table_name, attr = attr.split('.', 2)
              table_name = connection.quote_table_name(table_name)
            else
              table_name = quoted_table_name
            end

            "#{table_name}.#{connection.quote_column_name(attr)} #{attribute_condition(value)}"
          end.join(' AND ')

          replace_bind_variables(conditions, expand_range_bind_variables(attrs.values))
        end
        alias_method :sanitize_sql_hash, :sanitize_sql_hash_for_conditions

        # Sanitizes a hash of attribute/value pairs into SQL conditions for a SET clause.
        #   { :status => nil, :group_id => 1 }
        #     # => "status = NULL , group_id = 1"
        def sanitize_sql_hash_for_assignment(attrs)
          conditions = attrs.map do |attr, value|
            "#{connection.quote_column_name(attr)} = #{quote_bound_value(value)}"
          end.join(', ')
        end

        # Accepts an array of conditions.  The array has each value
        # sanitized and interpolated into the sql statement.
        #   ["name='%s' and group_id='%s'", "foo'bar", 4]  returns  "name='foo''bar' and group_id='4'"
        def sanitize_sql_array(ary)
          statement, *values = ary
          if values.first.is_a?(Hash) and statement =~ /:\w+/
            replace_named_bind_variables(statement, values.first)
          elsif statement.include?('?')
            replace_bind_variables(statement, values)
          else
            statement % values.collect { |value| connection.quote_string(value.to_s) }
          end
        end

        alias_method :sanitize_conditions, :sanitize_sql

        def replace_bind_variables(statement, values) #:nodoc:
          raise_if_bind_arity_mismatch(statement, statement.count('?'), values.size)
          bound = values.dup
          statement.gsub('?') { quote_bound_value(bound.shift) }
        end

        def replace_named_bind_variables(statement, bind_vars) #:nodoc:
          statement.gsub(/:([a-zA-Z]\w*)/) do
            match = $1.to_sym
            if bind_vars.include?(match)
              quote_bound_value(bind_vars[match])
            else
              raise PreparedStatementInvalid, "missing value for :#{match} in #{statement}"
            end
          end
        end

        def expand_range_bind_variables(bind_vars) #:nodoc:
          bind_vars.sum do |var|
            if var.is_a?(Range)
              [var.first, var.last]
            else
              [var]
            end
          end
        end

        def quote_bound_value(value) #:nodoc:
          if value.respond_to?(:map) && !value.is_a?(String)
            if value.respond_to?(:empty?) && value.empty?
              connection.quote(nil)
            else
              value.map { |v| connection.quote(v) }.join(',')
            end
          else
            connection.quote(value)
          end
        end

        def raise_if_bind_arity_mismatch(statement, expected, provided) #:nodoc:
          unless expected == provided
            raise PreparedStatementInvalid, "wrong number of bind variables (#{provided} for #{expected}) in: #{statement}"
          end
        end

        VALID_FIND_OPTIONS = [ :conditions, :include, :joins, :limit, :offset,
                               :order, :select, :readonly, :group, :from, :lock ]

        def validate_find_options(options) #:nodoc:
          options.assert_valid_keys(VALID_FIND_OPTIONS)
        end

        def set_readonly_option!(options) #:nodoc:
          # Inherit :readonly from finder scope if set.  Otherwise,
          # if :joins is not blank then :readonly defaults to true.
          unless options.has_key?(:readonly)
            if scoped_readonly = scope(:find, :readonly)
              options[:readonly] = scoped_readonly
            elsif !options[:joins].blank? && !options[:select]
              options[:readonly] = true
            end
          end
        end

        def encode_quoted_value(value) #:nodoc:
          quoted_value = connection.quote(value)
          quoted_value = "'#{quoted_value[1..-2].gsub(/\'/, "\\\\'")}'" if quoted_value.include?("\\\'") # (for ruby mode) "
          quoted_value
        end
    end

    public
      # New objects can be instantiated as either empty (pass no construction parameter) or pre-set with
      # attributes but not yet saved (pass a hash with key names matching the associated table column names).
      # In both instances, valid attribute keys are determined by the column names of the associated table --
      # hence you can't have attributes that aren't part of the table columns.
      def initialize(attributes = nil)
        @attributes = attributes_from_column_definition
        @attributes_cache = {}
        @new_record = true
        ensure_proper_type
        self.attributes = attributes unless attributes.nil?
        self.class.send(:scope, :create).each { |att,value| self.send("#{att}=", value) } if self.class.send(:scoped?, :create)
        result = yield self if block_given?
        callback(:after_initialize) if respond_to_without_attributes?(:after_initialize)
        result
      end

      # A model instance's primary key is always available as model.id
      # whether you name it the default 'id' or set it to something else.
      def id
        attr_name = self.class.primary_key
        column = column_for_attribute(attr_name)

        self.class.send(:define_read_method, :id, attr_name, column)
        # now that the method exists, call it
        self.send attr_name.to_sym

      end

      # Enables Active Record objects to be used as URL parameters in Action Pack automatically.
      def to_param
        # We can't use alias_method here, because method 'id' optimizes itself on the fly.
        (id = self.id) ? id.to_s : nil # Be sure to stringify the id for routes
      end
      
      # Returns a cache key that can be used to identify this record. Examples:
      #
      #   Product.new.cache_key     # => "products/new"
      #   Product.find(5).cache_key # => "products/5" (updated_at not available)
      #   Person.find(5).cache_key  # => "people/5-20071224150000" (updated_at available)
      def cache_key
        case 
        when new_record?
          "#{self.class.name.tableize}/new"
        when self[:updated_at]
          "#{self.class.name.tableize}/#{id}-#{updated_at.to_s(:number)}"
        else
          "#{self.class.name.tableize}/#{id}"
        end
      end

      def id_before_type_cast #:nodoc:
        read_attribute_before_type_cast(self.class.primary_key)
      end

      def quoted_id #:nodoc:
        quote_value(id, column_for_attribute(self.class.primary_key))
      end

      # Sets the primary ID.
      def id=(value)
        write_attribute(self.class.primary_key, value)
      end

      # Returns true if this object hasn't been saved yet -- that is, a record for the object doesn't exist yet.
      def new_record?
        defined?(@new_record) && @new_record
      end

      # * No record exists: Creates a new record with values matching those of the object attributes.
      # * A record does exist: Updates the record with values matching those of the object attributes.
      def save
        create_or_update
      end

      # Attempts to save the record, but instead of just returning false if it couldn't happen, it raises a
      # RecordNotSaved exception
      def save!
        create_or_update || raise(RecordNotSaved)
      end

      # Deletes the record in the database and freezes this instance to reflect that no changes should
      # be made (since they can't be persisted).
      def destroy
        unless new_record?
          connection.delete <<-end_sql, "#{self.class.name} Destroy"
            DELETE FROM #{self.class.quoted_table_name}
            WHERE #{connection.quote_column_name(self.class.primary_key)} = #{quoted_id}
          end_sql
        end

        freeze
      end

      # Returns a clone of the record that hasn't been assigned an id yet and
      # is treated as a new record.  Note that this is a "shallow" clone:
      # it copies the object's attributes only, not its associations.
      # The extent of a "deep" clone is application-specific and is therefore
      # left to the application to implement according to its need.
      def clone
        attrs = clone_attributes(:read_attribute_before_type_cast)
        attrs.delete(self.class.primary_key)
        record = self.class.new
        record.send :instance_variable_set, '@attributes', attrs
        record
      end

      # Returns an instance of the specified klass with the attributes of the current record. This is mostly useful in relation to
      # single-table inheritance structures where you want a subclass to appear as the superclass. This can be used along with record
      # identification in Action Pack to allow, say, Client < Company to do something like render :partial => @client.becomes(Company)
      # to render that instance using the companies/company partial instead of clients/client.
      #
      # Note: The new instance will share a link to the same attributes as the original class. So any change to the attributes in either
      # instance will affect the other.
      def becomes(klass)
        returning klass.new do |became|
          became.instance_variable_set("@attributes", @attributes)
          became.instance_variable_set("@attributes_cache", @attributes_cache)
          became.instance_variable_set("@new_record", new_record?)
        end
      end

      # Updates a single attribute and saves the record. This is especially useful for boolean flags on existing records.
      # Note: This method is overwritten by the Validation module that'll make sure that updates made with this method
      # aren't subjected to validation checks. Hence, attributes can be updated even if the full object isn't valid.
      def update_attribute(name, value)
        send(name.to_s + '=', value)
        save
      end

      # Updates all the attributes from the passed-in Hash and saves the record. If the object is invalid, the saving will
      # fail and false will be returned.
      def update_attributes(attributes)
        self.attributes = attributes
        save
      end

      # Updates an object just like Base.update_attributes but calls save! instead of save so an exception is raised if the record is invalid.
      def update_attributes!(attributes)
        self.attributes = attributes
        save!
      end

      # Initializes the +attribute+ to zero if nil and adds the value passed as +by+ (default is one). Only makes sense for number-based attributes. Returns self.
      def increment(attribute, by = 1)
        self[attribute] ||= 0
        self[attribute] += by
        self
      end

      # Increments the +attribute+ and saves the record.
      def increment!(attribute, by = 1)
        increment(attribute, by).update_attribute(attribute, self[attribute])
      end

      # Initializes the +attribute+ to zero if nil and subtracts the value passed as +by+ (default is one). Only makes sense for number-based attributes. Returns self.
      def decrement(attribute, by = 1)
        self[attribute] ||= 0
        self[attribute] -= by
        self
      end

      # Decrements the +attribute+ and saves the record.
      def decrement!(attribute, by = 1)
        decrement(attribute, by).update_attribute(attribute, self[attribute])
      end

      # Turns an +attribute+ that's currently true into false and vice versa. Returns self.
      def toggle(attribute)
        self[attribute] = !send("#{attribute}?")
        self
      end

      # Toggles the +attribute+ and saves the record.
      def toggle!(attribute)
        toggle(attribute).update_attribute(attribute, self[attribute])
      end

      # Reloads the attributes of this object from the database.
      # The optional options argument is passed to find when reloading so you
      # may do e.g. record.reload(:lock => true) to reload the same record with
      # an exclusive row lock.
      def reload(options = nil)
        clear_aggregation_cache
        clear_association_cache
        @attributes.update(self.class.find(self.id, options).instance_variable_get('@attributes'))
        @attributes_cache = {}
        self
      end

      # Returns the value of the attribute identified by <tt>attr_name</tt> after it has been typecast (for example,
      # "2004-12-12" in a data column is cast to a date object, like Date.new(2004, 12, 12)).
      # (Alias for the protected read_attribute method).
      def [](attr_name)
        read_attribute(attr_name)
      end

      # Updates the attribute identified by <tt>attr_name</tt> with the specified +value+.
      # (Alias for the protected write_attribute method).
      def []=(attr_name, value)
        write_attribute(attr_name, value)
      end

      # Allows you to set all the attributes at once by passing in a hash with keys
      # matching the attribute names (which again matches the column names). Sensitive attributes can be protected
      # from this form of mass-assignment by using the +attr_protected+ macro. Or you can alternatively
      # specify which attributes *can* be accessed with the +attr_accessible+ macro. Then all the
      # attributes not included in that won't be allowed to be mass-assigned.
      def attributes=(new_attributes, guard_protected_attributes = true)
        return if new_attributes.nil?
        attributes = new_attributes.dup
        attributes.stringify_keys!

        multi_parameter_attributes = []
        attributes = remove_attributes_protected_from_mass_assignment(attributes) if guard_protected_attributes

        attributes.each do |k, v|
          k.include?("(") ? multi_parameter_attributes << [ k, v ] : send(k + "=", v)
        end

        assign_multiparameter_attributes(multi_parameter_attributes)
      end


      # Returns a hash of all the attributes with their names as keys and the values of the attributes as values.
      def attributes(options = nil)
        self.attribute_names.inject({}) do |attrs, name|
          attrs[name] = read_attribute(name)
          attrs
        end
      end

      # Returns a hash of attributes before typecasting and deserialization.
      def attributes_before_type_cast
        self.attribute_names.inject({}) do |attrs, name|
          attrs[name] = read_attribute_before_type_cast(name)
          attrs
        end
      end

      # Format attributes nicely for inspect.
      def attribute_for_inspect(attr_name)
        value = read_attribute(attr_name)

        if value.is_a?(String) && value.length > 50
          "#{value[0..50]}...".inspect
        elsif value.is_a?(Date) || value.is_a?(Time)
          %("#{value.to_s(:db)}")
        else
          value.inspect
        end
      end

      # Returns true if the specified +attribute+ has been set by the user or by a database load and is neither
      # nil nor empty? (the latter only applies to objects that respond to empty?, most notably Strings).
      def attribute_present?(attribute)
        value = read_attribute(attribute)
        !value.blank?
      end

      # Returns true if the given attribute is in the attributes hash
      def has_attribute?(attr_name)
        @attributes.has_key?(attr_name.to_s)
      end

      # Returns an array of names for the attributes available on this object sorted alphabetically.
      def attribute_names
        @attributes.keys.sort
      end

      # Returns the column object for the named attribute.
      def column_for_attribute(name)
        self.class.columns_hash[name.to_s]
      end

      # Returns true if the +comparison_object+ is the same object, or is of the same type and has the same id.
      def ==(comparison_object)
        comparison_object.equal?(self) ||
          (comparison_object.instance_of?(self.class) &&
            comparison_object.id == id &&
            !comparison_object.new_record?)
      end

      # Delegates to ==
      def eql?(comparison_object)
        self == (comparison_object)
      end

      # Delegates to id in order to allow two records of the same type and id to work with something like:
      #   [ Person.find(1), Person.find(2), Person.find(3) ] & [ Person.find(1), Person.find(4) ] # => [ Person.find(1) ]
      def hash
        id.hash
      end

      # Freeze the attributes hash such that associations are still accessible, even on destroyed records.
      def freeze
        @attributes.freeze; self
      end

      # Returns +true+ if the attributes hash has been frozen.
      def frozen?
        @attributes.frozen?
      end

      # Returns +true+ if the record is read only. Records loaded through joins with piggy-back
      # attributes will be marked as read only since they cannot be saved.
      def readonly?
        defined?(@readonly) && @readonly == true
      end

      # Marks this record as read only.
      def readonly!
        @readonly = true
      end

      # Returns the contents of the record as a nicely formatted string.
      def inspect
        attributes_as_nice_string = self.class.column_names.collect { |name|
          if has_attribute?(name) || new_record?
            "#{name}: #{attribute_for_inspect(name)}"
          end
        }.compact.join(", ")
        "#<#{self.class} #{attributes_as_nice_string}>"
      end

    private
      def create_or_update
        raise ReadOnlyRecord if readonly?
        result = new_record? ? create : update
        result != false
      end

      # Updates the associated record with values matching those of the instance attributes.
      # Returns the number of affected rows.
      def update
        quoted_attributes = attributes_with_quotes(false, false)
        return 0 if quoted_attributes.empty?
        connection.update(
          "UPDATE #{self.class.quoted_table_name} " +
          "SET #{quoted_comma_pair_list(connection, quoted_attributes)} " +
          "WHERE #{connection.quote_column_name(self.class.primary_key)} = #{quote_value(id)}",
          "#{self.class.name} Update"
        )
      end

      # Creates a record with values matching those of the instance attributes
      # and returns its id.
      def create
        if self.id.nil? && connection.prefetch_primary_key?(self.class.table_name)
          self.id = connection.next_sequence_value(self.class.sequence_name)
        end

        quoted_attributes = attributes_with_quotes

        statement = if quoted_attributes.empty?
          connection.empty_insert_statement(self.class.table_name)
        else
          "INSERT INTO #{self.class.quoted_table_name} " +
          "(#{quoted_column_names.join(', ')}) " +
          "VALUES(#{quoted_attributes.values.join(', ')})"
        end

        self.id = connection.insert(statement, "#{self.class.name} Create",
          self.class.primary_key, self.id, self.class.sequence_name)

        @new_record = false
        id
      end

      # Sets the attribute used for single table inheritance to this class name if this is not the ActiveRecord descendent.
      # Considering the hierarchy Reply < Message < ActiveRecord, this makes it possible to do Reply.new without having to
      # set Reply[Reply.inheritance_column] = "Reply" yourself. No such attribute would be set for objects of the
      # Message class in that example.
      def ensure_proper_type
        unless self.class.descends_from_active_record?
          write_attribute(self.class.inheritance_column, Inflector.demodulize(self.class.name))
        end
      end

      def convert_number_column_value(value)
        case value
          when FalseClass; 0
          when TrueClass;  1
          when '';         nil
          else value
        end
      end

      def remove_attributes_protected_from_mass_assignment(attributes)
        safe_attributes =
          if self.class.accessible_attributes.nil? && self.class.protected_attributes.nil?
            attributes.reject { |key, value| attributes_protected_by_default.include?(key.gsub(/\(.+/, "")) }
          elsif self.class.protected_attributes.nil?
            attributes.reject { |key, value| !self.class.accessible_attributes.include?(key.gsub(/\(.+/, "")) || attributes_protected_by_default.include?(key.gsub(/\(.+/, "")) }
          elsif self.class.accessible_attributes.nil?
            attributes.reject { |key, value| self.class.protected_attributes.include?(key.gsub(/\(.+/,"")) || attributes_protected_by_default.include?(key.gsub(/\(.+/, "")) }
          else
            raise "Declare either attr_protected or attr_accessible for #{self.class}, but not both."
          end

        removed_attributes = attributes.keys - safe_attributes.keys

        if removed_attributes.any?
          logger.debug "WARNING: Can't mass-assign these protected attributes: #{removed_attributes.join(', ')}"
        end

        safe_attributes
      end

      # Removes attributes which have been marked as readonly.
      def remove_readonly_attributes(attributes)
        unless self.class.readonly_attributes.nil?
          attributes.delete_if { |key, value| self.class.readonly_attributes.include?(key.gsub(/\(.+/,"")) }
        else
          attributes
        end
      end

      # The primary key and inheritance column can never be set by mass-assignment for security reasons.
      def attributes_protected_by_default
        default = [ self.class.primary_key, self.class.inheritance_column ]
        default << 'id' unless self.class.primary_key.eql? 'id'
        default
      end

      # Returns a copy of the attributes hash where all the values have been safely quoted for use in
      # an SQL statement.
      def attributes_with_quotes(include_primary_key = true, include_readonly_attributes = true)
        quoted = {}
        connection = self.class.connection
        @attributes.each_pair do |name, value|
          if column = column_for_attribute(name)
            quoted[name] = connection.quote(read_attribute(name), column) unless !include_primary_key && column.primary
          end
        end
        include_readonly_attributes ? quoted : remove_readonly_attributes(quoted)
      end

      # Quote strings appropriately for SQL statements.
      def quote_value(value, column = nil)
        self.class.connection.quote(value, column)
      end

      # Interpolate custom sql string in instance context.
      # Optional record argument is meant for custom insert_sql.
      def interpolate_sql(sql, record = nil)
        instance_eval("%@#{sql.gsub('@', '\@')}@")
      end

      # Initializes the attributes array with keys matching the columns from the linked table and
      # the values matching the corresponding default value of that column, so
      # that a new instance, or one populated from a passed-in Hash, still has all the attributes
      # that instances loaded from the database would.
      def attributes_from_column_definition
        self.class.columns.inject({}) do |attributes, column|
          attributes[column.name] = column.default unless column.name == self.class.primary_key
          attributes
        end
      end

      # Instantiates objects for all attribute classes that needs more than one constructor parameter. This is done
      # by calling new on the column type or aggregation type (through composed_of) object with these parameters.
      # So having the pairs written_on(1) = "2004", written_on(2) = "6", written_on(3) = "24", will instantiate
      # written_on (a date type) with Date.new("2004", "6", "24"). You can also specify a typecast character in the
      # parentheses to have the parameters typecasted before they're used in the constructor. Use i for Fixnum, f for Float,
      # s for String, and a for Array. If all the values for a given attribute are empty, the attribute will be set to nil.
      def assign_multiparameter_attributes(pairs)
        execute_callstack_for_multiparameter_attributes(
          extract_callstack_for_multiparameter_attributes(pairs)
        )
      end

      def instantiate_time_object(name, values)
        if Time.zone && self.class.time_zone_aware_attributes && !self.class.skip_time_zone_conversion_for_attributes.include?(name.to_sym)
          Time.zone.local(*values)
        else
          Time.time_with_datetime_fallback(@@default_timezone, *values)
        end
      end

      def execute_callstack_for_multiparameter_attributes(callstack)
        errors = []
        callstack.each do |name, values|
          klass = (self.class.reflect_on_aggregation(name.to_sym) || column_for_attribute(name)).klass
          if values.empty?
            send(name + "=", nil)
          else
            begin
              value = if Time == klass
                instantiate_time_object(name, values)
              elsif Date == klass
                begin
                  Date.new(*values)
                rescue ArgumentError => ex # if Date.new raises an exception on an invalid date
                  instantiate_time_object(name, values).to_date # we instantiate Time object and convert it back to a date thus using Time's logic in handling invalid dates
                end
              else
                klass.new(*values)
              end

              send(name + "=", value)
            rescue => ex
              errors << AttributeAssignmentError.new("error on assignment #{values.inspect} to #{name}", ex, name)
            end
          end
        end
        unless errors.empty?
          raise MultiparameterAssignmentErrors.new(errors), "#{errors.size} error(s) on assignment of multiparameter attributes"
        end
      end

      def extract_callstack_for_multiparameter_attributes(pairs)
        attributes = { }

        for pair in pairs
          multiparameter_name, value = pair
          attribute_name = multiparameter_name.split("(").first
          attributes[attribute_name] = [] unless attributes.include?(attribute_name)

          unless value.empty?
            attributes[attribute_name] <<
              [ find_parameter_position(multiparameter_name), type_cast_attribute_value(multiparameter_name, value) ]
          end
        end

        attributes.each { |name, values| attributes[name] = values.sort_by{ |v| v.first }.collect { |v| v.last } }
      end

      def type_cast_attribute_value(multiparameter_name, value)
        multiparameter_name =~ /\([0-9]*([a-z])\)/ ? value.send("to_" + $1) : value
      end

      def find_parameter_position(multiparameter_name)
        multiparameter_name.scan(/\(([0-9]*).*\)/).first.first
      end

      # Returns a comma-separated pair list, like "key1 = val1, key2 = val2".
      def comma_pair_list(hash)
        hash.inject([]) { |list, pair| list << "#{pair.first} = #{pair.last}" }.join(", ")
      end

      def quoted_column_names(attributes = attributes_with_quotes)
        connection = self.class.connection
        attributes.keys.collect do |column_name|
          connection.quote_column_name(column_name)
        end
      end

      def self.quoted_table_name
        self.connection.quote_table_name(self.table_name)
      end

      def quote_columns(quoter, hash)
        hash.inject({}) do |quoted, (name, value)|
          quoted[quoter.quote_column_name(name)] = value
          quoted
        end
      end

      def quoted_comma_pair_list(quoter, hash)
        comma_pair_list(quote_columns(quoter, hash))
      end

      def object_from_yaml(string)
        return string unless string.is_a?(String)
        YAML::load(string) rescue string
      end

      def clone_attributes(reader_method = :read_attribute, attributes = {})
        self.attribute_names.inject(attributes) do |attrs, name|
          attrs[name] = clone_attribute_value(reader_method, name)
          attrs
        end
      end

      def clone_attribute_value(reader_method, attribute_name)
        value = send(reader_method, attribute_name)
        value.duplicable? ? value.clone : value
      rescue TypeError, NoMethodError
        value
      end
  end
end
