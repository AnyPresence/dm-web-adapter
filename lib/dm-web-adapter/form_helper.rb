module DataMapper
  module Adapters
    module Web
      module FormHelper
        
        def fill_form(form, properties, storage_name)
          @log.debug("Fill form #{form.inspect} with #{properties.inspect} and storage name #{storage_name.inspect}")
          properties.each do |property, value|
            @log.debug("Setting #{property.inspect} to #{value.inspect}")
            field_form_id = build_form_property_id(storage_name, property)
            checkbox_field = form.checkbox_with(:id => field_form_id)
            @log.debug("Pulled field #{checkbox_field.inspect} using #{field_form_id}")
            if value.is_a? TrueClass
              checkbox_field.check
            elsif value.is_a? FalseClass
              checkbox_field.uncheck
            else
              field = form.field_with(:id => field_form_id)
              @log.debug("Pulled field #{field.inspect} using #{field_form_id}")
              field.value = value
            end
          end
          form
        end
        
      end
    end
  end
end