var express    	= require("express"),
    app        	= express(),
    mongoose   	= require("mongoose"),
    Horoscope   = require("./models/horoscopes"),
    seeds       = require("./seeds.js"),
    bodyParser  = require("body-parser"),
    seedDB      = require("./seeds"),
    socketIO    = require("socket.io");
    port       	= process.env.PORT || 5000;

const server = app.listen(port, function(err){
    console.log("Horoscope Generator server is running on port " + port);
});

var databaseUrl = "mongodb://admin:cookiecoder@ds011331.mlab.com:11331/horoscope-generator";
// var databaseUrl = "mongodb://localhost:27017/horoscope-generator";
mongoose.connect(databaseUrl);

app.use(express.static("public"));
app.use(bodyParser.urlencoded({extended: true}));
app.set("views", "./src/views");
app.set("view engine", "ejs");
// seedDB();

//IO
const io = socketIO(server);
io.on('connection', function (socket) {
    socket.on('new_horoscope', function (data) {
        // we tell the client to execute 'new message'
        socket.broadcast.emit('new_horoscope', {horoscope: data});
    });
});

//ROOT ROUTE
app.get("/", function (req, res){
  Horoscope.find({}, function(err, allHoroscopes){
      if(err){
          console.log(err);
      } else {
          var horoscopeCount = allHoroscopes.length;
          res.render("index", {horoscopeCount:horoscopeCount});
      };
  });
});

app.get("/horoscopes", function (req, res){
    Horoscope.find({}, function(err, allHoroscopes){
        if(err){
            console.log(err);
        } else {
            allHoroscopes.reverse();
            firstTenHoroscopes = allHoroscopes.slice(0,10)
            res.render("horoscopes/index", {firstTenHoroscopes:allHoroscopes});
        };
    });
});

//CREATE -- Generate new horoscope
var newShowPage = "";
app.post("/horoscopes", function(req, res, next){
    var newHoroscope = {
      full_text       : req.body.full_text,
      abridged_text   : req.body.abridged_text,
      image           : req.body.image,
      author          : req.body.name,
      hometown        : req.body.hometown,
      date            : req.body.date,
      sign            : req.body.sign
    };
    Horoscope.create(newHoroscope, function(err, newlyCreated){
        if(err){
            console.log(err);
        } else{
            newShowPage = "/horoscopes/" + newlyCreated._id;
            res.send({redirect: newShowPage});
        };
    });
});

//NEW
app.get("/horoscopes/new", function(req, res){
    res.render("horoscopes/new");
});

//SHOW -- campground details
app.get("/horoscopes/:id", function(req, res){
    Horoscope.findById(req.params.id).exec(function(err, foundHoroscope){
        if(err){
            console.log(err);
        } else {
          res.render("horoscopes/show", {horoscope: foundHoroscope});
        };
    });
});

//safety net redirect
app.get("*", function (req, res){
    res.redirect("/");
});
