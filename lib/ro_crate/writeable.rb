module ROCrate
  module Writeable
    def filename
      filepath.split(File::SEPARATOR).last
    end

    def filepath
      id.sub(/\A.\//, '')
    end

    def write(io)
      io.write(content.respond_to?(:read) ? content.read : content)
    end
  end
end
