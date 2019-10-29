Gem::Specification.new do |s|
  s.name        = 'ro-crate-ruby'
  s.version     = '0.0.1'
  s.date        = '2019-10-23'
  s.summary     = 'Create RO crates'
  s.authors     = ['Finn Bacall']
  s.email       = 'finn.bacall@manchester.ac.uk'
  s.files       = `git ls-files`.split("\n")
  s.homepage    = 'https://github.com/fbacall/ro-crate-ruby'
  s.require_paths = ['lib']
  # s.add_runtime_dependency 'json-ld'
  s.add_runtime_dependency 'rubyzip'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'test-unit'
  s.add_development_dependency 'simplecov'
end
