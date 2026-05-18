Gem::Specification.new do |s|
  s.name        = 'ro-crate'
  s.version     = '0.6.0'
  s.summary     = 'Create, manipulate, read RO-Crates.'
  s.authors     = ['Finn Bacall']
  s.email       = 'finn.bacall@manchester.ac.uk'
  s.files       = `git ls-files`.split("\n")
  s.homepage    = 'https://github.com/ResearchObject/ro-crate-ruby'
  s.require_paths = ['lib']
  s.licenses    = ['MIT']
  s.add_runtime_dependency 'addressable', '>= 2.7', '< 3'
  s.add_runtime_dependency 'rubyzip', '>= 2.3', '< 4'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'test-unit'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'rexml'
end
