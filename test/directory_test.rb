require 'test_helper'

class DirectoryTest < Test::Unit::TestCase
  test 'adding directory via file' do
    crate = ROCrate::Crate.new
    crate.add_directory(fixture_file('directory'))

    entries = crate.entries
    base_path = ::File.dirname(fixture_file('directory'))
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/info.txt')), entries['directory/info.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/root.txt')), entries['directory/root.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data')), entries['directory/data'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data/info.txt')), entries['directory/data/info.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data/nested.txt')), entries['directory/data/nested.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data/binary.jpg')), entries['directory/data/binary.jpg'].path
  end

  test 'adding directory via path' do
    crate = ROCrate::Crate.new
    crate.add_directory(fixture_file('directory').path.to_s)

    entries = crate.entries
    base_path = ::File.dirname(fixture_file('directory'))
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/info.txt')), entries['directory/info.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/root.txt')), entries['directory/root.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data')), entries['directory/data'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data/info.txt')), entries['directory/data/info.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data/nested.txt')), entries['directory/data/nested.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data/binary.jpg')), entries['directory/data/binary.jpg'].path
  end

  test 'adding to given path' do
    crate = ROCrate::Crate.new
    crate.add_directory(fixture_file('directory').path.to_s, 'fish')

    entries = crate.entries
    base_path = ::File.dirname(fixture_file('directory'))
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/info.txt')), entries['fish/info.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/root.txt')), entries['fish/root.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data')), entries['fish/data'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data/info.txt')), entries['fish/data/info.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data/nested.txt')), entries['fish/data/nested.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data/binary.jpg')), entries['fish/data/binary.jpg'].path
  end
end
