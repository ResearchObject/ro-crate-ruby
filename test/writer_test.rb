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
    # Remote entries should not be written, so this 500 error should not affect anything.
    stub_request(:get, 'http://example.com/external_ref.txt').to_return(status: 500)

    crate = ROCrate::Crate.new
    crate.add_file(fixture_file('info.txt'))
    crate.add_file('http://example.com/external_ref.txt')
    crate.add_file(fixture_file('data.csv'), 'directory/data.csv')

    Tempfile.create do |file|
      ROCrate::Writer.new(crate).write_zip(file)

      Zip::File.open(file) do |zipfile|
        assert zipfile.file.exist?(ROCrate::Metadata::IDENTIFIER)
        assert zipfile.file.exist?(ROCrate::Preview::IDENTIFIER)
        refute zipfile.file.exist?('external_ref.txt')
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
        abs_file_path = ::File.join(fixture, file)
        next if ::File.directory?(abs_file_path)
        assert_equal ::File.read(abs_file_path), ::File.read(::File.join(dir, file)), "#{file} didn't match"
      end
    end
  end

  test 'reading/writing multiple times does not change the crate' do
    input_dir = fixture_file('sparse_directory_crate').path
    Dir.mktmpdir do |dir|
      3.times do |i|
        output_dir = ::File.join(dir, "new_directory_#{i}")
        crate = ROCrate::Reader.read(input_dir)

        ROCrate::Writer.new(crate).write(output_dir)
        expected_files = Dir.chdir(input_dir) { Dir.glob('**/*') }
        actual_files =  Dir.chdir(output_dir) { Dir.glob('**/*') }
        assert_equal expected_files, actual_files
        expected_files.each do |file|
          abs_file_path = ::File.join(input_dir, file)
          next if ::File.directory?(abs_file_path)
          assert_equal ::File.read(abs_file_path), ::File.read(::File.join(output_dir, file)), "#{file} didn't match"
        end

        input_dir = output_dir
      end
    end
  end

  test 'writing with conflicting paths in payload obeys specificity rules' do
    crate = ROCrate::Crate.new

    # Payload from crate
    crate.add_all(fixture_file('directory').path, false)
    Dir.mktmpdir do |dir|
      ROCrate::Writer.new(crate).write(dir)

      assert_equal "5678\n", ::File.read(::File.join(dir, 'data', 'info.txt'))
    end

    # Payload from crate + directory
    crate.add_directory(fixture_file('conflicting_data_directory').path.to_s, 'data')
    Dir.mktmpdir do |dir|
      ROCrate::Writer.new(crate).write(dir)

      assert_equal 'abcd', ::File.read(::File.join(dir, 'data', 'info.txt')), 'Directory payload should take priority over Crate.'
      assert_equal "No, I am nested!\n", ::File.read(::File.join(dir, 'data', 'nested.txt')), 'Directory payload should take priority over Crate.'
      assert ::File.exist?(::File.join(dir, 'data', 'binary.jpg'))
    end

    # Payload from crate + directory + file
    crate.add_file(StringIO.new('xyz'), 'data/info.txt')
    Dir.mktmpdir do |dir|
      ROCrate::Writer.new(crate).write(dir)

      assert_equal 'xyz', ::File.read(::File.join(dir, 'data', 'info.txt')), 'File payload should take priority over Crate and Directory.'
      assert_equal "No, I am nested!\n", ::File.read(::File.join(dir, 'data', 'nested.txt')), 'Directory payload should take priority over Crate.'
      assert ::File.exist?(::File.join(dir, 'data', 'binary.jpg'))
    end
  end

  test 'write crate with data entity that is neither file or directory' do
    crate = ROCrate::Reader.read_directory(fixture_file('misc_data_entity_crate').path)
    Dir.mktmpdir do |dir|
      ROCrate::Writer.new(crate).write(dir)
      Dir.chdir(dir) do
        file_list = Dir.glob('*').sort
        assert_equal ["ro-crate-metadata.json", "ro-crate-preview.html"], file_list
      end
    end
  end

  test 'write crate with data entity refers to a symlink as directory' do
    crate = ROCrate::Crate.new
    crate.add_all(fixture_file('workflow-test-fixture-symlink').path)
    assert crate.payload['images/workflow-diagram.png'].source.symlink?

    Dir.mktmpdir do |dir|
      ROCrate::Writer.new(crate).write(dir)
      Dir.chdir(dir) do
        assert File.symlink?('images/workflow-diagram.png')
      end
    end
  end

  test 'write crate with data entity refers to a symlink as zip' do
    crate = ROCrate::Crate.new
    crate.add_all(fixture_file('workflow-test-fixture-symlink').path)
    assert crate.payload['images/workflow-diagram.png'].source.symlink?

    Tempfile.create do |file|
      ROCrate::Writer.new(crate).write_zip(file)

      Zip::File.open(file) do |zipfile|
        assert zipfile.find_entry('images/workflow-diagram.png').symlink?
      end
    end
  end
end
