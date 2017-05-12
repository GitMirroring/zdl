

var separator = '\n';
var page = require('webpage').create(),
  system = require('system'),
  id, match;

if(system.args.length < 2) {
  console.error('No URL provided');
  phantom.exit(1);
}
match = system.args[1].match(
  /https?:\/\/(?:openload\.(?:co|io)|oload\.tv)\/(?:f|embed)\/([\w\-]+)/);
if(match === null) {
  console.error('Could not find video ID in provided URL');
  phantom.exit(2);
}
id = match[1];

page.settings.userAgent = 'Mozilla/5.0 (Linux; Android 6.0; LENNY3 Build/MRA58K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.132 Mobile Safari/537.36';

page.open('https://openload.co/embed/' + id + '/', function(status) {
  var info = page.evaluate(function() {
    return {
      decoded_id: document.getElementById('streamurl').innerHTML,
      title: document.querySelector('meta[name="og:title"],'
        + 'meta[name=description]').content
    };
  });
  var url = 'https://openload.co/stream/' + info.decoded_id + '?mime=true';
  console.log(url + separator + info.title);
  phantom.exit();
});

page.onInitialized = function() {
  page.evaluate(function() {
    delete window.callPhantom;
    delete window._phantom;
  });
};
