require 'test_helper'

class WriterTest < Test::Unit::TestCase
  def test_writing_to_directory
    crate = ROCrate::Crate.new
    crate.add_file(fixture_file('info.txt'))
    crate.add_file(StringIO.new('just a string!'), 'notice.txt')
    crate.add_file(fixture_file('data.csv'), 'directory/data.csv')

    Dir.mktmpdir do |dir|
      ROCrate::Writer.new(crate).write(dir)
      assert ::File.exist?(::File.join(dir, ROCrate::Metadata::IDENTIFIER))
      assert_equal 6, ::File.size(::File.join(dir, 'info.txt'))
      assert_equal 14, ::File.size(::File.join(dir, 'notice.txt'))
      assert_equal 20, ::File.size(::File.join(dir, 'directory', 'data.csv'))
    end
  end

  def test_reading_and_writing_to_same_directory
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

  def test_writing_to_zip
    crate = ROCrate::Crate.new
    crate.add_file(fixture_file('info.txt'))
    crate.add_file(fixture_file('data.csv'), 'directory/data.csv')

    Tempfile.create do |file|
      ROCrate::Writer.new(crate).write_zip(file)

      Zip::File.open(file) do |zipfile|
        assert zipfile.file.exist?(ROCrate::Metadata::IDENTIFIER)
        assert_equal 6, zipfile.file.size('info.txt')
        assert_equal 20, zipfile.file.size('directory/data.csv')
      end
    end
  end

  def test_writing_a_directory
    crate = ROCrate::Crate.new
    crate.add_directory(fixture_file('directory').path.to_s, 'fish')

    Tempfile.create do |file|
      ROCrate::Writer.new(crate).write_zip(file)

      Zip::File.open(file) do |zipfile|
        assert zipfile.file.exist?(ROCrate::Metadata::IDENTIFIER)
        assert zipfile.file.exist? 'fish/info.txt'
        assert zipfile.file.exist? 'fish/root.txt'
        assert zipfile.file.exist? 'fish/data/info.txt'
        assert zipfile.file.exist? 'fish/data/nested.txt'
        assert zipfile.file.exist? 'fish/data/binary.jpg'
      end
    end
  end
end
