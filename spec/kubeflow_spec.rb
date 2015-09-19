require 'kubeflow'
describe Kubeflow::VERSION do
  it "should be equal 0.0.1" do
    expect(Kubeflow::VERSION).to eql("0.0.1")
  end
end
