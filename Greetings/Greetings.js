require('dotenv').config();

exports.handler = (event, context, callback) => {
    console.log('Received event:', event);
    var response = process.env.Prefix + ' '+ event.params.path.name + ' '+process.env.Suffix;
    callback(null, response);
};
