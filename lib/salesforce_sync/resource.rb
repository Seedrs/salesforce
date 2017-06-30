module SalesforceSync
  module Resource
    extend self

    def self.descendants
      ObjectSpace.each_object(Class).select { |klass| klass < SalesforceSync::Resource::Base }
    end

    def self.events
      descendants.flat_map(&:events)
    end

    def self.sf_classes_by_resource_class
      descendants.each_with_object({}) do |descendant, mapping|
        mapping[descendant.resource_class] = descendant
      end
    end

    def self.resource_classes
      descendants.map(&:resource_class)
    end
  end
end
