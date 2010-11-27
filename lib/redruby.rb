require 'open-uri'
require 'json'

module RedRuby
    
    class Parser
        attr_accessor :json_string, :json_hash, :submissions
        
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
        end
        
        def parse_submissions
            @submissions = [] # empty array for storing links
            
            # Process each link submission / comment
            @json_hash["data"]["children"].each do |item|
                if item["kind"] == "t3" # is a submission
                    @submissions << parse_submission(item["data"])
                end
            end
        end
        
        private
        
        # Takes a JSON-generated hash and outputs 
        def parse_submission(hash)
            return Submission.new(hash)
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
            self.ups
        end
        
        def downvotes
            self.downs
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
        attr_accessor   :body, :body_html, :ups, :downs, :score, :replies, :author
                        :num_replies
                        
    end
    
    class User
        attr_accessor 
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

