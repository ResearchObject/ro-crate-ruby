module ROCrate
  ##
  # A representation of the `ro-crate-metadata.jsonld` file.
  class Metadata < File
    IDENTIFIER = 'ro-crate-metadata.json'.freeze
    IDENTIFIER_1_0 = 'ro-crate-metadata.jsonld'.freeze # 1.0 spec identifier
    RO_CRATE_BASE = 'https://w3id.org/ro/crate/'

    SUPPORTED_VERSIONS = %w[1.0 1.0-DRAFT 1.1 1.1-DRAFT 1.2 1.2-DRAFT].freeze
    DEFAULT_VERSION = '1.2'.freeze

    CONTEXT = "#{RO_CRATE_BASE}#{DEFAULT_VERSION}/context".freeze
    SPEC = "#{RO_CRATE_BASE}#{DEFAULT_VERSION}".freeze

    attr_reader :version

    def initialize(crate, properties = {}, version: DEFAULT_VERSION)
      unless SUPPORTED_VERSIONS.include?(version)
        raise ArgumentError, "Unsupported RO-Crate version: #{version.inspect}. Supported: #{SUPPORTED_VERSIONS.join(', ')}"
      end
      @version = version
      super(crate, nil, IDENTIFIER, properties)
    end

    def context_url
      "#{RO_CRATE_BASE}#{@version}/context"
    end

    def spec_url
      "#{RO_CRATE_BASE}#{@version}"
    end

    ##
    # Generate the crate's `ro-crate-metadata.jsonld`.
    # @return [String] The rendered JSON-LD as a "prettified" string.
    def generate
      graph = crate.entities.map(&:properties).reject(&:empty?)
      JSON.pretty_generate('@context' => context, '@graph' => graph)
    end

    def context
      @context || context_url
    end

    def context= c
      @context = c
    end

    private

    def source
      Entry.new(StringIO.new(generate))
    end

    def default_properties
      {
        '@id' => IDENTIFIER,
        '@type' => 'CreativeWork',
        'about' => { '@id' => crate.id },
        'conformsTo' => { '@id' => spec_url }
      }
    end
  end
end
