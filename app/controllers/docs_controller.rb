require 'zip/zip'

class DocsController < ApplicationController
  protect_from_forgery :except => [:create]
  before_filter :authenticate_user!, :only => [:new, :edit, :create, :generate, :create_project_docs, :update, :destroy, :delete_project_doc]
  after_filter :set_access_control_headers
  # JSON POST
  before_filter :http_basic_authenticate, :only => :create_project_docs, :if => Proc.new{|c| c.request.format == 'application/jsonrequest'}
  skip_before_filter :authenticate_user!, :verify_authenticity_token, :if => Proc.new{|c| c.request.format == 'application/jsonrequest'}

  autocomplete :docs, :sourcedb

  def index
    begin
      if params[:project_id]
        @project = Project.accessible(current_user).find_by_name(params[:project_id])
        raise "There is no such project." unless @project.present?
        docs = @project.docs
        @search_path = search_project_docs_path(@project.name)
      else
        docs = Doc
        @search_path = search_docs_path
      end

      # docs.each{|doc| doc.set_ascii_body} if (params[:encoding] == 'ascii')
      sort_order = sort_order(Doc)
      source_docs_all = docs.where(serial: 0).sort_by_params(sort_order)
      docs_list_hash = source_docs_all.map{|d| d.to_list_hash('doc')}

      @source_docs = source_docs_all.paginate(:page => params[:page])

      respond_to do |format|
        format.html
        format.json {render json: docs_list_hash}
        format.tsv  {render text: Doc.to_tsv(source_docs_all, 'doc')}
      end
    rescue => e
      respond_to do |format|
        format.html {redirect_to (@project.present? ? project_path(@project.name) : home_path), notice: e.message}
        format.json {render json: {notice:e.message}, status: :unprocessable_entity}
        format.txt  {render text: message, status: :unprocessable_entity}
      end
    end
  end
 
  def records
    if params[:project_id]
      @project, notice = get_project(params[:project_id])
      @new_doc_src = new_project_doc_path
      if @project
        @docs = @project.docs.order('sourcedb ASC').order('sourceid ASC').order('serial ASC')
      else
        @docs = nil
      end
    else
      @docs = Doc.order('sourcedb ASC').order('sourceid ASC').order('serial ASC')
      @new_doc_src = new_doc_path
    end

    @docs.each{|doc| doc.set_ascii_body} if (params[:encoding] == 'ascii')

    respond_to do |format|
      if @docs
        format.html { @docs = @docs.paginate(:page => params[:page]) }
        format.json { render json: @docs }
        format.txt  {
          file_name = (@project)? @project.name + ".zip" : "docs.zip"
          t = Tempfile.new("pubann-temp-filename-#{Time.now}")
          Zip::ZipOutputStream.open(t.path) do |z|
            @docs.each do |doc|
              title = "%s-%s-%02d-%s" % [doc.sourcedb, doc.sourceid, doc.serial, doc.section]
              title.sub!(/\.$/, '')
              title.gsub!(' ', '_')
              title += ".txt" unless title.end_with?(".txt")
              z.put_next_entry(title)
              z.print doc.body
            end
          end
          send_file t.path, :type => 'application/zip',
                            :disposition => 'attachment',
                            :filename => file_name
          t.close

          # texts = @docs.collect{|doc| doc.body}
          # render text: texts.join("\n----------\n")
        }
      else
        format.html { flash[:notice] = notice }
        format.json { head :unprocessable_entity }
        format.txt  { head :unprocessable_entity }
      end
    end
  end
 
  def sourcedb_index
    if params[:project_id].present?
      @project = Project.accessible(current_user).find_by_name(params[:project_id])
      raise "There is no such project." unless @project.present?
    end

    @sourcedb_doc_counts = if @project.present?
      @project.docs.where("serial = ?", 0).group(:sourcedb).count
    else
      Doc.where("serial = ?", 0).group(:sourcedb).count
    end
  end 
 
  def sourceid_index
    if params[:project_id].present?
      @project = Project.accessible(current_user).find_by_name(params[:project_id])
      raise "There is no such project." unless @project.present?
      docs = @project.docs.where('sourcedb = ?', params[:sourcedb])
      @search_path = search_project_docs_path(@project.name)
    else
      docs = Doc.where('sourcedb = ?', params[:sourcedb])
      @search_path = search_docs_path
    end

    sort_order = sort_order(Doc)
    @source_docs = docs.where(serial: 0).sort_by_params(sort_order).paginate(:page => params[:page])
  end 

  def search
    begin
      if params[:project_id]
        @project = Project.accessible(current_user).find_by_name(params[:project_id])
        raise "There is no such project." unless @project.present?
        docs = @project.docs
      else
        docs = Doc
      end

      # TODO cannot cannot CAST sourceid
      search_docs = docs.search(
        conditions: {sourcedb: "#{ params[:sourcedb] }*", sourceid: "#{ params[:sourceid] }*", body: "#{ params[:body] }*"}, 
        group_by: 'sourcedb, sourceid',
        order: 'sourcedb ASC, sourceid ASC',
        page: params[:page], 
        per_page: 10
      )

      # TODO search_docs.count is the number of docs matches conditions group by same sourcedb and sourceid.
      if search_docs.count < 5000
        # search_docs_list = search_docs.map{|d| {sourcedb: d.sourcedb, sourceid:d.sourceid}}.uniq
        # This line will execute SQL queries so many times
        # search_docs = search_docs_list.map{|d| docs.find_by_sourcedb_and_sourceid_and_serial(d[:sourcedb], d[:sourceid], 0)}
        search_docs_list = search_docs.map{|d| d.to_list_hash('doc')}
      else
        search_docs_list = []
      end

      @search_docs_number = search_docs.count
      @source_docs = search_docs 

      respond_to do |format|
        format.html
        format.json {render json: search_docs_list}
        format.tsv  {render text: Doc.to_tsv(search_docs, 'doc')}
      end
    rescue => e
      respond_to do |format|
        format.html {redirect_to (@project.present? ? project_path(@project.name) : docs_path), notice: e.message}
        format.json {render json: {notice: e.message}, status: :unprocessable_entity}
        format.tsv  {render text: e.message, status: :unprocessable_entity}
      end
    end
  end

  def show
    begin
      divs = Doc.find_all_by_sourcedb_and_sourceid(params[:sourcedb], params[:sourceid])
      raise "There is no such document." unless divs.present?

      if divs.length > 1
        respond_to do |format|
          format.html {redirect_to doc_sourcedb_sourceid_divs_index_path params}
          format.json {
            divs.each{|div| div.set_ascii_body} if params[:encoding] == 'ascii'
            render json: divs.collect{|div| div.body}
          }
          format.txt {
            divs.each{|div| div.set_ascii_body} if params[:encoding] == 'ascii'
            render text: divs.collect{|div| div.body}.join("\n")
          }
        end
      else
        @doc = divs[0]
        impressionist(@doc)

        @doc.set_ascii_body if params[:encoding] == 'ascii'
        @content = @doc.body.gsub(/\n/, "<br>")
        @annotations = @doc.hannotations

        sort_order = sort_order(Project)
        @projects = @doc.projects.accessible(current_user).sort_by_params(sort_order)

        respond_to do |format|
          format.html
          format.json {render json: @doc.to_hash}
          format.txt  {render text: @doc.body}
        end
      end

    rescue => e
      respond_to do |format|
        format.html {redirect_to (@project.present? ? project_docs_path(@project.name) : docs_path), notice: e.message}
        format.json {render json: {notice:e.message}, status: :unprocessable_entity}
        format.txt  {render text: message, status: :unprocessable_entity}
      end
    end
  end

  def project_doc_show
    begin
      @project = Project.accessible(current_user).find_by_name(params[:project_id])
      raise "There is no such project." unless @project.present?

      divs = @project.docs.find_all_by_sourcedb_and_sourceid(params[:sourcedb], params[:sourceid])
      raise "There is no such document in the project." unless divs.present?

      if divs.length > 1
        respond_to do |format|
          format.html {redirect_to index_project_sourcedb_sourceid_divs_docs_path(@project.name, params[:sourcedb], params[:sourceid])}
          format.json {
            divs.each{|div| div.set_ascii_body} if params[:encoding] == 'ascii'
            render json: divs.collect{|div| div.body}
          }
          format.txt {
            divs.each{|div| div.set_ascii_body} if params[:encoding] == 'ascii'
            render text: divs.collect{|div| div.body}.join("\n")
          }
        end
      else
        @doc = divs[0]

        @doc.set_ascii_body if (params[:encoding] == 'ascii')
        @annotations = @doc.hannotations(@project)
        @content = @doc.body.gsub(/\n/, "<br>")

        respond_to do |format|
          format.html {render 'show_in_project'}
          format.json {render json: @doc.to_hash}
          format.txt  {render text: @doc.body}
        end
      end

    # rescue => e
    #   respond_to do |format|
    #     format.html {redirect_to (@project.present? ? project_docs_path(@project.name) : docs_path), notice: e.message}
    #     format.json {render json: {notice:e.message}, status: :unprocessable_entity}
    #     format.txt  {render status: :unprocessable_entity}
    #   end
    end
  end

  # GET /docs/new
  # GET /docs/new.json
  def new
    @doc = Doc.new
    begin 
      @project = get_project2(params[:project_id])
    rescue => e
      notice = e.message
    end
    respond_to do |format|
      format.html # new.html.erb
      format.json {render json: @doc.to_hash}
    end
  end

  # GET /docs/1/edit
  def edit
    @doc = Doc.find(params[:id])
  end

  # POST /docs
  # POST /docs.json
  def create
    @doc = Doc.new(params[:doc])
    respond_to do |format|
      if @doc.save
        @project, notice = get_project(params[:project_id])
        @project.docs << @doc if @project.present?
        get_project(params[:project_id])
        format.html { 
          if @project.present?
            redirect_to project_doc_path(@project.name, @doc), notice: t('controllers.shared.successfully_created', :model => t('activerecord.models.doc'))
          else
            redirect_to @doc, notice: t('controllers.shared.successfully_created', :model => t('activerecord.models.doc'))
          end 
        }
        format.json { render json: @doc, status: :created, location: @doc }
      else
        format.html { render action: "new" }
        format.json { render json: @doc.errors, status: :unprocessable_entity }
      end
    end
  end

  # add new docs to a project
  def add
    begin
      project = Project.editable(current_user).find_by_name(params[:project_id])
      raise "There is no such project in your management." unless project.present?

      messages = []

      # get the docspecs list
      docspecs =  if params["_json"] && params["_json"].class == Array
                    params["_json"].collect{|d| d.symbolize_keys}
                  elsif params["sourcedb"].present? && params["sourceid"].present?
                    [{sourcedb:params["sourcedb"], sourceid:params["sourceid"]}]
                  elsif params[:ids].present? && params[:sourcedb].present?
                    params[:ids].split(/[ ,"':|\t\n]+/).collect{|id| id.strip}.collect{|id| {sourcedb:params[:sourcedb], sourceid:id}}
                  else
                    []
                  end

      imported, added, failed, messages = 0, 0, 0, []

      raise ArgumentError, "no valid document specification found." if docspecs.empty?

      docspecs.each{|d| d[:sourceid].sub!(/^(PMC|pmc)/, '')}
      docspecs.each do |docspec|
        i, a, f, m = project.add_doc(docspec[:sourcedb], docspec[:sourceid])
        imported += i; added += a; failed += f; messages << m
      end
    rescue => e
      messages << e.message
    end

    respond_to do |format|
      format.html {redirect_to project_path(project.name), notice:"imported:#{imported}, added:#{added}, failed:#{failed}"}
      format.json {render json:{imported:imported, added:added, failed:failed, messages:messages}, status:(added > 0 ? :created : :unprocessable_entity)}
    end
  end

  def uptodate
    # get the docspecs list
    docspecs =  if params["_json"] && params["_json"].class == Array
                  params["_json"].collect{|d| d.symbolize_keys}
                elsif params["sourcedb"].present? && params["sourceid"].present?
                  [{sourcedb:params["sourcedb"], sourceid:params["sourceid"]}]
                elsif params[:ids].present? && params[:sourcedb].present?
                  params[:ids].split(/[ ,"':|\t\n]+/).collect{|id| id.strip}.collect{|id| {sourcedb:params[:sourcedb], sourceid:id}}
                end

    docspecs.each do |docspec|
      doc = Doc.get_doc(docspec)
      p doc.projects
      # divs.each do |div|
      #   p div.projects
      # end
      puts "-----------"
    end

    respond_to do |format|
      format.html {redirect_to project_docs_path(project.name), notice:"imported:#{imported}, added:#{added}, failed:#{failed}"}
      format.json {render json:{imported:imported, added:added, failed:failed, messages:messages}, status:(added > 0 ? :created : :unprocessable_entity)}
    end

  end

  def create_project_docs
    # preprocessing for JSON array
    params[:docs] = params["_json"] if params["_json"]

    docs =  if params[:ids].present? && params[:sourcedb].present?
              params[:ids].split(/[ ,"':|\t\n]+/).collect{|id| id.strip}.collect{|id| {sourcedb:params[:sourcedb], sourceid:id}}
            elsif params[:docs].present?
              params[:docs].collect{|d| d.symbolize_keys}
            end

    begin 
      project = get_project2(params[:project_id])
    rescue => e
      message = e.message
    end

    num_created, num_added, num_failed = 0, 0, 0
    if project && docs
      begin
        num_created, num_added, num_failed = project.add_docs_from_json(docs, current_user)
      rescue => e
      end
    end
    result = {:created => num_created, :added => num_added, :failed => num_failed}

    respond_to do |format|
      format.html {
        notice = result.collect{|k,v| "#{k}: #{v}"}.join(', ')
        redirect_to project_docs_path(project.name), :notice => notice
      }
      format.json {
        if num_created > 0 || num_added > 0
          render :json => result, status: :created, location: project_docs_path(project.name)
        else
          render :json => result, status: :unprocessable_entity
        end
      }
    end  
  end

  # PUT /docs/1
  # PUT /docs/1.json
  def update
    params[:doc][:body].gsub!(/\r\n/, "\n")
    @doc = Doc.find(params[:id])

    respond_to do |format|
      if @doc.update_attributes(params[:doc])
        format.html { redirect_to @doc, notice: t('controllers.shared.successfully_updated', :model => t('activerecord.models.doc')) }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @doc.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /docs/1
  # DELETE /docs/1.json
  def destroy
    @doc = Doc.find(params[:id])
    if params[:project_id].present?
      project = Project.find_by_name(params[:project_id])
      project.docs.delete(@doc)
      redirect_path = records_project_docs_path(params[:project_id])
    else
      @doc.destroy
      redirect_path = docs_url
    end

    respond_to do |format|
      format.html { redirect_to redirect_path }
      format.json { head :no_content }
    end
  end
  
  def delete_project_doc
    begin
      project = Project.editable(current_user).find_by_name(params[:project_id])
      raise "There is no such project in your management." unless project.present?

      divs = project.docs.find_all_by_sourcedb_and_sourceid(params[:sourcedb], params[:sourceid])
      raise "There is no such document in the project." unless divs.present?

      divs.each{|d| d.destroy_project_annotations(project)}
    # rescue => e
    #   flash[:notice] = e
    end

    project.docs.delete(divs) 
    redirect_to :back
  end

  def autocomplete_sourcedb
    render :json => Doc.where(['LOWER(sourcedb) like ?', "%#{params[:term].downcase}%"]).collect{|doc| doc.sourcedb}.uniq
  end

  private

  def set_access_control_headers
    allowed_origins = ['http://localhost', 'http://localhost:8000', 'http://bionlp.dbcls.jp', 'http://textae.pubannotation.org']
    origin = request.env['HTTP_ORIGIN']
    if allowed_origins.include?(origin)
      headers['Access-Control-Allow-Origin'] = origin
      headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'Origin, Accept, Content-Type, X-Requested-With, X-CSRF-Token, X-Prototype-Version'
      headers['Access-Control-Allow-Credentials'] = 'true'
      headers['Access-Control-Max-Age'] = "1728000"
    end
  end

end
