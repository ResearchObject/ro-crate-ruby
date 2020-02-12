module ROCrate
  class Writer
    def initialize(crate)
      @crate = crate
    end

    def write(dir)
      FileUtils.mkdir_p(dir) # Make any parent directories
      @crate.entities.each do |entity|
        if entity.is_a?(ROCrate::File)
          entries = [entity]
        elsif entity.is_a?(ROCrate::Directory)
          entries = entity.entries
        else
          next
        end

        entries.each do |entry|
          fullpath = ::File.join(dir, entry.filepath)
          FileUtils.mkdir_p(::File.dirname(fullpath))
          ::File.open(fullpath, 'w') { |f| entry.write(f) }
        end
      end
    end

    def write_zip(io)
      Zip::File.open(io, Zip::File::CREATE) do |zip|
        @crate.entities.each do |entity|
          if entity.is_a?(ROCrate::File)
            entries = [entity]
          elsif entity.is_a?(ROCrate::Directory)
            entries = entity.entries
          else
            next
          end

          entries.each do |entry|
            zip.get_output_stream(entry.filepath) { |s| entry.write(s) }
          end
        end
      end
    end
  end
end
