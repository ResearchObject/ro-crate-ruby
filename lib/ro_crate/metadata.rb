module ROCrate
  class Metadata < File
    PROPERTIES = %i[name datePublished author license identifier distribution contactPoint publisher description url hasPart]

    def initialize(ro_crate)
      @ro_crate = ro_crate
      super(nil)
    end

    def content
      graph = @ro_crate.contents.map(&:properties).reject(&:empty?)

      compacted = { '@context' => context, '@graph' => graph }

      JSON.pretty_generate(compacted)
    end

    private

    def context
      'https://w3id.org/ro/crate/0.2/context'
    end

    def default_properties
      {
          '@id' => 'ro-crate-metadata.json',
          '@type' => 'CreativeWork',
          'about' => { '@id' => './' }
      }
    end
  end
end
