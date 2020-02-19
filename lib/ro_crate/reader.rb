module ROCrate
  class Reader
    ##
    # Reads an RO Crate from a directory of zip file.
    #
    # @param source [String, File, Pathname] The source location for the crate.
    # @return [Crate] The RO Crate.
    def self.read(source)
      if source.is_a?(String) && ::File.directory?(source)
        read_directory(source)
      else
        read_zip(source)
      end
    end

    ##
    # Reads an RO Crate from a zip file.
    #
    # @param source [String, File, Pathname] The location of the zip file.
    # @return [Crate] The RO Crate.
    def self.read_zip(source)
      Zip::File.open(source) do |zipfile|
        if zipfile.file.exist?(ROCrate::Metadata::IDENTIFIER)
          metadata_file = zipfile.file.open(ROCrate::Metadata::IDENTIFIER)
          read_from_metadata(metadata_file.read) do |filepath|
            filepath = filepath[2..-1] if filepath.start_with?('./')
            zipfile.file.open(filepath) if zipfile.file.exist?(filepath)
          end
        else
          raise "No metadata found!"
        end
      end
    end

    ##
    # Reads an RO Crate from a directory.
    #
    # @param path [String] The location of the directory.
    # @return [Crate] The RO Crate.
    def self.read_directory(path)
      metadata_file = Dir.entries(path).detect { |entry| entry == ROCrate::Metadata::IDENTIFIER }

      if metadata_file
        read_from_metadata(::File.open(::File.join(path, metadata_file)).read) do |filepath|
          fullpath = ::File.join(path, filepath)
          ::File.open(fullpath) if ::File.exist?(fullpath)
        end
      else
        raise "No metadata found!"
      end
    end

    ##
    # Reads an RO Crate from an `ro-crate-metadata.json` file.
    # Takes a block that implements reading of data entities.
    #
    # @yieldparam [String] filepath The path of the data entity to be read.
    # @yieldreturn [File] A file object for that entity.
    # @param metadata_json [String] A string containing the metadata JSON.
    # @return [Crate] The RO Crate.
    def self.read_from_metadata(metadata_json, &block)
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
          initialize_crate(entities, &block)
        else
          raise "No { @id : '#{ROCrate::Crate::IDENTIFIER}' } found in @graph!"
        end
      else
        raise "No @graph found in metadata!"
      end
    end

    ##
    # Create a crate from the given set of entities and block specifying how to read files.
    #
    # @yieldparam [String] filepath The path of the data entity to be read.
    # @yieldreturn [File] A file object for that entity.
    # @param entities [Hash] A Hash containing all the entities in the @graph, mapped by their @id.
    # @return [Crate] The RO Crate.
    def self.initialize_crate(entities)
      ROCrate::Crate.new.tap do |crate|
        crate.properties = entities[ROCrate::Crate::IDENTIFIER]
        crate.metadata.properties = entities[ROCrate::Metadata::IDENTIFIER]
        entities[ROCrate::Crate::IDENTIFIER]['hasPart'].each do |ref|
          part = entities.delete(ref['@id'])
          next unless part
          if Array(part['@type']).include?('Dataset')
            thing = ROCrate::Directory.new(crate, nil, nil, part)
          else
            file = yield(part['@id'])
            if file
              thing = ROCrate::File.new(crate, file, part['@id'], part)
            else
              warn "Could not find: #{part['@id']}"
            end
          end
          crate.add_data_entity(thing)
        end

        entities.each do |id, entity|
          crate.create_contextual_entity(id, entity)
        end
      end
    end
  end
end
