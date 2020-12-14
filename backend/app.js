// Copyright 2017 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

'use strict';



// [START gae_node_request_example]
const express = require('express');

const cors = require('cors');

const app = express();
app.use(cors())

// const token = ""
const token = ""

app.get('/', (req, res) => {
  res.status(200).send('Hello, world!').end();
});


app.get('/autocomplete/:ticker', (req, res) => {
	var request = require('request');
	console.log(req.params)
	var url = 'https://api.tiingo.com/tiingo/utilities/search?query='+ req.params.ticker +'&token=' + token
	console.log(url)
	var requestOptions = {
		'url' : url,
		'headers' : {
			'Content-Type' : 'application/json'
		}
	};

	request(requestOptions,
		function(error,response,body) {
			res.status(200).send(JSON.parse(body)).end()
		})
})

app.get('/daily/:ticker', (req, res) => {
	var request = require('request');
	console.log(req.params)
	var url = 'https://api.tiingo.com/tiingo/utilities/search/query='+ req.params.ticker +'&token=' + token
	console.log(url)
	var requestOptions = {
		'url' : url,
		'headers' : {
			'Content-Type' : 'application/json'
		}
	};

	request(requestOptions,
		function(error,response,body) {
			res.status(200).send(body).end()
		})
})

app.get('/summary/:ticker', (req, res) => {
	var request = require('request');
	console.log(req.params)
	var url = 'https://api.tiingo.com/tiingo/daily/'+ req.params.ticker +'?token=' + token
	console.log(url)
	var requestOptions = {
		'url' : url,
		'headers' : {
			'Content-Type' : 'application/json'
		}
	};

	request(requestOptions,
		function(error,response,body) {
			res.status(200).send(JSON.parse(body)).end()
		})
})

var lastprice = new Object();
app.get('/lastprice/:ticker', (req, res) => {
	if (lastprice[(req.params.ticker).toUpperCase()]) {
		res.status(503).send("Previous request of " + req.params.ticker + " is not finished. Click slowly...").end();
		console.log("request too fast");
	}
	else{
		lastprice[(req.params.ticker).toUpperCase()] = 'true';
		var request = require('request');
		var url = 'https://api.tiingo.com/iex?tickers='+ req.params.ticker +'&token=' + token
		console.log(url)
		var requestOptions = {
			'url' : url,
			'headers' : {
				'Content-Type' : 'application/json'
			}
		};

		request(requestOptions,
			function(error,response,body) {
				res.status(200).send(JSON.parse(body)).end();
				delete lastprice[(req.params.ticker).toUpperCase()];
			})
	}

})

const Freq = 'daily'

app.get('/historical/:ticker', (req, res) => {
	var request = require('request');
	console.log(req.params)

	var d = new Date();
	var n = d.toISOString();
	console.log(n)
	var year = n.substring(0,4) - 2;
	var startDate = year.toString() +'-'+n.substring(5,7) + '-' + n.substring(8,10);
	console.log(startDate)

	var url = 'https://api.tiingo.com/tiingo/daily/'+ req.params.ticker +'/prices?startDate=' + startDate +'&resampleFreq=' + Freq +'&token=' + token 
	console.log(url)

	var requestOptions = {
		'url' : url,
		'headers' : {
			'Content-Type' : 'application/json'
		}
	};

	request(requestOptions,
		function(error,response,body) {
			res.status(200).send(JSON.parse(body)).end()
		})
})


const highFreq = "5Min";

app.get('/dailychart/:ticker', (req, res) => {
	console.log("getting daily chart");
	var loading = 0;
	var info = [];
	var request = require('request');
	console.log(req.params)

	var dateRollBack = -5;

	var d = new Date()
	var year = d.getFullYear();
	var month = d.getMonth()+1;
	var date = d.getDate() + dateRollBack;
	var p = new Date(year, month-1, date)
	console.log("safe date: " + p);

	var year = p.getFullYear();
	var month = p.getMonth()+1;
	var date = p.getDate()


	var startDate = year.toString() + '-' + month.toString() + '-' + date.toString();

	console.log('try date: ' + startDate);
	var url = 'https://api.tiingo.com/iex/'+ req.params.ticker +'/prices?startDate=' + startDate +'&resampleFreq=' + highFreq +'&token=' + token 
	console.log(url)

	var start = 0;

	var requestOptions = {
		'url' : url,
		'headers' : {
			'Content-Type' : 'application/json'
		}
	};


	request(requestOptions,
		function(error,response,body) {
			info = JSON.parse(body);
			if (info.length != 0){
				for (var i = info.length-1;i>-1;i--){
					if (i == 0) {
						start = 0;
					}
					else{
						if (info[i].date.substring(8,10) != info[i-1].date.substring(8,10)){
							start = i;
							break;
						}
					}
				}
				res.status(200).send(info.slice(start)).end()
				console.log('latest data got');
			}
			else{
				res.status(500).send("No daily data avaliable").end()
				console.log("empty data")
			}

		}
	)

})

// app.get('/dailychart/:ticker', (req, res) => {
// 	var request = require('request');
// 	console.log(req.params)

// 	var d = new Date();
// 	var n = d.toISOString();
// 	console.log(n)
// 	// var year = n.substring(0,4) - 2;
// 	var year = n.substring(0,4);
// 	var startDate = year.toString() +'-'+n.substring(5,7) + '-' + n.substring(8,10);
// 	console.log(startDate)

// 	var url = 'https://api.tiingo.com/iex/'+ req.params.ticker +'/prices?startDate=' + startDate +'&resampleFreq=' + highFreq +'&token=' + token 
// 	console.log(url)

// 	var requestOptions = {
// 		'url' : url,
// 		'headers' : {
// 			'Content-Type' : 'application/json'
// 		}
// 	};

// 	request(requestOptions,
// 		function(error,response,body) {
// 			res.status(200).send(JSON.parse(body)).end()
// 		})
// })

const newsToken = ''

app.get('/news/:ticker', (req, res) => {
	var request = require('request');
	console.log(req.params)
	var url = 'https://newsapi.org/v2/everything?apiKey='+ newsToken + '&q=' + req.params.ticker;
	console.log(url)
	var requestOptions = {
		'url' : url,
		'headers' : {
			'Content-Type' : 'application/json'
		}
	};

	request(requestOptions,
		function(error,response,body) {
			body = JSON.parse(body);
			if (body.status == "ok"){
				// var toSend = JSON.parse(body.articles)
				// console.log(typeof(toSend))
				var toSend = body.articles.slice(0,100);
			}
			else{
				var toSend = [];
			}
			res.status(200).send(toSend).end()
		})
})



// Start the server
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`App listening on port ${PORT}`);
  console.log('Press Ctrl+C to quit.');
});
// [END gae_node_request_example]

module.exports = app;
