module ROCrate
  class DirectoryEntry

    attr_reader :path

    def initialize(path)
      @path = path
    end

    def write(io)
      io.write(::File.open(path, 'r').read)
    end

    def directory?
      ::File.directory?(path)
    end
  end
end
