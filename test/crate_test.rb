require 'test_helper'

class CrateTest < Test::Unit::TestCase
  test 'dereferencing' do
    crate = ROCrate::Crate.new
    info = crate.add_file(fixture_file('info.txt'),'the_info.txt')
    more_info = crate.add_file(fixture_file('info.txt'), 'directory/more_info.txt')

    assert_equal crate, crate.dereference(ROCrate::Crate::IDENTIFIER)
    assert_equal crate.metadata, crate.dereference(ROCrate::Metadata::IDENTIFIER)
    assert_equal info, crate.dereference('./the_info.txt')
    assert_equal more_info, crate.dereference('./directory/more_info.txt')
    assert_nil crate.dereference('./directory/blabla.zip')
  end

  test 'dereferencing equivalent ids' do
    crate = ROCrate::Reader.read(fixture_file('workflow-0.2.0').path)
    workflow = crate.data_entities.first

    assert_equal crate, crate.dereference('./')
    assert_equal crate, crate.dereference('.')
    assert_equal crate.metadata, crate.dereference('ro-crate-metadata.jsonld')
    assert_equal crate.metadata, crate.dereference('./ro-crate-metadata.jsonld')
    assert_equal workflow, crate.dereference('./workflow/workflow.knime')
    assert_equal workflow, crate.dereference('workflow/workflow.knime')
  end

  test 'entity equality' do
    crate = ROCrate::Crate.new
    entity = ROCrate::Entity.new(crate, 'id123')
    entity.properties['name'] = 'Jess'
    entity2 = ROCrate::Entity.new(crate, './id123')
    entity2.properties[ 'name'] = 'Fred'
    entity3 = ROCrate::Entity.new(crate, 'id123')
    entity3.properties['name'] = 'Hans'
    entity4 = ROCrate::Entity.new(crate, 'id456')
    entity4.properties['name'] = 'Hans'

    assert_equal entity.hash, entity2.hash
    assert_not_equal entity3.hash, entity4.hash
    assert_equal entity.canonical_id, entity2.canonical_id
    assert_not_equal entity.canonical_id, entity4.canonical_id
    assert_equal 1, ([entity] | [entity2]).length
    assert_equal 2, ([entity, entity4] | [entity2, entity4]).length
  end

  test 'dereferencing properties' do
    crate = ROCrate::Reader.read(fixture_file('workflow-0.2.0').path)
    workflow = crate.data_entities.first
    person = crate.dereference('#thomas')
    assert_equal 'RetroPath 2.0 Knime workflow', workflow.name
    assert_equal 'Thomas Duigou', person.name

    assert crate.properties.is_a?(ROCrate::JSONLDHash)
    assert_equal workflow.id, crate.properties['hasPart'].first['@id']
    assert crate.properties['hasPart'].first.is_a?(ROCrate::JSONLDHash)
    assert_equal workflow, crate.properties['hasPart'].first.dereference
    assert_equal person, crate.properties['hasPart'].first.dereference.properties['creator'].dereference
  end

  test 'auto dereferencing properties' do
    crate = ROCrate::Reader.read(fixture_file('workflow-0.2.0').path)
    person = crate.dereference('#thomas')
    person2 = crate.dereference('#stefan')

    crate.author = { '@id' => '#thomas' }
    assert_equal person, crate.author

    crate.author = [{ '@id' => '#thomas' }, { '@id' => '#stefan' }]
    assert_equal 2, crate.author.length
    assert_includes crate.author, person
    assert_includes crate.author, person2

    crate.author = [{ '@id' => '#thomas' },
                    { '@id' => '#stefan' },
                    'Bob',
                    { '@id' => 'http://external-person.example.com/about' }]
    assert_equal 4, crate.author.length
    assert_includes crate.author, person
    assert_includes crate.author, person2
    assert_includes crate.author, 'Bob'
  end

  test 'auto referencing properties' do
    crate = ROCrate::Reader.read(fixture_file('workflow-0.2.0').path)
    person = crate.dereference('#thomas')
    person2 = crate.dereference('#stefan')
    crate.author = nil
    assert_nil crate.author

    crate.author = person
    assert_equal person, crate.author
    assert_equal person.reference, crate.raw_properties['author']

    crate.author = [person, 'fred', person2]
    assert_equal [person, 'fred', person2], crate.author
    assert_equal [person.reference, 'fred', person2.reference], crate.raw_properties['author']

    crate.author = 'fred'
    assert_equal 'fred', crate.author
    assert_equal 'fred', crate.raw_properties['author']

    # Moving an entity to a new crate should add it to that crate's contextual_entities.
    new_crate = ROCrate::Crate.new
    assert_empty new_crate.contextual_entities
    new_crate.author = person
    assert_equal 1, new_crate.contextual_entities.length
    new_person = new_crate.contextual_entities.first
    assert_equal person.name, new_person.name
    assert_equal person['email'], new_person['email']
    assert_not_equal person.canonical_id, new_person.canonical_id
    assert_equal new_person, new_crate.author
    assert_equal new_person.reference, new_crate.raw_properties['author']
  end

  test 'encoding and decoding ids' do
    crate = ROCrate::Crate.new
    info = crate.add_file(fixture_file('info.txt'), 'awkward path with spaces [] etc.txt')
    assert_equal 'awkward%20path%20with%20spaces%20%5B%5D%20etc.txt', info.id
    assert_equal 'awkward path with spaces [] etc.txt', info.filepath
  end

  test 'adding contextual entities' do
    crate = ROCrate::Crate.new

    fish = crate.add_person('#fish', { name: 'Wanda' })
    assert_equal 'Wanda', fish.name
    assert_equal '#fish', fish.id
    assert_equal ROCrate::Person, fish.class

    cool = crate.add_organization('#cool', { name: 'Cool kids' })
    assert_equal 'Cool kids', cool.name
    assert_equal '#cool', cool.id
    assert_equal ROCrate::Organization, cool.class

    ab = crate.add_contact_point('#maintainer', { name: 'A B' })
    assert_equal 'A B', ab.name
    assert_equal '#maintainer', ab.id
    assert_equal ROCrate::ContactPoint, ab.class
  end

  test 'swapping entities between crates' do
    crate1 = ROCrate::Crate.new
    crate2 = ROCrate::Crate.new

    john = crate1.add_person('john', { name: 'John', cats: 1 })
    john_copy = crate2.add_contextual_entity(john)

    assert_equal 1, crate1.contextual_entities.length
    assert_equal 1, crate2.contextual_entities.length
    assert_equal crate1.contextual_entities.first.properties['name'], crate2.contextual_entities.first.properties['name']
    assert_equal crate1.contextual_entities.first.properties['cats'], crate2.contextual_entities.first.properties['cats']
    assert_not_equal john.canonical_id, john_copy.canonical_id

    # Modify the copy, which should not change the original
    john_copy.properties['cats'] = 2
    assert_equal crate1.contextual_entities.first.properties['name'], crate2.contextual_entities.first.properties['name']
    assert_not_equal crate1.contextual_entities.first.properties['cats'], crate2.contextual_entities.first.properties['cats']

    # Add the "copy" back into the first crate, which should replace the original, since they have the same ID.
    crate1.add_contextual_entity(john_copy)
    assert_equal 1, crate1.contextual_entities.length
    assert_equal 2, crate1.contextual_entities.first.properties['cats']
  end
end
