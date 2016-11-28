mongoid-encrypted-fields
========================
[![Build Status](https://secure.travis-ci.org/KoanHealth/mongoid-encrypted-fields.png?branch=master&.png)](http://travis-ci.org/KoanHealth/mongoid-encrypted-fields)
[![Code Climate](https://codeclimate.com/github/KoanHealth/mongoid-encrypted-fields.png)](https://codeclimate.com/github/KoanHealth/mongoid-encrypted-fields)

New Maintainer Needed
=====================
We are actively seeking a new maintainer for this gem!  As we no longer use MongoDB as part of our platform, we aren't using the gem for ourselves.  As MongoDB and Mongoid continually change, we want to make sure our gem keeps up.

If you're interested, please contact us!  Thanks

Description
===========
A library for storing encrypted data in Mongo using Mongoid.  We looked at a few alternatives, but wanted something that stored the values securely and unobtrusively.

Mongoid 3 supports [custom types](http://mongoid.org/en/mongoid/docs/documents.html) that need to only provide a simple interface - allowing us to extend core Ruby types to secure any type while providing a clean interface for developers.

Queries encrypt data before searching the database, so equality matches work automatically.

## Prerequisites
* >= Ruby 1.9.3
* >= [Mongoid](http://mongoid.org) 3.0+
* "Bring your own" encryption, see below

## Install
    gem 'mongoid-encrypted-fields'

## Searchable vs. Unsearchable

* Default encrypted fields use a global salt so the same value produces the same encrypted output.  Queries work by first encrypting the search term, then searching for the encrypted value.
* Unsearchable encrypted fields use a unique salt each time a value is encrypted.  Encrypting the same value multiple times will generate unique encrypted outputs each time.  Queries on unsearchable encrypted fields are not possible.

## Usage
* Configure the ciphers to be used for encrypting field values:

    GibberishCipher can be found in examples - uses the [Gibberish](https://github.com/mdp/gibberish) gem:
```Ruby
    Mongoid::EncryptedFields.cipher = GibberishCipher.new(ENV['MY_PASSWORD'], ENV['MY_SALT'])
    Mongoid::EncryptedFields.unsearchable_cipher = GibberishCipher.new(ENV['MY_PASSWORD'])
```

* Use encrypted types for fields in your models:
    ```Ruby
    class Person
        include Mongoid::Document

        field :ssn, type: Mongoid::EncryptedString              #can search for Person with ssn
        field :name, type: Mongoid::UnsearchableEncryptedString #don't need to search based on name
    end
    ```
* The field getter returns the unencrypted value:
    ```Ruby
    person = Person.new(ssn: '123456789')
    person.ssn # => '123456789'
    ```
* The encrypted value is accessible with the "encrypted" attribute
    ```Ruby
    person.ssn.encrypted # => <encrypted string>

    # It can also be accessed using the hash syntax supported by Mongoid
    person[:ssn] # => <encrypted string>
    ```
* Finding a model by an encrypted field works automatically (equality only):
    ```Ruby
    Person.where(ssn: '123456789').count() # ssn is encrypted before querying the database
    Person.where(name: 'John Doe').count() # does not work!  uses a new salt each time the value is encrypted
    ```
* The Mongoid uniqueness validator is patched to detect encrypted fields:
    ```Ruby
    class Person
        ...
        field :ssn, type: Mongoid::EncryptedString
        validates_uniqueness_of :ssn, case_sensitive: true # Works as expected
        validates_uniqueness_of :ssn, case_sensitive: false # Raises exception - encrypted field cannot support a case insensitive match
        validates_uniqueness_of :name # Raises exception - unsearchable encrypted field does not support match query
    end

    Person.create!(name: 'Bill', ssn: '123456789')
    Person.create!(name: 'Ted', ssn: '123456789') #=> fails with uniqueness error
    ```

## Known Limitations
* Currently can encrypt these [Mongoid types](http://mongoid.org/en/mongoid/docs/documents.html#fields)
  * Date
  * DateTime
  * Hash
  * String
  * Time
* The uniqueness validator for encrypted fields is always case-sensitive.  Using it with case-sensitive false raises an exception.
* Queries for unsearchable encrypted fields do not work.

## Related Articles
* [Storing Encrypted Data in MongoDB](http://jerryclinesmith.me/blog/2013/03/29/storing-encrypted-data-in-mongodb/)
* [Transparently Adding Encrypted Fields to a Rails App using Mongoid](http://blog.thesparktree.com/post/69538763994/transparently-adding-encrypted-fields-to-a-rails-app)

## Copyright
(c) 2012 Koan Health. See LICENSE.txt for further details.
