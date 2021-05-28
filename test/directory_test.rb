require 'test_helper'

class DirectoryTest < Test::Unit::TestCase
  test 'adding directory via file' do
    crate = ROCrate::Crate.new
    crate.add_directory(fixture_file('directory'))

    payload = crate.payload
    base_path = ::File.dirname(fixture_file('directory'))
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/info.txt')), payload['directory/info.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/root.txt')), payload['directory/root.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data')), payload['directory/data'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data/info.txt')), payload['directory/data/info.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data/nested.txt')), payload['directory/data/nested.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data/binary.jpg')), payload['directory/data/binary.jpg'].path
  end

  test 'adding directory via path' do
    crate = ROCrate::Crate.new
    crate.add_directory(fixture_file('directory').path.to_s)

    payload = crate.payload
    base_path = ::File.dirname(fixture_file('directory'))
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/info.txt')), payload['directory/info.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/root.txt')), payload['directory/root.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data')), payload['directory/data'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data/info.txt')), payload['directory/data/info.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data/nested.txt')), payload['directory/data/nested.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data/binary.jpg')), payload['directory/data/binary.jpg'].path
  end

  test 'adding to given path' do
    crate = ROCrate::Crate.new
    crate.add_directory(fixture_file('directory').path.to_s, 'fish')

    payload = crate.payload
    base_path = ::File.dirname(fixture_file('directory'))
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/info.txt')), payload['fish/info.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/root.txt')), payload['fish/root.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data')), payload['fish/data'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data/info.txt')), payload['fish/data/info.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data/nested.txt')), payload['fish/data/nested.txt'].path
    assert_equal ::File.expand_path(::File.join(base_path, 'directory/data/binary.jpg')), payload['fish/data/binary.jpg'].path
  end
end
