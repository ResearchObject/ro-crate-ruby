module ROCrate
  ##
  # A Ruby abstraction of an RO Crate.
  class Crate < Directory
    attr_reader :data_entities
    attr_reader :contextual_entities
    properties(%w[name datePublished author license identifier distribution contactPoint publisher description url hasPart])

    def initialize
      @data_entities = []
      @contextual_entities = []
      super(self, './')
    end

    def add_file(file, path: nil)
      path ||= file.respond_to?(:path) ? ::File.basename(file.path) : nil
      ROCrate::File.new(self, file, path).tap { |f| data_entities << f }
    end

    def metadata
      @metadata ||= ROCrate::Metadata.new(self)
    end

    def entities
      default_entities | data_entities | contextual_entities
    end

    def default_entities
      [metadata, self]
    end

    def properties
      super.merge('hasPart' => data_entities.map(&:reference))
    end

    def uuid
      @uuid ||= SecureRandom.uuid
    end

    def resolve_id(*parts)
      URI.join("arcp://uuid,#{uuid}", *parts)
    end
  end
end
