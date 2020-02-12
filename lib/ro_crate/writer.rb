module ROCrate
  class Writer
    def initialize(crate)
      @crate = crate
    end

    def write(dir)
      FileUtils.mkdir_p(dir) # Make any parent directories
      @crate.entries.each do |path, entry|
        fullpath = ::File.join(dir, path)
        FileUtils.mkdir_p(::File.dirname(fullpath))
        next if entry.directory?
        ::File.open(fullpath, 'w') { |f| entry.write(f) }
      end
    end

    def write_zip(io)
      Zip::File.open(io, Zip::File::CREATE) do |zip|
        @crate.entries.each do |path, entry|
          next if entry.directory?
          zip.get_output_stream(path) { |s| entry.write(s) }
        end
      end
    end
  end
end
