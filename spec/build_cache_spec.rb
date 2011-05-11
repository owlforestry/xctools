require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "BuildCache" do
  it "should initialize" do
    bc = IosBox::BuildCache.new
    bc.kind_of == "IosBox::BuildCache"
  end
  
  it "should do simple storing" do
    bc = IosBox::BuildCache.new
    bc.var1 = "One"
    bc.var2 = "Two"
    
    bc.var1 eql "One"
    bc.var2 eql "Two"
  end
  
  it "should save itself to file" do
    bc = IosBox::BuildCache.new
    bc.project_dir = File.dirname(__FILE__)
    
    bc.save
  end
end
