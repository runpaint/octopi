module Octopi
  class Repository < Base
    include Resource
    set_resource_name "repository", "repositories"

    find_path "/repos/search/:query"
    resource_path "/repos/show/:id"
    
    def branches
      Branch.find(self.owner, self.name)
    end  

    def tags
      Tag.find(self.owner, self.name)
    end  
    
    def clone_url
      #FIXME: Return "git@github.com:#{self.owner}/#{self.name}.git" if
      #user's logged in and owns this repo.
      "git://github.com/#{self.owner}/#{self.name}.git"  
    end

    def self.find_by_user(user)
      user = user.login if user.is_a? User
      self.validate_args(user => :user)
      find_plural(user, :resource)
    end

    def self.find(*args)
      api = args.last.is_a?(Api) ? args.pop : ANONYMOUS_API
      repo = args.pop
      user = args.pop
      
      user = user.login if user.is_a? User
      if repo.is_a? Repository
        repo = repo.name 
        user ||= repo.owner 
      end
      
      self.validate_args(user => :user, repo => :repo)
      super user, repo, api
    end

    def self.find_all(*args)
      # FIXME: This should be URI escaped, but have to check how the API
      # handles escaped characters first.
      super args.join(" ").gsub(/ /,'+')
    end
    
    def self.open_issue(args)
      Issue.open(args[:user], args[:repo], args)
    end
    
    def open_issue(args)
      Issue.open(self.owner, self, args, @api)
    end
    
    def commits(branch = "master")
      Commit.find_all(self, :branch => branch)
    end
    
    def issues(state = "open")
      Issue.find_all(self, :state => state)
    end
   
    def all_issues
      Issue::STATES.map{|state| self.issues(state)}.flatten
    end

    def issue(number)
      Issue.find(self, number)
    end

    def collaborators
      property('collaborators', [self.owner,self.name].join('/')).values
    end  

  end
end
