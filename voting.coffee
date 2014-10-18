class CommonVoting
  @all: allVotings = []
  # helpers
  log: log ? (obj) ->
    console?.log obj
    obj
  logmr: logmr ? (msg, obj) ->
    @log msg
    @log obj
  logvmr: (method, msg, obj) -> @logmr "Voting #{@name}.#{method}: #{msg}", obj
  logvr: (method, obj) -> @logmr "Voting #{@name}.#{method}", obj
  logv: (method, msg) -> @log "Voting #{@name}.#{method}: #{msg}"
  createObject: createObject ? ->
    object = {}
    for o,i in arguments
      if i%2==1 and (key = arguments[i-1])? then object[key] = o
    object

  constructor: (@name, @targets, @source, @fields={}) ->
    @logv 'init', '...'
    check @name, String
    check @targets?.find, Match.OptionalOrNull Function
    check @source?.find, Match.OptionalOrNull Function
    @method = "#{@name}_vote"
    if _.isString up = @fields then @fields = up: up
    check @fields, Match.OptionalOrNull Object
    if _.isEmpty @fields
      @fields.up   = 'votesUp'
      @fields.down = 'votesDown'
    @protectFields()
    allVotings.push @
    @logv 'init', 'done'

  # Get targets/voted sorted by count
  _getListName: (source = true, up = true) ->
    @fields["#{if source then 'source' else 'target'}List#{if up then 'Up' else 'Down'}"]
  _listContains: (object, source = true, up = true) ->

  _topOptions: (limit = 10, up = true) ->
    sort: createObject (if up then @fields.up else @fields.down), -1
    limit: limit
  findTop: (limit = 10, up = true) -> @targets.find {}, @_topOptions limit, up
  getTop: (limit = 1, up = true) ->
    if limit is 1 then @targets.findOne {}, @_topOptions limit, up
    else (@findTop limit, up).fetch()
  voted: (source, target, up) ->
    unless up?
      (@voted source, target, true) or (@voted source, target, false)
    else if (_.isObject source) and (sourceListName = @_getListName true, up)?
      _.contains (u.getValue source, sourceListName), target?._id ? target
    else if (_.isObject target) and (targetListName = @_getListName false, up)?
      _.contains (u.getValue target, targetListName), source?._id ? source
  targetFields: -> [@fields.up, @fields.down, @fields.targetListUp, @fields.targetListDown]
  sourceFields: -> [@fields.sourceListUp, @fields.sourceListDown]
  protectFields: ->
    #deny = (collection, fieldsToCheck) =>
    #  if (fieldsToCheck = _.compact fieldsToCheck).length > 0
    #    @logvmr 'deny', "fieldsToCheck on #{collection._name}", fieldsToCheck
    #    collection?.deny
    #      update: (userId, doc, fields, modifier) =>
    #        @logvmr 'deny.update', "fields", fields
    #        @logvr 'deny.update', (_.intersection fields, fieldsToCheck).length > 0
    #      fetch: []
    #deny @targets, @targetFields()
    #deny @source,  @sourceFields()
    u.protectCollection @targets, @targetFields()
    u.protectCollection @source,  @sourceFields()

  initObject: (object, belongingToCollection, overwriteExisting) ->
    initFields = (fields, value) -> for field in fields
      if field? and (overwriteExisting or not (u.getValue object, field)?)
        u.setValue object, field, value
    if belongingToCollection is @targets
      initFields [@fields.up, @fields.down], 0
      initFields [@fields.targetListUp, @fields.targetListDown], []
    if belongingToCollection is @source
      initFields [@fields.sourceListUp, @fields.sourceListDown], []
  @initObject: (object, belongingToCollection, overwriteExisting) ->
    for voting in @all
      voting.initObject object, belongingToCollection, overwriteExisting
  clearObject: (object, belongingToCollection) ->
    clearFields = (fields) ->
      u.unsetValue object, field for field in _.compact fields
    clearFields @targetFields() if belongingToCollection is @targets
    clearFields @sourceFields() if belongingToCollection is @source
  @clearObject: (object, belongingToCollection, overwriteExisting) ->
    for voting in @all
      voting.clearObject object, belongingToCollection, overwriteExisting

# the server-side links to a collection to store the actual votes
class ServerVoting extends CommonVoting
  # name of collection; targets: collection that will be voted on; source: collection of voters (optional);
  # fields: names for the fields used in source and target - see docs above for details.
  constructor: (@name, @targets, @source, @fields={}) ->
    super @name, @targets, @source, @fields
    @c = new Meteor.Collection @name

  _updateLists: (voter, voted, up) ->
    check voter, String
    check voted, String
    if up? # put in
      @logmr "Voting #{@name}.ulists: up=#{up}; fields", @fields
      # TODO use @_getListName
      #if (list = if up then @fields.sourceListUp else @fields.sourceListDown)? and @source?
      if (list = @_getListName true, up)? and @source?
        @source.update { _id: voter }, logmr "Voting #{@name}.ulists: list=#{list}", { $addToSet: @createObject list, voted }
      #if (list = if up then @fields.targetListUp else @fields.targetListDown)? and @targets?
      if (list = @_getListName false, up)? and @targets?
        @logmr "Voting #{@name}.ulists: list=#{list}", { $addToSet: @createObject list, voter }
        @log @targets.update { _id: voted }, { $addToSet: @createObject list, voter }
    else # pull out
      if not _.isEmpty(set = @createObject(@fields.sourceListUp, voted, @fields.sourceListDown, voted))
        @source?.update { _id: voter }, { $pull: set }
      if not _.isEmpty(set = @createObject(@fields.targetListUp, voter, @fields.targetListDown, voter))
        @targets?.update { _id: voted }, { $pull: set }

  # short cuts
  up: (voter, voted, why=null) -> @vote voter, voted, true, why
  down: (voter, voted, why=null) -> @vote voter, voted, false, why

  vote: (voter, voted, up=true, why=null) ->
    check voter, String
    check voted, String
    @unvote voter, voted
    @logmr "Voting #{@name}.vote: vote", @c.insert { voter: voter, voted: voted, up: up, why: why }
    # update counters
    if (field = if up then @fields.up else @fields.down)?
      # MAYBE calculate *real* votes now and then via @findVoted(...).count() and @findVoter
      inc = @logmr "Voting #{@name}.vote: inc", @createObject field, 1
      @logmr "Voting #{@name}.vote: target", @targets.update { _id: voted }, { $inc: inc }
    @_updateLists voter, voted, up
  unvote: (voter, voted) ->
    check voter, String
    check voted, String
    for vote in logr @getVotes voter, voted # actually, should be one at any time only
      inc = if (list = if vote.up then @fields.up else @fields.down)? then @createObject list, -1
      if inc? then @logmr "Voting #{@name}.unvote target", @targets.update { _id: voted }, { $inc: inc }
      @logmr "Voting #{@name}.unvote: vote", @c.remove { _id: vote._id }
    @_updateLists voter, voted

  getVotes: (voter, voted) ->
    check voter, String
    check voted, String
    @c.find({ voter: voter, voted: voted }).fetch() # Again, should always return one only...
  findVoters: (voted) ->
    check voted, String
    @c.find { voted: voted }
  getVoters: (voted) ->
    _.pluck @findVoters(voted).fetch(), 'voter'
  findVoted: (voter) ->
    check voter, String
    @c.find { voter: voter }
  getVoted: (voter) ->
    _.pluck @findVoted(voter).fetch(), 'voted'
  publishMethods: ->
    me = @ # no => because we need the @userId within the method call
    Meteor.methods u.createObject @method, (vote, target, up, why) ->
      log "Voting #{me.name}.publishedMethod: vote=#{vote}; user=#{@userId}; target=#{target}; up=#{up}; why=#{why}"
      check vote, Boolean
      check target, String
      check up, Match.OptionalOrNull Boolean
      check why, Match.OptionalOrNull String
      if vote then me.vote @userId, target, up, why
      else me.unvote @userId, target

# The client-side voting will only access the source and target collections - if you publish them
class ClientVoting extends CommonVoting

  hookupTemplate: (template, toggle = true, askWhy, whyFeedback) ->
    doVote = (target, up) =>
      user = Meteor.user()
      if toggle and @voted user, target, up
        Meteor.call @method, false, target, up
      else
        if not up and askWhy?
          if (why = prompt(askWhy))?
            Meteor.call @method, true, target, false, why
            alert whyFeedback if whyFeedback?
        else
          Meteor.call @method, true, target, up
    template.events
      #'click a.vote-up': -> Meteor.call @method, true, @_id, true
      #'click a.vote-down': -> Meteor.call @method, false, @_id, false
      'click a.vote-up': -> doVote @_id, true
      'click a.vote-down': -> doVote @_id, false
    votedClass = (target, up) =>
      if (@voted Meteor.user(), target, up) then 'voted'
    template.helpers
      voted: -> votedClass @
      votedUp: -> votedClass @, true
      votedDown: -> votedClass @, false

Meteor.Voting = if Meteor.isServer then ServerVoting else ClientVoting
