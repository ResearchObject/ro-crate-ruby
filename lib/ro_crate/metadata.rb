module ROCrate
  class Metadata < Entity
    include Writeable

    CONTEXT = 'https://w3id.org/ro/crate/0.2/context'.freeze
    FILENAME = 'ro-crate-metadata.jsonld'.freeze
    properties(%w[name datePublished author license identifier distribution contactPoint publisher description url hasPart])

    private

    def content
      graph = @crate.entities.map(&:properties).reject(&:empty?)

      StringIO.new(JSON.pretty_generate('@context' => CONTEXT, '@graph' => graph))
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
