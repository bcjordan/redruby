require 'open-uri'
require 'json'

module RedRuby
    
    class Parser
        attr_accessor :json_string, :json_hash, :submissions, :comments
        
        # Init method takes a reddit URL and loads its json page
        def initialize(url)
            # TODO: Handle case where url does not include .json and
            #       has ?key=value&k2=v2 options in it
            
            # 1. Construct URL
            if url.include? ".json"
                # nothing
            else
                url = ("#{url}.json")
            end
            
            # 2. Load in remote/local page, parse to hash
            contents = open(url) { |f| f.read }
            @json_string = contents
            @json_hash = JSON.parse(@json_string)
            

            @json_hash = @json_hash[0] if @json_hash.class == Array
        end
        
        def parse_submissions(hash = @json_hash)
            @submissions = [] # empty array for storing links
            
            # Process each link submission
            hash["data"]["children"].each do |item|
                if item["kind"] == "t3" # is a submission
                    @submissions << parse_submission(item["data"])
                end
            end
        end
        
        # Uses @json_hash to parse comments
        def parse_comments(hash = @json_hash)
            @comments = [] # empty array for top level of comments
            
            # Process comments w/ recursive helper (for Listing/submission pages)
            @comments = parse_comments_helper(hash)
            #pp hash
        end
        
        # Recursive helper for parsing comments
        def parse_comments_helper(hash)
            comments_array = []
            pp hash
            #pp "Hash kind is #{hash["kind"]}" 
            
            hash.each do |item|
                if item["kind"] == "t1"
                    comments_array += parse_comment item["data"]
                elsif item["kind"] == "t3" || item["kind"] == "Listing"
                    comments_array += parse_comments_helper item["data"]["children"]
                end
            end
=begin            # TODO: each in this "hash" (if it's an array)
            if hash["kind"] == "t1"
                comments_array << parse_comment(hash["data"])
            elsif hash["kind"] == "t3" || hash["kind"] == "Listing"
                if hash["data"]["children"]
                    puts "Size is #{hash["data"]["children"].size}"
                    hash["data"]["children"].each do |item|
                        puts "item!"
                        comments_array << parse_comments_helper(item)
                    end
                end
            end
=end
            return comments_array
        end
        
        private
        
        # Takes a JSON-generated submission data hash and outputs Submission
        # object
        def parse_submission(hash)
            return Submission.new(hash)
        end
        
        # Takes a JSON-generated comment data hash and returns Comment object
        def parse_comment(hash)
            return Comment.new(hash)
        end
    end
    
    class Submission
        REDDIT_URL_PREFIX = "http://reddit.com"
        
        attr_accessor  :json_hash, :score, :name, :permalink, :over_18,
            :is_self, :ups, :num_comments, :hidden, :likes, :subreddit,
            :title, :author, :thumbnail, :created_utc, :url, :domain, :id,
            :selftext, :media, :clicked, :subreddit_id, :selftext_html, 
            :levenshtein, :media_embed, :score, :saved, :created, :downs
        
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
        
        def json_link
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
            @thumbnail = submission_json["thumbnail"] # TODO: what format is this?
            @created_utc = submission_json["created_utc"]
            @url = submission_json["url"]
            @domain = submission_json["domain"]
            @id = submission_json["id"]
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
                        :ups
                        # TODO: :before and :after?
        
        def initialize(comment_hash = {})
            load_json(comment_hash)
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
        
        def json_link
            "#{REDDIT_URL_PREFIX}#{permalink}#{id}.json"
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
            @id = comment_json["id"]
            @subreddit = comment_json["subreddit"]
            @replies_json = comment_json["replies"]
            
            load_replies
        end
        
        # Recursive helper for parsing comments
        def parse_comments_helper(hash)
            comments_array = []
            
            if hash["kind"].to_s.eql? "t1"
                comments_array << parse_comment(hash["data"])
            elsif hash["kind"] == "t3"
                comments_array << parse_comments_helper(hash["data"])
            elsif hash["kind"] == "Listing"
                hash["data"]["children"].each do |item|
                    comments_array << parse_comments_helper(item)
                end
            end
            
            return comments_array
        end
    end
    
    class User
        attr_accessor :test
    end
end        
=begin
    class RedRuby
        def self.portray(food)
            if food.downcase == "broccoli"
                "Gross!"
            else
                "Delicious!"
            end
        end
=end

