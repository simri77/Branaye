import express from 'express';
import healthRoute from './routes/health.route';
import notesRoute from './routes/notes.route';
import tagsRoute from './routes/tags.route';
import { setupSwagger } from './config/swagger';
import { errorHandler } from './middleware/error';

const app = express();

app.use(express.json());

app.use('/api', healthRoute);
app.use('/api/notes', notesRoute);
app.use('/api/tags', tagsRoute);

setupSwagger(app);

app.get('/', (_req, res) => {
  res.send('Hello World!');
});

app.use(errorHandler);

export default app;