require 'test_helper'

class EntityTest < Test::Unit::TestCase
  CONTEXTUAL_ID_PATTERN = /\#\h{8}\-\h{4}\-\h{4}\-\h{4}\-\h{12}/
  DATA_ID_PATTERN = /\.\/\h{8}\-\h{4}\-\h{4}\-\h{4}\-\h{12}/
  DIR_ID_PATTERN = /\.\/\h{8}\-\h{4}\-\h{4}\-\h{4}\-\h{12}\//

  def test_automatic_ids
    crate = ROCrate::Crate.new

    assert_equal './', crate.id
    assert_equal 'ro-crate-metadata.jsonld', crate.metadata.id
    assert_match CONTEXTUAL_ID_PATTERN, ROCrate::Person.new(crate).id
    assert_match CONTEXTUAL_ID_PATTERN, ROCrate::Organization.new(crate).id
    assert_match CONTEXTUAL_ID_PATTERN, ROCrate::ContactPoint.new(crate).id
    assert_match DATA_ID_PATTERN, ROCrate::File.new(crate, StringIO.new('')).id
    assert_match DIR_ID_PATTERN, ROCrate::Directory.new(crate).id
  end
end
