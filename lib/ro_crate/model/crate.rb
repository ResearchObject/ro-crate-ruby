module ROCrate
  ##
  # A Ruby abstraction of an RO-Crate.
  class Crate < Directory
    IDENTIFIER = './'.freeze
    attr_reader :data_entities
    attr_reader :contextual_entities
    properties(%w[name datePublished author license identifier distribution contactPoint publisher description url hasPart])

    def self.format_id(id)
      return id if id == IDENTIFIER
      super
    end

    ##
    # Initialize an empty RO-Crate.
    def initialize(id = IDENTIFIER, properties = {})
      @data_entities = []
      @contextual_entities = []
      super(self, nil, id, properties)
    end

    ##
    # Create a new file and add it to the crate.
    #
    # @param source [String, Pathname, ::File, #read, nil] The source on the disk where this file will be read.
    # @param crate_path [String] The relative path within the RO-Crate where this file will be written.
    # @param entity_class [Class] The class to use to instantiate the Entity,
    #   useful if you have created a subclass of ROCrate::File that you want to use. (defaults to ROCrate::File).
    # @param properties [Hash{String => Object}] A hash of JSON-LD properties to associate with this file.
    #
    # @return [Entity]
    def add_file(source, crate_path = nil, entity_class: ROCrate::File, **properties)
      entity_class.new(self, source, crate_path, properties).tap { |e| add_data_entity(e) }
    end

    ##
    # Create a new file that references a remote URI and add it to the crate.
    #
    # @param source [String, URI] The URI to add.
    # @param entity_class [Class] The class to use to instantiate the Entity,
    #   useful if you have created a subclass of ROCrate::File that you want to use. (defaults to ROCrate::File).
    # @param properties [Hash{String => Object}] A hash of JSON-LD properties to associate with this file.
    #
    # @return [Entity]
    def add_external_file(source, entity_class: ROCrate::File, **properties)
      entity_class.new(self, source, nil, properties).tap { |e| add_data_entity(e) }
    end

    ##
    # Create a new directory and add it to the crate.
    #
    # @param source_directory [String, Pathname, ::File, #read, nil] The source directory that will be included in the crate.
    # @param crate_path [String] The relative path within the RO-Crate where this directory will be written.
    # @param entity_class [Class] The class to use to instantiate the Entity,
    #   useful if you have created a subclass of ROCrate::Directory that you want to use. (defaults to ROCrate::Directory).
    # @param properties [Hash{String => Object}] A hash of JSON-LD properties to associate with this directory.
    #
    # @return [Entity]
    def add_directory(source_directory, crate_path = nil, entity_class: ROCrate::Directory, **properties)
      entity_class.new(self, source_directory, crate_path, properties).tap { |e| add_data_entity(e) }
    end

    ##
    # Recursively add the contents of the given source directory at the root of the crate.
    # Useful for quickly RO-Crate-ifying a directory.
    # Creates data entities for each file/directory discovered (excluding the top level directory itself) if `create_entities` is true.
    #
    # @param source_directory [String, Pathname, ::File,] The source directory that will be included in the crate.
    # @param create_entities [Boolean] Whether to create data entities for the added content, or just include them anonymously.
    #
    # @return [Array<DataEntity>] Any entities that were created from the directory contents. Will be empty if `create_entities` was false.
    def add_all(source_directory, create_entities = true)
      added = []

      Dir.chdir(source_directory) { Dir.glob('**/*') }.each do |rel_path|
        source_path = Pathname.new(::File.join(source_directory, rel_path)).expand_path
        if create_entities
          if source_path.directory?
            added << add_directory(source_path, rel_path)
          else
            added << add_file(source_path, rel_path)
          end
        else
          populate_entries(Pathname.new(::File.expand_path(source_directory)))
        end
      end

      added
    end

    ##
    # Create a new ROCrate::Person and add it to the crate
    #
    # @param id [String, nil] An ID to identify this person, or blank to auto-generate an appropriate one,
    #   (or determine via the properties param)
    # @param properties [Hash{String => Object}] A hash of JSON-LD properties to associate with this person.
    # @return [Person]
    def add_person(id, properties = {})
      add_contextual_entity(ROCrate::Person.new(self, id, properties))
    end

    ##
    # Create a new ROCrate::ContactPoint and add it to the crate
    #
    # @param id [String, nil] An ID to identify this contact point, or blank to auto-generate an appropriate one,
    #   (or determine via the properties param)
    # @param properties [Hash{String => Object}] A hash of JSON-LD properties to associate with this contact point.
    # @return [ContactPoint]
    def add_contact_point(id, properties = {})
      add_contextual_entity(ROCrate::ContactPoint.new(self, id, properties))
    end

    ##
    # Create a new ROCrate::Organization and add it to the crate
    #
    # @param id [String, nil] An ID to identify this organization, or blank to auto-generate an appropriate one,
    #   (or determine via the properties param)
    # @param properties [Hash{String => Object}] A hash of JSON-LD properties to associate with this organization.
    # @return [Organization]
    def add_organization(id, properties = {})
      add_contextual_entity(ROCrate::Organization.new(self, id, properties))
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
    # The RO-Crate metadata file
    #
    # @return [Metadata]
    def metadata
      @metadata ||= ROCrate::Metadata.new(self)
    end

    ##
    # The RO-Crate preview file
    #
    # @return [Preview]
    def preview
      @preview ||= ROCrate::Preview.new(self)
    end

    ##
    # All the entities within the crate. Includes contextual entities, data entities, the crate itself and its metadata file.
    #
    # @return [Array<Entity>]
    def entities
      default_entities | data_entities | contextual_entities
    end

    ##
    # Entities for the metadata file and crate itself, which should be present in all RO-Crates.
    #
    # @return [Array<Entity>]
    def default_entities
      [metadata, preview, self]
    end

    def properties
      super.merge('hasPart' => data_entities.map(&:reference))
    end

    def uuid
      @uuid ||= SecureRandom.uuid
    end

    ##
    # The "canonical", global ID of the crate. If the crate was not given an absolute URI as its ID,
    # it will use an "Archive and Package" (ARCP) URI with the UUID of the crate, for example:
    #   arcp://uuid,b3d6fa2b-4e49-43ba-bd89-464e948b7f0c/
    #
    # @return [Addressable::URI]
    def canonical_id
      Addressable::URI.parse("arcp://uuid,#{uuid}").join(id)
    end

    ##
    # Return an absolute URI for the given string ID, relative to the crate's canonical ID.
    #
    # @param id [String] The ID to "join" onto the crate's base URI.
    #
    # @return [Addressable::URI]
    def resolve_id(id)
      canonical_id.join(id)
    end

    ##
    # Copy the entity, but as if it was in this crate.
    # (Or just return the entity if it was already included)
    def claim(entity)
      return entity if entity.crate == self
      entity.class.new(crate, entity.id, entity.raw_properties)
    end

    alias_method :own_entries, :entries
    ##
    # A map of all the files/directories contained in the RO-Crate, where the key is the destination path within the crate
    # and the value is an Entry where the source data can be read.
    #
    # @return [Hash{String => Entry}>]
    def entries
      entries = {}

      (default_entities | data_entities).each do |entity|
        (entity == self ? own_entries : entity.entries).each do |path, io|
          entries[path] = io
        end
      end

      entries
    end

    def get_binding
      binding
    end
  end
end
