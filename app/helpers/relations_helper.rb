module RelationsHelper
  def relations_count_helper(project, options = {})
    if params[:action] == 'spans'
      relations = @doc.hrelations(project, {:spans => {:begin_pos => params[:begin], :end_pos => params[:end]}})
      relations.present? ? relations.size : 0
    else 
      if project.present?
        if options[:doc].present?
          if params[:controller] == 'projects'
            
          else  
            options[:doc].project_relations_count(project.id)
          end
        else 
          project.relations_count
        end
      else
        options[:doc].relations_count
      end
    end
  end
end
