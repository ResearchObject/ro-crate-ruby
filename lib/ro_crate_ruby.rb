require_relative './ro_crate/crate'
require_relative './ro_crate/entry'
require_relative './ro_crate/metadata'

ctx = JSON::LD::Context.parse(File.join(File.dirname(__FILE__), 'ro-crate-context-0-2.json'))
JSON::LD::Context.add_preloaded('https://w3id.org/ro/crate/0.2/context', ctx)
