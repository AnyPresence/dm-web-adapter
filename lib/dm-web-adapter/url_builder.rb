module DataMapper
  module Adapters
    module Web
      module UrlBuilder
      
        def configured_mapping(storage_name)
          DataMapper.logger.debug("@mappings are #{@mappings.inspect} and storage_name is #{storage_name.inspect}")
          @mappings.fetch(storage_name.to_sym)
        end
        
        def build_edit_url(storage_name, id)
          url = build_path(storage_name,:update_path).gsub(":id",id.to_s)
          DataMapper.logger.debug("Will use #{url} to update")
          url
        end
        
        def build_query_url(query)
          storage_name = query.model.storage_name(query.repository)
          url = build_path(storage_name,:query_path)
          id_param = nil
          query.conditions.each do |condition|
            if condition.instance_of? ::DataMapper::Query::Conditions::EqualToComparison
              DataMapper.logger.debug("Handling equal to comparison #{condition.inspect}")
              id_param = condition.loaded_value
            else
              raise "Not yet supported!"
            end
          end
          
          url += "?query=#{id_param.to_s}" if id_param
          DataMapper.logger.debug("Will use #{url} to read")
          url
        end

        def build_create_url(storage_name)
          url = build_path(storage_name,:create_path)
          DataMapper.logger.debug("Will use #{url} to create")
          url
        end

        def build_form_id(storage_name, type, id=nil)
          form_id = configured_mapping(storage_name).fetch(type)
          if type == :update_form_id
            form_id = form_id.gsub(":id",id.to_s)
          end
          form_id
        end

        def build_form_property_id(storage_name, property)
          "#{DataMapper::Inflector.singularize(storage_name.to_s)}_#{property}"
        end

        def build_path(storage_name, path_type)
          configured_path = configured_mapping(storage_name).fetch(path_type)
          path = configured_path.nil? ? "#{storage_name.to_s}.#{@format.to_s}" : configured_path
          "#{@options[:scheme]}://#{@options[:host]}:#{@options[:port]}/#{path}"
        end
        
      end
    end
  end
end