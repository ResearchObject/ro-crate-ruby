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

    def add_file(path_or_io, properties = {})
      path = properties.delete(:path)
      path_or_io = ::File.open(path_or_io) if path_or_io.is_a?(String)
      path ||= path_or_io.respond_to?(:path) ? ::File.basename(path_or_io.path) : nil
      ROCrate::File.new(self, path_or_io, path, properties).tap { |e| data_entities << e }
    end

    def add_directory(path_or_file, properties = {})
      raise 'Not a directory' if path_or_file.is_a?(::File) && !::File.directory?(path_or_file)
      path_or_file ||= path_or_file.respond_to?(:path) ? path_or_file.path : path_or_file
      ROCrate::Directory.new(self, path_or_file, properties).tap { |e| data_entities << e }
    end

    def add_person(id, properties = {})
      ROCrate::Person.new(self, id, properties).tap { |e| contextual_entities << e }
    end

    def add_contact_point(id, properties = {})
      ROCrate::ContactPoint.new(self, id, properties).tap { |e| contextual_entities << e }
    end

    def add_organization(id, properties = {})
      ROCrate::Organization.new(self, id, properties).tap { |e| contextual_entities << e }
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
