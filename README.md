# ro-crate-ruby

This is a WIP gem for creating, manipulating and reading RO-Crates (conforming to version 1.1 of the specification).

* RO-Crate - https://researchobject.github.io/ro-crate/
* RO-Crate spec (1.1) - https://researchobject.github.io/ro-crate/1.1/

## Installation

Using bundler, add the following to your Gemfile:

```
gem 'ro-crate'
```

and run `bundle install`.

## Usage

This gem consists a hierarchy of classes to model RO-Crate "entities": the crate itself, data entities 
(files and directory) and contextual entities (with a limited set of specializations, such as `ROCrate::Person`). 
They are all descendents of the `ROCrate::Entity` class, with the `ROCrate::Crate` class representing the crate itself. 

The `ROCrate::Reader` class handles reading of RO-Crates into the above model, from a Zip file or directory.

The `ROCrate::Writer` class can write out an `ROCrate::Crate` instance into a Zip file or directory.

**Note:** for performance reasons, the gem is currently not linked-data aware and will allow you to set properties that 
are not semantically valid.

### Entities
Entities correspond to entries in the `@graph` of the RO-Crate's metadata JSON-LD file. Each entity class is 
basically a wrapper around a set of JSON properties, with some convenience methods for getting/setting some 
commonly used properties (`crate.name = "My first crate"`).
 
These convenience getter/setter methods will automatically handle turning objects into references and adding them to the 
`@graph` if necessary.

##### Getting/Setting Arbitrary Properties of Entities
As well as using the pre-defined getter/setter methods, you can get/set arbitrary properties like so.

To set the "creativeWorkStatus" property of the RO-Crate itself to a string literal:
```ruby
crate['creativeWorkStatus'] = 'work-in-progress'
```

If you want to reference other entities in the crate, you can get a JSON-LD reference from an entity object by using the `reference` method:
```ruby
joe = crate.add_person('joe', { name: 'Joe Bloggs' }) # Add the entity to the @graph
crate['copyrightHolder'] = joe.reference # Reference the entity from the "copyrightHolder" property
```
and to resolve those references back to the object, use the `dereference` method:
```ruby
joe = crate['copyrightHolder'].dereference
```

### Documentation

[Click here for API documentation](https://www.researchobject.org/ro-crate-ruby/).

### Examples

```ruby
require 'ro_crate'

# Make a new crate
crate = ROCrate::Crate.new
crate.add_file(File.open('Gemfile')) # Using IO-like objects
crate.add_file('README.md') # or paths

# Quickly add everything from a directory into the crate
crate = ROCrate::Crate.new
crate.add_all('workspace/secret_project/dataset123')

# Write to a zip file
ROCrate::Writer.new(crate).write_zip(File.new('ro_crate.zip', 'w'))

# Write to a directory
ROCrate::Writer.new(crate).write('./ro_crate_stuff')

# Read an RO-Crate
crate = ROCrate::Reader.read('./an_ro_crate_directory')

# Make some changes
existing_file = crate.dereference('some_data.csv')
existing_file.name = 'Some amazing data'
existing_author = existing_file.author
joe = crate.add_person('joe', { name: 'Joe Bloggs' })
file = crate.add_file('some_more_data.csv')
file.author = [joe, existing_author]

# Add an external file
ext_file = crate.add_external_file('https://example.com/my_file.txt')

# Write it back
ROCrate::Writer.new(crate).write('./an_ro_crate_directory')
```

### RO-Crate Preview
A simple HTML preview page is generated when an RO-Crate is written, containing a list of the crate's contents and some
metadata. This preview is written to `ro-crate-preview.html` at the root of the RO-Crate.

The default template can be seen here [here](lib/ro_crate/ro-crate-preview.html.erb).

You can customize this preview by providing your own ERB file. 
The ERB file is evaluated using the `ROCrate::Crate` instance's `binding`.

#### Example

```ruby
crate = ROCrate::Crate.new

# ... add stuff to the crate
 
# Tell the crate to use your own template (as a string)
crate.preview.template = File.read('path_to_your_template.html.erb')

# Write it
ROCrate::Writer.new(crate).write('./an_ro_crate_directory')
```
