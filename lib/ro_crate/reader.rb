module ROCrate
  ##
  # A class to handle reading of RO Crates from Zip files or directories.
  class Reader
    ##
    # Reads an RO Crate from a directory of zip file.
    #
    # @param source [String, File, Pathname] The source location for the crate.
    # @return [Crate] The RO Crate.
    def self.read(source)
      if ::File.directory?(source)
        read_directory(source)
      else
        read_zip(source)
      end
    end

    ##
    # Reads an RO Crate from a zip file. It first extracts the Zip file to a temporary directory, and then calls
    # #read_directory.
    #
    # @param source [String, File, Pathname] The location of the zip file.
    # @return [Crate] The RO Crate.
    def self.read_zip(source)
      source = ::File.expand_path(source)
      dir = Dir.mktmpdir
      Dir.chdir(dir) do
        Zip::File.open(source) do |zipfile|
          zipfile.each do |entry|
            unless ::File.exist?(entry.name)
              FileUtils::mkdir_p(::File.dirname(entry.name))
              zipfile.extract(entry, entry.name)
            end
          end
        end
      end

      read_directory(dir)
    end

    ##
    # Reads an RO Crate from a directory.
    #
    # @param source [String, File, Pathname] The location of the directory.
    # @return [Crate] The RO Crate.
    def self.read_directory(source)
      source = ::File.expand_path(source)
      metadata_file = Dir.entries(source).detect { |entry| entry == ROCrate::Metadata::IDENTIFIER }

      if metadata_file
        entities = entities_from_metadata(::File.open(::File.join(source, metadata_file)))
        build_crate(entities, source)
      else
        raise "No metadata found!"
      end
    end

    ##
    # Reads an RO Crate from an `ro-crate-metadata.json` file.
    #
    # @param metadata_json [String] A string containing the metadata JSON.
    # @return [Array<Hash>]
    def self.entities_from_metadata(metadata_json)
      metadata = JSON.load(metadata_json)
      graph = metadata['@graph']

      if graph
        # Collect all the things in the graph, mapped by their @id
        entities = {}
        graph.each do |entity|
          entities[entity['@id']] = entity
        end
        # Do some normalization...
        entities[ROCrate::Crate::IDENTIFIER] = (entities.delete('./') || entities.delete('.'))
        entities[ROCrate::Metadata::IDENTIFIER] = (entities.delete('./ro-crate-metadata.jsonld') || entities.delete('ro-crate-metadata.jsonld'))
        if entities[ROCrate::Crate::IDENTIFIER]
          entities
        else
          raise "No { @id : '#{ROCrate::Crate::IDENTIFIER}' } found in @graph!"
        end
      else
        raise "No @graph found in metadata!"
      end
    end

    ##
    # Create a crate from the given set of entities.
    #
    # @param entity_hash [Hash] A Hash containing all the entities in the @graph, mapped by their @id.
    # @param source [String, File, Pathname] The location of the RO Crate being read.
    # @return [Crate] The RO Crate.
    def self.build_crate(entity_hash, source)
      ROCrate::Crate.new.tap do |crate|
        crate.properties = entity_hash.delete(ROCrate::Crate::IDENTIFIER)
        crate.metadata.properties = entity_hash.delete(ROCrate::Metadata::IDENTIFIER)
        extract_data_entities(crate, source, entity_hash).each do |entity|
          crate.add_data_entity(entity)
        end
        # The remaining entities in the hash must be contextual.
        entity_hash.each do |id, entity|
          crate.create_contextual_entity(id, entity)
        end
      end
    end

    ##
    # Discover data entities from the `hasPart` property of a crate, and create DataEntity objects for them.
    # Entities are looked up in the given `entity_hash` (and then removed from it).
    # @param crate [Crate] The RO Crate being read.
    # @param source [String, File, Pathname] The location of the RO Crate being read.
    # @param entity_hash [Hash] A Hash containing all the entities in the @graph, mapped by their @id.
    # @return [Array<DataEntity>] An array of ROCrate::File or ROCrate::Directory objects.
    def self.extract_data_entities(crate, source, entity_hash)
      crate.raw_properties['hasPart'].map do |ref|
        entity_props = entity_hash.delete(ref['@id'])
        next unless entity_props
        id = entity_props['@id']
        fullpath = ::File.join(source, id)
        path = ::File.exist?(fullpath) ? Pathname.new(fullpath) : nil
        unless path
          warn "Missing file/directory: #{id}, skipping..."
          next
        end

        type = if Array(entity_props['@type']).include?('Dataset')
                 ROCrate::Directory
               else
                 ROCrate::File
               end

        type.new(crate, path, id, entity_props)
      end.compact
    end
  end
end
