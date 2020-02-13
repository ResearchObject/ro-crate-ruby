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
        temp = Tempfile.new('ro-crate-temp')
        begin
          entry.write(temp)
          temp.close
          FileUtils.mv(temp, fullpath)
        ensure
          temp.unlink
        end
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
