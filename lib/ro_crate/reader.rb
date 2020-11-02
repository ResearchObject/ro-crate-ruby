module ROCrate
  ##
  # A class to handle reading of RO Crates from Zip files or directories.
  class Reader
    ##
    # Reads an RO Crate from a directory of zip file.
    #
    # @param source [String, ::File, Pathname] The source location for the crate.
    # @param target_dir [String, ::File, Pathname] The target directory where the crate should be unzipped (if its a Zip file).
    # @return [Crate] The RO Crate.
    def self.read(source, target_dir: Dir.mktmpdir)
      raise "Not a directory!" unless ::File.directory?(target_dir)
      if ::File.directory?(source)
        read_directory(source)
      else
        read_zip(source, target_dir: target_dir)
      end
    end

    ##
    # Extract the contents of the given Zip file to the given directory.
    #
    # @param source [String, ::File, Pathname] The location of the zip file.
    # @param target [String, ::File, Pathname] The target directory where the file should be unzipped.
    def self.unzip_to(source, target)
      source = ::File.expand_path(source)
      Dir.chdir(target) do
        Zip::File.open(source) do |zipfile|
          zipfile.each do |entry|
            unless ::File.exist?(entry.name)
              FileUtils::mkdir_p(::File.dirname(entry.name))
              zipfile.extract(entry, entry.name)
            end
          end
        end
      end
    end

    ##
    # Reads an RO Crate from a zip file. It first extracts the Zip file to a temporary directory, and then calls
    # #read_directory.
    #
    # @param source [String, ::File, Pathname] The location of the zip file.
    # @param target_dir [String, ::File, Pathname] The target directory where the crate should be unzipped.
    # @return [Crate] The RO Crate.
    def self.read_zip(source, target_dir: Dir.mktmpdir)
      unzip_to(source, target_dir)

      read_directory(target_dir)
    end

    ##
    # Reads an RO Crate from a directory.
    #
    # @param source [String, ::File, Pathname] The location of the directory.
    # @return [Crate] The RO Crate.
    def self.read_directory(source)
      source = ::File.expand_path(source)
      metadata_file = Dir.entries(source).detect { |entry| entry == ROCrate::Metadata::IDENTIFIER ||
          entry == ROCrate::Metadata::IDENTIFIER_1_0 }

      if metadata_file
        entities = entities_from_metadata(::File.read(::File.join(source, metadata_file)))
        build_crate(entities, source)
      else
        raise 'No metadata found!'
      end
    end

    ##
    # Extracts all the entities from the @graph of the RO Crate Metadata.
    #
    # @param metadata_json [String] A string containing the metadata JSON.
    # @return [Hash{String => Hash}] A Hash of all the entities, mapped by their @id.
    def self.entities_from_metadata(metadata_json)
      metadata = JSON.parse(metadata_json)
      graph = metadata['@graph']

      if graph
        # Collect all the things in the graph, mapped by their @id
        entities = {}
        graph.each do |entity|
          entities[entity['@id']] = entity
        end

        # Do some normalization...
        entities[ROCrate::Metadata::IDENTIFIER] = extract_metadata_entity(entities)
        raise "No metadata entity found in @graph!" unless entities[ROCrate::Metadata::IDENTIFIER]
        entities[ROCrate::Crate::IDENTIFIER] = extract_root_entity(entities)
        raise "No root entity (with @id: #{entities[ROCrate::Metadata::IDENTIFIER].dig('about', '@id')}) found in @graph!" unless entities[ROCrate::Crate::IDENTIFIER]

        entities
      else
        raise "No @graph found in metadata!"
      end
    end

    ##
    # Create a crate from the given set of entities.
    #
    # @param entity_hash [Hash{String => Hash}] A Hash containing all the entities in the @graph, mapped by their @id.
    # @param source [String, ::File, Pathname] The location of the RO Crate being read.
    # @return [Crate] The RO Crate.
    def self.build_crate(entity_hash, source)
      ROCrate::Crate.new.tap do |crate|
        crate.properties = entity_hash.delete(ROCrate::Crate::IDENTIFIER)
        crate.metadata.properties = entity_hash.delete(ROCrate::Metadata::IDENTIFIER)
        extract_data_entities(crate, source, entity_hash).each do |entity|
          crate.add_data_entity(entity)
        end
        # The remaining entities in the hash must be contextual.
        extract_contextual_entities(crate, entity_hash).each do |entity|
          crate.add_contextual_entity(entity)
        end
      end
    end

    ##
    # Discover data entities from the `hasPart` property of a crate, and create DataEntity objects for them.
    # Entities are looked up in the given `entity_hash` (and then removed from it).
    # @param crate [Crate] The RO Crate being read.
    # @param source [String, ::File, Pathname] The location of the RO Crate being read.
    # @param entity_hash [Hash] A Hash containing all the entities in the @graph, mapped by their @id.
    # @return [Array<ROCrate::File, ROCrate::Directory>] The extracted DataEntity objects.
    def self.extract_data_entities(crate, source, entity_hash)
      crate.raw_properties['hasPart'].map do |ref|
        entity_props = entity_hash.delete(ref['@id'])
        next unless entity_props
        entity_class = ROCrate::DataEntity.specialize(entity_props)
        entity = create_data_entity(crate, entity_class, source, entity_props)
        next if entity.nil?
        entity
      end.compact
    end

    ##
    # Create appropriately specialized ContextualEntity objects from the given hash of entities and their properties.
    # @param crate [Crate] The RO Crate being read.
    # @param entity_hash [Hash] A Hash containing all the entities in the @graph, mapped by their @id.
    # @return [Array<ContextualEntity>] The extracted ContextualEntity objects.
    def self.extract_contextual_entities(crate, entity_hash)
      entities = []

      entity_hash.each do |id, entity_props|
        entity_class = ROCrate::ContextualEntity.specialize(entity_props)
        entity = entity_class.new(crate, id, entity_props)
        entities << entity
      end

      entities
    end

    ##
    # Create a DataEntity of the given class.
    # @param crate [Crate] The RO Crate being read.
    # @param source [String, ::File, Pathname] The location of the RO Crate being read.
    # @param entity_props [Hash] A Hash containing the entity's properties, including its @id.
    # @return [ROCrate::File, ROCrate::Directory, nil] The DataEntity object,
    #          or nil if it referenced a local file that wasn't found.
    def self.create_data_entity(crate, entity_class, source, entity_props)
      id = entity_props.delete('@id')
      decoded_id = URI.decode_www_form_component(id)
      path = nil
      uri = URI(id) rescue nil
      if uri&.absolute?
        path = uri
        decoded_id = nil
      else
        [id, decoded_id].each do |i|
          fullpath = ::File.join(source, i)
          path = Pathname.new(fullpath) if ::File.exist?(fullpath)
        end
        unless path
          warn "Missing file/directory: #{id}, skipping..."
          return nil
        end
      end

      entity_class.new(crate, path, decoded_id, entity_props)
    end


    ##
    # Extract the metadata entity from the entity hash, according to the rules defined here:
    # https://www.researchobject.org/ro-crate/1.1/root-data-entity.html#finding-the-root-data-entity
    # @return [Hash{String => Hash}] A Hash containing (hopefully) one value, the metadata entity's properties,
    # mapped by its @id.
    def self.extract_metadata_entity(entities)
      key = entities.detect do |_, props|
        props.key?('conformsTo') && props['conformsTo'].start_with?(ROCrate::Metadata::RO_CRATE_BASE)
      end&.first

      return entities.delete(key) if key

      # Legacy support
      (entities.delete("./#{ROCrate::Metadata::IDENTIFIER}") ||
          entities.delete(ROCrate::Metadata::IDENTIFIER) ||
          entities.delete("./#{ROCrate::Metadata::IDENTIFIER_1_0}") ||
          entities.delete(ROCrate::Metadata::IDENTIFIER_1_0))
    end

    ##
    # Extract the root entity from the entity hash, according to the rules defined here:
    # https://www.researchobject.org/ro-crate/1.1/root-data-entity.html#finding-the-root-data-entity
    # @return [Hash{String => Hash}] A Hash containing (hopefully) one value, the root entity's properties,
    # mapped by its @id.
    def self.extract_root_entity(entities)
      root_id = entities[ROCrate::Metadata::IDENTIFIER].dig('about', '@id')
      raise "Metadata entity does not reference any root entity" unless root_id
      entities.delete(root_id)
    end
  end
end
