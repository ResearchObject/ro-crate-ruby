# ro-crate-ruby

This is a WIP gem for creating, manipulating and reading RO crates (conforming to version 1.0 of the specification).

* RO Crate - https://researchobject.github.io/ro-crate/
* RO Crate spec (1.0) - https://researchobject.github.io/ro-crate/1.0/

Example:
```ruby
require 'ro_crate_ruby'

# Make a new crate
crate = ROCrate::Crate.new
crate.add_file(File.open('Gemfile')) # Using IO-like objects
crate.add_file('README.md') # or paths

# Write to a zip file
ROCrate::Writer.new(crate).write_zip(File.new('ro_crate.zip', 'w'))

# Write to a directory
ROCrate::Writer.new(crate).write('./ro_crate_stuff')

# Read an RO crate
crate = ROCrate::Reader.read('./an_ro_crate_directory')

# Make some changes
existing_file = crate.dereference('some_data.csv')
existing_file.name = 'Some amazing data'
existing_author = existing_file.author
joe = crate.add_person('joe', { name: 'Joe Bloggs' })
file = crate.add_file('some_more_data.csv')
file.author = [joe, existing_author]

# Write it back
ROCrate::Writer.new(crate).write('./an_ro_crate_directory')
```
