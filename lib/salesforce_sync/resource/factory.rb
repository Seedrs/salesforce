module SalesforceSync
  module Resource
    class Factory
      def self.create(resource)
        sf_class(resource.class).new(resource.id)
      end

      def self.sf_class(resource_class)
        resource_by_class = SalesforceSync::Rsource::Base.sf_classes_by_resource_class.find do |klass, _sf_class|
          resource_class <= klass
        end

        if resource_by_class.present?
          class_constant(resource_by_class[1])
        else
          SalesforceSync::Error.new("sf class not found for #{resource_class}", self).raise_error
        end
      end

      def self.resource_class(sf_class)
        resource_by_class = SalesforceSync::Rsource::Base.sf_classes_by_resource_class.find{ |_klass, sf_klass| sf_klass.to_s == sf_class.to_s }

        if resource_by_class.present?
          class_constant(resource_by_class[0])
        else
          SalesforceSync::Error.new("resource class not found for #{sf_class}", self).raise_error
        end
      end

      private

      def self.class_constant(klass)
        "::#{klass}".constantize
      end
    end
  end
end
