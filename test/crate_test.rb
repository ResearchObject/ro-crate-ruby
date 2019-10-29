require 'test_helper'

class CrateTest < Test::Unit::TestCase

  def test_dereferencing
    crate = ROCrate::Crate.new
    info = crate.add_file(fixture_file('info.txt'), path: 'the_info.txt')
    more_info = crate.add_file(fixture_file('info.txt'), path: 'directory/more_info.txt')

    assert_equal crate, crate.dereference('./')
    assert_equal crate.metadata, crate.dereference('ro-crate-metadata.jsonld')
    assert_equal info, crate.dereference('./the_info.txt')
    assert_equal more_info, crate.dereference('./directory/more_info.txt')
    assert_nil crate.dereference('./directory/blabla.zip')
  end

  def test_dereferencing_equivalent_ids
    crate = ROCrate::Reader.read(fixture_file('workflow-0.2.0').path)
    workflow = crate.parts.first

    assert_equal crate, crate.dereference('./')
    assert_equal crate, crate.dereference('.')
    assert_equal crate.metadata, crate.dereference('ro-crate-metadata.jsonld')
    assert_equal crate.metadata, crate.dereference('./ro-crate-metadata.jsonld')
    assert_equal workflow, crate.dereference('./workflow/workflow.knime')
    assert_equal workflow, crate.dereference('workflow/workflow.knime')
  end
end
