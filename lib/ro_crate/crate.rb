module ROCrate
  class Crate < Directory
    properties(%w[name datePublished author license identifier distribution contactPoint publisher description url hasPart])

    attr_reader :entries

    def initialize
      @entries = []
      super('./')
    end

    def add_file(file, path: nil)
      path ||= file.respond_to?(:path) ? file.path : nil
      @entries << ROCrate::File.new(file, path)
    end

    def metadata
      @metadata ||= ROCrate::Metadata.new(self)
    end

    def metadata=(metadata)
      @metadata = metadata
    end

    def contents
      [metadata, self] + entries
    end

    def properties
      super.merge('hasPart' => @entries.map(&:reference))
    end
  end
end
