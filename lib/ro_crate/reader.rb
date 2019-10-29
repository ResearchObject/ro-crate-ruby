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
        crate_info = graph.detect { |entry| entry['@id'] == './' || entry['@id'] == '.' }
        if crate_info
          ROCrate::Crate.new.tap do |crate|
            crate.properties = crate_info
            crate_info['hasPart'].each do |ref|
              part = graph.detect { |entry| entry['@id'] == ref['@id'] }
              next unless part
              if part['@type'] == 'Directory'
                thing = ROCrate::Directory.new(crate)
              else
                file = yield(part['@id'])
                if file
                  thing = ROCrate::File.new(crate, file)
                else
                  thing = ROCrate::Entity.new(crate)
                end
              end
              thing.properties = part
              crate.entries << thing
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
