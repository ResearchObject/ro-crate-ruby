require_relative './entry'
require_relative './metadata'
require 'json/ld'
require 'zip'

module ROCrate
  class Crate
    attr_reader :entries

    def initialize
      @entries = []
    end

    def add(file, opts = {})
      @entries << Entry.new(file, opts)
    end

    def write(dir)
      # Write metadata
      ROCrate::Metadata.new(self).write(File.join(dir, 'ro-crate-metadata.jsonld'))

      # Write entries
      @entries.each do |entry|
        entry.write(File.join(dir, entry.filepath))
      end
    end

    def write_zip(io)
      Zip::File.open(io, Zip::File::CREATE) do |zip|
        # Write metadata
        zip.get_output_stream('ro-crate-metadata.jsonld') { |s| ROCrate::Metadata.new(self).write(s) }

        # Write entries
        @entries.each do |entry|
          zip.get_output_stream(entry.filepath) { |s| entry.write(s) }
        end
      end
    end
  end
end
