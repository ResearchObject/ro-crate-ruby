module ROCrate
  class ContextualEntity < Entity
    def self.format_id(id)
      i = super
      if (URI(i).absolute? rescue false)
        i
      elsif i.start_with?('#')
        i
      else
        "##{i}"
      end
    end
  end
end
