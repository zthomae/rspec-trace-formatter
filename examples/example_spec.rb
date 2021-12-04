RSpec.describe "examples" do
  describe String do
    it "allows concatenation" do
      expect("foo" + "bar").to eq("foobar")
    end

    it "fails with bad concatenation" do
      expect("foo" + "bar").to eq("foo_bar")
    end
  end

  describe Kernel do
    it "sleeps" do
      sleep 3
    end
  end

  it "has an undefined example"

  xit "has an example skipped with xit"

  it "has an explicitly skipped example" do
    skip("Not running this test")
  end

  it "has a pending example that fails" do
    pending("This feature is not yet implemented")
    expect(GreatClass.start).to eq([])
  end

  it "has a pending example that passes" do
    pending("This feature is not yet implemented")
    expect(1 + 2).to eq(3)
  end
end
