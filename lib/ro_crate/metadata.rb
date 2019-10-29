module ROCrate
  class Metadata < Entity
    CONTEXT = 'https://w3id.org/ro/crate/0.2/context'.freeze
    FILENAME = 'ro-crate-metadata.jsonld'.freeze
    properties(%w[name datePublished author license identifier distribution contactPoint publisher description url hasPart])

    def filepath
      id.sub(/\A.\//, '')
    end

    def write(io)
      io.write(content)
    end

    private

    def content
      graph = @crate.contents.map(&:properties).reject(&:empty?)

      compacted = { '@context' => CONTEXT, '@graph' => graph }

      JSON.pretty_generate(compacted)
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
