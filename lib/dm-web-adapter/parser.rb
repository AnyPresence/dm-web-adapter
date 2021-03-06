module DataMapper
  module Adapters
    module Web
      module Parser
        
        def parse_collection(page, model, fields = nil)
          #TODO: Add fields support. This is what the query provides as the properties to be read
          @log.debug("parse_collection(#{page.inspect}, #{model}, #{fields})")
          xpath_expression = configured_mapping(class_name(model)).fetch(:collection_selector)
          collection = parse_collection_using_expression(page, model, fields, xpath_expression)
          
          if collection.empty? # Fallback on single record selector lest it's a "show" page
            xpath_expression = configured_mapping(class_name(model)).fetch(:record_selector)
            collection = parse_collection_using_expression(page, model, fields, xpath_expression)
          end
          
          @log.debug("Made collection #{collection.inspect}")
          collection
        end
        
        def parse_collection_using_expression(page, model, fields, xpath_expression)
          @log.debug("Will use xpath expression #{xpath_expression}")
          collection = []
          array = page.search(xpath_expression)
          @log.debug("Array is #{array.inspect}")
          properties = make_indexed_property_hash(model)
          @log.debug("Will use properties #{properties.inspect}")
          i = 0
          while i < array.size
            element = array[i,properties.size].map{|e| e.text.empty? ? nil : e.text }
            @log.debug("Array about to process is " + element.inspect)
            collection << parse_record(element, properties)
            i += properties.size
          end
          collection
        end
        
        def parse_record(values, properties)
          record = {}
          values.each_index do |index|
            next unless value = values[index]
            property = properties[index]
            @log.debug("Setting #{property.name} = #{property.typecast(value)}")
            record[property.field] = property.typecast(value)
          end
          @log.debug("Made record #{record.inspect}")
          record
        end
  
        
        def update_attributes(resource, body)
          @log.debug("update_attributes(#{resource}, #{body})")
          return if DataMapper::Ext.blank?(body)
          fields = {}
          model      = resource.model
          properties = model.properties(key_on=:field)

          properties.each do |prop| 
            fields[prop.field.to_sym] = prop.name.to_sym 
          end

          parse_record(body, model).each do |key, value|
            if property = properties[fields[key.to_sym]]
              property.set!(resource, value)
            end
          end
        end
  
        def make_indexed_property_hash(model)
          index = 0
          properties = {}
          model.properties(key_on=:field).each do |property|
            properties[index] = property
            index += 1
          end
          properties
        end
      end  
    end
  end
end