require 'json'
require 'zip'
require 'zip/filesystem'
require_relative './ro_crate/entity'
require_relative './ro_crate/file'
require_relative './ro_crate/directory'
require_relative './ro_crate/metadata'
require_relative './ro_crate/crate'
require_relative './ro_crate/person'
require_relative './ro_crate/contact_point'
require_relative './ro_crate/organization'
require_relative './ro_crate/reader'
require_relative './ro_crate/writer'
#
# ctx = JSON::LD::Context.parse(::File.join(::File.dirname(__FILE__), '..', 'vendor', 'ro-crate-context-0-2.json'))
# JSON::LD::Context.add_preloaded('https://w3id.org/ro/crate/0.2/context', ctx)
