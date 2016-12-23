# QuickbaseRecord

QuickbaseRecord is a baller ActiveRecord-style ORM/API client for QuickBase.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'quickbase_record'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install quickbase_record

## Setup

### Initialize the API Client
First you'll need to configure QuickbaseRecord with your app's realm name (realm-name.quickbase.com) and provide a valid username, password, and application token (if applicable). Alternatively, you can supply a user token. This can be done in a single initializer file with a call to `QuickbaseRecord.configure`.

```ruby
  # config/initializers/quickbase_record.rb

  QuickbaseRecord.configure do |config|
    config.realm = "quickbase_app_realm_name"
    config.token = "quickbase_app_token_if_applicable"
    config.username = "valid_username"
    config.password = "valid_password"

    # or, instead of username/password:

    config.usertoken = "quickbase_user_token"
  end
```

### Include it in a Class
Now you can simply `include QuickbaseRecord::Model` in a class representing a QuickBase table and call the `.define_fields` method to supply the table's Database ID and a mapping of desired field names => QuickBase Field IDs.

`.define_fields` follows a similar pattern to ActiveRecord migrations. It takes a block where data types and field names are defined with a corresponding QuickBase Field ID.

```ruby
  # app/models/post.rb

  class Post
    include QuickbaseRecord::Model

    define_fields do |t|
      t.dbid 'abcde12345'
      t.date :date_created, 1, :read_only
      t.number :id, 3, :primary_key
      t.string :content, 7
      t.string :author, 8
      t.string :title, 9
      t.string :title_plus_author, 10, :read_only
    end

    # code...
  end
```

### .define_fields

`.define_fields` will create attr_accessors for all fields and parse API responses to match the configured data type. Note that values will **not** be converted to anything when sending API calls.

The following configuration options/data types are supported:

  * **dbid** *required
    - The Database ID for the QuickBase table
    - **Does not accept multiple arguments, only a string of the Database ID**
  * **string**
    - All values are converted to a String
  * **number**
    - All values are converted to a Numeric (ints or floats)
  * **date**
    - All values are converted to a string representation of the date value: ex: "07/30/2015". Does not currently work for Date/Time conversion, so you'll have to pull in Date/Time fields as strings and parse them yourself. Sorry.
  * **boolean**
    - All values are converted to true or false (QuickBase returns "1" and "0")
  * **file_attachment**
    - Doesn't really do anything, only makes you feel better :) File attachments are explained [below](#file-attachments).

Additional options may be added to field definitions:

  * **:primary_key** *required
    - Pretty obvious.
  * **:read_only**
    - Fields marked as :read_only will not be sent along 'write' API requests -- #save, #update_attributes, #create, and .save_collection.
    - Useful for formula/lookup/other fields in your QuickBase table that you can't write to.


**IMPORTANT: You must supply a "dbid" data type and mark a single field as :primary_key. Weird shit can happen if you don't. Eventually I'll throw some errors if they're missing, but for now it's the wild west.**

---
## Methods
---
## Query for Records

* **.find(id)**
  ```ruby
    Post.find(params[:id])
    Post.find(3123)
  ```
  - Query for a specific QuickBase record by it's primary key.
  - Returns a single object

* **.where(query_hash OR string in QuickBase query format)**
  ```ruby
    Post.where(author: 'Cullen Jett')
  ```
  - Query QuickBase by any field name defined in your class' field mapping
  - Returns an array of objects

  - Multiple field_name/value pairs are joined with 'AND'
  ```ruby
    Post.where(id: 1, author: 'Cullen Jett')
    # ^ is parsed to the QuickBase format: {'3'.EX.'1'}AND{'8'.EX.'Cullen Jett'}
  ```

  - Values in an array are joined with 'OR'
  ```ruby
    Post.where(author: ['Cullen Jett', 'Socrates'])
    # {'8'.EX.'Cullen Jett'}OR{'8'.EX.'Socrates'}
  ```

  - To use a comparator other than 'EX', pass the value as another hash with the key as the comparator
  ```ruby
    Post.where(author: {XEX: 'Cullen Jett'})
    # {'8'.XEX.'Cullen Jett'}

    Post.where(date_created: {OBF: 'today'})
    # {'1'.OBF.'today'}
  ```

  - Also accepts a string in the standard QuickBase query format. This way works with both field names or Field IDs.
  ```ruby
    Post.where("{'3'.EX.'1'}")
    Post.where("{author.XEX.'Cullen Jett'}")
  ```

* **.batch_where(attributes_hash, count=1000)**
  - Same as `.where`, but queries in batches of {count} since QuickBase has a limit on how much data you can get back in one go. This bad boy will call multiple queries and then concatenate all of the responses in a single array.
  ```ruby
    Post.batch_where({date_created: ['today', 'yesterday']}, 5000)
  ```

* **.qid(id)**
  - Accepts a QID (QuickBase report ID)
  - Returns an array of objects
  ```ruby
    Post.qid(1)
  ```

##### Query Options (clist, slist, options)
  To query using the QuickBase query options such as 'clist', 'slist', or 'options', include :query_options as a key and a hash of `option_property: value` as values. An example is in order:
  ```ruby
    Post.where(author: ['Cullen Jett', 'Socrates'], query_options: {clist: 'id.author', slist: 'author', options: 'num-1'})
  ```

##### Broken Query?
If you want to see the QuickBase query string output of a `.where()` query hash you can pass your query hash to the `.build_query()` method and it will return the QuickBase query.

```ruby
  Post.build_query(author: 'Cullen', title: 'Some Title')
  => "{'8'.EX.'Cullen'}AND{'9'.EX.'Some Title'}"
```

##### AdvantageQuickbase
QuickBaseRecord is built on top of the [AdvantageQuickbase gem](https://github.com/AdvantageIntegratedSolutions/Quickbase-Gem). You can access the underlying instance of the AdvantageQuickbase client with `.qb_client`. This property lives on both the class and on any instance of that class. To access the dbid for the table, call .dbid on the class.

```ruby
  Post.qb_client.do_query(...)
  @post = Post.new(...)
  @post.qb_client.edit_record(self.class.dbid, self.id, {5 => 'Something', 6 => 'Something else'})
```

## Create and Update Records
  * **.create(attributes_hash)**
    ```ruby
      Post.create(content: 'Amazing post content', author: 'Cullen Jett')
    ```
    - Instantiate *and* save a new object with the given attributes
    - Assigns the returned object it's new Record ID

  * **.save_collection(array_of_objects)**
    ```ruby
      @post1 = Post.new(content: 'Amazing post content', author: 'Cullen Jett')
      @post2 = Post.find(123)

      Post.save_collection([@post1, @post2])
    ```
    - Save an array of objects (of the same class)
    - Uses API_ImportFromCSV under the hood, so it will edit a record if it has a record ID or create one if not.
    - Returns an array of Record IDs
    - **IMPORTANT: make sure all of the objects have the same QuickBase properties (even if they have empty values). The AdvantageQuickbase gem will use the first object in the array to generate the clist.**

  * **#save**
    ```ruby
      @post = Post.new(content: 'Amazing post content', author: 'Cullen Jett')
      @post.save # => <Post: @id: 1, @content: 'Amazing post content', @author: 'Cullen Jett'

      @post.author = 'Socrates'
      @post.save # => <Post: @id: 1, @content: 'Amazing post content', @author: 'Socrates'
    ```
    - Creates a new record in QuickBase for objects that don't have an ID *or* edits the corresponding QuickBase record if the object already has an ID
    - Returns the object (if #save created a record in QuickBase the the returned object will now have an ID)

  * **#update_attributes(attributes_hash)**
    ```ruby
      @post = Post.where(author: 'Cullen Jett').first
      @post.update_attributes(author: 'Socrates', content: 'Something enlightening...') # => <Post: @id: 1, @author: 'Socrates', @content: 'Something enlightening...'
    ```
    - **IMPORTANT: Updates *and* saves the object with the new attributes**
    - Only sends the passed in attributes as arguments to API_AddRecord or API_EditRecord (depending on whether the object has an ID or not)
    - Returns the object

## Delete Records
  * **#delete**
    ```ruby
      @post = Post.find(1)
      @post.delete
    ```
    - Delete the corresponding record in QuickBase
    - It returns the object if successful or `false` if unsuccessful

  * **.purge_records(attributes_hash OR QID)**
    ```ruby
      Post.purge_records(name: 'Cullen Jett') # attributes hash
      or
      Post.purge_records(9) # QID

      => [1,2,3,4,5...]
    ```
    - Delete ALL records that match the attributes hash or are in the record corresponding to the QID argument
    - Returns an array of deleted rids
    - **CAUTION** If you do not supply a query parameter, this call will delete ALL of the records in the table.



## Misc Methods
  * **#assign_attributes(attributes_hash)**
    ```ruby
      @post = Post.where(author: 'Cullen Jett').first
      @post.assign_attributes(author: 'Socrates', content: 'Something enlightening...')
      @post.save
    ```
    - Only changes the objects attributes in memory (i.e. does not save to QuickBase)
    - Useful for assigning multiple attributes at once, otherwise you could use the field name's attr_accessor to change a single attribute.
    - Returns the object

  * **.qb_client and #qb_client**
    - Access the quickbase API client (advantage_quickbase gem) directly

## File Attachments
When ***creating*** an object with a field of type 'file attachment', you must assign it as hash with :name and :file as keys.
After the object is ***saved*** that field will then become a new hash with :filename and :url as keys.
```ruby
  @post = Post.new(attachment: {name: 'Test File Name', file: 'path/to/your/file OR file contents'})
  @post.save
  @post.attachment => {filename: 'Test File Name', url: 'https://realm.quickbase.com/up/abcdefg/Test%20File%20Name'}
```

## Testing
Unfortunately you will not be able to run the test suite unless you have access to the QuickBase application used as the test database *or* you create your own QuickBase app to test against that mimics the test fakes. Eventually the test calls will be stubbed out so anyone can test it, but I've got stuff to do -- pull requests are welcome :)

As of now the tests serve more as documentation for those who don't have access to the testing QuickBase app.

If you're lucky enough to work with me then I can grant you access to the app and you can run the suite until your fingers bleed. You'll just need to modify `spec/quickbase_record_config.rb` to use your own credentials.

## Contributing

1. Fork it ( https://github.com/cullenjett/quickbase_record/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
