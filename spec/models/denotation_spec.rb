require 'spec_helper'

describe Denotation do
  describe 'belongs_to project' do
    before do
      @project = FactoryGirl.create(:project, :user => FactoryGirl.create(:user))
      @denotation = FactoryGirl.create(:denotation, :project => @project, :doc => FactoryGirl.create(:doc))
    end
    
    it 'denotation.should belongs to project' do
      @denotation.project.should eql(@project)
    end
  end
  
  describe 'belongs_to doc' do
    before do
      @doc = FactoryGirl.create(:doc)
      @denotation = FactoryGirl.create(:denotation, :doc => @doc, :project_id => 1)
      @doc.reload
    end
    
    it 'denotation should belongs to doc' do
      @denotation.doc.should eql(@doc)
    end  
    
    it 'doc should count up doc.denotations_count' do
      @doc.denotations_count.should eql(1)
    end  
  end
  
  describe 'has_many instances' do
    before do
      @denotation = FactoryGirl.create(:denotation, :project_id => 10, :doc_id => 20)
      @instance = FactoryGirl.create(:instance, :obj => @denotation, :project_id => 10) 
    end
    
    it 'denotation.instances should present' do
      @denotation.instances.should be_present
    end
    
    it 'denotation.instances should present' do
      (@denotation.instances - [@instance]).should be_blank
    end
  end
  
  describe 'has_many subrels' do
    before do
      @denotation = FactoryGirl.create(:denotation, :doc_id => 1, :project_id => 1)
      @relation = FactoryGirl.create(:relation,
        :subj_id => @denotation.id, 
        :subj_type => @denotation.class.to_s,
        :obj_id => 50, 
        :project_id => 1
      )
    end
    
    it 'denotation.resmods should preset' do
      @denotation.subrels.should be_present 
    end
    
    it 'denotation.resmods should include relation' do
      (@denotation.subrels - [@relation]).should be_blank 
    end
  end
  
  describe 'has_many objrels' do
    before do
      @denotation = FactoryGirl.create(:denotation, :doc_id => 1, :project_id => 1)
      @relation = FactoryGirl.create(:relation,
        :subj_id => 1, 
        :subj_type => 'Instance',
        :obj => @denotation, 
        :project_id => 1
      )
    end
    
    it 'denotation.objrels should preset' do
      @denotation.objrels.should be_present 
    end
    
    it 'denotation.resmods should include relation' do
      (@denotation.objrels - [@relation]).should be_blank 
    end
  end
  
  describe 'has_many insmods' do
    before do
      @denotation = FactoryGirl.create(:denotation, :doc_id => 1, :project_id => 1)
      @instance = FactoryGirl.create(:instance, :obj => @denotation, :project_id => 5)
      @modification = FactoryGirl.create(:modification,
      :obj => @instance,
      :obj_type => @instance.class.to_s
      )
    end
    
    it 'denotation.insmods should present' do
      @denotation.insmods.should be_present
    end
  end
  
  describe 'scope' do
    describe 'within_spans' do
      before do
        @denotation_0_9 = FactoryGirl.create(:denotation, :doc_id => 1, :project_id => 1, :begin => 0, :end => 9)
        @denotation_5_15 = FactoryGirl.create(:denotation, :doc_id => 2, :project_id => 2, :begin => 5, :end => 15)
        @denotation_10_15 = FactoryGirl.create(:denotation, :doc_id => 3, :project_id => 3, :begin => 10, :end => 15)
        @denotation_10_19 = FactoryGirl.create(:denotation, :doc_id => 4, :project_id => 4, :begin => 10, :end => 19)
        @denotation_10_20 = FactoryGirl.create(:denotation, :doc_id => 4, :project_id => 4, :begin => 10, :end => 20)
        @denotation_15_19 = FactoryGirl.create(:denotation, :doc_id => 5, :project_id => 5, :begin => 15, :end => 19)
        @denotation_15_25 = FactoryGirl.create(:denotation, :doc_id => 6, :project_id => 6, :begin => 15, :end => 25)
        @denotation_20_30 = FactoryGirl.create(:denotation, :doc_id => 7, :project_id => 7, :begin => 20, :end => 30)
        @denotations = Denotation.within_spans(10, 20)
      end
      
      it 'should not include begin and end are out of spans' do
        @denotations.should_not include(@denotation_0_9)
      end
      
      it 'should not include begin is out of spans' do
        @denotations.should_not include(@denotation_5_15)
      end
      
      it 'should include begin and end are within of spans' do
        @denotations.should include(@denotation_10_15)
      end
      
      it 'should include begin and end are within of spans' do
        @denotations.should include(@denotation_10_19)
      end
      
      it 'should include begin and end are within of spans' do
        @denotations.should include(@denotation_10_20)
      end
      
      it 'should include begin and end are within of spans' do
        @denotations.should include(@denotation_15_19)
      end
      
      it 'should not include end is within of spans' do
        @denotations.should_not include(@denotation_15_25)
      end
    end
   
    describe 'projects_denotations' do
      before do
        @denotation_project_1 = FactoryGirl.create(:denotation, :doc_id => 1, :project_id => 1)
        @denotation_project_2 = FactoryGirl.create(:denotation, :doc_id => 1, :project_id => 2)
        @denotation_project_3 = FactoryGirl.create(:denotation, :doc_id => 1, :project_id => 3)
      end
      
      it 'should include project_id included in project_ids' do
        Denotation.projects_denotations([1,2]).should =~ [@denotation_project_1, @denotation_project_2]
      end
    end 
    
    describe 'sql' do
      before do
        # User
        @current_user = FactoryGirl.create(:user)
        Denotation.stub(:current_user).and_return(@current_user)
        @another_user = FactoryGirl.create(:user)
        # Project
        @current_user_project_1 = FactoryGirl.create(:project, :user => @current_user, :accessibility => 0)
        @current_user_project_2 = FactoryGirl.create(:project, :user => @current_user, :accessibility => 0)
        @another_user_project_1 = FactoryGirl.create(:project, :user => @another_user, :accessibility => 0)
        @another_user_project_accessible = FactoryGirl.create(:project, :user => @another_user, :accessibility => 1)
        # Doc
        @doc_1 = FactoryGirl.create(:doc)
        @doc_2 = FactoryGirl.create(:doc)
        @doc_3 = FactoryGirl.create(:doc)
        @doc_4 = FactoryGirl.create(:doc)
        
        # Denotation
        @current_user_project_denotation_1 = FactoryGirl.create(:denotation, :project => @current_user_project_1, :doc => @doc_1)
        @current_user_project_denotation_2 = FactoryGirl.create(:denotation, :project => @current_user_project_2, :doc => @doc_2)
        @current_user_project_denotation_no_doc = FactoryGirl.create(:denotation, :project => @current_user_project_2, :doc_id => 100000)
        @another_user_project_denotation_1 = FactoryGirl.create(:denotation, :project => @another_user_project_1, :doc => @doc_3)
        @another_user_accessible_project_denotation = FactoryGirl.create(:denotation, :project => @another_user_project_accessible, :doc => @doc_4)
        
        ids = Denotation.all.collect{|d| d.id}
        @denotations = Denotation.sql(ids, @current_user.id)
      end
      
      it "should include denotations belongs to current user's project" do
        @denotations.should include(@current_user_project_denotation_1)
        @denotations.should include(@current_user_project_denotation_2)
      end
      
      it "should not include denotations doc is nil" do
        @denotations.should_not include(@current_user_project_denotation_no_doc)
      end
      
      it "should include denotations belongs to another users's project which accessibility == 1" do
        @denotations.should include(@another_user_accessible_project_denotation)
      end
      
      it "should not include denotations belongs to another users's project which accessibility != 1" do
        @denotations.should_not include(@another_user_project_denotation_1)
      end
    end   
  end
  
  describe 'get_hash' do
    before do
      @denotation = FactoryGirl.create(:denotation,
        :hid => 'hid',
        :begin => 1,
        :end => 5,
        :obj => 'obj',
        :project_id => 'project_id',
        :doc_id => 3
      )
      @get_hash = @denotation.get_hash
    end
    
    it 'should set hid as id' do
      @get_hash[:id].should eql(@denotation[:hid])
    end
    
    it 'should set begin as denotation:begin' do
      @get_hash[:span][:begin].should eql(@denotation[:begin])
    end
    
    it 'should set end as denotation:end' do
      @get_hash[:span][:end].should eql(@denotation[:end])
    end
    
    it 'obj as obj' do
      @get_hash[:obj].should eql(@denotation[:obj])
    end
  end
  
  describe 'self.project_denotations_count' do
    before do
      @project = FactoryGirl.create(:project)
      @another_project = FactoryGirl.create(:project)
      @proejct_denotations_count = 2
      @proejct_denotations_count.times do
        FactoryGirl.create(:denotation, :project => @project, :doc => FactoryGirl.create(:doc))
      end
    end
    
    context 'when project have denotations' do
      it 'should return denotations count' do
        Denotation.project_denotations_count(@project.id, Denotation).should eql(@proejct_denotations_count)
      end
    end
    
    context 'when project does not have denotations' do
      it 'should return denotations count' do
        Denotation.project_denotations_count(@another_project.id, Denotation).should eql(0)
      end
    end
  end
  
  describe 'increment_sproject_denotations_count' do
    before do
      @project = FactoryGirl.create(:project, :denotations_count => 0)
      @sproject_1 = FactoryGirl.create(:sproject, :denotations_count => 0)
      FactoryGirl.create(:projects_sproject, :project_id => @project.id, :sproject_id => @sproject_1.id)
      @sproject_2 = FactoryGirl.create(:sproject, :denotations_count => 1)
      FactoryGirl.create(:projects_sproject, :project_id => @project.id, :sproject_id => @sproject_2.id)
      @denotation = FactoryGirl.create(:denotation, :project => @project, :doc_id => 1)
    end
    
    it 'should increment project.denotations_count' do
      @project.reload
      @project.denotations_count.should eql(1)
    end      
    
    it 'should increment sproject.denotations_count' do
      @sproject_1.reload
      @sproject_1.denotations_count.should eql(1)
    end      
    
    it 'should increment sproject.denotations_count' do
      @sproject_2.reload
      @sproject_2.denotations_count.should eql(2)
    end      
  end
  
  describe 'decrement_sproject_denotations_count' do
    before do
      @project = FactoryGirl.create(:project, :denotations_count => 0)
      @sproject_1 = FactoryGirl.create(:sproject, :denotations_count => 1)
      FactoryGirl.create(:projects_sproject, :project_id => @project.id, :sproject_id => @sproject_1.id)
      @sproject_2 = FactoryGirl.create(:sproject, :denotations_count => 2)
      FactoryGirl.create(:projects_sproject, :project_id => @project.id, :sproject_id => @sproject_2.id)
      @denotation = FactoryGirl.create(:denotation, :project => @project, :doc_id => 1)
      @project.reload
      @sproject_1.reload
      @sproject_2.reload
      @denotation.destroy
    end
    
    it 'should decrement project.denotations_count' do
      @project.denotations_count.should eql(1)
      @project.reload
      @project.denotations_count.should eql(0)
    end      
    
    it 'should decrement sproject.denotations_count' do
      @sproject_1.denotations_count.should eql(2)
      @sproject_1.reload
      @sproject_1.denotations_count.should eql(1)
    end      
    
    it 'should decrement sproject.denotations_count' do
      @sproject_2.denotations_count.should eql(3)
      @sproject_2.reload
      @sproject_2.denotations_count.should eql(2)
    end
  end
  
  describe 'self.sql_find' do
    before do
    end
    
    context 'when params[:sql] present' do
      before do
        @sql = 'select * from denotations;'
        @params = {:sql => @sql}
        @project = FactoryGirl.create(:project, :accessibility => 1)
        @project_2 = FactoryGirl.create(:project, :accessibility => 1)
        @project_denotation = FactoryGirl.create(:denotation, :project => @project)  
        @not_project_denotation = FactoryGirl.create(:denotation, :project => @project_2)  
      end
      
      context 'when results.present' do
        context 'when project.present' do
          before do
            @denotations = Denotation.sql_find(@params, 1, @project)
          end
          
          it 'should return project denotations' do
            @denotations.should =~ [@project_denotation]
          end
        end
        
        context 'when project.blank' do
          before do
            @denotations = Denotation.sql_find(@params, 1000, nil)
          end
          
          it 'should return project denotations' do
            @denotations.should =~ Denotation.all
          end
        end
      end
    end

    context 'when params[:sql] blank' do
      before do
        @denotations = Denotation.sql_find({}, 1000, nil)
      end
      
      it 'should return blank' do
        @denotations.should be_blank
      end
    end
  end
end