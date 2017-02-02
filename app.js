(function(owner){
  console.log('ownder=', owner);
  /* =======================
      LOAD THE DEPENDENCIES
  ==========================*/
  //const webpack = require('webpack');
  const express = require('express');
  const bodyParser = require('body-parser');

  /* =======================
      LOAD THE CONFIG
  ==========================*/
  const port = process.env.PORT || 3000;

  /* =======================
      EXPRESS CONFIGURATION
  ==========================*/
  const app = express();
  var router = require('./router')(app);
  // parse JSON and url-encoded query
  app.use(bodyParser.urlencoded({extended: false}));
  app.use(bodyParser.json());


  // index page, just for testing
  app.get('/', (req, res) => {
      res.send('Hello JWT');
  });

  // require assets(by Isaac at 3 feb 2017)
  app.use('/js', express.static('js'));
  app.use('/css', express.static('css'));
  app.use('/css', express.static(__dirname + '/node_modules/bootstrap/dist/css'));
  app.use('/js', express.static(__dirname + '/node_modules/bootstrap/dist/js'));
  app.use('/js', express.static(__dirname + '/node_modules/jquery/dist'));

  app.set('views', __dirname + '/views');
  app.set('view engine', 'ejs');
  app.engine('html', require('ejs').renderFile);

  // open the server
  app.listen(port, () => {
      console.log(`Express is running on port ${port}`);
  });
})(this);
