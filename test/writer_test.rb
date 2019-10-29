require 'test_helper'

class WriterTest < Test::Unit::TestCase
  def test_writing_to_directory
    crate = ROCrate::Crate.new
    crate.add_file(fixture_file('info.txt'))
    crate.add_file(fixture_file('data.csv'))

    Dir.mktmpdir do |dir|
      ROCrate::Writer.new(crate).write(dir)
      assert ::File.exist?(::File.join(dir, ROCrate::Metadata::FILENAME))
      assert ::File.exist?(::File.join(dir, 'info.txt'))
      assert ::File.exist?(::File.join(dir, 'data.csv'))
    end
  end

  def test_writing_to_zip
    crate = ROCrate::Crate.new
    crate.add_file(fixture_file('info.txt'))
    crate.add_file(fixture_file('data.csv'))

    Tempfile.create do |file|
      ROCrate::Writer.new(crate).write_zip(file)

      Zip::File.open(file) do |zipfile|
        assert zipfile.file.exist?(ROCrate::Metadata::FILENAME)
        assert zipfile.file.exist?('info.txt')
        assert zipfile.file.exist?('data.csv')
      end
    end
  end
end
