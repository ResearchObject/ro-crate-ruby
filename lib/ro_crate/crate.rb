module ROCrate
  class Crate < Directory
    properties(%w[name datePublished author license identifier distribution contactPoint publisher description url hasPart])
    attr_reader :parts
    attr_reader :contextual_entities

    def initialize
      @contextual_entities = []
      @parts = []
      super(self, './')
    end

    def add_file(file, path: nil)
      path ||= file.respond_to?(:path) ? ::File.basename(file.path) : nil
      ROCrate::File.new(self, file, path).tap { |f| @parts << f }
    end

    def metadata
      @metadata ||= ROCrate::Metadata.new(self)
    end

    def metadata=(metadata)
      @metadata = metadata
    end

    def entities
      default_entities | @contextual_entities
    end

    def default_entities
      [metadata, self] + @parts
    end

    def properties
      super.merge('hasPart' => @parts.map(&:reference))
    end

    def uuid
      @uuid ||= SecureRandom.uuid
    end

    def absolute(*parts)
      URI.join("arcp://uuid,#{uuid}", *parts)
    end
  end
end
