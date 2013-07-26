require 'spec_helper'

describe DataMapper::Adapters::WebAdapter do
  
  before :all do
   @adapter = DataMapper.setup(:default, :adapter => 'web', :host => 'localhost', :port => 5000)      
  end
  
  it 'should do stuff' do
  end

end