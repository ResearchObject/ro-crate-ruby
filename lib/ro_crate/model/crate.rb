module ROCrate
  ##
  # A Ruby abstraction of an RO Crate.
  class Crate < Directory
    attr_reader :data_entities
    attr_reader :contextual_entities
    properties(%w[name datePublished author license identifier distribution contactPoint publisher description url hasPart])

    def self.format_id(id)
      './'
    end

    def initialize
      @data_entities = []
      @contextual_entities = []
      super(self, nil, './')
    end

    def add_file(path_or_io, crate_path = nil, entity_class: ROCrate::File, **properties)
      path_or_io = Pathname.new(path_or_io) if path_or_io.is_a?(String) || path_or_io.is_a?(::File)
      crate_path = path_or_io.basename.to_s if crate_path.nil? && path_or_io.respond_to?(:basename)
      entity_class.new(self, path_or_io, crate_path, properties).tap { |e| add_data_entity(e) }
    end

    def add_directory(path_or_file, crate_path = nil, entity_class: ROCrate::Directory, **properties)
      path_or_file = Pathname.new(path_or_file) if path_or_file.is_a?(String) || path_or_file.is_a?(::File)
      crate_path = path_or_file.basename.to_s if crate_path.nil? && path_or_file.respond_to?(:basename)
      entity_class.new(self, path_or_file, crate_path, properties).tap { |e| add_data_entity(e) }
    end

    def add_person(id, properties = {})
      create_contextual_entity(id, properties, entity_class: ROCrate::Person)
    end

    def add_contact_point(id, properties = {})
      create_contextual_entity(id, properties, entity_class: ROCrate::ContactPoint)
    end

    def add_organization(id, properties = {})
      create_contextual_entity(id, properties, entity_class: ROCrate::Organization)
    end

    def create_contextual_entity(id, properties, entity_class: nil)
      entity = (entity_class || ROCrate::Entity).new(self, id, properties)
      entity = entity.specialize if entity_class.nil?
      add_contextual_entity(entity)
      entity
    end

    def add_contextual_entity(entity)
      entity = claim(entity)
      contextual_entities.delete(entity) # Remove (then re-add) the entity if it exists
      contextual_entities.push(entity)
      entity
    end

    def add_data_entity(entity)
      entity = claim(entity)
      data_entities.delete(entity) # Remove (then re-add) the entity if it exists
      data_entities.push(entity)
      entity
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

    ##
    # Copy the entity, but as if it was in this crate.
    # (Or just return the entity if it was already included)
    def claim(entity)
      return entity if entity.crate == self
      entity.class.new(crate, entity.id, entity.raw_properties)
    end

    def entries
      entries = {
          metadata.filepath => metadata
      }

      data_entities.each do |entity|
        if entity.is_a?(Directory)
          entity.entries.each do |path, io|
            entries[path] = io
          end
        else
          entries[entity.filepath] = entity
        end
      end

      entries
    end
  end
end
