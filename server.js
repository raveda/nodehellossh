var express = require('express');
// Constants
var DEFAULT_PORT = 3000;
var PORT = process.env.PORT || DEFAULT_PORT;
// App
var app = express();
app.get('/', function (req, res) {
  res.send('Hello World from NodeJS docker \n');
});

app.listen(PORT)
console.log('Running on http://localhost:' + PORT);