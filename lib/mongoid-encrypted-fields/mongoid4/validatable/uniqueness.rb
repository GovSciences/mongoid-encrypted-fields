# encoding: utf-8

module Mongoid
  module Validatable

    # Monkey-patch for Mongoid's uniqueness validator to enforce that the :case_sensitive option does not work
    # for encrypted fields; they must always be case-sensitive.
    # Patch is confirmed to work on Mongoid >= 4.0.0
    class UniquenessValidator
      attr_reader :klass

      # Older versions of Mongoid's UniquenessValidator have a klass variable to reference the validating document
      # This was later replaced in ActiveModel with options[:class]
      def initialize(options={})
        @klass = options[:class] if options.key?(:class)
        super
      end

      def check_validity!

        return unless klass

        attributes.each do |attribute|
          field_name = klass.database_field_name(attribute)
          field_type = klass.fields[field_name].options[:type] if klass.fields[field_name]
          raise ArgumentError, "Encrypted field :#{attribute} cannot support uniqueness validation.  Use searchable encrypted type instead." if field_type && field_type.method_defined?(:encrypted) && field_type.respond_to?(:unsearchable?)
        end

        return if case_sensitive?
        attributes.each do |attribute|
          field_type = klass.fields[klass.database_field_name(attribute)].options[:type]
          raise ArgumentError, "Encrypted field :#{attribute} cannot support case insensitive uniqueness" if field_type && field_type.method_defined?(:encrypted)
        end
      end

    end
  end
end
