# encoding: utf-8
require 'test_helper'

class EntryTest < Test::Unit::TestCase
  setup do
    stub_request(:get, 'http://example.com/dir/file.txt').to_return(status: 200, body: 'file contents')
    stub_request(:get, 'http://example.com/dir/').to_return(status: 200, body: '<html>...')

    @local_file = ROCrate::Entry.new(fixture_file('info.txt'))
    @local_path = ROCrate::Entry.new(Pathname.new(fixture_dir).join('directory', 'info.txt'))
    @local_io = ROCrate::Entry.new(StringIO.new('stringio'))
    @local_dir = ROCrate::Entry.new(Pathname.new(fixture_dir).join('directory'))
    @local_symlink = ROCrate::Entry.new(Pathname.new(fixture_dir).join('symlink'))
    @local_dir_symlink = ROCrate::Entry.new(Pathname.new(fixture_dir).join('dir_symlink'))
    @remote_file = ROCrate::RemoteEntry.new(URI('http://example.com/dir/file.txt'))
    @remote_dir = ROCrate::RemoteEntry.new(URI('http://example.com/dir/'), directory: true)
  end

  test 'read' do
    assert_equal "Hello\n", @local_file.read
    assert_equal "1234\n", @local_path.read
    assert_equal "stringio", @local_io.read
    assert_raises(Errno::EISDIR) { @local_dir.read }
    assert_raises(Errno::EISDIR) { @local_dir_symlink.read }
    assert_equal "I have spaces in my name\n", @local_symlink.read
    assert_equal "file contents", @remote_file.read
    assert_equal "<html>...", @remote_dir.read
  end

  test 'write_to' do
    dest = StringIO.new
    @local_file.write_to(dest)
    dest.rewind
    assert_equal "Hello\n", dest.read

    dest = StringIO.new
    @local_path.write_to(dest)
    dest.rewind
    assert_equal "1234\n", dest.read

    dest = StringIO.new
    @local_io.write_to(dest)
    dest.rewind
    assert_equal "stringio", dest.read

    assert_raises(Errno::EISDIR) { @local_dir.write_to(dest) }

    assert_raises(Errno::EISDIR) { @local_dir_symlink.write_to(dest) }

    dest = StringIO.new
    @local_symlink.write_to(dest)
    dest.rewind
    assert_equal "I have spaces in my name\n", dest.read

    dest = StringIO.new
    @remote_file.write_to(dest)
    dest.rewind
    assert_equal "file contents", dest.read

    dest = StringIO.new
    @remote_dir.write_to(dest)
    dest.rewind
    assert_equal "<html>...", dest.read
  end

  test 'directory?' do
    refute @local_file.directory?
    refute @local_path.directory?
    refute @local_io.directory?
    assert @local_dir.directory?
    refute @local_symlink.directory?
    assert @local_dir_symlink.directory?
    refute @remote_file.directory?
    assert @remote_dir.directory?
  end

  test 'symlink?' do
    refute @local_file.symlink?
    refute @local_path.symlink?
    refute @local_io.symlink?
    refute @local_dir.symlink?
    assert @local_symlink.symlink?
    assert @local_dir_symlink.symlink?
    refute @remote_file.symlink?
    refute @remote_dir.symlink?
  end

  test 'remote?' do
    refute @local_file.remote?
    refute @local_path.remote?
    refute @local_io.remote?
    refute @local_dir.remote?
    refute @local_symlink.remote?
    refute @local_dir_symlink.remote?
    assert @remote_file.remote?
    assert @remote_dir.remote?
  end

  test 'path' do
    base = Pathname.new(fixture_dir).expand_path.to_s
    assert_equal "#{base}/info.txt", @local_file.path
    assert_equal "#{base}/directory/info.txt", @local_path.path
    assert_nil @local_io.path
    assert_equal "#{base}/directory", @local_dir.path
    assert_equal "#{base}/symlink", @local_symlink.path
    assert_equal "#{base}/dir_symlink", @local_dir_symlink.path
    assert_nil @remote_file.path
    assert_nil @remote_dir.path
  end
end
