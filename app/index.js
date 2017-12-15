const HAPI = require('hapi');
const server = new HAPI.Server({
    port: process.env.PORT || 4503,
    host: process.env.HOST
});

server.route({
    method: 'GET',
    path: '/',
    handler: (request, reply) => {
        return {
            id: request.info.id
        };
    }
});

server.start()
    .then((val) => {
        console.log(`Server running at: ${server.info.uri}`);
    }, (err) => {
        console.log('Failed to start server!', err);
    });