module ROCrate
  ##
  # A representation of the `ro-crate-metadata.jsonld` file.
  class Metadata < File
    IDENTIFIER = 'ro-crate-metadata.jsonld'.freeze
    CONTEXT = 'https://w3id.org/ro/crate/1.0/context'.freeze
    properties(%w[name datePublished author license identifier distribution contactPoint publisher description url hasPart])

    def initialize(crate, properties = {})
      super(crate, nil, IDENTIFIER, properties)
    end

    private

    def source
      graph = crate.entities.map(&:properties).reject(&:empty?)
      io = StringIO.new(JSON.pretty_generate('@context' => CONTEXT, '@graph' => graph))

      Entry.new(io)
    end

    def default_properties
      {
        '@id' => IDENTIFIER,
        '@type' => 'CreativeWork',
        'about' => { '@id' => ROCrate::Crate::IDENTIFIER }
      }
    end
  end
end
