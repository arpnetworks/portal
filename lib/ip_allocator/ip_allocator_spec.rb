require File.dirname(__FILE__) + '/ip_allocator'

describe IPAllocator do
  before do
    @supernet  = NetAddr::CIDR.create('208.79.88.0/21')

    @allocated = [NetAddr::CIDR.create('208.79.89.0/25'), 
                  NetAddr::CIDR.create('208.79.91.0/24')]

    @allocator = IPAllocator.new(@supernet, @allocated)
  end

  describe "Allocations" do
    it "should find 208.79.92.0/23 as first unused /23 block" do
      expect(@allocator.first_unused(23)).to eq('208.79.92.0/23')
    end

    it "should find 208.79.88.0/24 as first unused /24 block" do
      expect(@allocator.first_unused(24)).to eq('208.79.88.0/24')
    end
  end

  describe "Edge Cases" do
    it "should not find a block larger than the supernet" do
      # /20 is larger than supernet of /21
      expect(@allocator.first_unused(20)).to be_nil
    end
  end

  describe "Methods" do
    describe "available()" do
      it "should return available /23's" do
        expect(@allocator.available(23)).to eq(['208.79.92.0/23',
                                                '208.79.94.0/23'])
      end

      it "should return available /24's" do
        expect(@allocator.available(24)).to eq(['208.79.88.0/24',
                                                '208.79.90.0/24',
                                                '208.79.92.0/24',
                                                '208.79.94.0/24',
                                                '208.79.93.0/24',
                                                '208.79.95.0/24'])
      end

      it "should return available /22's" do
        expect(@allocator.available(22)).to eq(['208.79.92.0/22'])
      end

      it "should return empty set for requested block size larger than supernet" do
        expect(@allocator.available(20)).to eq([])
      end
    end
  
    describe "first_unused()" do
      describe "with generic use cases" do
        it "should not return a /30 contained within any other allocated block" do
          @supernet  = NetAddr::CIDR.create('208.79.89.128/25')
          @allocated = [NetAddr::CIDR.create('208.79.89.0/27'), 
                        NetAddr::CIDR.create('208.79.89.32/28'), 
                        NetAddr::CIDR.create('208.79.89.64/26'), 
                        NetAddr::CIDR.create('208.79.89.128/28'), 
                        NetAddr::CIDR.create('208.79.89.144/29')]

          @allocator = IPAllocator.new(@supernet, @allocated)

          @first_unused = @allocator.first_unused(30).to_s

          expect(@first_unused).not_to eq('208.79.89.0/30')
          expect(@first_unused).not_to eq('208.79.89.4/30')
          expect(@first_unused).not_to eq('208.79.89.8/30')
          expect(@first_unused).not_to eq('208.79.89.12/30')
          expect(@first_unused).not_to eq('208.79.89.16/30')
          expect(@first_unused).not_to eq('208.79.89.20/30')
          expect(@first_unused).not_to eq('208.79.89.24/30')
          expect(@first_unused).not_to eq('208.79.89.28/30')
          expect(@first_unused).not_to eq('208.79.89.32/30')
          expect(@first_unused).not_to eq('208.79.89.36/30')
          expect(@first_unused).not_to eq('208.79.89.40/30')
          expect(@first_unused).not_to eq('208.79.89.44/30')

          expect(@first_unused).not_to eq('208.79.89.64/30')
          expect(@first_unused).not_to eq('208.79.89.68/30')
          expect(@first_unused).not_to eq('208.79.89.72/30')
          expect(@first_unused).not_to eq('208.79.89.76/30')
          expect(@first_unused).not_to eq('208.79.89.80/30')
          expect(@first_unused).not_to eq('208.79.89.84/30')
          expect(@first_unused).not_to eq('208.79.89.88/30')
          expect(@first_unused).not_to eq('208.79.89.92/30')
          expect(@first_unused).not_to eq('208.79.89.96/30')
          expect(@first_unused).not_to eq('208.79.89.100/30')
          expect(@first_unused).not_to eq('208.79.89.104/30')
          expect(@first_unused).not_to eq('208.79.89.108/30')
          expect(@first_unused).not_to eq('208.79.89.112/30')
          expect(@first_unused).not_to eq('208.79.89.116/30')
          expect(@first_unused).not_to eq('208.79.89.120/30')
          expect(@first_unused).not_to eq('208.79.89.124/30')

          expect(@first_unused).not_to eq('208.79.89.128/30')
          expect(@first_unused).not_to eq('208.79.89.132/30')
          expect(@first_unused).not_to eq('208.79.89.136/30')
          expect(@first_unused).not_to eq('208.79.89.140/30')

          expect(@first_unused).not_to eq('208.79.89.144/30')
          expect(@first_unused).not_to eq('208.79.89.148/30')
        end
      end
    end
  end
end
