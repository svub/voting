Package.describe({
  summary: "Keeps track of the rotation of the device and updates the html tag's class attribute and Meteor.isLandscapeMode"
});

Package.on_use(function (api, where) {
  if(api.export) { api.export('rotationDetector'); }
  
  api.use(['underscore', 'coffeescript', 'meteor', 'jquery'], 'client');
  api.add_files('rotation-detector.coffee', 'client');

});
