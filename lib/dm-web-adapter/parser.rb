module DataMapper
  module Adapters
    module Web
      module Parser
        
        def parse_collection(page, model)
          DataMapper.logger.debug("parse_collection(#{page.inspect}, #{model})")
          xpath_expression = configured_mapping(model.storage_name).fetch(:collection_selector)
          DataMapper.logger.debug("Will use xpath expression #{xpath_expression}")
          collection = []
          array = page.search(xpath_expression)
          properties = make_indexed_property_hash(model)
          DataMapper.logger.debug("Will use properties #{properties.inspect}")
          i = 0
          while i < array.size
            element = array[i,properties.size].map{|e| e.text.empty? ? nil : e.text }
            DataMapper.logger.debug("Array about to process is " + element.inspect)
            collection << parse_record(element, properties)
            i += properties.size
          end
          DataMapper.logger.debug("Made collection #{collection.inspect}")
          collection
        end
  
        def parse_record(array, properties)
          record = {}
          properties.each do |index, property|
            value = array[index]
            DataMapper.logger.debug("Setting #{property.name} = #{value}")
            record[property.name] = property.typecast(value)
          end
          DataMapper.logger.debug("Made record #{record.inspect}")
          record
        end
  
        
        def update_attributes(resource, body)
          DataMapper.logger.debug("update_attributes(#{resource}, #{body})")
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