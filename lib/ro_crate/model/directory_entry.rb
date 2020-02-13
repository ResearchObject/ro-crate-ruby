module ROCrate
  class DirectoryEntry

    attr_reader :path

    def initialize(path)
      @path = path
    end

    def write(dest)
      ::File.open(path, 'r') do |input|
        while buff = input.read(4096)
          dest.write(buff)
        end
      end
    end

    def directory?
      ::File.directory?(path)
    end
  end
end
