# ro-crate-ruby

Example:
```
  crate = ROCrate::Crate.new
  crate.add(StringIO.new(''))
  crate.add(StringIO.new(''))
  crate.add(StringIO.new(''))
  crate.write_zip(File.new('ro_crate.zip', 'w'))
```
