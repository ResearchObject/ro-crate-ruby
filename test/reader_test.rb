require 'test_helper'

class ReaderTest < Test::Unit::TestCase
  def test_reading_from_directory
    crate = ROCrate::Reader.read(fixture_file('workflow-0.2.0').path)
    refute crate.dereference(".ssh/id_rsa")
    assert crate.dereference("workflow/workflow.knime")
    assert crate.dereference("workflow/")
    assert crate.dereference("tools/RetroPath2.cwl")
    assert crate.dereference("workflow/workflow.svg")
    assert crate.dereference("Dockerfile")
    assert crate.dereference("test/test.sh")
    assert crate.dereference("README.md")
  end

  def test_reading_from_zip
    crate = ROCrate::Reader.read(fixture_file('workflow-0.2.0.zip'))
    refute crate.dereference(".ssh/id_rsa")
    assert crate.dereference("workflow/workflow.knime")
    assert crate.dereference("workflow/")
    assert crate.dereference("tools/RetroPath2.cwl")
    assert crate.dereference("workflow/workflow.svg")
    assert crate.dereference("Dockerfile")
    assert crate.dereference("test/test.sh")
    assert crate.dereference("README.md")
  end
end
