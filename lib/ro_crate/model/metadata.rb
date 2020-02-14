module ROCrate
  ##
  # A representation of the `ro-crate-metadata.jsonld` file.
  class Metadata < File
    CONTEXT = 'https://w3id.org/ro/crate/1.0/context'.freeze
    FILENAME = 'ro-crate-metadata.jsonld'.freeze
    properties(%w[name datePublished author license identifier distribution contactPoint publisher description url hasPart])

    def initialize(crate, properties = {})
      super(crate, nil, FILENAME, properties)
    end

    private

    def source
      graph = crate.entities.map(&:properties).reject(&:empty?)
      io = StringIO.new(JSON.pretty_generate('@context' => CONTEXT, '@graph' => graph))

      Entry.new(io)
    end

    def default_properties
      {
        '@id' => FILENAME,
        '@type' => 'CreativeWork',
        'about' => { '@id' => './' }
      }
    end
  end
end
