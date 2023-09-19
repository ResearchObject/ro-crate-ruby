# encoding: utf-8
require 'test_helper'

class EntityTest < Test::Unit::TestCase
  CONTEXTUAL_ID_PATTERN = /\A\#\h{8}\-\h{4}\-\h{4}\-\h{4}\-\h{12}\Z/ # UUID preceeded by #
  DATA_ID_PATTERN = /\A\h{8}\-\h{4}\-\h{4}\-\h{4}\-\h{12}\Z/ # UUID
  DIR_ID_PATTERN = /\A\h{8}\-\h{4}\-\h{4}\-\h{4}\-\h{12}\/\Z/ # UUID with trailing /

  test 'automatic ids' do
    crate = ROCrate::Crate.new

    assert_equal './', crate.id
    assert_equal 'ro-crate-metadata.json', crate.metadata.id
    assert_match CONTEXTUAL_ID_PATTERN, ROCrate::Person.new(crate).id
    assert_match CONTEXTUAL_ID_PATTERN, ROCrate::Organization.new(crate).id
    assert_match CONTEXTUAL_ID_PATTERN, ROCrate::ContactPoint.new(crate).id
    assert_match DATA_ID_PATTERN, ROCrate::File.new(crate, StringIO.new('')).id
    assert_match DIR_ID_PATTERN, ROCrate::Directory.new(crate).id
  end

  test 'provided ids' do
    crate = ROCrate::Crate.new

    # Contextual entities need absolute URI or #bla ID
    assert_equal 'https://orcid.org/0000-0002-0048-3300',
                 ROCrate::Person.new(crate, 'https://orcid.org/0000-0002-0048-3300').id
    assert_equal '#finn', ROCrate::Person.new(crate, '#finn').id
    assert_equal '#finn', ROCrate::Person.new(crate, 'finn').id
    f = ROCrate::File.new(crate, StringIO.new(''), './hehe/').id
    refute f.end_with?('/')
    refute f.start_with?('.')
    refute f.start_with?('/')
    d = ROCrate::Directory.new(crate, fixture_file('directory'), 'test').id
    assert d.end_with?('/')
    refute d.start_with?('.')
    refute d.start_with?('/')
  end

  test 'fetch appropriate class for type' do
    assert_equal ROCrate::File, ROCrate::DataEntity.specialize({ '@type' => 'File' })
    assert_equal ROCrate::File, ROCrate::DataEntity.specialize({ '@type' => ['File', 'Image'] })
    assert_equal ROCrate::DataEntity, ROCrate::DataEntity.specialize({ '@type' => 'SoftwareSourceCode' })
    assert_equal ROCrate::DataEntity, ROCrate::DataEntity.specialize({ '@type' => 'anything that isnt a directory' })
    assert_equal ROCrate::Directory, ROCrate::DataEntity.specialize({ '@type' => 'Dataset' })
    assert_equal ROCrate::Directory, ROCrate::DataEntity.specialize({ '@type' => ['Dataset', 'Image'] })
    assert_equal ROCrate::DataEntity, ROCrate::DataEntity.specialize({ '@type' => 'Person' })
    assert_equal ROCrate::File, ROCrate::DataEntity.specialize({ '@type' => ['File', 'Image'], '@id' => 'http://www.external.com' })

    assert_equal ROCrate::Person, ROCrate::ContextualEntity.specialize({ '@type' => 'Person' })
    assert_equal ROCrate::Person, ROCrate::ContextualEntity.specialize({ '@type' => ['Person', 'Dave'] })
    assert_equal ROCrate::ContactPoint, ROCrate::ContextualEntity.specialize({ '@type' => 'ContactPoint' })
    assert_equal ROCrate::ContactPoint, ROCrate::ContextualEntity.specialize({ '@type' => ['ContactPoint', 'Something'] })
    assert_equal ROCrate::Organization, ROCrate::ContextualEntity.specialize({ '@type' => 'Organization' })
    assert_equal ROCrate::Organization, ROCrate::ContextualEntity.specialize({ '@type' => ['Organization', 'College'] })
    assert_equal ROCrate::ContextualEntity, ROCrate::ContextualEntity.specialize({ '@type' => 'Something else' })
    assert_equal ROCrate::ContextualEntity, ROCrate::ContextualEntity.specialize({ '@type' => 'File' })
  end

  test 'setting properties' do
    crate = ROCrate::Crate.new

    crate['test'] = 'hello'
    assert_equal 'hello', crate.properties['test']

    crate['test'] = ['hello']
    assert_equal ['hello'], crate.properties['test']

    person = ROCrate::Person.new(crate, 'fred', { name: 'Fred' })
    crate.author = person
    assert_equal({ '@id' => '#fred' }, crate['author'])
    assert_equal({ '@id' => '#fred' }, person.reference)
    assert_equal(person.canonical_id, crate.author.canonical_id)
  end

  test 'to_json' do
    crate = ROCrate::Crate.new

    crate['test'] = 'hello'
    crate['test2'] = ['hello']
    crate['test3'] = 123
    crate['test4'] = { a: 'bc' }

    json = crate.to_json
    parsed = JSON.parse(json)

    assert_equal 'hello', parsed['test']
    assert_equal ['hello'], parsed['test2']
    assert_equal 123, parsed['test3']
    assert_equal({ 'a' => 'bc' }, parsed['test4'])
  end

  test 'format various IDs' do
    assert_equal "#Hello%20World/Goodbye%20World", ROCrate::ContextualEntity.format_id('#Hello World/Goodbye World')
    assert_equal "#Hello%20World/Goodbye%20World", ROCrate::ContextualEntity.format_id('Hello World/Goodbye World')
    assert_equal "#%F0%9F%98%8A", ROCrate::ContextualEntity.format_id("😊")
    assert_equal "https://orcid.org/0000-0002-0048-3300", ROCrate::ContextualEntity.format_id("https://orcid.org/0000-0002-0048-3300")

    assert_equal "test123/hello.txt", ROCrate::File.format_id('./test123/hello.txt')
    assert_equal "test123/hello.txt", ROCrate::File.format_id('./test123/hello.txt/')
    assert_equal "http://www.data.com/my%20data.txt", ROCrate::File.format_id('http://www.data.com/my%20data.txt')
    assert_equal "http://www.data.com/my%20data.txt/", ROCrate::File.format_id('http://www.data.com/my%20data.txt/'), 'Should not modify absolute URI for DataEntity'

    assert_equal "my%20directory/", ROCrate::Directory.format_id('my directory')
    assert_equal "my%20directory/", ROCrate::Directory.format_id('my directory/')
    assert_equal 'http://www.data.com/my%20directory', ROCrate::Directory.format_id('http://www.data.com/my%20directory'), 'Should not modify absolute URI for DataEntity'
    assert_equal 'http://www.data.com/my%20directory/', ROCrate::Directory.format_id('http://www.data.com/my%20directory/'), 'Should not modify absolute URI for DataEntity'

    assert_equal "./", ROCrate::Crate.format_id('./')
    assert_equal "cool%20crate/", ROCrate::Crate.format_id('./cool crate')
    assert_equal "http://www.data.com/my%20crate/", ROCrate::Crate.format_id('http://www.data.com/my%20crate'), 'Crate ID should end with /'
    assert_equal "http://www.data.com/my%20crate/", ROCrate::Crate.format_id('http://www.data.com/my%20crate/')
  end

  test 'linked entities' do
    crate = ROCrate::Crate.new
    file = crate.add_file(StringIO.new(''), 'file')
    person = crate.add_person('#bob', { name: 'Bob' })
    file.author = person

    linked = file.linked_entities
    assert_include linked, person
    assert_equal 1, linked.length

    linked = crate.linked_entities
    assert_include linked, file
    assert_equal 1, linked.length

    linked = crate.linked_entities(deep: true)
    assert_include linked, file
    assert_include linked, person
    assert_equal 2, linked.length
  end

  test 'deleting entities removes linked entities' do
    crate = ROCrate::Crate.new
    file = crate.add_file(StringIO.new(''), 'file')
    person = crate.add_person('#bob', { name: 'Bob' })
    file.author = person

    assert file.delete
    assert_not_include crate.entities, file
    assert_not_include crate.entities, person
  end

  test 'deleting entities does not remove dangling entities if option set' do
    crate = ROCrate::Crate.new
    file = crate.add_file(StringIO.new(''), 'file')
    person = crate.add_person('#bob', { name: 'Bob' })
    file.author = person

    assert file.delete(remove_orphaned: false)
    assert_not_include crate.entities, file
    assert_include crate.entities, person
  end

  test 'creating files in various ways' do
    stub_request(:get, 'http://example.com/external_ref.txt').to_return(status: 200, body: 'file contents')

    crate = ROCrate::Crate.new

    f1 = nil
    Dir.chdir(fixture_dir) { f1 = ROCrate::File.new(crate, 'data.csv') }
    refute f1.source.remote?
    refute f1.source.directory?
    assert_equal 20, f1.source.read.length
    t = Tempfile.new('tf1')
    f1.source.write_to(t)
    t.rewind
    assert_equal 20, t.read.length

    f2 = ROCrate::File.new(crate, fixture_file('info.txt'), { author: crate.add_person('bob', name: 'Bob').reference })
    refute f2.source.remote?
    refute f2.source.directory?
    assert f2.source.read
    assert_equal 6, f2.source.read.length
    t = Tempfile.new('tf2')
    f2.source.write_to(t)
    t.rewind
    assert_equal 6, t.read.length

    f3 = ROCrate::File.new(crate, 'http://example.com/external_ref.txt')
    assert f3.source.remote?
    refute f3.source.directory?
    assert f3.source.read
    assert_equal 13, f3.source.read.length
    t = Tempfile.new('tf3')
    f3.source.write_to(t)
    t.rewind
    assert_equal 13, t.read.length

    f3 = ROCrate::File.new(crate, 'http://example.com/external_ref.txt')
    assert f3.source.remote?
    refute f3.source.directory?
    assert f3.source.read
    assert_equal 13, f3.source.read.length
    t = Tempfile.new('tf3')
    f3.source.write_to(t)
    t.rewind
    assert_equal 13, t.read.length
  end

  test 'assigning and checking type' do
    crate = ROCrate::Crate.new
    file = ROCrate::File.new(crate, 'data.csv')

    assert file.has_type?('File')

    file.type = ['File', 'Workflow']

    assert file.has_type?('Workflow')
    assert file.has_type?('File')
    refute file.has_type?('Banana')
  end

  test 'inspecting object truncates very long property list' do
    crate = ROCrate::Crate.new
    entity = ROCrate::ContextualEntity.new(crate, 'hello')

    assert entity.inspect.start_with?("<#ROCrate::ContextualEntity arcp://uuid,")

    entity['veryLong'] = ('123456789a' * 100)

    ins = entity.inspect
    assert ins.length < 1000
    assert ins.end_with?('...>')
  end
end
