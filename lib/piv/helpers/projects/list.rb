module Piv
  module Helpers
    module Projects
      module List
        def metachar_to_attribute_map
          {
            '%n' => :name,
            '%I' => :original_id
          }
        end

        def list_session_projects
          session_projects.each do |project|
            if project.current?
              print_formatted_model(project, options[:cformat])
            else
              print_formatted_model(project)
            end
          end
        end
      end
    end
  end
end
