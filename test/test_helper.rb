require 'simplecov'
SimpleCov.start

require 'test/unit'
require 'ro_crate'
require 'webmock/test_unit'

def fixture_file(name, *args)
  ::File.open(::File.join(::File.dirname(__FILE__), 'fixtures', name), *args)
end
