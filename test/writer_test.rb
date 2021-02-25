require 'test_helper'

class WriterTest < Test::Unit::TestCase
  test 'writing to directory' do
    crate = ROCrate::Crate.new
    crate.add_file(fixture_file('info.txt'))
    crate.add_file(StringIO.new('just a string!'), 'notice.txt')
    crate.add_file(fixture_file('data.csv'), 'directory/data.csv')

    Dir.mktmpdir do |dir|
      ROCrate::Writer.new(crate).write(dir)
      assert ::File.exist?(::File.join(dir, ROCrate::Metadata::IDENTIFIER))
      assert ::File.exist?(::File.join(dir, ROCrate::Preview::IDENTIFIER))
      assert_equal 6, ::File.size(::File.join(dir, 'info.txt'))
      assert_equal 14, ::File.size(::File.join(dir, 'notice.txt'))
      assert_equal 20, ::File.size(::File.join(dir, 'directory', 'data.csv'))
    end
  end

  test 'reading and writing to same directory' do
    Dir.mktmpdir do |dir|
      FileUtils.cp_r(fixture_file('workflow-0.2.0').path, dir)
      dir = ::File.join(dir, 'workflow-0.2.0')
      crate = ROCrate::Reader.read(dir)
      crate.add_file(fixture_file('info.txt'))

      ROCrate::Writer.new(crate).write(dir)
      assert_equal 6, ::File.size(::File.join(dir, 'info.txt'))
      assert_equal 1257, ::File.size(::File.join(dir, 'README.md'))
      assert_equal 24157, ::File.size(::File.join(dir, 'workflow', 'workflow.knime'))
    end
  end

  test 'reading and writing to same directory without overwriting' do
    Dir.mktmpdir do |dir|
      FileUtils.cp_r(fixture_file('workflow-0.2.0').path, dir)
      dir = ::File.join(dir, 'workflow-0.2.0')
      crate = ROCrate::Reader.read(dir)
      ::File.write(::File.join(dir, 'test.txt'), 'original') # Add an existing file to the directory.
      crate.add_file(StringIO.new('modified'), 'test.txt') # Also add a file with the same path, but different content to the crate.

      ROCrate::Writer.new(crate).write(dir, overwrite: false)
      assert_equal 'original', ::File.read(::File.join(dir, 'test.txt')), 'Existing file should not have been overwritten since `skip_existing` is true.'
      assert_equal 1257, ::File.size(::File.join(dir, 'README.md'))
      assert_equal 24157, ::File.size(::File.join(dir, 'workflow', 'workflow.knime'))
    end
  end

  test 'writing to zip' do
    crate = ROCrate::Crate.new
    crate.add_file(fixture_file('info.txt'))
    crate.add_file(fixture_file('data.csv'), 'directory/data.csv')

    Tempfile.create do |file|
      ROCrate::Writer.new(crate).write_zip(file)

      Zip::File.open(file) do |zipfile|
        assert zipfile.file.exist?(ROCrate::Metadata::IDENTIFIER)
        assert zipfile.file.exist?(ROCrate::Preview::IDENTIFIER)
        assert_equal 6, zipfile.file.size('info.txt')
        assert_equal 20, zipfile.file.size('directory/data.csv')
      end
    end
  end

  test 'writing a crate with a directory' do
    crate = ROCrate::Crate.new
    crate.add_directory(fixture_file('directory').path.to_s, 'fish')

    Tempfile.create do |file|
      ROCrate::Writer.new(crate).write_zip(file)

      Zip::File.open(file) do |zipfile|
        assert zipfile.file.exist?(ROCrate::Metadata::IDENTIFIER)
        assert zipfile.file.exist?(ROCrate::Preview::IDENTIFIER)
        assert zipfile.file.exist? 'fish/info.txt'
        assert zipfile.file.exist? 'fish/root.txt'
        assert zipfile.file.exist? 'fish/data/info.txt'
        assert zipfile.file.exist? 'fish/data/nested.txt'
        assert zipfile.file.exist? 'fish/data/binary.jpg'
      end
    end
  end

  test 'do not try and write external files' do
    stub_request(:get, "http://example.com/external_ref.txt").to_return(status: 500)

    crate = ROCrate::Crate.new
    crate.add_file(fixture_file('info.txt'))
    crate.add_external_file('http://example.com/external_ref.txt')

    Dir.mktmpdir do |dir|
      ROCrate::Writer.new(crate).write(dir)
      assert ::File.exist?(::File.join(dir, ROCrate::Metadata::IDENTIFIER))
      assert ::File.exist?(::File.join(dir, ROCrate::Preview::IDENTIFIER))
      Dir.chdir(dir) do
        file_list = Dir.glob('*').sort
        assert_equal file_list, [ROCrate::Metadata::IDENTIFIER, ROCrate::Preview::IDENTIFIER, 'info.txt'].sort
      end
    end
  end

  test 'should write out same contents that it was created with' do
    crate = ROCrate::Crate.new
    crate.add_all(fixture_file('directory').path, false)

    Dir.mktmpdir do |dir|
      ROCrate::Writer.new(crate).write(dir)
      assert ::File.exist?(::File.join(dir, ROCrate::Metadata::IDENTIFIER))
      assert ::File.exist?(::File.join(dir, ROCrate::Preview::IDENTIFIER))
      assert_equal 5, ::File.size(::File.join(dir, 'info.txt'))
      assert_equal 2529, ::File.size(::File.join(dir, 'data', 'binary.jpg'))
    end
  end

  test 'reading and writing out a directory crate produces an identical crate' do
    fixture = fixture_file('sparse_directory_crate').path
    Dir.mktmpdir do |dir|
      dir = ::File.join(dir, 'new_directory')
      crate = ROCrate::Reader.read(fixture)

      ROCrate::Writer.new(crate).write(dir)
      expected_files = Dir.chdir(fixture) { Dir.glob('**/*') }
      actual_files =  Dir.chdir(dir) { Dir.glob('**/*') }
      assert_equal expected_files, actual_files
      expected_files.each do |file|
        next if file == 'ro-crate-metadata.jsonld' # Expected context gets updated.
        next if file == 'ro-crate-preview.html' # RO-Crate preview format changed
        abs_file_path = ::File.join(fixture, file)
        next if ::File.directory?(abs_file_path)
        assert_equal ::File.read(abs_file_path), ::File.read(::File.join(dir, file)), "#{file} didn't match"
      end
    end
  end
end
