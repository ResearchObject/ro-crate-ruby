require 'test_helper'

class ReaderTest < Test::Unit::TestCase
  test 'reading from directory' do
    crate = ROCrate::Reader.read(fixture_file('workflow-0.2.0').path)

    refute crate.dereference('.ssh/id_rsa')

    entity = crate.dereference('workflow/workflow.knime')
    assert_not_nil entity
    assert entity.is_a?(ROCrate::File)
    assert_equal 'SoftwareSourceCode', entity.type

    entity = crate.dereference('workflow/')
    assert_not_nil entity
    assert entity.is_a?(ROCrate::Directory)
    assert_equal 'Dataset', entity.type

    entity = crate.dereference('tools/RetroPath2.cwl')
    assert_not_nil entity
    assert entity.is_a?(ROCrate::File)
    assert_equal 'SoftwareSourceCode', entity.type

    entity = crate.dereference('workflow/workflow.svg')
    assert_not_nil entity
    assert entity.is_a?(ROCrate::File)
    assert_equal 'ImageObject', entity.type

    entity = crate.dereference('Dockerfile')
    assert_not_nil entity
    assert entity.is_a?(ROCrate::File)
    assert_equal 'SoftwareSourceCode', entity.type

    entity = crate.dereference('test/test.sh')
    assert_not_nil entity
    assert entity.is_a?(ROCrate::File)
    assert_equal 'SoftwareSourceCode', entity.type

    # Example is broken
    # entity = crate.dereference('README.md')
    # assert_not_nil entity
    # assert entity.is_a?(ROCrate::File)
    # assert_equal 'File', entity.type
  end

  test 'reading from zip' do
    crate = ROCrate::Reader.read(fixture_file('workflow-0.2.0.zip'))

    refute crate.dereference('.ssh/id_rsa')

    entity = crate.dereference('workflow/workflow.knime')
    assert_not_nil entity
    assert entity.is_a?(ROCrate::File)
    assert_equal 'SoftwareSourceCode', entity.type

    entity = crate.dereference('workflow/')
    assert_not_nil entity
    assert entity.is_a?(ROCrate::Directory)
    assert_equal 'Dataset', entity.type

    entity = crate.dereference('tools/RetroPath2.cwl')
    assert_not_nil entity
    assert entity.is_a?(ROCrate::File)
    assert_equal 'SoftwareSourceCode', entity.type

    entity = crate.dereference('workflow/workflow.svg')
    assert_not_nil entity
    assert entity.is_a?(ROCrate::File)
    assert_equal 'ImageObject', entity.type

    entity = crate.dereference('Dockerfile')
    assert_not_nil entity
    assert entity.is_a?(ROCrate::File)
    assert_equal 'SoftwareSourceCode', entity.type

    entity = crate.dereference('test/test.sh')
    assert_not_nil entity
    assert entity.is_a?(ROCrate::File)
    assert_equal 'SoftwareSourceCode', entity.type

    # Example is broken
    # entity = crate.dereference('README.md')
    # assert_not_nil entity
    # assert entity.is_a?(ROCrate::File)
    # assert_equal 'File', entity.type
  end

  test 'reading from zip with directories' do
    crate = ROCrate::Reader.read_zip(fixture_file('directory.zip'))

    assert crate.entries['fish/info.txt']
    assert_equal '1234', crate.entries['fish/info.txt'].source.read.chomp
    assert crate.entries['fish/root.txt']
    assert crate.entries['fish/data/info.txt']
    assert crate.entries['fish/data/nested.txt']
    assert crate.entries['fish/data/binary.jpg']
    assert_equal ['./', 'fish/', 'ro-crate-metadata.jsonld', 'ro-crate-preview.html'], crate.entities.map(&:id).sort
  end

  test 'reading from zip to a specified target directory' do
    Dir.mktmpdir('test-1234-banana') do |dir|
      crate = ROCrate::Reader.read_zip(fixture_file('directory.zip'), target_dir: dir)

      assert crate.entries['fish/info.txt']
      assert crate.entries['fish/info.txt'].source.to_s.include?('/test-1234-banana')
    end
  end

  test 'reading from directory with directories' do
    crate = ROCrate::Reader.read_directory(fixture_file('directory_crate').path)

    assert crate.entries.values.all? { |e| e.is_a?(ROCrate::Entry) }
    assert crate.entries['fish/info.txt']
    assert_equal '1234', crate.entries['fish/info.txt'].source.read.chomp
    refute crate.entries['fish/root.txt'].directory?
    assert crate.entries['fish/data'].directory?
    assert crate.entries['fish/data/info.txt']
    refute crate.entries['fish/data/nested.txt'].remote?
    assert crate.entries['fish/data/binary.jpg']
    assert_equal ['./', 'fish/', 'ro-crate-metadata.jsonld', 'ro-crate-preview.html'], crate.entities.map(&:id).sort
  end

  test 'reading does not double-encode encoded IDs' do
    crate = ROCrate::Reader.read_directory(fixture_file('spaces').path)
    file = crate.dereference('file with spaces.txt')
    assert file
    assert_equal 'file%20with%20spaces.txt', file.id

    # Write/Read the crate 3 times to ensure!
    Tempfile.create do |file|
      ROCrate::Writer.new(crate).write_zip(file)
      crate = ROCrate::Reader.read_zip(file)
      Tempfile.create do |file|
        ROCrate::Writer.new(crate).write_zip(file)
        crate = ROCrate::Reader.read_zip(file)
        Tempfile.create do |file|
          ROCrate::Writer.new(crate).write_zip(file)
          crate = ROCrate::Reader.read_zip(file)
          file = crate.dereference('file with spaces.txt')
          assert file
          assert_equal 'file%20with%20spaces.txt', file.id
        end
      end
    end
  end

  test 'can read a 1.1 spec crate' do
    stub_request(:get, "http://example.com/external_ref.txt").to_return(status: 200, body: 'file contents')

    crate = ROCrate::Reader.read_directory(fixture_file('crate-spec1.1').path)
    file = crate.dereference('file with spaces.txt')
    assert file
    assert file.is_a?(ROCrate::File)
    refute file.remote?
    assert file.source.is_a?(ROCrate::Entry)
    assert_equal 'file%20with%20spaces.txt', file.id

    ext_file = crate.dereference('http://example.com/external_ref.txt')
    assert ext_file
    assert ext_file.is_a?(ROCrate::File)
    assert ext_file.remote?
    assert ext_file.source.is_a?(ROCrate::RemoteEntry)
    assert_equal 'http://example.com/external_ref.txt', ext_file.id
    assert_equal 'file contents', ext_file.source.read
  end

  test 'reading from directory with unlisted files' do
    crate = ROCrate::Reader.read_directory(fixture_file('sparse_directory_crate').path)

    assert_equal 11, crate.entries.count
    assert crate.entries['listed_file.txt']
    assert crate.entries['unlisted_file.txt']
    assert crate.entries['fish']
    assert_equal '1234', crate.entries['fish/info.txt'].source.read.chomp
    refute crate.entries['fish/root.txt'].directory?
    assert crate.entries['fish/data'].directory?
    assert crate.entries['fish/data/info.txt']
    refute crate.entries['fish/data/nested.txt'].remote?
    assert crate.entries['fish/data/binary.jpg']
    assert_equal ['./', 'listed_file.txt', 'ro-crate-metadata.jsonld', 'ro-crate-preview.html'], crate.entities.map(&:id).sort
  end

  test 'reading from a zip with unlisted files' do
    crate = ROCrate::Reader.read_zip(fixture_file('sparse_directory_crate.zip').path)

    assert_equal 11, crate.entries.count
    assert crate.entries['listed_file.txt']
    assert crate.entries['unlisted_file.txt']
    assert crate.entries['fish']
    assert_equal '1234', crate.entries['fish/info.txt'].source.read.chomp
    refute crate.entries['fish/root.txt'].directory?
    assert crate.entries['fish/data'].directory?
    assert crate.entries['fish/data/info.txt']
    refute crate.entries['fish/data/nested.txt'].remote?
    assert crate.entries['fish/data/binary.jpg']
    assert_equal ['./', 'listed_file.txt', 'ro-crate-metadata.jsonld', 'ro-crate-preview.html'], crate.entities.map(&:id).sort
  end
end
