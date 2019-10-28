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
            if zipfile.file.exist?(filepath)
              zipfile.file.open(filepath)
            else
              puts "Warning! Referenced file: #{filepath} not found."
            end
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
          ::File.open(::File.join(path, filepath))
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
        crate = graph.detect { |entry| entry['@id'] == './' || entry['@id'] == '.' }
        if crate
          ro_crate = ROCrate::Crate.new
          ro_crate.properties = crate
          crate['hasPart'].each do |ref|
            part = graph.detect { |entry| entry['@id'] == ref['@id'] }
            if part
              if part['@type'] == 'File' # TODO: This is not enough! Need to check subclasses
                file = ROCrate::File.new(yield(part['@id']))
                file.properties = part
                ro_crate.entries << file
              elsif part['@type'] == 'Directory'
                dir = ROCrate::Directory.new
                dir.properties = part
                ro_crate.entries << dir
              else
                thing = ROCrate::Node.new
                thing.properties = part
                ro_crate.entries << thing
              end
            end
          end

          return ro_crate
        else
          raise "No { @id : './' } found in @graph!"
        end
      else
        raise "No @graph found in metadata!"
      end
    end
  end
end
