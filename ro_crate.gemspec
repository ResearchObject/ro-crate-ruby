Gem::Specification.new do |s|
  s.name        = 'ro-crate'
  s.version     = '0.5.1'
  s.summary     = 'Create, manipulate, read RO-Crates.'
  s.authors     = ['Finn Bacall']
  s.email       = 'finn.bacall@manchester.ac.uk'
  s.files       = `git ls-files`.split("\n")
  s.homepage    = 'https://github.com/ResearchObject/ro-crate-ruby'
  s.require_paths = ['lib']
  s.licenses    = ['MIT']
  s.add_runtime_dependency 'addressable', '>= 2.7', '< 2.9'
  # s.add_runtime_dependency 'rubyzip', '~> 2.0.0'
  s.add_development_dependency 'rake', '~> 13.0.0'
  s.add_development_dependency 'test-unit', '~> 3.5.3'
  s.add_development_dependency 'simplecov', '~> 0.21.2'
  s.add_development_dependency 'yard', '~> 0.9.25'
  s.add_development_dependency 'webmock', '~> 3.8.3'
  s.add_development_dependency 'rexml', '~> 3.2.5'
end
