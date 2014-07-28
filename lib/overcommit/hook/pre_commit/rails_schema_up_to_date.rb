module Overcommit::Hook::PreCommit
  # Check to see whether the schema file is in line with the migrations
  class RailsSchemaUpToDate < Base
    def run # rubocop:disable CyclomaticComplexity
      if migration_files.any? && schema_files.none?
        return :fail, "It looks like you're adding a migration, but did not update the schema file"
      elsif migration_files.none? && schema_files.any?
        return :fail, "You're trying to change the schema without adding a migration file"
      elsif migration_files.any? && schema_files.any?
        latest_version = migration_files.map  { |file| file[/\d+/] }.sort.last
        schema         = schema_files.map     { |file| File.read(file) }.join
        up_to_date     = schema.include?(latest_version)

        unless up_to_date
          return :fail, "The latest migration version you're committing is " \
                       "#{latest_version}, but your schema file " \
                       "#{schema_files.join(' or ')} is on a different version."
        end
      end

      :pass
    end

  private

    def migration_files
      @migration_files ||= applicable_files.select do |file|
        file.match %r{db/migrate/.*\.rb}
      end
    end

    def schema_files
      @schema_files    ||= applicable_files.select do |file|
        file.match %r{db/schema\.rb|db/structure.*\.sql}
      end
    end
  end
end
