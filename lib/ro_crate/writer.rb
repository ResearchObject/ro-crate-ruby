module ROCrate
  class Writer
    ##
    # Initialize a new Writer for the given Crate.
    # @param crate [Crate] The RO Crate to be written.
    def initialize(crate)
      @crate = crate
    end

    ##
    # Write the crate to a directory.
    #
    # @param dir [String] A path for the directory for the crate to be written to. All parent directories will be created.
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

    ##
    # Write the crate to a zip file.
    #
    # @param destination [String, File] The destination where to write the RO Crate zip.
    def write_zip(destination)
      Zip::File.open(destination, Zip::File::CREATE) do |zip|
        @crate.entries.each do |path, entry|
          next if entry.directory?
          zip.get_output_stream(path) { |s| entry.write(s) }
        end
      end
    end
  end
end
