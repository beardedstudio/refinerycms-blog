require 'spec_helper'
Dir[File.expand_path('../../../features/support/factories/*.rb', __FILE__)].each{|factory| require factory}

describe BlogPost do
  let(:blog_post ) { Factory :post }
  
  describe "validations" do
    it "requires title" do
      Factory.build(:post, :title => "").should_not be_valid
    end

    it "won't allow duplicate titles" do
      Factory.build(:post, :title => blog_post.title).should_not be_valid
    end

    it "requires body" do
      Factory.build(:post, :body => nil).should_not be_valid
    end
  end

  describe "comments association" do

    it "have a comments attribute" do
      blog_post.should respond_to(:comments)
    end

    it "destroys associated comments" do
      Factory(:blog_comment, :blog_post_id => blog_post.id)
      blog_post.destroy
      BlogComment.find_by_blog_post_id(blog_post.id).should == nil
    end
  end

  describe "categories association" do
    it "have categories attribute" do
      blog_post.should respond_to(:categories)
    end
  end
  
  describe "tags" do
    it "acts as taggable" do
      blog_post.should respond_to(:tag_list)
      
      #the factory has default tags, including 'chicago'
      blog_post.tag_list.should include("chicago")
    end
  end
  
  describe "authors" do
    it "are authored" do
      BlogPost.instance_methods.map(&:to_sym).should include(:author)
    end
  end

  describe "by_archive scope" do
    before do
      @blog_post1 = Factory(:post, :published_at => Date.new(2011, 3, 11))
      @blog_post2 = Factory(:post, :published_at => Date.new(2011, 3, 12))
      
      #2 months before
      Factory(:post, :published_at => Date.new(2011, 1, 10))
    end

    it "returns all posts from specified month" do
      #check for this month
      date = "03/2011"
      BlogPost.by_archive(Time.parse(date)).count.should == 2
      BlogPost.by_archive(Time.parse(date)).should == [@blog_post2, @blog_post1]
    end
  end

  describe "all_previous scope" do
    before do
      @blog_post1 = Factory(:post, :published_at => Time.now - 2.months)
      @blog_post2 = Factory(:post, :published_at => Time.now - 1.month)
      Factory :post, :published_at => Time.now
    end

    it "returns all posts from previous months" do
      BlogPost.all_previous.count.should == 2
      BlogPost.all_previous.should == [@blog_post2, @blog_post1]
    end
  end

  describe "live scope" do
    before do
      @blog_post1 = Factory(:post, :published_at => Time.now.advance(:minutes => -2))
      @blog_post2 = Factory(:post, :published_at => Time.now.advance(:minutes => -1))
      Factory(:post, :draft => true)
      Factory(:post, :published_at => Time.now + 1.minute)
    end

    it "returns all posts which aren't in draft and pub date isn't in future" do
      BlogPost.live.count.should == 2
      BlogPost.live.should == [@blog_post2, @blog_post1]
    end
  end

  describe "uncategorized scope" do
    before do
      @uncategorized_blog_post = Factory(:post)
      @categorized_blog_post = Factory(:post)

      @categorized_blog_post.categories << Factory(:blog_category)
    end

    it "returns uncategorized posts if they exist" do
      BlogPost.uncategorized.should include @uncategorized_blog_post
      BlogPost.uncategorized.should_not include @categorized_blog_post
    end
  end

  describe "#live?" do
    it "returns true if post is not in draft and it's published" do
      Factory(:post).live?.should be_true
    end

    it "returns false if post is in draft" do
      Factory(:post, :draft => true).live?.should be_false
    end

    it "returns false if post pub date is in future" do
      Factory(:post, :published_at => Time.now.advance(:minutes => 1)).live?.should be_false
    end
  end

  describe "#next" do
    before do
      Factory(:post, :published_at => Time.now.advance(:minutes => -1))
      @blog_post = Factory(:post)
    end

    it "returns next article when called on current article" do
      BlogPost.last.next.should == @blog_post
    end
  end

  describe "#prev" do
    before do
      Factory(:post)
      @blog_post = Factory(:post, :published_at => Time.now.advance(:minutes => -1))
    end

    it "returns previous article when called on current article" do
      BlogPost.first.prev.should == @blog_post
    end
  end

  describe "#category_ids=" do
    before do
      @cat1 = Factory(:blog_category, :id => 1)
      @cat2 = Factory(:blog_category, :id => 2)
      @cat3 = Factory(:blog_category, :id => 3)
      blog_post.category_ids = [1,2,"","",3]
    end

    it "rejects blank category ids" do
      blog_post.categories.count.should == 3
    end

    it "returns array of categories based on given ids" do
      blog_post.categories.should == [@cat1, @cat2, @cat3]
    end
  end

  describe ".comments_allowed?" do
    context "with RefinerySetting comments_allowed set to true" do
      before do
        RefinerySetting.set(:comments_allowed, { :scoping => 'blog', :value => true })
      end
      
      it "should be true" do
        BlogPost.comments_allowed?.should be_true
      end
    end

    context "with RefinerySetting comments_allowed set to true" do
      before do
        RefinerySetting.set(:comments_allowed, { :scoping => 'blog', :value => false })
      end
      
      it "should be false" do
        BlogPost.comments_allowed?.should be_false
      end
    end
  end
end
