module ROCrate
  ##
  # A module to handle writing of an Entity to a File (or other IO-like) object.
  # Must provide `content` as a String (or IO-like) as the source to write.
  module Writeable
    ##
    # The path of the file, relative to the root of the RO crate.
    def filepath
      Addressable::URI.unescape(canonical_id.path.sub(/\A\//, '')) # Remove initial / and decode %20 etc.
    end

    ##
    # Write the file to the given IO.
    def write(io)
      io.write(content.respond_to?(:read) ? content.read : content)
    end
  end
end
