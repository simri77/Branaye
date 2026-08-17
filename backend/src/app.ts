import express from 'express';
import healthRoute from './routes/health.route';
const app = express();

app.use('/api', healthRoute);

app.get('/', (req, res) => {
    res.send('Hello World!');
});

export default app;