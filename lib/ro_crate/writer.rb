module ROCrate
  ##
  # A class to handle writing of RO-Crates to Zip files or directories.
  class Writer
    ##
    # Initialize a new Writer for the given Crate.
    # @param crate [Crate] The RO-Crate to be written.
    def initialize(crate)
      @crate = crate
    end

    ##
    # Write the crate to a directory.
    #
    # @param dir [String] A path for the directory for the crate to be written to. All parent directories will be created.
    # @param overwrite [Boolean] Whether or not to overwrite existing files.
    def write(dir, overwrite: true)
      FileUtils.mkdir_p(dir) # Make any parent directories
      @crate.payload.each do |path, entry|
        fullpath = ::File.join(dir, path)
        next if !overwrite && ::File.exist?(fullpath)
        next if entry.directory?
        FileUtils.mkdir_p(::File.dirname(fullpath))
        if entry.symlink?
          ::File.symlink(entry.source.readlink, fullpath)
        else
          temp = Tempfile.new('ro-crate-temp')
          begin
            entry.write_to(temp)
            temp.close
            FileUtils.mv(temp, fullpath)
          ensure
            temp.unlink
          end
        end
      end
    end

    ##
    # Write the crate to a zip file.
    #
    # @param destination [String, ::File] The destination where to write the RO-Crate zip.
    def write_zip(destination)
      Zip::File.open(destination, Zip::File::CREATE) do |zip|
        @crate.payload.each do |path, entry|
          next if entry.directory?
          if entry.symlink?
            zip.add(path, entry.path) if entry.path
          else
            zip.get_output_stream(path) { |s| entry.write_to(s) }
          end
        end
      end
    end
  end
end
