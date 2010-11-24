module RedRuby
    class Submission
        attr_accessor   :subreddit, :score, :url, :domain,
                        :author, :is_self, :downs, :ups, :score,
                        :created_utc, :num_comments
        
        def initialize()
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

