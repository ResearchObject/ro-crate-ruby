module ROCrate
  class Writer
    def initialize(crate)
      @crate = crate
    end

    def write(dir)
      @crate.contents.each do |entry|
        ::File.open(::File.join(dir, entry.filepath), 'w') { |f| entry.write(f) } if entry.respond_to?(:write)
      end
    end

    def write_zip(io)
      Zip::File.open(io, Zip::File::CREATE) do |zip|
        @crate.contents.each do |entry|
          zip.get_output_stream(entry.filepath) { |s| entry.write(s) } if entry.respond_to?(:write)
        end
      end
    end
  end
end
