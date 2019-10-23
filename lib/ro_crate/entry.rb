require 'securerandom'

module ROCrate
  class Entry
    def initialize(io, opts = {})
      @io = io
      @opts = opts
    end

    def filename
      @filename ||= "file_#{SecureRandom.uuid}.txt"
    end

    def id
      "./#{filename}"
    end

    def filepath
      filename
    end

    def write(io)
      io.write('abcdefgh')
    end

    def content_size
      8
    end

    def description
      'words'
    end
  end
end
