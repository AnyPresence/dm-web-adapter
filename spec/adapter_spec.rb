require 'spec_helper'

describe DataMapper::Adapters::WebAdapter do
  
  before :all do
   @adapter = DataMapper.setup(:default, :adapter => 'web', :scheme => 'http', :host => 'localhost', :port => 3000, :mappings => {
     :heffalumps => {
        :create_path => 'heffalumps/new', :create_form_id => 'new_heffalump', 
        :query_path  => 'heffalumps', :collection_selector => '/html/body/table//tr/td[position()<5]',
        :update_path => 'heffalumps/:id/edit', :update_form_id => 'edit_heffalump_:id',
        :delete_path => 'heffalumps/:id'
       }
   }
   )      
  end
  
  describe '#create' do
    it 'should not raise any errors' do
      lambda {
        heffalump_model.create(:color => 'peach')
      }.should_not raise_error
    end

    it 'should set the identity field for the resource' do
      heffalump = heffalump_model.new(:color => 'peach')
      heffalump.id.should be_nil
      heffalump.save
      heffalump.id.should_not be_nil
    end
  end

  describe '#read' do
    before :all do
      @heffalump = heffalump_model.create!(:color => 'brownish hue', :num_spots => 5, :striped => true)
    end

    it 'should not raise any errors' do
      lambda {
        heffalump_model.all()
      }.should_not raise_error
    end

    it 'should return stuff' do
      heffalump_model.all.should be_include(@heffalump)
    end
  end
  describe '#update' do
    before do
      @heffalump = heffalump_model.create(:color => 'indigo')
    end

    it 'should not raise any errors' do
      lambda {
        @heffalump.color = 'violet'
        @heffalump.save
      }.should_not raise_error
    end

    it 'should not alter the identity field' do
      id = @heffalump.id
      @heffalump.color = 'violet'
      @heffalump.save
      @heffalump.id.should == id
    end

    it 'should update altered fields' do
      @heffalump.color = 'violet'
      @heffalump.save
      heffalump_model.get(*@heffalump.key).color.should == 'violet'
    end

    it 'should not alter other fields' do
      color = @heffalump.color
      @heffalump.num_spots = 3
      @heffalump.save
      heffalump_model.get(*@heffalump.key).color.should == color
    end
  end
  
  describe '#delete' do
    before do
      @heffalump = heffalump_model.create(:color => 'forest green')
    end

    it 'should not raise any errors' do
      lambda {
        @heffalump.destroy
      }.should_not raise_error
    end

    it 'should delete the requested resource' do
      id = @heffalump.id
      @heffalump.destroy
      heffalump_model.get(id).should be_nil
    end
  end
end