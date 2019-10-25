# ro-crate-ruby

Example:
```
require './lib/ro_crate_ruby'

crate = ROCrate::Crate.new
crate.add_file(File.open("Gemfile"))
crate.add_file(File.open("README.md"))

# Write to a zip file
ROCrate::Writer.new(crate).write_zip(File.new('ro_crate.zip', 'w'))

# Write to a directory
ROCrate::Writer.new(crate).write('./ro_crate_stuff')
```
