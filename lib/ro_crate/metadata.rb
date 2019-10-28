module ROCrate
  class Metadata < File
    CONTEXT = 'https://w3id.org/ro/crate/0.2/context'.freeze
    FILENAME = 'ro-crate-metadata.jsonld'.freeze
    properties(%w[name datePublished author license identifier distribution contactPoint publisher description url hasPart])

    def initialize(ro_crate)
      @ro_crate = ro_crate
      super(nil)
    end

    def content
      graph = @ro_crate.contents.map(&:properties).reject(&:empty?)

      compacted = { '@context' => CONTEXT, '@graph' => graph }

      JSON.pretty_generate(compacted)
    end

    private

    def default_properties
      {
          '@id' => FILENAME,
          '@type' => 'CreativeWork',
          'about' => { '@id' => './' }
      }
    end
  end
end
