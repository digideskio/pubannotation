# encoding: utf-8
require 'spec_helper'

describe AnnotationsController do
  describe 'index' do
    context 'when project exists' do
      before do
        @user = FactoryGirl.create(:user)
        @project = FactoryGirl.create(:project, 
          :user => @user, 
          :name => 'test_name',
          :rdfwriter => '',
          :xmlwriter => '',
        )
        @project.docs << FactoryGirl.create(:doc)
        controller.stub(:get_project).and_return(@project)
        controller.stub(:get_docspec).and_return(nil)
        controller.stub(:get_doc).and_return('doc')
        @annotations = {
            :text => 'text val',
            :denotations => 'denotations val',
            :relations => 'relations val',
            :modifications => 'modifications val'
          }
        controller.stub(:get_annotations_for_json).and_return(@annotations)
      end
      
      context 'and when params pmdoc_id or pmc_doc_id exists' do
        
        context 'and when format is html' do
          before do
            get :index, :format => 'html', :project_id => @project.name, :pmdoc_id => 5
          end

          it 'should render html template' do
            response.should render_template('index')
          end
        end
        
        context 'and when format is json' do
          before do
            get :index, :format => 'json', :project_id => @project.name, :pmdoc_id => 5
          end

          it 'should render annotations as json' do
            response.body.should eql(@annotations.to_json)
          end
        end
        
        context 'and when format is ttl' do
          context 'and when project.rdfwriter is empty' do
            before do
              get :index, :format => 'ttl', :project_id => @project.name, :pmdoc_id => 5
            end
  
            it 'should return error 422' do
              response.status.should eql(422)
            end
          end

          context 'and when project.rdfwriter is not empty' do
            before do            
              @project = FactoryGirl.create(:project, 
                :user => @user, 
                :name => 'test_name2',
                :rdfwriter => 'rdfwriter'
              )
              controller.stub(:get_project).and_return(@project)
              @get_conversion_text = 'rendered text'
              controller.stub(:get_conversion).and_return(@get_conversion_text)
              get :index, :format => 'ttl', :project_id => @project.name, :pmdoc_id => 5
            end

            it 'should return get_conversion text' do
              response.body.should eql(@get_conversion_text)
            end
          end
        end
        
        context 'and when format is xml' do
          context 'and when project.rdfwriter is empty' do
            before do
              get :index, :format => 'xml', :project_id => @project.name, :pmdoc_id => 5
            end
  
            it 'should return error 422' do
              response.status.should eql(422)
            end
          end

          context 'and when project.rdfwriter is not empty' do
            before do
              @project = FactoryGirl.create(:project, 
                :user => @user, 
                :name => 'test_name3',
                :xmlwriter => 'xmlwriter'
              )
              controller.stub(:get_project).and_return(@project)
              @get_conversion_text = 'rendered text'
              controller.stub(:get_conversion).and_return(@get_conversion_text)
              get :index, :format => 'xml', :project_id => @project.name, :pmdoc_id => 5
            end
  
            it 'should return get_conversion text' do
              response.body.should eql(@get_conversion_text)
            end
          end
        end
      end

      context 'and when params pmdoc_id nor pmc_doc_id does not exists' do
        context 'and when anncollection exists' do
          context 'when params[:delay] present' do
            before do
               Project.any_instance.stub(:anncollection).and_return(
                [{
                  :source_db => 'source_db',
                  :source_id => 'source_id',
                  :division_id => 1,
                  :section => 'section',
               }])
               @refrerer = root_path
              request.env["HTTP_REFERER"] = @refrerer
              get :index, :delay => true, :project_id => @project.name
            end
            
            it 'should redirect to back' do
              response.should redirect_to(@refrerer)
            end
            
            after do
              # delete ZIP file
              File.unlink(@project.annotations_zip_path)
            end  
          end
          
          context 'when format is json' do
            before do
               Project.any_instance.stub(:anncollection).and_return(
                [{
                  :source_db => 'source_db',
                  :source_id => 'source_id',
                  :division_id => 1,
                  :section => 'section',
               }])
              get :index, :format => 'json', :project_id => @project.name
            end
            
            it 'should returns zip' do
              response.header['Content-Type'].should eql('application/zip')
            end
          end
  
          context 'when format is ttl' do
            before do
              controller.stub(:get_conversion).and_return(
              'line1
              line2
              line3
              line4
              line5
              line6
              line7
              line8
              line9
              ')
              get :index, :format => 'ttl', :project_id => @project.name
            end
            
            it 'should returns x-turtle' do
              response.header['Content-Type'].should eql('application/x-turtle; charset=utf-8')
            end
          end
        end

        context 'and when anncollection does not exists' do
          before do
            Project.any_instance.stub(:anncollection).and_return([])            
          end
          
          context 'and whern format html' do
            before do
              get :index, :format => 'html', :project_id => @project.name
            end
            
            it 'should render template' do
              response.should render_template('index')
            end
          end
          
          context 'and whern format json' do
            before do
              get :index, :format => 'json', :project_id => @project.name
            end
            
            it 'should return error 422' do
              response.status.should eql(422)
            end
          end
          
          context 'and whern format ttl' do
            before do
              get :index, :format => 'ttl', :project_id => @project.name
            end
            
            it 'should return error 422' do
              response.status.should eql(422)
            end
          end
        end
      end
    end
  end

  describe 'create' do
    before do
      controller.class.skip_before_filter :authenticate_user!
      @current_user = FactoryGirl.create(:user)
      current_user_stub(@current_user)
      @doc = FactoryGirl.create(:doc)
      @project = FactoryGirl.create(:project, name: 'project name', user: @current_user)
    end

    context 'when project present' do
      before do
        controller.stub(:get_doc).and_return(@doc)
        controller.stub(:get_project).and_return(@project)
      end

      context 'when doc present' do
        before do
          @project.docs << @doc
          @annotations = {'key' => 'value'} 
          controller.stub(:save_annotations) do |annotations, project, doc|
            @attr_annotations = annotations
          end
          @referer_path = docs_path
          request.env["HTTP_REFERER"] = @referer_path
        end

        context 'when params[:annotations] present' do
          context 'when format html' do
            before do
              post :create, project_id: @project.id, annotations: @annotations
            end
            
            it 'should set params[:annotations].symblize_keys as annotaitons' do
              @attr_annotations.should eql(@annotations.symbolize_keys)
            end
            
            it 'should redirect_to :back' do
              response.should redirect_to @referer_path
            end
          end

          context 'when format json' do
            before do
              post :create, project_id: @project.id, annotations: @annotations, format: 'json'
            end
            
            it 'should return created header' do
              response.status.should eql(201)
            end
          end
        end

        context 'when params[:text] present' do
          before do
            @denotations = 'denotations'
            @relations = 'relations'
            @modifications = 'modifications'
            @text = 'text'
            post :create, project_id: @project.id, text: @text, denotations: @denotations, relations: @relations, modifications: @modifications
          end
          
          it 'should set params text, denotations, relations, modifications as annotaitons' do
            @attr_annotations.should eql({:text => @text, :denotations => @denotations, :modifications => @modifications, :relations => @relations})
          end
        end

        context 'when params annotations, text is nil' do
          before do
            post :create, project_id: @project.id
          end
          
          it 'should set flash' do
            flash[:notice].should eql(I18n.t('controllers.annotations.create.no_annotation'))
          end
        end
      end

      context 'when doc blank' do
        before do
          controller.stub(:get_project).and_return(@project)
          controller.stub(:get_doc).and_return(@doc)
          @sourcedb = 'sourcedb'
          @sourceid = 'sourceid'
          post :create, project_id: @project.id, sourcedb: @sourcedb, sourceid: @sourceid
        end

        it 'should set flash' do
          flash[:notice].should eql(I18n.t('controllers.annotations.create.no_project_document', :project_id => @project.id, :sourcedb => @sourcedb, :sourceid => @sourceid)) 
        end
        
        it 'should redirect_to project_path' do
          response.should redirect_to project_path(@project.name)
        end
      end
    end

    context 'when project blank' do
      context 'when format html' do
        before do
          post :create, project_id: 0
        end

        it 'should redirect_to home_path' do
          response.should redirect_to home_path
        end
      end

      context 'when format json' do
        before do
          post :create, project_id: 0, format: 'json'
        end

        it 'should return unprocessable' do
          response.status.should eql 422
        end
      end
    end
  end
  
  describe 'set_access_control_headers' do
    context 'when HTTP_ORIGIN includes allowed_origins' do
      before do
        @controller = AnnotationsController.new
        @http_origin = 'http://bionlp.dbcls.jp'
        @controller.stub(:request).and_return(double(:env => {'HTTP_ORIGIN' => 'http://bionlp.dbcls.jp'}))
        @headers = Hash.new
        @controller.stub(:headers).and_return(@headers)
        @controller.instance_eval{ set_access_control_headers }
      end
      
      it 'shoule set headers Access-Control-Allow-Origin' do
        @headers['Access-Control-Allow-Origin'].should eql(@http_origin)
      end
      
      it 'shoule set headers Access-Control-Allow-Methods' do
        @headers['Access-Control-Allow-Methods'].should eql('POST, GET, OPTIONS')
      end
      
      it 'shoule set headers Access-Control-Allow-Headers' do
        @headers['Access-Control-Allow-Headers'].should eql('Origin, Accept, Content-Type, X-Requested-With, X-CSRF-Token, X-Prototype-Version')
      end
      
      it 'shoule set headers Access-Control-Allow-Credentials' do
        @headers['Access-Control-Allow-Credentials'].should eql('true')
      end
      
      it 'shoule set headers Access-Control-Max-Age' do
        @headers['Access-Control-Max-Age'].should eql('1728000')
      end
    end
  end

  describe 'generate' do
    before do 
      controller.class.skip_before_filter :authenticate_user!
      @current_user = FactoryGirl.create(:user)
      current_user_stub(@current_user)
      @project = FactoryGirl.create(:project, user: @current_user)
      @sourcedb = 'sourcedb'
      @sourceid = 'sourceid'
      @doc = FactoryGirl.create(:doc)
      @referer_path = root_path
      request.env["HTTP_REFERER"] = @referer_path
    end

    context 'when project present' do
      context 'when doc present' do
        before do
          controller.stub(:get_doc).and_return(@doc)
          @annotations = 'annotations'
          controller.stub(:get_annotations).and_return(nil)
          controller.stub(:gen_annotations).and_return(@annotations)
          controller.stub(:save_annotations) do |annotations, project, doc|
            @attr_annotations = annotations
          end
        end

        context 'when format html' do
          before do
            post :generate, project_id: @project.name, sourcedb: @sourcedb, sourceid: @sourceid
          end

          it 'should redirect_to back' do
            response.should redirect_to @referer_path 
          end

          it 'should set save_annotations as flash[:notice]' do
            flash[:notice].should eql @attr_annotations
          end
        end

        context 'when format html' do
          before do
            post :generate, project_id: @project.name, sourcedb: @sourcedb, sourceid: @sourceid, format: 'json'
          end
          
          it 'should return no content' do
           response.status.should eql 204
          end
        end
      end

      context 'when doc blank' do
        before do
          controller.stub(:get_doc).and_return(nil)
        end

        context 'when format html' do
          before do
            post :generate, project_id: @project.name, sourcedb: @sourcedb, sourceid: @sourceid
          end

          it 'should redirect_to project_path' do
            response.should redirect_to project_path(@project.name)
          end

          it 'should set save_annotations as flash[:notice]' do
            flash[:notice].should eql I18n.t('controllers.annotations.create.no_project_document', :project_id => @project.name, :sourcedb => @sourcedb, :sourceid => @sourceid) 
          end
        end

        context 'when format json' do
          before do
            post :generate, project_id: @project.name, sourcedb: @sourcedb, sourceid: @sourceid, format: 'json'
          end

          it 'should return unprocessable' do
            response.status.should eql 422
          end
        end
      end

      context 'when project blank' do
        before do
          post :generate, project_id: 0, sourcedb: @sourcedb, sourceid: @sourceid
        end

        it 'should return unprocessable' do
          response.should redirect_to home_path
        end
      end
    end
  end
  
  describe 'destroy_all' do
    before do
      controller.class.skip_before_filter :authenticate_user!
      @project = FactoryGirl.create(:project)
      @another_project = FactoryGirl.create(:project)
      controller.stub(:get_project).and_return([@project])
      controller.stub(:get_docspec).and_return(nil)
      
      @doc = FactoryGirl.create(:doc, :sourcedb => 'PMC', :sourceid => '123')
      controller.stub(:get_doc).and_return([@doc])
      @denotation_1 = FactoryGirl.create(:denotation, :project => @project, :doc => @doc)
      @denotation_2 = FactoryGirl.create(:denotation, :project => @project, :doc => @doc)
      @denotation_3 = FactoryGirl.create(:denotation, :project => @another_project, :doc => @doc)
      @referer_path = root_path
      request.env["HTTP_REFERER"] = @referer_path
    end
    
    context 'when annotations_destroy_all_project_sourcedb_sourceid_docs' do
      before do
        post :destroy_all, :project_id => @project.name, :sourcedb => @doc.sourcedb, :sourceid => @doc.sourceid 
      end    
      
      it 'should destroy doc.denotation belongs to project' do
        Denotation.find_by_id(@denotation_1.id).should be_nil
        Denotation.find_by_id(@denotation_2.id).should be_nil
      end
      
      it 'should not destroy doc.denotation not belongs to project' do
        Denotation.find_by_id(@denotation_3.id).should be_present
      end
      
      it 'should redirect_to back' do
        response.should redirect_to @referer_path
      end
    end
    
    context 'when annotations_project_sourcedb_sourceid_divs_docs' do
      before do
        post :destroy_all, :project_id => @project.name, :sourcedb => @doc.sourcedb, :sourceid => @doc.sourceid 
      end    
      
      it 'should destroy doc.denotation belongs to project' do
        Denotation.find_by_id(@denotation_1.id).should be_nil
        Denotation.find_by_id(@denotation_2.id).should be_nil
      end
      
      it 'should not destroy doc.denotation not belongs to project' do
        Denotation.find_by_id(@denotation_3.id).should be_present
      end
      
      it 'should redirect_to back' do
        response.should redirect_to @referer_path
      end
    end
      
    describe 'transaction cause error' do
      before do
        ActiveRecord::Relation.any_instance.stub(:destroy_all).and_raise('ERROR')
        post :destroy_all, :project_id => @project.name, :sourcedb => @doc.sourcedb, :sourceid => @doc.sourceid 
      end
      
      it 'should set flash[:notice]' do
        flash[:notice].should be_present
      end
    end
  end
end 
