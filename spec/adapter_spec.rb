require 'spec_helper'

describe DataMapper::Adapters::WebAdapter do
  
  before :all do
   @adapter = DataMapper.setup(:default, :adapter => 'web', :scheme => 'http', :host => 'localhost', :port => 3000, :mappings => {
     :heffalumps => {
        :create_path => 'heffalumps/new', :create_form_id => 'new_heffalump', 
        :update_path => 'heffalumps/:id/edit', :update_form_id => 'edit_heffalump',
        :query_path  => 'heffalumps', :collection_selector => '/html/body/table//tr/td[position()<5]' 
       }
   }
   )      
  end
  
  describe '#create' do
    it 'should not raise any errors' do
      lambda {
        Heffalump.create(:color => 'peach')
      }.should_not raise_error
    end

    it 'should set the identity field for the resource' do
      heffalump = Heffalump.new(:color => 'peach')
      heffalump.id.should be_nil
      heffalump.save
      heffalump.id.should_not be_nil
    end
  end

  describe '#read' do
    before :all do
      @heffalump = Heffalump.create(:color => 'brownish hue')
    end

    it 'should not raise any errors' do
      lambda {
        Heffalump.all()
      }.should_not raise_error
    end

    it 'should return stuff' do
      Heffalump.all.should be_include(@heffalump)
    end
  end
      
end