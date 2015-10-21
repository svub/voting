Package.describe({
  name: 'svub:voting',
  summary: 'Provides voting/rating/counting functionality for one item of a collection rating/counting an item of the same or different collection.',
  version: '1.0.3'
});

Package.onUse(function (api) {
  api.versionsFrom('1.2.0.2');

  common = ['client', 'server'];

  //api.use(['coffeescript', 'underscore', 'coffeescript', 'wizonesolutions:underscore-string', 'meteor', 'templating', 'ejson', 'mongo-livedata', 'deps'], common);
  //api.use(['minimongo', 'less'], 'client');
  api.use(['coffeescript', 'mongo']);

  api.add_files('voting.coffee');

});
