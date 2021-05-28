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

    assert crate.payload['fish/info.txt']
    assert_equal '1234', crate.payload['fish/info.txt'].source.read.chomp
    assert crate.payload['fish/root.txt']
    assert crate.payload['fish/data/info.txt']
    assert crate.payload['fish/data/nested.txt']
    assert crate.payload['fish/data/binary.jpg']
    assert_equal ['./', 'fish/', 'ro-crate-metadata.jsonld', 'ro-crate-preview.html'], crate.entities.map(&:id).sort
  end

  test 'reading from zip to a specified target directory' do
    Dir.mktmpdir('test-1234-banana') do |dir|
      crate = ROCrate::Reader.read_zip(fixture_file('directory.zip'), target_dir: dir)

      assert crate.payload['fish/info.txt']
      assert crate.payload['fish/info.txt'].source.to_s.include?('/test-1234-banana')
    end
  end

  test 'reading from directory with directories' do
    crate = ROCrate::Reader.read_directory(fixture_file('directory_crate').path)

    assert crate.payload.values.all? { |e| e.is_a?(ROCrate::Entry) }
    assert crate.payload['fish/info.txt']
    assert_equal '1234', crate.payload['fish/info.txt'].source.read.chomp
    refute crate.payload['fish/root.txt'].directory?
    assert crate.payload['fish/data'].directory?
    assert crate.payload['fish/data/info.txt']
    refute crate.payload['fish/data/nested.txt'].remote?
    assert crate.payload['fish/data/binary.jpg']
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

    assert_equal 11, crate.payload.count
    assert crate.payload['listed_file.txt']
    assert crate.payload['unlisted_file.txt']
    assert crate.payload['fish']
    assert_equal '1234', crate.payload['fish/info.txt'].source.read.chomp
    refute crate.payload['fish/root.txt'].directory?
    assert crate.payload['fish/data'].directory?
    assert crate.payload['fish/data/info.txt']
    refute crate.payload['fish/data/nested.txt'].remote?
    assert crate.payload['fish/data/binary.jpg']
    assert_equal ['./', 'listed_file.txt', 'ro-crate-metadata.jsonld', 'ro-crate-preview.html'], crate.entities.map(&:id).sort
  end

  test 'reading from a zip with unlisted files' do
    crate = ROCrate::Reader.read_zip(fixture_file('sparse_directory_crate.zip').path)

    assert_equal 11, crate.payload.count
    assert crate.payload['listed_file.txt']
    assert crate.payload['unlisted_file.txt']
    assert crate.payload['fish']
    assert_equal '1234', crate.payload['fish/info.txt'].source.read.chomp
    refute crate.payload['fish/root.txt'].directory?
    assert crate.payload['fish/data'].directory?
    assert crate.payload['fish/data/info.txt']
    refute crate.payload['fish/data/nested.txt'].remote?
    assert crate.payload['fish/data/binary.jpg']
    assert_equal ['./', 'listed_file.txt', 'ro-crate-metadata.jsonld', 'ro-crate-preview.html'], crate.entities.map(&:id).sort
  end

  test 'reading a zip from various object types' do
    string_io = StringIO.new
    string_io.write(::File.read(fixture_file('sparse_directory_crate.zip').path))
    string_io.rewind
    assert string_io.is_a?(StringIO)
    assert_equal 11, ROCrate::Reader.read_zip(string_io).payload.count

    path = Pathname.new(fixture_file('sparse_directory_crate.zip').path)
    assert path.is_a?(Pathname)
    assert_equal 11, ROCrate::Reader.read_zip(path).payload.count

    file = ::File.open(fixture_file('sparse_directory_crate.zip').path)
    assert file.is_a?(::File)
    assert_equal 11, ROCrate::Reader.read_zip(file).payload.count

    string = fixture_file('sparse_directory_crate.zip').path
    assert string.is_a?(String)
    assert_equal 11, ROCrate::Reader.read_zip(string).payload.count
  end

  test 'reading from zip where the crate root is nested somewhere within' do
    crate = ROCrate::Reader.read_zip(fixture_file('nested_directory.zip'))

    assert crate.payload['fish/info.txt']
    assert_equal '1234', crate.payload['fish/info.txt'].source.read.chomp
    assert crate.payload['fish/root.txt']
    assert crate.payload['fish/data/info.txt']
    assert crate.payload['fish/data/nested.txt']
    assert crate.payload['fish/data/binary.jpg']
    assert_equal ['./', 'fish/', 'ro-crate-metadata.json', 'ro-crate-preview.html'], crate.entities.map(&:id).sort
  end

  test 'reading preserves any additions to @context' do
    crate = ROCrate::Reader.read_directory(fixture_file('ro-crate-galaxy-sortchangecase').path)

    context = crate.metadata.context
    assert_equal [
                     'https://w3id.org/ro/crate/1.1/context',
                     {
                         'TestSuite' => 'https://w3id.org/ro/terms/test#TestSuite',
                         'TestInstance' => 'https://w3id.org/ro/terms/test#TestInstance',
                         'TestService' => 'https://w3id.org/ro/terms/test#TestService',
                         'TestDefinition' => 'https://w3id.org/ro/terms/test#TestDefinition',
                         'PlanemoEngine' => 'https://w3id.org/ro/terms/test#PlanemoEngine',
                         'JenkinsService' => 'https://w3id.org/ro/terms/test#JenkinsService',
                         'TravisService' => 'https://w3id.org/ro/terms/test#TravisService',
                         'GithubService' => 'https://w3id.org/ro/terms/test#GithubService',
                         'instance' => 'https://w3id.org/ro/terms/test#instance',
                         'runsOn' => 'https://w3id.org/ro/terms/test#runsOn',
                         'resource' => 'https://w3id.org/ro/terms/test#resource',
                         'definition' => 'https://w3id.org/ro/terms/test#definition',
                         'engineVersion' => 'https://w3id.org/ro/terms/test#engineVersion'
                     }
                 ], context
  end
end
