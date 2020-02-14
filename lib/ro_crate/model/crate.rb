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

    ##
    # Initialize an empty RO Crate.
    def initialize
      @data_entities = []
      @contextual_entities = []
      super(self, nil, './')
    end

    def add_file(source, crate_path = nil, entity_class: ROCrate::File, **properties)
      entity_class.new(self, source, crate_path, properties).tap { |e| add_data_entity(e) }
    end

    def add_directory(source, crate_path = nil, entity_class: ROCrate::Directory, **properties)
      entity_class.new(self, source, crate_path, properties).tap { |e| add_data_entity(e) }
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

    ##
    # Add a contextual entity to the crate
    #
    # @param entity [Entity] the entity to add to the crate.
    # @return [Entity] the entity itself, or a clone of the entity "owned" by this crate.
    def add_contextual_entity(entity)
      entity = claim(entity)
      contextual_entities.delete(entity) # Remove (then re-add) the entity if it exists
      contextual_entities.push(entity)
      entity
    end

    ##
    # Add a data entity to the crate
    #
    # @param entity [Entity] the entity to add to the crate.
    # @return [Entity] the entity itself, or a clone of the entity "owned" by this crate.
    def add_data_entity(entity)
      entity = claim(entity)
      data_entities.delete(entity) # Remove (then re-add) the entity if it exists
      data_entities.push(entity)
      entity
    end

    ##
    # The RO crate metadata file
    #
    # @return [Metadata]
    def metadata
      @metadata ||= ROCrate::Metadata.new(self)
    end

    ##
    # All the entities within the crate. Includes contextual entities, data entities, the crate itself and its metadata file.
    #
    # @return [Array<Entity>]
    def entities
      default_entities | data_entities | contextual_entities
    end

    ##
    # Entities for the metadata file and crate itself, which should be present in all RO crates.
    #
    # @return [Array<Entity>]
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

    ##
    # A map of all the files/directories contained in the RO crate, where the key is the destination path within the crate
    # and the value is an Entry where the source data can be read.
    #
    # @return [Hash{String => Entry}>]
    def entries
      entries = {}

      [metadata, *data_entities].each do |entity|
        entity.entries.each do |path, io|
          entries[path] = io
        end
      end

      entries
    end
  end
end
