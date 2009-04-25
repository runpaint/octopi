module Octopi
  class User < Base
    include Resource
    
    find_path "/user/search/:query"
    resource_path "/user/show/:id"
    
    @@traversed = {}
    @@yielded = {}

    def self.find(username)
      self.validate_args(username => :user)
      super username
    end

    def self.followers(username)
      self.validate_args(username => :user)
      self.property('followers', username).map{|u| LazyUser.new u}
    end

    def self.following(username)
      self.validate_args(username => :user)
      self.property('following', username).map{|u| LazyUser.new u}
    end
    
    def self.traverse(username, &block)
      username = String === username ? LazyUser.new(username) : username
      queue = [username]
      loop do
        user = queue.pop
        followers = self.followers user.login
        @@traversed[user.login] = true
        followers.each do |follower|
          block.call(follower) unless @@yielded[follower.login]
          @@yielded[follower.login] = true
        end
        queue.concat followers
        queue.delete_if {|e| @@traversed[e.login]}
        queue.uniq!  
        break if queue.empty?
      end  
    end
      
    def self.find_all(username)
      self.validate_args(username => :user)
      super username
    end

    def repositories
      Repository.find_by_user(login)
    end
    
    def repository(name)
      self.class.validate_args(name => :repo)
      Repository.find(login, name)
    end

  end
end
