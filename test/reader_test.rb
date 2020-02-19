require 'test_helper'

class ReaderTest < Test::Unit::TestCase
  def test_reading_from_directory
    crate = ROCrate::Reader.read(fixture_file('workflow-0.2.0').path)

    refute crate.dereference(".ssh/id_rsa")

    entity = crate.dereference("workflow/workflow.knime")
    assert_not_nil entity
    assert entity.is_a?(ROCrate::File)
    assert_equal 'SoftwareSourceCode', entity.type

    entity = crate.dereference("workflow/")
    assert_not_nil entity
    assert entity.is_a?(ROCrate::Directory)
    assert_equal 'Dataset', entity.type

    entity = crate.dereference("tools/RetroPath2.cwl")
    assert_not_nil entity
    assert entity.is_a?(ROCrate::File)
    assert_equal 'SoftwareSourceCode', entity.type

    entity = crate.dereference("workflow/workflow.svg")
    assert_not_nil entity
    assert entity.is_a?(ROCrate::File)
    assert_equal 'ImageObject', entity.type

    entity = crate.dereference("Dockerfile")
    assert_not_nil entity
    assert entity.is_a?(ROCrate::File)
    assert_equal 'SoftwareSourceCode', entity.type

    entity = crate.dereference("test/test.sh")
    assert_not_nil entity
    assert entity.is_a?(ROCrate::File)
    assert_equal 'SoftwareSourceCode', entity.type

    # Example is broken
    # entity = crate.dereference("README.md")
    # assert_not_nil entity
    # assert entity.is_a?(ROCrate::File)
    # assert_equal 'File', entity.type
  end

  def test_reading_from_zip
    crate = ROCrate::Reader.read(fixture_file('workflow-0.2.0.zip'))

    refute crate.dereference(".ssh/id_rsa")

    entity = crate.dereference("workflow/workflow.knime")
    assert_not_nil entity
    assert entity.is_a?(ROCrate::File)
    assert_equal 'SoftwareSourceCode', entity.type

    entity = crate.dereference("workflow/")
    assert_not_nil entity
    assert entity.is_a?(ROCrate::Directory)
    assert_equal 'Dataset', entity.type

    entity = crate.dereference("tools/RetroPath2.cwl")
    assert_not_nil entity
    assert entity.is_a?(ROCrate::File)
    assert_equal 'SoftwareSourceCode', entity.type

    entity = crate.dereference("workflow/workflow.svg")
    assert_not_nil entity
    assert entity.is_a?(ROCrate::File)
    assert_equal 'ImageObject', entity.type

    entity = crate.dereference("Dockerfile")
    assert_not_nil entity
    assert entity.is_a?(ROCrate::File)
    assert_equal 'SoftwareSourceCode', entity.type

    entity = crate.dereference("test/test.sh")
    assert_not_nil entity
    assert entity.is_a?(ROCrate::File)
    assert_equal 'SoftwareSourceCode', entity.type

    # Example is broken
    # entity = crate.dereference("README.md")
    # assert_not_nil entity
    # assert entity.is_a?(ROCrate::File)
    # assert_equal 'File', entity.type
  end

  def test_reading_from_zip_with_directories
    crate = ROCrate::Reader.read_zip(fixture_file('directory.zip'))

    assert crate.entries['fish/info.txt']
    assert_equal '1234', crate.entries['fish/info.txt'].source.read.chomp
    assert crate.entries['fish/root.txt']
    assert crate.entries['fish/data/info.txt']
    assert crate.entries['fish/data/nested.txt']
    assert crate.entries['fish/data/binary.jpg']
    assert_equal ['./', 'fish/', 'ro-crate-metadata.jsonld'], crate.entities.map(&:id).sort
  end

  def test_reading_from_directory_with_directories
    crate = ROCrate::Reader.read_directory(fixture_file('directory_crate').path)

    assert crate.entries['fish/info.txt']
    assert_equal '1234', crate.entries['fish/info.txt'].source.read.chomp
    assert crate.entries['fish/root.txt']
    assert crate.entries['fish/data/info.txt']
    assert crate.entries['fish/data/nested.txt']
    assert crate.entries['fish/data/binary.jpg']
    assert_equal ['./', 'fish/', 'ro-crate-metadata.jsonld'], crate.entities.map(&:id).sort
  end
end
