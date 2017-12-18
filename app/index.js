const HAPI = require('hapi');
const server = new HAPI.Server({
    port: process.env.PORT || 4503,
    host: process.env.HOST
});

let count = 0;

server.route({
    method: 'GET',
    path: '/',
    handler: (request, reply) => {
        return {
            id: request.info.id
        };
    }
});

server.route({
    method: 'GET',
    path: '/never_works',
    handler: (request, reply) => {
        throw 'This end point should never work!';
    }
});

server.route({
    method: 'GET',
    path: '/works_every_5th_time',
    handler: (request, reply) => {
        if((count++ % 5) === 0) {
            return {
                id: request.info.id,
                count: count - 1,
            }
        } else {
            throw `${count-1} % 5 !== 0`;
        }
    }
});

server.start()
    .then((val) => {
        console.log(`Server running at: ${server.info.uri}`);
    }, (err) => {
        console.log('Failed to start server!', err);
    });