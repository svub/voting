Package.describe({
  summary: "Provides voting/rating/counting functionality for one item of a collection rating/counting an item of the same or different collection."
});

Package.on_use(function (api, where) {
  common = ['client', 'server'];

  api.use(['underscore', 'coffeescript', 'underscore-string-latest', 'meteor', 'templating', 'ejson', 'mongo-livedata', 'deps'], common);
  api.use(['minimongo', 'less'], 'client');

  api.add_files('voting.coffee', common);

});
