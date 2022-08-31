require 'set'

module ROCrate
  ##
  # A Ruby abstraction of an RO-Crate.
  class Crate < Directory
    IDENTIFIER = './'.freeze
    attr_reader :data_entities
    attr_reader :contextual_entities
    properties(%w[name datePublished author license identifier distribution contactPoint publisher description url hasPart])

    def self.format_id(id)
      i = super(id)
      i.end_with?('/') ? i : "#{i}/"
    end

    def self.format_local_id(id)
      return id if id == IDENTIFIER
      super
    end

    ##
    # Initialize an empty RO-Crate.
    def initialize(id = IDENTIFIER, properties = {})
      @data_entities = Set.new
      @contextual_entities = Set.new
      super(self, nil, id, properties)
    end

    ##
    # Lookup an Entity using the given ID (in this Entity's crate).
    #
    # @param id [String] The ID to query.
    # @return [Entity, nil]
    def dereference(id)
      entities.detect { |e| e.canonical_id == crate.resolve_id(id) } if id
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
    # @param include_hidden [Boolean] Whether to include hidden files, i.e. those prefixed by a `.` (period).
    #
    # @return [Array<DataEntity>] Any entities that were created from the directory contents. Will be empty if `create_entities` was false.
    def add_all(source_directory, create_entities = true, include_hidden: false)
      added = []

      if create_entities
        list_all_files(source_directory, include_hidden: include_hidden).each do |rel_path|
          source_path = Pathname.new(::File.join(source_directory, rel_path)).expand_path
          if source_path.directory?
            added << add_directory(source_path, rel_path)
          else
            added << add_file(source_path, rel_path)
          end
        end
      else
        populate_entries(Pathname.new(::File.expand_path(source_directory)), include_hidden: include_hidden)
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
      contextual_entities.delete?(entity) # Remove (then re-add) the entity if it exists
      contextual_entities.add(entity)
      entity
    end

    ##
    # Add a data entity to the crate
    #
    # @param entity [Entity] the entity to add to the crate.
    # @return [Entity] the entity itself, or a clone of the entity "owned" by this crate.
    def add_data_entity(entity)
      entity = claim(entity)
      data_entities.delete?(entity) # Remove (then re-add) the entity if it exists
      data_entities.add(entity)
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
    # Set the RO-Crate preview file
    # @param preview [Preview] the preview to set.
    #
    # @return [Preview]
    def preview=(preview)
      @preview = claim(preview)
    end

    ##
    # All the entities within the crate. Includes contextual entities, data entities, the crate itself and its metadata file.
    #
    # @return [Set<Entity>]
    def entities
      default_entities | data_entities | contextual_entities
    end

    ##
    # Entities for the metadata file and crate itself, which should be present in all RO-Crates.
    #
    # @return [Set<Entity>]
    def default_entities
      Set.new([metadata, preview, self])
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

    alias_method :own_payload, :payload
    ##
    # The file payload of the RO-Crate - a map of all the files/directories contained in the RO-Crate, where the
    # key is the path relative to the crate's root, and the value is an Entry where the source data can be read.
    #
    # @return [Hash{String => Entry}>]
    def payload
      # Gather a map of entries, starting from the crate itself, then any directory data entities, then finally any
      # file data entities. This ensures in the case of a conflict, the more "specific" data entities take priority.
      entries = own_payload
      sorted_entities = (default_entities.delete(self) | data_entities).sort_by { |e| e.is_a?(ROCrate::Directory) ? 0 : 1 }

      sorted_entities.each do |entity|
        entity.payload.each do |path, entry|
          entries[path] = entry
        end
      end

      entries
    end
    alias_method :entries, :payload

    def get_binding
      binding
    end

    ##
    # Remove the entity from the RO-Crate.
    #
    # @param entity [Entity, String] The entity or ID of an entity to remove from the crate.
    # @param remove_orphaned [Boolean] Should linked contextual entities also be removed from the crate they are left
    #                                   dangling (nothing else is linked to them)?
    #
    # @return [Entity, nil] The entity that was deleted, or nil if nothing was deleted.
    def delete(entity, remove_orphaned: true)
      entity = dereference(entity) if entity.is_a?(String)
      return unless entity

      deleted = data_entities.delete?(entity) || contextual_entities.delete?(entity)

      if deleted && remove_orphaned
        crate_entities = crate.linked_entities(deep: true)
        to_remove = (entity.linked_entities(deep: true) - crate_entities)
        to_remove.each(&:delete)
      end

      deleted
    end

    ##
    # Remove any contextual entities that are not linked from any other entity.
    # Optionally takes a block to decide whether the given entity should be removed or not, otherwise removes all
    # unlinked entities.
    # @yieldparam [ContextualEntity] entity An unlinked contextual entity.
    # @yieldreturn [Boolean] remove Should this entity be removed?
    #
    # @return [Array<ContextualEntity>] The entities that were removed.
    def gc(&block)
      unlinked_entities = contextual_entities - metadata.linked_entities(deep: true)

      unlinked_entities.select(&block).each { |e| e.delete(remove_orphaned: false) }
    end

    private

    def full_entry_path(relative_path)
      relative_path
    end
  end
end
