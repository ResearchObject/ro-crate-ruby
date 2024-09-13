# encoding: utf-8
require 'test_helper'

class PreviewTest < Test::Unit::TestCase
  test 'simple attributes' do
    crate = ROCrate::Crate.new
    crate.author = 'Finn'

    html = crate.preview.source.read
    assert_includes html, '<dd>Finn</dd>'
  end

  test 'list attributes' do
    crate = ROCrate::Crate.new
    crate.author = ['Finn', 'Josiah']

    html = crate.preview.source.read
    assert_includes html, '<dd><ul><li>Finn</li><li>Josiah</li></ul></dd>'
  end

  test 'entity attributes' do
    crate = ROCrate::Crate.new
    crate.author = crate.add_person('https://orcid.org/0000-0002-0048-3300', name: 'Finn')

    html = crate.preview.source.read
    assert_includes html, '<dd><a href="https://orcid.org/0000-0002-0048-3300" target="_blank">Finn</a></dd>'
  end

  test 'complex attributes' do
    crate = ROCrate::Crate.new
    crate.author = [crate.add_person('https://orcid.org/0000-0002-0048-3300', name: 'Finn'), 'Josiah']

    html = crate.preview.source.read

    assert_includes html, '<dd><ul><li><a href="https://orcid.org/0000-0002-0048-3300" target="_blank">Finn</a></li><li>Josiah</li></ul></dd>'
  end

  test 'files' do
    crate = ROCrate::Crate.new
    crate.add_file(fixture_file('info.txt'))
    crate.add_external_file('https://raw.githubusercontent.com/ResearchObject/ro-crate-ruby/master/README.md')

    html = crate.preview.source.read

    assert_includes html, '<strong>info.txt</strong>'
    assert_includes html, '<strong><a href="https://raw.githubusercontent.com/ResearchObject/ro-crate-ruby/master/README.md" target="_blank">https://raw.githubusercontent.com/ResearchObject/ro-crate-ruby/master/README.md</a></strong>'
  end
end
