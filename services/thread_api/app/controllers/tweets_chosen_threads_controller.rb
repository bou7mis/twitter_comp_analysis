class TweetsChosenThreadsController < ApplicationController
  # GET /tweets_chosen_threads
  # GET /tweets_chosen_threads.xml
  def index
    @tweets_chosen_threads = TweetsChosenThread.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @tweets_chosen_threads }
    end
  end

  # GET /tweets_chosen_threads/1
  # GET /tweets_chosen_threads/1.xml
  def show
    @tweets_chosen_thread = TweetsChosenThread.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @tweets_chosen_thread }
    end
  end

  # GET /tweets_chosen_threads/new
  # GET /tweets_chosen_threads/new.xml
  def new
    @tweets_chosen_thread = TweetsChosenThread.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @tweets_chosen_thread }
    end
  end

  # GET /tweets_chosen_threads/1/edit
  def edit
    @tweets_chosen_thread = TweetsChosenThread.find(params[:id])
  end

  # POST /tweets_chosen_threads
  # POST /tweets_chosen_threads.xml
  def create
    @tweets_chosen_thread = TweetsChosenThread.new(params[:tweets_chosen_thread])

    respond_to do |format|
      if @tweets_chosen_thread.save
        format.html { redirect_to(@tweets_chosen_thread, :notice => 'TweetsChosenThread was successfully created.') }
        format.xml  { render :xml => @tweets_chosen_thread, :status => :created, :location => @tweets_chosen_thread }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @tweets_chosen_thread.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /tweets_chosen_threads/1
  # PUT /tweets_chosen_threads/1.xml
  def update
    @tweets_chosen_thread = TweetsChosenThread.find(params[:id])

    respond_to do |format|
      if @tweets_chosen_thread.update_attributes(params[:tweets_chosen_thread])
        format.html { redirect_to(@tweets_chosen_thread, :notice => 'TweetsChosenThread was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @tweets_chosen_thread.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /tweets_chosen_threads/1
  # DELETE /tweets_chosen_threads/1.xml
  def destroy
    @tweets_chosen_thread = TweetsChosenThread.find(params[:id])
    @tweets_chosen_thread.destroy

    respond_to do |format|
      format.html { redirect_to(tweets_chosen_threads_url) }
      format.xml  { head :ok }
    end
  end
  
  def thread_response
    # result = Rails.cache.fetch("threads_tree_#{params[:id]}"){
    #   root = TweetsChosenThread.find(:first, :conditions => {:thread_id => params[:id]}, :order => "pubdate asc")
    #   tweet = Tweet.find_by_twitter_id(root.twitter_id)
    #   if tweet.in_reply_to_status_id && tweet.in_reply_to_status_id != 0
    #     root = TweetsChosenThread.tweet_data(tweet.in_reply_to_status_id)
    #     in_reply_to_status_id = root.class==Array ? root.first["in_reply_to_status_id"] : root.in_reply_to_status_id
    #     while in_reply_to_status_id && in_reply_to_status_id != 0 
    #       root = TweetsChosenThread.tweet_data(tweet.in_reply_to_status_id)
    #       in_reply_to_status_id = root.class==Array ? root.first["in_reply_to_status_id"] : root.in_reply_to_status_id        
    #     end
    #   end
    #   TweetsChosenThread.return_child_js(root, nil, params[:id])      
    # }
    result = thread_json
    render :json => result
  end
  
  def graph
    @json = thread_json
    respond_to do |format|
      format.html
    end
  end
  
  def actor_breakdown
    puts thread_hash.inspect
    thread = thread_hash
    result = {}
    actor_type_index = actor_index
    result[:originator] = {:screen_name => thread["name"], :actor_type => actor_type_index[thread["name"]]}
    users = all_children(thread)
    users.delete(thread["name"])
    actor_type_breakdown = {}
    for user in users
      actor_type = actor_type_index[user]
      if actor_type_breakdown.has_key?(actor_type)
        actor_type_breakdown[actor_type][:count] += 1
      else
        actor_type_breakdown[actor_type] = {:count => 1}
      end
    end
    total = (users.length - 1).to_f
    actor_type_breakdown.each {|k,v| actor_type_breakdown[k][:percent] = (v[:count] / total)}
    result[:actor_types] = actor_type_breakdown
    render :json => result.to_json
  end

  def actor_index
    r = ActiveRecord::Base.connection.execute("select p_screen_name, p_type from profiles").all_hashes
    index = {}
    r.each {|h| index[h["p_screen_name"]] = h["p_type"].to_i }
    return index
  end
  
  def all_children(hash)
    children = []
    children << hash["name"]
    hash["children"].each {|h| children += all_children(h) }
    return children.uniq
  end
  
  def thread_hash
    result = Rails.cache.fetch("threads_tree_#{params[:id]}"){
      root = TweetsChosenThread.find(:first, :conditions => {:thread_id => params[:id]}, :order => "pubdate asc")
      tweet = Tweet.find_by_twitter_id(root.twitter_id)
      if tweet.in_reply_to_status_id && tweet.in_reply_to_status_id != 0
        root = TweetsChosenThread.tweet_data(tweet.in_reply_to_status_id)
        in_reply_to_status_id = root.class==Array ? root.first["in_reply_to_status_id"] : root.in_reply_to_status_id
        while in_reply_to_status_id && in_reply_to_status_id != 0 
          root = TweetsChosenThread.tweet_data(tweet.in_reply_to_status_id)
          in_reply_to_status_id = root.class==Array ? root.first["in_reply_to_status_id"] : root.in_reply_to_status_id        
        end
      end
      TweetsChosenThread.return_child_js(root, params[:id])
    }
    return result
  end
  
  def thread_json
    return thread_hash.to_json
  end
  
end
