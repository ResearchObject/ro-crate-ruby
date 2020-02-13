module ROCrate
  class Directory < Entity
    attr_accessor :content
    properties(%w[name contentSize dateModified encodingFormat identifier sameAs])

    def initialize(crate, input_directory = nil, crate_path = nil, properties = {})
      raise 'Not a directory' if input_directory && !(::File.directory?(input_directory) rescue false)
      super(crate, crate_path, properties)
      @entries = {}
      if input_directory
        Dir.chdir(input_directory) { Dir.glob("**/*") }.each do |file|
          source_path = ::File.expand_path(::File.join(input_directory, file))
          dest_path = ::File.join(id, file)
          @entries[dest_path] = DirectoryEntry.new(source_path)
        end
      end
    end

    def entries
      @entries
    end

    private

    def default_properties
      super.merge(
        '@id' => "./#{SecureRandom.uuid}/",
        '@type' => 'Dataset'
      )
    end
  end
end
