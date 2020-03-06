# ro-crate-ruby

This is a WIP gem for creating, manipulating and reading RO crates (conforming to version 1.0 of the specification).

* RO Crate - https://researchobject.github.io/ro-crate/
* RO Crate spec (1.0) - https://researchobject.github.io/ro-crate/1.0/

Example:
```ruby
require './lib/ro_crate_ruby'

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

### RO Crate Preview
A simple HTML preview page is generated when an RO Crate is written, containing a list of the crate's contents and some
metadata. This preview is written to `ro-crate-preview.html` at the root of the RO Crate.

The default template can be seen here [here](lib/ro_crate/ro-crate-preview.html.erb).

You can customize this preview by providing your own ERB file. The ERB file is evaluated using the `ROCrate` instance's `binding`.

#### Example
```ruby
crate = ROCrate::Crate.new

# ... add stuff to the crate
 
# Tell the crate to use your own template (as a string)
crate.preview.template = File.read('path_to_your_template.html.erb')

# Write it
ROCrate::Writer.new(crate).write('./an_ro_crate_directory')
```
