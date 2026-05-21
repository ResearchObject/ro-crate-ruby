require 'simplecov'
SimpleCov.start

require 'test/unit'
require 'ro_crate'
require 'webmock/test_unit'

def teardown
  self._opened_files.each(&:close)
end

def _opened_files
  @opened_files ||= []
end

def fixture_file(name, *args)
  f = ::File.open(::File.join(fixture_dir, name), *args)
  self._opened_files << f
  f
end

def fixture_dir
  ::File.join(::File.dirname(__FILE__), 'fixtures')
end
