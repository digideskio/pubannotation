require 'impression_lib'

class HomeController < ApplicationController
  def index
    unless read_fragment('sourcedbs')
      # @sourcedbs = Doc.select(:sourcedb).sourcedbs.uniq
      @sourcedb_doc_counts = Doc.where("serial = ?", 0).group(:sourcedb).count
    end
    @projects_number = Project.accessible(current_user).length
    @projects_top = Project.accessible(current_user).top
    @popular_project_impressions = ImpressionLib.popular('Project')
    @popular_docs = ImpressionLib.popular('Doc')
  end
end
