require 'spec_helper'

describe DataMapper::Adapters::WebAdapter do
  
  before :all do
   @adapter = DataMapper.setup(:default, :adapter => 'web', :scheme => 'http', :host => 'localhost', :port => 3000, :mappings => {
     :heffalumps => {:create_path => 'heffalumps/new', :create_form_id => 'new_heffalump' }
   }
   )      
  end
  
  describe '#create' do
    it 'should not raise any errors' do
      heffalump = Heffalump.new(:color => 'red')
      lambda {
        heffalump.save
      }.should_not raise_error
    end
  end
end