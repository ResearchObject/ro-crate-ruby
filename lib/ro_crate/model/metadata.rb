module ROCrate
  ##
  # A representation of the `ro-crate-metadata.jsonld` file.
  class Metadata < File
    IDENTIFIER = 'ro-crate-metadata.json'.freeze
    IDENTIFIER_1_0 = 'ro-crate-metadata.jsonld'.freeze # 1.0 spec identifier
    CONTEXT = 'https://w3id.org/ro/crate/1.1/context'.freeze
    SPEC = 'https://w3id.org/ro/crate/1.1'.freeze

    def initialize(crate, properties = {})
      super(crate, nil, IDENTIFIER, properties)
    end

    ##
    # Generate the crate's `ro-crate-metadata.jsonld`.
    # @return [String] The rendered JSON-LD as a "prettified" string.
    def generate
      graph = crate.entities.map(&:properties).reject(&:empty?)
      JSON.pretty_generate('@context' => CONTEXT, '@graph' => graph)
    end

    private

    def source
      Entry.new(StringIO.new(generate))
    end

    def default_properties
      {
        '@id' => IDENTIFIER,
        '@type' => 'CreativeWork',
        'about' => { '@id' => ROCrate::Crate::IDENTIFIER },
        'conformsTo' => { '@id' => SPEC }
      }
    end
  end
end
