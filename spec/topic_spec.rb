require 'kubeflow'
describe MultiCli::Topic do
  it "Add topic in class variable" do
    a = MultiCli::Topic.new(name: 'topic1', description: "description1", hidden: true)
    expect(MultiCli::Topic.topics[
  end
end
