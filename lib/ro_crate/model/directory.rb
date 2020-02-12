module ROCrate
  class Directory < Entity
    attr_accessor :content
    properties(%w[name contentSize dateModified encodingFormat identifier sameAs])

    def initialize(crate, input_directory = nil, crate_path = nil, properties = {})
      @entries = {}
      if input_directory
        Dir.glob(::File.join(input_directory, '**', '*')).each do |file|
          @entries[::File.join(crate_path || '.', file)] = DirectoryEntry.new(file)
        end
      end
      super(crate, crate_path, properties)
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
