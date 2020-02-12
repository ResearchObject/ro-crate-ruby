module ROCrate
  class Reader
    def self.read(path_or_io)
      if path_or_io.is_a?(String)
        if ::File.directory?(path_or_io)
          read_directory(path_or_io)
        else
          read_zip(path_or_io)
        end
      else
        read_zip(path_or_io)
      end
    end

    def self.read_zip(path_or_io)
      Zip::File.open(path_or_io) do |zipfile|
        if zipfile.file.exist?(ROCrate::Metadata::FILENAME)
          metadata_file = zipfile.file.open(ROCrate::Metadata::FILENAME)
          read_from_metadata(metadata_file.read) do |filepath|
            filepath = filepath[2..-1] if filepath.start_with?('./')
            zipfile.file.open(filepath) if zipfile.file.exist?(filepath)
          end
        else
          raise "No metadata found!"
        end
      end
    end

    def self.read_directory(path)
      metadata_file = Dir.entries(path).detect { |entry| entry == ROCrate::Metadata::FILENAME }

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
    # Block takes a relative path and should return a File
    def self.read_from_metadata(metadata_json)
      metadata = JSON.load(metadata_json)
      graph = metadata['@graph']

      if graph
        # Collect all the things in the graph, mapped by their @id
        entities = {}
        graph.each do |entity|
          entities[entity['@id']] = entity
        end
        crate_info = entities.delete('./') || entities.delete('.')
        crate_metadata_info = entities.delete('./ro-crate-metadata.jsonld') || entities.delete('ro-crate-metadata.jsonld')
        if crate_info
          ROCrate::Crate.new.tap do |crate|
            crate.properties = crate_info
            crate.metadata.properties = crate_metadata_info
            crate_info['hasPart'].each do |ref|
              part = entities.delete(ref['@id'])
              next unless part
              if Array(part['@type']).include?('Dataset')
                thing = ROCrate::Directory.new(crate, nil, nil, part)
              else
                file = yield(part['@id'])
                if file
                  thing = ROCrate::File.new(crate, file, nil, part)
                else
                  thing = ROCrate::Entity.new(crate, nil, part)
                end
              end
              crate.add_data_entity(thing)
            end

            entities.each do |id, entity|
              crate.create_contextual_entity(id, entity)
            end
          end
        else
          raise "No { @id : './' } found in @graph!"
        end
      else
        raise "No @graph found in metadata!"
      end
    end
  end
end
