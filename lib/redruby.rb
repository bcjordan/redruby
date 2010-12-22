require 'open-uri'
require 'json'

module RedRuby
    
    class Parser
        attr_accessor :json_string, :json_hash, :submissions, :comments,
                      :json_submission_hash, :parent_submission
        
        # Init method takes a reddit URL and loads its json page
        def initialize(url)
            # TODO: Handle case where url does not include .json and
            #       has ?key=value&k2=v2 options in it
            
            # 1. Construct JSON API URL
            url = ("#{url}.json") unless url.include? ".json"
            
            # 2. Load in remote/local page, parse to hash
            @json_hash = load_json(url)
            
            if submission_comments_page? # order of next two lines matters
                @json_submission_hash = @json_hash[0]["data"]["children"][0]["data"]
                @json_hash = @json_hash[1]
                parse_submissions
                @parent_submission = @submissions[0]
            end
        end
        
        # Loads a JSON file from a local or remote location
        def load_json(location)
            # http://www.eggheadcafe.com/software/aspnet/35791813/ruby-idiom-to-retry-open-upto-n-times-before-giving-up.aspx
            contents = open(location) { |f| f.read }
            @json_string = contents
            return JSON.parse(@json_string)
        end
        
        def parse_submissions(hash = @json_hash)
            @submissions = [] # empty array for storing links
            
            if submission_comments_page?
                # Store single submission
                @submissions << parse_submission(@json_submission_hash)
            else
                # Process each submission in listing
                hash["data"]["children"].each do |item|
                    if item["kind"] == "t3" # is a submission
                        @submissions << parse_submission(item["data"])
                    end
                end
            end
        end
        
        # Uses @json_hash to parse comments
        def parse_comments(hash = @json_hash)
            @comments = [] # empty array for top level of comments
            
            # Process comments
            hash["data"]["children"].each do |item|
                if item["kind"] == "t1" # is a comment
                    @comments << parse_comment(item["data"])
                end
            end
        end
        
        private
        
        # Takes a JSON-generated submission data hash and outputs Submission
        # object
        def parse_submission(hash)
            return Submission.new(hash)
        end
        
        # Takes a JSON-generated comment data hash and returns Comment object
        def parse_comment(hash)
            if submission_comments_page? && @parent_submission
                return Comment.new(hash, @parent_submission)
            else
                return Comment.new(hash)
            end
        end
        
        # Determines whether we are parsing a submission's comments page
        def submission_comments_page?
            @json_hash.class == Array || @json_submission_hash
        end
    end
    
    class Submission
        REDDIT_URL_PREFIX = "http://reddit.com"
        
        attr_accessor  :json_hash, :score, :name, :permalink, :over_18,
            :is_self, :ups, :num_comments, :hidden, :likes, :subreddit,
            :title, :author, :thumbnail, :created_utc, :url, :domain, :self_id,
            :selftext, :media, :clicked, :subreddit_id, :selftext_html, 
            :levenshtein, :media_embed, :score, :saved, :created, :downs,
            :thumbnail_url
        
        def initialize(submission_hash = {})
            # populates all instance variables,
            # stores submission_hash in @raw_json 
            load_json(submission_hash)
        end
        
        # Alias upvotes and downvotes
        def upvotes
            @ups
        end
        
        def downvotes
            @downs
        end
        
        # Returns printable datetime (UTC)
        def date
            Time.at(self.created_utc)
        end
        
        # Returns remote link to submission's json
        def json_url
            "#{REDDIT_URL_PREFIX}#{permalink}.json"
        end
        
        # Updates class member variables from json_hash
        def load_json(submission_json = @json_hash)
            @json_hash = submission_json
            @score = submission_json["score"]
            @name = submission_json["name"]
            @permalink = submission_json["permalink"]
            @over_18 = submission_json["over_18"]
            @is_self = submission_json["is_self"]
            @ups = submission_json["ups"]
            @num_comments = submission_json["num_comments"]
            @title = submission_json["title"]
            @author = submission_json["author"]
            @thumbnail = submission_json["thumbnail"] 
            #@thumbnail_url = submission_json["thumbnail_url"] if submission_json["thumbnail_url"] # 
            @created_utc = submission_json["created_utc"]
            @url = submission_json["url"]
            @domain = submission_json["domain"]
            @self_id = submission_json["id"]
            @selftext = submission_json["selftext"]
            @media = submission_json["media"] # TODO: what format is this?
            @clicked = submission_json["clicked"]
            @subreddit_id = submission_json["subreddit_id"]
            @selftext_html = submission_json["selftext_html"]
            @levenshtein = submission_json["levenshtein"] # TODO: what is this?
            @media_embed = submission_json["media_embed"] # TODO: what is this? hash format
            @score = submission_json["score"]
            @saved = submission_json["saved"]
            @created = submission_json["created"]
            @downs = submission_json["downs"]
            @hidden = submission_json["hidden"]
            @likes = submission_json["likes"]
            @subreddit = submission_json["subreddit"]
        end
    end
    
    class Comment
        REDDIT_URL_PREFIX = "http://reddit.com"
        
        attr_accessor   :body, :subreddit_id, :name, :author, :downs, :created,
                        :created_utc, :body_html, :levenshtein, :link_id, 
                        :parent_id, :likes, :replies, :num_replies, :json_hash,
                        :ups, :replies_json, :self_id, :subreddit, :submission
                        # TODO: :before and :after?
        
        def initialize(comment_hash = {}, parent_submission = nil)
            load_json(comment_hash)
            @submission = parent_submission if parent_submission
        end
        
        # Alias upvotes and downvotes
        def upvotes
            @ups
        end
        
        def downvotes
            @downs
        end
        
        # Returns printable datetime (UTC)
        def date
            Time.at(self.created_utc)
        end
        
        # Returns remote link to comment's json
        def json_url
        #    "#{REDDIT_URL_PREFIX}#{permalink}#{@self_id}.json"
        end
        
        # Updates class member variables from json_hash
        def load_json(comment_json = @json_hash)
            @json_hash = comment_json
            @body = comment_json["body"]
            @subreddit_id = comment_json["subreddit_id"]
            @name = comment_json["name"]
            @author = comment_json["author"]
            @downs = comment_json["downs"]
            @created = comment_json["created"]
            @created_utc = comment_json["created_utc"]
            @body_html = comment_json["body_html"]
            @levenshtein = comment_json["levenshtein"]
            @link_id = comment_json["link_id"]
            @parent_id = comment_json["parent_id"]
            @likes = comment_json["likes"]
            @ups = comment_json["ups"]
            @self_id = comment_json["id"]
            @subreddit = comment_json["subreddit"]
            @replies_json = comment_json["replies"]
            
            load_replies
        end
        
        # Recursive helper for parsing reply comments
        def load_replies
            @replies = []
            
            if @replies_json != ""
                # if we have some replies, create them
                @replies_json["data"]["children"].each do |comment|
                    if @submission
                        @replies << Comment.new(comment["data"], @submission)
                    else
                        @replies << Comment.new(comment["data"])
                    end
                end
            end
        end
    end
    
    class User
        attr_accessor   :name, :created, :created_utc, :link_karma, :json_hash,
                        :comment_karma, :is_mod, :self_id
        
        def initialize(user_hash = {})
            load_json(user_hash)
        end
        
        def load_json(user_json = @json_hash)
            @json_hash = user_json # Update JSON hash
            
            @name = user_json["name"]
            @created = user_json["created"]
            @created_utc = user_json["created_utc"]
            @link_karma = user_json["link_karma"]
            @comment_karma = user_json["comment_karma"]
            @is_mod = user_json["is_mod"]
            @self_id = user_json["id"]
        end
        
        # Returns printable datetime (UTC)
        def date
            Time.at(self.created_utc)
        end
    end
end

