module ROCrate
  class DataEntity < Entity
    def self.format_id(id)
      super.chomp('/')
    end

    def filepath
      Addressable::URI.unescape(id.sub(/\A\//, '')).to_s # Remove initial / and decode %20 etc.
    end
  end
end
