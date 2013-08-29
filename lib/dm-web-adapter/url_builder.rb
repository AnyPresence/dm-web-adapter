module DataMapper
  module Adapters
    module Web
      module UrlBuilder
        
        def class_name(model)
          DataMapper::Inflector.pluralize(model.name.split(/::/).last).downcase
        end
        
        def configured_mapping(class_name)
          @log.debug("@mappings are #{@mappings.inspect} and class_name is #{class_name.inspect}")
          @mappings.fetch(class_name.to_sym)
        end
        
        def build_edit_url(class_name, id)
          url = build_path(class_name,:update_path).gsub(":id",id.to_s)
          @log.debug("Will use #{url} to update")
          url
        end
        
        def build_all_url(class_name)
          url = build_path(class_name,:query_path)
          @log.debug("Will use #{url} to read all")
          url
        end
        
        def build_delete_link(class_name, id)
          url = build_path(class_name,:delete_path).gsub(":id",id.to_s)
          @log.debug("Will use #{url} to destroy")
          url
        end
        
        def build_query_url(query)
          class_name = class_name(query.model)
          url = build_path(class_name,:query_path)
          id_param = nil
          query.conditions.each do |condition|
            if condition.instance_of? ::DataMapper::Query::Conditions::EqualToComparison
              @log.debug("Handling equal to comparison #{condition.inspect}")
              id_param = condition.loaded_value
            else
              raise "Not yet supported!"
            end
          end
          
          url += "/#{id_param.to_s}" if id_param
          @log.debug("Will use #{url} to read")
          url
        end

        def build_create_url(class_name)
          url = build_path(class_name,:create_path)
          @log.debug("Will use #{url} to create")
          url
        end

        def build_form_id(class_name, type, id=nil)
          form_id = configured_mapping(class_name).fetch(type)
          if type == :update_form_id
            form_id = form_id.gsub(":id",id.to_s)
          end
          form_id
        end

        def build_form_property_id(class_name, property)
          "#{DataMapper::Inflector.singularize(class_name.to_s)}_#{property}"
        end

        def build_path(class_name, path_type)
          configured_path = configured_mapping(class_name).fetch(path_type)
          path = configured_path.nil? ? "#{class_name.to_s}.#{@format.to_s}" : configured_path
          "#{@options[:scheme]}://#{@options[:host]}:#{@options[:port]}/#{path}"
        end
        
      end
    end
  end
end