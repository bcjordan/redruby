require File.dirname(__FILE__) + '/test_helper.rb'

class RedRubyTest < Test::Unit::TestCase

    REDDIT_URL = "http://reddit.com/"
    REDDIT_NEW_URL = "http://www.reddit.com/new/.json?sort=new"
    SUBMISSIONS_PATH = "test_submissions.json"
    SUBMISSION_PATH = "test_submission.json" 
    COMMENTS_PATH = "test_comments.json"
    COMMENT_PATH = "test_comment.json"
    USER_PATH = "test_user.json"
    USER_NAME = "ProbablyHittingOnYou"

    # Helper methods
    
    # Loads a JSON file from a local or remote location
    def load_json(location, pause=false)
        contents = open(location) { |f| f.read }
        @json_string = contents
        sleep 2 if pause # Reddit API admins like this pace
        return JSON.parse(@json_string)
    end
    
    # Unit tests
    context "a redruby submission" do
        setup do
            @submission = RedRuby::Submission.new(load_json(SUBMISSION_PATH))
        end

        should "create a submission object" do
            assert @submission
        end

        should "store information on submission" do
            assert_equal "self.AskReddit", @submission.domain
            assert_equal "AskReddit", @submission.subreddit
            assert_equal nil, @submission.selftext_html
            assert_equal "", @submission.selftext
            assert_equal nil, @submission.likes
            assert_equal false, @submission.saved
            assert_equal "ecldw", @submission.self_id
            assert_equal false, @submission.clicked
            assert_equal "Pizzaman99", @submission.author
            assert_equal nil, @submission.media
            assert_equal 2, @submission.score
            assert_equal false, @submission.over_18
            assert_equal false, @submission.hidden
            assert_equal "", @submission.thumbnail
            assert_equal "t5_2qh1i", @submission.subreddit_id
            assert_equal 0, @submission.downs
            assert_equal 2, @submission.ups
            assert_equal true, @submission.is_self
            assert_equal "/r/AskReddit/comments/ecldw/does_anyone_else_constantly_click_report_instead/", @submission.permalink
            assert_equal "t3_ecldw", @submission.name
            assert_equal 1290917314.0, @submission.created
            assert_equal 1290892114.0, @submission.created_utc
            assert_equal "http://www.reddit.com/comments/ecldw/does_anyone_else_constantly_click_report_instead/", @submission.url
            assert_equal "Does anyone else constantly click \"report\" instead of \"reply\" by mistake?", @submission.title
            assert_equal 0, @submission.num_comments
        end
    end

    context "a redruby username" do
        setup do
            @user = RedRuby::User.new(USER_NAME)
        end

        should "create a user" do
            assert @user
        end

        should "have some user data" do
            assert_equal "ProbablyHittingOnYou", @user.name
        end
    end

    context "a redruby user" do
        setup do
            @user = RedRuby::User.new(load_json(USER_PATH))
        end
        
        should "create a user" do
            assert @user
        end
        
        should "store information on user" do
            assert_equal "ProbablyHittingOnYou", @user.name
            assert_equal 1282848421.0, @user.created
            assert_equal 1282848421.0, @user.created_utc
            assert_equal 961, @user.link_karma
            assert_equal 103559, @user.comment_karma
            assert_equal false, @user.is_mod
            assert_equal "4a5h0", @user.self_id # JSON just "id", ruby reserved
            # assert_equal nil, user.has_mod_mail # Anyone want this data?
        end
    end
    
    context "a redruby comment" do
        setup do
            @comment = RedRuby::Comment.new(load_json(COMMENT_PATH))
        end
        
        should "create a comment" do
            assert @comment
        end
        
        should "store attributes of comment" do
            assert_equal "t1_c172ye1", @comment.name
            assert @comment.body_html
            assert_equal 1, @comment.ups
            assert_equal 0, @comment.downs
            assert_equal "t3_ecm0n", @comment.link_id
            assert_equal "perceived_pattern", @comment.author
            assert_equal "I am a top level comment.", @comment.body
            assert_equal 1290895511.0, @comment.created_utc
            assert_equal 1290895511.0, @comment.created
            assert_equal "c172ye1", @comment.self_id
            assert_equal "t3_ecm0n", @comment.parent_id
            # assert "levenshtein" == nil
            assert_equal "t5_2qpol", @comment.subreddit_id
            assert_equal "circlejerk", @comment.subreddit
            assert @comment.likes.nil?
        end
        
        should "have alias accessor methods for up and downvotes" do
            assert_equal 1, @comment.upvotes
            assert_equal 0, @comment.downvotes
        end
        
        should "have pretty date method" do
            assert_equal "Sat Nov 27 17:05:11 -0500 2010", @comment.date().to_s
        end
        
        should "store replies and their attributes" do
            assert @comment.replies
            reply = @comment.replies[0]
            assert reply
            
            assert_equal "t1_c172yew", reply.name
            assert_equal 0, reply.replies.size
        end
    end
    
    context "a redruby parser" do
        setup do
            @parser = RedRuby::Parser.new(SUBMISSIONS_PATH)
            @remote_parser = RedRuby::Parser.new(REDDIT_URL)
            
            @comments_parser = RedRuby::Parser.new(COMMENTS_PATH)
        end
        
        should "download valid json, be accessible" do
            assert @parser.json_string
            assert @remote_parser.json_string
            
            # should be parsable json
            assert JSON.parse(@parser.json_string)
            
            # should save parsed json hash
            assert @parser.json_hash
            assert @remote_parser.json_hash
            assert_equal 25, @parser.json_hash["data"]["children"].size
            assert @remote_parser.json_hash["data"]["children"].size > 0
            assert @comments_parser.json_hash["data"]["children"].size > 0
        end
        
        context "parsing submissions (links)" do
            setup do
                @parser.parse_submissions
            end
                
            should "parse correctly" do
                num_links = @parser.json_hash["data"]["children"].size
                
                submissions = @parser.submissions
                assert_equal num_links, submissions.size
                
                assert_equal "t3_ecldw", submissions[0].json_hash["name"]
                assert_equal "t3_ecldw", submissions[0].name
                
                assert_equal "Sat Nov 27 16:08:34 -0500 2010", submissions[0].date().to_s
                
                assert_equal "http://reddit.com/r/AskReddit/comments/ecldw/does_anyone_else_constantly_click_report_instead/.json",
                             submissions[0].json_url
                
                # TODO: test points, ups, downs, links, and other submission attrs
            end
        end
        
        context "parsing comments" do
            setup do
                @comments_parser.parse_comments
                @comments = @comments_parser.comments
            end
            
            should "store each comment and its data" do
                assert @comments
            end
            
            should "store the parent submission of a comment" do
                assert_equal "perceived_pattern", @comments[0].submission.author
            end
        end
    end
end
