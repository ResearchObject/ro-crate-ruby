module ROCrate
  class JSONLDHash < ::Hash
    def initialize(graph, content = {})
      @graph = graph
      super()
      update(stringified(content))
    end

    def [](key)
      jsonld_wrap(super)
    end

    def dereference
      @graph.dereference(self['@id']) if self['@id']
    end

    def has_type?(type)
      t = self['@type']
      t.is_a?(Array) ? t.include?(type) : t == type
    end

    private

    def jsonld_wrap(val)
      if val.is_a?(Array)
        val.map { |v| jsonld_wrap(v) }
      elsif val.instance_of?(::Hash)
        self.class.new(@graph, val)
      else
        val
      end
    end

    # A slow and stupid way of making sure all hash keys are strings.
    def stringified(hash)
      JSON.parse(hash.to_json)
    end
  end
end
